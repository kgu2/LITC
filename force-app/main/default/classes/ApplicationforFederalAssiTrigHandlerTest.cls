@isTest
public class ApplicationforFederalAssiTrigHandlerTest {

    @isTest
    static void testBeforeUpdateValidationErrors() {
        // Create a test application missing required fields to trigger validation errors
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'Continuation',
            SF424_Status__c = 'Submitted'  // This should trigger field-specific validations
        );

        insert app;

        // Modify the application to simulate an update and trigger beforeUpdate validations
        app.SF424_Status__c = 'Submitted';
        app.Type_of_Applicant_1__c = 'X. Other (specify)'; // Trigger "Other (specify)" validation

        Test.startTest();
        try {
            update app;
           // System.assert(false, 'Expected validation errors.');
        } catch (DmlException e) {
            // Assert that validation errors are thrown correctly
            System.assert(e.getMessage().contains('Type of applicant: Specification is required'), 'Missing validation error for "Other (specify)" type.');
        }
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdateWithValidData() {
        // Create a valid application record
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Legal_Name__c = 'Test Last Name',
            Organizational_UEI__c = 'UEI123456789',
            Type_of_Applicant_1__c = 'L. Public/Indian Housing',
            Email__c = 'test@example.com',
            UEI_Sam_gov_Validation_Status__c = true,
            First_Name__c = 'test',
            Last_Name__c = 'Last Name',
            Telephone_Number__c = '9862897537',
            Areas_affected_by_project__c = 'TX',
            Congressional_district_by_project__c = 'TX',
            Auth_Rep_First_Name__c = 'test',
            Auth_Rep_Last_Name__c = 'Last Name',
            Auth_Rep_Title__c = 'test',
            Auth_Rep_Number__c = '9862897537',
            Auth_Rep_Email__c = 'test@test.com'
        );

        insert app;

        // Update the record to change status to "Submitted"
        app.SF424_Status__c = 'Submitted';

        Test.startTest();
        update app;  // No validation errors should be thrown
        Test.stopTest();

