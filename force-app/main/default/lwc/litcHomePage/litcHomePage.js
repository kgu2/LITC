import { LightningElement, track, wire, api } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import { getFieldValue, getRecord, createRecord, updateRecord } from 'lightning/uiRecordApi';
import utilities from 'c/utilities';
import animations from '@salesforce/resourceUrl/animationsCSS';
import { NavigationMixin } from 'lightning/navigation';
import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import getAffiliatedAccount from '@salesforce/apex/ApplicationFederalAssistanceController.getAffiliatedAccount';
import getApplications from '@salesforce/apex/ApplicationFederalAssistanceController.getApplications';
import fetchFiles from '@salesforce/apex/ApplicationFederalAssistanceController.fetchFiles'; 
import createNewApplication from '@salesforce/apex/ApplicationFederalAssistanceController.createNewApplication'; 
import createContinuationApplication from '@salesforce/apex/ApplicationFederalAssistanceController.createContinuationApplication'; 
import getUnverified from '@salesforce/apex/litcLoginController.getUnverified';
import CONTACT_ID from "@salesforce/schema/User.ContactId";
import USER_ID from '@salesforce/user/Id';
import ROLE from '@salesforce/schema/Contact.LITC_Role_v2__c';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';
import getNTAReview from '@salesforce/apex/ApplicationFederalAssistanceController.getNTAReview'; 
import getStaffReview from '@salesforce/apex/ApplicationFederalAssistanceController.getStaffReview'; 

import getFundingAwards from '@salesforce/apex/ApplicationFederalAssistanceController.getFundingAwards'; 

import generatePDF from '@salesforce/apex/ApplicationFederalAssistanceController.generatePDF';

import { refreshApex } from '@salesforce/apex';



const columns = [
    { label: 'Application Id', fieldName: 'Name', type : 'text', wrapText: true, hideDefaultActions: true},
    { label: 'Type', fieldName: 'Type_of_Application__c', type : 'text', hideDefaultActions: true},
    { label: 'Deadline', fieldName: 'submissionDeadline', type : 'text', hideDefaultActions: true},
    { label: 'Status', fieldName: 'Status__c', type : 'text', hideDefaultActions: true,
        cellAttributes: { class: { fieldName: 'statusStyle' } }
    },
    
    {label: 'Edit/View', hideDefaultActions: true, type: "button-icon", name: 'provideInfo', typeAttributes: {  
        iconName: { fieldName: 'dynamicIconProvideInfo' },
        variant: 'brand',
        initialWidth: 175,
        class : { fieldName: 'stylingProvideInformation' }
    }},
    {label: 'More Actions', hideDefaultActions: true, type: "button", typeAttributes: {  
        label: { fieldName: 'moreActionsLabel' },  
        name: 'AdditionalInfoButton',  
        variant: 'base', 
        class : { fieldName: 'stylingFundingDecision' }
    }},
    {label: 'Download', hideDefaultActions: true, type: "button-icon", initialWidth: 100, typeAttributes: {  
        iconName: 'action:download',
        variant: 'brand',
        class : { fieldName: 'stylingDownload' }
    }},
];

export default class litcHomePage extends utilities {

    @api disableCreate
    @track isLoading;
    @track stylePath = portalStyles;
    @track stylePathTwo = animations;
    @track showToggle;
    @track activeTab;
    @track columns = columns;
    @track apps;
    @track showApps;
    @track showCreateAppModal; 
    @track accountId;

    @track selectedNTAId;
    @track selectedAppId;
    @track showFundingDecisionModal;
    @track showFundingDecisionConfirmation;
    @track fundingDecisionSelection;
    @track fundingAmount; fundingExplanation; fundingConditions; BASummary;
    fieldA; fieldB; fieldC; fieldD; fieldE; fieldF; fieldG; fieldH;

    @track showFundingAwardModal;

    dynamicAcceptedFormat = ['.pdf', '.doc', '.docx', '.docb','.tif'];

