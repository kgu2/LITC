import { LightningElement, api, wire, track } from 'lwc';
import utilities from 'c/utilities';
import getLineItemsByType from '@salesforce/apex/LITCReportingController.getLineItemsByType';
import { getFieldValue, getRecord, updateRecord, deleteRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LINE_ITEM from '@salesforce/schema/LITC_Reporting_Line_Item__c';

export default class LitcReportingDatatable extends utilities {

    @track showLineItemModal;
    @track selectedLineItem;
    @track lineItemsByType;
    @track showTable;
    @track columnsLineItems = [];

    @api selectedType;
    @api recordId;
    @api disableEdits;

    @track selectedRecordType;

    @wire(getObjectInfo, { objectApiName : LINE_ITEM })
    getInfo({error, data}) {
        if (data) {
            let recordTypes = data.recordTypeInfos;
     
            for ( let [key, value] of Object.entries(recordTypes)) 
                if (value.name.includes(this.selectedType)) 
                    this.selectedRecordType = value.recordTypeId;
        }
        else if (error) {
            console.log(error);
        }
    }

    @wire(getLineItemsByType, { reportId: '$recordId', type: '$selectedType' })
    setReportsType(res) {
        this.lineItemsByTypeResult = res;
        if (res.data) {   
            this.setColumnsType(this.selectedType);
            this.lineItemsByType = res.data;      
            this.showTable = res.data.length > 0;
        }
        else if (res.error) {
            console.log(res.error);
        }
    }

    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }


    openAddLineItemModal(){ 
        this.showLineItemModal = true;
    }

    handleDelete(){ 
        deleteRecord(this.selectedLineItem).then(()=>{ 
            this.showNotification('Saved', 'Saved', 'success');
            this.closeEditLineItemModal();
            refreshApex(this.lineItemsByTypeResult);
            getRecordNotifyChange([{recordId: this.recordId}]);
        })
    }

    openEditLineItemModal(event){ 
        this.selectedLineItem = event.detail.row.Id;
        this.showLineItemModal = true;
    }

    closeEditLineItemModal(){ 
        this.showLineItemModal = false;
        this.selectedLineItem = null;
    }

    handleSuccess(event){ 
        this.showNotification('Saved', 'Saved', 'success');
        this.closeEditLineItemModal();
        refreshApex(this.lineItemsByTypeResult);
    }

    setColumnsType(type){ 
        let tempColumns = [];

        if(type === 'Exception Explanation'){ 
            tempColumns = [
                { label: 'Explanation', fieldName: 'Exception_explanation__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'TAS Case'){ 
            tempColumns = [
                { label: 'Issue', fieldName: 'Case_Issue__c', type : 'text', hideDefaultActions: true},
                { label: 'Result', fieldName: 'Case_Result__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Trial Location'){ 
            tempColumns = [
                { label: 'City', fieldName: 'Trial_Location_City__c', type : 'text', hideDefaultActions: true},
                { label: 'State', fieldName: 'Trial_Location_State__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Outreach Activity'){ 
            tempColumns = [
                { label: 'Date', fieldName: 'Activity_Date__c', type : 'text', hideDefaultActions: true},
                { label: 'Venue', fieldName: 'Venue_Organization__c', type : 'text', hideDefaultActions: true},
                { label: 'Type', fieldName: 'Activity_Type__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
         if(type === 'Educational Activity'){ 
            tempColumns = [
                { label: 'Date', fieldName: 'Activity_Date__c', type : 'text', hideDefaultActions: true},
                { label: 'Presenter', fieldName: 'Presenter__c', type : 'text', hideDefaultActions: true},
                { label: 'Venue', fieldName: 'Venue_Organization__c', type : 'text', hideDefaultActions: true},
                { label: 'Attendees', fieldName: 'Attendees__c', type : 'text', hideDefaultActions: true},
                { label: 'Primary Audience', fieldName: 'Primary_Audience__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Advocacy Activity'){ 
            tempColumns = [
                { label: 'Type', fieldName: 'Activity_Type__c', type : 'text', hideDefaultActions: true},
                { label: 'Clinician', fieldName: 'Clinician_Staff_Member__c', type : 'text', hideDefaultActions: true},
                { label: 'Description', fieldName: 'Description__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Impediment'){ 
            tempColumns = [
                { label: 'Impediment', fieldName: 'Impediment__c', type : 'text', hideDefaultActions: true},
                { label: 'Efforts Made to Overcome', fieldName: 'Efforts_Made_to_Overcome__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Emerging Issue'){ 
            tempColumns = [
                { label: 'Issue', fieldName: 'Issue__c', type : 'text', hideDefaultActions: true},
                { label: 'Description', fieldName: 'Description__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Success'){ 
            tempColumns = [
                { label: 'Case/Activity', fieldName: 'Case_Activity__c', type : 'text', hideDefaultActions: true},
                { label: 'Description', fieldName: 'Description__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Staff Change'){ 
            tempColumns = [
                { label: 'Staff Member', fieldName: 'Staff_Member__c', type : 'text', hideDefaultActions: true},
                { label: 'Details', fieldName: 'Details__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Tax Law'){ 
            tempColumns = [
                { label: 'Trainee', fieldName: 'Trainee__c', type : 'text', hideDefaultActions: true},
                { label: 'Topic', fieldName: 'Topic__c', type : 'text', hideDefaultActions: true},
                { label: 'Training Hours', fieldName: 'Training_Hours__c', type : 'text', hideDefaultActions: true},
                { label: 'Provider', fieldName: 'Provider__c', type : 'text', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }

        this.columnsLineItems = tempColumns;
    }

    get selectedTypeA(){ 
        return this.selectedType === 'Exception Explanation';
    }

    get selectedTypeB(){ 
        return this.selectedType === 'TAS Case';
    }

    get selectedTypeC(){ 
        return this.selectedType === 'Trial Location';
    }

    get selectedTypeD(){ 
        return this.selectedType === 'Outreach Activity';
    }

    get selectedTypeE(){ 
        return this.selectedType === 'Educational Activity';
    }

    get selectedTypeF(){ 
        return this.selectedType === 'Advocacy Activity';
    }
    get selectedTypeG(){ 
        return this.selectedType === 'Impediment';
    }
    get selectedTypeH(){ 
        return this.selectedType === 'Emerging Issue';
    }
    get selectedTypeI(){ 
        return this.selectedType === 'Success';
    }
    get selectedTypeJ(){ 
        return this.selectedType === 'Staff Change';
    }
    get selectedTypeK(){ 
        return this.selectedType === 'Tax Law';
    }
  
}