import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import utilities from 'c/utilities';
import TOTAL_B from '@salesforce/schema/Application_for_Federal_Assistance__c.Total_Matching_Funds__c';
import TOTAL_A from '@salesforce/schema/Application_for_Federal_Assistance__c.Total_Match_Dollar_Combined__c';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';
import getStaffReview from '@salesforce/apex/ApplicationFederalAssistanceController.getStaffReview'; 
import getNTAReview from '@salesforce/apex/ApplicationFederalAssistanceController.getNTAReview'; 
import FED_EXP from '@salesforce/schema/Application_for_Federal_Assistance__c.Total_Federal_Expenses__c';

import FILE from "@salesforce/resourceUrl/LITCJFormInstructions";

const FIELDS = [TOTAL_A, TOTAL_B, FED_EXP];

export default class Form13424J extends utilities {

    @api recordId;
    @api status;
    @api appStatus;
    @api recordFields;
    @api deadlinePassed;
    @api disableEdits;
    @api results;
    @track activeTab = "instructions";
    @track showHelpPopover = {};
    @track submissionErrors;
    @track certCheckboxChecked;
    @track prefill;
    @track activeSections= ['overview'];
    @track showValidationModal;
    @track fteValue;
    @track fileLink = FILE;

    @track totalA; totalB;
    @track role;
    @track isRendered;

    fundingAmount; fundingExplanation; fundingConditions;
    fieldA; fieldB; fieldC; fieldD; fieldE; fieldF; fieldG; fieldH;

    @track showBAModal;

    @track fedExpenses;

