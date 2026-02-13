import { LightningElement, wire, track, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getFieldValue, getRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';

import portalStyles from '@salesforce/resourceUrl/g20Styles';
import updateRecord from '@salesforce/apex/g20GuestRegistrationController.updateRecord';
import getRecordByToken from '@salesforce/apex/g20GuestRegistrationController.getRecordByToken';
import { CurrentPageReference } from 'lightning/navigation';

import FIRST_NAME from '@salesforce/schema/G20_Event_Registration__c.DI_First_Name__c';
import LAST_NAME from '@salesforce/schema/G20_Event_Registration__c.DI_Last_Name__c';
import EMAIL from '@salesforce/schema/G20_Event_Registration__c.DI_Email__c';
import MIDDLE_NAME from '@salesforce/schema/G20_Event_Registration__c.DI_Middle_Name__c';
import TITLE from '@salesforce/schema/G20_Event_Registration__c.DI_Title__c';
import PHONE from '@salesforce/schema/G20_Event_Registration__c.DI_Phone_Number__c';
import GENDER from '@salesforce/schema/G20_Event_Registration__c.DI_Gender__c';

import DELEGATION from '@salesforce/schema/G20_Event_Registration__c.Delegation_International_Organization__c';
import ROLE from '@salesforce/schema/G20_Event_Registration__c.G20_Role__c';

import DEADLINE from '@salesforce/schema/G20_Event_Registration__c.Guest_Registration_Deadline__c';
import STATUS from '@salesforce/schema/G20_Event_Registration__c.Status__c';

import decryptRecordId from '@salesforce/apex/EncrpytionUtility.decryptRecordId';


const FIELDS = [FIRST_NAME, LAST_NAME, EMAIL, DEADLINE, STATUS, MIDDLE_NAME, TITLE, PHONE, GENDER, DELEGATION, ROLE];




export default class LitcContactPage extends utilities {
    stylePath = portalStyles;

    // @track contactId;
    @track tokenId;
    @track registrationId;
    @track deadlinePassed;
    @track status;
    @track renderPage;

    @track currentStep = '1';

    firstName; lastName; email; middleName; title; phone; gender; delegation; role;

    fileLoaded;

    showTitleOther; showMinistryOther;

    handleError(event){ 
        console.log('in error')
        console.log(JSON.stringify(event.detail));
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.tokenId = currentPageReference.state.token;
            decryptRecordId({encryptedString : this.tokenId}).then(res=>{ 
                this.registrationId = res;
            }).catch(err=> console.log(err))
        }
    }

    // @wire(getRecordByToken, {token: '$tokenId'})
    // getRecordByToken(result){
    //     if(result.data){ 
    //         console.log(result.data)
    //         this.registrationId = result.data.Id;
    //         console.log(this.registrationId);



    //         let currentDate = Date.parse(new Date().toLocaleString());
    //         let deadline = Date.parse(result.data.Guest_Registration_Deadline__c);
    //         this.status = result.data.Status__c;
    //         this.deadlinePassed = currentDate > deadline || !result.data.Guest_Registration_Deadline__c;
    //         console.log(this.deadlinePassed);
    //         this.firstName = result.data.DI_First_Name__c;
    //         this.middleName = result.data.DI_Middle_Name__c;
    //         this.lastName = result.data.DI_Last_Name__c;
    //         this.email = result.data.DI_Email__c;
    //         this.title = result.data.DI_Title__c;
    //         this.phone = result.data.DI_Phone_Number__c;
    //         this.gender = result.data.DI_Gender__c;
    //         this.delegation = result.data.Delegation_International_Organization__c;
    //         this.role = result.data.G20_Role__c;
    //         this.renderPage = true;
    //     } else if (result.error) console.log(result.error);
    // }

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
        ]);
    }

    async handleNavigate(event){ 
        let inputFields;
        if(event.target.label === 'Next'){ 
            let tab = event.target.value;
            
            if(tab === '3'){ 
                if(!this.fileLoaded){
                    this.showNotification('Error', 'All required fields must be complete', 'error');
                }else{ 
                    this.currentStep = event.target.value;
                }
                  
            } else{ 
                let prevTab = event.target.value - 1;
                inputFields = this.template.querySelectorAll('.tab' + prevTab);

                let isValid = true;

                inputFields.forEach(input => {
                    console.log(input)
                    if(!input.value) {
                        this.showNotification('Error', 'All required fields must be complete', 'error');
                        isValid = false;
                    }
                });

                if(isValid){
                    this.currentStep = event.target.value;  
                }
            }
        } else{ 
            this.currentStep = event.target.value;  
        }
    
    }

    @wire(getRecord, { recordId: '$registrationId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            console.log(data);
            let currentDate = Date.parse(new Date().toLocaleString());
            let deadline = Date.parse(getFieldValue(data, DEADLINE));
            this.status = getFieldValue(data, STATUS);
            this.deadlinePassed = currentDate > deadline || !getFieldValue(data, DEADLINE);
            console.log(this.deadlinePassed);
            this.renderPage = true;

            this.firstName = getFieldValue(data, FIRST_NAME);
            this.middleName = getFieldValue(data, MIDDLE_NAME);
            this.lastName = getFieldValue(data, LAST_NAME);
            this.email = getFieldValue(data, EMAIL);
            this.title = getFieldValue(data, TITLE);
            this.phone = getFieldValue(data, PHONE);
            this.gender = getFieldValue(data, GENDER);
            this.delegation = getFieldValue(data, DELEGATION);
            this.role = getFieldValue(data, ROLE);
        }
        else if(error){ 
            console.log('in error')
            console.log(this.registrationId);
            console.error(error);
        }
    }
    
    handleFileLoaded(event){ 
        this.fileLoaded = event.detail;
    }

 

    handleSubmitRegistration(event){
        event.preventDefault();
        console.log('in submit')
        // map fields 
        const allFields = this.template.querySelectorAll('lightning-input');
        const updateFields = { Id: this.registrationId };

        allFields.forEach((input) => {
            if(input.value) {
                updateFields[input.dataset.field] = input.value;
            }
        });    
        updateFields.Status__c= 'Submitted';
        updateFields.Submitted_Date__c = new Date().toISOString();
        updateFields.Name = updateFields.DI_First_Name__c + ' ' + updateFields.DI_Last_Name__c;

        const allPicklistFields = this.template.querySelectorAll('lightning-combobox');
        allPicklistFields.forEach((input)=>{ 
            if(input.value){ 
                updateFields[input.dataset.field] = input.value;
            }
        })
        console.log(JSON.stringify(updateFields));

        // validate final tab
        let inputFields = this.template.querySelectorAll('.tab4');

        let isValid = true;
        inputFields.forEach(input => {
            if(!input.value) {
                this.showNotification('Error', 'All required fields must be complete', 'error');
                isValid = false;
            }
        });
        if(!isValid) return;


        updateRecord({recordId: this.registrationId, objectName: 'G20_Event_Registration__c', fields: updateFields}).then(res=>{ 
            this.showNotification('Success', 'Thank you for registering', 'success');
            this.status = 'Submitted';
        }).catch(err=>{
             console.log(err)
        })

    }

    clearFields(){ 
        this.selectedValueSelf = null;
        this.selectedValueType = null;
        const lightningFields = this.template.querySelectorAll('lightning-input-field');
        lightningFields.forEach(field => {
            field.value = null;
        });
    }

    handleSuccess(){
        console.log('in success')
        this.showNotification('Success', 'Thank you for registering', 'success');
        this.currentStep = '1';
    }

    openRegistrationModal(event){ 
        this.selectedId = event.detail.row.Id;
        this.showRegistrationModal = true;
    }
    closeRegistrationModal(){ 
        this.showRegistrationModal = false;
        this.selectedId= null;
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


    get showErrorMessage(){ 
        return !this.registrationId || this.deadlinePassed || !this.renderPage
    }
    get isSessionValid(){
        return !this.showErrorMessage && this.renderPage && this.status === 'Pending'
    }
    get isStatusSubmitted(){ 
        return this.status === 'Submitted' || this.status === 'Accepted';
    }


    handleTitleChange(event){ 
        // this.selectedTitle = event.target.value;
        this.showTitleOther = event.target.value === 'Other'
    }
    // handleGenderChange(event){ 
    //     this.selectedGender = event.target.value;
    // }
    // handleDelegationChange(event){ 
        
    // }
    handleMinistryChange(event){ 
        this.showMinistryOther = event.target.value === 'Other'
    }
    // handleG20RoleChange(event){ 
        
    // }
    // handleCountryChange(event){ 
        
    // }

    get titleOptions() {
        return [
            { label: 'Dr.', value: 'Dr.' },
            { label: 'Mr.', value: 'Mr.' },
            { label: 'Mrs.', value: 'Mrs.' },
            { label: 'Ms.', value: 'Ms.' },
            { label: 'Other', value: 'Other' }
        ];
    }
    get genderOptions() {
        return [
            { label: 'Male', value: 'Male' },
            { label: 'Female', value: 'Female' }
        ];
    }
    get delegationOptions() {
        return [
            { label: 'United States', value: 'United States' },
            { label: 'African Union', value: 'African Union' },
            { label: 'Argentina', value: 'Argentina' },
            { label: 'Australia', value: 'Australia' },
            { label: 'Brazil', value: 'Brazil' },
            { label: 'Canada', value: 'Canada' },
            { label: 'China', value: 'China' },
            { label: 'European Union', value: 'European Union' },
            { label: 'France', value: 'France' },
            { label: 'Germany', value: 'Germany' },
            { label: 'India', value: 'India' },
            { label: 'Indonesia', value: 'Indonesia' },
            { label: 'Italy', value: 'Italy' },
            { label: 'Japan', value: 'Japan' },
            { label: 'Republic of Korea', value: 'Republic of Korea' },
            { label: 'Mexico', value: 'Mexico' },
            { label: 'Russia', value: 'Russia' },
            { label: 'Saudi Arabia', value: 'Saudi Arabia' },
            // { label: 'South Africa', value: 'South Africa' },
            { label: 'Türkiye', value: 'Türkiye' },
            { label: 'United Kingdom', value: 'United Kingdom' },
            { label: 'Bank of International Settlements (BIS)', value: 'Bank of International Settlements (BIS)' },
            { label: 'Financial Action Task Force (FATF)', value: 'Financial Action Task Force (FATF)' },
            { label: 'Financial Stability Board (FSB)', value: 'Financial Stability Board (FSB)' },
            { label: 'International Monetary Fund (IMF)', value: 'International Monetary Fund (IMF)' },
            { label: 'Organization for Economic Co-operation and Development (OECD)', value: 'Organization for Economic Co-operation and Development (OECD)' },
            { label: 'World Bank', value: 'World Bank' },
            { label: 'Other', value: 'Other' }
        ];
    }

    get ministryOptions() {
        return [
            { label: 'Ministry of Finance', value: 'Ministry of Finance' },
            { label: 'Central Bank', value: 'Central Bank' },
            { label: 'International Organization', value: 'International Organization' },
            { label: 'Other', value: 'Other' }
        ];
    }

    get g20RoleOptions() {
        return [
            { label: 'Deputy (Head of Delegation)', value: 'Deputy (Head of Delegation)' },
            { label: 'Deputy’s Deputy', value: 'Deputy’s Deputy' },
            { label: 'Delegate', value: 'Delegate' },
            { label: 'Delegation Contact Officer (DCO)', value: 'Delegation Control Officer (DCO)' },
            { label: 'Delegation Accreditation Officer (DAO)', value: 'Delegation Accreditation Officer (DAO)' }
        ];
    }

    get countryOptions(){ 
        return [
        { "label": "United States of America (USA)", "value": "United States of America (USA)" },
        { "label": "Afghanistan", "value": "Afghanistan" },
        { "label": "Albania", "value": "Albania" },
        { "label": "Algeria", "value": "Algeria" },
        { "label": "All Others", "value": "All Others" },
        { "label": "Andorra", "value": "Andorra" },
        { "label": "Angola", "value": "Angola" },
        { "label": "Anguilla (dependent territory of United Kingdom)", "value": "Anguilla (dependent territory of United Kingdom)" },
        { "label": "Antigua and Barbuda (formerly Antigua)", "value": "Antigua and Barbuda (formerly Antigua)" },
        { "label": "Argentina", "value": "Argentina" },
        { "label": "Armenia", "value": "Armenia" },
        { "label": "Aruba (now independent of Netherlands Antilles)", "value": "Aruba (now independent of Netherlands Antilles)" },
        { "label": "Ashmore and Cartier Islands, Territory of (Australian external territory)", "value": "Ashmore and Cartier Islands, Territory of (Australian external territory)" },
        { "label": "Australia", "value": "Australia" },
        { "label": "Austria", "value": "Austria" },
        { "label": "Azerbaijan", "value": "Azerbaijan" },
        { "label": "Azores Islands", "value": "Azores Islands" },
        { "label": "Bahamas, The", "value": "Bahamas, The" },
        { "label": "Bahrain", "value": "Bahrain" },
        { "label": "Balearic Islands", "value": "Balearic Islands" },
        { "label": "Bangladesh", "value": "Bangladesh" },
        { "label": "Barbados", "value": "Barbados" },
        { "label": "Belarus", "value": "Belarus" },
        { "label": "Belgium", "value": "Belgium" },
        { "label": "Belize (formerly British Honduras)", "value": "Belize (formerly British Honduras)" },
        { "label": "Benin (formerly Dahomey)", "value": "Benin (formerly Dahomey)" },
        { "label": "Bermuda (dependent territory of United Kingdom)", "value": "Bermuda (dependent territory of United Kingdom)" },
        { "label": "Bhutan", "value": "Bhutan" },
        { "label": "Bolivia", "value": "Bolivia" },
        { "label": "Bosnia and Herzegovina", "value": "Bosnia and Herzegovina" },
        { "label": "Botswana", "value": "Botswana" },
        { "label": "Brazil", "value": "Brazil" },
        { "label": "British Indian Ocean Territory (dependent territory of United Kingdom)", "value": "British Indian Ocean Territory (dependent territory of United Kingdom)" },
        { "label": "British Virgin Islands", "value": "British Virgin Islands" },
        { "label": "Brunei", "value": "Brunei" },
        { "label": "Bulgaria", "value": "Bulgaria" },
        { "label": "Burkina Faso (formerly Upper Volta)", "value": "Burkina Faso (formerly Upper Volta)" },
        { "label": "Burma (Myanmar)", "value": "Burma (Myanmar)" },
        { "label": "Burundi", "value": "Burundi" },
        { "label": "Cambodia", "value": "Cambodia" },
        { "label": "Cameroon", "value": "Cameroon" },
        { "label": "Canada", "value": "Canada" },
        { "label": "Cape Verde (Cabo Verde)", "value": "Cape Verde (Cabo Verde)" },
        { "label": "Central African Republic", "value": "Central African Republic" },
        { "label": "Chad", "value": "Chad" },
        { "label": "Chile", "value": "Chile" },
        { "label": "China - People's Republic of China", "value": "China - People's Republic of China" },
        { "label": "Colombia", "value": "Colombia" },
        { "label": "Comoros", "value": "Comoros" },
        { "label": "Congo", "value": "Congo" },
        { "label": "Congo, Democratic Republic of", "value": "Congo, Democratic Republic of" },
        { "label": "Costa Rica", "value": "Costa Rica" },
        { "label": "Cote d'Ivoire (Ivory Coast)", "value": "Cote d'Ivoire (Ivory Coast)" },
        { "label": "Croatia", "value": "Croatia" },
        { "label": "Cuba", "value": "Cuba" },
        { "label": "Cyprus", "value": "Cyprus" },
        { "label": "Czech Republic", "value": "Czech Republic" },
        { "label": "Denmark", "value": "Denmark" },
        { "label": "Djibouti", "value": "Djibouti" },
        { "label": "Dominica", "value": "Dominica" },
        { "label": "Dominican Republic", "value": "Dominican Republic" },
        { "label": "Ecuador", "value": "Ecuador" },
        { "label": "Egypt", "value": "Egypt" },
        { "label": "El Salvador", "value": "El Salvador" },
        { "label": "Equatorial Guinea", "value": "Equatorial Guinea" },
        { "label": "Eritrea", "value": "Eritrea" },
        { "label": "Estonia", "value": "Estonia" },
        { "label": "Eswatini (Swaziland)", "value": "Eswatini (Swaziland)" },
        { "label": "Ethiopia", "value": "Ethiopia" },
        { "label": "Fiji", "value": "Fiji" },
        { "label": "Finland", "value": "Finland" },
        { "label": "France", "value": "France" },
        { "label": "Gabon", "value": "Gabon" },
        { "label": "Gambia", "value": "Gambia" },
        { "label": "Georgia", "value": "Georgia" },
        { "label": "Germany", "value": "Germany" },
        { "label": "Ghana", "value": "Ghana" },
        { "label": "Greece", "value": "Greece" },
        { "label": "Greenland", "value": "Greenland" },
        { "label": "Grenada", "value": "Grenada" },
        { "label": "Guatemala", "value": "Guatemala" },
        { "label": "Guinea", "value": "Guinea" },
        { "label": "Guinea-Bissau", "value": "Guinea-Bissau" },
        { "label": "Guyana", "value": "Guyana" },
        { "label": "Haiti", "value": "Haiti" },
        { "label": "Honduras", "value": "Honduras" },
        { "label": "Hong Kong", "value": "Hong Kong" },
        { "label": "Hungary", "value": "Hungary" },
        { "label": "Iceland", "value": "Iceland" },
        { "label": "India", "value": "India" },
        { "label": "Indonesia", "value": "Indonesia" },
        { "label": "Iran", "value": "Iran" },
        { "label": "Iraq", "value": "Iraq" },
        { "label": "Ireland", "value": "Ireland" },
        { "label": "Israel", "value": "Israel" },
        { "label": "Italy", "value": "Italy" },
        { "label": "Jamaica", "value": "Jamaica" },
        { "label": "Japan", "value": "Japan" },
        { "label": "Jordan", "value": "Jordan" },
        { "label": "Kazakhstan", "value": "Kazakhstan" },
        { "label": "Kenya", "value": "Kenya" },
        { "label": "Korea - North Korea", "value": "Korea - North Korea" },
        { "label": "Korea - South Korea", "value": "Korea - South Korea" },
        { "label": "Kuwait", "value": "Kuwait" },
        { "label": "Kyrgyzstan", "value": "Kyrgyzstan" },
        { "label": "Laos", "value": "Laos" },
        { "label": "Latvia", "value": "Latvia" },
        { "label": "Lebanon", "value": "Lebanon" },
        { "label": "Lesotho", "value": "Lesotho" },
        { "label": "Liberia", "value": "Liberia" },
        { "label": "Libya", "value": "Libya" },
        { "label": "Liechtenstein", "value": "Liechtenstein" },
        { "label": "Lithuania", "value": "Lithuania" },
        { "label": "Luxembourg", "value": "Luxembourg" },
        { "label": "Macau", "value": "Macau" },
        { "label": "Madagascar", "value": "Madagascar" },
        { "label": "Malawi", "value": "Malawi" },
        { "label": "Malaysia", "value": "Malaysia" },
        { "label": "Maldives", "value": "Maldives" },
        { "label": "Mali", "value": "Mali" },
        { "label": "Malta", "value": "Malta" },
        { "label": "Marshall Islands", "value": "Marshall Islands" },
        { "label": "Mauritania", "value": "Mauritania" },
        { "label": "Mauritius", "value": "Mauritius" },
        { "label": "Mexico", "value": "Mexico" },
        { "label": "Moldova", "value": "Moldova" },
        { "label": "Monaco", "value": "Monaco" },
        { "label": "Mongolia", "value": "Mongolia" },
        { "label": "Montenegro", "value": "Montenegro" },
        { "label": "Morocco", "value": "Morocco" },
        { "label": "Mozambique", "value": "Mozambique" },
        { "label": "Namibia", "value": "Namibia" },
        { "label": "Nepal", "value": "Nepal" },
        { "label": "Netherlands", "value": "Netherlands" },
        { "label": "New Zealand", "value": "New Zealand" },
        { "label": "Nicaragua", "value": "Nicaragua" },
        { "label": "Niger", "value": "Niger" },
        { "label": "Nigeria", "value": "Nigeria" },
        { "label": "Norway", "value": "Norway" },
        { "label": "Oman", "value": "Oman" },
        { "label": "Pakistan", "value": "Pakistan" },
        { "label": "Palestine", "value": "Palestine" },
        { "label": "Panama", "value": "Panama" },
        { "label": "Papua New Guinea", "value": "Papua New Guinea" },
        { "label": "Paraguay", "value": "Paraguay" },
        { "label": "Peru", "value": "Peru" },
        { "label": "Philippines", "value": "Philippines" },
        { "label": "Poland", "value": "Poland" },
        { "label": "Portugal", "value": "Portugal" },
        { "label": "Qatar", "value": "Qatar" },
        { "label": "Romania", "value": "Romania" },
        { "label": "Russia", "value": "Russia" },
        { "label": "Rwanda", "value": "Rwanda" },
        { "label": "Saint Kitts and Nevis", "value": "Saint Kitts and Nevis" },
        { "label": "Saint Lucia", "value": "Saint Lucia" },
        { "label": "Saint Vincent and the Grenadines", "value": "Saint Vincent and the Grenadines" },
        { "label": "Samoa", "value": "Samoa" },
        { "label": "San Marino", "value": "San Marino" },
        { "label": "Sao Tome and Principe", "value": "Sao Tome and Principe" },
        { "label": "Saudi Arabia", "value": "Saudi Arabia" },
        { "label": "Senegal", "value": "Senegal" },
        { "label": "Serbia", "value": "Serbia" },
        { "label": "Seychelles", "value": "Seychelles" },
        { "label": "Sierra Leone", "value": "Sierra Leone" },
        { "label": "Singapore", "value": "Singapore" },
        { "label": "Slovakia", "value": "Slovakia" },
        { "label": "Slovenia", "value": "Slovenia" },
        { "label": "Solomon Islands", "value": "Solomon Islands" },
        { "label": "Somalia", "value": "Somalia" },
        // { "label": "South Africa", "value": "South Africa" },
        { "label": "South Korea", "value": "South Korea" },
        { "label": "South Sudan", "value": "South Sudan" },
        { "label": "Spain", "value": "Spain" },
        { "label": "Sri Lanka", "value": "Sri Lanka" },
        { "label": "Sudan", "value": "Sudan" },
        { "label": "Suriname", "value": "Suriname" },
        { "label": "Sweden", "value": "Sweden" },
        { "label": "Switzerland", "value": "Switzerland" },
        { "label": "Syria", "value": "Syria" },
        { "label": "Taiwan", "value": "Taiwan" },
        { "label": "Tajikistan", "value": "Tajikistan" },
        { "label": "Tanzania", "value": "Tanzania" },
        { "label": "Thailand", "value": "Thailand" },
        { "label": "Togo", "value": "Togo" },
        { "label": "Tonga", "value": "Tonga" },
        { "label": "Trinidad and Tobago", "value": "Trinidad and Tobago" },
        { "label": "Tunisia", "value": "Tunisia" },
        { "label": "Turkey", "value": "Turkey" },
        { "label": "Turkmenistan", "value": "Turkmenistan" },
        { "label": "Uganda", "value": "Uganda" },
        { "label": "Ukraine", "value": "Ukraine" },
        { "label": "United Arab Emirates", "value": "United Arab Emirates" },
        { "label": "United Kingdom", "value": "United Kingdom" },
        { "label": "Uruguay", "value": "Uruguay" },
        { "label": "Uzbekistan", "value": "Uzbekistan" },
        { "label": "Vanuatu", "value": "Vanuatu" },
        { "label": "Vatican City", "value": "Vatican City" },
        { "label": "Venezuela", "value": "Venezuela" },
        { "label": "Vietnam", "value": "Vietnam" },
        { "label": "Yemen", "value": "Yemen" },
        { "label": "Zambia", "value": "Zambia" },
        { "label": "Zimbabwe", "value": "Zimbabwe" },
        ]
    }


}