import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import utilities from 'c/utilities';
import FORM13424M_STATUS from '@salesforce/schema/Application_for_Federal_Assistance__c.Form_13424_Status__c';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';
import getStaffReview from '@salesforce/apex/ApplicationFederalAssistanceController.getStaffReview'; 
import getNTAReview from '@salesforce/apex/ApplicationFederalAssistanceController.getNTAReview'; 

export default class Form13424 extends utilities {

    @api recordId;
    @api status;
    @api appStatus;
    @api recordFields;
    @api deadlinePassed;
    @api disableEdits;
    @api results;
    @api applicationType;
    @api version;
    @api legacyAppId;
    @api legacyResults;
    @api legacyResultsM;
    @track activeTab = "instructions";
    // @track errors = {sectionOne : null, sectionTwo : null, sectionThree : null};
    @track showHelpPopover = {};
    @track submissionErrors;
    @track certCheckboxChecked;
    @track prefill;
    @track role;
    @track isRendered;

    fundingAmount; fundingExplanation; fundingConditions;
    fieldA; fieldB; fieldC; fieldD; fieldE; fieldF; fieldG; fieldH;

    @track showBAModal;

    connectedCallback(){ 
        if(this.version === 'Legacy'){ 
            this.prefill = JSON.stringify({
                ContextId: this.legacyAppId
            });
        } else{ 
            this.prefill = JSON.stringify({
                ContextId: this.recordId
            });
        }

        getMyRole().then(data=>{ 
            this.role= data;
            this.isRendered= true;
        }) 


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

    handleOnActive(event) {
        this.activeTab = event.target.value;

        if(this.isNew){ 
            console.log(this.results);
        
            if(this.results.data){ 
                const updateFields = { Id: this.recordId };
                const fields = this.results.data;
    
        
                const filteredObj = Object.fromEntries(
                    // can not updateRecord for checkbox fields with value = null**
                    // Object.entries(fields).filter(([key, value]) => key.endsWith("__c"))
                    Object.entries(fields).filter(([key, value]) => key.endsWith("__c") && value !== null)
                );
                Object.entries(filteredObj).forEach(([key, value]) => {
                    updateFields[key] = value;
                });
    
                console.log('Saving fields');
                console.log(JSON.stringify(updateFields));
    
                updateRecord({fields: updateFields}).then(()=>{
                     console.log('Saving omniscript json');
                }).catch(error => {
                    console.error(error);
                });
            }
        } else{ 
            this.handleLegacyResults();
        }
    }

    openBAModal(){ 
        this.showBAModal= true;
    }
    closeBAModal(){ 
        this.showBAModal= false;
    }

    handleLegacyResults(){ 
        if(this.legacyResults.data){ 

            const updateFields = { Id: this.legacyAppId };
            const fields = this.legacyResults.data;

            const filteredObj = Object.fromEntries(
                Object.entries(fields).filter(([key, value]) => key.endsWith("__c") && value !== null)
            );
            Object.entries(filteredObj).forEach(([key, value]) => {
                updateFields[key] = value;
            });

            console.log(JSON.stringify(updateFields));

            updateRecord({fields: updateFields}).then(()=>{
                 console.log('Saving omniscript json');
            }).catch(error => {
                console.error(error);
            });
        }

        if(this.legacyResultsM.data){ 
            const updateFields = { Id: this.legacyAppId };
            const fields = this.legacyResultsM.data;
    
            const filteredObj = Object.fromEntries(
                Object.entries(fields).filter(([key, value]) => key.endsWith("__c") && value !== null)
            );
            Object.entries(filteredObj).forEach(([key, value]) => {
                updateFields[key] = value;
            });

            console.log(JSON.stringify(updateFields));
            updateRecord({fields: updateFields}).then(()=>{
                 console.log('Saving omniscript json');
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
        updateRecord({fields: {Id: this.recordId, 'Form_13424_Status__c': 'Submitted'}}).then(()=>{ 
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
            if(this.isNew){ 
                let temp = error.body.output.fieldErrors;
                let tempErrors = [
                    {showList: true, errList: [], label: 'Clinic information'}, 
                    {showList: true, errList: [], label: 'Background'}, 
                    {showList: true, errList: [], label: 'Taxpayer access, geographic area and target audience, outreach strategy'}, 
                    {showList: true, errList: [], label: 'Taxpayer services'}, 
                    {showList: true, errList: [], label: 'Staffing'}, 
                    {showList: true, errList: [], label: 'Volunteers'}, 
                    {showList: true, errList: [], label: 'Clinic operations'}, 
                    {showList: true, errList: [], label: 'Training and resources'}, 
                    {showList: true, errList: [], label: 'Financial responsibility'}, 
                    {showList: true, errList: [], label: 'Program information'}, 
                    {showList: true, errList: [], label: 'Civil rights information'}, 
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
            } else{ 
                this.handleDisplayValidationsLegacy(error);
            }
        })
    }

    handleDisplayValidationsLegacy(error){ 
        let inputString = error.body.output.errors[0].message;

        let tempErrors = [
            {showList: true, errList: [], label: 'Applicant information'}, 
            {showList: true, errList: [], label: 'Clinic information'}, 
            {showList: true, errList: [], label: 'Experience'}, 
            {showList: true, errList: [], label: 'Financial responsibility'}, 
            {showList: true, errList: [], label: 'Program staff'}, 
            {showList: true, errList: [], label: 'Taxpayer services'}, 
            {showList: true, errList: [], label: 'Clinic operations'}, 
            {showList: true, errList: [], label: 'Training and resources'}, 
            {showList: true, errList: [], label: 'Program monitoring, evaluation, and reporting'}, 
            {showList: true, errList: [], label: 'Program numerical goals'}, 
            {showList: true, errList: [], label: 'Civil rights review'}, 
        ]

        let errorLines = inputString.split('\n');

        errorLines.forEach(val => { 
            tempErrors.forEach(item=>{ 
                if(val.includes(item.label)){ 
                    item.errList.push(val);
                }
            });
        });

        tempErrors.forEach(item=>{ 
            if(item.errList.length == 0){ item.showList = false}
        });

        this.submissionErrors = tempErrors;
    }
    
    get anyErrors(){
        return !this.certCheckboxChecked;
    }

    get resultsOne(){
        return this.results && this.results.results && this.results.results.Block_Clinic_Information === false;
    }
    get resultsTwo(){
        return this.results && this.results.results && this.results.results.Block_Taxpayer_Access === false;
    }
    get resultsThree(){
        return this.results && this.results.results && this.results.results.Block_Taxpayer_Services === false;
    }
    get resultsFour(){
        return this.results && this.results.results && this.results.results.Block_Staffing === false;
    }
    get resultsFive(){
        return this.results && this.results.results && this.results.results.Block_Volunteers === false;
    }
    get resultsSix(){
        return this.results && this.results.results && this.results.results.Block_Clinic_Operations === false;
    }
    get resultsSeven(){ 
        return this.results && this.results.results && this.results.results.Block_Background === false;
    }
    get resultsEight(){ 
        return this.results && this.results.results && this.results.results.Block_Training_Resources === false;
    }
    get resultsNine(){ 
        return this.results && this.results.results && this.results.results.Block_Financial_Responsibility === false;
    }
    get resultsTen(){ 
        return this.results && this.results.results && this.results.results.Block_Program_Information === false;
    }
    get resultsEleven(){ 
        return this.results && this.results.results && this.results.results.Block_Civil_Rights === false;
    }

    get legacyResultsOne(){ 
        return this.legacyResults && this.legacyResults.results && this.legacyResults.results.Block_Applicant_Information === false;
    }
    get legacyResultsTwo(){ 
        return this.legacyResults && this.legacyResults.results && this.legacyResults.results.Block_Clinic_Information === false;
    }
    get legacyResultsThree(){ 
        return this.legacyResultsM && this.legacyResultsM.results && this.legacyResultsM.results.Background_Information === false;
    }
    get legacyResultsFour(){ 
        return this.legacyResultsM && this.legacyResultsM.results && this.legacyResultsM.results.Block_Program_Performance_Plan === false;
    }
    get legacyResultsFive(){ 
        return this.legacyResultsM && this.legacyResultsM.results && this.legacyResultsM.results.Block_Civil_Rights_Review === false;
    }

    get form(){
        return this.activeTab === 'form' ? 'slds-show' : 'slds-hide';
    }
    get formLegacy(){
        return this.activeTab === 'formLegacy' ? 'slds-show' : 'slds-hide';
    }
    get formLegacyM(){
        return this.activeTab === 'formLegacyM' ? 'slds-show' : 'slds-hide';
    }
    get submission(){
        return this.activeTab === 'submission' ? 'slds-show' : 'slds-hide';
    }
    get instructions(){
        return this.activeTab === 'instructions' ? 'slds-show' : 'slds-hide';
    }
    
    get isContinuation(){ 
        return this.applicationType === 'Continuation';
    }

    get isSubmitted(){
         return this.disableEdits === true;
    }



    get isLegacy(){ 
        return this.version === 'Legacy';
    }
    get isNew(){ 
        return !this.isLegacy;
    }

    // only AO and General Staff can see this tab
    get isAuthorizedOfficial(){ 
        return this.role != undefined && (this.role.includes('Authorized Official') || this.role.includes('Program Staff'))
    }
    get isNotAuthorizedOfficial(){ 
        return this.isRendered && !this.isAuthorizedOfficial;
    }

    get isStatusAmended(){ 
        return this.appStatus === 'Amendment In Progress';
    }

}