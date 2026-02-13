import { LightningElement, wire, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import getMyRecord from '@salesforce/apex/app605Controller.getMyRecord';
import getSLTApplicationData from '@salesforce/apex/app605Controller.getSLTApplicationData';
import getPreviousLATCFApp from '@salesforce/apex/app605Controller.getPreviousLATCFApp';
import handleReturnToDraft from '@salesforce/apex/app605Controller.handleReturnToDraft';
import getWireNum from '@salesforce/apex/app605Controller.getWireNum';
import STATUS_ONE from '@salesforce/schema/X605_Application__c.Cert_Status__c';
import STATUS_TWO from '@salesforce/schema/X605_Application__c.CREC_Status__c';

const numberOfFields = 25;
const FIELDS = [STATUS_ONE, STATUS_TWO];


export default class App605Form extends LightningElement {
    @api recordId;
    @api disableEdits;
    @api isSaved;
    @api recipType;
    @track application;
    @track isLoading = false;
    @track showModalReturnDraft;
    @track showModalImport;
    @track progress = 0;
    @track useless = 0;
    @track showReturnToDraft;
    @track statusOne;
    @track statusTwo;
    @track recipType;
    @api secondTranche;

    @track isTimer;
    @track errors;
    @track acctError; conPhoneError; finPhoneError; postalError; wireError; achError; ueiError; tinError; confirmACHError; confirmWireError; confirmAcctError;

    @wire(getMyRecord, {recordId: '$recordId',useless: '$useless'})
    setData(data, error){ 
        if(data.data){ 
            let tempData = JSON.parse(JSON.stringify(data.data));
            let size = Object.keys(tempData).length - 2;    // subtract 2 because of id and status
            //console.log(tempData);
            this.showReturnToDraft = tempData.Status__c == 'Awaiting Signature'? true : false;
            this.recipType = tempData.Type_of_Recipient__c;
            //console.log(size);
            this.progress = (size / numberOfFields) * 100;
            // console.log(this.progress);

            const selectedEvent = new CustomEvent('getprogress', {
                detail: this.progress
            });
            this.dispatchEvent(selectedEvent); 

            getWireNum({recordId: this.recordId}).then((data)=>{ 
                tempData.Routing_Transit_Number_WIRE__c = data;
                let tempErrors = [];
                const myErrors = this.handleValidations(tempData);
    
                Object.values(myErrors).forEach(item => {
                    if(item.isValid == false) { 
                        // console.log(item);
                        tempErrors.push(item.error);
                        setTimeout(() => this.template.querySelector(item.class).classList.add('slds-has-error'));
                    }
                    else{ 
                        setTimeout(() => this.template.querySelector(item.class).classList.remove('slds-has-error'));
                    }
                });
                
                if(tempErrors.length != 0){ 
                    this.errors = tempErrors;
                } else {
                    this.errors = false;
                }
                console.error(this.errors);
            });
        }
        else if(error) console.log(error);
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.statusOne = getFieldValue(data, STATUS_ONE);
            this.statusTwo = getFieldValue(data, STATUS_TWO);
            //console.log(data);
        }

        else if(error){ 
            console.error(error);
        }
    }

    connectedCallback(){
        // console.log(this.recordId);
    }
    renderedCallback(){
        var ringcon = document.getElementsByClassName("ringContainer")[0];
        if(ringcon){
            ringcon.classList.remove('notransition');
            // console.log('removed');
        }else{
            // console.log('not removed');
        }
    }

    handlePaste(event){
        event.preventDefault();
    }

    autosave(event){ 
        event.preventDefault();

        const fields = this.template.querySelectorAll('lightning-input-field');
        const updateFields = { Id: this.recordId };

        fields.forEach((input) => {
            updateFields[input.fieldName] = input.value;
        });

        this.dispatchEvent(new CustomEvent('issaving', {detail: {isSaving: true, isSaved: false}}));
        clearTimeout( this.isTimer );

        updateRecord({ fields: updateFields }).then(()=>{
            this.useless++;
            refreshApex(this.setData);
            // console.log("SAVED");
        }).catch(error=>{
            console.error(error);
        }).finally(()=>{ 
            this.isTimer = setTimeout(() => {
                this.useless++;
                refreshApex(this.setData);
                this.dispatchEvent(new CustomEvent('issaving', {detail: {isSaving: false, isSaved: true}}));
            }, 1000);
        })
    }

    handleImport(){
        if(this.secondTranche){ 
            const fields = this.template.querySelectorAll('lightning-input-field');
            const updateFields = { Id: this.recordId };

            getPreviousLATCFApp({recordId: this.recordId}).then(data=>{ 
                console.log(data);
                fields.forEach(field => {
                    for (let key in data) {
                        if(field.fieldName === key){ 
                            field.value = data[key];
                        }
                    }
                });
    
                fields.forEach((input) => {
                    updateFields[input.fieldName] = input.value;
                });
    
                updateRecord({fields: updateFields}).then(()=>{ 
                    this.useless++;
                    refreshApex(this.setData);
                    this.showNotification('Success','Information successfully imported', 'success');
                }).catch(error=>{ 
                    this.showNotification('Error','Could not import information. Please re-enter all data', 'error');
                    console.error(error);
                })

            }).catch(error=>{
                console.log(error)
                this.showNotification('Error','Could not import information. Please re-enter all data', 'error');
            }).finally(()=>{ 
                this.closeImportModal();
            })
        } else{ 
            const fields = this.template.querySelectorAll('lightning-input-field');
            const updateFields = { Id: this.recordId };
    
            getSLTApplicationData({recordId: this.recordId}).then(data=>{
    
                fields.forEach(field => {
                    for (let key in data) {
                        if(field.dataset.nametwo == key){ 
                            field.value = data[key];
                        }
                        else if(field.dataset.name == key){
                            field.value = data[key];
                        }
                    }
                });
    
                fields.forEach((input) => {
                    updateFields[input.fieldName] = input.value;
                });
    
                updateRecord({fields: updateFields}).then(()=>{ 
                    this.useless++;
                    refreshApex(this.setData);
                    this.showNotification('Success','SLFRF Application Information successfully imported', 'success');
                }).catch(error=>{ 
                    this.showNotification('Error','Could not import SLFRF Application Information. Please re-enter all data', 'error');
                    console.error(error);
                })
            
    
            }).catch(error=>{
                console.error(error);
                this.showNotification('Error','Could not import SLFRF Application Information. Please re-enter all data', 'error');
            }).finally(()=>{ 
                this.closeImportModal();
            })
        }
    }

    handleNav(event){
        // console.log(event.target.name)
        const selectedEvent = new CustomEvent("changetab", {
            detail: event.target.name
        });
        this.dispatchEvent(selectedEvent);
    }

    openImportModal(){ 
        this.showModalImport = true;
    }

    closeImportModal(){ 
        this.showModalImport = false;
    }

    openReturnDraftModal(){ 
        this.showModalReturnDraft = true;
    }

    closeReturnDraftModal(){ 
        this.showModalReturnDraft = false;
    }

    returnToDraft(){
        this.closeReturnDraftModal();
        this.isLoading = true;
        handleReturnToDraft({recordId : this.recordId}).then(()=>{
            window.location.reload();
        }).catch(error=>{ 
            console.error(error);
        }).finally(()=>{ 
            this.isLoading = false;
        });
    }

    handleSubmit(event){ 
        event.preventDefault();
        // console.log('in submit');
        const fields = event.detail.fields;
        // console.log(JSON.stringify(fields));
        this.template.querySelector('lightning-record-edit-form').submit(fields);
    }

    handleSuccess(event){ 
        event.preventDefault();
        // console.log('success');
    }

    handleError(event){ 
        console.error(JSON.stringify(event));
    }

    @api refreshFromAnotherTab(){
        // console.log("REFRESHING FROM ANOTHER TAB");
        this.useless++;
        refreshApex(this.setData);
    }

    showNotification(ntf_Title, ntf_Message, ntf_Variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: ntf_Title,
                message: ntf_Message,
                variant: ntf_Variant,
                mode: 'dismissable'
            }),
        );
    }

    handleValidations(fields){
        let postcode = fields.Postal_Code__c;
        let wire = fields.Routing_Transit_Number_WIRE__c;
        let ach = fields.Routing_Transit_Number_ACH__c;
        let acctNum = fields.Recipient_Account_Number__c;
        let phoneNum = fields.Contact_Person_Phone__c;
        let financialPhone = fields.Financial_Institution_Telephone_Number__c;
        let confirmWire = fields.Confirm_Routing_Number_WIRE__c;
        let confirmACH = fields.Confirm_Routing_Number_ACH__c;
        let confirmAccount  = fields.Confirm_Recipient_Account_Number__c;
        let uei = fields.Recipient_UEI__c;
        let tin = fields.Recipient_s_Taxpayer_ID_Number__c;
 

        const obj = {
            actNumFormatValid: {isValid: true, error: 'Recipient Account Number must be at least 4 digits.', class: '.acctNum'},
            contactPhoneFormatValid: {isValid: true, error: 'Contact Phone must be at least 10 digits.', class: '.contactPhone'},
            financialPhoneFormatValid: {isValid: true, error: 'Financial Institution Telephone Number must be at least 10 digits.', class: '.finPhone'},
            postFormatValid: {isValid: true, error: 'Postal Code + 4 must be entered in its correct format.', class: '.postCode'},
            wireFormatValid: {isValid: true, error: 'Routing Number (Wire) must be 9 digits.', class: '.wire'},
            achFormatValid: {isValid: true, error: 'Routing Number (ACH) must be 9 digits.', class: '.ach'},
            confirmWireValid: {isValid: true, error: 'Routing Numbers (Wire) must match', class: '.confirmWire'},
            confirmACHValid: {isValid: true, error: 'Routing Numbers (ACH) must match', class: '.confirmACH'},
            confirmAccountValid: {isValid: true, error: 'Account Numbers must match', class: '.confirmAcct'},
            ueiValid: {isValid: true, error: 'UEI Number must be 12 digits', class: '.ueiField'},
            tinValid: {isValid: true, error: 'Taxpayer ID Number must be 9 digits', class: '.tin'},
        };
    
        var regexPost = new RegExp("\\d{5}$|\\d{5}-\\d{4}$");
        var regexWire = new RegExp("\\d{9}$|X{5}\\d{4}$");
        var regexAch = new RegExp("\\d{9}$|X{5}\\d{4}$");

        if ((acctNum != '' && acctNum != undefined) && acctNum.length <= 3) obj.actNumFormatValid.isValid = false;
        if ((phoneNum != '' && phoneNum != undefined) && phoneNum.length < 10) obj.contactPhoneFormatValid.isValid = false;
        if ((financialPhone != '' && financialPhone != undefined) && financialPhone.length < 10) obj.financialPhoneFormatValid.isValid = false;
        if ((postcode != '' && postcode != undefined) && !regexPost.test(postcode)) obj.postFormatValid.isValid = false;
        if ((wire != '' && wire != undefined) && (!regexWire.test(wire) || wire == '000000000')) obj.wireFormatValid.isValid = false;
        if ((ach != '' && ach != undefined) && (!regexAch.test(ach) || ach == '000000000')) obj.achFormatValid.isValid = false;
        if ((uei != '' && uei != undefined) && uei.length != 12) obj.ueiValid.isValid = false;
        if ((tin != '' && tin != undefined) && tin.length != 9) obj.tinValid.isValid = false;

        // reading in the values as X's
        // if (confirmWire != wire) obj.confirmWireValid.isValid = false;
        // if (confirmACH != ach) obj.confirmACHValid.isValid = false;
        // if (confirmAccount != acctNum) obj.confirmAccountValid.isValid = false;

        this.acctError = !obj.actNumFormatValid.isValid;
        this.conPhoneError = !obj.contactPhoneFormatValid.isValid;
        this.finPhoneError = !obj.financialPhoneFormatValid.isValid;
        this.postalError = !obj.postFormatValid.isValid;
        this.wireError = !obj.wireFormatValid.isValid;
        this.achError = !obj.achFormatValid.isValid;
        this.ueiError = !obj.ueiValid.isValid;
        this.tinError = !obj.tinValid.isValid;
        // this.confirmACHError = !obj.confirmACHValid.isValid;
        // this.confirmWireError = !obj.confirmWireValid.isValid;
        // this.confirmAcctError = !obj.confirmAccountValid.isValid;

        return obj;
    }

    get certTabText(){ 
        return this.recipType == 'Eligible Revenue Sharing County' ? 'Next: Certification' : 'Next: Certification and Agreement';
    }
}