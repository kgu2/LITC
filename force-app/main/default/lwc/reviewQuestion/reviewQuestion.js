import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { deleteRecord, getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';
import getApplicationFields from '@salesforce/apex/ReviewCardController.getApplicationFields';
import getLegacyApplicationFields from '@salesforce/apex/ReviewCardController.getLegacyApplicationFields';

import getLicenses from '@salesforce/apex/ApplicationFederalAssistanceController.getLicenses';
import getOtherStaff from '@salesforce/apex/ApplicationFederalAssistanceController.getOtherStaff';



export default class ReviewQuestion extends utilities {
    @api question;
    @api version;
    @api disableEdits;
    @track isLoading;
    @track isRendered;
    @track activeSections = ['Description', 'Fields', 'Score'];

    @track fieldNames;
    @track appData = [];
    @track showPopover;
    @track fieldValue;

    @track licensesA; licensesB; licensesC;
    @track otherStaff;
    @track showPopoverHelp;

    connectedCallback(){ 
        console.log(this.version)
        if(!this.question.Review_Question__r.Formula__c) return;

        this.fieldNames = this.question.Review_Question__r.Formula__c.split(',').map(field => field.trim());
        let applicationValue = this.question.Review_Card__r.NTA_Review__r.Application_for_Federal_Assistance__c;

        if(this.version === 'Legacy') {
            getLegacyApplicationFields({recordId: applicationValue, fieldNames: this.fieldNames}).then(data=>{
                this.appData = Object.keys(data).filter(key => key !== 'Id').map(key => ({key,value: data[key]}));
           }).catch(error=>{
                console.log(error);
           })
        } else{ 
            getApplicationFields({recordId: applicationValue, fieldNames: this.fieldNames}).then(data=>{
                this.appData = Object.keys(data).filter(key => key !== 'Id').map(key => ({key,value: data[key]}));
           }).catch(error=>{
                console.log(error);
           })

           let questionId = this.question.Question_ID__c;

           if(questionId === 'LITC-12'){ 
                console.log('in litc 12')
                getLicenses({appId: applicationValue, type: 'Qualified Tax Expert'}).then(res=>{
                    console.log(res)
                    this.licensesA = res;
            })
           }
           if(questionId === 'LITC-13'){ 
                getLicenses({appId: applicationValue, type: 'Clinic Director'}).then(res=>{
                    this.licensesB = res;
            })
           }
           if(questionId === 'LITC-14'){ 
                getLicenses({appId: applicationValue, type: 'Qualified Business Administrator'}).then(res=>{
                    this.licensesC = res;
            })
           }

           if(questionId === 'LITC-15'){ 
                getOtherStaff({appId: applicationValue}).then(res=>{
                    this.otherStaff = res;
                })
           }
        }
    }

    renderedCallback(){ 
        if(!this.isRendered){ 
            if (this.question.Score__c) {
                const radio = this.template.querySelector(`input[value="${this.question.Score__c}"]`);
                if (radio) {
                    radio.checked = true;
                }
            }
        }
        this.isRendered = true;
    }

    handleReset(){ 
        console.log('in here');
        this.isLoading = true;
        updateRecord({ fields: { Id: this.question.Id, 'Score__c': null} }).then(()=>{
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('getrefresh', { detail: true }));

            const radio = this.template.querySelector(`input[value="${this.question.Score__c}"]`);
            if (radio) {
                radio.checked = false;
            }
        }).catch(error=>{
            this.isLoading = false;
            console.log(error);
        })
    }

    handleRatingChange(event){
        this.isLoading = true;
        updateRecord({ fields: { Id: this.question.Id, 'Score__c': event.target.value} }).then(()=>{
            this.isLoading = false;
            this.dispatchEvent(new CustomEvent('getrefresh', { detail: true }));
        }).catch(error=>{
            this.isLoading = false;
            console.log(error);
        })
    }

    
    handleNavigateAnswer(){ 
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.question.Id,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });  
    }

    handleChange(event){
        let data = JSON.parse(JSON.stringify(event.detail));
        if(data.questionNumber === '1')  this.question1 = data.rating; 
        if(data.questionNumber === '2')  this.question2 = data.rating; 
        if(data.questionNumber === '3')  this.question3 = data.rating; 
        if(data.questionNumber === '4')  this.question4 = data.rating; 
    }

    openPopover(event){ 
        this.fieldValue = event.target.dataset.value;
        this.showPopover= true;
    }
    closePopover(){ 
        this.showPopover = false;
    }

    handleSave(field, value){ 
        updateRecord({fields: {Id: this.question.Id, [field]: value}});
    }

    autosave(event){ 
        this.handleSave(event.target.fieldName, event.target.value);
    }

    handleNavigateToRecord(event){ 
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: this.question.Review_Card__r.NTA_Review__r.Application_for_Federal_Assistance__c,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });  
    }

    handleNavRelatedRecord(event){ 
        this[NavigationMixin.GenerateUrl]({
            type: "standard__recordPage",
            attributes: {
                recordId: event.currentTarget.dataset.value,
                actionName: 'view'
            }
        }).then(url => {
            window.open(url, "_blank");
        });  
    }


  
    togglePopover(){ 
        this.showPopoverHelp= !this.showPopoverHelp;
    }
}