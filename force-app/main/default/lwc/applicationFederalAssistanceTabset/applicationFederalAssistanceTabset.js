import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord, createRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import animations from '@salesforce/resourceUrl/animationsCSS';
import CONFETTI from "@salesforce/resourceUrl/confettiJS";
import SWEETALERT from "@salesforce/resourceUrl/sweetAlertJS";
import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import WelcomeSplash from '@salesforce/resourceUrl/welcomeSplash';
import utilities from 'c/utilities';

import STATUS from '@salesforce/schema/Application_for_Federal_Assistance__c.Status__c';
import SF424_STATUS from '@salesforce/schema/Application_for_Federal_Assistance__c.SF424_Status__c';
import FORM13424M_STATUS from '@salesforce/schema/Application_for_Federal_Assistance__c.Form_13424_Status__c';
import FORM13424J_STATUS from '@salesforce/schema/Application_for_Federal_Assistance__c.Form_13424_J_Status__c';
import DEADLINE from '@salesforce/schema/Application_for_Federal_Assistance__c.Submission_Deadline__c';
import generatePDF from '@salesforce/apex/ApplicationFederalAssistanceController.generatePDF';
import fetchFiles from '@salesforce/apex/ApplicationFederalAssistanceController.fetchFiles'; 
import VERSION from '@salesforce/schema/Application_for_Federal_Assistance__c.Version__c';

import AREAS_PROJECT from '@salesforce/schema/Application_for_Federal_Assistance__c.Areas_affected_by_project__c';
import AREAS_DISTRICT from '@salesforce/schema/Application_for_Federal_Assistance__c.Congressional_district_by_project__c';
import TYPE from '@salesforce/schema/Application_for_Federal_Assistance__c.Type_of_Application__c';
import createSamGovRecord from '@salesforce/apex/ApplicationFederalAssistanceController.createSamGovRecord'; 
import UEI from '@salesforce/schema/Application_for_Federal_Assistance__c.Organizational_UEI__c';
import getLegacyApplication from '@salesforce/apex/ApplicationFederalAssistanceController.getLegacyApplication'; 

const FIELDS = [STATUS, DEADLINE, SF424_STATUS, FORM13424M_STATUS, FORM13424J_STATUS, AREAS_PROJECT, AREAS_DISTRICT, TYPE, UEI, VERSION];

export default class ApplicationFederalAssistanceTabset extends utilities {

    @api recordId;
    @track isLoading;
    @track stylePath = portalStyles;
    @track stylePathTwo = animations;

    @track closeNotification;
    
    @track disableEditsSF424;
    @track disableEdits13424M;
    @track disableEdits13424J;

    @track status;
    @track form13424MStatus;
    @track form13424JStatus;
    @track sf424Status;
    @track applicationType;

    @track recordFields = [{label: 'Application number', fieldName : 'Name'}, {label: 'Application type', fieldName : 'Type_of_Application__c'}, {label: 'Form', noField : ''}, {label: 'Deadline', fieldName : 'Submission_Deadline__c'}];
    
    @track deadlinePassed;
    @track showUnsubmitApp;

    @track currentPage = 'overview';

    @track sf424Results;
    @track form13424Results;

    @track formLegacy13424Results;
    @track formLegacy13424MResults;
    @track areasAffectedProject;

    @track uei;
    @track version;
    @track legacyAppId;

