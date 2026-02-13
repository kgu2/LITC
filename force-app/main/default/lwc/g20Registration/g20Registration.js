import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue, getRecord, getRecordNotifyChange , updateRecord} from 'lightning/uiRecordApi';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from '@salesforce/user/Id';
import utilities from 'c/utilities';
import getRegistrations from '@salesforce/apex/g20GuestRegistrationController.getRegistrations';
import getG20Event from '@salesforce/apex/g20RegistrationController.getG20Event';
import portalStyles from '@salesforce/resourceUrl/g20Styles';
// import updateRecordv from '@salesforce/apex/g20GuestRegistrationController.updateRecord';
import createRecord from '@salesforce/apex/g20GuestRegistrationController.createRecord';
import fetchFiles from '@salesforce/apex/g20GuestRegistrationController.fetchFilesV2';
import relinkFiles from '@salesforce/apex/g20RegistrationController.relinkFile';
import getAllRegistrations from '@salesforce/apex/g20GuestRegistrationController.getAllRegistrations';

const columns = [
    { label: 'First Name', hideDefaultActions: true, fieldName: 'DI_First_Name__c', type : 'text', editable: false},
    { label: 'Last Name', hideDefaultActions: true, fieldName: 'DI_Last_Name__c', type : 'text', editable: false},
    { label: 'Email', hideDefaultActions: true, fieldName: 'DI_Email__c', type : 'text', editable: false},
    { label: 'Role', hideDefaultActions: true, fieldName: 'G20_Role__c', type : 'text', editable: false},
    { label: 'Status', fieldName: 'Status__c', type : 'text', hideDefaultActions: true,
        cellAttributes: { class: { fieldName: 'statusStyle' } }
    },
    {label: 'View/Edit', hideDefaultActions: true, type: "button", name: 'provideInfo', typeAttributes: {  
        label: 'View record',
        variant: 'base',
        initialWidth: 175,
        class : { fieldName: 'stylingProvideInformation' }
    }},
    {
        label: 'Resend invite', hideDefaultActions: true, type: 'button', typeAttributes: {
            label: 'Resend',
            name: 'extend_expiration',
            variant: 'base',
            disabled: { fieldName: 'isExpired' }, 
            class : { fieldName: 'stylingResend' }
        }
    },
];


export default class LitcContactPage extends utilities {
    stylePath = portalStyles;
    columns = columns;
    @track isLoading;

    @track contactId;
    @track currentStep = '1';
    @track selectedId;
    @track g20EventId;

    dynamicAcceptedFormat = ['.jpg', '.jpeg', '.png'];

    optionsSelf= [{label: 'Myself', value: 'self'}, {label: 'Someone else', value: 'other'}];
    optionsRegistrationType= [{label: 'Full', value: 'full'}, {label: 'Basic', value: 'basic'}]
    selectedValueSelf; 
    selectedValueType;

    showTable;
    registrations;

    showRegistrationModal;
    uploadedDocumentId;
    disableEdits;
    refreshUpload = true;

    allRegistrations;
    showPublicURL;

    showTitleOther; showMinistryOther;

