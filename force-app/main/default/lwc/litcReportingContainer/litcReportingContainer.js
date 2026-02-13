import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord, createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import animations from '@salesforce/resourceUrl/animationsCSS';
import CONFETTI from "@salesforce/resourceUrl/confettiJS";
import SWEETALERT from "@salesforce/resourceUrl/sweetAlertJS";
import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import STATUS from '@salesforce/schema/LITC_Reporting_Form__c.Status__c';
import DEADLINE from '@salesforce/schema/LITC_Reporting_Form__c.Submission_Deadline__c';
import utilities from 'c/utilities';
import REPORT_TYPE from '@salesforce/schema/LITC_Reporting_Form__c.Record_Type_Name__c';
import REPORT_PERIOD from '@salesforce/schema/LITC_Reporting_Form__c.Reporting_period__c';

import getCurrentContactInformation from '@salesforce/apex/LITCReportingController.getCurrentContactInformation';

import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';

const FIELDS = [STATUS, REPORT_TYPE, DEADLINE, REPORT_PERIOD];



export default class LitcReportingContainer extends utilities {
    @api recordId;
    @track stylePath = portalStyles;
    @track stylePathTwo = animations;
    @track disableEdits;
    @track reportType;
    @track reportPeriod;
    @track userName;
    @track role;

    @track recordFields = [{label: 'Report Id', fieldName : 'Name'}, {label: 'Report period', fieldName : 'Reporting_period__c'}, {label: 'Form', noField : ''}, {label: 'Deadline', fieldName : 'Submission_Deadline__c'}];

    constructor() {
        super(); 
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
            loadStyle(this, `${this.stylePathTwo}`), 
            loadScript(this, CONFETTI),
            loadScript(this, SWEETALERT), 
        ]).catch(error => {
                console.log(error)
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.status = getFieldValue(data, STATUS);
            this.disableEdits = this.status === 'Submitted';
            this.reportType = getFieldValue(data, REPORT_TYPE);
            this.reportPeriod = getFieldValue(data, REPORT_PERIOD);

            this.recordFields = [
                {label: 'Report Id', fieldName : 'Name'}, 
                {label: 'Form', noField : this.reportType}, 
                {label: 'Clinic name', fieldName : 'Name_of_Clinic__c'}, 
                {label: 'Grant Year', fieldName : 'Grant_Year__c'}, 
                {label: 'Type of Clinic', fieldName : 'Clinic_Type__c'}, 
                {label: 'Report period', fieldName : 'Reporting_period__c'}, 
                {label: 'Deadline', fieldName : 'Submission_Deadline__c'},
            ];

            let currentDate = Date.parse(new Date().toLocaleString());
            let deadline = Date.parse(getFieldValue(data, DEADLINE));
            this.deadlinePassed = currentDate > deadline;
        }
        else if(error){ 
            console.error(error);
        }
    }

    @wire(getCurrentContactInformation)
    setCurrentContactData({error,data}){
        if(data){
            this.userName = data.Name;
        } else if (error){ 
            console.log(error);
        }
    }

    connectedCallback(){ 
        getMyRole().then(data=>{ 
            this.role= data;
        }) 
    }

    get form13424R(){ 
        return this.reportType === 'Form 13424-R';
    }
    get form13424L(){ 
        return this.reportType === 'Form 13424-L';
    }
}