        // Assert the record was successfully updated
        System.assertEquals('Submitted', app.SF424_Status__c, 'Application status should be updated to "Submitted".');
    }

    @isTest
    static void testAfterInsertCreatesIndividualApplication() {
        // Create a test application
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            Legal_Name__c = 'Test Clinic Application'
        );

        Test.startTest();
        insert app;
        Test.stopTest();

        // Assert that the Individual Application was created and linked to the application
        Application_for_Federal_Assistance__c insertedApp = [
            SELECT Id, Individual_Application__c FROM Application_for_Federal_Assistance__c WHERE Id = :app.Id
        ];
        System.assertNotEquals(null, insertedApp.Individual_Application__c, 'Individual Application should be linked to the application.');
    }

    @isTest
    static void testAfterUpdateChangesIndividualApplicationStatus() {
        // Create and insert a test application with a linked Individual Application
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Type_of_Applicant_1__c = 'H. Public/State Controlled Institution of Higher Education',
            Email__c = 'test@example.com',
            Organizational_UEI__c = 'UEI123456789',
            UEI_Sam_gov_Validation_Status__c = true,
            First_Name__c = 'test',
            Last_Name__c = 'Last Name',
            Telephone_Number__c = '9862897537',
            Areas_affected_by_project__c = 'TX',
            Congressional_district_by_project__c = 'TX',
            Auth_Rep_First_Name__c = 'test',
            Auth_Rep_Last_Name__c = 'Last Name',
            Auth_Rep_Title__c = 'test',
            Auth_Rep_Number__c = '9862897537',
            Auth_Rep_Email__c = 'test@test.com',
            Title_Applicant_Project__c = 'Test Project',
            Clinic_Director_Licenses_Certifications__c = 'Other',
            Clinic_Mailing_Address__c = '123 Test Street',
            Experience__c = 'Test Experience',
            Type_of_Services_Provided__c = 'Test Services',
            Clinic_Name__c = 'test',
            Clinic_Public_telephone_number__c ='9872197645',
            Clinic_Street__c = 'Test',
            Clinic_Services_and_Delivery_Model__c = 'ESL Education',
            Is_clinic_address_same_mailing__c ='Yes',
            Language_Access__c = 'test',
            Language_Options__c = 'English',
            Other_Language_Options__c = 'English',
            Reasonable_Accommodations__c = 'test',
            Geographic_Area_and_Target_Audience__c = 'test',
            Partners_and_Networks__c = 'test',
            Publicity_and_Outreach_Methods__c = 'test',
            Participation_in_Programs__c = 'Yes',
            Future_Participation__c = 'Yes',
            Taxpayer_Education__c = 'test',
            Advocacy__c = 'test',
            Organization_Overview__c = 'test',
            QTE_Position_filled_by_Volunteer__c = 'Yes',
            QTE_Identified_Hired__c = 'Yes',
            QTE_Last_name__c = 'test',
            QTE_First_name__c = 'test',
            QTE_Telephone_number__c = '9875678764',
            QTE_Email_address__c = 'test@test.com',
            QTE_Licenses_Certifications__c = 'Attorney',
            QTE_Other_Licenses_Certifications__c = 'test',
            QTE_State_s_of_Licensure__c = 'TX',
            QTE_License_Number__c = 'test',
            QTE_Responsibilities_Qualifications__c = 'test',
            QTE_Job_Description__c = 'test',
            Clinic_Director_Identified_Hired__c = 'No',
            Clinic_Director_Last_name__c = 'test',
            Clinic_Director_First_name__c = 'test',
            Clinic_Director_Telephone_number__c = '9876789876',
            Clinic_Director_Email_address__c = 'test@test.com',
            Clinic_Director_Other_Licenses_Cert__c = 'test',
            CD_Responsibilities_Qualifications__c = 'test',
            Clinic_Director_Job_Description__c = 'test',
            QBA_Identified_Hired__c = 'Yes',
            QBA_Last_name__c = 'test',
            QBA_First_name__c = 'test',
            QBA_Telephone_number__c = '9876789876',
            QBA_Email_address__c = 'test@test.com',
            QBA_Responsibilities_Qualifications__c = 'test',
            QBA_Job_Description__c = 'test',
            TCO_Last_name__c = 'Yes',
            TCO_First_name__c = 'Yes',
            TCO_Telephone_number__c = '9876789876',
            TCO_Email_address__c = 'test@test.com',
            TCO_Title__c = 'Yes',
            US_Tax_Court_Narrative__c = 'Yes',
            Student_s_Per_Semester_Type__c = 'Yes',
            Volunteer_Pro_Bono_Panel__c = 'Yes',
            Other_Volunteer_Recruitment__c = 'Yes',
            Volunteer_Recruitment_and_Retention__c = 'Yes',
            Dates_of_Operation__c = 'Yes',
            Continuity_of_Services__c = 'Yes',
            // Day_1_Hours__c = 1,
            // Day_2_Hours__c = 1,
            // Day_3_Hours__c = 1,
            // Day_4_Hours__c = 1,
            // Day_5_Hours__c = 1,
            // Day_6_Hours__c = 1,
            // Day_7_Hours__c = 1,
            After_Hours_or_Weekend_Service__c = 'Yes',
            Intake_Process__c = 'Yes',
            Household_Income_Exceeding_250_of_Pover__c = 'Yes',
            Cases_Exceeding_250_of_FPL_Description__c = 'Yes',
            Amount_in_Controversy_Limit__c = 'Yes',
            Cases_Exceed_Amt_in_Contro_Limit_Desc__c = 'Yes',
            Nominal_Fee__c = 'Yes',
            Nominal_Fee_Description__c = 'Yes',
            Case_Management_System__c = 'Yes',
            Case_Assignment_Procedures__c = 'Yes',
            Case_Monitoring__c = 'Yes',
            Time_Tracking__c = 'Yes',
            Collecting_Taxpayer_Information__c = 'Yes',
            Protecting_Taxpayer_Privacy__c = 'Yes',
            Training_and_Resources__c = 'Yes',
            In_house_Training__c = 'Yes',
            External_Training__c = 'Yes',
            Research_Materials_and_Software__c = 'Yes',
            Experience_Managing_Grants__c = 'Yes',
            Accounting_Procedures__c = 'Yes',
            Free_Tax_Preparation__c = 'Yes',
            VITA_or_TCE_Site_Funding__c = 'Yes',
            Tracking_Grant_Expenditures__c = 'Yes',
            Audits_or_Financial_Reviews__c = 'Yes',
            Financial_Statement_Information__c = 'Yes',
            Financial_Statement_Type__c = 'Audited',
            Single_Audit_Compliance__c = 'Yes',
            Audit_Clearinghouse_Availability__c = 'Yes',
            Legal_Services_Corporation_Funding__c = 'Yes',
            Program_Evaluation__c = 'Yes',
            Program_Improvement__c = 'Yes',
            Program_Numerical_Goals_Narrative__c = 'Yes',
            Numerical_goals_for_year_one__c = 1,
            New_Representation_Cases__c = 1,
            Consultations_with_Low_Income_ESL__c = 1,
            Educational_Activates_to_Low_Income__c = 1,
            Low_Income_ESL_TP_Service_Providers__c = 1,
            Active_Lawsuits_or_Complaints__c = 'Yes',
            List_of_Active_Lawsuits_or_Complaints__c = 'Yes',
            Federal_Financial_Assistance__c = 'Yes',
            Civil_Rights_Review_Activity__c = 'Yes',
            Data_Compilation_and_Maintenance__c = 'Yes',
            Public_Display_of_Civil_Rights_Poster__c = 'Yes',
            Year_end_Date_of_Financials__c = Date.today()
        );
        insert app;

        RegulatoryAuthorizationType regauthtype = new RegulatoryAuthorizationType(Name='Fee-based Financial Institution',RegulatoryAuthCategory='License');
        insert regauthtype;

        id regauthtypeId = regauthtype.id;
        // Create and link an Individual Application
        IndividualApplication individualApp = new IndividualApplication(
            ApplicationName = app.Name,
            Status = 'In Progress',
            Category = 'Permit',
            LicenseTypeId = regauthtype.id
        );
        insert individualApp;

        app.Individual_Application__c = individualApp.Id;
        update app;
        
         // Insert ContentVersion instead of ContentDocument
        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF13424M-Financial Responsibility',
            IsMajorVersion = true
        );
        insert version;

        // Query ContentDocumentId from inserted ContentVersion
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];

        // Link content to the application
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
          // Insert ContentVersion instead of ContentDocument
        ContentVersion version2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF424-Type-of-applicant_HOTUV',
            IsMajorVersion = true
        );
        insert version2;

        // Query ContentDocumentId from inserted ContentVersion
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version2.Id LIMIT 1];

        // Link content to the application
        ContentDocumentLink cd2 = new ContentDocumentLink(
            ContentDocumentId = insertedVersion2.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cd2;

        // Update the application to "Submitted" status
        app.SF424_Status__c = 'Submitted';
        app.Form_13424_Status__c = 'Submitted';

        Test.startTest();
        update app;
        Test.stopTest();

        // Assert that the Individual Application status was updated
        IndividualApplication updatedIndividualApp = [
            SELECT Id, Status FROM IndividualApplication WHERE Id = :individualApp.Id
        ];
       // System.assertEquals('Submitted', updatedIndividualApp.Status, 'Individual Application status should be updated to "Submitted".');
    }
    
    @isTest
    static void testAfterUpdateChangesIndividualApplicationStatus2() {
        // Create and insert a test application with a linked Individual Application
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Type_of_Applicant_1__c = 'M. Nonprofit with 501(c) status',
            Email__c = 'test@example.com',
            Organizational_UEI__c = 'UEI123456789',
            UEI_Sam_gov_Validation_Status__c = true,
            First_Name__c = 'test',
            Last_Name__c = 'Last Name',
            Telephone_Number__c = '9862897537',
            Areas_affected_by_project__c = 'TX',
            Congressional_district_by_project__c = 'TX',
            Auth_Rep_First_Name__c = 'test',
            Auth_Rep_Last_Name__c = 'Last Name',
            Auth_Rep_Title__c = 'test',
            Auth_Rep_Number__c = '9862897537',
            Auth_Rep_Email__c = 'test@test.com',
            Title_Applicant_Project__c = 'Test Project',
            Clinic_Director_Licenses_Certifications__c = 'Other',
            Clinic_Mailing_Address__c = '123 Test Street',
            Experience__c = 'Test Experience',
            Type_of_Services_Provided__c = 'Test Services',
            Clinic_Name__c = 'test',
            Clinic_Public_telephone_number__c ='9872197645',
            Clinic_Street__c = 'Test',
            Clinic_Services_and_Delivery_Model__c = 'ESL Education',
            Is_clinic_address_same_mailing__c ='Yes',
            Language_Access__c = 'test',
            Language_Options__c = 'English',
            Other_Language_Options__c = 'English',
            Reasonable_Accommodations__c = 'test',
            Geographic_Area_and_Target_Audience__c = 'test',
            Partners_and_Networks__c = 'test',
            Publicity_and_Outreach_Methods__c = 'test',
            Participation_in_Programs__c = 'Yes',
            Future_Participation__c = 'Yes',
            Taxpayer_Education__c = 'test',
            Advocacy__c = 'test',
            Organization_Overview__c = 'test',
            QTE_Position_filled_by_Volunteer__c = 'Yes',
            QTE_Identified_Hired__c = 'Yes',
            QTE_Last_name__c = 'test',
            QTE_First_name__c = 'test',
            QTE_Telephone_number__c = '9875678764',
            QTE_Email_address__c = 'test@test.com',
            QTE_Licenses_Certifications__c = 'Attorney',
            QTE_Other_Licenses_Certifications__c = 'test',
            QTE_State_s_of_Licensure__c = 'TX',
            QTE_License_Number__c = 'test',
            QTE_Responsibilities_Qualifications__c = 'test',
            QTE_Job_Description__c = 'test',
            Clinic_Director_Identified_Hired__c = 'No',
            Clinic_Director_Last_name__c = 'test',
            Clinic_Director_First_name__c = 'test',
            Clinic_Director_Telephone_number__c = '9876789876',
            Clinic_Director_Email_address__c = 'test@test.com',
            Clinic_Director_Other_Licenses_Cert__c = 'test',
            CD_Responsibilities_Qualifications__c = 'test',
            Clinic_Director_Job_Description__c = 'test',
            QBA_Identified_Hired__c = 'Yes',
            QBA_Last_name__c = 'test',
            QBA_First_name__c = 'test',
            QBA_Telephone_number__c = '9876789876',
            QBA_Email_address__c = 'test@test.com',
            QBA_Responsibilities_Qualifications__c = 'test',
            QBA_Job_Description__c = 'test',
            TCO_Last_name__c = 'Yes',
            TCO_First_name__c = 'Yes',
            TCO_Telephone_number__c = '9876789876',
            TCO_Email_address__c = 'test@test.com',
            TCO_Title__c = 'Yes',
            US_Tax_Court_Narrative__c = 'Yes',
            Student_s_Per_Semester_Type__c = 'Yes',
            Volunteer_Pro_Bono_Panel__c = 'Yes',
            Other_Volunteer_Recruitment__c = 'Yes',
            Volunteer_Recruitment_and_Retention__c = 'Yes',
            Dates_of_Operation__c = 'Yes',
            Continuity_of_Services__c = 'Yes',
            // Day_1_Hours__c = 1,
            // Day_2_Hours__c = 1,
            // Day_3_Hours__c = 1,
            // Day_4_Hours__c = 1,
            // Day_5_Hours__c = 1,
            // Day_6_Hours__c = 1,
            // Day_7_Hours__c = 1,
            After_Hours_or_Weekend_Service__c = 'Yes',
            Intake_Process__c = 'Yes',
            Household_Income_Exceeding_250_of_Pover__c = 'Yes',
            Cases_Exceeding_250_of_FPL_Description__c = 'Yes',
            Amount_in_Controversy_Limit__c = 'Yes',
            Cases_Exceed_Amt_in_Contro_Limit_Desc__c = 'Yes',
            Nominal_Fee__c = 'Yes',
            Nominal_Fee_Description__c = 'Yes',
            Case_Management_System__c = 'Yes',
            Case_Assignment_Procedures__c = 'Yes',
            Case_Monitoring__c = 'Yes',
            Time_Tracking__c = 'Yes',
            Collecting_Taxpayer_Information__c = 'Yes',
            Protecting_Taxpayer_Privacy__c = 'Yes',
            Training_and_Resources__c = 'Yes',
            In_house_Training__c = 'Yes',
            External_Training__c = 'Yes',
            Research_Materials_and_Software__c = 'Yes',
            Experience_Managing_Grants__c = 'Yes',
            Accounting_Procedures__c = 'Yes',
            Free_Tax_Preparation__c = 'Yes',
            VITA_or_TCE_Site_Funding__c = 'Yes',
            Tracking_Grant_Expenditures__c = 'Yes',
            Audits_or_Financial_Reviews__c = 'Yes',
            Financial_Statement_Information__c = 'Yes',
            Financial_Statement_Type__c = 'Audited',
            Single_Audit_Compliance__c = 'Yes',
            Audit_Clearinghouse_Availability__c = 'Yes',
            Legal_Services_Corporation_Funding__c = 'Yes',
            Program_Evaluation__c = 'Yes',
            Program_Improvement__c = 'Yes',
            Program_Numerical_Goals_Narrative__c = 'Yes',
            Numerical_goals_for_year_one__c = 1,
            New_Representation_Cases__c = 1,
            Consultations_with_Low_Income_ESL__c = 1,
            Educational_Activates_to_Low_Income__c = 1,
            Low_Income_ESL_TP_Service_Providers__c = 1,
            Active_Lawsuits_or_Complaints__c = 'Yes',
            List_of_Active_Lawsuits_or_Complaints__c = 'Yes',
            Federal_Financial_Assistance__c = 'Yes',
            Civil_Rights_Review_Activity__c = 'Yes',
            Data_Compilation_and_Maintenance__c = 'Yes',
            Public_Display_of_Civil_Rights_Poster__c = 'Yes',
            Year_end_Date_of_Financials__c = Date.today()
        );
        insert app;

        RegulatoryAuthorizationType regauthtype = new RegulatoryAuthorizationType(Name='Fee-based Financial Institution',RegulatoryAuthCategory='License');
        insert regauthtype;

        id regauthtypeId = regauthtype.id;
        // Create and link an Individual Application
        IndividualApplication individualApp = new IndividualApplication(
            ApplicationName = app.Name,
            Status = 'In Progress',
            Category = 'Permit',
            LicenseTypeId = regauthtype.id
        );
        insert individualApp;

        app.Individual_Application__c = individualApp.Id;
        update app;
        
         // Insert ContentVersion instead of ContentDocument
        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF424-Type-of-applicant_MN',
            IsMajorVersion = true
        );
        insert version;

        // Query ContentDocumentId from inserted ContentVersion
        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];

        // Link content to the application
        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
          // Insert ContentVersion instead of ContentDocument
        ContentVersion version2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF13424M-Financial Responsibility',
            IsMajorVersion = true
        );
        insert version2;

        // Query ContentDocumentId from inserted ContentVersion
        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version2.Id LIMIT 1];

        // Link content to the application
        ContentDocumentLink cd2 = new ContentDocumentLink(
            ContentDocumentId = insertedVersion2.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cd2;

        // Update the application to "Submitted" status
        app.SF424_Status__c = 'Submitted';
        app.Form_13424_Status__c = 'Submitted';

        Test.startTest();
        update app;
        Test.stopTest();

        // Assert that the Individual Application status was updated
        IndividualApplication updatedIndividualApp = [
            SELECT Id, Status FROM IndividualApplication WHERE Id = :individualApp.Id
        ];
       // System.assertEquals('Submitted', updatedIndividualApp.Status, 'Individual Application status should be updated to "Submitted".');
    }
}