    @track appOptions = [ { value: 'new', label: 'New'}, { value: 'Continuation', label: 'Continuation'}];
    // @track optionsTwo = [ { value: 'Year 2', label: 'Year 2'}, { value: 'Year 3', label: 'Year 3'}];
    @track optionsThree = [ { value: 'Yes', label: 'Yes'}, { value: 'No', label: 'No'}];
    @track appValue;
    @track appValueTwo;
    @track appValueThree;

    @track contactId;
    @track role;


    activeSections=["Help"]

    constructor() {
        super();
        Promise.all([
            loadStyle(this, `${this.stylePath}`),
            loadStyle(this, `${this.stylePathTwo}`)
        ]);
    }

    // redirects to registration page based on unverified checkbox
    connectedCallback(){ 
        getMyRole().then(data=>{ 
            console.log(data)
            this.role= data;
        })

        getUnverified().then(data=>{ 
            console.log(data);
            if(data){ 
                this[NavigationMixin.Navigate]({
                    type: 'comm__namedPage',
                        attributes: {
                            pageName: 'registration'
                    }
                });
            } else{
                this.showPage = true;
            }
        }).catch(error=>{ 
            console.log(error);
        })
    }

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
    @wire(getRecord, { recordId: '$contactId', fields: [ROLE] })
    contactRecord({ error, data }) {
        if (data) {
            // this.role = getFieldValue(data, ROLE);
            // console.log(this.role)
        } else if (error) {
            console.log(error);
        }
    }


    @wire(getAffiliatedAccount)
    setAccount({error, data}) {
        if (data) {   
            this.accountId = data;
        }
        else if (error) {
            console.log(error);
        }

    }

