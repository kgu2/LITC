import { LightningElement, api, track, wire } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { deleteRecord } from 'lightning/uiRecordApi';
import getContentDocumentId from "@salesforce/apex/OmniStudioFileController.getContentDocumentId";
import getReleatedFiles from '@salesforce/apex/OmniStudioFileController.releatedFiles';

const columns = [
    { label: 'Title', fieldName: 'Title' },
    { label: 'Upload date', fieldName: 'CreatedDate', type: 'date'}
];

export default class OmnistudioFileLoader extends OmniscriptBaseMixin(LightningElement) {
    @api myRecordId;
    @api disableEdits;
    @api filePrefix = '';
    @api dynamicAcceptedFormat = '.pdf';
    @api required;
    @api hideUploads = false;
    @api helpText;
    @api objectName;
    @api uploadLabel = 'Upload required document(s)';

    @api hidedownload = false;
    @api dontDeleteFiles = false;

    @track data;
    @track error;
    @track spinner = false;
    @track fileCounter = 0;
    @track columns = columns;
    @track urlLinks;
    @track selectedRecords;
    @track fileNames;

    connectedCallback(){
        console.log('dynamicAcceptedFormat:::' + this.dynamicAcceptedFormat);
    }

    contentVersionId;
    handleUploadFinished(event){
        const uploadedFiles = event.detail.files;
        const fileIds = [];
        uploadedFiles.forEach((element, idx) => {
            this.contentVersionId = element.contentVersionId;
            console.log(JSON.stringify(element));
        });
        
        getContentDocumentId({contentVersionId: this.contentVersionId})
        .then((result) => {
            this.omniUpdateDataJson(result);
        })
        .catch((error) => {
            this.omniUpdateDataJson(null);
        });

        getReleatedFiles({ contentVersionId: this.contentVersionId }).then((result) =>{
            this.wiredFileResults = result;
            if ( result ) {
                this.data = result;
                this.error = undefined; 
                
            } else if ( result.error ) {
                this.dispatchEvent(showNotification('Error!!', result.error, 'error'));
                this.error = result.error; 
                this.data = undefined;
            }
            else {
                this.data = undefined;
                this.error = undefined;
            }

        }).catch((error) => {


        });
        
    }

    get encryptedToken() {
        return this.filePrefix;
    }
     
 
     get acceptedFormats() {
         if ( this.dynamicAcceptedFormat == '' ) 
         {
            return ['.pdf', '.doc', '.docx', '.docb', '.xls', '.xlsx', '.csv', '.txt', '.jpg', '.jpeg', 'png'];
         }else return this.dynamicAcceptedFormat;
         
    }

    get removeFiles()
    {
        return this.selectedRecords != null && !this.dontDeleteFiles;
    }

    
    deleteSelected()
    {
        this.contentVersionId = undefined;
        this.data = undefined;
        this.selectedRecords = undefined;
        this.omniUpdateDataJson(null);
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

}