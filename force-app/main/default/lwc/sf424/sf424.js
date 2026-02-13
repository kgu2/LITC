import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import utilities from 'c/utilities';
import SAM_OVERRIDE from '@salesforce/schema/Application_for_Federal_Assistance__c.Sam_gov_override__c';
import SUBMITTED_NO_UEI from '@salesforce/schema/Application_for_Federal_Assistance__c.Submitted_with_no_UEI__c';

import HAVE_UEI from '@salesforce/schema/Application_for_Federal_Assistance__c.Do_you_have_a_UEI__c';
import NO_UEI_EXPLANATION from '@salesforce/schema/Application_for_Federal_Assistance__c.Effort_on_obtaining_a_UEI__c';
import SAM_VALIDATED from '@salesforce/schema/Application_for_Federal_Assistance__c.UEI_Sam_gov_Validation_Status__c';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';


const fields = [HAVE_UEI, SAM_OVERRIDE, NO_UEI_EXPLANATION, SAM_VALIDATED, SUBMITTED_NO_UEI];


export default class Sf424 extends utilities {

    @api disableEdits;
    @api recordId;
    @api status;
    @api recordFields;
    @api deadlinePassed;
    @api areasProject;
    @api results;
    @track activeTab = "instructions";
    @track certCheckboxChecked;
    @track showHelpPopover = {};
    @track submissionErrors;
    @track prefill;
    @track role;
    @track isRendered;

    @track recordData;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    setReviewcardData({ error, data }) {
        if(data){
            this.recordData = data;
        }
        else if(error){ console.log(error);}
    }

    connectedCallback(){ 
        this.prefill = JSON.stringify({
            ContextId: this.recordId
        });
        console.log(this.prefill);

        getMyRole().then(data=>{ 
            this.role= data;
            this.isRendered= true;
        }) 
    }

    handleOnActive(event) {
        this.activeTab = event.target.value;

        // saves omniscript json on tab change
        if(this.results.data){ 
            const updateFields = { Id: this.recordId };
            const fields = this.results.data;

            // exclude formula fields
            const excludedFields = new Set([
                "Estimated_Funding_Total__c",
                "Estimated_Funding_Applicant__c",
                "Estimated_Funding_Other__c",
                "Estimated_Funding_Program_Income__c", 
                "Estimated_Funding_Federal__c"
            ]);
            
            const filteredObj = Object.fromEntries(
                Object.entries(fields).filter(([key, value]) => key.endsWith("__c") && !excludedFields.has(key))
                        // Object.entries(fields).filter(([key, value]) => key.endsWith("__c") && value !== null)
            );

            Object.entries(filteredObj).forEach(([key, value]) => {
                updateFields[key] = value;
            });

            console.log('Saving fields');
            console.log(JSON.stringify(updateFields));
            updateRecord({fields: updateFields}).then(()=>{
                 console.log('Saving omniscript json');
                 console.log(JSON.stringify(updateFields));
            }).catch(error => {
                console.error(error);
            });
        }
    }

