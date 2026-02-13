import { LightningElement, track, wire, api } from 'lwc';
import { getFieldValue, getRecord, createRecord } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';
import { NavigationMixin } from 'lightning/navigation';
import fetchFiles from '@salesforce/apex/ApplicationFederalAssistanceController.fetchFiles'; 
import getFundingAwards from '@salesforce/apex/ApplicationFederalAssistanceController.getFundingAwards'; 
import getFundingDisbursements from '@salesforce/apex/ApplicationFederalAssistanceController.getFundingDisbursements'; 
import generatePDF from '@salesforce/apex/FundingAwardPDFController.generatePDF'; 
import updateRecord from '@salesforce/apex/litcLoginController.updateRecord';

import { refreshApex } from '@salesforce/apex';

const columns = [
    { label: 'Name', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status', type : 'text', hideDefaultActions: true, },
    { label: 'Funding amount', fieldName: 'Amount', type : 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
    { label: 'Disbursement amount', fieldName: 'Disbursement_Total__c', type : 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }},    
    { label: 'Accept/Reject', hideDefaultActions: true, type: "button-icon", name: 'provideInfo', typeAttributes: {  
        iconName: 'action:edit',
        variant: 'brand',
        initialWidth: 175,
        class :'lightblue'
    }}
];

const columnsDisbursement = [
    { label: 'Name', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'Status', fieldName: 'Recipient_Status__c', type : 'text', hideDefaultActions: true, cellAttributes: { class: { fieldName: 'statusStyle' } }},
    { label: 'Amount', fieldName: 'Amount', type : 'currency', hideDefaultActions: true, cellAttributes: { alignment: 'left' }},
    { label: 'Date', fieldName: 'DisbursementDate', type : 'date', hideDefaultActions: true, typeAttributes: {
        day: "numeric",
        month: "numeric",
        year: "numeric"
    }},
    { label: 'Accept/Reject', hideDefaultActions: true, type: "button", name: 'provideInfo', typeAttributes: {  
        variant: 'base',
        label: 'Accept/Reject',
        class : { fieldName: 'showLink' },
        initialWidth: 175,
    }}, 
    {label: 'Download', hideDefaultActions: true, type: "button-icon", initialWidth: 100, typeAttributes: {  
        iconName: 'action:download',
        variant: 'brand',
        class : { fieldName: 'stylingDownload' }
    }},
];



export default class LitcFundingAward extends utilities {
    @api recordId;
    @track isLoading;
    // @track showDisbursementPage;

    @track fundingAwards;
    @track selectedAward;
    @track selectedDisbursement;

    @track fundingDisbursements;
    @track fundingAwardColumns = columns;
    @track fundingDisbursementColumns = columnsDisbursement;

    @track recipientDecision;
    @track rejectionComments;

    connectedCallback(){ 
        console.log(this.recordId);
    }

    @wire(getFundingAwards, { appId: '$recordId' })
    setFundingAwards({ error, data }) {
        if (data) {
            console.log(data);
            let tempReports = [];

            data.forEach(function(item) {
                let tempRecord = Object.assign({}, item);

                tempReports.push(tempRecord);
            });

            this.fundingAwards = tempReports;
        } else if (error) {
            console.log(error);
        }
    }

    @wire(getFundingDisbursements, { awardId: '$selectedAward' })
    setFundingDisbursements(result) {
        this.disbursementResult = result;
        if (result.data) {
            let tempReports = [];
            result.data.forEach(function(item) {
                let tempRecord = Object.assign({}, item);
                if(tempRecord.Recipient_Status__c === 'Accepted') {
                    tempRecord.statusStyle = 'slds-text-color_success';
                    tempRecord.stylingDownload = 'slds-show gray slds-button';
                } else{ 
                    tempRecord.stylingDownload = 'slds-hide';
                }
                
                if(tempRecord.Recipient_Status__c === 'Accepted' || tempRecord.Recipient_Status__c === 'Rejected'){ 
                    tempRecord.showLink = 'slds-hide';
                }

                tempReports.push(tempRecord);
            });

            this.fundingDisbursements = tempReports;
        } else if (result.error) {
            console.log(result.error);
        }
    }

    handleOptionChange(event){ 
        this.recipientDecision = event.target.value;
    }

    @track options = [
        { label: 'Accept', value: 'Accepted' },
        { label: 'Reject', value: 'Rejected' },
    ];

    handleFundingDisbursementSelect(event){
        let button = event.detail.action.class.fieldName;
        if(button === 'stylingDownload'){
            this.downloadPDF(event.detail.row.Id);
        } else{ 
            this.selectedDisbursement = event.detail.row.Id;
        }
    }

    downloadPDF(id){
        let temp = false;
        fetchFiles({recordId: id}).then(data=>{ 
            let filesList = JSON.parse(JSON.stringify(data));
            let fileId = '';

            filesList.some(obj => {
                if(obj.ContentDocument.FileType == 'PDF'){ 
                    fileId = obj.ContentDocumentId;
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
    }

    async checkExistingFile(id) {
        try {
            const data = await fetchFiles({ recordId: id });
            const filesList = JSON.parse(JSON.stringify(data));
            let fileId = '';

            filesList.some(obj => {
                if (obj.ContentDocument.FileType === 'PDF') {
                    fileId = obj.ContentDocumentId;
                    return true;
                }
                return false;
            });

            console.log(fileId);

            if (fileId) {
                return true;
            } else {
                return false;
            }
        } catch (error) {
            return false;
        }
    }

    async handleSubmit(){ 
        this.isLoading= true;
        console.log(this.recipientDecision);

        if(!this.recipientDecision){ 
            this.showNotification('Error', 'Required fields are missing', 'error');
            return;
        }
        if(this.recipientDecision === 'Rejected' && !this.rejectionComments){ 
            this.showNotification('Error', 'Required fields are missing', 'error');
            return;
        }

        let fields = {
            Recipient_Comments__c: this.rejectionComments,
            Recipient_Status__c: this.recipientDecision
        };

        try {
            console.log('in updateRecord');
            await updateRecord({recordId: this.selectedDisbursement, objectName: 'FundingDisbursement', fields: fields});
            console.log(this.selectedDisbursement);

            if(this.recipientDecision === 'Accepted'){ 
                console.log(this.selectedAward);
                console.log(this.selectedDisbursement);
                // on accept it should always generate the file
                await generatePDF({recordId: this.selectedAward, disbursementId: this.selectedDisbursement});
                this.downloadPDF(this.selectedDisbursement);
                // const result = await this.checkExistingFile(this.selectedDisbursement);
                // if(result === true){ 
                //     this.downloadPDF(this.selectedDisbursement);
                // } else{ 
                //     await generatePDF({recordId: this.selectedAward, disbursementId: this.selectedDisbursement});
                //     this.downloadPDF(this.selectedDisbursement);
                // }
                this.showNotification('Success', 'Thank you for accepting the award. If further correspondence is needed, the LITC Program Office will reach out.', 'success');
            } else{ 
                this.showNotification('Success', 'Thank you for your response. The LITC Program Office will be in touch for further discussion about the award.', 'success');
            }

            refreshApex(this.disbursementResult);
            this.selectedDisbursement = undefined;
            this.rejectionComments = undefined;
            this.recipientDecision = undefined;
            this.isLoading= false;

        } catch (error) {
            console.error(error);
        }
    }

    // this should always generate a pdf, even if theres an existing file
    async handleDownloadPDF(){
        this.isLoading = true;
        // const result = await this.checkExistingFile(this.selectedDisbursement);
        // if(result === true){ 
        //     this.downloadPDF(this.selectedDisbursement);
        // } else{ 
        //     await generatePDF({recordId: this.selectedAward, disbursementId: this.selectedDisbursement});
        //     this.downloadPDF(this.selectedDisbursement);
        // }

        await generatePDF({recordId: this.selectedAward, disbursementId: this.selectedDisbursement});
        this.downloadPDF(this.selectedDisbursement);
        this.isLoading = false;
    }

    closeModal(){ 
        this.dispatchEvent(new CustomEvent('closemodal'));
    }

    openFundingAward(event){ 
        this.selectedAward = event.detail.row.Id;
    }
    handleBackClick(){ 
        this.selectedAward = undefined;
    }
    handleBackClickTwo(){
        this.selectedDisbursement = undefined;
    }

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    handleCommentsChange(event){
        this.rejectionComments = event.target.value;
    }

    get showRejection(){ 
        return this.recipientDecision === 'Rejected';
    }
}