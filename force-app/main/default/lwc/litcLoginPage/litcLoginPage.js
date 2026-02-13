import { LightningElement, wire, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { loadScript } from 'lightning/platformResourceLoader';
import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import { getFieldValue, getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import ACCOUNT_ID from '@salesforce/schema/Contact.AccountId';

import USER_ID from '@salesforce/user/Id';
import updateRecord from '@salesforce/apex/litcLoginController.updateRecord';
import createRecord from '@salesforce/apex/litcLoginController.createRecord';
import deleteRecord from '@salesforce/apex/litcLoginController.deleteRecord';
import getChildAccounts from '@salesforce/apex/litcLoginController.getChildAccounts';
import validateUEI from '@salesforce/apex/ApplicationFederalAssistanceController.validateUEI';
import { NavigationMixin } from 'lightning/navigation';
import utilities from 'c/utilities';

const columns = [
    { label: 'Name', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'Street', fieldName: 'BillingStreet', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'City', fieldName: 'BillingCity', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'State', fieldName: 'BillingState', type : 'text', wrapText: true, hideDefaultActions: true},
    // { label: 'Delete', hideDefaultActions: true, type: "button-icon", initialWidth: 100, typeAttributes: {  
    //     iconName: 'utility:delete',
    //     variant: 'bare',
    // }},
];

export default class CompliancePortalErrorPage extends utilities{

    @track contactId;
    @track accountId;
    @track stylePath = portalStyles;

    // account fields
    @track accountName; BillingStreet; BillingCity; BillingState; BillingPostalCode; sponsoringOrgSameValue; ueiValue;

    // contact fields
    @track firstName; lastName; title; phone;

    @track currentStep = '1';
    @track aoValue;

    @track parentAccountName;
    @track columns = columns;
    @track childAccounts = [];
    @track showTable;

    @track options= [{label: 'Yes, the sponsoring organization and the clinic are the same entity.', value: 'Yes'}, {label: 'No, the sponsoring organzation and the clinic are not the same entity.', value: 'No'}]
    @track roleOptions = [{label: '	Authorized Official', value: 'Authorized Official'}, {label: 'EBiz POC', value: 'EBiz POC'}];
    @track selectedRole;

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`)
        ]);
    }


    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    setData({error, data}) {
        if (data) {
            this.contactId = getFieldValue(data, CONTACT_ID);
            console.log(this.contactId);
        }
        else if (error) {
            console.log(error);
        }
    }

    @wire(getRecord, { recordId: '$contactId', fields: [ACCOUNT_ID] })
    contactRecord({ error, data }) {
        if (data) {
            this.accountId = getFieldValue(data, ACCOUNT_ID);
            console.log('Account ID:', this.accountId);
        } else if (error) {
            console.log(error);
        }
    }

    // @wire(getRecord, { recordId: '$accountId', fields: [NAME] })
    // accountRecord({ error, data }) {
    //     if (data) {
    //         console.log(data);
    //         this.parentAccountName = getFieldValue(data, NAME);
    //     } else if (error) {
    //         console.log(error);
    //     }
    // }

    @wire(getChildAccounts, {recordId: '$accountId'})
    childAccountData(result){
        this.childAccountResult = result;
        if(result.data){ 
            console.log(result.data)
            this.childAccounts = result.data;
            this.showTable = result.data.length > 0;
        } else if (result.error) console.log(result.error);
    }


    handleAccountChange(event){ 
        if(event.target.dataset.name === 'Name') this.accountName = event.target.value;
        if(event.target.dataset.name === 'BillingStreet') this.BillingStreet = event.target.value;
        if(event.target.dataset.name === 'BillingCity') this.BillingCity = event.target.value;
        if(event.target.dataset.name === 'BillingState') this.BillingState = event.target.value;
        if(event.target.dataset.name === 'BillingPostalCode') this.BillingPostalCode = event.target.value;
        if(event.target.dataset.name === 'UEI') this.ueiValue = event.target.value;
    }
    handleContactChange(event){ 
        if(event.target.dataset.name === 'FirstName') this.firstName = event.target.value;
        if(event.target.dataset.name === 'LastName') this.lastName = event.target.value;
        if(event.target.dataset.name === 'Title') this.title = event.target.value;
        if(event.target.dataset.name === 'Phone') this.phone = event.target.value;
        if(event.target.dataset.name === 'MiddleName') this.middleName = event.target.value;
    }

    handleAOChange(event){ 
        this.aoValue = event.target.checked;
    }
    get isAO(){ 
        return this.aoValue === true;
    }

    handleRoleChange(event){ 
        this.selectedRole = event.target.value;
    }
  

    async handleUpdateAccount(){ 
        if(!this.accountName  || !this.BillingStreet || !this.BillingCity || !this.BillingState || !this.BillingPostalCode || !this.sponsoringOrgSameValue){ 
            this.showNotification('Error', 'All fields are required', 'error');
        } else{ 
            let ueiValue = '';
            let errorMessage = 'The UEI you entered is invalid. Please ensure the UEI is exactly 12 alphanumeric characters with no spaces or special characters.'
            if(this.ueiValue){ 
                let samGovResult = await validateUEI({uei : this.ueiValue});
                console.log(samGovResult);
                if(samGovResult.errorDetails){ 
                    this.showNotification('Error', errorMessage, 'error');
                    return;
                } else{ 
                    ueiValue = this.ueiValue;
                }
            }

            let fields = {
                Name: this.accountName, 
                BillingStreet: this.BillingStreet,
                BillingCity : this.BillingCity,
                BillingState : this.BillingState,
                BillingPostalCode : this.BillingPostalCode, 
                Account_Type__c: 'LITC Sponsoring Organization',
                Sponsoring_Org_Same_As_Clinic__c: this.sponsoringOrgSameValue, 
                Recipient_UEI__c : ueiValue
            };
            console.log(fields);
            
            // ses custom function to update/create contacts/accounts due to permissions 
            updateRecord({recordId: this.accountId, objectName: 'Account', fields: fields }).then(()=>{ 
                if(this.sponsoringOrgSameValue === 'Yes'){ 
                    this.autoCreateChildAccount(ueiValue);
                    this.currentStep = '4';
                    this.showNotification('Success', 'Saved', 'success');
                } else{ 
                    this.currentStep = '3';
                    this.showNotification('Success', 'Saved', 'success');
                }
            }).catch(error=>{
                console.log(error)
           })
        }
    }

    // skip child account creation if they answer yes and autocreate
    autoCreateChildAccount(uei){ 
        console.log('in here');
        let fields = {
            Name: this.accountName + ' (Clinic)', 
            BillingStreet: this.BillingStreet,
            BillingCity : this.BillingCity,
            BillingState : this.BillingState,
            BillingPostalCode : this.BillingPostalCode, 
            ParentId : this.accountId, 
            Account_Type__c: 'LITC Clinic',
            Recipient_UEI__c : uei
        };
        console.log(fields);
        
        // ses custom function to update/create contacts/accounts due to permissions 
        createRecord({objectName: 'Account', fields: fields }).then((res)=>{ 
            const acrFields = {AccountId : res, contactId: this.contactId};   
            createRecord({objectName: 'AccountContactRelation', fields: acrFields }).catch((err)=>{ 
                console.log(err);
            })
        }).catch(error=>{
            console.log(error)
       })
    }

    handleUpdateContact(){ 
        if(!this.firstName || !this.lastName || !this.title || !this.phone || !this.selectedRole){ 
            this.showNotification('Error', 'All fields are required', 'error');
        } else{ 
            let fields = {
                FirstName: this.firstName, 
                LastName: this.lastName,
                Title : this.title,
                Phone : this.phone,
                LITC_Role_v2__c : this.selectedRole
            };
            console.log(fields);
            
            // ses custom function to update/create contacts/accounts due to permissions 
            updateRecord({recordId: this.contactId, objectName: 'Contact', fields: fields }).then(()=>{ 
                this.currentStep = '2';
                this.resetFields();
                this.showNotification('Success', 'Saved', 'success');
            }).catch(error=>{
                console.log(error)
           })
        }
    }

    async handleCreateAccount(){ 
        if(!this.accountName  || !this.BillingStreet || !this.BillingCity || !this.BillingState || !this.BillingPostalCode){ 
            this.showNotification('Error', 'All fields are required', 'error');
        } else{ 
            let fields = {
                Name: this.accountName, 
                BillingStreet: this.BillingStreet,
                BillingCity : this.BillingCity,
                BillingState : this.BillingState,
                BillingPostalCode : this.BillingPostalCode, 
                ParentId : this.accountId, 
                Account_Type__c: 'LITC Clinic',
            };
            console.log(fields);
            
            if(this.ueiValue){ 
                let samGovResult = await validateUEI({uei : this.ueiValue});
                console.log(samGovResult);
                if(samGovResult.errorDetails){ 
                    this.showNotification('Error', samGovResult.errorDetails, 'error');
                    return;
                } else{ 
                    fields.Recipient_UEI__c = this.ueiValue;
                }
            }
            
            // ses custom function to update/create contacts/accounts due to permissions 
            createRecord({objectName: 'Account', fields: fields }).then((res)=>{ 
                this.showNotification('Success', 'Saved', 'success');
                refreshApex(this.childAccountResult);
                this.resetFieldsAccount();

                console.log(res);
                console.log(res);

                const acrFields = {AccountId : res, contactId: this.contactId};   
                createRecord({objectName: 'AccountContactRelation', fields: acrFields }).catch((err)=>{ 
                    console.log(err);
                })
            }).catch(error=>{
                console.log(error)
           })
        }
    }


    resetFieldsAccount(){ 
        let fields = this.template.querySelectorAll('lightning-input');
        fields.forEach(field => {
            field.value = null;
        });
    }

    resetFields(){ 
        this.accountName = null;
        this.BillingStreet = null;
        this.BillingCity= null;
        this.BillingState = null;
        this.ueiValue = null;
        this.BillingPostalCode = null;
    }

    deleteClinic(event){ 
        let id = event.detail.row.Id;
        deleteRecord({objectName: 'Account', recordId: id}).then(()=>{ 
            refreshApex(this.childAccountResult);
        }).catch(error=>{
             console.log(error);
        })
    }

    handleFinalSubmit(){ 
        let fields = {Unverified__c : false};
        updateRecord({recordId: this.contactId, objectName: 'Contact', fields: fields }).then(()=>{ 
            this.currentStep = '4';
            this.showNotification('Success', 'Saved', 'success');
        }).catch(error=>{
            console.log(error)
       })
    }

    handleError(event){ 
        console.log(JSON.stringify(event));
    }


    navigatePortal(){ 
        let fields = {Unverified__c : false};
        updateRecord({recordId: this.contactId, objectName: 'Contact', fields: fields }).then(()=>{ 
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                    attributes: {
                        pageName: 'home'
                }
            }); 
            
            setTimeout(() => {
                window.location.reload();
            }, 1000);
        }).catch(error=>{
            console.log(error)
       })
    }

    handleNavigate(event){ 
        if(this.currentStep > event.target.value) { 
            this.currentStep = event.target.value;   
        }
    }

    handleSponsoringOrgChange(event){ 
        this.sponsoringOrgSameValue = event.target.value;
    }

    get currentStepOne(){ 
        return this.currentStep === '1';
    }
    get currentStepTwo(){ 
        return this.currentStep === '2';
    }
    get currentStepThree(){ 
        return this.currentStep === '3';
    }
    get currentStepFour(){ 
        return this.currentStep === '4';
    }

    get isSponsoringOrgYes(){ 
        return this.sponsoringOrgSameValue === 'Yes';
    }

}