import { LightningElement, wire, api, track } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/X605_Application__c.Status__c';
import STATUS_ONE from '@salesforce/schema/X605_Application__c.Cert_Status__c';
import STATUS_TWO from '@salesforce/schema/X605_Application__c.CREC_Status__c';
import SHOWWELCOME from '@salesforce/schema/X605_Application__c.Show_Welcome__c';
import RECIPTYPE from '@salesforce/schema/X605_Application__c.Type_of_Recipient__c';
import { NavigationMixin } from 'lightning/navigation';
import portalStyles from '@salesforce/resourceUrl/SLFRFPortalStyles';
import { loadStyle } from 'lightning/platformResourceLoader';
import logoAboveVertNavSLFRF from '@salesforce/resourceUrl/app605Card';
import WelcomeSplash from '@salesforce/resourceUrl/WelcomeSplash';
import X2T_TRANCHE from '@salesforce/schema/X605_Application__c.X2nd_Tranche__c';
import getWelcome from '@salesforce/apex/app605Controller.getWelcomeField';

const FIELDS = [STATUS, SHOWWELCOME, RECIPTYPE, STATUS_ONE, STATUS_TWO, X2T_TRANCHE];

export default class App605Tabset extends NavigationMixin(LightningElement) {

    @api recordId;
    @api disableEdits;
    @track recipType;
    @track stylePath = portalStyles;
    @track slfrfCard = logoAboveVertNavSLFRF;
    // @track welcomeSplash = WelcomeSplash;
    @track application;
    @track showHelpPopover = false;
    @track showWelcome;

    // progress ring
    @track progress;
    @track isSaved;
    @track isSaving;

    // accordian infobox
    @track status;
    @track statusOne;
    @track statusTwo;
    @track errors;
    @track fields = [{label: 'Submission Type', noField: 'LATCF'},  {label: 'Submission Name', fieldName : 'Name'}, {label: 'First Tranche Amount Obligated', fieldName : 'FY22_Amount_Obligated__c'}, {label: 'Total Allocation Amount', fieldName : 'Total_Funds_Obligated__c'}];
    @track X2T_fields = [{label: 'Submission Type', noField: 'LATCF (2nd Tranche)'},  {label: 'Submission Name', fieldName : 'Application_Name__c'}, {label: 'Second Tranche Amount Obligated', fieldName : 'FY23_Amount_Obligated__c'}, {label: 'Total Allocation Amount', fieldName : 'Total_Funds_Obligated__c'}];
    @track recordFields;

    @track activeTab="instructions";

    @track X2Tranche;

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.application = data;
            this.status = getFieldValue(this.application, STATUS);
            this.statusOne = getFieldValue(this.application, STATUS_ONE);
            this.statusTwo = getFieldValue(this.application, STATUS_TWO);
            this.recipType = getFieldValue(this.application, RECIPTYPE);
            this.X2Tranche = getFieldValue(this.application, X2T_TRANCHE);

            this.recordFields = this.X2Tranche ? this.X2T_fields : this.fields;

            if(this.status === 'Draft'){ 
                updateRecord({ fields: {Id: this.recordId, Status__c: 'Incomplete'} }).then(() => {
                }).catch(error=>{
                    console.error(error);
                })
            }


            updateRecord({ fields: {Id: this.recordId, Recipient_Type__c: this.recipType} }).then(() => {
            }).catch(error=>{
                console.error(error);
            })
        }

        else if(error){ 
            console.error(error);
        }
    }

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;

        if (currentPageReference.state) {
            this.activeTab = currentPageReference.state.c__activeTab;
        }
    }

    connectedCallback(){ 
        //console.log(this.recordId);
        getWelcome({ recordId: this.recordId}).then((data)=>{ 
            this.showWelcome = data;
        }).catch(error=>{ 
            console.error(error);
        })
    }

    handleOnActive(event) {
        event.preventDefault();
        event.stopPropagation();
        if (this.activeTab !== event.target.value) {
            this.activeTab = event.target.value;

            if(this.activeTab == 'form') { 
                const formTab = this.template.querySelector("c-app-605-form");
                //console.log(formTab)
                formTab.refreshFromAnotherTab();
            }

            this[NavigationMixin.Navigate](
                this.getUpdatedPageReference({
                    c__activeTab: this.activeTab
                }),true 
            );


        }

        
    }

    getUpdatedPageReference(stateChanges) {
        return Object.assign({}, this.currentPageReference, {
            state: Object.assign(
                {},
                this.currentPageReference.state,
                stateChanges
            )
        });
    }

    handleChangeTab(event){
        this.template.querySelector('lightning-tabset').activeTabValue = event.detail;
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
          }
        window.scrollTo(scrollOptions);
    }

    handleProgress(event){ 
        //console.log('in get progress');
        this.progress = event.detail;
        //console.log(this.progress);
    }

    handleGetSave(event){ 
        //console.log('in here')
        this.isSaving = event.detail.isSaving;
        this.isSaved = event.detail.isSaved;
    }

    constructor() {
        super();
        Promise.all([
          loadStyle(this, `${this.stylePath}`),
        ]);
      }

    
    get disableEdits() {
        return getFieldValue(this.application, STATUS) == 'Draft' || getFieldValue(this.application, STATUS) == 'Incomplete' || getFieldValue(this.application, STATUS) == 'Failed Payee Verification Review' ? false : true;
    }

    togglePopover(){
        this.showHelpPopover = !this.showHelpPopover;
    }
    
    get instructions(){
        return this.activeTab == 'instructions' ? 'slds-show' : 'slds-hide';
    }
    get form(){
        // this is to make refresh from another tab work
        return this.activeTab == 'form' ? 'slds-show' : 'slds-hide';
    }
    get certification(){
        return this.activeTab == 'certification' ? 'slds-show' : 'slds-hide';
    }
    get CREC(){
        return this.activeTab =='CREC' ? 'slds-show': 'slds-hide';
    }
    get notForm(){
        if(this.activeTab=='form'){
            return "opacity:100;";
        }else{
            return "opacity:0;"
        }
    }

    get isForm(){ 
        return this.activeTab == 'form';
    }

    get progressStyle(){
        if(this.progress==100){
            return "display: inline-block; margin-left:5px; transition:none !important;"
        }
        else{
            return "display: inline-block; margin-left:5px;"
        }
    }

    get isComplete(){
        return this.progress == 100;
    }

    closeWelcome(){ 
        this.showWelcome = false;
    }

    handleDontShow(event){ 
        const fields = { Id: this.recordId, Show_Welcome__c: false };
        updateRecord({ fields: fields });
    }

    handleGetErrors(event){ 
        this.errors = event.detail;
        console.error(this.errors);
    }

    handleErrorClick(event){ 
        console.error(event.detail);
        // this.activeTab = 'form';
    }

    get splash() {
        return `height:600px; width:800px; background-image:url(${WelcomeSplash})`;
    }

    get certTabText(){ 
        if(this.X2Tranche){ 
            return 'Affirmation';
        }
        return this.recipType == 'Eligible Revenue Sharing County' ? 'Certification' : 'Certification and Agreement';
    }
}