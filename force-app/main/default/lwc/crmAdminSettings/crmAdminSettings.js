import { LightningElement, track, api, wire } from 'lwc';
import isAdmin from "@salesforce/apex/crmAdminSettingsController.isAdmin";
import userGroups from "@salesforce/apex/crmAdminSettingsController.userGroups";
import objectList from "@salesforce/apex/crmAdminSettingsController.objectList";
import objectLayoutList from "@salesforce/apex/crmAdminSettingsController.objectLayoutList";
import layoutAssignmentList from "@salesforce/apex/crmAdminSettingsController.layoutAssignmentList";
import usersList from "@salesforce/apex/crmAdminSettingsController.usersList";
import updateLayouts from "@salesforce/apex/crmAdminSettingsController.updateLayouts";

import allLayouts from "@salesforce/apex/crmAdminSettingsController.allLayouts";
//import allLayoutsNew from "@salesforce/apex/crmAdminSettingsController.allLayoutsNew";

export default class CrmAdminSettings extends LightningElement {

    userIsAdmin = true;

    isDebug = false;

    usersList = [];
    usersListWithId = {};

    objectsList = [];
    assignmentList = {};
    userAndLayout = [];
    editUserAndLayout = [];

    layoutAndFields = [];
    layoutAndFieldsNew = [];
    oneColumn = false;
    twoColumn = true;
    totalColunm = 1;

    layoutList = [];
    layoutListWithId = {};
    layoutListNoId = [];

    layoutOptions = [];
    layoutOptionsTest = [];

    groupName;
    groupNickname;

    showEditField = false;

    resultSave = [];
    resultOriginal = [];

    
    connectedCallback(){ 
        if (this.isDebug) {
            console.log('connectedCallback');
        }
        
        this.getUserGroup();
        //this.getIsAdmin();        
        //this.getObjectList();
        //this.getUsersList();
        //this.getObjectLayoutList();	
        //this.getLayoutAssignmentList();
        //this.getUsersAndLayouts();	
	}  
    
    getUserGroup(){
        userGroups()
                .then((result) => {
                    if (this.isDebug) {
                        console.log("userGroups start ................... ");
                        console.log("userGroups result: " + JSON.stringify(result)); 
                    }

                    let temp;
                    let tempKey;
                    if (result != null){
                        for(let key in result) {                        
                            if (result.hasOwnProperty(key)) { 
                                // Filtering the data in the loop
                                tempKey = key;
                                temp = result[key];                                                            
                            }
                        }
                    }
                    this.groupName = temp; 
                    this.groupNickname = tempKey;
                    
                    this.getIsAdmin();                                     			
                })
                .catch((error) => {
                    console.log("userGroups error " + error);
                    console.log("userGroups message  " + error.message);
                });
    }

    getIsAdmin(){
        isAdmin()
                .then((result) => {
                    if (this.isDebug) {
                        console.log("isAdmin start ................... ");
                        console.log("isAdmin result: " + JSON.stringify(result));
                    }
                    this.userIsAdmin = result;                   
                     
                    this.getObjectList();
                })
                .catch((error) => {
                    console.log("isAdmin error " + error);
                    console.log("isAdmin message  " + error.message);
                });
    }    

    getObjectList(){
        objectList()
                .then((result) => {
                    if (this.isDebug) {
                        console.log("objectList start ................... ");
                        console.log("objectList result: " + JSON.stringify(result)); 
                    }  
                    
                    let tempArray = [];
                    for(let key in result) {                        
                        if (result.hasOwnProperty(key)) { 
                            // Filtering the data in the loop
                            let temp = result[key];
                            //temp = apiToName(temp);
                            // temp = temp.replace('__c', '');
                            // temp = temp.replace('__C', '');
                            // temp = temp.replace('_', ' ');
                            tempArray.push(temp);
                        }
                    }
                    this.objectsList = tempArray;
                    if (this.isDebug) { console.log("this.objectsList: " + JSON.stringify(this.objectsList)); }

                    tempArray.forEach(element => {
                        this.userAndLayout[element] = {};
                    });
                    if (this.isDebug) { console.log("this.userAndLayout: " + JSON.stringify(this.userAndLayout)); }
                    
                    this.getUsersList();                                     			
                })
                .catch((error) => {
                    console.log("objectList error " + error);
                    console.log("objectList message  " + error.message);
                });
    }

