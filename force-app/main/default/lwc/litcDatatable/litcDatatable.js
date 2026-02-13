import { LightningElement, api, wire, track } from 'lwc';
import utilities from 'c/utilities';
import getLineItemsByType from '@salesforce/apex/ApplicationFederalAssistanceController.getLineItemsByType';
import { getFieldValue, getRecord, updateRecord, deleteRecord } from 'lightning/uiRecordApi';
import { refreshApex } from '@salesforce/apex';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import LINE_ITEM from '@salesforce/schema/X13424_J_Line_Item__c';

import getRollupFields from '@salesforce/apex/ApplicationFederalAssistanceController.getRollupFields';

import getSelectedLineItem from '@salesforce/apex/LITCReportingController.getSelectedLineItem';


export default class LitcDatatable extends utilities {

    @track showLineItemModal;
    @track selectedLineItem;
    @track lineItemsByType;
    @track showTable;
    @track columnsLineItems = [];
    @api selectedType;
    @api recordId;
    @api readOnly;

    @track selectedRecordType;

    totalDonatedGoods; 
    totalPersonnelFederal; totalPersonnelMatch; 
    totalFringeFederal; totalFringeMatch; 
    totalSuppliesFederal; totalSuppliesMatch;
    totalIndirect; totalMatchingFunds;
    totalMatchingFundsFormula;

    @track indirectRate;
    @track indirectRateType;
    @track showIEUploadFile = false;
    filePrefix;
    dynamicAcceptedFormat = ['.pdf', '.doc', '.docx', '.docb','.tif'];


    @track attributableValue;
    @track totalUnitsValue;
    @track litcAllocationValue;

    @track enteredDollarFedAmount; enteredDollarMatchAmount;

        @track showPercent;

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

    @wire(getRollupFields, {recordId : '$recordId'})
    setRollupFields(res){ 
        this.rollupsResult = res;
        if (res.data) {
            let data = res.data
            this.totalDonatedGoods = data.Donated_Goods_and_Services_Total__c;
            this.totalPersonnelFederal = data.Personnel_Dollar_Federal_Total__c;
            this.totalPersonnelMatch = data.Personnel_Dollar_Match_Total__c;
            this.totalFringeFederal = data.Fringe_Dollar_Federal_Total__c;
            this.totalFringeMatch = data.Fringe_Dollar_Match_Total__c;
            this.totalSuppliesFederal = data.Supplies_etc_Dollar_Federal_Total__c;
            this.totalSuppliesMatch = data.Supplies_etc_Dollar_Match_Total__c;
            this.totalIndirect = data.Indirect_Expenses_Federal_Total__c;
            this.totalMatchingFunds = data.Matching_Funds_Total__c;
            this.totalMatchingFundsFormula = data.Total_Matching_Funds__c;
        } else if (res.error){ 
            console.log(res.error);
        }
    }

