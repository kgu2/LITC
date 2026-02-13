import { LightningElement, track, api, wire } from 'lwc';
import userGroups from "@salesforce/apex/crmAdminSettingsController.userGroups";
import isAdmin from "@salesforce/apex/crmAdminSettingsController.isAdmin";
import groupAnnouncement from "@salesforce/apex/crmAdminSettingsController.groupAnnouncement";
import updateAnnouncement from "@salesforce/apex/crmAdminSettingsController.updateAnnouncement";
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';

export default class CrmHomePageHeader extends NavigationMixin(LightningElement){

    @track groupName;
    @track groupNickname;
    @track announcement;
    @track newAnnouncement;
    @track hasAnnouncement = false;
    @track userIsAdmin = true;
    @track showEditField = false;
    @track isLoading = true;

    isDebug = false;

    connectedCallback(){ 
        if (this.isDebug) { console.log('connectedCallback'); }
        
        this.getUserGroup();
    }

    getIsAdmin(){
        isAdmin()
                .then((result) => {
                    if (this.isDebug) {
                        console.log("isAdmin start ................... ");
                        console.log("isAdmin result: " + JSON.stringify(result));
                    }
                    this.userIsAdmin = result; 
                    this.isLoading = false;
                })
                .catch((error) => {
                    console.log("isAdmin error " + error);
                    console.log("isAdmin message  " + error.message);
                });
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
                    if (this.isDebug) { console.log("this.groupName: " + JSON.stringify(this.groupName)); }
                    this.getGroupAnnouncement();                                     			
                })
                .catch((error) => {
                    console.log("userGroups error " + error);
                    console.log("userGroups message  " + error.message);
                });
    }

    getGroupAnnouncement(){
        groupAnnouncement()
                .then((result) => {
                    if (this.isDebug) {
                        console.log("groupAnnouncement start ................... ");
                        console.log("groupAnnouncement result: " + JSON.stringify(result)); 
                    }

                    if (result != null){
                        if (result.length > 0){
                            this.announcement = result;
                            this.hasAnnouncement = true;
                        }
                    }
                    if (this.isDebug) { console.log("this.announcement: " + JSON.stringify(this.announcement)); }
                    
                    this.getIsAdmin();
                })
                .catch((error) => {
                    console.log("userGroups error " + error);
                    console.log("userGroups message  " + error.message);
                });
    }

    handleEdit() {
        this.showEditField = !this.showEditField;
    }

    handleChange(event){
        //event.preventDefault();
        this.newAnnouncement = event.targer.value;
    }

    handleSave(){
        this.newAnnouncement = this.template.querySelector("lightning-textarea").value;
        this.announcement = this.newAnnouncement;
        if (this.isDebug) {
            console.log("lightning-textarea : " + this.newAnnouncement);
            console.log("groupName : " + this.groupNickname);
        }
        
        updateAnnouncement({groupName: this.groupNickname, newDescription: this.newAnnouncement})
        .then(() => {
            this.showEditField = false;
            if (this.isDebug) { console.log("updateAnnouncement success "); }
        })
        .catch(error => {
            console.log("updateAnnouncement error ", error);
        });
    }

    handleCancel(){
        this.showEditField = false;
        //window.history.back();
    }    

}