    @wire(getApplications)
    async setApps(result) {
        this.setAppsResult = result;

        if (result.data) {
            let tempApps = [];
            let myRole = this.role;

            const restrictedRoles = ['View Only Staff', 'EBiz POC'];
            const hasOnlyRestrictedRoles = myRole != undefined && myRole.split(';').every(role => restrictedRoles.includes(role));

            for (let item of result.data) {
                let tempRecord = Object.assign({}, item);
                tempRecord.submissionDeadline = tempRecord.Submission_Deadline__c ? new Date(tempRecord.Submission_Deadline__c + 'T00:00:00').toLocaleDateString('en-US') : undefined;

                if (tempRecord.Status__c === 'Submitted' || tempRecord.Status__c === 'Amendment Submitted' || tempRecord.Status__c === 'Closed') {
                    tempRecord.statusStyle = 'slds-text-color_success';
                    tempRecord.stylingProvideInformation = 'darkblue';
                    tempRecord.dynamicIconProvideInfo = 'action:preview';
                    tempRecord.stylingDownload = 'slds-show gray slds-button';

                    try {

                        // for submitted applications, check for funding award, if no funding award show funding decision
                        let fundingAward = await getFundingAwards({ appId: tempRecord.Id });

                        if(fundingAward && fundingAward.length > 0){ 
                            tempRecord.stylingFundingDecision = 'slds-show slds-button';
                            tempRecord.moreActionsLabel = 'Funding award';
                        } else{ 
                            let res = await getNTAReview({ appId: tempRecord.Id });
        
                            if (res[0]?.Review_Status__c === 'NTA Finalized' && res[0]?.Funding_Decision_Status__c !== 'Recipient Response Received') {
                                tempRecord.stylingFundingDecision = 'slds-show slds-button';
                                tempRecord.moreActionsLabel = 'Funding decision';
                            } else {
                                tempRecord.stylingFundingDecision = 'slds-hide slds-button';
                            }
                        }
                    } catch (err) {
                        console.error(err);
                    }
                } else {
                    tempRecord.dynamicIconProvideInfo = 'action:edit';
                    tempRecord.statusStyle = 'slds-text-color_error';
                    tempRecord.stylingProvideInformation = 'lightblue';
                    tempRecord.stylingFundingDecision = 'slds-hide slds-button';

                    // always show download button for view only staff
                    // if (myRole !== 'View Only Staff' && myRole !== 'EBiz POC') {

                    if (!hasOnlyRestrictedRoles) {
                        // tempRecord.stylingDownload = 'slds-hide gray slds-button';
                        tempRecord.stylingDownload = 'gray slds-button';
                    } else {
                        tempRecord.stylingDownload = 'gray slds-button';
                    }
                }

                // if (myRole === 'View Only Staff' || myRole === 'EBiz POC') {
                if(hasOnlyRestrictedRoles){
                    tempRecord.stylingProvideInformation = 'slds-hide';
                    tempRecord.stylingFundingDecision = 'slds-hide slds-button';
                }

                if(tempRecord.Status__c === 'Incomplete') tempRecord.stylingProvideInformation = 'slds-hide';

                tempApps.push(tempRecord);
            }

            this.apps = tempApps;
            this.showApps = tempApps.length > 0;
        } else if (result.error) {
            console.log(result.error);
        }
    }


    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    handleRowAction(event){ 
        let button = event.detail.action.class.fieldName;
        if(button === 'stylingProvideInformation'){
            this[NavigationMixin.Navigate]({
                type: "standard__recordPage",
                attributes: {
                  actionName: 'view',
                  recordId : event.detail.row.Id,
                  objectApiName : 'Application_for_Federal_Assistance__c'
                  }
              });
        } 
        if(button === 'stylingFundingDecision'){ 
            let id = event.detail.row.Id;

            console.log(id);

            console.log(JSON.stringify(event.detail.row.moreActionsLabel))

            if(event.detail.row.moreActionsLabel === 'Funding award'){ 
                this.showFundingAwardModal = true;
                this.selectedAppId = event.detail.row.Id;
            } else{ 
                this.showFundingDecisionModal = true;
            }

            getNTAReview({appId: id}).then(res=>{
                console.log(res)
                this.selectedNTAId = res[0].Id;
                this.selectedAppId = res[0].Application_for_Federal_Assistance__c;
                this.fundingAmount= res[0].NTA_Award_Amount__c;
                this.fundingExplanation = res[0].Funding_Decision_Reason__c;
                this.fundingConditions = res[0].NTA_Conditions__c;
                this.BASummary = res[0].BA_Summary__c;
            }).catch(err=>{
                 console.log(err)
            })

            getStaffReview({appId: id}).then(res=>{ 
                console.log(res)
                this.fieldA = res[0].Personnel__c;
                this.fieldB = res[0].Fringe_Benefits__c;
                this.fieldC = res[0].Travel__c;
                this.fieldD = res[0].Equipment__c;
                this.fieldE = res[0].Supplies__c;
                this.fieldF = res[0].Contractual__c;
                this.fieldG = res[0].Other_Expenses__c;
                this.fieldH = res[0].Indirect_Charges__c;
                this.fieldI = res[0].Matching_Fund__c;
            }).catch(err=>{ 
                console.log(err)
            })
        }
        if(button === 'stylingDownload'){ 
            let id = event.detail.row.Id;
            let version = event.detail.row.Version__c;
            this.downloadPDF(id, version);
        }

    }

    handleFundingDecisionClick(){ 
        if(!this.fundingDecisionSelection || !this.selectedNTAId){ 
            this.showNotification('Error', 'You must provide a response', 'error');
        } else{ 
            this.showFundingDecisionModal = false;
            this.showFundingDecisionConfirmation = true;
        }
    }

