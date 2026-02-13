import { LightningElement, api , wire, track } from 'lwc';
import utilities from 'c/utilities';
import { getRecord, updateRecord, createRecord, getRecordNotifyChange , getFieldValue} from 'lightning/uiRecordApi';
import CLOSEOUT_STATUS from '@salesforce/schema/FundingAward.Closeout_status__c';
import RETURN_FUNDS from '@salesforce/schema/FundingAward.Return_Grant_Funds__c';
import AMOUNT_RETURNED from '@salesforce/schema/FundingAward.Amount_Returned__c';
import runChecks from '@salesforce/apex/LITCCloseoutController.runChecks';
import generatePDF from '@salesforce/apex/FundingAwardPDFController.generatePDF'; 

import DISBURSEMENTS_ACCEPTED from '@salesforce/schema/FundingAward.All_disbursements_accepted__c';
import REPORTING_ACCEPTED from '@salesforce/schema/FundingAward.All_Reporting_Forms_Accepted__c';
import REPORTING_SUBMITTED from '@salesforce/schema/FundingAward.All_Reporting_Forms_Submitted__c';
import PMS_VALIDATED from '@salesforce/schema/FundingAward.PMS_Figures_Validated__c';


const FIELDS = [CLOSEOUT_STATUS, RETURN_FUNDS, AMOUNT_RETURNED, DISBURSEMENTS_ACCEPTED, REPORTING_ACCEPTED, REPORTING_SUBMITTED, PMS_VALIDATED];

export default class LitcCloseoutCheck extends utilities {
    @api recordId;
    @track record;
    @track showModal;
    @track isLoading;
    @track showModalTwo;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.record = data;
        }
        else if(error){ 
            console.error(error);
        }
    }

    async handleRunChecks(){ 
        this.isLoading= true;

        try{
            await updateRecord({fields: {Id: this.recordId, 'Closeout_status__c': 'Closeout In Process'}})
            await runChecks({recordId: this.recordId})
            this.showNotification('Success', 'Closeout initiated', 'success');
            getRecordNotifyChange([{recordId: this.recordId}]);
            this.isLoading= false;
            
        } catch(error){ 
            console.log(error);
            this.isLoading= false;
        }

        
    }

    async handleFinalizeCloseout(){ 
        this.isLoading= true;
        this.showModal = false;

        try{ 
            await updateRecord({fields: {Id: this.recordId, 'Closeout_status__c': 'Closeout Completed'}});
            let amount = 0;

            if(getFieldValue(this.record, RETURN_FUNDS) === 'Yes'){ 
                
                amount = getFieldValue(this.record, AMOUNT_RETURNED) * -1;
                console.log(amount)
            }

            const fields = {Amount : amount, FundingAwardId: this.recordId, DisbursementDate: new Date().toISOString(), Recipient_Status__c: 'Accepted'};
            let disbursement = await createRecord({ apiName: 'FundingDisbursement', fields: fields });

            await generatePDF({recordId: this.recordId, disbursementId: disbursement.id});
            
            this.showNotification('Success', 'Closeout finalized', 'success');
            getRecordNotifyChange([{recordId: this.recordId}]);


            this.showModalTwo = true;

        } catch(error){ 
            console.log(error)
            // this.showNotification('Error', error.body.output.errors[0].message, 'error');
            console.log(error)

            if(!getFieldValue(this.record, DISBURSEMENTS_ACCEPTED)){
                this.showNotification('Error', 'All Disbursements Accepted must be checked before attempting to closeout', 'error');
            }
            if(!getFieldValue(this.record, REPORTING_SUBMITTED)){
                this.showNotification('Error', 'All Reporting Forms Submitted must be checked before attempting to closeout', 'error');
            }
            if(!getFieldValue(this.record, REPORTING_ACCEPTED)){
                this.showNotification('Error', 'All Reporting Forms Accepted must be checked before attempting to closeout', 'error');
            }
            if(!getFieldValue(this.record, PMS_VALIDATED)){
                this.showNotification('Error', 'PMS Figures Validated is required before attempting to closeout', 'error');
            }

            
        } finally{ 
            this.showModal = false;
            this.isLoading= false;
        }
        
    }

    async handleRequestReview(){ 
        try{
            await updateRecord({fields: {Id: this.recordId, 'Closeout_status__c': 'Review Needed'}})
            this.showNotification('Success', 'Notification sent', 'success');
            getRecordNotifyChange([{recordId: this.recordId}]);
            
        } catch(error){ 
            console.log(error);
        }
    }

    async handleModalTwo(){ 
        try{
            await updateRecord({fields: {Id: this.recordId, 'Final_Funding_Award__c': 'Yes'}})
            getRecordNotifyChange([{recordId: this.recordId}]);
            
        } catch(error){ 
            console.log(error);
        } finally{
            this.showModalTwo = false;
        }
    }

    openConfirmationModal(){ 
        this.showModal = true;
    }
    closeModal(){ 
        this.showModal = false;
    }
    closeModalTwo(){ 
        this.showModalTwo = false;
    }


    get isCloseoutInProgress(){ 
        return getFieldValue(this.record, CLOSEOUT_STATUS) === 'Closeout In Process';
    }

    get isCloseoutComplete(){ 
        return getFieldValue(this.record, CLOSEOUT_STATUS) === 'Closeout Completed';
    }

    get isCloseoutReviewNeeded(){ 
        return getFieldValue(this.record, CLOSEOUT_STATUS) === 'Review Needed';
    }

    get isCloseoutNotStarted(){ 
        return getFieldValue(this.record, CLOSEOUT_STATUS) === null || getFieldValue(this.record, CLOSEOUT_STATUS) === 'Closeout Not Started';
    }

    get isCloseoutStarted(){ 
        return !this.isCloseoutNotStarted;
    }
    get isCloseoutReviewNeededDisabled(){
        return this.isCloseoutNotStarted || this.isCloseoutComplete;
    } 
    get isCloseoutCompleteDisabled(){
        return this.isCloseoutNotStarted || this.isCloseoutComplete;
    } 


}