    handleChangeTab(event){
        this.template.querySelector('lightning-tabset').activeTabValue = event.target.name;

        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
          }
        window.scrollTo(scrollOptions);

    }

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    handleSave(field, value){ 
        updateRecord({fields: {Id: this.recordId, [field]: value}});
    }

    autosave(event){ 
        this.handleSave(event.target.fieldName, event.target.value);
    }

    handleSaveButton(){ 
        this.showNotification('Saved', 'Saved', 'success');
    }

    showPopover(event) {
        this.showHelpPopover.one = event.target.name === 'iconOne'
        this.showHelpPopover.two = event.target.name === 'iconTwo'
        this.showHelpPopover.three = event.target.name === 'iconThree'
        this.showHelpPopover.four = event.target.name === 'iconFour'
        this.showHelpPopover.five = event.target.name === 'iconFive'
        this.showHelpPopover.six = event.target.name === 'iconSix'
    }

    closePopover(event){ 
        this.showHelpPopover.one = !event.target.name === 'iconOne';
        this.showHelpPopover.two = !event.target.name === 'iconTwo';
        this.showHelpPopover.three = !event.target.name === 'iconThree';
        this.showHelpPopover.four = !event.target.name === 'iconFour'
        this.showHelpPopover.five = !event.target.name === 'iconFive'
        this.showHelpPopover.six = event.target.name === 'iconSix'
    }

    handleErrorClick(event){ 
        this.activeTab = 'form';
        // setTimeout(()=>{ 
        //     if(event.detail == 'Applicant information') window.scroll({top: 100,behavior: "smooth"});
        //     if(event.detail == 'Organization unit') window.scroll({top: 800,behavior: "smooth"});
        //     if(event.detail == 'Type of applicant') window.scroll({top: 1300,behavior: "smooth"});
        //     if(event.detail == 'Congressional district / Project info') window.scroll({top: 2300,behavior: "smooth"});
        //     if(event.detail == 'Authorized representative') window.scroll({top: 3000,behavior: "smooth"});
        // })
    }

  
    // certification
    handleCheckboxCertify(event){
        this.certCheckboxChecked = event.target.checked;
    }
    handleSubmit(){ 
        if(getFieldValue(this.recordData, NO_UEI_EXPLANATION) && getFieldValue(this.recordData, HAVE_UEI) === 'No' && !getFieldValue(this.recordData, SAM_VALIDATED)){ 
            updateRecord({fields: {Id: this.recordId, 'Submitted_with_no_UEI__c': true}}).catch((err)=>{ 
                console.log(err)
            });
        }

        updateRecord({fields: {Id: this.recordId, 'SF424_Status__c': 'Submitted'}}).then(()=>{ 
            this.submissionErrors = undefined;
            
            var config = {
                icon: "success",
                title: "This form has been Submitted ",
                text: "Note: Your application is not complete until both Standard Form 424 and Form 13424 has been submitted. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
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
                {showList: true, errList: [], label: 'Applicant information'}, 
                {showList: true, errList: [], label: 'Organization unit'}, 
                {showList: true, errList: [], label: 'Type of applicant'}, 
                {showList: true, errList: [], label: 'Congressional district / Project info'},
                {showList: true, errList: [], label: 'Estimated funding'}, 
                {showList: true, errList: [], label: 'Authorized representative'}, 
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

            // let inputString = error.body.output.errors[0].message;

            // let tempErrors = [
            //     {showList: true, errList: [], label: 'Applicant information'}, 
            //     {showList: true, errList: [], label: 'Organization unit'}, 
            //     {showList: true, errList: [], label: 'Type of applicant'}, 
            //     {showList: true, errList: [], label: 'Congressional district / Project info'}, 
            //     // {showList: true, errList: [], label: 'Estimated funding'}, 
            //     {showList: true, errList: [], label: 'Authorized representative'}, 
            // ]

            // let errorLines = inputString.split('\n');

            // errorLines.forEach(val => { 
            //     tempErrors.forEach(item=>{ 
            //         if(val.includes(item.label)){ 
            //             item.errList.push(val);
            //         }
            //     });
            // });

            // tempErrors.forEach(item=>{ 
            //     if(item.errList.length == 0){ item.showList = false}
            // });

            // this.submissionErrors = tempErrors;
            
            //  console.log(error)
        })
    }
    get anyErrors(){
        return !this.certCheckboxChecked;
    }


    get resultsOne(){
         return this.results && this.results.results && this.results.results.Block_Applicant_Information === false;
    }
    get resultsTwo(){
        return this.results && this.results.results && this.results.results.Block_Organization_Unit === false;
    }
    get resultsThree(){
        return this.results && this.results.results && this.results.results.Block_Type_Of_Applicant === false;
    }
    get resultsFour(){
        return !this.areasProject;
    }
    get resultsFive(){
        return this.results && this.results.results && this.results.results.Block_Authorized_Representative === false;
    }
    get resultsSix(){
        return this.results && this.results.results && this.results.results.Block_Estimated_Funding === false;
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


    get showSubmittedNoUEI(){ 
            return getFieldValue(this.recordData, SUBMITTED_NO_UEI) && !getFieldValue(this.recordData, SAM_OVERRIDE)
    }

    // only AO and General Staff can see this tab
    get isAuthorizedOfficial(){ 
        return this.role != undefined && (this.role.includes('Authorized Official') || this.role.includes('Program Staff'))
    }
    get isNotAuthorizedOfficial(){ 
        return this.isRendered && !this.isAuthorizedOfficial;
    }
}