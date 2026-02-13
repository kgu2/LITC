public with sharing class SF13424JController {
    public Id applicationId { get; set; }
    public Application_for_Federal_Assistance__c application { get; set; }
    public List<Map<String, String>> formattedLineItemsGDS { get; private set; } 
    public List<Map<String, String>> formattedLineItemsF { get; private set; }     
    public List<Map<String, String>> formattedLineItemsSCTOE { get; private set; } 
    public List<Map<String, String>> formattedLineItemsIE { get; private set; } 
    public List<Map<String, String>> formattedLineItemsP { get; private set; } 
    public List<Map<String, String>> formattedLineItemsMF { get; private set; } 

    public String recordTypeDeveloperName { get; set; }

    public String budgetPeriod { get; set; }

    public SF13424JController(ApexPages.StandardController controller) {
        this.application = (Application_for_Federal_Assistance__c)controller.getRecord();
        this.applicationId = controller.getId();
        
        application = [SELECT Id, Name, Funding_Opportunity_Number__c, Legal_Name__c FROM Application_for_Federal_Assistance__c WHERE Id = :applicationId];

        formattedLineItemsGDS = new List<Map<String, String>>();                       
        formattedLineItemsF = new List<Map<String, String>>();
        formattedLineItemsSCTOE = new List<Map<String, String>>();
        formattedLineItemsIE = new List<Map<String, String>>();
        formattedLineItemsP = new List<Map<String, String>>();
        formattedLineItemsMF = new List<Map<String, String>>();
        
        fetchLineItems();


        // budget period start/end dates comes from the FO
        if(application.Funding_Opportunity_Number__c != null){ 
            List<FundingOpportunity> FO = [SELECT ID, Fund_Loading_FY__c FROM FundingOpportunity WHERE Name =: application.Funding_Opportunity_Number__c LIMIT 1];
            if(!FO.isEmpty()){ 
                budgetPeriod = '1/1/' + FO[0].Fund_Loading_FY__c + '-' + '12/31/' + FO[0].Fund_Loading_FY__c;
            }
        }

    }

    public void fetchLineItems() {

        system.debug('RS999 recordTypeDeveloperName :' +recordTypeDeveloperName);
        List<X13424_J_Line_Item__c> lineItems = [SELECT RecordType.DeveloperName,Description__c, Total_Allocated_Salary__c, 
        Quantity__c, U_M__c, Cost_per_Unit__c, Total__c ,Total_Cost__c,Total_Allocated_Cost__c,Dollar_Federal__c,Dollar_Match__c,
        Percentage__c,Indirect_Cost_Federal__c,Indirect_Cost_Rate_Type__c,Agency_who_issued_ICRA__c,Personnel_Name__c,
        Position__c,LITC_FTE__c,Matching_Funds_Amont__c,Matching_Funds_Type__c,Category__c, Notes__c, ICRA_To_Date__c, Modified_Direct_Cost__c, Indirect_Cost_Rate__c
                                                     FROM X13424_J_Line_Item__c 
                                                     WHERE Application_for_Federal_Assistance__c = :applicationId 
                                                     ];

        // Clear the existing list to refresh data dynamically
        //formattedLineItems.clear();

        // Populate formattedLineItems
        for (X13424_J_Line_Item__c item : lineItems) {
            Map<String, String> formattedItem = new Map<String, String>();
            formattedItem.put('RecordTypeName', item.RecordType.DeveloperName);
            formattedItem.put('Description__c', String.isBlank(item.Description__c) ? '' : item.Description__c);
            formattedItem.put('Quantity__c', String.isBlank(formatNumber(item.Quantity__c)) ? '' : formatNumber(item.Quantity__c));
            formattedItem.put('U_M__c', String.isBlank(item.U_M__c) ? '' : item.U_M__c);
            formattedItem.put('Cost_per_Unit__c', String.isBlank(formatNumber(item.Cost_per_Unit__c)) ? '' :  '$' + formatNumber(item.Cost_per_Unit__c));
            formattedItem.put('FormattedTotal', String.isBlank(formatNumber(item.Total__c)) ? '' :'$' + formatNumber(item.Total__c));
            formattedItem.put('Total_Cost__c', String.isBlank(formatNumber(item.Total_Cost__c)) ? '' :'$' + formatNumber(item.Total_Cost__c));
            formattedItem.put('Total_Allocated_Cost__c', String.isBlank(formatNumber(item.Total_Allocated_Cost__c)) ? '' :'$' + formatNumber(item.Total_Allocated_Cost__c));
            formattedItem.put('Total_Allocated_Salary__c', String.isBlank(formatNumber(item.Total_Allocated_Salary__c)) ? '' :'$' + formatNumber(item.Total_Allocated_Salary__c));
            formattedItem.put('Dollar_Federal__c', String.isBlank(formatNumber(item.Dollar_Federal__c)) ? '' :'$' + formatNumber(item.Dollar_Federal__c));
            formattedItem.put('Dollar_Match__c', String.isBlank(formatNumber(item.Dollar_Match__c)) ? '' :'$' + formatNumber(item.Dollar_Match__c));
            formattedItem.put('Percentage__c', String.isBlank(formatNumber(item.Percentage__c)) ? '' : Decimal.valueOf(formatNumber(item.Percentage__c)) * 100 + '%');
            formattedItem.put('Indirect_Cost_Federal__c', String.isBlank(formatNumber(item.Indirect_Cost_Federal__c)) ? '' :'$' + formatNumber(item.Indirect_Cost_Federal__c));
            formattedItem.put('Indirect_Cost_Rate_Type__c', String.isBlank(item.Indirect_Cost_Rate_Type__c) ? '' : item.Indirect_Cost_Rate_Type__c);
            formattedItem.put('Agency_who_issued_ICRA__c', String.isBlank(item.Agency_who_issued_ICRA__c) ? '' : item.Agency_who_issued_ICRA__c);
            formattedItem.put('Personnel_Name__c', String.isBlank(item.Personnel_Name__c) ? '' : item.Personnel_Name__c);
            formattedItem.put('Position__c', String.isBlank(item.Position__c) ? '' : item.Position__c);
            formattedItem.put('LITC_FTE__c', String.isBlank(formatNumber(item.LITC_FTE__c)) ? '' : formatNumber(item.LITC_FTE__c));
            formattedItem.put('Matching_Funds_Amont__c', String.isBlank(formatNumber(item.Matching_Funds_Amont__c)) ? '' :'$' + formatNumber(item.Matching_Funds_Amont__c));
            formattedItem.put('Matching_Funds_Type__c', String.isBlank(item.Matching_Funds_Type__c) ? '' : item.Matching_Funds_Type__c);
            formattedItem.put('Category__c', String.isBlank(item.Category__c) ? '' : item.Category__c);
            formattedItem.put('Notes__c', String.isBlank(item.Notes__c) ? '' : item.Notes__c);
            formattedItem.put('ICRA_To_Date__c', item.ICRA_To_Date__c == null ? '' : item.ICRA_To_Date__c.format());
            formattedItem.put('Modified_Direct_Cost__c', String.isBlank(formatNumber(item.Modified_Direct_Cost__c)) ? '' :'$' + formatNumber(item.Modified_Direct_Cost__c));
            formattedItem.put('Indirect_Cost_Rate__c',  item.Indirect_Cost_Rate__c == null ? '' : item.Indirect_Cost_Rate__c + '%');

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

        system.debug('RS999 formattedLineItemsGDS :' +formattedLineItemsGDS);
        system.debug('RS999 formattedLineItemsMF :' +formattedLineItemsMF);
    }

    // Helper method to format currency fields
    public String formatNumber(Decimal value) {
        if (value == null) return '0.00';
       return value.format();
    }
}