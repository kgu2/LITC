import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import utilities from 'c/utilities';

import FIELD_A from  '@salesforce/schema/LITC_Reporting_Form__c.X90_250_Percentage_of_New_Cases__c';
import CLINIC_TYPE from  '@salesforce/schema/LITC_Reporting_Form__c.Clinic_Type__c';
import REPORT_PERIOD from  '@salesforce/schema/LITC_Reporting_Form__c.Reporting_period__c';
import FIELD_B from  '@salesforce/schema/LITC_Reporting_Form__c.Total_Volunteer_Activties__c';
import GRANT_YEAR from  '@salesforce/schema/LITC_Reporting_Form__c.Grant_Year__c';
import CLINIC_NAME from  '@salesforce/schema/LITC_Reporting_Form__c.Name_of_Clinic__c';


import NEW_CASES from  '@salesforce/schema/LITC_Reporting_Form__c.New_Cases__c';
import TOTAL_CONSULTATIONS from  '@salesforce/schema/LITC_Reporting_Form__c.Total_Consultations__c';
import EA_TOTAL_ATTENDEES from  '@salesforce/schema/LITC_Reporting_Form__c.EA_Total_Attendees__c';
import EA_TOTAL_EVENTS from  '@salesforce/schema/LITC_Reporting_Form__c.Total_Number_Educational_Activities__c';

import generatePDF from '@salesforce/apex/LWCUploadController.generatePDF';

const fields = [FIELD_A, REPORT_PERIOD, CLINIC_TYPE, FIELD_B, GRANT_YEAR, CLINIC_NAME, NEW_CASES, TOTAL_CONSULTATIONS, EA_TOTAL_ATTENDEES, EA_TOTAL_EVENTS];


export default class litcReportingR extends utilities {

    @api disableEdits;
    @api recordId;
    @api status;
    @api recordFields;
    @api deadlinePassed;
    @api results;
    @api userName;

    @track activeTab = "instructions";
    @track certCheckboxChecked;
    @track isLoading;


    @track submissionErrors;
    @api role;
    @track isRendered;

    @track recordData;

    @track newCases; totalConsultations; totalAttendees; totalEvents;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    setReviewcardData({ error, data }) {
        if(data){
            this.recordData = data;
        }
        else if(error){ console.log(error);}
    }

    handleOnActive(event) {
        this.activeTab = event.target.value;
    }

    handleChangeTab(event){
        const visibleTabs = Array.from(this.template.querySelectorAll('lightning-tab'));

        const currentTabValue = this.template.querySelector('lightning-tabset').activeTabValue;

        const currentIndex = visibleTabs.findIndex(tab => tab.value === currentTabValue);

        const direction = event.target.label === 'Back' ? -1 : 1;
        const nextIndex = currentIndex + direction;

        this.template.querySelector('lightning-tabset').activeTabValue = visibleTabs[nextIndex].value;
        window.scrollTo({ top: 0, left: 0, behavior: 'smooth' });
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
        
        const allFields = this.template.querySelectorAll('lightning-input-field');
        const updateFields = { Id: this.recordId };

        allFields.forEach((input) => {
            if(input.required){ 
                updateFields[input.fieldName] = input.value;
            }
        });

        // save form
        console.log(JSON.stringify(updateFields));
        updateRecord({ fields: updateFields });
        console.log("SAVED");

        this.showNotification('Saved', 'Saved', 'success');
    }

 
    handleErrorClick(event){ 
        this.activeTab = event.detail;
    }

  
    // certification
    handleCheckboxCertify(event){
        this.certCheckboxChecked = event.target.checked;
    }
    handleSuccess(){ 
        console.log('in handleSuccess r form')
    }

