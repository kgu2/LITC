public with sharing class ApplicationSnapshotController {

    public static void createSnapshots(List<Id> appIds){
        String appQuery = 'SELECT Id, ';
        appQuery += String.join(applicationFields, ', ');
        appQuery += ', (SELECT Id, ';
        appQuery += String.join(legacyAppFields.keySet(),', ');
        appQuery += ' FROM Legacy_13424_Applications__r)';
        appQuery += ' FROM Application_for_Federal_Assistance__c ';
        appQuery += ' WHERE Id IN :appIds';
        List<Application_for_Federal_Assistance__c> apps = Database.query(appQuery);
        Map<Id,Application_Federal_Assistance_Snapshot__c> snapshots = new Map<Id,Application_Federal_Assistance_Snapshot__c>();
        for(Application_for_Federal_Assistance__c app : apps){
            snapshots.put(app.Id, createAppSnapshotFromApp(app));
        }
        insert snapshots.values();

        //Line Item Snapshots
        String lineItemQuery = 'SELECT Id, RecordType.Name, Application_for_Federal_Assistance__c, ';
        lineItemQuery += String.join(lineItemFields, ', ');
        lineItemQuery += ' FROM X13424_J_Line_Item__c ';
        lineItemQuery += ' WHERE Application_for_Federal_Assistance__c IN :appIds';
        List<X13424_J_Line_Item__c> lineItems = Database.query(lineItemQuery);
        List<X13424_J_Line_Item_Snapshot__c> lineItemSnapshots = new List<X13424_J_Line_Item_Snapshot__c>();
        for(X13424_J_Line_Item__c lineItem : lineItems){
            X13424_J_Line_Item_Snapshot__c snapshot= createLineItemSnapshotFromLineItem(lineItem);
            snapshot.Application_Federal_Assistance_Snapshot__c = snapshots.get(lineItem.Application_for_Federal_Assistance__c).Id;
            lineItemSnapshots.add(snapshot);
        }
        insert lineItemSnapshots;
    }
    private static Application_Federal_Assistance_Snapshot__c createAppSnapshotFromApp(Application_for_Federal_Assistance__c application){
        Application_Federal_Assistance_Snapshot__c snapshot = new Application_Federal_Assistance_Snapshot__c();
        snapshot.Application_for_Federal_Assistance__c = application.Id;
        for(String field: applicationFields){
            snapshot.put(field, application.get(field));
        }
        snapshot.Name = snapshot.Name + ' - ' + Date.today().format();
        if(application.Legacy_13424_Applications__r.size() > 0){
            Legacy_13424_Application__c legacyApp = application.Legacy_13424_Applications__r[0];
            for(String field: legacyAppFields.keySet()){
                snapshot.put(legacyAppFields.get(field), legacyApp.get(field));
            }
        }
        System.debug(snapshot);
        return snapshot;
    }
    public static X13424_J_Line_Item_Snapshot__c createLineItemSnapshotFromLineItem(X13424_J_Line_Item__c lineItem){
        X13424_J_Line_Item_Snapshot__c snapshot = new X13424_J_Line_Item_Snapshot__c();
        snapshot.X13424_J_Line_Item__c = lineItem.Id;
        snapshot.RecordTypeId = lineItemSnapshotRecordTypes.get(lineItem.RecordType.Name).getRecordTypeId();
        for(String field: lineItemFields){
            snapshot.put(field, lineItem.get(field));
        }
        snapshot.Name = snapshot.Name + ' - ' + Date.today().format();
        return snapshot;
        //add the application snapshot after this returns
    }
    // add any new line item snapshot fields to this list
    private static final List<String> lineItemFields = new List<String>{
        'Attributable_to_LITC__c',
        'Agency_who_issued_ICRA__c',
        'Category__c',
        'Cost_Base__c',
        'Cost_per_Unit__c',
        'Description__c',
        'Dollar_Federal__c',
        'Dollar_Match__c',
        'Expense_Category__c',
        'Extension_Requested__c',
        'Federal_Expense__c',
        'Fringe_Allocation_Percent__c',
        'Full_Time_Equivalent_Hours__c',
        'ICRA_From_Date__c',
        'ICRA_To_Date__c',
        'Indirect_Cost_Federal__c',
        'Indirect_Cost_Rate__c',
        'Indirect_Cost_Rate_Type__c',
        'LITC_Allocation_Percent__c',
        // 'LITC_Allocation_Percent_v2__c',
        'LITC_FTE__c',
        'LITC_Hours__c',
        'Match_Expense__c',
        'Matching_Funds_Amont__c',
        'Matching_Funds_Type__c',
        'Modified_Direct_Cost__c',
        'Name',
        'Notes__c',
        'Pay_Rate__c',
        'Pay_Type__c',
        'Percent_Federal__c',
        'Percent_Match__c',
        'Percentage__c',
        'Personnel_Name__c',
        'Position__c',
        'Primary_Role__c',
        'Quantity__c',
        'Total__c',
        'Total_Allocated_Cost__c',
        'Total_Allocated_Salary__c',
        'Total_Cost__c',
        'Total_Cost_Supplies_Contr_Other__c',
        'Total_Hours__c',
        'Total_Units__c',
        'U_M__c'
    };
    private static Map<String,Schema.RecordTypeInfo> lineItemSnapshotRecordTypes = Schema.SObjectType.X13424_J_Line_Item_Snapshot__c.getRecordTypeInfosByName();
    private static final List<String> applicationFields = new List<String>{ 
        'Consultations_with_Low_Income_ESL__c',
        'Donated_Goods_and_Services_Total__c',
        'Educational_Activates_to_Low_Income__c',
        'Fringe_Dollar_Federal_Total__c',
        'Fringe_Dollar_Match_Total__c',
        'Full_Time_Equivalent_Hours__c',
        'Indirect_Expenses_Federal_Total__c',
        'Low_Income_ESL_TP_Service_Providers__c',
        'Matching_Funds_Total__c',
        'Name',
        'New_Representation_Cases__c',
        'Personnel_Dollar_Federal_Total__c',
        'Supplies_etc_Dollar_Federal_Total__c',
        'Supplies_etc_Dollar_Match_Total__c',
        'Total_Matching_Funds__c',
        'Personnel_Dollar_Match_Total__c',
        'Other_Expenses_Match_Total__c',
        'Other_Expenses_Federal_Total__c'
    };
    private static final Map<String,String> legacyAppFields = new Map<String,String>{
        'Consulta_W_Low_Income_ESL_First_Year__c' => 'Consultations_with_Low_Income_ESL__c',
        'Educa_Activ_to_Low_Income_First_Year__c' => 'Educational_Activates_to_Low_Income__c',
        'Low_Income_ESL_to_be_reached_First_Year__c' => 'Low_Income_ESL_TP_Service_Providers__c',
        'New_representation_cases_First_Year__c'=> 'New_Representation_Cases__c'
    };
}