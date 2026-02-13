import { LightningElement, api, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, updateRecord, createRecord, getRecordNotifyChange , getFieldValue} from 'lightning/uiRecordApi';
import { CloseActionScreenEvent } from 'lightning/actions';
import APPLICATION_REVIEW_OBJECT from '@salesforce/schema/ApplicationReview';
import INDIVIDUAL_APPLICATION_APPLICATION_FOR_FEDERAL_ASSISTANCE_OBJECT from '@salesforce/schema/Application_for_Federal_Assistance__c.Individual_Application__c';

// Fields for NTA_Review__c
import INTERNAL_APPLICATION_STATUS from  '@salesforce/schema/NTA_Review__c.Review_Status__c';
import DATE_INTAKE_REVIEW_STARTED from '@salesforce/schema/NTA_Review__c.Date_Intake_Review_Started__c';
import APPLICATION_FOR_FEDERAL_ASSISTANCE from '@salesforce/schema/NTA_Review__c.Application_for_Federal_Assistance__c';
import FLOW_STATUS from '@salesforce/schema/NTA_Review__c.Flow_Status__c';

// Fields for ApplicationReview
import APPLICATION_ID from '@salesforce/schema/ApplicationReview.ApplicationId';
import APLICATION_REVIEW_APPLICATION_FOR_FEDERAL_ASSISTANCE from '@salesforce/schema/ApplicationReview.Application_for_Federal_Assistance__c';
import NTAREVIEW from '@salesforce/schema/ApplicationReview.NTA_Review__c';

import createLevel2RC from '@salesforce/apex/ReviewCardController.createLevel2RC'; 
import getLevel2RCs from '@salesforce/apex/ReviewCardController.getLevel2RCs'; 
import getLevel1RCs from '@salesforce/apex/ReviewCardController.getLevel1RCs'; 
import utilities from 'c/utilities';
import { NavigationMixin } from 'lightning/navigation';

export default class lITCQuickAction extends utilities {
    @api recordId; // ID of the Application_for_Federal_Assistance__c
    @api buttonType;
    @track showModal = false;
    selectedOption = 'No'; // Default selection

    individualApplicationId; // Stores retrieved Individual_Application__c
    ApplicationForFederalAssistance;


    @track showRCModal;
    @track ntaRecord;
    @track showLevel2Button;
    @track allSubmittedLevelOne;
    @track allSubmittedLevelTwo;
/*     @api invoke() {
        this.showModal = true;
        this.selectedOption = 'No'; // Ensure 'No' is default when modal opens
    } */

    // Fetch Individual_Application__c when component loads
    @wire(getRecord, { recordId: '$recordId', fields: [APPLICATION_FOR_FEDERAL_ASSISTANCE, FLOW_STATUS, INTERNAL_APPLICATION_STATUS] })
    wiredApplication({ error, data }) {
        if (data) {
            this.ntaRecord = data;
            this.ApplicationForFederalAssistance = data.fields.Application_for_Federal_Assistance__c.value;
        } else if (error) {
            console.error('Error retrieving Individual_Application__c', error);
        }
    }

    // Once ApplicationForFederalAssistance is set, fetch the Individual_Application__c from that record
    @wire(getRecord, { 
        recordId: '$ApplicationForFederalAssistance', 
        fields: [INDIVIDUAL_APPLICATION_APPLICATION_FOR_FEDERAL_ASSISTANCE_OBJECT] 
    })
    wiredIndividualApplication({ error, data }) {
        if (data) {
            this.individualApplicationId = data.fields[INDIVIDUAL_APPLICATION_APPLICATION_FOR_FEDERAL_ASSISTANCE_OBJECT.fieldApiName].value;
        } else if (error) {
            console.error('Error retrieving Individual_Application__c', error);
        }
    }

    // Options for radio group
    reviewOptions = [
        { label: 'Yes', value: 'Yes' },
        { label: 'No', value: 'No' }
    ];


    @wire(getLevel2RCs, { recordId: '$recordId' })
    getLevel2RCs({ error, data }) {
        if (data) {
            console.log(data);
            this.showLevel2Button = data && data.length === 0;
            this.allSubmittedLevelTwo = data.length > 0 && data.every(rc => rc.Status__c === "Submitted");

            console.log(this.showLevel2Button)
            console.log(this.allSubmittedLevelTwo)
        } else if (error) console.error( error);
    }
    @wire(getLevel1RCs, { recordId: '$recordId' })
    getLevel1RCs({ error, data }) {
        if (data) {
            this.allSubmittedLevelOne = data.length > 0  && data.every(rc => rc.Status__c === "Submitted");
        } else if (error) console.error( error);
    }


