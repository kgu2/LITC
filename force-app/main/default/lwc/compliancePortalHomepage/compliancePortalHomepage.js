import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getFieldValue, getRecord } from 'lightning/uiRecordApi';
import { showNotification } from 'c/utilities';
import { NavigationMixin } from 'lightning/navigation';
// import portalStyles from '@salesforce/resourceUrl/portalChecklistStyles';
import animations from '@salesforce/resourceUrl/animate';
import portalStyles from '@salesforce/resourceUrl/SLFRFPortalStyles';
import projectOverviewStyles from '@salesforce/resourceUrl/slfrfProjectOverviewStyles';
import logoAboveVertNavSLFRF from '@salesforce/resourceUrl/complianceCardHomepage';
import isNeuUser from '@salesforce/apex/neuUser.isNeuUser';
import WelcomeSplash from '@salesforce/resourceUrl/WelcomeSplash';
import WarningSplash from '@salesforce/resourceUrl/ARPWarningMat';
import getAudit from '@salesforce/apex/slfrfAuditController.getAudit';
import getCurrentContactInformation from '@salesforce/apex/AccountPortalPageController.getCurrentContactInformation';
import USER_ID from '@salesforce/user/Id';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import getStateRecipient from '@salesforce/apex/slfrfAwardRedirectController.getSLFRFRecipientId';
import getAccount from '@salesforce/apex/createArpApplicationsController.getAffiliatedAccount';
import getUnverified from '@salesforce/apex/HubLoginController.getUnverified';
import { CurrentPageReference } from 'lightning/navigation';

export default class compliancePortalHomepage extends NavigationMixin(LightningElement) {

    @track stylePath = portalStyles;
    @track projectStylePath = projectOverviewStyles;
    @track stylePathTwo = animations;
    @track userId = USER_ID;
    @track showWelcome;
    @track showWarning = true;
    @track showAudit;
    @track auditRecordId;
    @track stateRecipientId;
    @track showWarning = true;
    @track showPage = true;
    @track showToggle;
    @track activeTab;
    @api showBanner;
    @api date;

    @track countCCNs = 0;

