import { LightningElement, api, wire, track } from 'lwc';
import utilities from 'c/utilities';
import getOtherStaff from '@salesforce/apex/ApplicationFederalAssistanceController.getOtherStaff';
import getLicenses from '@salesforce/apex/ApplicationFederalAssistanceController.getLicenses';
import { getFieldValue, getRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';

const columns = [
    { label: 'Last name', fieldName: 'Other_Staff_Last_Name__c', type : 'text', hideDefaultActions: true},
    { label: 'First name', fieldName: 'Other_Staff_First_Name__c', type : 'text',hideDefaultActions: true,},
    { label: 'Licensure', fieldName: 'Other_Staff_Licenses_Certifications__c', type : 'text', hideDefaultActions: true},
    {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
        iconName: 'utility:edit',
        variant: 'bare'
    }}
];

const columnsLicense = [
    { label: 'Type', fieldName: 'Licensure__c', type : 'text', hideDefaultActions: true},
    {label: 'Edit', hideDefaultActions: true, type: "button-icon", typeAttributes: {  
        iconName: 'utility:edit',
        variant: 'bare'
    }}
];

export default class LitcOtherStaffing extends utilities {

    @track showModal;
    @track selectedStaff;
    @track showTable;
    @track columns = columns;
    @track otherStaff;
    @track currentLicense;
    @api recordId;
    @api typeLicense;


    @track showModalLicense;
    @track showTableLicense;
    @track columnsLicense = columnsLicense;
    @track licenses;
    @track selectedLicense;


    @wire(getOtherStaff, { appId: '$recordId' })
    setReportsType(res) {
        this.result = res;
        if (res.data) {   
            this.otherStaff = res.data;      
            this.showTable = res.data.length > 0;
        }
        else if (res.error) {
            console.log(res.error);
        }
    }
    @wire(getLicenses, { appId: '$recordId', type: '$typeLicense' })
    setLicensesType(res) {
        this.resultLicenses = res;
        if (res.data) {   
            this.licenses = res.data;      
            this.showTableLicense = res.data.length > 0;
        }
        else if (res.error) {
            console.log(res.error);
        }
    }

    openAddStaffModal(){ 
        this.showModal = true;
    }
    openAddLicenseModal(){ 
        this.showModalLicense = true;
    }
    closeLicenseModal(){ 
        this.showModalLicense = false;
        this.selectedLicense = null;
        this.currentLicense = null;
    }

    handleDelete(){ 
        deleteRecord(this.selectedStaff).then(()=>{ 
            this.handleSuccess();
        })
    }
    handleDeleteLicense(){ 
        deleteRecord(this.selectedLicense).then(()=>{ 
            this.handleSuccess();
        })
    }

    openEditStaffModal(event){ 
        console.log(event.detail.row);
        this.selectedStaff = event.detail.row.Id;
        this.showModal = true;
    }
    openEditLicenseModal(event){ 
        this.selectedLicense = event.detail.row.Id;
        this.showModalLicense = true;
        this.currentLicense = event.detail.row.Licensure__c;
        console.log(this.selectedLicense);
    }

    closeEditStaffModal(){ 
        this.showModal = false;
        this.selectedStaff = null;
    }

    handleSuccess(){ 
        this.showNotification('Saved', 'Saved', 'success');
        this.closeEditStaffModal();
        this.closeLicenseModal();
        refreshApex(this.resultLicenses);
        refreshApex(this.result);
    }

    handleLicenseChange(event){ 
        this.currentLicense = event.target.value;
        console.log(this.currentLicense);
    }




    get showAdditionalFields(){ 
        return this.currentLicense && this.currentLicense !== 'Enrolled Agent';
    }

    get showOther(){ 
        return this.currentLicense === 'Other';
    }

}