import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import updateOnboardingExpirationDate from '@salesforce/apex/litcLoginController.updateOnboardingExpirationDate';
import { getFieldValue, getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import ACCOUNT_ID from '@salesforce/schema/Contact.AccountId';
import ROLE from '@salesforce/schema/Contact.LITC_Role_v2__c';
import USER_ID from '@salesforce/user/Id';
import updateRecord from '@salesforce/apex/litcLoginController.updateRecord';
import createRecord from '@salesforce/apex/litcLoginController.createRecord';
import deleteRecord from '@salesforce/apex/litcLoginController.deleteRecord';
import getChildAccounts from '@salesforce/apex/litcLoginController.getChildAccounts';
import getAllRelatedContacts from '@salesforce/apex/litcLoginController.getAllRelatedContacts';
import getContacts from '@salesforce/apex/litcLoginController.getRelatedContacts';
import getMyAccount from '@salesforce/apex/litcLoginController.getMyAccount';
import { NavigationMixin } from 'lightning/navigation';
import utilities from 'c/utilities';

const columns = [
    { label: 'Name', hideDefaultActions: true, fieldName: 'Name', type : 'text', editable: false},
    { label: 'Email', hideDefaultActions: true, fieldName: 'Email', type : 'text', editable: false},
    { label: 'Title', hideDefaultActions: true, fieldName: 'Title', type : 'text', editable: false},
    { label: 'Role', hideDefaultActions: true, fieldName: 'LITC_Role_v2__c', type : 'picklist', editable: false},
    // { label: 'On-boarding Expiration Date', hideDefaultActions: true, fieldName: 'On_boarding_Expiration_Date__c', type : 'date-local', editable: false}, 
    {
        label: 'On-boarding email',
        hideDefaultActions: true,
        type: 'button',
        typeAttributes: {
            label: 'Resend',
            name: 'extend_expiration',
            variant: 'Brand-outline',
            disabled: { fieldName: 'isOnBoardingExpired' }, 
            class : { fieldName: 'stylingResend' }
        }
    },
    {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
        iconName: 'utility:edit',
        variant: 'bare', 
        class : { fieldName: 'stylingEdit' }
    }}
];


export default class LitcContactPage extends utilities {

    // current user values
    @track accountId;
    @track contactId;

    @track showAddContactModal;
    @track showEditContactModal;

    // picklist
    @track childAccountValue;
    @track childAccounts;

    @track columns = columns;
    @track contacts;
    @track allContacts;

    @track selectedContact;
    @track selectedFirstName; selectedLastName; selectedTitle; selectedPhone; selectedEmail; selectedRole;

    @track selectedRole;
    
    @track showConfirmationDuplicate;
    @track duplicateContactId;


    @api myRole;

    handleError(event){ 
        console.log('in error')
        console.log(event);
    }

    // get current user contact id
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    setData({error, data}) {
        if (data) {
            this.contactId = getFieldValue(data, CONTACT_ID);
        }
        else if (error) {
            console.log(error);
        }
    }

    // get parent account id
    @wire(getRecord, { recordId: '$contactId', fields: [ACCOUNT_ID, ROLE] })
    contactRecord({ error, data }) {
        if (data) {
            this.accountId = getFieldValue(data, ACCOUNT_ID);
            // this.myRole = getFieldValue(data, ROLE);
        } else if (error) {
            console.log(error);
        }
    }

    // get all child accounts to populate picklist
    @wire(getChildAccounts, {recordId: '$accountId'})
    childAccountData(result){
        if(result.data){    
            getMyAccount({recordId: this.accountId}).then(res=>{ 
                console.log(res);

                this.childAccounts = result.data.map(item => ({
                    label: item.Name, 
                    value: item.Id 
                }));

                let myAccount = {label: res.Name, value: res.Id};
                if(res.Account_Type__c === 'LITC Sponsoring Organization'){ 
                    myAccount = {label: res.Name + ' (Sponsoring org)', value: res.Id};
                } 
         
                this.childAccounts.push(myAccount)
            }) 

        } else if (result.error) console.log(result.error);
    }


    // get contacts related to selected child account
    @wire(getContacts, {recordId: '$childAccountValue'})
    getContactsData(result){
        this.contactsResult = result;
        if(result.data){ 
            console.log(result.data);
            let myRole = this.myRole;
            let contacts = [];
            result.data.forEach(function(item) {
                let tempRecord = Object.assign({}, item);

                let contactWithExtraField = {
                    ...tempRecord.Contact,
                    isOnBoardingExpired: tempRecord.isOnBoardingExpired 
                };

                // if(myRole !== 'Authorized Official' && myRole !== 'EBiz POC') { 
                if( !myRole || (!myRole.includes('Authorized Official') && !myRole.includes('EBiz POC'))){
                    contactWithExtraField.stylingResend = 'slds-hide';
                    contactWithExtraField.stylingEdit = 'slds-hide';
                }

                contacts.push(contactWithExtraField);
            });
           this.contacts = contacts;
        } else if (result.error) console.log(result.error);
    }

    // get all contacts 
    @wire(getAllRelatedContacts, {recordId: '$accountId'})
    getAllContactsData(result){
        this.allContactsResult = result;
        if(result.data){ 
            console.log(result.data)
           this.allContacts = result.data;
        } else if (result.error) console.log(result.error);
    }

