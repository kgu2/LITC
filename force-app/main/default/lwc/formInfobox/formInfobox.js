import { LightningElement, api,track} from 'lwc';
import { updateRecord } from 'lightning/uiRecordApi'
import { NavigationMixin } from 'lightning/navigation';
import SWEETALERT from "@salesforce/resourceUrl/sweetAlertJS";
import { loadScript } from 'lightning/platformResourceLoader';

export default class FormInfobox extends NavigationMixin(LightningElement) {

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
    @api statusFieldName;

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

    @track showUnsubmitModal;
    

    get formStyle(){
        if(this.status == 'Submitted'){ 
            return 'color:#2E8540';
        } else if (this.status == 'Awaiting Signature') 
            return 'color:#00599C';
        else{ 
            return 'color:#930012';
        }
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
        }
    }

    handleErrorClick(event){
        this.dispatchEvent(new CustomEvent('gettabname', { detail: event.currentTarget.dataset.name }));
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
    }

    closeUnsubmitModal(){
        this.showUnsubmitModal = false;
    }

    handleUnsubmit(){
        this.showUnsubmitModal = false;
        this.isLoading = true;
        updateRecord({ fields: {Id: this.recordId, [this.statusFieldName]: 'In Progress'} }).then(() => {
        }).catch(error=>{
            console.log(error);
        }).finally(()=>{ 
            this.isLoading = false;
            window.location.reload();
        })
    }

    get statusSubmitted(){
        return this.status == 'Submitted' || this.status == 'Awaiting Signature';
    }


}