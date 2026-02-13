import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { createRecord, updateRecord } from 'lightning/uiRecordApi';
//import { showNotification } from 'c/utilities';
import USER_ID from '@salesforce/user/Id';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getLayoutFields_V5 from "@salesforce/apex/crmPageLayoutController.getLayoutFields_V5";
import getDefaultMasterRecId  from "@salesforce/apex/crmPageLayoutController.getDefaultMasterRecordId";

export default class CrmNewObjectRecord extends NavigationMixin(LightningElement) {

    showEditField = true;
    @track objectApiName;

    sections = [];
    objMapClm = [];
    oneColumn = false;
    twoColumn = true;
    totalColunm = 1;

    objTitle = 'Create New Record';

    isDebug = false; //true; //false;
    isDebug1 = true; //false;

    currentUserId = USER_ID;
    recordTypeId;
    recordTypeName;
    hasRecordType = false;
    recordId; //this will hold master default rec Id for object supporting multiple record types
    
    handleSubmit(event){        

        if (this.recordId != null){         
            event.preventDefault();   
            if (this.isDebug1) { console.log('handleSubmit preventDefault '); }          
        }
                
        let fields = event.detail.fields;  
        if (this.isDebug1) { console.log('handleSubmit const fields  ===  ', fields); } 
        fields.OwnerId = this.currentUserId;     

        // const allValid = [...this.template.querySelectorAll('lightning-input-field')]
        // .reduce((validSoFar, inputCmp) => {
        //     inputCmp.reportValidity();
        //     return validSoFar && inputCmp.reportValidity();
        // }, true);         
        // if (this.isDebug1) { console.log('handleSubmit const allValid  ===  ', allValid); }    

        if (this.objectApiName == 'Case' || this.objectApiName == 'Opportunity') {

            fields.Active__c = true;

            if (fields.Id != null) {               
                
            //    fields.OwnerId = this.currentUserId;
                delete fields.Id;      
            //    fields.OwnerId = this.currentUserId;
            
            }  
            
            if (this.objectApiName == 'Case'){
                let recImput = { apiName: this.objectApiName, fields : fields, OwnerId : this.currentUserId };
                createRecord(recImput)
                        .then(result => {

                        if (this.isDebug1) { console.log('created ', result); }

                        this.newRecId = result.id;

                        if (this.isDebug1) { console.log('created result Id', this.newRecId ); }

                        this.dispatchEvent(
                            new ShowToastEvent({
                                title: 'Success',
                                message: 'New Record Created Successfully',
                                variant: 'Success'
                            })
                        )

                        this[NavigationMixin.Navigate]({
                            type: 'standard__recordPage',
                            attributes: {
                                recordId: this.newRecId,
                                actionName: 'view'
                            }
                        });    
                    
                })
                .catch(error => {                
                    console.log('created error', error);
                    console.log('created error message', error.message);
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: error.body.output.errors[0].message,
                            variant: 'error'
                        })
                    )
                    //this.dispatchEvent(showNotification('Error', 'There was an error creating new record.', 'error'));
                    //message: error.body.output.errors[0].errorCode + '- '+ error.body.output.errors[0].message,
                });
            }
        }
           
        
    }

    handleCancel(){
        window.history.back();
    }

    handleSuccess(event) {          
           
        const newRecordId = event.detail.id;

        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: 'New Record Created Successfully',
                variant: 'Success'
            })
        )

        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: newRecordId,
                actionName: 'view'
            }
        });           
        
    }

    connectedCallback(){ 

       // Get the current URL
       let currentUrl = window.location.href;

       // Split the URL by '/' to get the segments
       let urlSegments = currentUrl.split('/');

       // Find the segment that contains the object API name
       let index = urlSegments.indexOf('o'); // Find the index of 'o' segment
       if (index !== -1 && index < urlSegments.length - 1) {
           this.objectApiName = urlSegments[index + 1]; // Get the API name after 'o'
       }

       // Now objectApiName should contain the API name of the object
       if (this.isDebug) { console.log('Object API Name:', this.objectApiName); }

       let objName = this.objectApiName.replace('__c', '');
       objName = objName.replace('__C', '');
       objName = objName.replace('_', ' ');
       this.objTitle = objName + ' New Record';

       // if (this.isDebug) { console.log("connectedCallback this.recordTypeId: " + JSON.stringify(this.recordTypeId)); }

        this.getDefaultMasterRecordId();
       
	} 

    
    getDefaultMasterRecordId(){
        getDefaultMasterRecId({ objectApiName: this.objectApiName})
        .then((result) => {
            if (this.isDebug) {
                console.log("getDefaultMasterRecordId start @@@@@@@@@@@@@@@@@@@@@@@@@@@@@ ");
                console.log("getDefaultMasterRecordId result: " + JSON.stringify(result));
            }  
            
            if (result != null){
                // const recordId = result;
                this.recordId = result;
            }
            
            if (this.objectApiName) {      
                this.getLayoutViewFields_V5(); 	
            }

        })
        .catch((error) => {
            console.log("getDefaultMasterRecordId error @@@@@@@ " + error);
            console.log("getDefaultMasterRecordId message  " + error.message);
        });
    }  
        
    getLayoutViewFields_V5(){
        getLayoutFields_V5({ objectApiName: this.objectApiName, isNewRec: true })
                .then((result) => {

                    if (this.isDebug) {
                        console.log("getLayoutNameForObject NEW start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ");
                        console.log("getLayoutNameForObject NEW result: " + JSON.stringify(result));
                    }
                    
                    let tempArray = [];                    

                    for(let key in result) {  
                        
                        let tempClm1 = [];
                        let tempClm2 = []; 
                        let clmSize = 0;                
       
                        if (result.hasOwnProperty(key)) { 

                            if(key != "System Information"){

                                // Filtering the data in the loop
                                for(let key2 in result[key]){
                                    
                                    if (this.isDebug) {
                                        console.log("key2: " + JSON.stringify(key2));
                                        console.log("value2: " + JSON.stringify(result[key][key2]));
                                    }
                                

                                    for(let key3 in result[key][key2]){

                                        //Required; Edit; Readonly; "MiddleName","Suffix"
                                        let tempRequired = false;
                                        let tempReadonly = false;
            
                                        if (result[key][key2][key3] == 'Required' && ((key3 != 'MiddleName') && (key3 != 'Suffix') )) tempRequired = true;
                                        if (result[key][key2][key3] == 'Readonly') tempReadonly = true;

                                        if (key2 == "true"){
                                            tempClm1.push({fieldAPI: key3, behavior : {fieldRequired: tempRequired, fieldReadonly : tempReadonly}});
                                        } else if (key2 == "false"){
                                            tempClm2.push({fieldAPI: key3, behavior : {fieldRequired: tempRequired, fieldReadonly : tempReadonly}});
                                            this.totalColunm = this.totalColunm + 1;
                                        } 

                                        clmSize = tempClm1.length;
                                        if (tempClm2.length > tempClm1.length) clmSize = tempClm2.length;

                                        if (this.isDebug) {
                                            console.log("tempClm1: " + JSON.stringify(tempClm1));
                                            console.log("tempClm2: " + JSON.stringify(tempClm2));
                                        }
                                    }
                                }                        

                                let temp_1_2 = [];
                                if (clmSize > 0){
                                    temp_1_2.push({columns: "column1", fields :tempClm1});
                                    temp_1_2.push({columns: "column2", fields :tempClm2});
                                    tempArray.push({key: key, value: temp_1_2});

                                    this.sections.push(key);
                                    if (this.isDebug) { console.log("sections key: " + JSON.stringify(key)); }
                                }

                                tempClm1 = [];
                                tempClm2 = [];

                            }
                        }
                    }

                    if (this.isDebug) {
                        console.log("tempArray: " + JSON.stringify(tempArray));
                        console.log({'tempArray !!!!!!':tempArray});
                    }
                    
                    this.objMapClm = tempArray;
                    if (this.totalColunm == 1){
                        this.oneColumn = true;
                        this.twoColumn = false;
                    }

                    if (this.isDebug) {
                        console.log("getLayoutNameForObject objMapClm: " + JSON.stringify(this.objMapClm));
                        console.log("sections: " + JSON.stringify(this.sections));
                    }
                                 			
                })
                .catch((error) => {
                    console.log("getLayoutNameForObject error " + error);
                    console.log("getLayoutNameForObject message  " + error.message);
                });
    }

}