    // Handle radio selection change
    handleCheckboxChange(event) {
        this.selectedOption = event.detail.value;
    }

    openModal() {
        this.showModal = true;
        this.selectedOption = 'No'; // Reset to default
    }

    // Handle Submit
    handleSubmit() {
        if (this.selectedOption === 'No') {
            this.showModal = false; // Close modal without changes
            return;
        }

        const fields = {};
        fields[INTERNAL_APPLICATION_STATUS.fieldApiName] = 'Intake Review Started';
        fields[DATE_INTAKE_REVIEW_STARTED.fieldApiName] = new Date().toISOString();
        fields['Id'] = this.recordId; // Needed for update

        const recordInput = { fields };

        updateRecord(recordInput)
            .then(() => {
                // Create ApplicationReview Record
                const appReviewFields = {};
                appReviewFields[APLICATION_REVIEW_APPLICATION_FOR_FEDERAL_ASSISTANCE.fieldApiName] = this.ApplicationForFederalAssistance;
                appReviewFields[APPLICATION_ID.fieldApiName] = this.individualApplicationId;
                appReviewFields[NTAREVIEW.fieldApiName] = this.recordId;


                const appReviewRecordInput = { apiName: APPLICATION_REVIEW_OBJECT.objectApiName, fields: appReviewFields };

                createRecord(appReviewRecordInput).then(res=>{
                    console.log(res);
                    this[NavigationMixin.GenerateUrl]({
                        type: 'standard__recordPage',
                            attributes: {
                                objectApiName: 'ApplicationReview',
                                actionName: 'view',
                                recordId : res.id
                        }
                    }).then(url => {
                        window.open(url, "_blank");
                        window.location.reload();
                    });
                })
                
            })
            .then(() => {
                console.log('Successfully created ApplicationReview record');

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Success',
                        message: 'Intake Review started successfully!',
                        variant: 'success',
                    })
                );

               // eval("$A.get('e.force:refreshView').fire();");

                this.showModal = false; // Close modal
            })
            .catch(error => {
                console.error('Error in process', error);
                const errorMessage = error.body && error.body.message ? error.body.message : error.message;
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: error.body.message,
                        variant: 'error',
                    })
                );
            });
    }

    // Close Modal
    closeModal() {
        this.showModal = false;
        this.dispatchEvent(new CloseActionScreenEvent()); // Close Quick Action Panel
    }



    openRCModal(){
        this.showRCModal = true;
    }
    closeRCModal() {
        this.showRCModal = false;
    }
    handleCreateRC(){ 
        if(this.allSubmittedLevelOne){ 
            createLevel2RC({recordId: this.recordId}).then(res=>{
                this[NavigationMixin.GenerateUrl]({
                   type: 'standard__recordPage',
                       attributes: {
                           objectApiName: 'Review_Card__c',
                           actionName: 'view',
                           recordId : res
                   }
               }).then(url => {
                   this.showLevel2Button = false;
                   window.open(url, "_blank");
                   window.location.reload();
               });
                this.showRCModal = false;
           }).catch(error=>{
               console.log(error)
           })
        } else{ 
            this.showNotification('Error', 'All level one review cards must be submitted', 'error');
        }
    }
    approveTechnicalReview(){ 
        updateRecord({fields: {
            Id: this.recordId, 
            Review_Status__c: 'Technical Review Complete', 
            Date_Technical_Review_Completed__c: new Date().toISOString(),
            Flow_Status__c: 'Staff Review',
        }}).then(()=>{   
            getRecordNotifyChange([{recordId: this.recordId}]);
        }).catch(err=>{
             console.log(err)
        })
    }


    get showIntakeReview(){ 
        return getFieldValue(this.ntaRecord, FLOW_STATUS) === 'Intake Review' && getFieldValue(this.ntaRecord, INTERNAL_APPLICATION_STATUS) === null;
    }
    get showReviewCard(){ 
        return getFieldValue(this.ntaRecord, FLOW_STATUS) === 'Technical Review' && this.showLevel2Button && this.allSubmittedLevelOne;
    }
    get showApproveLevelTwo(){ 
        return getFieldValue(this.ntaRecord, FLOW_STATUS) === 'Technical Review' && this.allSubmittedLevelTwo && !this.showLevel2Button
    }
}