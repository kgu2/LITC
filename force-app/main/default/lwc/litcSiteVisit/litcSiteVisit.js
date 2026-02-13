import { LightningElement, api, wire, track } from 'lwc';
import { getFieldValue, getRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import { refreshApex } from '@salesforce/apex';
import utilities from 'c/utilities';
import { loadStyle, loadScript } from 'lightning/platformResourceLoader';
import STATUS from '@salesforce/schema/Site_Visit__c.Recipient_Status__c';
import fetchFiles from '@salesforce/apex/ApplicationFederalAssistanceController.fetchFiles'; 

import portalStyles from '@salesforce/resourceUrl/LITCPortalStyles';
import getLineItems from '@salesforce/apex/SiteVisitController.getLineItems';
import getMyRole from '@salesforce/apex/litcLoginController.getMyRole';

const FIELDS = [STATUS];

const columns = [
    { label: 'Intake date', fieldName: 'Intake_Date__c', type : 'text', hideDefaultActions: true},
    { label: 'Client ID', fieldName: 'Client_ID__c', type : 'text', hideDefaultActions: true},
    { label: 'Explanation', fieldName: 'Explanation__c', type : 'text', hideDefaultActions: true},
    {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
        iconName: 'utility:edit',
        variant: 'bare'
    }}
];


export default class LitcSiteVisit extends utilities {

    @api recordId;
    @track status;
    @track disableEdits;
    @track stylePath = portalStyles;
    @track isLoading;
    @track recordFields = [{label: 'Record name', fieldName : 'Name'}, {label: 'Clinic name', fieldName : 'Clinic_Name__c'}];// {label: 'Date of site assistance visit', fieldName : 'Visit_Date__c'}
    @track activeTab;
    dynamicAcceptedFormat = ['.pdf', '.doc', '.docx', '.docb','.tif', '.csv'];

    @track showTable;
    @track showModal;
    @track showConfirmationModal;
    @track selectedLineItem;
    @track columns = columns;
    @track records;
    @track deadlinePassed = true;

    @track referencedFiles;
    @track fileName;

    @track showExplanation;


    handleOnActive(event) {
        this.activeTab = event.target.value;
    }

    @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
    setApp({error, data}) {
        if (data) {
            this.status = getFieldValue(data, STATUS);
            this.disableEdits = getFieldValue(data, STATUS) === 'Submitted' || this.isViewOnly;
        }
        else if(error){ 
            console.error(error);
        }
    }

    constructor() {
        super(); 
        Promise.all([
          loadStyle(this, `${this.stylePath}`),
        ]).catch(error => {
              console.log(error)
        });
    }

    @wire(getLineItems, { reportId: '$recordId'})
    setReportsType(res) {
        this.lineItemsByTypeResult = res;
        if (res.data) {   
            this.records = res.data;      
            this.showTable = res.data.length > 0;
        }
        else if (res.error) {
            console.log(res.error);
        }

    }

    connectedCallback(){ 
        console.log('in hree')
        fetchFiles({recordId: this.recordId}).then(data=>{
            // this.referencedFiles = data;    
            let filesList = JSON.parse(JSON.stringify(data));

            let fileId = '';
            let fileName = '';

            filesList.some(obj => {
                if(obj.ContentDocument.Title.includes('share')){ 
                    fileId += obj.ContentDocumentId + '/';
                    fileName = obj.ContentDocument.Title;
                    return true;
                }
            });
            this.referencedFiles = fileId;
            this.fileName = fileName;
        }).catch(err=>{ 
            console.log(err)
        })

        getMyRole().then(data=>{ 
            this.role= data;
        }) 
    }

    handleSave(field, value){ 
        updateRecord({fields: {Id: this.recordId, [field]: value}});
    }

    autosave(event){ 
        this.handleSave(event.target.fieldName, event.target.value);
    }

    handleFileDownload(event){ 
        let baseUrl = window.location.href;
        baseUrl = baseUrl.substring(0, baseUrl.indexOf('/s'));
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: baseUrl + '/sfc/servlet.shepherd/document/download/' + event.target.value + '?operationContext=S1'
            }
        }, false)
    }

    handleNav(event){ 
        this.activeTab = event.target.value
    }

    get form(){
        return this.activeTab === 'form' ? 'slds-show' : 'slds-hide';
    }
    get form2(){
        return this.activeTab === 'form2' ? 'slds-show' : 'slds-hide';
    }

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    async handleSuccess(event){ 
        console.log('in handleSuccess')  
        this.showNotification('Saved', 'Saved', 'success');
        refreshApex(this.lineItemsByTypeResult);
        this.selectedLineItem = null;
        this.showModal =false;
    }

    openAddLineItemModal(){ 
        this.showModal = true;
        this.handleRenderConditional();
    }
    openEditLineItemModal(event){ 
        this.selectedLineItem = event.detail.row.Id;
        this.showModal = true;
        this.handleRenderConditional();
    }

    handleRenderConditional(){ 
        setTimeout(() => {
            let fieldA = this.template.querySelector('.fieldA');
            let fieldB = this.template.querySelector('.fieldB');

            if ((fieldA && fieldA.value === 'Yes') || (fieldB && fieldB.value === 'Yes')) {
                this.showExplanation = true;
            } else{ 
                this.showExplanation = false;
            }
        }, 500)
    }

    closeEditLineItemModal(){ 
        this.showModal = false;
        this.showExplanation=null
    }
    openConfirmationModal(){ 
        this.showConfirmationModal = true;
    }
    closeConfirmationModal(){ 
        this.showConfirmationModal = false;
    }

    handleDelete(){ 
        deleteRecord(this.selectedLineItem).then(()=>{ 
            this.showNotification('Saved', 'Saved', 'success');
            this.closeEditLineItemModal();
            refreshApex(this.lineItemsByTypeResult);
        })
    }


    async handleSubmit(event){
        event.preventDefault();

        this.isLoading = true;
        this.showConfirmationModal = false;

        await updateRecord({ fields: {Id: this.recordId, 'Recipient_Status__c': 'Submitted', Submitted_Date__c: new Date().toISOString()} });
        console.log("SAVED");

        this.isLoading = false;
       
        const config = {
            icon: "success",
            title: "This form has been Submitted",
            text: "The reporting record has been submitted. You will be notified if it has been accepted or returned. If you need to make any changes you may unsubmit at any time before the submission deadline.\n",
            buttons: {
                close: {
                    text: "Close",
                },
            },
        };
        await swal(config);
        swal.close();

        this.activeTab= 'form';

        //  await generatePDF({recordId: this.recordId, vfPageName: 'LITCReportingRPDF', prefix: filePrefix});
    }
    

    get isViewOnly(){ 
        return this.role !== undefined && this.role === 'View Only Staff';
    }
}