/**
 * Trigger handler class for the NTA_Review__c and NTA_Review__c objects
 * Contains logic to creating review cards and updating application data
 */
public with sharing class NTAReviewTriggerHandler {
    /**
     * proccess afterUpdate function for NTA_Review__c
     * Creates level 1 Review Cards if NTA Review is passed. Also updates related application fields.
     * @param newReviews List of updated NTA_Review__c records
     * @param oldReviewsMap map of old NTA_Review__c records
     */
    public static void processNTAReview(List<NTA_Review__c> newReviews, Map<Id, NTA_Review__c> oldReviewsMap) {
    
        Review_Template__c template;
        Review_Template__c legacyTemplate;
        try {
            template = [SELECT Id FROM Review_Template__c WHERE Name = 'LITC Application template' LIMIT 1];
            legacyTemplate = [SELECT Id FROM Review_Template__c WHERE Name = 'LITC Legacy Application Template' LIMIT 1];
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    
        Id levelOneRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 1').getRecordTypeId();
        
        Set<Id> applicationIds = new Set<Id>();
        Set<Id> reviewIds = new Set<Id>();
        for (NTA_Review__c review : newReviews) {
            applicationIds.add(review.Application_for_Federal_Assistance__c);
            reviewIds.add(review.Id);
        }
        
        Map<Id, Application_for_Federal_Assistance__c> applicationMap = new Map<Id, Application_for_Federal_Assistance__c>(
            [SELECT Id, Name FROM Application_for_Federal_Assistance__c WHERE Id IN :applicationIds]
        );
        
        // checks for existing review cards
        List<Review_Card__c> existingCards = [SELECT Id FROM Review_Card__c WHERE NTA_Review__c IN :reviewIds];

        List<Review_Card__c> reviewCards = new List<Review_Card__c>();
        for (NTA_Review__c review : newReviews) {
            NTA_Review__c oldReview = oldReviewsMap.get(review.Id);

            // assign the correct template 
            String reviewTemplateId;
            if(review.Version__c == 'Legacy'){ 
                if(legacyTemplate == null) return;
                reviewTemplateId = legacyTemplate.Id;
            } else{ 
                if(template == null) return;
                reviewTemplateId = template.Id;
            }
            
            // create review cards if passed
            if (review.Review_Status__c == 'Passed Intake Review' && oldReview.Review_Status__c != 'Passed Intake Review' && review.Staff_Review_Application_Type__c != 'NCCs under 30' && review.Staff_Review_Application_Type__c != 'NCCs above 30') {
                if (existingCards.isEmpty()) { 
                    String applicatioName = applicationMap.get(review.Application_for_Federal_Assistance__c).Name;
                    
                    List<String> letters = new List<String>{'A', 'B', 'C'};
                    for (Integer i = 0; i < 3; i++) {
                        Review_Card__c newReviewCard = new Review_Card__c(
                            NTA_Review__c = review.Id,
                            Name = applicatioName + ' - level 1 Review Card ' + letters[i],
                            Review_Template__c = reviewTemplateId,
                            Program__c = 'LITC',
                            RecordTypeId = levelOneRecordType,
                            Status__c = 'Not Submitted'
                        );
                        reviewCards.add(newReviewCard);
                    }
                }
            }
        }
    
        if (!reviewCards.isEmpty()) {
            insert reviewCards;
        }

        // updates related application fields
        updateApplicationFields(newReviews, oldReviewsMap);
    }

    public static void processDeleteRCs(List<NTA_Review__c> newReviews, Map<Id, NTA_Review__c> oldReviewsMap){ 
        Set<Id> reviews = new Set<Id>();
        for (NTA_Review__c review : newReviews) {
            NTA_Review__c oldReview = oldReviewsMap.get(review.Id);
            // if NCC delete RCs
            if((review.Staff_Review_Application_Type__c == 'NCCs under 30' || review.Staff_Review_Application_Type__c == 'NCCs above 30') 
            && (oldReview.Staff_Review_Application_Type__c != 'NCCs under 30' && oldReview.Staff_Review_Application_Type__c != 'NCCs above 30')){ 
                reviews.add(review.Id);
            }
        }

        if(!reviews.isEmpty()){ 
            List<Review_Card__c> rcsToDelete = [SELECT ID FROM Review_Card__c WHERE NTA_Review__c IN: reviews];
            delete rcsToDelete;
        }
    }

    public static void beforeUpdate(List<NTA_Review__c> newReviews) {
        for(NTA_Review__c nta : newReviews){ 
            if(nta.Review_Status__c == 'NTA Finalized'){ 
                nta.Flow_Status__c = 'NTA Finalized';
            }
        }
    }

    /**
     * Updates field(s) on related application based on NTA values
     * @param newReviews List of updated NTA_Review__c records
     * @param oldReviewsMap map of old NTA_Review__c records
     */
    private static void updateApplicationFields(List<NTA_Review__c> newReviews, Map<Id, NTA_Review__c> oldReviewsMap){ 
        
        Map<Id, NTA_Review__c> appToNTAMap = new Map<Id, NTA_Review__c>();

        for (NTA_Review__c review : newReviews) {
            if (review.Application_for_Federal_Assistance__c != null) {
                appToNTAMap.put(review.Application_for_Federal_Assistance__c, review);
            }
        }

        if (appToNtaMap.isEmpty()) return;
        
        List<Application_for_Federal_Assistance__c> appsToUpdate = [SELECT Id, NTA_Denial_Reason__c, Denied__c, Related_Business_Account__c FROM Application_for_Federal_Assistance__c WHERE Id IN :appToNTAMap.keySet()];

        List<Account> accounts = new List<Account>();

        for (Application_for_Federal_Assistance__c app : appsToUpdate) {
            NTA_Review__c review = appToNTAMap.get(app.Id);
            app.NTA_Denial_Reason__c = review.NTA_Denial_Reasons__c;
            if (review.Review_Status__c == 'Denied') {
                app.Denied__c = true;
            }

            if(review.Efficiency_Score__c != null){ 
                Account account = new Account(Id = app.Related_Business_Account__c, Efficiency_Score__c = review.Efficiency_Score__c);
                accounts.add(account);
            }
        }

        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }

        if (!accounts.isEmpty()) {
            update accounts;
        }


       
    }


    public static void afterInsert(List<NTA_Review__c> newReviews) {
        Map<Id, NTA_Review__c> appToNTAMap = new Map<Id, NTA_Review__c>();

        for (NTA_Review__c review : newReviews) {
            if (review.Application_for_Federal_Assistance__c != null) {
                appToNTAMap.put(review.Application_for_Federal_Assistance__c, review);
            }
        }

        System.debug(appToNTAMap);

        if (appToNtaMap.isEmpty()) return;
        
        Map<Id, Application_for_Federal_Assistance__c> apps = new Map<Id, Application_for_Federal_Assistance__c>(
            [SELECT Id, Related_Business_Account__c 
            FROM Application_for_Federal_Assistance__c 
            WHERE Id IN :appToNtaMap.keySet()]
        );

        System.debug(apps);

        List<Account> accounts = new List<Account>();

        for (Id appId : appToNtaMap.keySet()) {
            Application_for_Federal_Assistance__c app = apps.get(appId);
            if (app.Related_Business_Account__c != null) {
                accounts.add(new Account(Id = app.Related_Business_Account__c, Most_recent_NTA__c = appToNtaMap.get(appId).Id));
            }
        }   

        System.debug(accounts);

        if (!accounts.isEmpty()) {
            update accounts;
        }
    }
}