    getObjectLayoutList(){
        objectLayoutList()
        .then((result) => {
            if (this.isDebug) {
                console.log("objectLayoutList start ................... ");
                console.log("objectLayoutList result: " + JSON.stringify(result)); 
            }

            this.layoutListWithId = result;
            if (this.isDebug) { console.log("this.layoutListWithId : " + JSON.stringify(this.layoutListWithId)); }

            let tempArrayLt = [];
            for(let key in result) {                        
                if (result.hasOwnProperty(key)) { 
                    // Filtering the data in the loop
                    tempArrayLt.push(result[key]);
                }
            }
            this.layoutListNoId = tempArrayLt;
            if (this.isDebug) { console.log("this.layoutListNoId: " + JSON.stringify(this.layoutListNoId)); }
            
            let tempArray = [];
            let obj = '';
            let tempLayout = [];
            let tempDefault = this.groupNickname + '_Layout';            

            let ind = 0;
            for (let item in this.objectsList){
                tempLayout = [];
                obj = this.objectsList[item];
                tempLayout.push({label : 'Default', value : 'Default'});

                //for(let key in result) { 
                for(let key in result) {  
                    
                    // Filtering the data in the loop
                    if (ind == 0) tempArray.push({label : result[key], value : result[key]});
                    let rec = result[key].split('-'); 
                    let recObj = rec[0];
                    
                     if (( obj == recObj ) && ( rec[1] != tempDefault )){
                        tempLayout.push({label : rec[1], value : rec[1]});
                    }                    
                }
                ind++; 
                this.layoutOptions.push({key: obj, value: tempLayout});
            }
            
            if (this.isDebug) { console.log("this.layoutOptions: " + JSON.stringify(this.layoutOptions)); }
            this.layoutList = tempArray;            
            if (this.isDebug) { console.log("this.layoutList: " + JSON.stringify(this.layoutList)); }
             
             
            this.getLayoutAssignmentList();
        })
        .catch((error) => {
            console.log("objectLayoutList error " + error);
            console.log("objectLayoutList message  " + error.message);
        });
    }
    getLayoutAssignmentList(){
        layoutAssignmentList()
        .then((result) => {
            if (this.isDebug) {
                console.log("layoutAssignmentList start ................... ");
                console.log("layoutAssignmentList result: " + JSON.stringify(result)); 
            }
            
            //assignmentList = {};
            let tempArrayObjLayoutUser = [];
            let tempOriginal = [];
            let i = 0;
            for(let key in result) {                        
                if (result.hasOwnProperty(key)) { 
                    //layoutAssignmentList result: ["a02BZ0000024Va6YAE;Account-Rita_Account;Bureau User1", .......]
                    let temp1 = result[key].split(';');
                    let temp2 = temp1[1].split('-');
                    
                    let tempObj = {
                        "obj" :  temp2[0],
                        "user" : temp1[2],
                        "layout" : temp2[1]
                    }

                    let tempUserId = '';
                    for (let item in this.usersListWithId){
                        
                        if(this.usersListWithId[item] == temp1[2]){
                            tempUserId = item;
                            if (this.isDebug) { console.log("item in this.usersListWithId: " + JSON.stringify(this.usersListWithId[item])); }
                        }
                    }

                    //["Account~00582000001NAm7AAG~Rita_Account"] : temp2[0]  + '~' + tempUserId  + '~' + temp2[1]
                    let tempRec = temp2[0]  + '~' + tempUserId  + '~' + temp2[1];
                    tempOriginal.push(tempRec);
                    if (this.isDebug) { console.log("layoutAssignmentList tempObj: " + JSON.stringify(tempObj)); }

                    tempArrayObjLayoutUser.push(tempObj);
                }
            }
            this.assignmentList = tempArrayObjLayoutUser;
            this.resultOriginal = tempOriginal;
            this.resultSave = tempOriginal;
            if (this.isDebug) {
                console.log("this.assignmentList: " + JSON.stringify(this.assignmentList));
                console.log("this.resultOriginal: " + JSON.stringify(this.resultOriginal)); 
            }
             
            this.getUsersAndLayouts();
        })
        .catch((error) => {
            console.log("layoutAssignmentList error " + error);
            console.log("layoutAssignmentList message  " + error.message);
        });
    }

