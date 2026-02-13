import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class guestFileUpload extends LightningElement {

    @api recId;
    relatedRecordBool = true;
    currentPageReference;
    uploadFinish;

    acceptedFormats = ['.jpg', '.jpeg', '.png'];

    handleUploadFinished(event) {

        const uploadedFiles = event.detail.files;
        let noOfFiles = uploadedFiles.length;
        console.log( 'No. of files uploaded', noOfFiles );
        this.dispatchEvent(
            new ShowToastEvent( {
                title: 'File(s) Download',
                message: noOfFiles + 'File(s) Uploaded Successfully',
                variant: 'success'
            } ),
        );

        this.uploadFinish = true;
        const loadEvent = new CustomEvent('fileloaded', { detail: true ,bubbles:true});
        this.dispatchEvent(loadEvent);

    }

}