import { LightningElement, wire, api, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import portalStyles from '@salesforce/resourceUrl/SLFRFPortalStyles';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import FileUtilities from 'c/fileUtilities';
import logoAboveVertNavSLFRF from '@salesforce/resourceUrl/app605Card';
import WelcomeSplash from '@salesforce/resourceUrl/WelcomeSplash';
import getWelcome from '@salesforce/apex/LATCFComplianceController.getWelcomeField';
import generateFile from '@salesforce/apex/LATCFComplianceController.generateFile';
import getCurrentContact from '@salesforce/apex/AccountPortalPageController.getCurrentContactInformation';
import SHOW_WELCOME from '@salesforce/schema/SLT_Compliance_Report__c.Report_Started__c';
import STATUS from '@salesforce/schema/SLT_Compliance_Report__c.Status__c';
import fetchFiles from '@salesforce/apex/SLFRF_PDF_ComplianceController.fetchFiles'; 
import animations from '@salesforce/resourceUrl/animate';
import CONFETTI from "@salesforce/resourceUrl/confetti";
import SWEETALERT from "@salesforce/resourceUrl/sweetalert";
import ALLOCATION_AMOUNT from '@salesforce/schema/SLT_Compliance_Report__c.LATCF_Allocation_Amount__c';
import DEADLINE from '@salesforce/schema/SLT_Compliance_Report__c.Submission_Deadline__c';
import PERIOD from '@salesforce/schema/SLT_Compliance_Report__c.Report_Period__c';
import Q1 from '@salesforce/schema/SLT_Compliance_Report__c.Audit_Expended_750000_More__c';
import Q2 from '@salesforce/schema/SLT_Compliance_Report__c.Submitted_Single_Audit__c';
import CURRENT_USER_PROFILE_NAME from '@salesforce/apex/EmergencyCapitalInvestmentRegulatorCtrl.getCurrentUserProfileName';
import generateRC from '@salesforce/apex/LATCFComplianceController.generateRC';
import REMAINING_AMOUNT from '@salesforce/schema/SLT_Compliance_Report__c.Total_Remaining_LATCF_Allocation_Amount__c';


const FIELDS = [SHOW_WELCOME, STATUS, ALLOCATION_AMOUNT, DEADLINE, PERIOD, Q1, Q2, REMAINING_AMOUNT];


export default class LatcfAnnualReport extends FileUtilities  {

    @track stylePath = portalStyles;
    @track stylePathTwo = animations;
    @track slfrfCard = logoAboveVertNavSLFRF;
    @api recordId; 
    @api reportId;
    @track record;
    @track activeTab="instructions";
    @track disableEdits;
    @track deadlinePassed;
    @track isLoading;
    @track isWaiting;
    @track allocationAmount;
    @track showCheckboxCertify;
    @track checkboxValue;
    @track questionValue = 'No';

    // current logged in contact  
    @track userEmail;
    @track userPhone;
    @track userTitle;
    @track userName;
    @track userRole;

    // accordian infobox
    @track status;
    @track fields = [
        {label: 'Report Name', fieldName: 'Name'},  
        {label: 'Report Type', noField : 'LATCF Annual Report'}, 
        {label: 'Submission Deadline', fieldName : 'Submission_Deadline__c'},
        {label: 'Allocated Amount', fieldName : 'LATCF_Allocation_Amount__c'}, 
    ];
    @track showToggle;

    //modals
    @track showCertModal;

    //overview totals
    @track cumulativeObl;
    @track cumulativeExp;
    @track currentPeriodExp;
    @track currentPeriodObl;
    @track remainingAllocatedAmount;

    // 2023
    @track q1Value; q2Value; 
    @track dontShowCloseout;

    @track confettiModalClosed;



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

    connectedCallback(){ 
        getWelcome({ recordId: this.reportId}).then((data)=>{ 
            this.showWelcome = !data;
        }).catch(error=>{ 
            console.error(error);
        })
    }

    @wire(CURRENT_USER_PROFILE_NAME)
    Profile({ error, data }){
        if(data) {
            this.currentUserProfileName = data;
        }
        else if( error ) {	
            console.error('error > ' + JSON.stringify(error));	
        }	
    };


    @wire(getRecord, { recordId: '$reportId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.record = data;
            this.status = getFieldValue(this.record, STATUS);
            this.disableEdits = getFieldValue(this.record, STATUS) == 'Draft' || getFieldValue(this.record, STATUS) == 'Reopened' ? false : true;
            this.allocationAmount = getFieldValue(this.record, ALLOCATION_AMOUNT);
            let currentDate = Date.parse(new Date().toLocaleString());
            let deadline = Date.parse(getFieldValue(this.record, DEADLINE));
            this.deadlinePassed = currentDate > deadline && this.status == 'Submitted';
        }
        else if(error){ 
            console.error(error);
        }
    }

    @wire(getCurrentContact)
    setCurrentContactData({error,data}){
        if(data){
            this.userEmail = data.Email;
            this.userName = data.Name;
            this.userTitle = data.Title;
            this.userPhone = data.Phone;
            this.userRole = JSON.stringify(data.Roles__c);
        } else if (error){ 
            console.log(error);
        }
    }

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    handleSubmit(){     
        if(!this.userRole || (!this.userRole.includes('Authorized Representative') && !this.userRole.includes('Account Administrator'))){ 
            this.showNotification('Insufficent Access...', 'Only LATCF Authorized Representative(s) or Account Administrator(s) can submit this record. Your Account Administrator can edit access."', 'error');
        } else{ 
            this.isLoading = true;
            this.template.querySelector('c-latcf-annual-report-project').handleTEST();
            setTimeout(()=>{ 
                // Jurisdiction_Expended_LATCF_Funds__c: this.checkboxValue,
                updateRecord({ fields: { 
                        Id: this.reportId, Status__c: 'Submitted', 
                        LATCF_Spent_Funds_Lobbying__c: this.questionValue,
                        Submitted_Auth_Rep_Name__c: this.userName, Submitted_Auth_Rep_Phone__c: this.userPhone, 
                        Submitted_Auth_Rep_Title__c: this.userTitle, Submitted_Auth_Rep_Email__c: this.userEmail, 
                        LATCF_Cumulative_Expenditures__c: this.cumulativeExp, LATCF_Cumulative_Obligations__c: this.cumulativeObl, LATCF_Cumulative_Current_Period_Obl__c: this.currentPeriodObl, LATCF_Cumulative_Current_Period_Exp__c: this.currentPeriodExp,
                        Submission_Date__c: new Date().toISOString()  } })
                    .then(() => {
                        // generate files
                        generateFile({reportId : this.reportId, type: 'csv'}).then(() =>{ 
                            generateFile({reportId : this.reportId, type: 'pdf'}).then(()=>{ 
                                this.isLoading = false;
    
                                generateRC({recordId : this.reportId}).catch(err=>{ 
                                    console.log(err)
                                })
    
                                // fire confetti!
                                confetti({particleCount: 100, spread: 70, origin: {y: 0.6}});
    
                                // configuration for SWAL
                                var config = {
                                    icon: "success",
                                    title: "Thank you for Submitting!",
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
                                        // gets the files attached and downloads the first one
                                        fetchFiles({recordId: this.reportId}).then(data=>{ 
                                            let filesList = JSON.parse(JSON.stringify(data));
    
                                            let fileIdPDF = '';
                                            let fileIdCSV = '';
    
                                            filesList.some(obj => {
                                                if(obj.ContentDocument.FileType == 'PDF'){ 
                                                    fileIdPDF = obj.ContentDocumentId;
                                                }
                                                if(obj.ContentDocument.FileType == 'EXCEL'){ 
                                                    fileIdCSV = obj.ContentDocumentId;
                                                }
                                            });
                            
                                            if(fileIdPDF && fileIdCSV){ 
                                                let baseUrl = window.location.href;
                                                baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
                            
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__webPage',
                                                    attributes: {
                                                        url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileIdPDF + '?operationContext=S1'
                                                    }
                                                }, false);
                                                this[NavigationMixin.Navigate]({
                                                    type: 'standard__webPage',
                                                    attributes: {
                                                        url: baseUrl + '/sfc/servlet.shepherd/document/download/' + fileIdCSV + '?operationContext=S1'
                                                    }
                                                }, false);
                                            }
                            
                                        }).catch(error=>{ 
                                            console.log(error);
                                        }).finally(()=>{ 
                                            swal.close();
                                            console.log('in HERE 1');
                                            this.confettiModalClosed = true;
                                        })
                                    }else{ 
                                        console.log('in HERE 2');
                                        this.confettiModalClosed = true;
                                    }
                        
                                })
                            }).catch(error=>{ 
                                console.log(error);
                                this.isLoading = false;
                            })
                        }).catch(error=>{ 
                            console.log(error);
                            this.isLoading = false;
                        })
                    })
                .catch(error => {
                    console.log(error);
                    this.isLoading = false;
                    this.showNotification('Error', 'There was an error submitting.', 'error');
                })
    
            }, 4000); 
            
        }
   
    }

    handleSave(){ 
        this.template.querySelector('c-latcf-annual-report-project').handleTEST();
        this.showNotification('Success', 'Saved.', 'Success');
    }

    handleGetTotal(event){ 
        this.cumulativeObl = event.detail.cumulativeObl;
        this.cumulativeExp = event.detail.cumulativeExp;
        this.currentPeriodExp = event.detail.currentPeriodExp;
        this.currentPeriodObl = event.detail.currentPeriodObl;
        this.showCheckboxCertify = parseFloat(this.cumulativeExp) == this.allocationAmount;
    }

    handleGetWait(event){ 
        console.log(event.detail);
        this.isWaiting = event.detail;
    }

    handleGetErrors(event){ 
        console.log(event.detail);
    }

    handleCheckbox(event){ 
        this.checkboxValue = event.target.checked;
    }

    handleLobbyingChange(event){ 
        this.questionValue = event.target.value;
    }

    // infobox
    collapse(){ 
        this.template.querySelector('.containerInfobox').classList.add('animate__fadeOutRight');
        setTimeout(() => {
            this.showToggle = !this.showToggle;
        }, 700); 
        setTimeout(() => {
            this.template.querySelector('.container').classList.replace('slds-small-size_10-of-12', 'slds-small-size_12-of-12');
            this.template.querySelector('.containerInfobox').classList.remove('animate__fadeOutRight');
        }, 900); 

    }
    expand(){ 
        this.template.querySelector('.container').classList.replace('slds-small-size_12-of-12', 'slds-small-size_10-of-12');
        this.showToggle = !this.showToggle;
        this.template.querySelector('.containerInfobox').classList.add('animate__fadeInRight'); 
        setTimeout(() => {
            this.template.querySelector('.containerInfobox').classList.remove('animate__fadeInRight');
        }, 900); 
    }


    // welcome mat
    @track showWelcome;
    @track welcomeMatCheckbox = false;

    get splash() {
        return `height:600px; width:800px; border-radius:6px; background-image:url(${WelcomeSplash})`;
    }

    closeWelcome(){ 
        this.showWelcome = false;
        // updateRecord({ fields: {Id: this.reportId, Report_Started__c: this.welcomeMatCheckbox} }).catch(error=>{
        //     console.error(error);
        // })
    }

    handleDontShow(event){ 
        this.welcomeMatCheckbox = event.target.checked;
    }

    get showError(){ 
        return this.isWaiting && this.template.querySelector('c-latcf-annual-report-project').getTrueIfErrors();
    }


    // TABSET NAV
    get recipient(){
        return this.activeTab === 'recipient' ? 'slds-show' : 'slds-hide';
    }
    get form(){
        return this.activeTab === 'form' ? 'slds-show' : 'slds-hide';
    }
    get certification(){
        return this.activeTab === 'certification' ? 'slds-show' : 'slds-hide';
    }
    get instructions(){
        return this.activeTab === 'instructions' ? 'slds-show' : 'slds-hide';
    }
    handleChangeTab(event){
        this.template.querySelector('lightning-tabset').activeTabValue = event.target.name;
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
          }
        window.scrollTo(scrollOptions);
    }
    handleOnActive(event) {
        this.activeTab = event.target.value;
        this.handleSave();
        this.template.querySelector('.container').classList.remove('fade');
        setTimeout(() => {
            this.template.querySelector('.container').classList.add('fade'); 
        });
    }
    handleSurveyNav(){ 
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                    attributes: {
                        url: '/survey?id=' + this.reportId + '&type=latcf'
            }
        });
    }

    navigateToHome(){ 
        if(this.currentUserProfileName == 'Compliance Community Login'){
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'home',
                },
                state: {
                    closeout: 'true'
                }
            });
        }
        else{
            this[NavigationMixin.Navigate]({
                type: 'comm__namedPage',
                attributes: {
                    pageName: 'slt',
                },
                state: {
                    closeout: 'true'
                }
            });
        }
    }


    // 2023 req
    
    get is2023(){ 
        return getFieldValue(this.record, PERIOD) === 'Annual 2023';
    } 

    handleSaveAuto(field, value){ 
        updateRecord({fields: {Id: this.reportId, [field]: value}});
    }

    autosave(event){ 
        this.handleSaveAuto(event.target.fieldName, event.target.value);
        console.log(event.target.value);
        if(event.target.fieldName === 'Audit_Expended_750000_More__c') this.q1Value = event.target.value;
        if(event.target.fieldName === 'Submitted_Single_Audit__c') this.q2Value = event.target.value;
    }

    get q1Yes(){ 
        return this.q1Value ? this.q1Value === 'Yes' : getFieldValue(this.record, Q1) === 'Yes';
    }
    get q2Yes(){ 
        return this.q2Value ? this.q2Value === 'Yes' : getFieldValue(this.record, Q2) === 'Yes';
    }
    get q2No(){ 
        return this.q2Value ? this.q2Value === 'No' : getFieldValue(this.record, Q2) === 'No';
    }

    get showCloseout(){ 
        return this.showCheckboxCertify && this.activeTab === 'certification' && !this.dontShowCloseout && !this.disableEdits && getFieldValue(this.record, Q1);
    }
    get showCloseoutModalAfterSubmission(){ 
        return this.showCheckboxCertify && this.activeTab === 'certification' && !this.dontShowCloseout && this.disableEdits;
    }

    handleCloseoutClick(event){ 
        console.log(event.target.name)
        updateRecord({fields: {Id: this.reportId, Ready_for_closeout__c : event.target.name}});
        this.dontShowCloseout = true;
    }

    closeCloseout(){ 
        this.dontShowCloseout = true;
    }

    get showCloseoutModal(){ 
        return getFieldValue(this.record, REMAINING_AMOUNT) <= 500 && getFieldValue(this.record, STATUS) === 'Submitted' && this.confettiModalClosed == true;
        // return getFieldValue(this.record, REMAINING_AMOUNT) === 0 && getFieldValue(this.record, STATUS) === 'Submitted' && this.confettiModalClosed == true;
    }


    closeFinalCloseoutModal(){ 
        this.confettiModalClosed = false;
    }

}