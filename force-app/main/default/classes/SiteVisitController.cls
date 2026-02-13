public with sharing class SiteVisitController {
    @AuraEnabled(cacheable=true)
    public static List<Site_Visit__c> getVisits() {
        List<Site_Visit__c> visits = new List<Site_Visit__c>();
        for (Site_Visit__c visit : [SELECT Id, Name, Status__c, Recipient_Status__c FROM Site_Visit__c]){ 
            visits.add(visit);
        }
        return visits;
    }

    @AuraEnabled(cacheable=true)
    public static List<Site_Visit_Case_Eligibility_Requirement__c> getLineItems(String reportId) {
        List<Site_Visit_Case_Eligibility_Requirement__c> lineItems = new List<Site_Visit_Case_Eligibility_Requirement__c>();

        for (Site_Visit_Case_Eligibility_Requirement__c item : [
            SELECT 
                Id, Client_ID__c, Explanation__c, Highest_amount_controversy_more_50_000__c, Highest_Amount_in_Controversy__c, 
                Household_Income_Representation__c, Income_more_250_Fed_Poverty_Guidelines__c, Intake_Date__c, 
                Number_of_Tax_Years_in_Controversy__c, Site_Visit__c, Name, Size_of_Family_Unit__c, What_was_used_to_determine_income__c
            FROM Site_Visit_Case_Eligibility_Requirement__c WHERE Site_Visit__c =: reportId]){ 
            lineItems.add(item);
        }
        return lineItems;
    }
}