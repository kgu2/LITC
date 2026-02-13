import { LightningElement, api, track, wire } from 'lwc';
import sendDocusignEnvelope from '@salesforce/apex/app605Controller.sendDocusignEnvelopeCREC';
import STATUS from '@salesforce/schema/X605_Application__c.Status__c';
import CERT_STATUS from '@salesforce/schema/X605_Application__c.CREC_Status__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import handleFileValidation from '@salesforce/apex/app605Controller.handleFileUploadValidation';
import generatePDF from '@salesforce/apex/app605Controller.generatePDF';

const fields = [STATUS, CERT_STATUS];
export default class App605CREC extends NavigationMixin(LightningElement) {
    @api recordId;
    @track docusignCertification = true;
    @track certCheckboxChecked;
    @api disableEdits;
    @track isLoading = false;
    @track application;
    @track errors;
    @track currentStatus;

    @wire(getRecord, { recordId : '$recordId', fields })
    setData({error, data}) {
        if (data) {
            this.application = data;
            this.currentStatus = getFieldValue(this.application, CERT_STATUS);
        }
        else if (error) 
            console.error(error);
    }

    handleSubmitDocusign(){
        //console.log(this.recordId);
        this.isLoading = true;
        sendDocusignEnvelope({recordId : this.recordId})
            .then((result)=>{
                this.showNotification('Success','Docusign successfully sent','success');
                this.errors = false;
                //console.log(result);
                updateRecord({ fields: { Id: this.recordId, CREC_Status__c: 'Awaiting Signature'} })
            })
            .catch((error)=>{
                console.error(error);
                let temp = error.body.output.fieldErrors;
                let tempErrors = [
                    {showList: true, errList: [], label: 'Recipient'}, 
                    {showList: true, errList: [], label: 'Authorized Representative'}, 
                    {showList: true, errList: [], label: 'Contact Person'},
                    {showList: true, errList: [], label: 'Financial Institution Information'}];

                Object.values(temp).forEach(val => { 
                    tempErrors.forEach(item=>{ 
                        if(val[0].message.includes(item.label)){ 
                            item.errList.push(val[0].message);
                        }
                    });
                });

                tempErrors.forEach(item=>{ 
                    if(item.errList.length == 0){ item.showList = false}
                });

                this.errors = tempErrors;
                console.error(this.errors);
                this.dispatchEvent(new CustomEvent('geterrors', { detail: this.errors }));
                this.scrollToTop();
                this.isLoading = false;
            }).finally(()=>{ 
                this.isLoading = false;
            });
    }

    handleSubmissionSourceChange(event){ 
        this.docusignCertification = event.target.value == 'Docusign';
        this.certCheckboxChecked = false;
    }

    handleManualClick(){ 
        this.template.querySelector('.submissionSource').value = 'Manual';
    }

    handleDocusignClick(){ 
        this.template.querySelector('.submissionSource').value = 'Docusign';
    }

    showNotification(ntf_Title, ntf_Message, ntf_Variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: ntf_Title,
                message: ntf_Message,
                variant: ntf_Variant,
                mode: 'dismissable'
            }),
        );
    }

    handleCheckboxCertify(event){
        this.certCheckboxChecked = event.target.checked;
        //console.log(this.certCheckboxChecked);
    }

    handleDownloadAwardTermFile(){
        //console.log(this.recordId)
        generatePDF({recordId: this.recordId, certType: 'CREC' })
        .then(result => {
          this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
              url: result
            }
          }, false);
        });
    }

    submitManual(){
        handleFileValidation({recordId: this.recordId, certType: 'CREC'}).then(nofile=>{
            //console.log(nofile);
            if(nofile == true){
                this.showNotification('Error','Please Upload Certification','error');
            }
            else{
                let date = new Date().toISOString();
                this.isLoading = true;
                updateRecord({ fields: { 
                    Id: this.recordId, CREC_Status__c: 'Submitted',
                    CREC_Source__c:'Manual', 
                    Submitted_Date__c: date} 
                }).then(()=>{
                    this.errors = false;
                    this.showNotification('Success','Submitted','success');
                    // this[NavigationMixin.Navigate]({
                    //     type: 'standard__webPage',
                    //             attributes: {
                    //                 url: '/survey?id=' + this.recordId + '&type=app'
                    //     }
                    // });
                }).catch(error=>{
                    console.error(error);
                    let temp = error.body.output.fieldErrors;
                    let tempErrors = [
                        {showList: true, errList: [], label: 'Recipient'}, 
                        {showList: true, errList: [], label: 'Authorized Representative'}, 
                        {showList: true, errList: [], label: 'Contact Person'},
                        {showList: true, errList: [], label: 'Financial Institution Information'}];

                    Object.values(temp).forEach(val => { 
                        tempErrors.forEach(item=>{ 
                            if(val[0].message.includes(item.label)){ 
                                item.errList.push(val[0].message);
                            }
                        });
                    });

                    tempErrors.forEach(item=>{ 
                        if(item.errList.length == 0){ item.showList = false}
                    });

                    this.errors = tempErrors;
                    this.dispatchEvent(new CustomEvent('geterrors', { detail: this.errors }));
                    this.scrollToTop();
                }).finally(()=>{
                    this.isLoading = false;
                })
            }
        }).catch(error=>{ 
            console.error(error);
        })
    }

    handleNav(event){
        //console.log(event.target.name)
        const selectedEvent = new CustomEvent("changetab", {
            detail: event.target.name
        });
        this.dispatchEvent(selectedEvent);
    }

    scrollToTop(){ 
        const scrollOptions = {
            left: 0,
            top: 0,
            behavior: 'smooth'
          }
        window.scrollTo(scrollOptions);
    }

    get isAwaitingSignature() {
        return getFieldValue(this.application, CERT_STATUS) == 'Awaiting Signature'? true : false;
    }

    get isSubmitted() {
        return getFieldValue(this.application, CERT_STATUS) == 'Submitted'? true : false;
    }

    get isDraft(){ 
        return getFieldValue(this.application, CERT_STATUS) == 'Not Started' || getFieldValue(this.application, CERT_STATUS) == undefined ? true : false;
    }

    get formStyle(){
        if(this.currentStatus == 'Submitted'){ 
            return 'color:#2E8540';
        } else if (this.currentStatus == 'Awaiting Signature') 
            return 'color:#D8BE0E';
        else{ 
            return 'color:#930012';
        }
    }
}