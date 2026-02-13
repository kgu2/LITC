public with sharing class LineItemSnapshotTriggerHandler {
    public static void handleEvent(){
        if(trigger.isAfter && trigger.isInsert) handleAfterInsert((list<X13424_J_Line_Item_Snapshot__c>)trigger.new);
        if(trigger.isAfter && trigger.isUpdate) handleAfterUpdate((list<X13424_J_Line_Item_Snapshot__c>)trigger.new);
        if(trigger.isAfter && trigger.isDelete) handleAfterDelete((list<X13424_J_Line_Item_Snapshot__c>)trigger.old);
    }
    
    public static void handleAfterUpdate(List<X13424_J_Line_Item_Snapshot__c> lineItems) {
        calculateRollups(lineItems);
    }
    public static void handleAfterInsert(List<X13424_J_Line_Item_Snapshot__c> lineItems) {
        calculateRollups(lineItems);
    }
    public static void handleAfterDelete(List<X13424_J_Line_Item_Snapshot__c> lineItems) {
        calculateRollups(lineItems);
    }

    public static void calculateRollups(List<X13424_J_Line_Item_Snapshot__c> lineItems) {
        Set<Id> appIds = new Set<Id>();
        for (X13424_J_Line_Item_Snapshot__c lineItem : lineItems) {
            if (lineItem.LITC_Reporting_Form__c != null) {
                appIds.add(lineItem.LITC_Reporting_Form__c);
            }
        }

        System.debug(appIds);


        Map<Id, Map<String, Decimal>> parentFieldSums = new Map<Id, Map<String, Decimal>>();
        /*processRollupData(appIds, 'Donated Goods and Services', 'Total_Formula__c', 'Donated_Goods_and_Services_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Personnel', 'Dollar_Federal_Formula__c', 'Personnel_Dollar_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Personnel', 'Dollar_Match_Formula__c', 'Personnel_Dollar_Match_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Fringe', 'Dollar_Federal_Formula__c', 'Fringe_Dollar_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Fringe', 'Dollar_Match_Formula__c', 'Fringe_Dollar_Match_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Indirect Expenses', 'Indirect_Cost_Federal__c', 'Indirect_Expenses_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Matching Funds', 'Matching_Funds_Amont__c', 'Matching_Funds_Total__c', parentFieldSums, null);
   
        // Theses are the filtered ones by category...
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal_Formula__c', 'Travel_Federal_Total__c', parentFieldSums, 'Travel');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match_Formula__c', 'Travel_Match_Total__c', parentFieldSums, 'Travel');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal_Formula__c', 'Equipment_Federal_Total__c', parentFieldSums, 'Equipment');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match_Formula__c', 'Equipment_Match_Total__c', parentFieldSums, 'Equipment');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal_Formula__c', 'Supplies_Federal_Total__c', parentFieldSums, 'Supplies');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match_Formula__c', 'Supplies_Match_Total__c', parentFieldSums, 'Supplies');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal_Formula__c', 'Contractual_Federal_Total__c', parentFieldSums, 'Contractual');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match_Formula__c', 'Contractual_Match_Total__c', parentFieldSums, 'Contractual');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal_Formula__c', 'Other_expenses_Federal_Total__c', parentFieldSums, 'Other');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match_Formula__c', 'Other_Expenses_Match_Total__c', parentFieldSums, 'Other');
        */
        processRollupData(appIds,parentFieldSums);

        System.debug(parentFieldSums);

        // for (Id parentId : parentFieldSums.keySet()) {
        //     Map<String, Decimal> fieldSums = parentFieldSums.get(parentId);

        //     if(fieldSums.containsKey('Other_Expenses_Match_Total__c') && fieldSums.containsKey('Donated_Goods_and_Services_Total__c')){ 
        //         fieldSums.put('Other_Expenses_Match_Total__c', fieldSums.get('Other_Expenses_Match_Total__c') + fieldSums.get('Donated_Goods_and_Services_Total__c')) ;
        //     }
        // }
        for (Id parentId : parentFieldSums.keySet()) {
            Map<String, Decimal> fieldSums = parentFieldSums.get(parentId);
        
            if (fieldSums.containsKey('Other_Expenses_Match_Total__c') || fieldSums.containsKey('Donated_Goods_and_Services_Total__c')) { 
                Decimal otherExpensesMatchTotal = fieldSums.get('Other_Expenses_Match_Total__c') != null ? fieldSums.get('Other_Expenses_Match_Total__c') : 0;
                Decimal donatedGoodsAndServicesTotal = fieldSums.get('Donated_Goods_and_Services_Total__c') != null ? fieldSums.get('Donated_Goods_and_Services_Total__c') : 0;
        
                fieldSums.put('Other_Expenses_Match_Total__c', otherExpensesMatchTotal + donatedGoodsAndServicesTotal);
            }
        }


        //processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal_Formula__c', 'Supplies_etc_Dollar_Federal_Total__c', parentFieldSums, null);
        //processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match_Formula__c', 'Supplies_etc_Dollar_Match_Total__c', parentFieldSums, null);


        List<LITC_Reporting_Form__c> parentsToUpdate = processNullHelper(parentFieldSums);

            
        // Check if there are any remaining records for these Applications
        Map<Id, Boolean> hasRemainingRecords = new Map<Id, Boolean>();
        if (!appIds.isEmpty()) {
            List<AggregateResult> remainingCounts = [
                SELECT LITC_Reporting_Form__c appId, COUNT(Id) recordCount FROM X13424_J_Line_Item_Snapshot__c 
                WHERE LITC_Reporting_Form__c IN :appIds 
                GROUP BY LITC_Reporting_Form__c
            ];
            
            for (AggregateResult result : remainingCounts) {
                Id appId = (Id) result.get('appId');
                hasRemainingRecords.put(appId, ((Integer) result.get('recordCount')) > 0);
            }
        }
    
        // If no remaining records exist, set all rollups to 0
        for (Id appId : appIds) {
            if (!hasRemainingRecords.containsKey(appId) || !hasRemainingRecords.get(appId)) {
                LITC_Reporting_Form__c appUpdate = new LITC_Reporting_Form__c(
                    Id = appId,
                    Donated_Goods_and_Services_Total__c = 0,
                    Personnel_Dollar_Federal_Total__c = 0,
                    Personnel_Dollar_Match_Total__c = 0,
                    Fringe_Dollar_Federal_Total__c = 0,
                    Fringe_Dollar_Match_Total__c = 0,
                    Supplies_etc_Dollar_Federal_Total__c = 0,
                    Supplies_etc_Dollar_Match_Total__c = 0,
                    Indirect_Expenses_Federal_Total__c = 0,
                    Matching_Funds_Total__c = 0,
                    Travel_Federal_Total__c = 0,
                    Travel_Match_Total__c = 0,
                    Equipment_Federal_Total__c = 0,
                    Equipment_Match_Total__c = 0,
                    Supplies_Federal_Total__c = 0,
                    Supplies_Match_Total__c = 0,
                    Contractual_Federal_Total__c = 0,
                    Contractual_Match_Total__c = 0,
                    Other_expenses_Federal_Total__c = 0,
                    Other_Expenses_Match_Total__c = 0
                );
                parentsToUpdate.add(appUpdate);
            }
        }

        if (!parentsToUpdate.isEmpty()) {
            update parentsToUpdate;
        }
    }
    
    public static void processRollupData(Set<Id> appIds, Map<Id, Map<String, Decimal>> parentFieldSums) {

        String query = 'SELECT LITC_Reporting_Form__c, RecordType.Name, Category__c, SUM(Total_Formula__c) Total_Formula__c,SUM(Indirect_Cost_Federal_Formula__c) Indirect_Cost_Federal_Formula__c,SUM(Matching_Funds_Amont__c) Matching_Funds_Amont__c, SUM(Dollar_Federal_Formula__c) Dollar_Federal_Formula__c, SUM(Dollar_Match_Formula__c) Dollar_Match_Formula__c FROM X13424_J_Line_Item_Snapshot__c WHERE LITC_Reporting_Form__c IN :appIds GROUP BY LITC_Reporting_Form__c, RecordType.Name, Category__c';
        

        List<AggregateResult> results = Database.query(query);

        System.debug(results);

        for(AggregateResult result: results){
            Id parentId = (Id) result.get('LITC_Reporting_Form__c');
            String recordTypeName = (String) result.get('Name');
            String category = (String) result.get('Category__c');
            if (!parentFieldSums.containsKey(parentId)) {
                parentFieldSums.put(parentId,new Map<String, Decimal>());
            }
            Map<String,String> catMap;
            if(recordTypeName == 'Supplies, Contractual, Travel, and Other Expenses'){
                //handle category
                catMap = fieldMap.get(category);
                Decimal suppliesETCDFedT = parentFieldSums.get(parentId).containsKey('Supplies_etc_Dollar_Federal_Total__c')?(Decimal)parentFieldSums.get(parentId).get('Supplies_etc_Dollar_Federal_Total__c'):(Decimal)0;
                Decimal suppliesETCDMatchT = parentFieldSums.get(parentId).containsKey('Supplies_etc_Dollar_Match_Total__c')?(Decimal)parentFieldSums.get(parentId).get('Supplies_etc_Dollar_Match_Total__c'):(Decimal)0;
                
                Decimal fedSum = suppliesETCDFedT + (Decimal) (result.get('Dollar_Federal_Formula__c')!=null?result.get('Dollar_Federal_Formula__c'):0);
                Decimal matchSum = suppliesETCDMatchT + (Decimal) (result.get('Dollar_Match_Formula__c')!=null?result.get('Dollar_Match_Formula__c'):0);
                
                parentFieldSums.get(parentId).put('Supplies_etc_Dollar_Federal_Total__c', fedSum);
                parentFieldSums.get(parentId).put('Supplies_etc_Dollar_Match_Total__c', matchSum);
                if(category == null) continue;
            }else{
                catMap = fieldMap.get(recordTypeName);
            }
            for(String keyname : catMap.keySet()){
                Decimal value = (Decimal) result.get(keyname);
                parentFieldSums.get(parentId).put(catMap.get(keyname), value);
            }
        }

    }

    // helper function to set rollups to 0 if null
    private static List<LITC_Reporting_Form__c> processNullHelper(Map<Id, Map<String, Decimal>> parentFieldSums) {
        List<LITC_Reporting_Form__c> parentsToUpdate = new List<LITC_Reporting_Form__c>();
        for (Id parentId : parentFieldSums.keySet()) {
            Map<String, Decimal> fieldSums = parentFieldSums.get(parentId);
            LITC_Reporting_Form__c parent = new LITC_Reporting_Form__c(Id = parentId);
    
            parent.Donated_Goods_and_Services_Total__c = fieldSums.containsKey('Donated_Goods_and_Services_Total__c') ? fieldSums.get('Donated_Goods_and_Services_Total__c') : 0;
            parent.Personnel_Dollar_Federal_Total__c = fieldSums.containsKey('Personnel_Dollar_Federal_Total__c') ? fieldSums.get('Personnel_Dollar_Federal_Total__c') : 0;
            parent.Personnel_Dollar_Match_Total__c = fieldSums.containsKey('Personnel_Dollar_Match_Total__c') ? fieldSums.get('Personnel_Dollar_Match_Total__c') : 0;
            parent.Fringe_Dollar_Federal_Total__c = fieldSums.containsKey('Fringe_Dollar_Federal_Total__c') ? fieldSums.get('Fringe_Dollar_Federal_Total__c') : 0;
            parent.Fringe_Dollar_Match_Total__c = fieldSums.containsKey('Fringe_Dollar_Match_Total__c') ? fieldSums.get('Fringe_Dollar_Match_Total__c') : 0;
            parent.Supplies_etc_Dollar_Federal_Total__c = fieldSums.containsKey('Supplies_etc_Dollar_Federal_Total__c') ? fieldSums.get('Supplies_etc_Dollar_Federal_Total__c') : 0;
            parent.Supplies_etc_Dollar_Match_Total__c = fieldSums.containsKey('Supplies_etc_Dollar_Match_Total__c') ? fieldSums.get('Supplies_etc_Dollar_Match_Total__c') : 0;
            parent.Indirect_Expenses_Federal_Total__c = fieldSums.containsKey('Indirect_Expenses_Federal_Total__c') ? fieldSums.get('Indirect_Expenses_Federal_Total__c') : 0;
            parent.Matching_Funds_Total__c = fieldSums.containsKey('Matching_Funds_Total__c') ? fieldSums.get('Matching_Funds_Total__c') : 0;
            //
            parent.Travel_Federal_Total__c = fieldSums.containsKey('Travel_Federal_Total__c') ? fieldSums.get('Travel_Federal_Total__c') : 0;
            parent.Travel_Match_Total__c = fieldSums.containsKey('Travel_Match_Total__c') ? fieldSums.get('Travel_Match_Total__c') : 0;
            parent.Equipment_Federal_Total__c = fieldSums.containsKey('Equipment_Federal_Total__c') ? fieldSums.get('Equipment_Federal_Total__c') : 0;
            parent.Equipment_Match_Total__c = fieldSums.containsKey('Equipment_Match_Total__c') ? fieldSums.get('Equipment_Match_Total__c') : 0;
            parent.Supplies_Federal_Total__c = fieldSums.containsKey('Supplies_Federal_Total__c') ? fieldSums.get('Supplies_Federal_Total__c') : 0;
            parent.Supplies_Match_Total__c = fieldSums.containsKey('Supplies_Match_Total__c') ? fieldSums.get('Supplies_Match_Total__c') : 0;
            parent.Contractual_Federal_Total__c = fieldSums.containsKey('Contractual_Federal_Total__c') ? fieldSums.get('Contractual_Federal_Total__c') : 0;
            parent.Contractual_Match_Total__c = fieldSums.containsKey('Contractual_Match_Total__c') ? fieldSums.get('Contractual_Match_Total__c') : 0;
            parent.Other_expenses_Federal_Total__c = fieldSums.containsKey('Other_expenses_Federal_Total__c') ? fieldSums.get('Other_expenses_Federal_Total__c') : 0;
            parent.Other_Expenses_Match_Total__c = fieldSums.containsKey('Other_Expenses_Match_Total__c') ? fieldSums.get('Other_Expenses_Match_Total__c') : 0;
    
            parentsToUpdate.add(parent);
        }
        return parentsToUpdate;
    }
    private static final Map<String,Map<String,String>> fieldMap = new Map<String,Map<String,String>>{
        'Donated Goods and Services' => new Map<String,String>{
            'Total_Formula__c'=>'Donated_Goods_and_Services_Total__c'
        },
        'Personnel' => new Map<String,String>{
            'Dollar_Federal_Formula__c'=>'Personnel_Dollar_Federal_Total__c',
            'Dollar_Match_Formula__c'=>'Personnel_Dollar_Match_Total__c'
        },
        'Fringe' => new Map<String,String>{
            'Dollar_Federal_Formula__c'=>'Fringe_Dollar_Federal_Total__c',
            'Dollar_Match_Formula__c'=>'Fringe_Dollar_Match_Total__c'
        },
        'Indirect Expenses' => new Map<String,String>{
            'Indirect_Cost_Federal_Formula__c'=>'Indirect_Expenses_Federal_Total__c'
        },
        'Matching Funds' => new Map<String,String>{
            'Matching_Funds_Amont__c'=>'Matching_Funds_Total__c'
        },
        //Supplies, Contractual, Travel, and Other Expenses
        'Travel'=> new Map<String,String>{
            'Dollar_Federal_Formula__c'=>'Travel_Federal_Total__c',
            'Dollar_Match_Formula__c'=> 'Travel_Match_Total__c'
        },
        'Equipment' => new Map<String,String>{
            'Dollar_Federal_Formula__c'=> 'Equipment_Federal_Total__c',
            'Dollar_Match_Formula__c'=> 'Equipment_Match_Total__c'
        },
        'Supplies' => new Map<String,String>{
            'Dollar_Federal_Formula__c'=> 'Supplies_Federal_Total__c',
            'Dollar_Match_Formula__c'=> 'Supplies_Match_Total__c'
        },
        'Contractual' => new Map<String,String>{
            'Dollar_Federal_Formula__c'=> 'Contractual_Federal_Total__c',
            'Dollar_Match_Formula__c'=> 'Contractual_Match_Total__c'
        },
        'Other' => new Map<String,String>{
            'Dollar_Federal_Formula__c'=> 'Other_expenses_Federal_Total__c',
            'Dollar_Match_Formula__c'=> 'Other_Expenses_Match_Total__c'
        }
    };
}