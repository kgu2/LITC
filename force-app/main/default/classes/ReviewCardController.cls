/**
 *  Main controller for handling actions related to Review cards and review related processes
 */
public with sharing class ReviewCardController {

    /**
     * Gets list of all review answers
     *
     * @param recordId ID of the review card 
     * @return list of Review_Answer__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Review_Answer__c> getQuestions(String recordId) {
        List<Review_Answer__c> reviewQuestions = [
            SELECT Id, Name, Question_ID__c, Section__c, Review_Question__r.Name, Review_Question__r.Formula__c, Review_Question__r.Description__c, Score__c, Evaluation__c, Description__c, Review_Card__r.NTA_Review__r.Application_for_Federal_Assistance__c, Section_Weight__c, Summary__c
            FROM Review_Answer__c WHERE Review_Card__c =: recordId AND Summary__c = false ORDER BY Question_ID__c asc];
        return reviewQuestions;
    }

    /**
     * Gets list of all review answers where Summary__c is true
     *
     * @param recordId ID of the review card 
     * @return list of Review_Answer__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Review_Answer__c> getSummaryQuestions(String recordId) {
        List<Review_Answer__c> reviewQuestions = [SELECT Id, Name, Section_Summary__c, Summary__c, Notes__c, Strengths__c, Weaknesses__c FROM Review_Answer__c WHERE Review_Card__c =: recordId AND Summary__c = true];
        return reviewQuestions;
    }

    /**
     * Dynamically returns fields from Application_for_Federal_Assistance__c given the provided api names
     * @param recordId ID of the Application
     * @param fieldNames List of field API names
     * @return Map of field label to value 
     */
    @AuraEnabled
    public static Map<String, String> getApplicationFields(Id recordId, List<String> fieldNames) {
        String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM Application_for_Federal_Assistance__c WHERE Id = :recordId';
        Application_for_Federal_Assistance__c myApp = Database.query(query);
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Application_for_Federal_Assistance__c').getDescribe().fields.getMap();

        Map<String, String> result = new Map<String, String>();
        for (String fieldName : fieldNames) {
            if (fieldMap.containsKey(fieldName)) {
                String label = fieldMap.get(fieldName).getDescribe().getLabel();
                String value = String.valueOf(myApp.get(fieldName));
                result.put(label, value); 
            }
        }

        return result; 
    }

    /**
     * Dynamically returns fields from Legacy_13424_Application__c given the provided api names
     * @param recordId ID of the Application
     * @param fieldNames List of field API names
     * @return Map of field label to value 
     */
    @AuraEnabled
    public static Map<String, String> getLegacyApplicationFields(Id recordId, List<String> fieldNames) {
        Legacy_13424_Application__c legacyApp = [SELECT ID, Name FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c =: recordId LIMIT 1];

        String query = 'SELECT ' + String.join(fieldNames, ',') + ' FROM Legacy_13424_Application__c WHERE Id = \'' + legacyApp.Id + '\'';
        Legacy_13424_Application__c myApp = Database.query(query);
        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('Legacy_13424_Application__c').getDescribe().fields.getMap();

        Map<String, String> result = new Map<String, String>();
        for (String fieldName : fieldNames) {
            if (fieldMap.containsKey(fieldName)) {
                String label = fieldMap.get(fieldName).getDescribe().getLabel();
                String value = String.valueOf(myApp.get(fieldName));
                result.put(label, value); 
            }
        }

        return result; 
    }

    /**
     * Gets list of all level 2 review cards related to an NTA review record
     *
     * @param recordId ID of the NTA_Review__c record
     * @return list of Review_Card__c records
     */
    @AuraEnabled(Cacheable=true)
    public static List<Review_Card__c> getLevel2RCs(String recordId){ 
        Id levelTwoRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 2').getRecordTypeId();
        List<Review_Card__c> rcs = [SELECT Id, Status__c FROM Review_Card__c WHERE NTA_Review__c =: recordId AND RecordTypeId =: levelTwoRecordType];
        return rcs;
    }

    /**
     * Gets list of all level 1 review cards related to an NTA review record
     *
     * @param recordId ID of the NTA_Review__c record
     * @return list of Review_Card__c records
     */
    @AuraEnabled(Cacheable=true)
    public static List<Review_Card__c> getLevel1RCs(String recordId){ 
        Id levelTwoRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 1').getRecordTypeId();
        List<Review_Card__c> rcs = [SELECT Id, Status__c FROM Review_Card__c WHERE NTA_Review__c =: recordId AND RecordTypeId =: levelTwoRecordType];
        return rcs;
    }

    /**
     * Creates a Level 2 Review Card for an NTA Review. A legacy template is used for legacy applications.
     * @param recordId ID of the NTA_Review__c record
     * @return ID of the created Review_Card__c record
     */
    @AuraEnabled
    public static String createLevel2RC(String recordId){ 
        Id levelTwoRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 2').getRecordTypeId();
        NTA_Review__c nta = [SELECT Id, Application_for_Federal_Assistance__r.Name, Version__c FROM NTA_Review__c WHERE Id =: recordId];

        Review_Template__c template = [ SELECT Id FROM Review_Template__c WHERE Name = 'LITC Application template' LIMIT 1];
        Review_Template__c legacyTemplate = [SELECT Id FROM Review_Template__c WHERE Name = 'LITC Legacy Application Template' LIMIT 1];

        String reviewCardName = nta.Application_for_Federal_Assistance__r.Name + ' - level 2 Review Card';

        String reviewTemplateId = '';
        if(nta.Version__c == 'Legacy'){ 
            reviewTemplateId = legacyTemplate.Id;
        } else{
            reviewTemplateId = template.Id;
        }

        Review_Card__c newReviewCard = new Review_Card__c(NTA_Review__c = recordId, Name = reviewCardName, Review_Template__c = reviewTemplateId, Program__c = 'LITC', RecordTypeId = levelTwoRecordType,Status__c = 'Not Submitted');
        insert newReviewCard;

        return newReviewCard.Id;
    }
}