    isNEU;
    error;
    slfrfCard = logoAboveVertNavSLFRF;
    activeSections=["Notifications","Help", "Legend"]

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
            loadStyle(this, `${this.projectStylePath}`), 
            loadStyle(this, `${this.stylePathTwo}`), 
        ]);

    }

    connectedCallback(){ 
        getUnverified().then(data=>{ 
            console.log(data);
            if(data){ 
                this.navigateToErrorPage();
            } else{
                this.showPage = true;
            }
        }).catch(error=>{ 
            console.log(error);
        })

        console.log('this.current', this.currentPageReference);
        if(this.currentPageReference.state.closeout == 'true'){ 
            this.activeTab = 'closeoutreports'
        }
    }
    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference) {
        this.currentPageReference = currentPageReference;
    }
    

    @wire(getAccount)
    setAccount({error,data}){
        if(data){
            let accountId = data;
            getStateRecipient({accountId: accountId}).then(data=>{
                console.log(data);
                this.stateRecipientId = data;
            }).catch(error=>{ 
                console.log(error);
                console.log('could not find state recipient tied to this account')
            });
        } else if(error){ 
            console.log(error);
        }
    }

    @wire(getAudit)
    setAuditData({error, data}){ 
        if(data){ 
            this.showAudit = data.length > 0;
            if(this.showAudit) this.auditRecordId = data[0].Id
        } else if (error){ 
            console.log(error);
        }
    }

    @wire(getCurrentContactInformation)
    setCurrentContactData({error,data}){
        if(data){
            this.roles = data.Roles__c;
            if(this.roles == undefined){
                this.roles = 'no role';
            }
        } else if(error){
            console.log(error)
        }
    }
    
    @wire(getRecord, { recordId: USER_ID, fields: [CONTACT_ID] })
    settingNeuData({error, data}) {
        if (data) {
            let contactId = getFieldValue(data, CONTACT_ID);
            isNeuUser({ contactId: contactId }).then(result => {
                this.isNEU = result;
                this.error = undefined;
            })
            .catch(fetchError => {
                console.log(fetchError);
                this.dispatchEvent(showNotification('Error', 'Error retrieving your NEU data.', 'error')); 
                this.error = JSON.stringify(fetchError);
                this.isNEU = undefined;
            })
        }

        else if (error) {
            console.log(error);
            this.dispatchEvent(showNotification('Error', 'Error retrieving your data.', 'error')); 
        }

        else this.dispatchEvent(showNotification('Fatal Error', 'Error retrieving your data.', 'error')); 

    }

    navigateToErrorPage(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'error-login'
            }
        });
    }

    handleQuarterlyReport(){
        this.template.querySelector('lightning-tabset').activeTabValue = 'reports';
    }


    closeWelcome(){ 
        this.showWelcome = false;
    }

    closeWarning(){ 
        this.showWarning = false;
        this.showWelcome = true;
    }

    gotoAudit(){ 
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              actionName: 'view',
              recordId : this.auditRecordId,
              objectApiName : 'Audit__c'
              }
          });
    }

    get showHAF() {
        let hafRoles = '';
        if (this.roles != undefined) {
            let arrayRoles = this.roles.split(';');
            arrayRoles.forEach(entry => {
                if (entry.includes('HAF')) hafRoles += entry + ';';
            });
    
            if (hafRoles != '') hafRoles = hafRoles.slice(0, -1); //remove the last ;
            else hafRoles = undefined;
        }
        return hafRoles;
    }

    get showERA() {
        let roles = '';
        if (this.roles != undefined) {
            let arrayRoles = this.roles.split(';');
            arrayRoles.forEach(entry => {
                if (entry.includes('ERA') && entry && entry != 'ERA - Communications Only') roles += entry + ';';
            });
    
            if (roles != '') roles = roles.slice(0, -1); //remove the last ;
            return roles;
        }
        else return undefined;
        
    }

    get showSLFRF() {
        let roles = '';
        if (this.roles != undefined) {
            let arrayRoles = this.roles.split(';');
            arrayRoles.forEach(entry => {
                if (entry.includes('SLFRF') && entry && entry != 'SLFRF - Communications Only') roles += entry + ';';
            });
    
            if (roles != '') roles = roles.slice(0, -1); //remove the last ;
            return roles;
        }
        else return undefined;
    }

    get showERAorSLFRF(){ 
        return this.showERA || (this.showSLFRF && this.stateRecipientId);
    }

    get showSubmissionTab() {
        return this.showERA || (this.showSLFRF && this.stateRecipientId) || this.showHAF;
    }

    get splash() {
        return `height:600px; width:800px; background-image:url(${WelcomeSplash})`;
    }

    get warningSplash() {
        return `height:600px; width:800px; background-image:url(${WarningSplash})`;
    }

    handleCloseGovWarning(event){
        this.showWarning = event.detail;
    }

    // infobox
    collapse(){ 
        this.template.querySelector('.helpInfoBox').classList.add('animate__fadeOutRight');
        setTimeout(() => {
            this.showToggle = !this.showToggle;
        }, 700); 
        setTimeout(() => {
            this.template.querySelector('.container').classList.replace('slds-small-size_10-of-12', 'slds-small-size_12-of-12');
            this.template.querySelector('.helpInfoBox').classList.remove('animate__fadeOutRight');
            this.template.querySelector('.helpInfoBox').classList.add('hide');
        }, 900); 

    }
    expand(){ 
        this.showToggle = !this.showToggle;
        this.template.querySelector('.helpInfoBox').classList.remove('hide');
        this.template.querySelector('.helpInfoBox').classList.add('animate__fadeInRight'); 
        this.template.querySelector('.container').classList.replace('slds-small-size_12-of-12', 'slds-small-size_10-of-12');
        setTimeout(() => {
            this.template.querySelector('.helpInfoBox').classList.remove('animate__fadeInRight');
        }, 900); 
    }

    handleOnActive(event) {
        this.activeTab = event.target.value;
    }

    handleGetCount(event){ 
        console.log(event.detail);
        this.countCCNs = event.detail;
    }

    get showCCN(){ 
        return this.countCCNs !== 0;
    }

    get intro(){ 
        return this.activeTab == 'intro' ? 'slds-show' : 'slds-hide';
    }
    get reports(){ 
        return this.activeTab == 'reports' ? 'slds-show' : 'slds-hide';
    }
    get submissions(){ 
        return this.activeTab == 'submissions' ? 'slds-show' : 'slds-hide';
    }
    get isNotIntro(){ 
        return this.activeTab != 'intro';
    }
    get closeoutReports() {
        return this.activeTab == 'closeoutreports' ? 'slds-show' : 'slds-hide';
    }
}