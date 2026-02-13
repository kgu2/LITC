/**
 *  Main controller for handling actions related to LITC Login Registration Form
 */
public without sharing class litcLoginController {

    /**
     * @description Checks if the currently logged-in user's Contact is unverified
     *
     * @return Boolean whether the user's Contact is unverified
     */
    @AuraEnabled
    public static Boolean getUnverified(){
        try {
            User u = [SELECT Id, Contact.Unverified__c FROM User where Id = :UserInfo.getUserId() limit 1];
            if(u.Contact.Unverified__c != null){ 
                return u.Contact.Unverified__c;
            }
            return false;
        } catch (Exception e) { throw new AuraHandledException(e.getMessage()); }
    }

    /**
     * @description Generic function for creating a new record
     *
     * @param objectName The name of the object
     * @param fields Map of field names and their field values
     * @return ID of the created record
     */
    @AuraEnabled
    public static Id createRecord(String objectName, Map<String, Object> fields) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    
        Schema.SObjectType objType = globalDescribe.get(objectName);
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();    

        SObject newRecord = objType.newSObject();

        for (String fieldName : fields.keySet()) {
            newRecord.put(fieldName, fields.get(fieldName));
        }

        if(objectName != 'AccountContactRelation'){ 
            User u = [SELECT Id, Name, email, username FROM User WHERE username like '%venkatasriram.avasarala%' ORDER BY CreatedDate limit 1];
            newRecord.put('OwnerId', u.Id);
        }
    
        try {
            Database.insert(newRecord);
            return newRecord.Id;
        } catch (DMLException e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    /**
     * @description Generic function for deleting a record
     *
     * @param objectName The name of the object
     * @param recordId The ID of the record to be deleted
     */
    @AuraEnabled
    public static void deleteRecord(String objectName, String recordId) {
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Schema.SObjectType objType = globalDescribe.get(objectName);
        SObject recordToDelete = objType.newSObject(recordId);

        try {
            Database.delete(recordToDelete);
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
            for(String key : fields.keySet()){
                rec.put(key, fields.get(key));
            }
            
            update rec;
            
        } catch (QueryException e){
                System.debug(e.getMessage());
                throw new AuraHandledException(e.getMessage());    
        }
    }

    /**
     * @description Gets child accounts for a given parent account
     *
     * @param recordId The ID of the parent account
     * @return A list of child Account records
     */
    @AuraEnabled(Cacheable=true)
    public static List<Account> getChildAccounts(String recordId) {
        try {
            List<Account> childAccounts = [SELECT Id, Name, ParentId, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingAddress FROM Account WHERE ParentId = :recordId];
            return childAccounts;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    /**
     * @description Gets an account record by Id.
     *
     * @param recordId The ID of the account
     * @return The Account record.
     */
    @AuraEnabled
    public static Account getMyAccount(String recordId) {
        try {
            Account myAccount = [SELECT Id, Name, Account_Type__c FROM Account WHERE Id = :recordId];
            return myAccount;
        } catch (Exception e) {
            throw new AuraHandledException('Error: ' + e.getMessage());
        }
    }

    /**
     * @description Gets the LITC role of the current logged-in user
     *
     * @return The Role value of the current user's Contact.
     */
    @AuraEnabled
    public static string getMyRole(){
        try {
            User currentUser = [SELECT Contact.LITC_Role__c, Contact.LITC_Role_v2__c  FROM User WHERE Id = :UserInfo.getUserId()];
            return currentUser.Contact.LITC_Role_v2__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
 
    /**
     * @description Gets all related contacts for a given account
     *
     * @param recordId The ID of the account
     * @return A list of related contacts
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getRelatedContacts(String recordId) {
        List<AccountContactRelation> aCRel = [
            SELECT Contact.Id, Contact.Phone, Contact.Email, Contact.Name, Contact.Title, 
                   Contact.LITC_Role__c, Contact.FirstName, Contact.LastName, Contact.LITC_Role_v2__c,
                   Contact.On_boarding_Expiration_Date__c, Contact.On_boarding_Expirired__c
            FROM AccountContactRelation
            WHERE AccountId = :recordId
        ];
    
        // Collect contact emails
        Set<String> contactEmails = new Set<String>();
        for (AccountContactRelation acr : aCRel) {
            if (acr.Contact != null && acr.Contact.Email != null) {
                contactEmails.add('%' + acr.Contact.Email + '.litc');
            }
        }
    
        Map<String, Boolean> userEmailMap = new Map<String, Boolean>();
        if (!contactEmails.isEmpty()) {
            List<User> usersWithEmails = [SELECT Username FROM User WHERE Username LIKE :contactEmails];
            for (User user : usersWithEmails) {
                userEmailMap.put(user.Username, true);
            }
        }
    
        List<Map<String, Object>> responseList = new List<Map<String, Object>>();
        for (AccountContactRelation acr : aCRel) {
            Map<String, Object> recordMap = new Map<String, Object>();
            recordMap.put('Contact', acr.Contact);
    
            String emailPattern = '%' + acr.Contact.Email + '.litc';
            Boolean isUserFound = userEmailMap.containsKey(emailPattern);
    
            if (isUserFound) {
                recordMap.put('isOnBoardingExpired', true);
            } else {
                recordMap.put('isOnBoardingExpired', acr.Contact.On_boarding_Expirired__c);
            }
    
            responseList.add(recordMap);
        }
    
        return responseList;
    }
    
    
    /**
     * @description Gets all contacts
     *
     * @return A list of all Contact records
     */
    @AuraEnabled(cacheable=true)
    public static List<Contact> getAllRelatedContacts(string recordId) {
        List<Contact> CRel = new List<Contact>();
        CRel = [SELECT Id, Phone, Email, Name, Title, LITC_Role__c,LITC_Role_v2__c, On_boarding_Expiration_Date__c,Contact.On_boarding_Expirired__c FROM Contact];
        return CRel;
    }

    /**
     * @description Updates the onboarding expiration date of a Contact
     *
     * @param contactId The ID of the Contact
     * @param newExpirationDate The new expiration date
     */
    @AuraEnabled
    public static void updateOnboardingExpirationDate(Id contactId, Date newExpirationDate) {
        try {
            Contact contactRecord = [SELECT Id, On_boarding_Expiration_Date__c FROM Contact WHERE Id = :contactId LIMIT 1];
            contactRecord.On_boarding_Expiration_Date__c = newExpirationDate;
            update contactRecord;
        } catch (Exception e) {
            throw new AuraHandledException('Failed to update onboarding expiration date: ' + e.getMessage());
        }
    }

}