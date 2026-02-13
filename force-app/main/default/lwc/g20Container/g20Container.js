import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getFieldValue, getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';
import { NavigationMixin } from 'lightning/navigation';
import portalStyles from '@salesforce/resourceUrl/g20Styles';
import getG20Event from '@salesforce/apex/g20RegistrationController.getG20Event';

import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from '@salesforce/user/Id';
import ROLE from '@salesforce/schema/Contact.G20_Role__c';
import ACCOUNT from '@salesforce/schema/Contact.AccountId';
import DELEGATION from '@salesforce/schema/Contact.Delegation_International_Organization__c';
import ORGANIZATION from '@salesforce/schema/Contact.Organization__c';



export default class G20Container extends utilities {

    stylePath = portalStyles;
    activeTab;
    activeSections=["Help"]
    @track contactId;
    @track g20EventId;
    @track role;
    @track renderPage;
    @track accountId;
    @track delegation;
    @track organization;

    // gets the role of current contact
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    setData({error, data}) {
        if (data) {
            console.log(data)
            this.contactId = getFieldValue(data, CONTACT_ID);
        }
        else if (error) {
            console.log(error);
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

    @wire(getRecord, { recordId: '$contactId', fields: [ROLE, ACCOUNT, DELEGATION, ORGANIZATION] })
    contactRecord({ error, data }) {
        if (data) {
            this.role = getFieldValue(data, ROLE);
            this.accountId = getFieldValue(data, ACCOUNT);
            this.delegation = getFieldValue(data, DELEGATION);
            this.organization= getFieldValue(data, ORGANIZATION);
            this.renderPage = true;
            console.log(this.role)
        } else if (error) {
            console.log(error);
        }
    }

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
        ]);
    }

    collapse(){ 
        this.showToggle = !this.showToggle;
        this.template.querySelector('.container').classList.replace('slds-small-size_10-of-12', 'slds-small-size_12-of-12');
        this.template.querySelector('.helpInfoBox').classList.add('hide');
    }
    expand(){ 
        this.showToggle = !this.showToggle;
        this.template.querySelector('.helpInfoBox').classList.remove('hide');
        this.template.querySelector('.container').classList.replace('slds-small-size_12-of-12', 'slds-small-size_10-of-12');
    }

    handleOnActive(event) {
        this.activeTab = event.target.value;
    } 

    get intro(){ 
        return this.activeTab === 'intro' ? 'slds-show' : 'slds-hide';
    }
    get registration(){ 
        return this.activeTab === 'registration' ? 'slds-show' : 'slds-hide';
    }
    get reservation(){
        return this.activeTab === 'reservation' ? 'slds-show' : 'slds-hide';
    }

    handleButtonNavReg(){
        this.activeTab = 'registration';
    }
    handleButtonNavRes(){
        this.activeTab = 'reservation';
    }


    get isRoleDCO(){ 
        return this.role === 'Delegation Control Officer (DCO)';
    }

    get isRoleDAO(){ 
        return this.role === 'Delegation Accreditation Officer (DAO)';
    }

    get isRoleAuthorized(){ 
        return this.isRoleDCO || this.isRoleDAO;
    }
    get isNotRoleAuthorized(){ 
        return !this.isRoleAuthorized;
    }
}