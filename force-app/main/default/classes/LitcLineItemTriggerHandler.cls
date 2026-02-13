public with sharing class LitcLineItemTriggerHandler {
    public static void handleEvent(){
        if(trigger.isAfter && trigger.isInsert) handleAfterInsert((list<X13424_J_Line_Item__c>)trigger.new);
        if(trigger.isAfter && trigger.isUpdate) handleAfterUpdate((list<X13424_J_Line_Item__c>)trigger.new);
        if(trigger.isAfter && trigger.isDelete) handleAfterDelete((list<X13424_J_Line_Item__c>)trigger.old);

        // if(trigger.isBefore && trigger.isInsert) handleBeforeInsert((list<X13424_J_Line_Item__c>)trigger.new, (Map<Id, X13424_J_Line_Item__c>)trigger.oldMap);
        // if(trigger.isBefore && trigger.isUpdate) handleBeforeUpdate((list<X13424_J_Line_Item__c>)trigger.new, (Map<Id, X13424_J_Line_Item__c>)trigger.oldMap);
    }
    
    public static void handleAfterUpdate(List<X13424_J_Line_Item__c> lineItems) {
        calculateRollups(lineItems);
    }
    public static void handleAfterInsert(List<X13424_J_Line_Item__c> lineItems) {
        calculateRollups(lineItems);
    }
    public static void handleAfterDelete(List<X13424_J_Line_Item__c> lineItems) {
        calculateRollups(lineItems);
        deleteAttachments(lineItems);
    }

    // public static void handleBeforeInsert(List<X13424_J_Line_Item__c> lineItems, Map<Id, X13424_J_Line_Item__c> oldMap){ 
    //     for (X13424_J_Line_Item__c rec : lineItems) {
    //         if (rec.Entered_Dollar_Federal__c != null && rec.Total_Allocated_Salary__c != null && rec.Total_Allocated_Salary__c != 0) {
    //             rec.Percent_Federal__c = rec.Entered_Dollar_Federal__c / rec.Total_Allocated_Salary__c;
    //         }
    //     }
    // }
    // public static void handleBeforeUpdate(List<X13424_J_Line_Item__c> lineItems, Map<Id, X13424_J_Line_Item__c> oldMap){ 
    //     for (X13424_J_Line_Item__c rec : lineItems) {
    //         if (rec.Entered_Dollar_Federal__c != null && rec.Total_Allocated_Salary__c != null && rec.Total_Allocated_Salary__c != 0) {
    //             rec.Percent_Federal__c = rec.Entered_Dollar_Federal__c / rec.Total_Allocated_Salary__c;
    //         }
    //     }
    // }

    public static void calculateRollups(List<X13424_J_Line_Item__c> lineItems) {
        Set<Id> appIds = new Set<Id>();
        for (X13424_J_Line_Item__c lineItem : lineItems) {
            if (lineItem.Application_for_Federal_Assistance__c != null) {
                appIds.add(lineItem.Application_for_Federal_Assistance__c);
            }
        }


        Map<Id, Map<String, Decimal>> parentFieldSums = new Map<Id, Map<String, Decimal>>();
        processRollupData(appIds, 'Donated Goods and Services', 'Total__c', 'Donated_Goods_and_Services_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Personnel', 'Dollar_Federal__c', 'Personnel_Dollar_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Personnel', 'Dollar_Match__c', 'Personnel_Dollar_Match_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Fringe', 'Dollar_Federal__c', 'Fringe_Dollar_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Fringe', 'Dollar_Match__c', 'Fringe_Dollar_Match_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Indirect Expenses', 'Indirect_Cost_Federal__c', 'Indirect_Expenses_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Matching Funds', 'Matching_Funds_Amont__c', 'Matching_Funds_Total__c', parentFieldSums, null);
   
        // Theses are the filtered ones by category...
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal__c', 'Travel_Federal_Total__c', parentFieldSums, 'Travel');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match__c', 'Travel_Match_Total__c', parentFieldSums, 'Travel');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal__c', 'Equipment_Federal_Total__c', parentFieldSums, 'Equipment');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match__c', 'Equipment_Match_Total__c', parentFieldSums, 'Equipment');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal__c', 'Supplies_Federal_Total__c', parentFieldSums, 'Supplies');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match__c', 'Supplies_Match_Total__c', parentFieldSums, 'Supplies');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal__c', 'Contractual_Federal_Total__c', parentFieldSums, 'Contractual');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match__c', 'Contractual_Match_Total__c', parentFieldSums, 'Contractual');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal__c', 'Other_expenses_Federal_Total__c', parentFieldSums, 'Other');
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match__c', 'Other_Expenses_Match_Total__c', parentFieldSums, 'Other');
        

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


        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Federal__c', 'Supplies_etc_Dollar_Federal_Total__c', parentFieldSums, null);
        processRollupData(appIds, 'Supplies, Contractual, Travel, and Other Expenses', 'Dollar_Match__c', 'Supplies_etc_Dollar_Match_Total__c', parentFieldSums, null);


        List<Application_for_Federal_Assistance__c> parentsToUpdate = processNullHelper(parentFieldSums);

            
        // Check if there are any remaining records for these Applications
        Map<Id, Boolean> hasRemainingRecords = new Map<Id, Boolean>();
        if (!appIds.isEmpty()) {
            List<AggregateResult> remainingCounts = [
                SELECT Application_for_Federal_Assistance__c appId, COUNT(Id) recordCount FROM X13424_J_Line_Item__c 
                WHERE Application_for_Federal_Assistance__c IN :appIds 
                GROUP BY Application_for_Federal_Assistance__c
            ];
            
            for (AggregateResult result : remainingCounts) {
                Id appId = (Id) result.get('appId');
                hasRemainingRecords.put(appId, ((Integer) result.get('recordCount')) > 0);
            }
        }
    
        // If no remaining records exist, set all rollups to 0
        for (Id appId : appIds) {
            if (!hasRemainingRecords.containsKey(appId) || !hasRemainingRecords.get(appId)) {
                Application_for_Federal_Assistance__c appUpdate = new Application_for_Federal_Assistance__c(
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
    
    private static void processRollupData(Set<Id> appIds, String recordTypeName, String sourceField, String rollupField, Map<Id, Map<String, Decimal>> parentFieldSums, String category) {
        String query = '';
        if(category != null){ 
            query = 'SELECT Application_for_Federal_Assistance__c, SUM(' + sourceField + ') value ' +
            'FROM X13424_J_Line_Item__c ' +
            'WHERE Application_for_Federal_Assistance__c IN :appIds AND RecordType.Name = :recordTypeName AND Category__c = :category ' +
            'GROUP BY Application_for_Federal_Assistance__c';
        } else{ 
            query = 'SELECT Application_for_Federal_Assistance__c, SUM(' + sourceField + ') value ' +
            'FROM X13424_J_Line_Item__c ' +
            'WHERE Application_for_Federal_Assistance__c IN :appIds AND RecordType.Name = :recordTypeName ' +
            'GROUP BY Application_for_Federal_Assistance__c';
        }

    
        List<AggregateResult> results = Database.query(query);
    
        for (AggregateResult result : results) {
            Id parentId = (Id) result.get('Application_for_Federal_Assistance__c');
            Decimal value = (Decimal) result.get('value');
            if (!parentFieldSums.containsKey(parentId)) {
                parentFieldSums.put(parentId, new Map<String, Decimal>());
            }
            parentFieldSums.get(parentId).put(rollupField, value);
        }
    }

    // helper function to set rollups to 0 if null
    private static List<Application_for_Federal_Assistance__c> processNullHelper(Map<Id, Map<String, Decimal>> parentFieldSums) {
        List<Application_for_Federal_Assistance__c> parentsToUpdate = new List<Application_for_Federal_Assistance__c>();
        for (Id parentId : parentFieldSums.keySet()) {
            Map<String, Decimal> fieldSums = parentFieldSums.get(parentId);
            Application_for_Federal_Assistance__c parent = new Application_for_Federal_Assistance__c(Id = parentId);
    
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

    public static void deleteAttachments(List<X13424_J_Line_Item__c> lineItems) {
        if (lineItems == null || lineItems.isEmpty()) {
            return; // No records to process
        }

        // Collect the IDs of Application_for_Federal_Assistance__c fields from the provided list
        Set<Id> applicationIds = new Set<Id>();
        for (X13424_J_Line_Item__c lineItem : lineItems) {
            if (lineItem.Application_for_Federal_Assistance__c != null) {
                applicationIds.add(lineItem.Application_for_Federal_Assistance__c);
            }
        }

        if (applicationIds.isEmpty()) {
            return; // No related applications to process
        }

        // Step 1: Query ContentDocumentLink records to get associated ContentDocumentIds
        List<ContentDocumentLink> documentLinks = [
            SELECT ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId IN :applicationIds
        ];

        if (documentLinks.isEmpty()) {
            return; // No ContentDocumentLinks found
        }

        Set<Id> contentDocumentIds = new Set<Id>();
        for (ContentDocumentLink link : documentLinks) {
            contentDocumentIds.add(link.ContentDocumentId);
        }

        // Step 2: Query ContentDocument records where ContentVersions match the criteria
        List<ContentDocument> contentDocumentsToDelete = [
            SELECT Id
            FROM ContentDocument
            WHERE Id IN :contentDocumentIds
            AND Id IN (
                SELECT ContentDocumentId
                FROM ContentVersion
                WHERE File_Prefix__c LIKE '%IndirectExpenseRate%'
            )
        ];

        if (!contentDocumentsToDelete.isEmpty()) {
            // Step 3: Delete the ContentDocuments
            try {
                delete contentDocumentsToDelete;
            } catch (DmlException e) {
                System.debug('Error deleting ContentDocument records: ' + e.getMessage());
                throw e; // Re-throw the exception to ensure visibility
            }
        }
    }
}