    async handleConfirmFundingConfirmation(event){ 
        if(this.isSelectedAmendment){ 
            await updateRecord({fields: {
                Id: this.selectedNTAId, 
                'Funding_Decision_Status__c': 'Recipient Response Received', 
            }}).catch(error=>{ 
                console.log(error);
            })

            await updateRecord({fields: {
                Id: this.selectedAppId, 
                Funding_Decision_Recipient_Response__c: 'Start Application Amendment', 
                Status__c: 'Amendment In Progress',
                SF424_Status__c: 'In Progress', 
                Form_13424_Status__c: 'In Progress', 
                Form_13424_J_Status__c: 'In Progress'
            }}).catch(error=>{ 
                console.log(error);
            })

            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    objectApiName: 'Application_for_Federal_Assistance__c',
                    actionName: 'view',
                    recordId: this.selectedAppId
                }
            });
        }
        if(this.isSelectedConference){ 
            await updateRecord({fields: {
                Id: this.selectedNTAId, 
                'Review_Status__c': 'Needs Review', 
                'Funding_Decision_Status__c': 'Recipient Response Received', 
            }}).catch(error=>{ 
                console.log(error);
            })

            await updateRecord({fields: {
                Id: this.selectedAppId, 
                'Funding_Decision_Recipient_Response__c': 'Request for Conference', 
            }}).catch(error=>{ 
                console.log(error);
            })

            setTimeout(() => {
                window.location.reload();
            }, 2000);
        }

        this.showFundingDecisionConfirmation = false;
        this.showNotification('Success', 'Response received', 'success');
    }


    async downloadPDF(id, version){
        await this.generatePDFs(id, version);

        fetchFiles({recordId: id}).then(data=>{ 
            let filesList = JSON.parse(JSON.stringify(data));
            let fileId = '';

            filesList.some(obj => {
                if(obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.Title === 'SF424.pdf'){ 
                    fileId += obj.ContentDocumentId + '/';
                    return true;
                }
            });
            filesList.some(obj => {
                if(obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.Title === '13424-J.pdf'){ 
                    fileId += obj.ContentDocumentId + '/';
                    return true;
                }
            });
            filesList.some(obj => {
                // handles both legacy and new m forms
                if(obj.ContentDocument.FileType == 'PDF' && (obj.ContentDocument.Title === '13424-M.pdf' || obj.ContentDocument.Title === '13424.pdf')){ 
                    fileId += obj.ContentDocumentId + '/';
                    return true;
                }
            });

            console.log(fileId);

            if(fileId){ 
                let baseUrl = window.location.href;
                baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
                this[NavigationMixin.Navigate]({
                    type: 'standard__webPage',
                    attributes: {
                        url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileId + '?operationContext=S1'
                    }
                }, false)
            } else{
                throw new Error('No file found');
            }

        }).catch(error=>{ 
            console.log('in catch' + error);
        })
    }

    generatePDFs(recordId, version){ 
        console.log('in generatePDFs');
        this.isLoading = true;
        let mForm = version === 'Legacy' ? '13424' : '13424-M';

        return Promise.all([
            generatePDF({recordId: recordId, name: 'SF424'}).catch(error=>{ 
                console.log(error)
            }),
            generatePDF({recordId: recordId, name: '13424-J'}).catch(error=>{ 
                console.log(error)
            }),
            generatePDF({recordId: recordId, name: mForm}).catch(error=>{ 
                console.log(error)
            })
        ]).catch(error=>{ 
            console.log(error)
        }).finally(() => {
            this.isLoading = false; 
        });
    }

    // downloadPDF(id, name){
    //     fetchFiles({recordId: id}).then(data=>{ 
    //         let filesList = JSON.parse(JSON.stringify(data));
    //         let fileId = '';

    //         filesList.some(obj => {
    //             if(obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.Title === name){ 
    //                 fileId = obj.ContentDocumentId;
    //             }
    //         });

    //         if(fileId){ 
    //             let baseUrl = window.location.href;
    //             baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
    //             this[NavigationMixin.Navigate]({
    //                 type: 'standard__webPage',
    //                 attributes: {
    //                     url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileId + '?operationContext=S1'
    //                 }
    //             }, false)
    //         } else{
    //             throw new Error('No file found');
    //         }

    //     }).catch(error=>{ 
    //         console.log('in catch');
    //     })
    // }

    closeCreateAppModal(){ 
        this.showCreateAppModal = false;
    }
    openCreateAppModal(){ 
        this.showCreateAppModal = true;
    }

    closeFundingDecisionModal(){ 
        this.showFundingDecisionModal = false;
    }
    closeFundingDecisionConfirmation(){ 
        this.showFundingDecisionConfirmation = false;
    }

    handleCloseModal(){ 
        this.showFundingAwardModal = false;
    }

    handleOptionChange(event){ 
        this.fundingDecisionSelection = event.target.value;
    }

    @track fundingOptions = [
        { label: 'Start Application Amendment', value: 'Start Application Amendment' },
        { label: 'Request for Conference', value: 'Request for Conference' },
    ];

    handleAppTypeChange(event){ 
        this.appValue = event.target.value;
    }
    handleAppTypeChangeTwo(event){ 
        this.appValueTwo = event.target.value;
    }
    handleAppTypeChangeThree(event){ 
        this.appValueThree = event.target.value;
    }
    
    handleCreateApp(){ 
        if(!this.appValue){
            this.showNotification('Error', 'Application type is required', 'error');
        } else if(!this.appValueTwo){ 
            this.showNotification('Error', 'Application year is required', 'error');
        } else{
            this.closeCreateAppModal();

            // commented 9/18/25 - continuation works the same as new
            // if(this.appValue == 'new' || this.appValue == 'Continuation'){ 
            //     createNewApplication( {appType: this.appValue, projectPeriod : this.appValueTwo, accountId: this.accountId} )
            //     .then(result => {
            //         this.showNotification('Success', 'Application created', 'success');
            //         this[NavigationMixin.Navigate]({
            //             type: 'standard__recordPage',
            //             attributes: {
            //                 objectApiName: 'Application_for_Federal_Assistance__c',
            //                 actionName: 'view',
            //                 recordId: result.Id
            //             }
            //         });
            //         console.log(result);
            //     })
            //     .catch(error=>{
            //         console.log(error);
            //         this.showNotification('Error', 'Unable to create application: ' + error, 'error');
            //     }); 

            if(this.appValue == 'new'){ 
                createNewApplication( {appType: this.appValue, projectPeriod : this.appValueTwo, accountId: this.accountId} )
                .then(result => {
                    this.showNotification('Success', 'Application created', 'success');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            objectApiName: 'Application_for_Federal_Assistance__c',
                            actionName: 'view',
                            recordId: result.Id
                        }
                    });
                    console.log(result);
                })
                .catch(error=>{
                    console.log(error);
                    this.showNotification('Error', 'Unable to create application: ' + error, 'error');
                }); 

            } else{ 
                // 2.4.25 continuation commented out for now
                // 9/18/25 continuation uncommented
                createContinuationApplication({projectPeriod : this.appValueTwo, accountId: this.accountId}).then(result=>{ 
                    this.showNotification('Success', 'Application created', 'success');
                    this[NavigationMixin.Navigate]({
                        type: 'standard__recordPage',
                        attributes: {
                            objectApiName: 'Application_for_Federal_Assistance__c',
                            actionName: 'view',
                            recordId: result.Id
                        }
                    });
                }).catch(error=>{ 
                    console.log(error)
                    this.showNotification('Error', 'Could not create continuation application. Verify that you have submitted a previous application: ', 'error');
                })
            }
        }
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

    handleNavApplications(){
        this.activeTab = 'applications';
            
    }
 

    get intro(){ 
        return this.activeTab == 'intro' ? 'slds-show' : 'slds-hide';
    }
    get applications(){ 
        return this.activeTab == 'applications' ? 'slds-show' : 'slds-hide';
    }
    get contacts(){
        return this.activeTab == 'contacts' ? 'slds-show' : 'slds-hide';
    }
    get reports(){ 
        return this.activeTab == 'reports' ? 'slds-show' : 'slds-hide';
    }
    get visits(){ 
        return this.activeTab == 'visits' ? 'slds-show' : 'slds-hide';
    }

    get isAuthorizedOfficial(){ 
        return this.role != undefined && (this.role.includes('Authorized Official') || this.role.includes('Program Staff'));
        // return this.role === 'Authorized Official';
    }

    get isContinuation(){
         return this.appValue=== 'Continuation';
    }
    get isNew(){
         return this.appValue=== 'new';
    }
    get showYearField(){ 
        return this.isContinuation || this.isNew;
    }

    get showApplication(){ 
        return !this.disableCreate;
    }
 
    get isSelectedAmendment(){ 
        return this.fundingDecisionSelection=== 'Start Application Amendment';
    }

    get isSelectedConference(){ 
        return this.fundingDecisionSelection=== 'Request for Conference';
    }

    get optionsTwo(){ 
        return this.isNew ? [ { value: 'Single-Year', label: 'Single-Year'}, { value: 'Multi-Year', label: 'Multi-Year'}] : [ { value: 'Year 2', label: 'Year 2'}, { value: 'Year 3', label: 'Year 3'}]
    }
}