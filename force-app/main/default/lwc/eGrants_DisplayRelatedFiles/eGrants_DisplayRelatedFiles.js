import { LightningElement, track, api, wire} from 'lwc';
import getRelatedFiles from '@salesforce/apex/NHTSAUtilities.relatedFiles';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { deleteRecord } from 'lightning/uiRecordApi'; 
import { reduceErrors } from 'c/ldsUtils';
const actions = [
    { label: 'Delete', name: 'delete' },
];

export default class EGrants_DisplayRelatedFiles extends LightningElement {
    @api recordId;
    //testRecId = 'a0M3S00000BRZgD';
    @api filePrefix = '';
    @api mode = 'readonly';
    @track data;
    @track error;
    @track totRecords = 0;
    @track allRecords; //list of contenter versions
    @track wireDataLength = 0;
    getFiles = true;
  
    showTable = false; //Used to render table after we get the data from apex controller    
    recordsToDisplay = []; //Records to be displayed on the page
    rowNumberOffset; //Row number
    preSelected = [];
    selectedRows;
    showActionButton;

    
    //update with record columns
    
    @api recColumns =  [
        {
          label: "File Name",
          fieldName: "Title",
          type: "text",
          sortable: true,
        },
        
        { label: 'Created Date', 
            fieldName: 'CreatedDate', 
            type: 'date', 
            sortable:true,
            typeAttributes:{timeZone:'UTC', year:'numeric', month:'numeric', day:'numeric'}},
        {
        
            type: 'action',
            typeAttributes: { rowActions: actions },
        }
        
      ];

      @api recColumnsRO =  [
        {
          label: "File Name",
          fieldName: "Title",
          type: "text",
          sortable: true,
        },
        
        { label: 'Date Uploaded', 
            fieldName: 'CreatedDate', 
            type: 'date', 
            sortable:true,
            typeAttributes:{timeZone:'UTC', year:'numeric', month:'numeric', day:'numeric'}},
        {
            label: "Description of Updates / Changes",
            fieldName: "Description",
            type: "textarea",
            sortable: true,
        },

        {
            label: "Type",
            fieldName: "FileType",
            type: "text",
            sortable: true,
        },
        
      ];

      get columnsToDisplay (){
        console.log('this.mode = ' + this.mode);
        if(this.mode == 'readonly'){
            return this.recColumnsRO;
        }else{
            return this.recColumns;
        }
      }

    renderedCallback(){
        console.log('fileprfix rcb = ' + this.filePrefix);
        console.log('depslay rendared rfiles = ' + this.recordId + ' mode = '+ this.mode);
        // if(this.getFiles){
           
        // }
    }

    connectedCallback(){
       // console.log('connected callback displapy  callback id = ' +this.recordId);
       console.log('fileprfix ccb = ' + this.filePrefix);
    }
    
    wiredFileResults;
    @wire(getRelatedFiles,{ idParent: '$recordId', prefix: '$filePrefix'})
    files(result)  {
        //console.log('wire results ', result);
        this.wiredFileResults = result;
        if ( result.data ) {
            this.data = result.data;
            this.error = undefined; 
            this.wireDataLength = this.data.length;
            console.log('wired data length = ' + this.wireDataLength);
            console.log('data ' , this.data);
            
        } else if ( result.error ) {
            console.log('found an error' + result.error);
            //this.dispatchEvent(showNotification('Error!!', result.error, 'error'));
            this.error = result.error; 
            this.data = undefined;
        }
        else {
            this.data = undefined;
            this.error = undefined;
        }
        
    }

    //Capture the event fired from the paginator component
    handlePaginatorChange(event){
        this.recordsToDisplay = event.detail.recordsToDisplay;
        this.preSelected = event.detail.preSelected;
        if(this.recordsToDisplay && this.recordsToDisplay > 0){
            this.rowNumberOffset = this.recordsToDisplay[0].rowNumber-1;
        }else{
            this.rowNumberOffset = 0;
        } 
    }    

    handleAllSelectedRows(event) {
        this.selectedRows = [];
        const selectedItems = event.detail;          
        let items = [];
        selectedItems.forEach((item) => {
            this.showActionButton = true;
            console.log(item);
            items.push(item);
        });
        this.selectedRows = items;  
        //console.log('disply selected Rows = ' ,this.selectedRows);        
    } 


   // <<<row:>>>{"Id":"0683S000002oymQQAQ","Title":"budgeting","ContentDocumentId":"0693S000002pF4TQAU","CreatedDate":"2024-09-10T13:14:41.000Z"}
     handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;
        const id = event.detail.row.ContentDocumentId;
        //console.log('<<<row:>>>'+JSON.stringify(row));

        switch (actionName) {
            case 'delete':
                this.deleteFile(id);
                break;
            default:
        }
    }   

    async deleteFile(recId) {
        //const recordId = event.target.dataset.recordid;
        try {
            await deleteRecord(recId);
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Success',
            //         message: 'Account deleted',
            //         variant: 'success'
            //     })
            // );
            await refreshApex(this.wiredFileResults);
        } catch (error) {
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Error deleting record',
                    message: reduceErrors(error).join(', '),
                    variant: 'error'
                })
            );
        }
    } 
}