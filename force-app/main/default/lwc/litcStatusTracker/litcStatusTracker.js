import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';

import AA_STATUS from "@salesforce/schema/NTA_Review__c.Advocacy_Analyst_Review_Status__c";
import BA_STATUS from "@salesforce/schema/NTA_Review__c.Budget_Analyst_Review_Status__c";
import PO_STATUS from "@salesforce/schema/NTA_Review__c.Program_Office_Review_Status__c";
import RO_STATUS from "@salesforce/schema/NTA_Review__c.Reviewing_Official_Review_Status__c";

const FIELDS = [AA_STATUS, BA_STATUS, PO_STATUS, RO_STATUS];

export default class LitcStatusTracker extends LightningElement {

    @api recordId;
    
    @track aaStatus; baStatus; poStatus; roStatus;


    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.aaStatus = getFieldValue(data, AA_STATUS);
            this.baStatus = getFieldValue(data, BA_STATUS);
            this.poStatus = getFieldValue(data, PO_STATUS);
            this.roStatus = getFieldValue(data, RO_STATUS);
        }
        else if(error){ 
            console.error(error);
        }
    }


    get aaStatusSubmitted(){ 
        return this.aaStatus === 'Complete';
    }
    get aaStatusNotSubmitted(){ 
        return !this.aaStatusSubmitted;
    }

    get baStatusSubmitted(){ 
        return this.baStatus === 'Complete';
    }
    get baStatusNotSubmitted(){ 
        return !this.baStatusSubmitted;
    }

    get poStatusSubmitted(){ 
        return this.poStatus === 'Complete';
    }
    get poStatusNotSubmitted(){ 
        return !this.poStatusSubmitted;
    }

    get roStatusSubmitted(){ 
        return this.roStatus === 'Complete';
    }
    get roStatusNotSubmitted(){ 
        return !this.roStatusSubmitted;
    }
}