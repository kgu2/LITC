import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getFieldValue, getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';
import { NavigationMixin } from 'lightning/navigation';
import getVisits from '@salesforce/apex/SiteVisitController.getVisits';
import fetchFiles from '@salesforce/apex/ApplicationFederalAssistanceController.fetchFiles'; 
import generatePDF from '@salesforce/apex/LWCUploadController.generatePDF';

import { refreshApex } from '@salesforce/apex';

const columns = [
    { label: 'Report Id', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true},
    // { label: 'Report period', fieldName: 'Reporting_Period_Full__c', type : 'text', hideDefaultActions: true},
    // { label: 'Deadline', fieldName: 'submissionDeadline', type : 'text', hideDefaultActions: true},
    { label: 'Status', fieldName: 'Recipient_Status__c', type : 'text', hideDefaultActions: true,
        cellAttributes: { class: { fieldName: 'statusStyle' } }
    },
    
    {label: 'Edit/View', hideDefaultActions: true, type: "button-icon", name: 'provideInfo', typeAttributes: {  
        iconName: { fieldName: 'dynamicIconProvideInfo' },
        variant: 'brand',
        initialWidth: 175,
        class : { fieldName: 'stylingProvideInformation' }
    }},
    // {label: 'More Actions', hideDefaultActions: true, type: "button", typeAttributes: {  
    //     label: { fieldName: 'moreActionsLabel' },  
    //     name: 'AdditionalInfoButton',  
    //     variant: 'base', 
    //     class : { fieldName: 'stylingFundingDecision' }
    // }},
    // {label: 'Download', hideDefaultActions: true, type: "button-icon", initialWidth: 100, typeAttributes: {  
    //     iconName: 'action:download',
    //     variant: 'brand',
    //     class : { fieldName: 'stylingDownload' }
    // }},
];

export default class LitcSiteVisitsChecklist extends utilities {
    @api myRole;
    @api account;
    @track isLoading;

    @track siteVisits;
    @track showVisits;

    @track columns = columns;

    @wire(getVisits)
    async setApps(result) {
        this.setAppsResult = result;

        if (result.data) {
            console.log(result.data);
            let tempData = [];
        
            let myRole = this.myRole;

            const restrictedRoles = ['EBiz POC'];
            const hasOnlyRestrictedRoles = myRole !== undefined && myRole.split(';').every(role => restrictedRoles.includes(role));

            for (let item of result.data) {
                let tempRecord = Object.assign({}, item);

                // tempRecord.submissionDeadline = tempRecord.Submission_Deadline__c ? new Date(tempRecord.Submission_Deadline__c).toLocaleDateString("en-US") : undefined;

                if (tempRecord.Recipient_Status__c === 'Submitted') {
                    tempRecord.statusStyle = 'slds-text-color_success';
                    tempRecord.stylingProvideInformation = 'darkblue';
                    tempRecord.dynamicIconProvideInfo = 'action:preview';
                    tempRecord.stylingDownload = 'slds-show gray slds-button';
                } else {
                    tempRecord.dynamicIconProvideInfo = 'action:edit';
                    tempRecord.statusStyle = 'slds-text-color_error';
                    tempRecord.stylingProvideInformation = 'lightblue';
                    tempRecord.stylingFundingDecision = 'slds-hide slds-button';
                    tempRecord.stylingDownload = 'slds-show gray slds-button';
                }
    
                if(hasOnlyRestrictedRoles){
                    tempRecord.stylingProvideInformation = 'slds-hide';
                    tempRecord.stylingFundingDecision = 'slds-hide slds-button';
                }

                tempData.push(tempRecord);
            }

            this.siteVisits = tempData;
            this.showVisits = tempData.length > 0;

        } else if (result.error) {
            console.log(result.error);
        }
    }

    handleRowAction(event){ 
        let button = event.detail.action.class.fieldName;
        if(button === 'stylingProvideInformation'){
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    actionName: 'view',
                    recordId : event.detail.row.Id,
                    objectApiName : 'Site_Visit__c'
                    }
                });
        } 
        if(button === 'stylingDownload'){ 
            let id = event.detail.row.Id;

            // this.downloadPDFReporting(id, reportType, reportPeriod, grantYear, clinicName);
        }
    }
}