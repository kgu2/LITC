import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getFieldValue, getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';
import { NavigationMixin } from 'lightning/navigation';
import getReports from '@salesforce/apex/LITCReportingController.getReports';
import get425Reports from '@salesforce/apex/SF425ReportingController.getReportsLITC';
import fetchFiles from '@salesforce/apex/ApplicationFederalAssistanceController.fetchFiles'; 
import generatePDF from '@salesforce/apex/LWCUploadController.generatePDF';

import { refreshApex } from '@salesforce/apex';

const columns = [
    { label: 'Report Id', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'Report period', fieldName: 'Reporting_Period_Full__c', type : 'text', hideDefaultActions: true},
    { label: 'Deadline', fieldName: 'submissionDeadline', type : 'text', hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status__c', type : 'text', hideDefaultActions: true,
        cellAttributes: { class: { fieldName: 'statusStyle' } }
    },
    
    {label: 'Edit/View', hideDefaultActions: true, type: "button-icon", name: 'provideInfo', typeAttributes: {  
        iconName: { fieldName: 'dynamicIconProvideInfo' },
        variant: 'brand',
        initialWidth: 175,
        class : { fieldName: 'stylingProvideInformation' }
    }},
    {label: 'More Actions', hideDefaultActions: true, type: "button", typeAttributes: {  
        label: { fieldName: 'moreActionsLabel' },  
        name: 'AdditionalInfoButton',  
        variant: 'base', 
        class : { fieldName: 'stylingFundingDecision' }
    }},
    {label: 'Download', hideDefaultActions: true, type: "button-icon", initialWidth: 100, typeAttributes: {  
        iconName: 'action:download',
        variant: 'brand',
        class : { fieldName: 'stylingDownload' }
    }},
];

export default class LitcReportingChecklist extends utilities {
    
    @api myRole;
    @api account;
    @track isLoading;

    @track columns = columns;

    @track reportsR;
    @track reportsL;
    @track reports425;
    @track showReportsR;
    @track showReportsL;
    @track showReportsSF425;

    @track setAppsResult;
    @track set425Result;

    @wire(getReports)
    async setApps(result) {
        this.setAppsResult = result;

        if (result.data) {
            console.log(result.data);
            let tempAppsR = [];
            let tempAppsL = [];
            let myRole = this.myRole;

            const restrictedRoles = ['View Only Staff', 'EBiz POC'];
            const hasOnlyRestrictedRoles = myRole !== undefined && myRole.split(';').every(role => restrictedRoles.includes(role));

            for (let item of result.data) {
                let tempRecord = Object.assign({}, item);

                tempRecord.submissionDeadline = tempRecord.Submission_Deadline__c ? new Date(tempRecord.Submission_Deadline__c).toLocaleDateString("en-US") : undefined;

                if (tempRecord.Status__c === 'Submitted') {
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

                if(tempRecord.RecordType.Name === 'Form 13424-R'){ 
                    tempAppsR.push(tempRecord);
                }
                if(tempRecord.RecordType.Name === 'Form 13424-L'){ 
                    tempAppsL.push(tempRecord);
                }
            }

            this.reportsR = tempAppsR;
            this.showReportsR = tempAppsR.length > 0;

            this.reportsL = tempAppsL;
            this.showReportsL = tempAppsL.length > 0;

        } else if (result.error) {
            console.log(result.error);
        }
    }
    @wire(get425Reports)
    async set425Rep(result){
        this.set425Result = result;
        console.log('sf425 result', result);

        if(result.data){
            console.log(result.data);
            let temp425 = [];
            let myRole = this.myRole;
            const restrictedRoles = ['View Only Staff', 'EBiz POC'];
            const hasOnlyRestrictedRoles = myRole !== undefined && myRole.split(';').every(role => restrictedRoles.includes(role));

            for (let item of result.data) {
                let tempRecord = Object.assign({}, item);

                // tempRecord.submissionDeadline = tempRecord.Submission_Deadline__c ? new Date(tempRecord.Submission_Deadline__c).toLocaleDateString("en-US") : undefined;

                if (tempRecord.Status__c === 'Submitted') {
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

                temp425.push(tempRecord);
            }

            this.reports425 = temp425;
            this.showReportsSF425 = temp425.length > 0;

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
                    objectApiName : 'LITC_Reporting_Form__c'
                    }
                });
        } 
        if(button === 'stylingDownload'){ 
            let id = event.detail.row.Id;
            let reportType = event.detail.row.RecordType.Name;
            let reportPeriod = event.detail.row.Reporting_period__c;
            let grantYear = event.detail.row.Grant_Year__c;
            let clinicName = event.detail.row.Name_of_Clinic__c;

            this.downloadPDFReporting(id, reportType, reportPeriod, grantYear, clinicName);
        }
    }
    handleRowAction425(event){
        let button = event.detail.action.class.fieldName;
        if(button === 'stylingProvideInformation'){
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                    actionName: 'view',
                    recordId : event.detail.row.Id,
                    objectApiName : 'S425_Form__c'
                    }
                });
        } 
        if(button === 'stylingDownload'){ 
            let id = event.detail.row.Id;
            this.downloadPDF(id);
        }
    }

    async downloadPDFReporting(id, reportType, period, grantYear, clinicName){ 
        let temp = false;
        this.isLoading = true;

        let reportPeriod = '';
        if(period === 'Year-End report (January 1 through December 31)'){ 
            reportPeriod = 'YE';
        } else{ 
            reportPeriod = 'INT';
        }

        let filePrefix = '';
        let vfPageName = '';
        if(reportType === 'Form 13424-R'){ 
            filePrefix = grantYear + '-Form13424R-' + reportPeriod + '-' + clinicName;
            vfPageName = 'LITCReportingRPDF';
        } else{ 
            filePrefix = grantYear + '-Form13424L-' + reportPeriod + '-' + clinicName;
            vfPageName = 'LITCReportingLPDF';
        }

        await generatePDF({recordId: id, vfPageName: vfPageName, prefix: filePrefix});

        fetchFiles({recordId: id}).then(data=>{ 
            let filesList = JSON.parse(JSON.stringify(data));
            let fileId = '';
            console.log(filesList)

            filesList.some(obj => {
                if(obj.ContentDocument.FileType == 'PDF'){ 
                    fileId = obj.ContentDocumentId;
                    return true;
                }
            });
        
            console.log(fileId);

            if(fileId){ 
                temp = true;
                let baseUrl = window.location.href;
                baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileId + '?operationContext=S1'
                    }
                }, false)
            } else{
                throw new Error('No file found');
            }

            return temp;

        }).catch(error=>{ 
            console.log('in catch');
        }) 

        this.isLoading = false;
    }


    async downloadPDF(id){ 
        let temp = false;
        this.isLoading = true;

        await generatePDF({recordId: id, vfPageName: 'SF425', prefix: 'formSF425'});

        fetchFiles({recordId: id}).then(data=>{ 
            let filesList = JSON.parse(JSON.stringify(data));
            let fileId = '';

            filesList.some(obj => {
                if(obj.ContentDocument.FileType == 'PDF'){ 
                    fileId = obj.ContentDocumentId;
                    return true;
                }
            });
        
            console.log(fileId);

            if(fileId){ 
                temp = true;
                let baseUrl = window.location.href;
                baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileId + '?operationContext=S1'
                    }
                }, false)
            } else{
                throw new Error('No file found');
            }

            return temp;

        }).catch(error=>{ 
            console.log('in catch');
        }) 

         this.isLoading = false;
    }
}