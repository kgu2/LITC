@isTest
public with sharing class LITCCloseoutTest {
    @isTest
    static void setupTestData() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Version__c = 'Legacy', Personnel_Dollar_Federal_Total__c= 20, Indirect_Expenses_Federal_Total__c=20);
        insert application;

        LITC_Reporting_Form__c rForm = new LITC_Reporting_Form__c(Application_for_Federal_Assistance__c = application.Id, 
        recordTypeId = Schema.SObjectType.LITC_Reporting_Form__c.getRecordTypeInfosByName().get('Form 13424-R').getRecordTypeId());

        LITC_Reporting_Form__c lForm = new LITC_Reporting_Form__c(Application_for_Federal_Assistance__c = application.Id, 
        recordTypeId = Schema.SObjectType.LITC_Reporting_Form__c.getRecordTypeInfosByName().get('Form 13424-L').getRecordTypeId());

        SF425_Form__c sfForm = new SF425_Form__c(Application_for_Federal_Assistance__c = application.Id);

        insert rForm;
        insert lForm;
        insert sfForm;


        X13424_J_Line_Item__c lineItem = new X13424_J_Line_Item__c(Application_for_Federal_Assistance__c = application.Id);
        insert lineItem;    

        X13424_J_Line_Item_Snapshot__c snap = new X13424_J_Line_Item_Snapshot__c(LITC_Reporting_Form__c = lForm.Id);
        insert snap;

        FundingAward fa = new FundingAward(Name='test', Application_for_Federal_Assistance__c = application.Id);
        insert fa;

        FundingDisbursement fd = new FundingDisbursement(FundingAwardId = fa.Id);
        insert fd;

        LITC_Payment__c payment = new LITC_Payment__c(Document_Number__c='123', Funding_Award__c = fa.Id);
        insert payment;

        LITCCloseoutController.runChecks(fa.Id);

        // fa.Status = 'closed';
        update fa;   

    }

}