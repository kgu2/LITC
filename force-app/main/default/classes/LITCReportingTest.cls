@isTest
public with sharing class LITCReportingTest {
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
        update rForm;
        update sfForm;

        LITCReportingController.getReports();
        LITCReportingController.getJLineItemsByType(rForm.Id, 'test');
        LITCReportingController.validateSF425(sfForm);
        

        X13424_J_Line_Item__c lineItem = new X13424_J_Line_Item__c(Application_for_Federal_Assistance__c = application.Id);
        insert lineItem;

        LITCReportingController.createLineItemSnapshotFromLineItem(lineItem);


        LITCReportingController.getSelectedLineItem(lineItem.Id);

        

        X13424_J_Line_Item_Snapshot__c snap = new X13424_J_Line_Item_Snapshot__c(LITC_Reporting_Form__c = lForm.Id);
        insert snap;
   


        Test.startTest();
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(rForm);
        LitcReportingFormPDFController controller = new LitcReportingFormPDFController(stdController);

        ApexPages.StandardController stdController2 = new ApexPages.StandardController(lForm);
        LitcReportingFormPDFController controller2 = new LitcReportingFormPDFController(stdController2);
        Test.stopTest();

        delete snap;
    }

    @isTest
    static void setupTestSF425() {

        SF425ReportingController.getReportsLITC();

        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'LITC Customer Community Login' LIMIT 1];

        Account a = new Account(Name='Test Co.');
        insert a;
        Contact c = new Contact(LastName='Test', AccountId=a.Id);
        insert c;
        User u = new User(Alias = 't23', Email='teststandarduser@test.com', 
                        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                        LocaleSidKey='en_US', ProfileId = userProfile.Id,    
                        TimeZoneSidKey='America/Los_Angeles', UserName='testmser127@test.com', ContactId=c.Id);
        insert u;


        System.runAs(u) {
            Contact con = SF425ReportingController.getCurrentContactInformation();
        }
    }


}