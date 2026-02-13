import { LightningElement, track, api, wire } from 'lwc';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import { getRecordUi, getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin, CurrentPageReference } from 'lightning/navigation';

import getLayoutFieldsFinal_V5 from "@salesforce/apex/crmPageLayoutController.getLayoutFieldsFinal_V5";

export default class CrmObjectDetails extends NavigationMixin(LightningElement) {

    @api recordId;
    @api objectApiName;

    objectApi;
    accountRecType;
    
    @track objectInfo;
    showForm = false;
    isLoading = true;
    @track objectName = '';    
    
    error;

    objFields = []; //Array to store field api and label
    fields = [];
    fieldsMap = {};

    sections = [];    
    objMapClm = [];  
    oneColumn = false;
    twoColumn = true;
    totalColunm = 1;
    
    fieldsWithObj = [];
    showEditField;
    @track recValue;
    @track hasRecValue = false;

    isDebug = false; //true;

    handleSuccess(event) {
        this.showEditField = false;
    }
    handleEdit() {
        this.showEditField = !this.showEditField;
    }

    handleCancel(){
        if (this.showEditField){

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: this.recordId,
                    actionName: 'view'
                }
            });
            
        }
    }

    handleSave(){
    }

    connectedCallback(){ 

        if (this.isDebug) { console.log('recordID: ', this.recordId); }

        this.objectApi = this.objectApiName;
        if (this.isDebug) { console.log('objectApi: ', this.objectApi); }

        if (this.isDebug) { console.log('connectedCallback, isLoading: ', this.isLoading); }
        if (this.isLoading == false){
            this.showForm = true;
            if (this.isDebug) { console.log('connectedCallback, showForm: ', this.showForm); }
        }  
            
        this.getLayoutViewFieldsFinal_V5();
        		
	}  

    
    getLayoutViewFieldsFinal_V5(){         
        getLayoutFieldsFinal_V5({ objectApiName: this.objectApiName, recordId: this.recordId})
                .then((result) => {

                    if (this.isDebug) {
                        console.log("getLayoutFieldsFinal_V5 start ~~~~~~~~~~~~~~~~~~~~~~~~~~~~ ");
                        console.log("V5 result: " + JSON.stringify(result));
                    }
                    
                    let tempArray = [];                    

                    for(let key in result) {  
                        
                        let tempClm1 = [];
                        let tempClm2 = []; 
                        let clmSize = 0;                
                        
                        if (result.hasOwnProperty(key)) {

                            for(let key2 in result[key]){

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
                    
                     this.isLoading = false;
                     this.showForm = true;

                     if (this.isDebug) { console.log('getLayoutFieldsFinal_V5 end #################');     }             			
                })
                .catch((error) => {
                    console.log("getLayoutNameForObject error " + error);
                    console.log("getLayoutNameForObject message  " + error.message);
                });
    }
    
    @wire(getObjectInfo, { objectApiName: '$objectApiName' })
    wiredObjectInfo({  error, data  }){
        if (data) {

            if (this.isDebug) {
                console.log('Start Object Info'); 
                console.log('wire start, isLoading: ', this.isLoading);
                console.log(data);
                console.log('name: ', data.apiName);
            }

            this.objectName = data.apiName;
            this.objectInfo = data; 

            //label: field.label,editable: field.editable
            this.objFields = Object.values(data.fields).map(field => ({
                apiName: field.apiName,                
                label: field.label
            }));   
            
             this.isLoading = false;
             this.showForm = true;

             if (this.isDebug) {
                console.log('wire end, isLoading: ', this.isLoading);
                console.log('this.objFields: ', JSON.stringify(this.objFields));
             }
             
        }
        else if (error) {            
            console.log('Error: ', error);
        }       
    }  
    
}