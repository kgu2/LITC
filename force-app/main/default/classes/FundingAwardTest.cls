@isTest
public with sharing class FundingAwardTest {

    @isTest
    static void setupTestData() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Version__c = 'Legacy', Personnel_Dollar_Federal_Total__c= 20, Indirect_Expenses_Federal_Total__c=20);
        insert application;

        FundingOpportunity fo = new FundingOpportunity(Name='test');
        insert fo;

        FundingAward fa = new FundingAward(Name='test', FundingOpportunityId = fo.Id, Application_for_Federal_Assistance__c = application.Id);
        insert fa;

        FundingDisbursement fd = new FundingDisbursement(FundingAwardId = fa.Id, Amount= 0);
        insert fd;
 
        update fd;


        Test.startTest();
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(fa);

        FundingAwardPDFController controller = new FundingAwardPDFController(stdController);

        Test.stopTest();

        FundingAwardPDFController.generatePDF(fa.Id, fd.Id);
    }
}