    connectedCallback(){
        getMyRole().then(data=>{ 
            this.role= data;
            this.isRendered= true;
        }) 

        this.prefill = JSON.stringify({
            ContextId: this.recordId
        });

        getNTAReview({appId: this.recordId}).then(res=>{
            console.log(res)
            this.fundingAmount= res[0].NTA_Award_Amount__c;
            this.fundingExplanation = res[0].Funding_Decision_Reason__c;
            this.fundingConditions = res[0].NTA_Conditions__c;
        }).catch(err=>{
                console.log(err)
        })

        getStaffReview({appId: this.recordId}).then(res=>{ 
            console.log(res)
            this.fieldA = res[0].Personnel__c;
            this.fieldB = res[0].Fringe_Benefits__c;
            this.fieldC = res[0].Travel__c;
            this.fieldD = res[0].Equipment__c;
            this.fieldE = res[0].Supplies__c;
            this.fieldF = res[0].Contractual__c;
            this.fieldG = res[0].Other_Expenses__c;
            this.fieldH = res[0].Indirect_Charges__c;
            this.fieldI = res[0].Matching_Fund__c;
        }).catch(err=>{ 
            console.log(err)
        })
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.totalA = getFieldValue(data, TOTAL_A);
            this.totalB = getFieldValue(data, TOTAL_B);
            this.fedExpenses = getFieldValue(data, FED_EXP);
        }
        else if(error){ 
            console.error(error);
        }
    }

    handleOnActive(event) {
        this.activeTab = event.target.value;
    }

    handleChangeTab(event){
        this.template.querySelector('lightning-tabset').activeTabValue = event.target.name;
        this.template.querySelector('.form').submit();
        
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
          }
        window.scrollTo(scrollOptions);

        if(this.fteValue) updateRecord({fields: {Id: this.recordId, Full_Time_Equivalent_Hours__c: this.fteValue}})
    }

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    handleSave(field, value){ 
        updateRecord({fields: {Id: this.recordId, [field]: value}}).then(()=>{ 
            this.template.querySelector('.table').refreshFromParent();
        })
    }

    autosave(event){ 
        this.handleSave(event.target.fieldName, event.target.value);
        if(event.target.fieldName === 'Full_Time_Equivalent_Hours__c') this.fteValue = event.target.value;
    }

    showPopover(event) {
        this.showHelpPopover.one = event.target.name === 'iconOne'
        this.showHelpPopover.two = event.target.name === 'iconTwo'
        this.showHelpPopover.three = event.target.name === 'iconThree'
    }

    closePopover(event){ 
        this.showHelpPopover.one = !event.target.name === 'iconOne';
        this.showHelpPopover.two = !event.target.name === 'iconTwo';
        this.showHelpPopover.three = !event.target.name === 'iconThree';
    }

    handleSaveButton(){ 
        this.showNotification('Saved', 'Saved', 'success');
    }

    handleCheckboxCertify(event){
        this.certCheckboxChecked = event.target.checked;
    }
    handleSubmit(){ 

        if(this.isStatusAmended){ 
            if(Number.parseFloat(this.fedExpenses).toFixed(2) !== Number.parseFloat(this.fundingAmount).toFixed(2)){ 
                this.showNotification('Error', 'Total federal expenses must be equal to funding amount of $' + this.fundingAmount, 'error');
                return;
            }
        }
    

        updateRecord({fields: {Id: this.recordId, 'Form_13424_J_Status__c': 'Submitted'}}).then(()=>{ 
            this.submissionErrors = undefined;
            
            var config = {
                icon: "success",
                title: "This form has been Submitted ",
                text: "Note: your application is not complete until all other forms have been submitted. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
                buttons: {
                    close: {
                        text: "Close",
                    },
                },
            }
            swal(config).then(res=> { 
                swal.close();
            })
        }).catch(error=>{
           console.log(error);
           let temp = error.body.output.fieldErrors;
           let tempErrors = [
               {showList: true, errList: [], label: 'Indirect expenses'}, 
           ]

           Object.values(temp).forEach(val => { 
               tempErrors.forEach(item=>{ 
                   if(val[0].message.includes(item.label)){ 
                       item.errList.push(val[0].message);
                   }
               });
           });

           tempErrors.forEach(item=>{ 
               if(item.errList.length == 0){ item.showList = false}
           });

           this.submissionErrors = tempErrors;
    
        })
    }

    handleClick(event){
        let baseUrl = 'https://' + location.host;
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: baseUrl + event.target.dataset.url
            }
        }, false);
    }

    openValidationModal(){ 
        this.showValidationModal = true;
    }
    closeValidationModal(){ 
        this.showValidationModal = false;
    }

    openBAModal(){ 
        this.showBAModal= true;
    }
    closeBAModal(){ 
        this.showBAModal= false;
    }

    get colorTotalMatch(){ 
        return this.totalB >= this.totalA ? 'color: #4DA264' : 'color: #CC8E00';
        // return this.totalA === this.totalB ? 'color: #4DA264' : 'color: #CC8E00';
    }
    get isTotalMatch(){ 
        // return this.totalA === this.totalB;
        return this.totalB >= this.totalA;
    }
    get isNotTotalMatch(){ 
        // return this.totalA !== this.totalB;
        return this.totalB < this.totalA;
    }
    
    get anyErrors(){
        return !this.certCheckboxChecked || this.isNotTotalMatch;
    }

    get form(){
        return this.activeTab === 'form' ? 'slds-show' : 'slds-hide';
    }
    get submission(){
        return this.activeTab === 'submission' ? 'slds-show' : 'slds-hide';
    }
    get instructions(){
        return this.activeTab === 'instructions' ? 'slds-show' : 'slds-hide';
    }
    get isSubmitted(){
        return this.disableEdits === true;
    }

    // ONLY AO AND Financial Staff can see J form
    get isAuthorizedOfficial(){ 
        return this.role != undefined && (this.role.includes('Authorized Official') || this.role.includes('Financial Staff'))
        // return this.role === 'Authorized Official' || this.role === 'Financial Staff';
    }
    get isNotAuthorizedOfficial(){ 
        return this.isRendered && !this.isAuthorizedOfficial;
    }

    get isStatusAmended(){ 
        return this.appStatus === 'Amendment In Progress';
    }

}