    getUsersList(){
        usersList()
        .then((result) => {
            if (this.isDebug) {
                console.log("usersList start ................... ");
                console.log("usersList result: " + JSON.stringify(result));   
            } 
            
            let tempArray = [];
            for(let key in result) {                        
                if (result.hasOwnProperty(key)) { 
                    // Filtering the data in the loop
                    tempArray.push(result[key]);
                }
            }
            this.usersList = tempArray;
            if (this.isDebug) { console.log("this.usersList: " + JSON.stringify(this.usersList)); }
            this.usersListWithId = result;
            if (this.isDebug) { console.log("this.usersListWithId: " + JSON.stringify(this.usersListWithId)); }
        
            this.getObjectLayoutList();
        })
        .catch((error) => {
            console.log("usersList error " + error);
            console.log("usersList message  " + error.message);
        });
    }

    getUsersAndLayouts(){
        if (this.isDebug) { console.log("getUsersAndLayouts start ################### "); }
        //this.usersList: "FName LName"
        //this.objectsList: "Account"
        //this.userAndLayout[element] = {}; where element = "Account"
        //this.layoutList, "obj" :  temp2[0], "user" : temp1[2], "layout" : temp2[1]

        let tempArray = [];
        let tempArrayEdit = [];

        for(let keyObj in this.userAndLayout){            
            if (this.isDebug) { console.log("getUsersAndLayouts key: " + JSON.stringify(keyObj)); }
            let tempMatch = [];
            let tempMatchEdit = [];
            let tempLayoutOption = [];
            
            for(let item in this.usersListWithId){ 
                let tempLayout = '';
                let tempLayoutEdit = '';
                let tempLayoutOptionEdit = [];
                
                for(let element in this.assignmentList){                   
                    if(keyObj == this.assignmentList[element].obj){
                        if (this.usersListWithId[item] == this.assignmentList[element].user){                            
                            tempLayout = this.assignmentList[element].layout; 
                            tempLayoutEdit = keyObj + '~' + item + '~' +  tempLayout;                         
                        }
                    }
                }
                for(let item in this.layoutOptions){                    
                    if (this.layoutOptions[item].key == keyObj){                        
                        tempLayoutOption = this.layoutOptions[item].value; 
                       // console.log("inside for loop tempLayoutOption: " + JSON.stringify(tempLayoutOption));                       
                    }
                }

                if (this.isDebug) {
                    console.log("result key: " + JSON.stringify(key));
                    console.log("result tempLayoutOption: " + JSON.stringify(tempLayoutOption));
                    console.log("this.usersList[item]: " + JSON.stringify(this.usersList[item]));
                }

                for(let index in tempLayoutOption){                  
                    tempLayoutOptionEdit.push({label : tempLayoutOption[index].label, value : keyObj + '~' + item + '~' +  tempLayoutOption[index].value});                        
                } 
                if (this.isDebug) { console.log("tempLayoutOptionEdit: " + JSON.stringify(tempLayoutOptionEdit));     }          

                tempMatch.push({name: this.usersListWithId[item], layout: tempLayout, options: tempLayoutOption});
                tempMatchEdit.push({name: this.usersListWithId[item], layout: tempLayoutEdit, options: tempLayoutOptionEdit});
            }


            let objName = keyObj.replace('__c', '');
            objName = objName.replace('__C', '');
            objName = objName.replace('_', ' ');
            objName = objName.replace(/([a-z])([A-Z])/g, '$1 $2');

            tempArray.push({ key: objName, value: tempMatch});
            tempArrayEdit.push({ key: objName, value: tempMatchEdit});
        }
        this.userAndLayout = tempArray;
    //    this.editUserAndLayout = tempArray;
        this.editUserAndLayout = tempArrayEdit;

        if (this.isDebug) {
            console.log("FINAL!!!!!: " + JSON.stringify(this.userAndLayout));
            console.log("FINAL!!!!!: " + JSON.stringify(this.editUserAndLayout));
        }

        this.allLayoutsList();
       // this.allLayoutsListNew();
    }

    /*
    allLayoutsList(){
        allLayouts()
                .then((result) => {
                    
                //    console.log("NEW ######## allLayouts start ................... ");
                //    console.log("NEW ######## allLayouts result: " + JSON.stringify(result)); 
                    
                    let tempArray = [];
                    for(let key in result) {                        
                        if (result.hasOwnProperty(key)) { 
                            // Filtering the data in the loop
                            //tempArray.push(result[key]);
                            let ltName = key.replace('-', ' - ');
                            tempArray.push({ key: ltName, value: result[key]});
                        }
                    }
                    this.layoutAndFields = tempArray;
                //    console.log("NEW ######## this.layoutAndFields: " + JSON.stringify(this.layoutAndFields)); 
                                                      			
                })
                .catch((error) => {
                    console.log("NEW allLayouts error " + error);
                    console.log("NEW allLayouts message  " + error.message);
                });
    }
    */

