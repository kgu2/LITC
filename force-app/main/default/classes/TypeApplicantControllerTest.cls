@isTest
public class TypeApplicantControllerTest {

    @isTest
    static void testTypeApplicantController() {
        // Create a test record for Application_for_Federal_Assistance__c
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

        // Create a standard controller for the test record
        ApexPages.StandardController stdController = new ApexPages.StandardController(testApplication);

        // Set a test parameter
        ApexPages.currentPage().getParameters().put('caller', 'SF13424M');
 
        // Initialize the controller
        TypeApplicantController controller = new TypeApplicantController(stdController);

        // Validate initializations
    /*     System.assertEquals('Test Project', controller.formattedTitle, 'The title should be formatted correctly.');
        System.assertEquals('Test Area', controller.areasAffectedbyProject, 'The areas affected should be formatted correctly.');
        System.assertEquals('Test District', controller.congressDistrictByProject, 'The congressional district should be formatted correctly.');
        //System.assert(controller.IsOtherSelected, 'IsOtherSelected should be true.');
        System.assert(controller.IsClinicDirectorOther, 'IsClinicDirectorOther should be true.');
        System.assert(controller.IsQTEOther, 'IsQTEOther should be true.');
        System.assert(controller.IsClinicMailingAddress, 'IsClinicMailingAddress should be true.');
        System.assert(controller.IsOrganizationOverviewPresent, 'IsOrganizationOverviewPresent should be true.');
        System.assert(controller.IsExperiencePresent, 'IsExperiencePresent should be true.');
        System.assert(controller.IsTypeOfServicesProvidedPresent, 'IsTypeOfServicesProvidedPresent should be true.'); */

        // Validate date formatting
        String expectedFormattedDate = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('MM/dd/yyyy');
        System.assertEquals(expectedFormattedDate, controller.formattedYearEndDate, 'The formatted year-end date should match.');

        // Clean up test data
        delete testApplication;
    }
}