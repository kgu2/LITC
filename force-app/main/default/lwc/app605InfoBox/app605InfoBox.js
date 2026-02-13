import { LightningElement, api,track} from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi'
import { NavigationMixin } from 'lightning/navigation';
import SWEETALERT from "@salesforce/resourceUrl/sweetalert";
import { loadScript } from 'lightning/platformResourceLoader';

export default class App605InfoBox extends NavigationMixin(LightningElement) {

    constructor() {
        super();
        Promise.all([
          loadScript(this, SWEETALERT)
        ]).catch(error => {
              console.log(error)
        });
    }


    @api recordId;
    @api objectName;

    // optional status field gets passed in separately 
    @api status;
    @api statusOne;
    @api statusTwo;

    @api deadlinePassed;
    @api showUnsubmit;
    @api program; 

    // pased in a list of fields in the form of [{label : 'label', fieldName: 'fieldName'}, ...]
    @api fields;

    // set true to hide status field 
    @api hideStatus = false;

    // set true to show legend tab
    @api showLegend = false;

    @track activeSections = ['Record-Details', 'Errors'];

    @track showFAQModal;
    @track showUnsubmitModal;
    

    get formStyle(){
        if(this.status == 'Submitted'){ 
            return 'color:#2E8540';
        } else if (this.status == 'Awaiting Signature') 
            return 'color:#D8BE0E';
        else{ 
            return 'color:#930012';
        }
    }

    handleNav(event){ 
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: 'https://home.treasury.gov/system/files/136/July-2022-PE-Report-User-Guide.pdf'
            }
        }).then(url => {
            window.open(url, "_blank");
        });;
    }


    @api accordionErrors;
    @track showMultipleSections = true;
    @track activeSection = false;

    handleSectionToggle(event) {
        this.showMultipleSections = false;
    }

    connectedCallback(){ 
        if(this.accordionErrors){ 
          this.activeSections = ['Errors']
        }
    }

    renderedCallback(){ 
        if(this.accordionErrors){ 
            this.template.querySelector('.errorsAccordian').classList.remove('slds-hide');
            // this.activeSections = ['Errors'];
        }
    }

    handleErrorClick(event){
        this.dispatchEvent(new CustomEvent('gettabname', { detail: event.currentTarget.dataset.name }));
    }

    closeFAQModal(){ 
        this.showFAQModal = false;
    }

    handleFAQClick(){ 
        this.showFAQModal = true;
    }

    openUnsubmitModal(){
            // configuration for SWAL
            var config = {
                icon: "warning",
                text: "Are you sure you want to unsubmit? You will have to Recertify.",
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
                    this.handleUnsubmit();
                }
            })
            // this.showUnsubmitModal = true;
    }

    closeUnsubmitModal(){
        this.showUnsubmitModal = false;
    }

    handleUnsubmit(){
        this.showUnsubmitModal = false;
        this.isLoading = true;
        updateRecord({ fields: {Id: this.recordId, Status__c: 'Draft'} }).then(() => {
        }).catch(error=>{
            console.log(error);
        }).finally(()=>{ 
            this.isLoading = false;
            window.location.reload();
        })
    }

    get statusSubmitted(){
        return this.status == 'Submitted';
    }

    get isCPF(){
        return this.program == 'CPF';
    }

}