@isTest
public with sharing class NTA_Review_PDF_Controller_Test {
    
    @isTest
    static void setupTestData() {

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Type_of_Applicant_1__c = 'M. Nonprofit with 501(c) status',
            Email__c = 'test@example.com',
            Organizational_UEI__c = 'UEI123456789',
            UEI_Sam_gov_Validation_Status__c = true);
        insert app;

        RegulatoryAuthorizationType regauthtype = new RegulatoryAuthorizationType(Name='Fee-based Financial Institution',RegulatoryAuthCategory='License');
        insert regauthtype;

        IndividualApplication individualApp = new IndividualApplication(
            ApplicationName = app.Name,
            Status = 'In Progress',
            Category = 'Permit',
            LicenseTypeId = regauthtype.id
        );
        insert individualApp;

        NTA_Review__c ntaReview = new NTA_Review__c(Review_Status__c = 'Intake Review Started', Application_for_Federal_Assistance__c = app.Id);
        insert ntaReview;


        ApplicationReview appReview = new ApplicationReview(ApplicationId = individualApp.id, Intake_Status__c = 'Intake Needs Review', Application_for_Federal_Assistance__c = app.Id, NTA_Review__c = ntaReview.Id);
        insert appReview;

        Staff_Review__c sr1 = new Staff_Review__c(NTA_Review__c = ntaReview.Id,
        recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Advocacy Analyst Review').getRecordTypeId());
        insert sr1;

        Staff_Review__c sr2 = new Staff_Review__c(NTA_Review__c = ntaReview.Id, recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Budget Analyst Review').getRecordTypeId());
        insert sr2;

        Staff_Review__c sr3= new Staff_Review__c(NTA_Review__c = ntaReview.Id, recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Program Office Review').getRecordTypeId());
        insert sr3;

        Staff_Review__c sr4 = new Staff_Review__c(NTA_Review__c = ntaReview.Id, Program_Office_Review__c = sr3.Id, AA_Narrative_Summary__c='test', Reviewing_Official_Summary__c = 'test', recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Reviewing Official Review').getRecordTypeId());
        insert sr4;

        Test.startTest();
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(ntaReview);

        NTA_Review_PDF_Controller controller = new NTA_Review_PDF_Controller(stdController);

        Test.stopTest();

        NTA_Review_PDF_Controller.generatePDF(new List<String>{ntaReview.Id});

        NTA_Review_PDF_Controller.PDFInput testInput = new NTA_Review_PDF_Controller.PDFInput();
        testInput.recordIds = ntaReview.Id;
        List<NTA_Review_PDF_Controller.PDFInput> inputList = new List<NTA_Review_PDF_Controller.PDFInput>{ testInput };
        List<NTA_Review_PDF_Controller.PDFResult> results = NTA_Review_PDF_Controller.generatePDFsInvocable(inputList);

    }
}