    @wire(getLineItemsByType, { appId: '$recordId', type: '$selectedType' })
    setReportsType(res) {
        this.lineItemsByTypeResult = res;
        if (res.data) {   
            this.setColumnsType(this.selectedType);
            this.lineItemsByType = res.data;      
            this.showTable = res.data.length > 0;
            if (this.selectedType === 'Indirect Expenses' && res.data.Indirect_Cost_Rate_Type__c !='De Minimis' )
            {
                console.log('RS999 into the condition')
                this.showIEUploadFile = true;
                this.filePrefix = 'IndirectExpenseRate' + res.data.Indirect_Cost_Rate_Type__c; 
            }

            if(this.selectedType === 'Indirect Expenses' && res.data.length > 0){ 
                this.disableIndirectExpense = true;
            }

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
            refreshApex(this.rollupsResult);
        })
    }

    openEditLineItemModal(event){ 
        this.selectedLineItem = event.detail.row.Id;
        this.showLineItemModal = true;
    }

    closeEditLineItemModal(){ 
        this.showLineItemModal = false;
        this.selectedLineItem = null;
        this.litcAllocationValue = null;
    }

    async handleSuccess(event){ 
        console.log('in handleSuccess')  
        const fields = event.detail.fields;

        let result = await getSelectedLineItem({recordId: event.detail.id})
        console.log(result);

        if(this.enteredDollarFedAmount && this.enteredDollarMatchAmount && this.showPercent){           
            console.log('in here 1')  

            let percentFed = 0; 
            let percentMatch = 0;

            // if(this.selectedTypeB){ 
            //     console.log('in selectedTypeB');
            //     percentFed = ((this.enteredDollarFedAmount / result.Total_Allocated_Salary__c) * 100).toFixed(5);
            //     percentMatch = ((this.enteredDollarMatchAmount / result.Total_Allocated_Salary__c) * 100).toFixed(5);
            // }
            // if(this.selectedTypeC){
            //     console.log('in selectedTypeC');
            //     percentFed = ((this.enteredDollarFedAmount/ result.Total_Allocated_Cost__c) * 100).toFixed(5);
            //     percentMatch = ((this.enteredDollarMatchAmount / result.Total_Allocated_Cost__c) * 100).toFixed(5);
            // }
            // if(this.selectedTypeD){
            //     console.log('in selectedTypeD');
            //     percentFed = ((this.enteredDollarFedAmount / result.Total_Allocated_Cost__c) * 100).toFixed(5);
            //     percentMatch = ((this.enteredDollarMatchAmount / result.Total_Allocated_Cost__c) * 100).toFixed(5);
            // }

            if (this.selectedTypeB) {
                console.log('in selectedTypeB');
                percentFed = ((this.enteredDollarFedAmount / Number(result.Total_Allocated_Salary__c.toFixed(2))) * 100).toFixed(5);
                percentMatch = ((this.enteredDollarMatchAmount / Number(result.Total_Allocated_Salary__c.toFixed(2))) * 100).toFixed(5);
            }
            if (this.selectedTypeC) {
                console.log('in selectedTypeC');
                percentFed = ((this.enteredDollarFedAmount / Number(result.Total_Allocated_Cost__c.toFixed(2))) * 100).toFixed(5);
                percentMatch = ((this.enteredDollarMatchAmount / Number(result.Total_Allocated_Cost__c.toFixed(2))) * 100).toFixed(5);
            }
            if (this.selectedTypeD) {
                console.log('in selectedTypeD');
                percentFed = ((this.enteredDollarFedAmount / Number(result.Total_Allocated_Cost__c.toFixed(2))) * 100).toFixed(5);
                percentMatch = ((this.enteredDollarMatchAmount / Number(result.Total_Allocated_Cost__c.toFixed(2))) * 100).toFixed(5);
            }
            
            await updateRecord({fields: {Id: event.detail.id, Percent_Federal__c: percentFed, Percent_Match__c: percentMatch}})
        }
        

        if(fields.Attributable_to_LITC__c && fields.Total_Units__c && this.selectedLineItem && this.selectedTypeD){ 
            let temp = (fields.Attributable_to_LITC__c.value / fields.Total_Units__c.value) * 100;
            updateRecord({fields: {Id: this.selectedLineItem, LITC_Allocation_Percent__c: temp}}).then(()=>{ 
                this.showNotification('Saved', 'Saved', 'success');
                this.closeEditLineItemModal();
                refreshApex(this.lineItemsByTypeResult);
                refreshApex(this.rollupsResult);
                this.enteredDollarFedAmount = null;
                this.enteredDollarMatchAmount = null;
        
            }).catch(error=>{
                 console.log(error);
            })
        } else{ 
            this.showNotification('Saved', 'Saved', 'success');
            this.closeEditLineItemModal();
            refreshApex(this.lineItemsByTypeResult);
            refreshApex(this.rollupsResult);
            this.litcAllocationValue = null;
            this.enteredDollarFedAmount = null;
            this.enteredDollarMatchAmount = null;
        }

    }

    @api
    refreshFromParent(){ 
        console.log('in refresh')
        refreshApex(this.lineItemsByTypeResult);
        refreshApex(this.rollupsResult);
    }

    handleAllocationChange(event){ 
       
        if(event.target.fieldName == 'Attributable_to_LITC__c'){ 
            this.attributableValue = event.target.value;
        }

        if(event.target.fieldName == 'Total_Units__c'){ 
            this.totalUnitsValue = event.target.value;
        }

        this.litcAllocationValue = (this.attributableValue / this.totalUnitsValue) * 100;

         console.log(this.litcAllocationValue);
    }

    handleFedChange(event){ 
        this.enteredDollarFedAmount = event.target.value;
    }
    handleMatchChange(event){ 
        this.enteredDollarMatchAmount = event.target.value;
    }


    setColumnsType(type){ 
        let tempColumns = [];

        if(type === 'Donated Goods and Services'){ 
            tempColumns = [
                { label: 'Description', fieldName: 'Description__c', type : 'text', hideDefaultActions: true},
                { label: 'Quantity', fieldName: 'Quantity__c', type : 'text',hideDefaultActions: true,},
                { label: 'Unit of Measure', fieldName: 'U_M__c', type : 'text', hideDefaultActions: true},
                { label: 'Cost per Unit', fieldName: 'Cost_per_Unit__c', type : 'currency', hideDefaultActions: true},
                { label: 'Total', fieldName: 'Total__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Personnel'){ 
            tempColumns = [
                { label: 'Name', fieldName: 'Personnel_Name__c', type : 'text', hideDefaultActions: true},
                { label: 'Position', fieldName: 'Position__c', type : 'text',hideDefaultActions: true, wrapText:true},
                { label: 'LITC FTE', fieldName: 'LITC_FTE__c', type : 'text', hideDefaultActions: true},
                { label: 'Total Allocated Salary', fieldName: 'Total_Allocated_Salary__c', type : 'currency', hideDefaultActions: true},
                { label: '$ Federal', fieldName: 'Dollar_Federal__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                { label: '$ Match', fieldName: 'Dollar_Match__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Fringe'){ 
            tempColumns = [
                { label: 'Total Cost', fieldName: 'Total_Cost__c', type : 'currency', hideDefaultActions: true},
                { label: 'Total Allocated Cost', fieldName: 'Total_Allocated_Cost__c', type : 'currency', hideDefaultActions: true},
                { label: '$ Federal', fieldName: 'Dollar_Federal__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                { label: '$ Match', fieldName: 'Dollar_Match__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Supplies, Contractual, Travel, and Other Expenses'){ 
            tempColumns = [
                { label: 'Category', fieldName: 'Category__c', type : 'text', hideDefaultActions: true},
                { label: 'Total Allocated Cost', fieldName: 'Total_Allocated_Cost__c', type : 'currency', hideDefaultActions: true},
                { label: 'Description', fieldName: 'Description__c', type : 'text', hideDefaultActions: true},
                // { label: 'Percentage', fieldName: 'Percentage__c', type : 'percent', hideDefaultActions: true},
                { label: '$ Federal', fieldName: 'Dollar_Federal__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                { label: '$ Match', fieldName: 'Dollar_Match__c', type : 'currency', hideDefaultActions: true, initialWidth: 150},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Indirect Expenses'){ 
            tempColumns = [
                { label: 'Indirect Cost Rate Type', fieldName: 'Indirect_Cost_Rate_Type__c', type : 'text', hideDefaultActions: true},
                { label: 'Agency who issued ICRA', fieldName: 'Agency_who_issued_ICRA__c', type : 'text', hideDefaultActions: true},
                { label: 'Indirect Cost (Federal)', fieldName: 'Indirect_Cost_Federal__c', type : 'currency', hideDefaultActions: true},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }
        if(type === 'Matching Funds'){ 
            tempColumns = [
                { label: 'Type', fieldName: 'Matching_Funds_Type__c', type : 'text', hideDefaultActions: true},
                { label: 'Amount', fieldName: 'Matching_Funds_Amont__c', type : 'currency', hideDefaultActions: true, initialWidth: 350},
                {label: 'Edit', hideDefaultActions: true, type: "button-icon", initialWidth: 150, typeAttributes: {  
                    iconName: 'utility:edit',
                    variant: 'bare'
                }}
            ];
        }

    
        if(this.readOnly){ 
            let lastColumn = tempColumns[tempColumns.length - 1];
            lastColumn.typeAttributes.class = 'slds-hide';
        }


        this.columnsLineItems = tempColumns;
    }

    handleRateChange(event){ 
        this.indirectRate = event.target.value;
    }

    handleRateTypeChange(event){ 
        this.indirectRateType = event.target.value;
        if (this.indirectRateType == 'De Minimis' )
        {
            this.showIEUploadFile = false;
        } else
        {
            this.showIEUploadFile = true;
            this.filePrefix = 'IndirectExpenseRate' + this.indirectRateType; 
        }
    }

    handleToggle(){ 
        this.showPercent= !this.showPercent;
    }

    get showRateFields(){ 
        return this.indirectRate > 15;
    }


    get selectedTypeA(){
        return this.selectedType === 'Donated Goods and Services'
    }
    get selectedTypeB(){
        return this.selectedType === 'Personnel';
    }
    get selectedTypeC(){
        return this.selectedType === 'Fringe';
    }
    get selectedTypeD(){
        return this.selectedType === 'Supplies, Contractual, Travel, and Other Expenses';
    }
    get selectedTypeE(){
        return this.selectedType === 'Indirect Expenses';
    }
    get selectedTypeF(){
        return this.selectedType === 'Matching Funds';
    }

    get selectedTypeDisplay(){
        return this.selectedType === 'Supplies, Contractual, Travel, and Other Expenses' ? 'Supplies, Contractual, Travel, Equipment and Other Expenses' : this.selectedType;
    }


    get wrapTableHeader(){ 
        return (this.selectedType === 'Personnel' || this.selectedType === 'Supplies, Contractual, Travel, and Other Expenses') ? 'all' : '';
    }

    // handleDataTableSave(event) {
    //     this.saveDraftValues = event.detail.draftValues;
    //     const recordInputs = this.saveDraftValues.slice().map(draft => {
    //         const fields = Object.assign({}, draft);
    //         return { fields };
    //     });
    //     const promises = recordInputs.map(recordInput => updateRecord(recordInput));
    //     Promise.all(promises).then(() => {
    //         this.showNotification('Updating...', 'Your Record has been updated.', 'success');
    //         refreshApex(this.lineItemsResult);
    //     }).catch(error => {
    //         console.log(error);
    //     }).finally(() => {
    //         this.saveDraftValues = [];
    //     });
    // }
}