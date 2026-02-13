import { LightningElement, api, track, wire } from 'lwc';
import sendDocusignEnvelope from '@salesforce/apex/app605Controller.sendDocusignEnvelope';
import STATUS from '@salesforce/schema/X605_Application__c.Status__c';
import CERT_STATUS from '@salesforce/schema/X605_Application__c.Cert_Status__c';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { getRecord, getFieldValue, updateRecord } from 'lightning/uiRecordApi';
import { NavigationMixin } from 'lightning/navigation';
import handleFileValidation from '@salesforce/apex/app605Controller.handleFileUploadValidation';
import generatePDF from '@salesforce/apex/app605Controller.generatePDF';

import STREET from '@salesforce/schema/X605_Application__c.Street__c';
import CITY from '@salesforce/schema/X605_Application__c.City__c';
import STATE from '@salesforce/schema/X605_Application__c.State__c';
import POSTAL_CODE from '@salesforce/schema/X605_Application__c.Postal_Code__c';
import FIRST_AUTH from '@salesforce/schema/X605_Application__c.First_Name_of_Authorized_Representative__c';
import LAST_AUTH from '@salesforce/schema/X605_Application__c.Last_Name_of_Authorized_Representative__c';
import TITLE_AUTH from '@salesforce/schema/X605_Application__c.Title_of_Authorized_Representative__c';


const fields = [STATUS, CERT_STATUS, STREET, CITY, STATE, POSTAL_CODE, FIRST_AUTH, LAST_AUTH, TITLE_AUTH];

export default class App605Certification extends NavigationMixin(LightningElement){
    @api recordId;
    @track docusignCertification = true;
    @track certCheckboxChecked;
    @api disableEdits;
    @track isLoading = false;
    @track application;
    @track errors;
    @track currentStatus;
    @api recipType;
    @api secondTranche;

    @wire(getRecord, { recordId : '$recordId', fields })
    setData({error, data}) {
        if (data) {
            this.application = data;
            this.currentStatus = getFieldValue(this.application, STATUS) == 'Draft' || getFieldValue(this.application, STATUS) == 'Incomplete' ? 'Not Started' : getFieldValue(this.application, STATUS);
        }
        else if (error) 
            console.error(error);
    }

    handleSubmitDocusign(){
        // console.log(this.recordId);
        this.isLoading = true;
        updateRecord({ fields: { Id: this.recordId, Submission_Source__c:'Docusign', Status__c: 'Awaiting Signature'} }).then(()=>{
            sendDocusignEnvelope({recordId : this.recordId})
            .then((result)=>{
                this.showNotification('Success','Docusign successfully sent','success');
                this.errors = false;
                // console.log(result);
            })
            .catch((error)=>{
                console.error(error);
            }).finally(()=>{ 
                this.isLoading = false;
            })
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
            console.error(this.errors);
            this.dispatchEvent(new CustomEvent('geterrors', { detail: this.errors }));
            this.scrollToTop();
            this.isLoading = false;
        })
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
        // console.log(this.certCheckboxChecked);
    }

    handleDownloadAwardTermFile(){
        let errors = this.getErrors();
        console.log(errors);
        if(errors[0].errList.length != 0 || errors[1].errList.length != 0){ 
            this.errors = errors;
            this.dispatchEvent(new CustomEvent('geterrors', { detail: this.errors }));
            this.showNotification('Error','Please verify all fields are filled out','error');
        } else{ 
            generatePDF({recordId: this.recordId, certType: 'notCREC' })
            .then(result => {
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                url: result
                }
            }, false);
            });
        }
    }

    getErrors(){ 
        let tempErrors = [
            {showList: false, errList: [], label: 'Recipient'}, 
            {showList: false, errList: [], label: 'Authorized Representative'}, 
        ];

        if(!getFieldValue(this.application, STREET)){ 
            tempErrors[0].errList.push('Recipient: Street is required');
            tempErrors[0].showList = true;
        }
        if(!getFieldValue(this.application, CITY)){ 
            tempErrors[0].errList.push('Recipient: City is required');
            tempErrors[0].showList = true;
        }
        if(!getFieldValue(this.application, STATE)){ 
            tempErrors[0].errList.push('Recipient: State/Territory is required');
            tempErrors[0].showList = true;
        }
        if(!getFieldValue(this.application, POSTAL_CODE)){ 
            tempErrors[0].errList.push('Recipient: Postal Code is required');
            tempErrors[0].showList = true;
        }
        if(!getFieldValue(this.application, FIRST_AUTH)){ 
            tempErrors[1].errList.push('Authorized Representative : First Name is required');
            tempErrors[1].showList = true;
        }
        if(!getFieldValue(this.application, LAST_AUTH)){ 
            tempErrors[1].errList.push('Authorized Representative : Last Name is required');
            tempErrors[1].showList = true;
        }
        if(!getFieldValue(this.application, TITLE_AUTH)){ 
            tempErrors[1].errList.push('Authorized Representative : Title is required');
            tempErrors[1].showList = true;
        }

        return tempErrors;
    }

    handleDownloadCRECFile(){
        // console.log(this.recordId)
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
        handleFileValidation({recordId: this.recordId, certType: 'notCREC'}).then(nofile=>{
            // console.log(nofile);
            if(nofile == true){
                this.showNotification('Error','Please Upload Certification','error');
            }
            else{
                let date = new Date().toISOString();
                this.isLoading = true;
                updateRecord({ fields: { 
                    Id: this.recordId, Status__c: 'Submitted',
                    Submission_Source__c:'Manual', 
                    : date} 
                }).then(()=>{
                    this.errors = false;
                    this.showNotification('Success','Submitted','success');
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

    handleSecondTrancheSubmit(){ 
        let date = new Date().toISOString();
        this.isLoading = true;
        updateRecord({ fields: { 
            Id: this.recordId, Status__c: 'Submitted',
            Submission_Source__c:'Manual', 
            : date} 
        }).then(()=>{
            this.errors = false;
            this.showNotification('Success','Submitted','success');
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

    handleNav(event){
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
        return getFieldValue(this.application, STATUS) == 'Awaiting Signature'? true : false;
    }

    get isSubmitted() {
        return getFieldValue(this.application, STATUS) == 'Submitted'? true : false;
    }

    get isDraft(){ 
        return getFieldValue(this.application, STATUS) == 'Draft' || getFieldValue(this.application, STATUS) == 'Incomplete' || getFieldValue(this.application, STATUS) == 'Failed Payee Verification Review' || getFieldValue(this.application, STATUS) == undefined ? true : false;
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

    handleSurveyNav(){ 
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
                    attributes: {
                        url: '/survey?id=' + this.recordId + '&type=app'
            }
        });
    }

    get county(){ 
        return this.recipType == 'Eligible Revenue Sharing County' || this.recipType == 'Consolidated Government';
    }

    get tribal(){ 
        return this.recipType == 'Tribal Government';
    }

}