    async handleSubmit(event){
        event.preventDefault();

        if(!this.isAuthorizedOfficial){ 
            this.showNotification('Error', 'Only Authorized Official or Program Staff may submit', 'error');
            return;
        }

        this.isLoading = true;
        console.log('in handleSubmit R form');

        let missingSections = new Set();

        // grab all fields
        const allFields = this.template.querySelectorAll('lightning-input-field');
        const updateFields = { Id: this.recordId };

        allFields.forEach((input) => {
            if(input.required){ 
                if (input.value === "" || input.value === null || input.value === undefined) {
                    console.log(input.value)
                    missingSections.add(input.dataset.section);
                }
                updateFields[input.fieldName] = input.value;
            }
        });

        // save form
        console.log(JSON.stringify(updateFields));
        await updateRecord({ fields: updateFields });
        console.log("SAVED");

        let tempErrors = [
            {showList: true, errList: [], label: 'Case information'}, 
            {showList: true, errList: [], label: 'Additional case information'}, 
            {showList: true, errList: [], label: 'Tax information'}, 
            {showList: true, errList: [], label: 'Activities'}, 
            {showList: true, errList: [], label: 'Goals / narratives'}, 
        ]
        const sectionToTabLabel = {
            caseInventory: 'Case information',
            irsFunctionOrCourt: 'Case information',
            caseIssuesWorked: 'Case information',
            statutoryRequirements: 'Case information',
            additionalCaseInformation: 'Additional case information',
            consultations: 'Case information',
            taxReturns: 'Tax information',
            ITIN: 'Tax information',
            volunteerActivities: 'Activities',
            goals: 'Goals / narratives',
            narrative: 'Goals / narratives'
        };
        const sectionLabelMap = {
            caseInventory: 'Case Inventory',
            irsFunctionOrCourt: 'IRS Function or Court',
            caseIssuesWorked: 'Case Issues Worked',
            statutoryRequirements: 'Statutory Requirements',
            additionalCaseInformation: 'Additional Case Info',
            consultations: 'Consultations',
            taxReturns: 'Tax Returns',
            ITIN: 'ITIN',
            volunteerActivities: 'Volunteer Activities',
            goals: 'Goals',
            narrative: 'Narrative'
        };

        // process validations if necessary
        if(missingSections.size > 0){ 
            console.log('processing validations');
            missingSections.forEach((sectionName) => {
                const tabLabel = sectionToTabLabel[sectionName];

                let errorMessage = 'Required fields are missing under section: ' + sectionLabelMap[sectionName];

                tempErrors.find(s => s.label === tabLabel).errList.push(errorMessage);
            });

            tempErrors.forEach(item=>{ 
                if(item.errList.length === 0){ item.showList = false}
            });
            console.log(JSON.stringify(tempErrors));
            this.submissionErrors = tempErrors;
            this.isLoading = false;
            this.showNotification('Error', 'There are errors with your submission, please review the errors on the right and resubmit', 'error');

        } else{ 
            // submit form if no validations
            console.log('submitting form');

            let grantYear = getFieldValue(this.recordData, GRANT_YEAR);
            let reportPeriod = this.isYearEnd ? 'YE' : 'INT';
            let clinicName = getFieldValue(this.recordData, CLINIC_NAME);
            let filePrefix = grantYear + '-Form13424R-' + reportPeriod + '-' + clinicName;

            await generatePDF({recordId: this.recordId, vfPageName: 'LITCReportingRPDF', prefix: filePrefix});
                
            await updateRecord({fields: {Id: this.recordId, Status__c: 'Submitted', Submission_Date__c: new Date().toISOString(), Submitted_Name__c: this.userName}});

            this.isLoading = false;
            this.submissionErrors = undefined;
            const config = {
                icon: "success",
                title: "This form has been Submitted",
                text: "The reporting record has been submitted. You will be notified if it has been accepted or returned. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
                buttons: {
                    close: {
                        text: "Close",
                    },
                },
            };
            await swal(config);
            swal.close();
        }
    }

    navigateFooter(){ 
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
            }
        })
    }

    get anyErrors(){
        return !this.certCheckboxChecked;
    }



    get tab1(){
        return this.activeTab === 'Case information' ? 'slds-show' : 'slds-hide';
    }
    get tab2(){
        return this.activeTab === 'Additional Case information' ? 'slds-show' : 'slds-hide';
    }
    get tab3(){
        return this.activeTab === 'Tax information' ? 'slds-show' : 'slds-hide';
    }
    get tab4(){
        return this.activeTab === 'Activities' ? 'slds-show' : 'slds-hide';
    }
    get tab5(){
        return this.activeTab === 'Goals / narratives' ? 'slds-show' : 'slds-hide';
    }
    get tab6(){
        return this.activeTab === 'Clinic information' ? 'slds-show' : 'slds-hide';
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


    get isInterim(){ 
        return getFieldValue(this.recordData, REPORT_PERIOD) === 'Interim report (January 1 through June 30)';
    }
    get isYearEnd(){ 
        return getFieldValue(this.recordData, REPORT_PERIOD) === 'Year-End report (January 1 through December 31)';
    }

    get isStandard(){ 
        return getFieldValue(this.recordData, CLINIC_TYPE) === 'Standard (representation, education, advocacy)';
    }
    get isESL(){ 
        return getFieldValue(this.recordData, CLINIC_TYPE) === 'English as a Second Language (ESL) education only';
    } 



    get percentGreater10(){ 
        return getFieldValue(this.recordData, FIELD_A) > 10;
    }
    get showVolunteerQuestion(){ 
        return getFieldValue(this.recordData, FIELD_B) > 0;
    }


    get isAuthorizedOfficial(){ 
        return this.role !== undefined && (this.role.includes('Authorized Official') || this.role.includes('Program Staff'))
        // return this.role !== undefined && (this.role.includes('Program Staff'))
    }

    get isNotAuthorizedOfficial(){ 
        return !this.isAuthorizedOfficial;
    }
}