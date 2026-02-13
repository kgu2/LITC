import { LightningElement, api, track, wire } from 'lwc';
import { getPicklistValues } from "lightning/uiObjectInfoApi";
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import OBJECT from '@salesforce/schema/Application_for_Federal_Assistance__c';
import STATE from "@salesforce/schema/Application_for_Federal_Assistance__c.State__c";
import getCounties from '@salesforce/apex/ApplicationFederalAssistanceController.getCounties';
import getDistricts from '@salesforce/apex/ApplicationFederalAssistanceController.getDistricts';

export default class LitcCountyMapping extends LightningElement {

    @api recordId;
    @track stateOptions = [];
    @track stateValue;
    @track countyOptions = [];
    @track districtOptions = [];
    @track selectedCounties = [];
    @track selectedDistricts = [];

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    @wire(getObjectInfo, { objectApiName: OBJECT}) 
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: STATE })
    setExternalStatuses({error, data}) {
        if (data) {
            let tempOptions = [];
            data.values.forEach(function(item) {
               tempOptions.push({value: item.value, label: item.value});
            })
            this.stateOptions = tempOptions;
        } else if(error) console.log(error)
    }

    handleStateChange(event){ 
        this.stateValue = event.target.value;
        getCounties({state: event.target.value}).then(data=>{
             console.log(data);
             let tempOptions = [];
             data.forEach(function(item) {
                tempOptions.push({value: item.Name, label: item.County_Name__c});
             })
             this.countyOptions = tempOptions;
          
        }).catch(error=>{
             console.log(error);
        })
    }

    handleStateChangeTwo(event){ 
        getDistricts({state: event.target.value}).then(data=>{
            console.log(data);
            let tempOptions = [];
            data.forEach(function(item) {
               tempOptions.push({value: item.Name, label: item.Name});
            })
            this.districtOptions = tempOptions;
         
       }).catch(error=>{
            console.log(error);
       })
    }

    handleAddCounty(){
        // get new values as list
        let temp = this.template.querySelector('.countyPicklist').value;
        let newValuesList = JSON.parse(JSON.stringify(temp));

        // get previous values as list
        let inputField = this.template.querySelector("lightning-input-field[data-name='areasInput']").value;
        let existingValuesList = inputField ? inputField.split(';') : [];

        // combine lists and use set to remove duplicates
        let combinedList = [...existingValuesList, ...newValuesList];
        let uniqueValuesSet = new Set(combinedList);

        // turn back to list from set and concatenate as String
        let uniqueValuesList = Array.from(uniqueValuesSet);
        let concatenatedString = uniqueValuesList.join(';');

        updateRecord({fields: {Id: this.recordId, 'Areas_affected_by_project__c': concatenatedString}}).then(()=>{ 
            // this.triggerCheckValidations();
        })
    }

    handleAddDistrict(){
        // get new values as list
        let temp = this.template.querySelector('.districtPicklist').value;
        let newValuesList = JSON.parse(JSON.stringify(temp));

        // get previous values as list
        let inputField = this.template.querySelector("lightning-input-field[data-name='districtInput']").value;
        let existingValuesList = inputField ? inputField.split(';') : [];

        // combine lists and use set to remove duplicates
        let combinedList = [...existingValuesList, ...newValuesList];
        let uniqueValuesSet = new Set(combinedList);

        // turn back to list from set and concatenate as String
        let uniqueValuesList = Array.from(uniqueValuesSet);
        let concatenatedString = uniqueValuesList.join(';');

        updateRecord({fields: {Id: this.recordId, 'Congressional_district_by_project__c': concatenatedString}}).then(()=>{})
        updateRecord({fields: {Id: this.recordId, 'Congressional_District_Program_Project__c': concatenatedString}}).then(()=>{})
    }
    
    handleSelectAllCounties(){ 
        if (this.selectedCounties.length === this.countyOptions.length) {
            this.selectedCounties = [];
        } else {
            this.selectedCounties = this.countyOptions.map(option => option.value);
        }
    }
    handleSelectAllDistricts(){ 
        if (this.selectedDistricts.length === this.districtOptions.length) {
            this.selectedDistricts = [];
        } else {
            this.selectedDistricts = this.districtOptions.map(option => option.value);
        }
    }

    handleClearAreasField(){ 
        updateRecord({fields: {Id: this.recordId, 'Areas_affected_by_project__c': null}});
    }
    handleClearAreasFieldTwo(){ 
        updateRecord({fields: {Id: this.recordId, 'Congressional_district_by_project__c': null}});
    }

}