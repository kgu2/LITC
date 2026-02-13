@isTest
public class SF13424JControllerTest {
    @isTest
    static void testControllerInitialization() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New');
        insert application;

        X13424_J_Line_Item__c lineItem1 = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = application.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Donated Goods and Services').getRecordTypeId(),
            Description__c = 'Test GDS Description',
            Quantity__c = 5,
            U_M__c = 'Hr.',
            Cost_per_Unit__c = 100.00
        );
        
        X13424_J_Line_Item__c lineItem2 = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = application.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
            Description__c = 'Test Personnel Description',
            Quantity__c = 10,
            U_M__c = 'Ea.',
            Cost_per_Unit__c = 50.00
        );

        insert new List<X13424_J_Line_Item__c>{lineItem1, lineItem2};

        ApexPages.StandardController stdController = new ApexPages.StandardController(application);

        SF13424JController controller = new SF13424JController(stdController);

        System.assertEquals(application.Id, controller.applicationId, 'Application ID should match.');

        System.assertEquals(1, controller.formattedLineItemsGDS.size(), 'Should have one GDS line item.');
        System.assertEquals('Test GDS Description', controller.formattedLineItemsGDS[0].get('Description__c'), 'Description should match for GDS.');

        System.assertEquals(1, controller.formattedLineItemsP.size(), 'Should have one Personnel line item.');
        System.assertEquals('Test Personnel Description', controller.formattedLineItemsP[0].get('Description__c'), 'Description should match for Personnel.');
    }

    @isTest
    static void testFetchLineItemsWithEmptyData() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New');
        insert application;

        ApexPages.StandardController stdController = new ApexPages.StandardController(application);

        SF13424JController controller = new SF13424JController(stdController);

        System.assertEquals(0, controller.formattedLineItemsGDS.size(), 'No GDS line items should exist.');
        System.assertEquals(0, controller.formattedLineItemsF.size(), 'No Fringe line items should exist.');
        System.assertEquals(0, controller.formattedLineItemsSCTOE.size(), 'No SCTOE line items should exist.');
        System.assertEquals(0, controller.formattedLineItemsIE.size(), 'No IE line items should exist.');
        System.assertEquals(0, controller.formattedLineItemsP.size(), 'No Personnel line items should exist.');
        System.assertEquals(0, controller.formattedLineItemsMF.size(), 'No MF line items should exist.');
    }

    @isTest
    static void testFormatNumber() {

        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New');
        insert application;
        ApexPages.StandardController stdController = new ApexPages.StandardController(application);
        SF13424JController controller = new SF13424JController(stdController);
        System.assertEquals('0.00', controller.formatNumber(null), 'Null value should return 0.00.');
    }

    @isTest
    static void testTypeApplicantController() {
        Application_for_Federal_Assistance__c testApplication = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Legal_Name__c = 'Test Last Name',
            Organizational_UEI__c = 'UEI123456789',
            Type_of_Applicant_1__c = 'L. Public/Indian Housing',
            Email__c = 'test@example.com',
            UEI_Sam_gov_Validation_Status__c = true,
            First_Name__c = 'test',
            Last_Name__c = 'Last Name',
            Telephone_Number__c = '9862897537',
            Areas_affected_by_project__c = 'TX',
            Congressional_district_by_project__c = 'TXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTXTX',
            Auth_Rep_First_Name__c = 'test',
            Auth_Rep_Last_Name__c = 'Last Name',
            Auth_Rep_Title__c = 'test',
            Auth_Rep_Number__c = '9862897537',
            Auth_Rep_Email__c = 'test@test.com',
            Title_Applicant_Project__c = 'Test Project',
            Clinic_Director_Licenses_Certifications__c = 'Other',
            QTE_Licenses_Certifications__c = 'Other',
            Clinic_Mailing_Address__c = '123 Test Street',
            Organization_Overview__c = 'Test Overview',
            Experience__c = 'Test Experience',
            Type_of_Services_Provided__c = 'Test Services',
            Year_end_Date_of_Financials__c = Date.today()
        );
        insert testApplication;

        ApexPages.StandardController stdController = new ApexPages.StandardController(testApplication);

        ApexPages.currentPage().getParameters().put('caller', 'SF13424M');

        TypeApplicantController controller = new TypeApplicantController(stdController);

        String expectedFormattedDate = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('MM/dd/yyyy');
        System.assertEquals(expectedFormattedDate, controller.formattedYearEndDate, 'The formatted year-end date should match.');

        delete testApplication;
    }
}