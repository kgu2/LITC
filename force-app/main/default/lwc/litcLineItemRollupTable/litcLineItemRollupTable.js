import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import styles from '@salesforce/resourceUrl/LITCOmniscriptStyles';
import FED_EXP from '@salesforce/schema/Application_for_Federal_Assistance__c.Total_Federal_Expenses__c';
import MATCH_EXP from '@salesforce/schema/Application_for_Federal_Assistance__c.Total_Match_Expenses__c';
import TOTAL_EXP from '@salesforce/schema/Application_for_Federal_Assistance__c.Total_Expenses__c';

import APP_ID from '@salesforce/schema/Staff_Review__c.Application_for_Federal_Assistance__c';


import FED_EXP2 from '@salesforce/schema/LITC_Reporting_Form__c.Total_Federal_Expenses__c';
import MATCH_EXP2 from '@salesforce/schema/LITC_Reporting_Form__c.Total_Match_Expenses__c';
import TOTAL_EXP2 from '@salesforce/schema/LITC_Reporting_Form__c.Total_Expenses__c';

const FIELDS = [FED_EXP, MATCH_EXP, TOTAL_EXP];
const STAFF_FIELDS = [APP_ID];
const FIELDS2 = [FED_EXP2, MATCH_EXP2, TOTAL_EXP2];



export default class LitcLineItemRollupTable extends LightningElement {
    @api recordId;
    @api reportId;
    @api staffReviewRecordId;
    @api isReportReview;
    @api isStaffReview;
    @track appId;

    stylePath = styles;

    @track fedExp; 
    matchExp; totalExp;

    constructor() {
        super();
        Promise.all([
          loadStyle(this, `${this.stylePath}`),
        ]).catch(error => {
              console.log(error)
        });
    }

    connectedCallback(){ 
        console.log('in connectedCallback');
        console.log(this.isReportReview)

        if(this.isReportReview){ 
            this.reportId = this.recordId;
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    getData1({error, data}) {
        if (data) {
            console.log('test 1 ');
            console.log(data);
            this.fedExp = getFieldValue(data, FED_EXP);
            this.matchExp = getFieldValue(data, MATCH_EXP);
            this.totalExp = getFieldValue(data, TOTAL_EXP);
        }
        else if(error){ 
            console.error(error);
        }
    }

    @wire(getRecord, { recordId: '$reportId', fields: FIELDS2 })
    getData2({error, data}) {
        if (data) {
            console.log('test 2 ');
            console.log(data);
            this.fedExp = getFieldValue(data, FED_EXP2);
            this.matchExp = getFieldValue(data, MATCH_EXP2);
            this.totalExp = getFieldValue(data, TOTAL_EXP2);
        }
        else if(error){ 
            console.error(error);
        }
    }

    @wire(getRecord, { recordId: '$recordId', fields: STAFF_FIELDS })
    getData({error, data}) {
        if (data) {
            if(!this.isReportReview){ 
                console.log('test 3');
                console.log(data);
                this.appId = getFieldValue(data, APP_ID);
                this.recordId = this.appId;
            }
        }
        else if(error){ 
            console.error(error);
        }
    }


    get myRecId(){ 
        return this.isStaffReview ? this.appId : this.reportId ? this.reportId : this.recordId;
    }


    get myObjectName(){ 
        return this.reportId ? 'LITC_Reporting_Form__c' : 'Application_for_Federal_Assistance__c';
    }
    

    get colorSum(){ 
        return 'blue';
        // return this.reportId ? 'blue' : 'cyan';
    }

}