    @api role;
    @api accountId;
    @api delegation;
    @api organization;
    @track selectedRole;

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
        ]);
    }

    // get all contacts 
    @wire(getAllRegistrations)
    getAllRegistrations(result){
        this.allRegistrationsResult = result;
        if(result.data){ 
            // console.log(result.data)
            this.allRegistrations = result.data;
        } else if (result.error) console.log(result.error);
    }

    @wire(getRegistrations, {contactId: '$contactId'})
    setData(result) {
        this.registrationRes = result;
        if (result.data) {
            let tempApps = [];
            console.log(result.data)
            for (let item of result.data) {
                let tempRecord = Object.assign({}, item);
                if (tempRecord.Status__c === 'Submitted' || tempRecord.Status__c === 'Accepted') {
                    tempRecord.statusStyle = 'slds-text-color_success';
                } else{ 
                    tempRecord.statusStyle = 'slds-text-color_warning';
                }

                tempRecord.dynamicIconProvideInfo = 'action:preview';

                if(tempRecord.Status__c !== 'Pending' || !tempRecord.Guest_Registration__c){ 
                    tempRecord.stylingResend = 'slds-hide';
                } 
                if(tempRecord){ 
                    tempRecord.isExpired = true;
                    const deadline = new Date(tempRecord.Guest_Registration_Deadline__c);
                    tempRecord.isExpired = deadline > new Date();
                }
                // tempRecord.stylingResend = 'slds-hide';
                // tempRecord.stylingEdit = 'slds-hide';

                tempApps.push(tempRecord);
            }

            this.showTable = result.data.length > 0;
            this.registrations = tempApps;
        }
        else if (result.error) {
            console.log(result.error);
        }
    }
    @wire(getG20Event)
    setEventData({error, data}) {
        if (data) {
            this.g20EventId = data[0].Id;
        }
        else if (error) {
            console.log(error);
        }
    }

    // get current user contact id
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    setContactData({error, data}) {
        if (data) {
            this.contactId = getFieldValue(data, CONTACT_ID);
        }
        else if (error) {
            console.log(error);
        }
    }

    async handleNavigate(event){ 
        if(this.selectedValueSelf === 'self') this.selectedValueType = 'full';

        let inputFields;
        if(event.target.label === 'Next'){ 

            let tab = event.target.value;
            
            if(tab === '4'){ 
                const res = await fetchFiles({ recordId: this.contactId });

                let fileFound = res.some(file => file.File_Prefix__c === 'passport');
                if (fileFound) {
                    this.currentStep = tab 
                } else{ 
                    this.showNotification('Error', 'Missing file', 'error'); 
                }
            } else{ 
                let prevTab = event.target.value - 1;
                inputFields = this.template.querySelectorAll('.tab' + prevTab);

                let isValid = true;
                let existingEmailValid = true;

                inputFields.forEach(input => {
                    if(!input.value) {
                        this.showNotification('Error', 'All required fields must be complete', 'error');
                        isValid = false;
                    }

                    if(input.fieldName === 'DI_Email__c'){ 
                        console.log(input.value);
                        const foundDuplicate = this.allRegistrations.some(data => {
                            if (data.DI_Email__c === input.value) {
                                this.showNotification('Error', 'Registration for this email already exists', 'error');
                                return true;
                            }
                            return false;
                        });
                        existingEmailValid = !foundDuplicate;
                    }
                });

                

                if(isValid && existingEmailValid){
                    this.currentStep = event.target.value;  
                }
            }
        } else{ 
            this.currentStep = event.target.value;  
        }
        
        // this.currentStep = event.target.value;  
    }

    handleSelfChange(event){ 
        this.selectedValueSelf = event.target.value;
        // this.selectedValueType = this.selectedValueSelf === 'self' ? 'full' : 'basic';
    }
    handleFullBasicChange(event){ 
        this.selectedValueType = event.target.value;
    }

    handleRoleChange(event){ 
        this.selectedRole = event.target.value;
        console.log(this.selectedRole);
    }

    handleTitleChange(event){ 
        this.showTitleOther = event.target.value === 'Other';
    }
    handleMinistryChange(event){ 
        this.showMinistryOther = event.target.value === 'Other';
    }

    async handleSubmitRegistration(event){
        event.preventDefault();
        this.isLoading = true;
        console.log('in submit')
        const fields = event.detail.fields;

        const foundDuplicate = this.allRegistrations.some(data => {
            if (data.DI_Email__c === fields.DI_Email__c) {
                this.showNotification('Error', 'Registration for this email already exists', 'error');
                return true;
            }
            return false;
        });

        if(foundDuplicate) {
            this.isLoading = false;
            return;
        }
 
        fields.G20_Event__c = this.g20EventId;
        fields.Name = fields.DI_First_Name__c + ' ' + fields.DI_Last_Name__c;
        fields.Contact__c = this.contactId; // created by contact
        fields.Created_For_Contact__c = this.contactId;
        fields.Delegation_International_Organization__c = this.delegation;
        let guestUser = false;

        if(this.isSelectedFull){ 
            fields.Status__c= 'Submitted';
            fields.Submitted_Date__c = new Date().toISOString();
        } else{ 
            // create contacts for DCO / DAO users 
            if(fields.G20_Role__c === 'Delegation Control Officer (DCO)' || fields.G20_Role__c === 'Delegation Accreditation Officer (DAO)'){ 

                console.log('creating contact for DCO/DAO');

                let contactFields = { 
                    FirstName: fields.DI_First_Name__c, 
                    LastName: fields.DI_Last_Name__c,
                    Title : fields.DI_Title__c,
                    Phone : fields.DI_Phone_Number__c,
                    Email: fields.DI_Email__c,
                    G20_Role__c : fields.G20_Role__c,
                    AccountId : this.accountId, 
                    Delegation_International_Organization__c : this.delegation
                };
                // let duplicateContactId = null;
                // const isDuplicate = this.allContacts.some(contact => {
                //     if (contact.Email === emailField) {
                //         duplicateContactId = contact.Id;
                //         return true;
                //     }
                //     return false;
                // });

                console.log('in here')
                try{ 
                    let createdContact = await createRecord({objectName: 'Contact', fields: contactFields });
                    console.log(createdContact);
                    fields.Created_For_Contact__c = createdContact;
                } catch (error){ 
                      console.log(error);
                }
            } 
            // guest users
            else{ 

                console.log('GUEST USER');
                fields.Guest_Registration__c = true;
                fields.Guest_Registration_Deadline__c = this.setDeadline();
                fields.Status__c = 'Pending';
                guestUser = true;
                // fields.Access_Token__c = await encryptRecordId();
            }
        }
        
        createRecord({objectName: 'G20_Event_Registration__c', fields: fields, isGuest: guestUser }).then((res)=>{ 
            
            if(this.uploadedDocumentId){ 

                relinkFiles({contentDocumentId: this.uploadedDocumentId, newParentId: res}).then(()=>{ 
                    // this.refreshUpload = false;
                    console.log('in here')
                    const temp = this.template.querySelector('c-file-loader');
                    console.log(temp)
                    setTimeout(() => {
                        if (temp) {
                            console.log('found child:', temp);
                            temp.manualRefresh();
                        }
                    }, 0);
              
                    this.displaySuccess();
                }).catch(err=>{console.log(err)})
            } else{ 
                this.displaySuccess();
            }
        }).catch(error=>{
            console.log(error)
        })
    }

    displaySuccess(){
        this.showNotification('Success', 'Thank you for registering', 'success');
        this.currentStep = '1';
        refreshApex(this.registrationRes)
        refreshApex(this.allRegistrationsResult);
        this.clearFields();
        // this.refreshUpload = true;
        this.isLoading = false;
    }

    clearFields(){ 
        this.selectedValueSelf = null;
        this.selectedValueType = null;
        this.showTitleOther= null;
        this.showMinistryOther = null;
        const lightningFields = this.template.querySelectorAll('lightning-input-field');
        lightningFields.forEach(field => {
            field.value = null;
        });
        this.uploadedDocumentId = null;
    }

    handleSuccess(){
        this.showNotification('Success', 'Thank you for registering', 'success');
        this.currentStep = '1';
        this.showRegistrationModal = false;
        this.isLoading = false;
    }

    async openRegistrationModal(event){ 
        let button = event.detail.action.class.fieldName;
        this.selectedId = event.detail.row.Id;

        if(button === 'stylingProvideInformation'){ 
            this.disableEdits = event.detail.row.Status__c === 'Approved' || event.detail.row.Status__c === 'Submitted';
            this.showRegistrationModal = true;
            this.showPublicURL = event.detail.row.Guest_Registration__c ? event.detail.row.Public_Link_URL__c : null;
            console.log(this.showPublicURL)
        } else{ 
            let deadline = this.setDeadline()
             updateRecord({ fields: {Id: this.selectedId, Guest_Registration_Deadline__c: deadline, Resend_public_link_email__c: true} }).then(() => {
                this.showNotification('Success', 'Invitation resent', 'success');
                refreshApex(this.registrationRes)
            }).catch(error=>{
                console.log(error);
            })
        }
    }
    closeRegistrationModal(){ 
        this.showRegistrationModal = false;
        this.selectedId= null;
    }

    async handleSubmitEdit(event){ 
        event.preventDefault()
        console.log('in here');
        const res = await fetchFiles({ recordId: this.selectedId });
        if (res && res.length > 0) {
            this.template.querySelector('.g20Edit').submit();
        } else {
            this.showNotification('Error', 'Missing file', 'error');
        }
    }

    handleFileLoaded(event){ 
        this.uploadedDocumentId = (event.detail.files.map(file => file.documentId))[0];
        this.disableEdits = true;
    }

    setDeadline(){ 
        let expirationDate = new Date();
        expirationDate.setDate(expirationDate.getDate() + 3);
        return expirationDate.toISOString();
    }

    @track showPassport = false;
    handleHideToggle(){ 
        console.log(this.showPassport)
        this.showPassport = !this.showPassport;
    }

    get currentStepOne(){ 
        return this.currentStep === '1' ? 'slds-show' : 'slds-hide';
    }
    get currentStepTwo(){ 
        return this.currentStep === '2' ? 'slds-show' : 'slds-hide';
    }
    get currentStepThree(){ 
        return this.currentStep === '3' ? 'slds-show' : 'slds-hide';
    }
    get currentStepFour(){ 
        return this.currentStep === '4' ? 'slds-show' : 'slds-hide';
    }
    get currentStepFive(){ 
        return this.currentStep === '5' ? 'slds-show' : 'slds-hide';
    }
    get selectedValueTypeOther(){
        return this.selectedValueSelf === 'other';
    }


    get isSelectedBasic(){ 
        return this.selectedValueType && this.selectedValueType === 'basic'
    }
    get isSelectedFull(){ 
        return this.selectedValueType && this.selectedValueType === 'full';
    }
   

    get isRoleDCO(){ 
        return this.role === 'Delegation Control Officer (DCO)';
    }

    get isRoleDAO(){ 
        return this.role === 'Delegation Accreditation Officer (DAO)';
    }


    get showTextDCODAO(){ 
        return this.selectedRole === 'Delegation Accreditation Officer (DAO)' || this.selectedRole === 'Delegation Control Officer (DCO)'
    }


    radioOptions = [
        { label: 'I will complete the registration ', value: 'full' },
        { label: 'Send invitation for delegate to complete registration ', value: 'basic' },
    ];

    


}