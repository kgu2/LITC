import { LightningElement, track, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation'; 
import { CurrentPageReference } from 'lightning/navigation';

import getAccountRecType from "@salesforce/apex/crmPageLayoutController.getAccountRecordType";
import getLayoutFieldsAccount_V5 from "@salesforce/apex/crmPageLayoutController.getLayoutFieldsAccount_V5";
import getLayoutFields_V5 from "@salesforce/apex/crmPageLayoutController.getLayoutFields_V5";

export default class CrmNewAccountRecord extends NavigationMixin(LightningElement) {

    name = '';

    showEditField = true;
    objectAccount = 'Account';
    objectPerson = 'PersonAccount';
    objectApiName = 'Account';
    
    sections = [];
    objMapClm = [];
    oneColumn = false;
    twoColumn = true;
    totalColunm = 1;

    objResults = {};

    recordTypeId;
    recordTypeName;
    hasRecordType = false;
    isPerson = false;
    title = 'Account New Record';

    isDebug = false;

    @wire(CurrentPageReference)
    getRecordTypeId(currentPageReference) {
       if (currentPageReference) {
            this.recordTypeId = currentPageReference.state.recordTypeId;
            if (this.recordTypeId != null) this.hasRecordType = true;
           
            if (this.isDebug) {
                console.log(" wire this.recordTypeId: " + JSON.stringify(this.recordTypeId)); 
                console.log(" wire this.recordTypeName: " + JSON.stringify(this.recordTypeName));
            }       
       }
    }

    handleNameChange(event){
       // this.name = event.target.value;
    }

    handleSave(){                
    }

    handleCancel(){
        window.history.back();
    }

    handleOnLoad(event) {  
        //console.log(" detail.record.fields handleOnLoad ### : ", event.detail.record.fields);        
    }

    handleSuccess(event) {  
        //window.history.back();   
        const recordId = event.detail.id;
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: {
                recordId: recordId,
                actionName: 'view'
            }
        }); 
        
    }

    connectedCallback(){  
        if (this.isDebug) { console.log("connectedCallback this.recordTypeId: " + JSON.stringify(this.recordTypeId)); }
        if (this.recordTypeId != null){
            this.hasRecordType = true;
            this.getAccountRecordType(); 
        }
        else{
            this.getLayoutViewFields_V5();            
        }    	
	} 

    getAccountRecordType(){
        getAccountRecType({ recordTypeId: this.recordTypeId})
        .then((result) => {
            if (this.isDebug) {
                console.log("getAccountRecordType start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ");
                console.log("getAccountRecordType result: " + JSON.stringify(result));
            }

            this.recordTypeName = result;
            if (this.recordTypeName.includes('Person')) this.isPerson = true; 
            if (this.recordTypeName != null) this.hasRecordType = true;
            this.title = this.recordTypeName + ' New Record';

            this.getLayoutViewFieldsAccount_V5();
        })
        .catch((error) => {
            console.log("getAccountRecordType error " + error);
            console.log("getAccountRecordType message  " + error.message);
        });
    }    

    getLayoutViewFieldsAccount_V5(){
        getLayoutFieldsAccount_V5({ recordTypeId: this.recordTypeId})
                .then((result) => {
                    if (this.isDebug) {
                        console.log("getLayoutFieldsAccount_V5 NEW start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ");
                        console.log("getLayoutFieldsAccount_V5 NEW result: " + JSON.stringify(result));
                    }

                    this.objResults = result;
                    if (this.isDebug) { console.log("V5 this.objResults: " + JSON.stringify(this.objResults)); }

                    this.getLayout(this.objResults);             
                    if (this.isDebug) { console.log("V5 END @@@@@@@@@@@@@@@@@@@@@@@@@@@@@");  }           			
                })
                .catch((error) => {
                    console.log("getLayoutNameForObject error " + error);
                    console.log("getLayoutNameForObject message  " + error.message);
                });                
    }

    getLayout(returnObj){

        if (this.isDebug) { console.log("getLayout returnObj: " + JSON.stringify(returnObj)); }
        let tempArray = [];                    

        for(let key in returnObj) {  
            
            let tempClm1 = [];
            let tempClm2 = []; 
            let clmSize = 0;               
 
            if (returnObj.hasOwnProperty(key)) { 

                if(key != "System Information"){

                    // Filtering the data in the loop
                    //let test = returnObj[key];
                    //console.log("get V5 key : " + JSON.stringify(key));
                    //console.log("get V5 result[key]: " + JSON.stringify(test));
                    //get  result[key]: {"true":["Name","AccountId","Title","Email","Phone","MobilePhone"],"false":["OwnerId","ReportsToId","Department","Fax"]}                            
                    // {"Name":"Required","BillingAddress":"Edit","ParentId":"Edit","OCCIP_International_Presence__c":"Required"}

                    for(let key2 in returnObj[key]){
                        
                        if (this.isDebug) {
                            console.log("V5 key2: " + JSON.stringify(key2));
                            console.log("v5 value2: " + JSON.stringify(returnObj[key][key2]));  
                        }
                                    
                        for(let key3 in returnObj[key][key2]){

                            //Required; Edit; Readonly; "MiddleName","Suffix"
                            let tempRequired = false;
                            let tempReadonly = false;

                            if (returnObj[key][key2][key3] == 'Required' && ((key3 != 'MiddleName') && (key3 != 'Suffix') )) tempRequired = true;
                            if (returnObj[key][key2][key3] == 'Readonly') tempReadonly = true;

                            //push({field: key3, behavior : {fieldRequired: tempRequired, fieldReadonly : tempReadonly}});
                            if (key2 == "true"){
                                tempClm1.push({fieldAPI: key3, behavior : {fieldRequired: tempRequired, fieldReadonly : tempReadonly}});
                            } else if (key2 == "false"){
                                tempClm2.push({fieldAPI: key3, behavior : {fieldRequired: tempRequired, fieldReadonly : tempReadonly}});
                                this.totalColunm = this.totalColunm + 1;
                            } 

                            clmSize = tempClm1.length;
                            if (tempClm2.length > tempClm1.length) clmSize = tempClm2.length;

                            if (this.isDebug) {
                                console.log("V5 tempClm1: " + JSON.stringify(tempClm1));
                                console.log("V5 tempClm2: " + JSON.stringify(tempClm2));
                            }
                        }
                    }                        

                    let temp_1_2 = [];
                    if (clmSize > 0){
                        temp_1_2.push({columns: "column1", fields :tempClm1});
                        temp_1_2.push({columns: "column2", fields :tempClm2});
                        tempArray.push({key: key, value: temp_1_2});

                        this.sections.push(key);
                        if (this.isDebug) { console.log("getLayout sections key: " + JSON.stringify(key)); }
                    }
                    tempClm1 = [];
                    tempClm2 = [];
                }
            }
        }

        if (this.isDebug) { console.log("tempArray: " + JSON.stringify(tempArray)); } 
        
        this.objMapClm = tempArray;
        if (this.totalColunm == 1){
            this.oneColumn = true;
            this.twoColumn = false;
        }

        if (this.isDebug) {
            console.log("getLayout getLayoutNameForObject objMapClm: " + JSON.stringify(this.objMapClm));
            console.log("getLayout sections: " + JSON.stringify(this.sections));
            console.log("END getLayout &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&");
        }

    }

    //getLayoutFields_V5(String objectApiName, boolean isNewRec)
    getLayoutViewFields_V5(){
        getLayoutFields_V5({ objectApiName: this.objectApiName, isNewRec: true})
                .then((result) => {
                    if (this.isDebug) {
                        console.log("getLayoutNameForObject NEW start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ");
                        console.log("getLayoutNameForObject NEW result: " + JSON.stringify(result));
                    }

                    this.objResults = result;
                    if (this.isDebug) { console.log("getLayoutNameForObject this.objResults: " + JSON.stringify(this.objResults)); }

                    this.getLayout(this.objResults);             
                    if (this.isDebug) { console.log("V5 END @@@@@@@@@@@@@@@@@@@@@@@@@@@@@");  }
                                 			
                })
                .catch((error) => {
                    console.log("getLayoutNameForObject error " + error);
                    console.log("getLayoutNameForObject message  " + error.message);
                });
    }

}