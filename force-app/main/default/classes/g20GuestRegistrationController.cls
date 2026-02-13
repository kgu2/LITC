public without sharing class g20GuestRegistrationController {
    /**
     * @description Generic function for creating a new record
     *
     * @param objectName The name of the object
     * @param fields Map of field names and their field values
     * @return ID of the created record
     */
    @AuraEnabled
    public static Id createRecord(String objectName, Map<String, Object> fields, Boolean isGuest) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
        Schema.SObjectType objType = globalDescribe.get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();    

        SObject newRecord = objType.newSObject();

        for (String fieldName : fields.keySet()) {
            // newRecord.put(fieldName, fields.get(fieldName));
              if (!objFieldMap.containsKey(fieldName)) continue;

            Schema.DisplayType fieldType = objFieldMap.get(fieldName).getDescribe().getType();
            Object fieldValue = fields.get(fieldName);
            if (fieldValue == null) continue;

            // Convert value based on field type
            switch on fieldType {
                when DATE {
                    newRecord.put(fieldName, Date.valueOf((String)fieldValue));
                }
                when DATETIME {
                    String dt = (String) fieldValue;
                    dt = dt.replace('T', ' ').replace('Z', '').split('\\.')[0]; 
                    newRecord.put(fieldName, Datetime.valueOfGmt(dt));
                }
                when BOOLEAN {
                    newRecord.put(fieldName, Boolean.valueOf((Boolean)fieldValue));
                }
                when DOUBLE, CURRENCY, INTEGER, PERCENT {
                    newRecord.put(fieldName, Decimal.valueOf((String)fieldValue));
                }
                when ID, STRING, TEXTAREA, EMAIL, PHONE, URL, PICKLIST, MULTIPICKLIST {
                    newRecord.put(fieldName, (String)fieldValue);
                }
                when else {
                    newRecord.put(fieldName, fieldValue);
                }
            }
        }

        if(isGuest == true){ 
                if(objectName != 'AccountContactRelation'){ 
                User u = [SELECT Id, Name, email, username FROM User WHERE username like '%venkatasriram.avasarala%' ORDER BY CreatedDate limit 1];
                newRecord.put('OwnerId', u.Id);
            }
        }
        
        try {
            Database.insert(newRecord);
            return newRecord.Id;
        } catch (DMLException e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    /**
     * @description Generic function for updating a record
     *
     * @param recordId The ID of the record to update
     * @param objectName The name of the object 
     * @param fields Map of field names and their field values to update
     */
    @AuraEnabled
    public static void updateRecord(String recordId, String objectName, Map<String, Object> fields) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objType = globalDescribe.get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();

        String query = 'SELECT';
        for (String fieldName : fields.keySet()) {
            query += ' ' + fieldName + ',';
        }

        if (query.endsWith(',')) {
            query = query.subString(0, query.length() - 1);
        }

        query += ' FROM ' + objectName;
        query += ' WHERE Id =: recordId LIMIT 1';

        try {
            SObject rec = database.query(query);
            for (String fieldName : fields.keySet()) {
                if (!objFieldMap.containsKey(fieldName)) continue;

                Schema.DisplayType fieldType = objFieldMap.get(fieldName).getDescribe().getType();
                Object fieldValue = fields.get(fieldName);
                if (fieldValue == null) continue;

                switch on fieldType {
                    when DATE {
                        rec.put(fieldName, Date.valueOf((String)fieldValue));
                    }
                    when DATETIME {
                        String dt = (String) fieldValue;
                        dt = dt.replace('T', ' ').replace('Z', '').split('\\.')[0]; 
                        rec.put(fieldName, Datetime.valueOfGmt(dt));
                    }
                    when BOOLEAN {
                        rec.put(fieldName, Boolean.valueOf((Boolean)fieldValue));
                    }
                    when DOUBLE, CURRENCY, INTEGER, PERCENT {
                        rec.put(fieldName, Decimal.valueOf((String)fieldValue));
                    }
                    when ID, STRING, TEXTAREA, EMAIL, PHONE, URL, PICKLIST, MULTIPICKLIST {
                        rec.put(fieldName, (String)fieldValue);
                    }
                    when else {
                        rec.put(fieldName, fieldValue);
                    }
                }
            }
            update rec;
            
        } catch (QueryException e){
                System.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());    
        }
    }

    @AuraEnabled
    public static List<ContentVersion> fetchFilesV2(String recordId) {
        try {

            String versionId = '';
            String conDocumentId = '';
            Set<Id> conDocumentIds = new Set<Id>();

            for (ContentDocumentLink docLink : [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = : recordId]) {
                if (docLink.ContentDocumentId != null){
                    conDocumentIds.add(docLink.ContentDocumentId);                        
                }  
            }  
            List<ContentVersion> getFiles = new List<ContentVersion>();
            if(conDocumentIds != null){
                getFiles =  [SELECT Id, ContentDocumentId, File_Prefix__c, Title, FileType,CreatedDate 
                             FROM ContentVersion 
                             WHERE ContentDocumentId IN : conDocumentIds Order by ContentDocument.CreatedDate asc];
            }
            
            return getFiles;
        } catch(Exception ex) { throw new AuraHandledException(ex.getMessage()); }
    }

    @AuraEnabled(cacheable=true)
    public static List<G20_Event_Registration__c> getAllRegistrations() {
        List<G20_Event_Registration__c> CRel = new List<G20_Event_Registration__c>();
        CRel = [SELECT Id, DI_Email__c, Name FROM G20_Event_Registration__c];
        return CRel;
    }

    @AuraEnabled(cacheable=true)
    public static List<G20_Event_Registration__c> getRegistrations(String contactId) {
        List<G20_Event_Registration__c> apps = new List<G20_Event_Registration__c>();
        for (G20_Event_Registration__c app : [SELECT Id, Name, DI_First_Name__c, DI_Last_Name__c, DI_Email__c, G20_Role__c, Status__c, Guest_Registration__c, Guest_Registration_Deadline__c, Public_Link_URL__c
         FROM G20_Event_Registration__c WHERE Contact__c =: contactId OR Created_For_Contact__c =: contactId]){ 
            apps.add(app);
        }
        return apps;
    }

    @AuraEnabled(cacheable=true)
    public static G20_Event_Registration__c getRecordByToken(String token) {
        List<G20_Event_Registration__c> rec = [SELECT Id, DI_First_Name__c, DI_Last_Name__c, DI_Email__c, DI_Middle_Name__c, DI_Title__c, DI_Phone_Number__c,  Guest_Registration_Deadline__c,
        DI_Gender__c, Delegation_International_Organization__c, G20_Role__c, Status__c FROM G20_Event_Registration__c WHERE Access_Token__c = :token LIMIT 1];
        return rec[0];
    }

    
}