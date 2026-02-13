import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import utilities from 'c/utilities';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';
import APP from '@salesforce/schema/LITC_Reporting_Form__c.Application_for_Federal_Assistance__c';
import RETURN_FUNDS from '@salesforce/schema/LITC_Reporting_Form__c.Return_Grant_Funds__c';
import REQUEST_FUNDS from '@salesforce/schema/LITC_Reporting_Form__c.Request_additional_funds__c';
import generatePDF from '@salesforce/apex/LWCUploadController.generatePDF';
import GRANT_YEAR from  '@salesforce/schema/LITC_Reporting_Form__c.Grant_Year__c';
import CLINIC_NAME from  '@salesforce/schema/LITC_Reporting_Form__c.Name_of_Clinic__c';
const fields = [APP, RETURN_FUNDS, REQUEST_FUNDS, GRANT_YEAR, CLINIC_NAME];

import FILE from "@salesforce/resourceUrl/LITCJFormInstructions";

export default class litcReportingL extends utilities {

    @api role;
    @api disableEdits;
    @api recordId;
    @api status;
    @api recordFields;
    @api deadlinePassed;
    @api results;
    @api reportPeriod;
    @api userName;

    @track activeTab = "instructions";
    @track certCheckboxChecked;


    @track submissionErrors;
    @track isRendered;

    @track recordData;

    @track appId;

    @track fileLink = FILE;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    setReviewcardData({ error, data }) {
        if(data){
            this.recordData = data;
            this.appId = getFieldValue(data, APP);
        }
        else if(error){ console.log(error);}
    }

    handleOnActive(event) {
        this.activeTab = event.target.value;
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

 
    handleErrorClick(event){ 
        this.activeTab = 'form';
    }

  
    // certification
    handleCheckboxCertify(event){
        this.certCheckboxChecked = event.target.checked;
    }

    async handleSubmit(){ 

        if(!this.isAuthorizedOfficial){ 
            this.showNotification('Error', 'Only Authorized Official or Program Staff may submit', 'error');
            return;
        }

        const inputFields = this.template.querySelectorAll('lightning-input-field');

        let missingField = false;

        inputFields.forEach((input) => {
            if(input.fieldName !== 'Full_Time_Equivalent_Hours__c' && input.value === null || input.value === undefined) { 
                console.log(input.fieldName);
                missingField = true;
            }
        });

        if(missingField){
            this.showNotification('Error', 'All required fields must be filled out', 'error');
            this.activeTab = 'form';
        } else{ 
            this.isLoading = true;

            let grantYear = getFieldValue(this.recordData, GRANT_YEAR);
            let reportPeriod = this.isYearEnd ? 'YE' : 'INT';
            let clinicName = getFieldValue(this.recordData, CLINIC_NAME);
            let filePrefix = grantYear + '-Form13424L-' + reportPeriod + '-' + clinicName;

            await generatePDF({recordId: this.recordId, vfPageName: 'LITCReportingLPDF', prefix: filePrefix});

            updateRecord({fields: {Id: this.recordId, 'Status__c': 'Submitted', Submission_Date__c: new Date().toISOString(), Submitted_Name__c: this.userName}}).then(()=>{ 
                this.submissionErrors = undefined;
                this.isLoading = false;
                
                let config = {
                    icon: "success",
                    title: "This form has been Submitted ",
                    text: "The reporting record has been submitted. You will be notified if it has been accepted or returned. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
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
            })
            }
    }

    async handleSuccess(){ 
        console.log('in litcReportingL handle success')
        // this.isLoading = true;

        // await generatePDF({recordId: this.recordId, vfPageName: 'LITCReportingLPDF', prefix: 'form13424L'});

        // updateRecord({fields: {Id: this.recordId, 'Status__c': 'Submitted', Submission_Date__c: new Date().toISOString(), Submitted_Name__c: this.userName}}).then(()=>{ 
        //     this.submissionErrors = undefined;
        //     this.isLoading = false;
            
        //     let config = {
        //         icon: "success",
        //         title: "This form has been Submitted ",
        //         text: "The reporting record has been submitted. You will be notified if it has been accepted or returned. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
        //         buttons: {
        //             close: {
        //                 text: "Close",
        //             },
        //         },
        //     }
        //     swal(config).then(res=> { 
        //         swal.close();
        //     })
        // }).catch(error=>{
        //     console.log(error);    
        // })
    }
    get anyErrors(){
        return !this.certCheckboxChecked;
    }


    @track showOldTable;
    handleToggle(){ 
        this.showOldTable = !this.showOldTable
    }

    navigateFooter(){ 
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
            }
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


    get showReturnFundsYes(){ 
        return getFieldValue(this.recordData, RETURN_FUNDS) === 'Yes';
    }

    get showRequestFundsYes(){ 
        return getFieldValue(this.recordData, REQUEST_FUNDS) === 'Yes';
    }


  

    get form(){
        return this.activeTab === 'form' ? 'slds-show' : 'slds-hide';
    }
    get jForm(){
        return this.activeTab === 'jForm' ? 'slds-show' : 'slds-hide';
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


    get isYearEnd(){
        return this.reportPeriod === 'Year-End report (January 1 through December 31)';
     }  



    get isAuthorizedOfficial(){ 
        return this.role !== undefined && (this.role.includes('Authorized Official') || this.role.includes('Financial Staff'))
    }

    get isNotAuthorizedOfficial(){ 
        return !this.isAuthorizedOfficial;
    }
    

}