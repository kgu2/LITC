/**
 * Trigger handler class for the ApplicationReview object
 * Contains logic to update the parent NTA_Review__c record when the Application Review record is updated
 */
public with sharing class ApplicationReviewTriggerHandler {

    /**
     * This function updates the related NTA_Review__c record when the intake status gets changed to "Passed Intake Review"
     * @param newRecords List of new ApplicationReview records
     * @param oldMap Map of old ApplicationReview records
     */
    public static void handleAfterUpdate(List<ApplicationReview> newRecords, Map<Id, ApplicationReview> oldMap) {

        Set<Id> ntaReviewSet = new Set<Id>();
        Set<Id> appIdSet = new Set<Id>();

        for (ApplicationReview ar : newRecords) {
            if(ar.NTA_Review__c != null){ 
                ntaReviewSet.add(ar.NTA_Review__c);
            }
            if(ar.Application_for_Federal_Assistance__c != null){ 
                appIdSet.add(ar.Application_for_Federal_Assistance__c);
            }
        }

        Map<Id, NTA_Review__c> ntaReviewsMap = new Map<Id, NTA_Review__c>([
            SELECT Id, Review_Status__c, Date_Intake_Review_Completed__c, Flow_Status__c, Date_of_Technical_Review_Started__c, 
            Intake_Risk_Score__c, Intake_Review_Risk_Comments__c
            FROM NTA_Review__c WHERE Id IN :ntaReviewSet]);
        List<NTA_Review__c> reviewsToUpdate = new List<NTA_Review__c>();

        Map<Id, Application_for_Federal_Assistance__c> applicationMap = new Map<Id, Application_for_Federal_Assistance__c>([
            SELECT Id, Intake_Review_Denial_Reasons__c
            FROM Application_for_Federal_Assistance__c WHERE Id IN :appIdSet]);
        System.debug(applicationMap);

        List<Application_for_Federal_Assistance__c> appsToUpdate = new List<Application_for_Federal_Assistance__c>();

        for (ApplicationReview ar : newRecords) {

            ApplicationReview oldRecord = oldMap.get(ar.Id);
            
            NTA_Review__c ntaReview = ntaReviewsMap.get(ar.NTA_Review__c);
            ntaReview.Intake_Risk_Score__c = ar.Risk_Score__c;
            ntaReview.Intake_Review_Risk_Comments__c = ar.Risk_Comments__c;

            if (ar.Intake_Status__c == 'Passed Intake Review' && oldRecord.Intake_Status__c != 'Passed Intake Review' && ar.NTA_Review__c != null) {
                ntaReview.Review_Status__c = 'Passed Intake Review';
                ntaReview.Flow_Status__c = 'Technical Review';
                ntaReview.Date_Intake_Review_Completed__c = Date.today();
                ntaReview.Date_of_Technical_Review_Started__c = Date.today();
            }
            if(ar.Intake_Status__c == 'Denied'){
                ntaReview.Review_Status__c = 'Denied';
            }

            reviewsToUpdate.add(ntaReview);

            Application_for_Federal_Assistance__c application = applicationMap.get(ar.Application_for_Federal_Assistance__c);
            application.Intake_Review_Denial_Reasons__c = ar.Intake_Review_Denial_Reasons__c;
            appsToUpdate.add(application);
        }

        if (!reviewsToUpdate.isEmpty()) {
            update reviewsToUpdate;
        }

        if(!appsToUpdate.isEmpty()){ 
            update appsToUpdate;
        }
    }
}