    handleSubmitAddContact(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields.Active__c = true;
        fields.AccountId = this.childAccountValue;
        fields.LITC_Role_v2__c = this.selectedRole;

        const emailField = fields.Email;
        console.log(emailField);

        // const isDuplicate = this.allContacts.some(contact => contact.Email === emailField);
        let duplicateContactId = null;
        const isDuplicate = this.allContacts.some(contact => {
            if (contact.Email === emailField) {
                duplicateContactId = contact.Id;
                return true;
            }
            return false;
        });

        if(isDuplicate){ 
            this.duplicateContactId = duplicateContactId;
            this.showConfirmationDuplicate = true;
            this.showAddContactModal = false;
        } else{ 
            createRecord({objectName: 'Contact', fields: fields }).then((res)=>{ 
                this.showNotification('Success', 'Saved', 'success');
                this.showAddContactModal = false;

                // sets initial expiration date to the application deadline july 14, => one day after. If past deadline set to 14 days
                const today = new Date();
                let newExpirationDate = new Date(2025, 6, 15);
                
                if (today >= newExpirationDate) {
                    newExpirationDate = new Date(); 
                    newExpirationDate.setDate(today.getDate() + 14); 
                }
                
                const formattedDate = newExpirationDate.toISOString().split('T')[0];
                updateOnboardingExpirationDate({ contactId: res, newExpirationDate: formattedDate}).catch(err=>{
                     console.log(err);
                })
                refreshApex(this.contactsResult);
                refreshApex(this.allContactsResult);
            }).catch(error=>{
                console.log(error)
            })
        }
    }

    // if finds duplicate and confirmation = yes then adds indirect relationship
    handleAddDuplicate(){ 
        const fields = {AccountId : this.childAccountValue, contactId: this.duplicateContactId};       
        createRecord({objectName: 'AccountContactRelation', fields: fields }).then(()=>{ 
            this.showNotification('Success', 'Saved', 'success');
            refreshApex(this.contactsResult);
            refreshApex(this.allContactsResult);
            this.closeConfirmationDuplicateModal();
        }).catch(error=>{
            console.log(error);
            if(error.body.message.includes('DUPLICATE_VALUE')){
                this.showNotification('Error...', 'Contact already exists for this account', 'error');
                this.closeConfirmationDuplicateModal();
            }
        })
    }

    handleSubmitEditContact(event){
        event.preventDefault();
        const fields = event.detail.fields;
        fields.LITC_Role_v2__c = this.selectedRole;

        updateRecord({recordId: this.selectedContact, objectName: 'Contact', fields: fields }).then(()=>{ 
            this.showNotification('Success', 'Saved', 'success');
            this.showEditContactModal = false;
            refreshApex(this.contactsResult);
            refreshApex(this.allContactsResult);
            getRecordNotifyChange([{recordId: this.selectedContact}]);

        }).catch(error=>{
            console.log(error)
        })
    }

    handleAccountChange(event){ 
        this.childAccountValue = event.target.value;
    }

    openEditContactModal(event){ 
        this.selectedContact = event.detail.row.Id;
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        if (actionName === 'extend_expiration') {

            this.updateExprityDate(event)

        } else 
        {
            this.selectedFirstName = event.detail.row.FirstName;
            this.selectedLastName = event.detail.row.LastName;
            this.selectedEmail = event.detail.row.Email;
            this.selectedPhone = event.detail.row.Phone;
            this.selectedRole = event.detail.row.LITC_Role_v2__c;
            this.selectedTitle = event.detail.row.Title;
    
            console.log(this.selectedRole)
            this.showEditContactModal = true;
        }
    }

    updateExprityDate(event)
    {
        this.selectedContact = event.detail.row.Id;
        const newExpirationDate = new Date();
        newExpirationDate.setDate(newExpirationDate.getDate() + 14);
        const formattedDate = newExpirationDate.toISOString().split('T')[0];
        const convertedDate = new Date(formattedDate);

        // Update the record
/*         const fields = {
            Id: this.selectedContact,
            On_boarding_Expiration_Date__c: formattedDate
        }; */

        updateOnboardingExpirationDate({ 
            contactId: this.selectedContact, 
            newExpirationDate: formattedDate 
        })
        .then(() => {
            this.showNotification('Success', 'Expiration date extended successfully', 'success');
            refreshApex(this.contactsResult);
        })
        .catch(error => {
            console.error('Error updating expiration date:', error);
            this.showNotification('Error', `Failed to update expiration date: ${error.body.message}`, 'error');
        });

    }

    closeEditContactModal(){ 
        this.showEditContactModal = false;
    }
    closeAddContactModal(){
         this.showAddContactModal = false;
    }
    openAddContactModal(){
        this.showAddContactModal = true;
    }
    closeConfirmationDuplicateModal(){ 
        this.showConfirmationDuplicate = false;
    }


    handleRoleChange(event){ 
        this.selectedRole = event.target.value;
    }
    get roleOptions(){ 
        return [{label: 'LITC Member', value: 'LITC Member'}, {label: 'LITC Administrator', value: 'LITC Administrator'}]
    }

    // disable role update if selecting self (Authorizing official), only ebiz poc/ ao can update their own role
    get disableRoleUpdate(){ 
        return this.selectedContact === this.contactId && !this.isAO;
    }


    get isAO(){ 
        return this.myRole != undefined && (this.myRole.includes('Authorized Official') || this.myRole.includes('EBiz POC'));
        // return this.myRole === 'Authorized Official' || this.myRole === 'EBiz POC';
    }

    // get isEbizPOC(){ 
    //     return this.myRole != undefined && (this.myRole.includes('Authorized Official') || this.myRole.includes('EBiz POC'));
    // }

}