    allLayoutsList(){
        allLayouts()
                .then((result) => {
                    
                    if (this.isDebug) {
                        console.log("NEW ######## allLayoutsNew start ................... ");
                        console.log("NEW ######## allLayoutsNew result: " + JSON.stringify(result)); let tempArray = []; 
                    }                   
                    
                    let tempArrayLayouts = [];

                    for(let key in result) {  
                        
                        // key, result[key]
                        // let ltName = key.replace('-', ' - ');
                        // tempArray.push({ key: ltName, value: result[key]});
                        let tempArrayOneLayout = [];
                        
                        let tempOneLayout = result[key];

                        for(let key1 in tempOneLayout){
                        
                            let tempClm1 = [];
                            let tempClm2 = []; 
                            let clmSize = 0;        

                            for(let key2 in tempOneLayout[key1]){
                                
                                if (this.isDebug) {
                                    console.log("key2: " + JSON.stringify(key2));
                                    console.log("value2: " + JSON.stringify(tempOneLayout[key1][key2]));
                                    console.log("editable: " + tempOneLayout[key1][key2].readOnly);
                                }

                                if (key2 == "true"){
                                    tempClm1 = tempOneLayout[key1][key2];
                                } else if (key2 == "false"){
                                    tempClm2 = tempOneLayout[key1][key2];
                                    this.totalColunm = this.totalColunm + 1;
                                } 

                                clmSize = tempClm1.length;
                                if (tempClm2.length > tempClm1.length) clmSize = tempClm2.length;

                                if (this.isDebug) {
                                    console.log("tempClm1: " + JSON.stringify(tempClm1));
                                    console.log("tempClm2: " + JSON.stringify(tempClm2));
                                }
                            }                        

                            let temp_1_2 = [];
                            if (clmSize > 0){
                                temp_1_2.push({columns: "column1", fields :tempClm1});
                                temp_1_2.push({columns: "column2", fields :tempClm2});
                                tempArrayOneLayout.push({key: key1, value: temp_1_2});

                                //this.sections.push(key);
                                if (this.isDebug) { console.log("sections key: " + JSON.stringify(key1)); }
                            }
                        }
                        
                        tempArrayLayouts.push({key: key, value: tempArrayOneLayout});

                    }

                    if (this.isDebug) {
                        console.log("tempArrayLayouts: " + JSON.stringify(tempArrayLayouts));
                        console.log({'tempArray !!!!!!':tempArray});
                    }
                    
                    this.layoutAndFieldsNew = tempArrayLayouts;
                    if (this.totalColunm == 1){
                        this.oneColumn = true;
                        this.twoColumn = false;
                    }

                    if (this.isDebug) { console.log("FINAL getLayoutNameForObject layoutAndFieldsNew: " + JSON.stringify(this.layoutAndFieldsNew)); }
                                     			
                })
                .catch((error) => {
                    console.log("getLayoutNameForObject error " + error);
                    console.log("getLayoutNameForObject message  " + error.message);
                });
    }

    handleEdit() {
        this.showEditField = !this.showEditField;
            if (this.isDebug) { console.log("this.showEditField = " + JSON.stringify(this.showEditField)); }
    }

    handleCancel(){
        this.showEditField = false;
        this.resultSave = this.resultOriginal;
        //window.history.back();
    } 

    handleChange(event){
       
        if (this.isDebug) { console.log("event.detail.value" + event.detail.value); }
        let tempResult = [];
                
        let temp = event.detail.value;
        let tempArray = temp.split('~');
        let tempStr = tempArray[0] + '~' + tempArray[1];
        if (this.isDebug) { console.log("tempStr" + tempStr); }

        this.resultSave = this.resultSave.filter(item => !item.includes(tempStr));
    //   if (tempArray[2] != 'Default'){
            this.resultSave.push(temp);
            if (this.isDebug) { console.log("event.detail.value added"); }
    //    }
    if (this.isDebug) { console.log("this.resultSave" + JSON.stringify(this.resultSave));  }      
    }

    handleSave(){     
        
        updateLayouts({groupName: this.groupNickname, newLayouts: this.resultSave})
        .then(() => {
            this.showEditField = false;
            if (this.isDebug) { console.log("updateLayouts success "); }
        })
        .catch(error => {
            console.log("updateLayouts error ", error);
        });

    }

    apiToName(name){
         let temp = name.replace('__c', '');
         temp = temp.replace('__C', '');
         temp = temp.replace('_', ' ');
         return temp;
    }

}