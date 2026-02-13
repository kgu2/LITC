import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle } from 'lightning/platformResourceLoader';
import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import animations from '@salesforce/resourceUrl/animationsCSS';

import utilities from 'c/utilities';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';
import generatePDF from '@salesforce/apex/LWCUploadController.generatePDF';

import STATUS from  '@salesforce/schema/SF425_Form__c.Status__c';
import RECEIPTS from  '@salesforce/schema/SF425_Form__c.Receipts__c';

import ROLE from '@salesforce/schema/Contact.LITC_Role_v2__c';

import { refreshApex } from '@salesforce/apex';
import getCurrentContactInformation from '@salesforce/apex/SF425ReportingController.getCurrentContactInformation';

const fields = [STATUS, RECEIPTS];



export default class LitcReportingSF425 extends utilities {

    @track disableEdits;
    @track stylePath = portalStyles;
    @track stylePathTwo = animations;
    @api recordId;
    @track status;
    @api recordFields;
    @api deadlinePassed;
    @api results;
    @track activeTab = "instructions";
    @track certCheckboxChecked;
    @track showHelpPopover = {};
    @track submissionErrors;
    @track prefill;
    @track role;
    @track isRendered;
    @track recordData;
    @track contactData;
    @track isLoading;

    @track recordResult;

    @track recordFields = [{label: 'Report Id', fieldName : 'Name'}, {label: 'Report type', fieldName : 'Report_Type__c'}, {label: 'Form', noField : 'SF-425'}, {label: 'Deadline', fieldName : 'Submission_Deadline__c'}];


    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
            loadStyle(this, `${this.stylePathTwo}`)
        ]);
    }
    connectedCallback(){ 
        this.prefill = JSON.stringify({
            ContextId: this.recordId
        });
        console.log('prefill:', this.prefill);

        // getMyRole().then(data=>{ 
        //     console.log('getMyRole', data);
        //     this.role= data;
        //     this.isRendered= true;
        //     console.log(this.role);
        //     console.log(this.isRendered);
        //     console.log('this.role', this.role);

        // });
        // console.log('this.role', this.role);
    }
    @wire(getRecord, { recordId: '$recordId', fields: fields })
    setReportData(result) {
        this.recordData = result;
        let data = result.data;
        let error = result.error;
        if(data){
            this.recordData = data;
            console.log('data',data);
            this.noData = getFieldValue(data, RECEIPTS) == null;
            console.log('nodata', this.noData);
            this.disableEdits = getFieldValue(data, STATUS) == 'Submitted';
            this.status = getFieldValue(data, STATUS);
        }
        else if(error){ console.log(error);}
    }
    @wire(getCurrentContactInformation)
    setCurrentContactData({error,data}){
        if(data){
            this.contactData = data;
            this.role = data.LITC_Role_v2__c;
            this.isRendered = true;
            
        } else if (error){ 
            console.log(error);
        }
    }

    handleOnActive(event) {
        console.log('handleOnactive', event.target.value);
        this.activeTab = event.target.value;
        console.log(this.setReportData);
        refreshApex(this.setReportData).then(()=>{
            console.log('refreshed, setreportData')
        }).catch(error=>{
            console.log('error refreshing, setreportdata');
            console.log(error);
        });
        console.log(this.recordResult);
        refreshApex(this.recordResult).then(()=>{
            console.log('refreshed, recordResult')
        }).catch(error=>{
            console.log('error refreshing, recordResult');
            console.log(error);
        });;        // saves omniscript json on tab change
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
        console.log(this.setReportData);
        refreshApex(this.setReportData).then(()=>{
            console.log('refreshed, setreportData')
        }).catch(error=>{
            console.log('error refreshing, setreportdata');
            console.log(error);
        });
        console.log(this.recordResult);
        refreshApex(this.recordResult).then(()=>{
            console.log('refreshed, recordResult')
        }).catch(error=>{
            console.log('error refreshing, recordResult');
            console.log(error);
        });;
        
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
          }
        window.scrollTo(scrollOptions);

    }

    handleError(event){
        console.error('handle error', JSON.stringify(event.detail));
        console.error(event.detail);
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
        // setTimeout(()=>{ 
        //     if(event.detail == 'Applicant information') window.scroll({top: 100,behavior: "smooth"});
        //     if(event.detail == 'Organization unit') window.scroll({top: 800,behavior: "smooth"});
        //     if(event.detail == 'Type of applicant') window.scroll({top: 1300,behavior: "smooth"});
        //     if(event.detail == 'Congressional district / Project info') window.scroll({top: 2300,behavior: "smooth"});
        //     if(event.detail == 'Authorized representative') window.scroll({top: 3000,behavior: "smooth"});
        // })
    }
    get disableSubmit(){
        return this.disableEdits || this.noData;
    }
  
    // certification
    handleCheckboxCertify(event){
        this.certCheckboxChecked = event.target.checked;
    }
    handleSubmit(){ 
        this.isLoading = true;
        updateRecord({fields: {Id: this.recordId, Status__c: 'Submitted', Date_Submitted__c:new Date().toISOString(), 'Last_Name__c':this.contactData.LastName, First_Name__c:this.contactData.FirstName, Middle_Name__c:this.contactData.MiddleName, Title__c:this.contactData.Title, Email__c:this.contactData.Email, Telephone__c:this.contactData.Phone}}).then(()=>{ 
            this.submissionErrors = undefined;
            
            var config = {
                icon: "success",
                title: "This form has been Submitted ",
                text: "Please ensure that you have submitted your other reports for this period.\n",
                buttons: {
                    close: {
                        text: "Close",
                    },
                },
            }
            let url = generatePDF({recordId: this.recordId, vfPageName: 'SF425', prefix: 'formSF425'});
            console.log(url);

            swal(config).then(res=> { 
                swal.close();
            });
            this.isLoading = false;

        }).catch(error=>{
            console.log(error);
            let temp = error.body.output.fieldErrors;
            let tempErrors = [
                {showList: true, errList: [], label: 'SF425'}
                // {showList: true, errList: [], label: 'Applicant information'}, 
                // {showList: true, errList: [], label: 'Organization unit'}, 
                // {showList: true, errList: [], label: 'Type of applicant'}, 
                // {showList: true, errList: [], label: 'Congressional district / Project info'},
                // {showList: true, errList: [], label: 'Estimated funding'}, 
                // {showList: true, errList: [], label: 'Authorized representative'}, 
            ]

            Object.values(temp).forEach(val => { 
                console.log('val', val);
                tempErrors.forEach(item=>{ 
                    console.log('item', item);
                    if(val[0].message.includes(item.label)){ 
                        item.errList.push(val[0].message);
                    }
                });
            });

            tempErrors.forEach(item=>{ 
                if(item.errList.length == 0){ item.showList = false}
            });

            this.submissionErrors = tempErrors;
            this.isLoading = false;
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
        return this.isRendered && this.role != undefined && (this.role.includes('Authorized Official') || this.role.includes('Financial Staff'));
    }
    get isNotAuthorizedOfficial(){ 
        return this.isRendered && !this.isAuthorizedOfficial;
    }
    navigateFooter(){ 
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
            }
        })
    }

}