    constructor() {
        super(); 
        Promise.all([
          loadStyle(this, `${this.stylePath}`),
          loadStyle(this, `${this.stylePathTwo}`), 
          loadScript(this, CONFETTI),
          loadScript(this, SWEETALERT), 
        ]).catch(error => {
              console.log(error)
        });
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.status = getFieldValue(data, STATUS);
            this.form13424MStatus = getFieldValue(data, FORM13424M_STATUS);
            this.form13424JStatus = getFieldValue(data, FORM13424J_STATUS);
            this.sf424Status = getFieldValue(data, SF424_STATUS);
            this.disableEditsSF424 = this.sf424Status === 'Submitted' || this.sf424Status === 'Amendment Submitted';
            this.disableEdits13424M = this.form13424MStatus === 'Submitted' || this.form13424MStatus === 'Amendment Submitted';
            this.disableEdits13424J = this.form13424JStatus === 'Submitted' || this.form13424JStatus === 'Amendment Submitted';
            this.applicationType = getFieldValue(data, TYPE);
            this.uei = getFieldValue(data, UEI);

            // do not allow unsubmit for main app if past deadline
            // let currentDate = Date.parse(new Date().toLocaleString());
            // let deadline = Date.parse(getFieldValue(data, DEADLINE));
            let currentDate = new Date();
            let deadline = new Date(getFieldValue(data, DEADLINE) + 'T23:59:59');

            this.showUnsubmitApp = currentDate < deadline;
            console.log(this.showUnsubmitApp)
            console.log(deadline)
            console.log(currentDate)

            // do not allow unsubmit for individual forms if main app is submitted
            this.deadlinePassed = this.status === 'Submitted' || this.status === 'Amendment Submitted' || this.status === 'Closed';

            console.log(this.deadlinePassed)


            this.areasAffectedProject = getFieldValue(data, AREAS_PROJECT) && getFieldValue(data, AREAS_DISTRICT);

            this.version = getFieldValue(data, VERSION);

        }
        else if(error){ 
            console.error(error);
        }
    }

    @wire(getLegacyApplication, { appId: '$recordId'})
    setLegacyApp({error, data}) {
        if(data){ 
            this.legacyAppId = data[0].Id;
            console.log(this.legacyAppId)
        } else if (error) console.log(error)
    }


    


    get splash() {
        return `height:600px; width:800px; background-image:url(${WelcomeSplash})`;
    }
    get showSubmissionNotification(){ 
        return this.form13424MStatus === 'Submitted' && this.sf424Status === 'Submitted' && this.form13424JStatus === 'Submitted' && !this.closeNotification && (this.status != 'Submitted' || this.status != 'Amendment Submitted' || this.status != 'Closed');
    }

    navigateFooter(){ 
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
            }
        })
    }
    closeWelcome(){ 
        this.closeNotification = true;
    }

    handleGetPage(event){
        this.currentPage = event.detail;
    }
    handleFormBoxClick(event){ 
        this.currentPage = event.currentTarget.dataset.name;
        if(this.template.querySelector('c-litc-header')) this.template.querySelector('c-litc-header').selectLink(event.currentTarget.dataset.name);
    }


    async handleSubmit(){ 
        this.template.querySelector('c-signature-capture').openModal();
    }

    async handleSignatureSuccess(){ 
        await this.generatePDFs();

        try {
            if(this.uei){ 
                this.isLoading = true;
                console.log('in createSamGovRecord');
                let res = await createSamGovRecord({applicationId: this.recordId, uei: this.uei})
                console.log(res);
            }
        } catch (error) {
            console.log(error);
        }

        let submittedValue = this.status === 'Amendment In Progress' ? 'Amendment Submitted' : 'Submitted';

        updateRecord({fields: {Id: this.recordId, 'Status__c': submittedValue, Date_Received__c: new Date().toISOString()}}).then(()=>{   
            this.isLoading = false;
            confetti({particleCount: 100, spread: 70, origin: {y: 0.6}});
    
            // configuration for SWAL
            var config = {
                icon: "success",
                title: "Thank you for Submitting! ",
                text: "You may review the information submitted and download a PDF of your report. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
                buttons: {
                    action: {
                    text: "Download File",
                    value: "file",
                    closeModal: false,
                    },
                    close: {
                        text: "Close",
                    },
                },
            }
    
            // fire SWAL
            swal(config).then(res=> { 
                if(res == 'file'){ 
                    this.downloadPDF(this.recordId);
                    // this.downloadPDF(this.recordId, 'SF424.pdf');
                    // this.downloadPDF(this.recordId, '13424-J.pdf');
                    // this.downloadPDF(this.recordId, '13424-M.pdf');
                } else{ 
                    swal.close();
                }
            })
        }).catch(error=>{ 
            console.log(error)
            this.isLoading = false;
        })  
    }

    handleSurveyNav(){ 
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                    attributes: {
                        url: '/survey?id=' + this.recordId + '&type=LITC'
            }
        })
    }

    showUnsubmit(){ 
        var config = {
            icon: "warning",
            text: "Are you sure you want to unsubmit? You will have to resubmit both forms",
            buttons: {
                close: {
                    text: "Cancel",
                    value: false
                },
                action: {
                    text: "Unsubmit",
                    value: true,
                    closeModal: false,
                },
            },
        }

        swal(config).then((res)=> { 
            if(res){ 
                swal.close();
                this.handleUnsubmitApplication();
            }
        })
    }

    handleUnsubmitApplication(){ 
        this.isLoading = true;
        updateRecord({ fields: {Id: this.recordId, Status__c: 'In Progress', SF424_Status__c: 'In Progress', Form_13424_Status__c: 'In Progress', Form_13424_J_Status__c: 'In Progress'} }).then(() => {
        }).catch(error=>{
            console.log(error);
        }).finally(()=>{ 
            this.isLoading = false;
            window.location.reload();
        })
    }

    handleResultsSF(event){ 
        this.sf424Results = event.detail;
    }
    handleResultsForm13424(event){ 
        if(this.isNewApp){ 
            this.form13424Results = event.detail;
        }
    }
    
    handleResultsFormLegacy13424(event){ 
        this.formLegacy13424Results = event.detail;
    }
    handleResultsFormLegacy13424M(event){ 
        this.formLegacy13424MResults = event.detail;
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

    downloadPDF(id){
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
                if(obj.ContentDocument.FileType == 'PDF' && obj.ContentDocument.Title === '13424-M.pdf' || obj.ContentDocument.Title === '13424.pdf'){ 
                    fileId += obj.ContentDocumentId + '/';
                    return true;
                }
            });

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
            console.log('in catch');
        })
    }

    generatePDFs(){ 
        console.log('in generatePDFs');
        this.isLoading = true;
        let mForm = this.isLegacyApp ? '13424' : '13424-M';

        return Promise.all([
            generatePDF({recordId: this.recordId, name: 'SF424'}).catch(error=>{ 
                console.log(error)
            }),
            generatePDF({recordId: this.recordId, name: '13424-J'}).catch(error=>{ 
                console.log(error)
            }),
            generatePDF({recordId: this.recordId, name: mForm}).catch(error=>{ 
                console.log(error)
            })
        ]).catch(error=>{ 
            console.log(error)
        }).finally(() => {
            this.isLoading = false; 
        });
    }

    get currentPageOverview(){
        return this.currentPage === 'overview';
    }
    get currentPageSF424(){
        if(this.currentPage === 'sf424'){ 
            this.recordFields[2].noField = 'Standard Form 424';
        }
        return this.currentPage === 'sf424';
    }
    get currentPageForm13424M(){
        if(this.currentPage === 'form13424M'){ 
            this.recordFields[2].noField = 'Form 13424-M';
        }
        return this.currentPage === 'form13424M';
    }

    get currentPageForm13424J(){
        if(this.currentPage === 'form13424J'){ 
            this.recordFields[2].noField = 'Form 13424-J';
        }
        return this.currentPage === 'form13424J';
    }

    get isAppSubmitted(){ 
        return this.status === 'Submitted' || this.status === 'Amendment Submitted' || this.status === 'Closed';
    }
    get disableSubmitButton(){ 
        return this.sf424Status != 'Submitted' || this.form13424MStatus != 'Submitted' || this.form13424JStatus != 'Submitted';
    }
    

    // 3.18.25 for initial application launch we are using legacy version...
    get isLegacyApp(){ 
        return this.version === 'Legacy';
    }
    get isNewApp(){ 
        return !this.isLegacy;
    }
}