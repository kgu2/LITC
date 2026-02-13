@isTest
public with sharing class SiteVisitTest {

    @isTest
    static void setupTestData() {
        Account testAccount = new Account( Name = 'Test Account');
        insert testAccount;

        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Version__c = 'Legacy', Personnel_Dollar_Federal_Total__c= 20, Indirect_Expenses_Federal_Total__c=20);
        insert application;

        Site_Visit__c sv= new Site_Visit__c(Related_Business_Account__c = testAccount.Id);
        insert sv;

        Site_Visit_Case_Eligibility_Requirement__c line = new Site_Visit_Case_Eligibility_Requirement__c(Site_Visit__c = sv.Id);
        insert line;

        update sv;

        SiteVisitController.getVisits();
        SiteVisitController.getLineItems(sv.Id);
    }
}