import { LightningElement, api, track, wire } from 'lwc';
import { deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
import updateRecord from '@salesforce/apex/LWCUploadController.updateRecord';
import getReleatedFiles from '@salesforce/apex/LWCUploadController.releatedFiles';
import generateDownloadURLs from '@salesforce/apex/LWCUploadController.generateDownloadURLs';
import deleteURLs from '@salesforce/apex/LWCUploadController.deleteURL';

const columns = [
    { label: 'Title', fieldName: 'Title' },
    { label: 'Upload date', fieldName: 'CreatedDate', type: 'date'},
    { label: 'View uploaded file', type: 'button', typeAttributes: { label: 'View uploaded file', name : 'downloadFile', disabled: false, value:'viewBtn', class: 'scaled-down', variant:'brand-outline' } }
];

const ssbciQuarterlyColumns = [
    { label: 'Title', fieldName: 'Title' },
    { label: 'Upload date', fieldName: 'CreatedDate', type: 'date',
    typeAttributes: {
        day:'numeric',
        month:'short',
        year:'numeric',
        hour:'2-digit',
        minute:'2-digit',
        second:'2-digit',
        hour12:true
    }},
    { label: 'View uploaded file', type: 'button', typeAttributes: { label: 'View uploaded file', name : 'downloadFile', disabled: false, value:'viewBtn', class: 'scaled-down', variant:'brand-outline' } }
];

export default class FileLoader extends NavigationMixin(LightningElement) {
    @api myRecordId;
    @api disableEdits = false;
    @api filePrefix = '';
    @api dynamicAcceptedFormat = '';
    @api hidedownload = false;
    @api required;
    @api hideUploads = false;
    @api helpText = '';
    @api dontDeleteFiles = false;
    @api objectName;
    //@api uploadLabel = 'Upload required document(s)';
    @api uploadLabel = '';

    @track data;
    @track error;
    @track spinner = false;
    @track fileCounter = 0;
    @track columns = this.objectName == 'SSBCI_Quarterly_Report__c' ? ssbciQuarterlyColumns : columns;;
    @track urlLinks;
    @track selectedRecords;

    @api manualRefresh(){ 
        console.log('in manual refresh')
        refreshApex(this.wiredFileResults);
    }


    renderedCallback() {
        if (this.data != undefined) refreshApex(this.wiredFileResults);

        this.columns = this.objectName == 'SSBCI_Quarterly_Report__c' ? ssbciQuarterlyColumns : columns;
    }

    
    deleteSelected()
    {
        let originalNumber = 0;
        
        if (this.data) {
           // console.log('original files: ' + this.data.length)
            originalNumber  = this.data.length;    
        }
        
        const fileRemoveIds = this.selectedRecords.split(",");
        
        for(var i = 0; i < fileRemoveIds.length; i++) {
            const item = fileRemoveIds[i];
            deleteRecord(item).then(() => {  
                console.log("deleted"); 
            })
            .catch(error => { 
                console.log(error); 
            })
            .finally(() => {
                this.selectedRecords = null;
                this.data = undefined;
                refreshApex(this.wiredFileResults);
            });
        };

        const loadEvent = new CustomEvent('filedeleted', { detail: {original: originalNumber, deleted: fileRemoveIds.length },bubbles:true});
        this.dispatchEvent(loadEvent);

    }


    generateURLS(event) {
        var documentId = event.detail.row.ContentDocumentId;

        console.log('downloading');
        generateDownloadURLs({ contentDocumentId : documentId })
        .then(data => {
            this.urlLinks = data;
            this.filePreview(documentId);
        })
        .catch(error => {
            console.log(JSON.stringify(error));
        });
        
    }


    filePreview(contentDocumentId) {
        // Naviagation Service to the show preview  
        var versionId = 0;

        for ( var i = 0; i < this.data.length; i++ ){
            if ( this.data[i].ContentDocumentId == contentDocumentId )
            {
                versionId = this.data[i].Id;
                break;
            }        
        }

       
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__webPage',
            attributes: {
                url: this.urlLinks
                
            }
          }).then(generatedUrl => {
                window.open(generatedUrl);
        }).catch(error => {
            console.log(error);
        }).finally(() => {
            deleteURLs({ contentVersionId : versionId });
        });
        
    }

   
    get encryptedToken() {
       return this.filePrefix;
    }
    

    get acceptedFormats() {
        if ( this.dynamicAcceptedFormat == '' ) return ['.pdf', '.doc', '.docx', '.docb', '.xls', '.xlsx', '.csv', '.txt', '.jpg', '.jpeg', 'png'];
        else return this.dynamicAcceptedFormat;
    }


    get removeFiles()
    {
        console.log({
            'this.selectedRecords' : this.selectedRecords,
            'this.dontDeleteFiles' : this.dontDeleteFiles
        });

        return (this.selectedRecords != null && this.selectedRecords != '') && !this.dontDeleteFiles;
    }


    handleUploadFinished(event) {

        const uploadedFiles = event.detail.files;
        const fileIds = [];
        uploadedFiles.forEach((element, idx) => {
            //console.log('FILE:'+element.documentId);
            fileIds.push(element.documentId);
        });

        //console.log("In fileLoader: " + { recordId:this.myRecordId, uploadIds : fileIds, prefix : this.filePrefix });

        updateRecord({ recordId:this.myRecordId, uploadIds : fileIds, prefix : this.filePrefix }).then(result => {
            this.fileCounter = this.fileCounter + 1;
            const loadEvent = new CustomEvent('fileloaded', { detail: {parentId: this.myRecordId, files: uploadedFiles },bubbles:true });
            this.dispatchEvent(loadEvent);
        })
        .finally(() => {
            this.selectedRecords = null;
            this.data = undefined;
            refreshApex(this.wiredFileResults);
        })

    }
    

    // Getting releated files of the current record
    wiredFileResults;
    @wire(getReleatedFiles,{ idParent: '$myRecordId', prefix: '$filePrefix', fileCount: '$fileCounter' })
    files(result)  {
        console.log(result);
        this.wiredFileResults = result;
        if ( result.data ) {
            this.data = result.data;
            this.error = undefined; 
            
        } else if ( result.error ) {
            this.error = result.error; 
            this.data = undefined;
        }
        else {
            this.data = undefined;
            this.error = undefined;
        }
    }


    // Getting selected rows to perform any action
    getSelectedRecords(event) {
        let conDocIds;
        const selectedRows = event.detail.selectedRows;
        conDocIds = new Set();

        // Display that fieldName of the selected rows
        for ( let i = 0; i < selectedRows.length; i++ ){
            conDocIds.add(selectedRows[i].ContentDocumentId);
        }

        this.selectedRecords = Array.from(conDocIds).join(',');
        
    }

    get updatedHelptext(){ 
        return this.helpText + this.acceptedFormats;
    }

}