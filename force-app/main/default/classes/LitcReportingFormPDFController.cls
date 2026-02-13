public with sharing class LitcReportingFormPDFController {
    public Id applicationId { get; set; }

    public List<Map<String, String>> formattedLineItemsGDS { get; private set; } 
    public List<Map<String, String>> formattedLineItemsF { get; private set; }     
    public List<Map<String, String>> formattedLineItemsSCTOE { get; private set; } 
    public List<Map<String, String>> formattedLineItemsIE { get; private set; } 
    public List<Map<String, String>> formattedLineItemsP { get; private set; } 
    public List<Map<String, String>> formattedLineItemsMF { get; private set; } 

    public List<LITC_Reporting_Line_Item__c> lineItemAdvocacy { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemEducational { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemEmerging { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemException { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemImpediment { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemOutreach { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemStaffChange { get; private set; } 
    public List<LITC_Reporting_Line_Item__c> lineItemSuccess { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemTASCase { get; private set; } //
    public List<LITC_Reporting_Line_Item__c> lineItemTaxLaw { get; private set; } 
    public List<LITC_Reporting_Line_Item__c> lineItemTrialLocation { get; private set; } //
    


    public LitcReportingFormPDFController(ApexPages.StandardController controller) {

        this.applicationId = controller.getRecord().Id;
        String lRecTypeId =  Schema.SObjectType.LITC_Reporting_Form__c.getRecordTypeInfosByName().get('Form 13424-L').getRecordTypeId();
        String rRecTypeId =  Schema.SObjectType.LITC_Reporting_Form__c.getRecordTypeInfosByName().get('Form 13424-R').getRecordTypeId();

        LITC_Reporting_Form__c myForm = [SELECT Id, Name, RecordTypeId FROM LITC_Reporting_Form__c WHERE Id = :applicationId];

        if(myForm.RecordTypeId == lRecTypeId){ 
            formattedLineItemsGDS = new List<Map<String, String>>();                       
            formattedLineItemsF = new List<Map<String, String>>();
            formattedLineItemsSCTOE = new List<Map<String, String>>();
            formattedLineItemsIE = new List<Map<String, String>>();
            formattedLineItemsP = new List<Map<String, String>>();
            formattedLineItemsMF = new List<Map<String, String>>();
            fetchLineItems();
        }
        if(myForm.RecordTypeId == rRecTypeId){ 
            lineItemAdvocacy = LITCReportingController.getLineItemsByType(myForm.Id, 'Advocacy Activity');
            lineItemEducational = LITCReportingController.getLineItemsByType(myForm.Id, 'Educational Activity');
            lineItemEmerging = LITCReportingController.getLineItemsByType(myForm.Id, 'Emerging Issue');
            lineItemException = LITCReportingController.getLineItemsByType(myForm.Id, 'Exception Explanation');
            lineItemImpediment = LITCReportingController.getLineItemsByType(myForm.Id, 'Impediment');
            lineItemOutreach = LITCReportingController.getLineItemsByType(myForm.Id, 'Outreach Activity');
            lineItemStaffChange = LITCReportingController.getLineItemsByType(myForm.Id, 'Staff Change');
            lineItemSuccess = LITCReportingController.getLineItemsByType(myForm.Id, 'Success');
            lineItemTASCase = LITCReportingController.getLineItemsByType(myForm.Id, 'TAS Case');
            lineItemTaxLaw = LITCReportingController.getLineItemsByType(myForm.Id, 'Tax Law');
            lineItemTrialLocation = LITCReportingController.getLineItemsByType(myForm.Id, 'Trial Location');
        }
    }

    public void fetchLineItems() {

        List<X13424_J_Line_Item_Snapshot__c> lineItems = [
            SELECT RecordType.DeveloperName,Description__c, 
            Total_Allocated_Salary__c, Quantity__c, U_M__c, Cost_per_Unit__c, Total__c ,Total_Cost__c,Total_Allocated_Cost__c,
            Dollar_Federal__c,Dollar_Match__c,Percentage__c,Indirect_Cost_Federal__c,Indirect_Cost_Rate_Type__c,
            Agency_who_issued_ICRA__c,Personnel_Name__c,Position__c,LITC_FTE__c,Matching_Funds_Amont__c,Matching_Funds_Type__c,Category__c, 

            Total_Formula__c, Dollar_Match_Formula__c, Dollar_Federal_Formula__c, Total_Allocated_Salary_Formula__c,
            LITC_FTE_Formula__c, Total_Allocated_Cost_Formula__c, Total_Cost_Formula__c, Percentage_Formula__c,  Indirect_Cost_Federal_Formula__c
            FROM X13424_J_Line_Item_Snapshot__c 
            WHERE LITC_Reporting_Form__c = :applicationId 
        ];

        for (X13424_J_Line_Item_Snapshot__c item : lineItems) {
            Map<String, String> formattedItem = new Map<String, String>();
            formattedItem.put('RecordTypeName', item.RecordType.DeveloperName);
            formattedItem.put('Description__c', String.isBlank(item.Description__c) ? '' : item.Description__c);
            formattedItem.put('Quantity__c', String.isBlank(formatNumber(item.Quantity__c)) ? '' : formatNumber(item.Quantity__c));
            formattedItem.put('U_M__c', String.isBlank(item.U_M__c) ? '' : item.U_M__c);
            formattedItem.put('Cost_per_Unit__c', String.isBlank(formatNumber(item.Cost_per_Unit__c)) ? '' :  '$' + formatNumber(item.Cost_per_Unit__c));

            formattedItem.put('FormattedTotal', String.isBlank(formatNumber(item.Total_Formula__c)) ? '' :'$' + formatNumber(item.Total_Formula__c));
            formattedItem.put('Total_Cost__c', String.isBlank(formatNumber(item.Total_Cost_Formula__c)) ? '' :'$' + formatNumber(item.Total_Cost_Formula__c));
            formattedItem.put('Total_Allocated_Cost__c', String.isBlank(formatNumber(item.Total_Allocated_Cost_Formula__c)) ? '' :'$' + formatNumber(item.Total_Allocated_Cost_Formula__c));
            formattedItem.put('Total_Allocated_Salary__c', String.isBlank(formatNumber(item.Total_Allocated_Salary_Formula__c)) ? '' :'$' + formatNumber(item.Total_Allocated_Salary_Formula__c));
            formattedItem.put('Dollar_Federal__c', String.isBlank(formatNumber(item.Dollar_Federal_Formula__c)) ? '' :'$' + formatNumber(item.Dollar_Federal_Formula__c));
            formattedItem.put('Dollar_Match__c', String.isBlank(formatNumber(item.Dollar_Match_Formula__c)) ? '' :'$' + formatNumber(item.Dollar_Match_Formula__c));
            formattedItem.put('Percentage__c', String.isBlank(formatNumber(item.Percentage_Formula__c)) ? '' : Decimal.valueOf(formatNumber(item.Percentage_Formula__c)) * 100 + '%');
            formattedItem.put('Indirect_Cost_Federal__c', String.isBlank(formatNumber(item.Indirect_Cost_Federal_Formula__c)) ? '' :'$' + formatNumber(item.Indirect_Cost_Federal_Formula__c));
            formattedItem.put('Indirect_Cost_Rate_Type__c', String.isBlank(item.Indirect_Cost_Rate_Type__c) ? '' : item.Indirect_Cost_Rate_Type__c);
            formattedItem.put('Agency_who_issued_ICRA__c', String.isBlank(item.Agency_who_issued_ICRA__c) ? '' : item.Agency_who_issued_ICRA__c);
            formattedItem.put('Personnel_Name__c', String.isBlank(item.Personnel_Name__c) ? '' : item.Personnel_Name__c);
            formattedItem.put('Position__c', String.isBlank(item.Position__c) ? '' : item.Position__c);
            formattedItem.put('LITC_FTE__c', String.isBlank(formatNumber(item.LITC_FTE_Formula__c)) ? '' : formatNumber(item.LITC_FTE_Formula__c));
            formattedItem.put('Matching_Funds_Amont__c', String.isBlank(formatNumber(item.Matching_Funds_Amont__c)) ? '' :'$' + formatNumber(item.Matching_Funds_Amont__c));
            formattedItem.put('Matching_Funds_Type__c', String.isBlank(item.Matching_Funds_Type__c) ? '' : item.Matching_Funds_Type__c);
            formattedItem.put('Category__c', String.isBlank(item.Category__c) ? '' : item.Category__c);

            if (item.RecordType.DeveloperName == 'Donated_Goods_and_Services'){
                formattedLineItemsGDS.add(formattedItem);
            }
            
            if (item.RecordType.DeveloperName == 'Fringe'){
                formattedLineItemsF.add(formattedItem);
            }
            
            if (item.RecordType.DeveloperName == 'Supplies_Contractual_Travel_and_Other_Expenses'){
                formattedLineItemsSCTOE.add(formattedItem);
            }

            if (item.RecordType.DeveloperName == 'Indirect_Expenses'){
                formattedLineItemsIE.add(formattedItem);
            }

            if (item.RecordType.DeveloperName == 'Personnel'){
                formattedLineItemsP.add(formattedItem);
            }

            if (item.RecordType.DeveloperName == 'Matching_Funds'){
                formattedLineItemsMF.add(formattedItem);
            }
        }
    }

    // Helper method to format currency fields
    public String formatNumber(Decimal value) {
        if (value == null) return '0.00';
       return value.format();
    }

}