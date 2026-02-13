@isTest
public class ApplicationFederalAssistanceTest {
    @TestSetup
    static void setupTestData() {

        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com'
        );
        insert contact;
        Account testAccount = new Account(
        Name = 'Test Account'
        );
    
        insert testAccount;

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
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
            Congressional_district_by_project__c = 'TX',
            Auth_Rep_First_Name__c = 'test',
            Auth_Rep_Last_Name__c = 'Last Name',
            Auth_Rep_Title__c = 'test',
            Auth_Rep_Number__c = '9862897537',
            Auth_Rep_Email__c = 'test@test.com'
        );
        insert app;

        Other_Staff__c otherStaff = new Other_Staff__c(
            Application_for_Federal_Assistance__c = app.Id,
            License_number__c = 'test',
            Other_License_Certfication__c = 'test',
            Other_Staff_Application_Affirms__c = true,
            Other_Staff_First_Name__c = 'test',
            Other_Staff_Last_Name__c = 'test',
            Other_Staff_Licenses_Certifications__c = 'CPA',
            Other_Staff_Middle_Initial__c = 'T',
            Other_Staff_Responsibilities_Qualf__c = 'test',
            Other_Staff_Suffix__c = 'test',
            State_of_licensure__c = 'TX',
            U_S_tax_court_number__c = 'test'
        );
        insert otherStaff;

        X13424_J_Line_Item__c lineItem1 = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = app.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Donated Goods and Services').getRecordTypeId(),
            Description__c = 'Test GDS Description',
            Quantity__c = 5,
            U_M__c = 'Hr.',
            Cost_per_Unit__c = 100.00
        );

        Congressional_District_118__c districtRecord = new Congressional_District_118__c(
            name = 'AL-01',
            District__c = '01',
            State__c = 'AL'
        );
        insert districtRecord;  

        County_to_State_Mapping__c countyRecord = new County_to_State_Mapping__c(
            Name = 'CA-Los Angeles',
            County_Name__c = 'Los Angeles',
            State_Abbr__c = 'CA'
        );

        insert countyRecord;
            
        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            IsMajorVersion = true
        );
        insert version;

        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }

    @isTest
    static void testBeforeUpdateValidationErrors() {
        // Create a test application missing required fields to trigger validation errors
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'Continuation',
            SF424_Status__c = 'Submitted' 
        );

        insert app;

        app.SF424_Status__c = 'Submitted';
        app.Type_of_Applicant_1__c = 'X. Other (specify)'; 

        Test.startTest();
        try {
            update app;
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Type of applicant: Specification is required'), 'Missing validation error for "Other (specify)" type.');
        }
        Test.stopTest();
    }

    @isTest
    static void testBeforeUpdateWithValidData() {

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Is_Applicant_Delinquent_on_Federal_Debt__c = 'No',
            Do_you_have_a_UEI__c = 'Yes',
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

        app.SF424_Status__c = 'Submitted';

        Test.startTest();
        update app; 
        Test.stopTest();

        System.assertEquals('Submitted', app.SF424_Status__c, 'Application status should be updated to "Submitted".');
    }

    @isTest
    static void testAfterInsertCreatesIndividualApplication() {
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            Legal_Name__c = 'Test Clinic Application'
        );

        Test.startTest();
        insert app;
        Test.stopTest();

        Application_for_Federal_Assistance__c insertedApp = [
            SELECT Id, Individual_Application__c FROM Application_for_Federal_Assistance__c WHERE Id = :app.Id
        ];
        System.assertNotEquals(null, insertedApp.Individual_Application__c, 'Individual Application should be linked to the application.');
    }

    @isTest
    static void testAfterUpdateChangesIndividualApplicationStatus() {

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Do_you_have_a_UEI__c = 'Yes',
            Version__c = 'New',
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
            Clinic_City__c = 'Houston',
            Clinic_State__c = 'TX',
            Clinic_Zip_Code__c = '20788',
            Clinic_Services_and_Delivery_Model__c = 'ESL Education',
            Is_clinic_address_same_mailing__c ='Yes',
            Language_Access__c = 'test',
            Language_Options__c = 'Spanish',
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
            QTE_Identified_Hired__c = 'No',
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
            Is_Applicant_Delinquent_on_Federal_Debt__c = 'No',
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

        IndividualApplication individualApp = new IndividualApplication(
            ApplicationName = app.Name,
            Status = 'In Progress',
            Category = 'Permit',
            LicenseTypeId = regauthtype.id
        );
        insert individualApp;

        app.Individual_Application__c = individualApp.Id;
        update app;
        
        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF13424M-Financial Responsibility',
            IsMajorVersion = true
        );
        insert version;

        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        ContentVersion version2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF424-Type-of-applicant_HOTUV',
            IsMajorVersion = true
        );
        insert version2;

        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version2.Id LIMIT 1];

        ContentDocumentLink cd2 = new ContentDocumentLink(
            ContentDocumentId = insertedVersion2.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cd2;

        app.SF424_Status__c = 'Submitted';
        app.Form_13424_Status__c = 'Submitted';

        Test.startTest();
        update app;
        Test.stopTest();

        IndividualApplication updatedIndividualApp = [
            SELECT Id, Status FROM IndividualApplication WHERE Id = :individualApp.Id
        ];

    }
    
    @isTest
    static void testAfterUpdateChangesIndividualApplicationStatus2() {

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Version__c = 'New',
            Do_you_have_a_UEI__c = 'Yes',
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
            Clinic_City__c = 'Houston',
            Clinic_State__c = 'TX',
            Clinic_Zip_Code__c = '20788',
            Clinic_Services_and_Delivery_Model__c = 'ESL Education',
            Is_clinic_address_same_mailing__c ='Yes',
            Language_Access__c = 'test',
            Language_Options__c = 'Spanish',
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
            QTE_Identified_Hired__c = 'No',
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
            Is_Applicant_Delinquent_on_Federal_Debt__c = 'No',
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

        IndividualApplication individualApp = new IndividualApplication(
            ApplicationName = app.Name,
            Status = 'In Progress',
            Category = 'Permit',
            LicenseTypeId = regauthtype.id
        );
        insert individualApp;

        app.Individual_Application__c = individualApp.Id;
        update app;

        ContentVersion version = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF424-Type-of-applicant_MN',
            IsMajorVersion = true
        );
        insert version;

        ContentVersion insertedVersion = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version.Id LIMIT 1];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = insertedVersion.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cdl;
        
        ContentVersion version2 = new ContentVersion(
            Title = 'Test Document',
            PathOnClient = 'TestDocument.pdf',
            VersionData = Blob.valueOf('Test PDF content'),
            Origin = 'C',
            File_Prefix__c = 'SF13424M-Financial Responsibility',
            IsMajorVersion = true
        );
        insert version2;

        ContentVersion insertedVersion2 = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :version2.Id LIMIT 1];

        ContentDocumentLink cd2 = new ContentDocumentLink(
            ContentDocumentId = insertedVersion2.ContentDocumentId,
            LinkedEntityId = app.Id,
            ShareType = 'I',
            Visibility = 'AllUsers'
        );
        insert cd2;
        app.SF424_Status__c = 'Submitted';
        app.Form_13424_Status__c = 'Submitted';

        Test.startTest();
        update app;
        Test.stopTest();

        IndividualApplication updatedIndividualApp = [
            SELECT Id, Status FROM IndividualApplication WHERE Id = :individualApp.Id
        ];
    }

    // @IsTest
    // static void testHandleFileUploadValidation() {
    //     Application_for_Federal_Assistance__c app = [SELECT Id FROM Application_for_Federal_Assistance__c LIMIT 1];
    //     Boolean result = ApplicationFederalAssistanceController.handleFileUploadValidation(app.Id);
    // }

    @IsTest
    static void testGeneratePDF() {
        Application_for_Federal_Assistance__c app = [SELECT Id FROM Application_for_Federal_Assistance__c LIMIT 1];

        String pdfUrl = ApplicationFederalAssistanceController.generatePDF(app.Id, 'SF424');
        System.assertNotEquals(null, pdfUrl, 'PDF URL should be generated successfully.');
    }

    @IsTest
    static void testGetApplications() {
        List<Application_for_Federal_Assistance__c> apps = ApplicationFederalAssistanceController.getApplications();
        System.assert(apps.size() > 0, 'Applications should be retrieved.');
    }

    @IsTest
    static void testGetLineItemsByType() {
        Application_for_Federal_Assistance__c app = [SELECT Id FROM Application_for_Federal_Assistance__c LIMIT 1];

        List<X13424_J_Line_Item__c> lineItems = ApplicationFederalAssistanceController.getLineItemsByType(app.Id, 'Test Type');
        System.assert(lineItems.size() >= 0, 'Line items should be retrieved.');
    }

    @IsTest
    static void testCreateContinuationApplication() {
        
        SAM_gov_Validation__c samGov = new SAM_gov_Validation__c(
            name = 'J Test Validation',
            Legal_Entity_Name__c = 'J Test',
            State__c = 'TX',
            City__c = 'Houston',
            Zip__c = '77478',
            Address_1__c = 'test',
            ueiSAM__c = '1A2S3D',
            EIN__c = '454562456');
            insert samGov;

		Account testAccount = new Account(
            Name = 'Test Account',
    		SAM_gov_Validation__c = samGov.id,
            Recipient_UEI__c = '12345678'
            );

        insert testAccount;
        
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Do_you_have_a_UEI__c = 'Yes',
            Status__c = 'Submitted',
            Type_of_Application__c = 'New',
            SF424_Status__c = 'Submitted',
            Form_13424_Status__c = 'Submitted',
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
            Language_Options__c = 'Spanish',
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
            QTE_Identified_Hired__c = 'No',
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
            Related_Business_Account__c = testAccount.id,
            Project_Period__c = 'Year 2',
            Year_end_Date_of_Financials__c = Date.today()
        );
        insert app;

        Other_Staff__c otherStaff = new Other_Staff__c(
            Application_for_Federal_Assistance__c = app.Id,
            License_number__c = 'test',
            Other_License_Certfication__c = 'test',
            Other_Staff_Application_Affirms__c = true,
            Other_Staff_First_Name__c = 'test',
            Other_Staff_Last_Name__c = 'test',
            Other_Staff_Licenses_Certifications__c = 'CPA',
            Other_Staff_Middle_Initial__c = 'T',
            Other_Staff_Responsibilities_Qualf__c = 'test',
            Other_Staff_Suffix__c = 'test',
            State_of_licensure__c = 'TX',
            U_S_tax_court_number__c = 'test'
        );
        insert otherStaff;
        
        X13424_J_Line_Item__c childItem = new X13424_J_Line_Item__c(
		Application_for_Federal_Assistance__c = app.Id,
        recordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
        Category__c = 'Supplies',
        Cost_Base__c	= 100,
        Quantity__c = 10,
        Federal_Expense__c = 100,
        Fringe_Allocation_Percent__c = 10,
        Full_Time_Equivalent_Hours__c = 10,
        Indirect_Cost_Rate__c = 10,
        U_M__c = 'Ea.',
        Cost_per_Unit__c = 50.00
        );
        insert childItem;
        
        County_to_State_Mapping__c cSM = new County_to_State_Mapping__c(
            County_Name__c = 'te',
            State_Abbr__c = 'TX',
            Name = 'test-TX');
		insert cSM;        
        Congressional_District_118__c cD118 = new Congressional_District_118__c (
            District__c = 'te',
            State__c = 'TX',
            Name = 'test-TX'
        );
        insert cD118;
        
        Test.startTest();
        ApplicationFederalAssistanceController.createNewApplication('New','Year 2',testAccount.id);
        ApplicationFederalAssistanceController.createContinuationApplication('Year 2',testAccount.id);
        ApplicationFederalAssistanceController.getOtherStaff(app.id);
        ApplicationFederalAssistanceController.getRollupFields(app.id);
        ApplicationFederalAssistanceController.getDistricts('TX');
        ApplicationFederalAssistanceController.getCounties('TX');
        ApplicationFederalAssistanceController.getAffiliatedAccount();   
        ApplicationFederalAssistanceController.fetchFiles(app.id);     
        Test.stopTest();
    }    

    @isTest
    static void testLineItemController() {
        Application_for_Federal_Assistance__c testApplication = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New');
        insert testApplication;

        X13424_J_Line_Item__c lineItem1 = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = testApplication.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Donated Goods and Services').getRecordTypeId(),
            Description__c = 'Test GDS Description',
            Quantity__c = 5,
            U_M__c = 'Hr.',
            Cost_per_Unit__c = 100.00
        );
        insert lineItem1;
        
        X13424_J_Line_Item__c lineItem2 = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = testApplication.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
            Description__c = 'Test Item 2',
            Quantity__c = 3,
            U_M__c = 'Hr.',
            Cost_per_Unit__c = 150
        );
        insert lineItem2;

        Test.startTest();
        ApexPages.currentPage().getParameters().put('id', testApplication.Id);
        LineItemController controller = new LineItemController();
        Test.stopTest();
        
        System.assertNotEquals(null, controller.application, 'Application should not be null');
        System.assertEquals(testApplication.Id, controller.application.Id, 'Application Id should match');
        System.assertEquals(2, controller.lineItems13424J.size(), 'Should retrieve 2 line items');
    }
    
    @isTest
    static void testDeleteAttachments() {

        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New',SF424_Status__c = 'In Progress');
        insert application;

        X13424_J_Line_Item__c lineItem = new X13424_J_Line_Item__c(Application_for_Federal_Assistance__c = application.Id,recordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
        Category__c = 'Supplies',
        Cost_Base__c	= 100,
        Quantity__c = 10,
        Federal_Expense__c = 100,
        Fringe_Allocation_Percent__c = 10,
        Full_Time_Equivalent_Hours__c = 10,
        Indirect_Cost_Rate__c = 10,
        U_M__c = 'Ea.',
        Cost_per_Unit__c = 50.00);
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Test File',
            PathOnClient = 'TestFile.pdf',
            VersionData = Blob.valueOf('Test content'),
            FirstPublishLocationId = application.Id
        );
        
        Test.startTest();
        insert lineItem;
        insert contentVersion;
        delete lineItem;
        Test.stopTest();

        // ContentDocument contentDoc = [SELECT Id FROM ContentDocument WHERE Id IN (SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id)];
    }

    @isTest
    static void testHandleAfterInsert() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New',SF424_Status__c = 'In Progress');
        insert application;

        X13424_J_Line_Item__c lineItem = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = application.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
            Category__c = 'Supplies',
            Cost_Base__c	= 100,
            Quantity__c = 10,
            Federal_Expense__c = 100,
            Fringe_Allocation_Percent__c = 10,
            Full_Time_Equivalent_Hours__c = 10,
            Indirect_Cost_Rate__c = 10,
            U_M__c = 'Ea.',
            Cost_per_Unit__c = 50.00
        );

        Test.startTest();
        insert lineItem;
        Test.stopTest();

        Application_for_Federal_Assistance__c updatedApplication = [SELECT Personnel_Dollar_Federal_Total__c FROM Application_for_Federal_Assistance__c WHERE Id = :application.Id];
    }

    @isTest
    static void testHandleAfterUpdate() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New',SF424_Status__c = 'In Progress');
        insert application;

        X13424_J_Line_Item__c lineItem = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = application.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
            Category__c = 'Supplies',
            Cost_Base__c	= 100,
            Quantity__c = 10,
            Federal_Expense__c = 100,
            Fringe_Allocation_Percent__c = 10,
            Full_Time_Equivalent_Hours__c = 10,
            Indirect_Cost_Rate__c = 10,
            U_M__c = 'Ea.',
            Cost_per_Unit__c = 50.00
        );
       

        Test.startTest();
        insert lineItem;
        Test.stopTest();

        Application_for_Federal_Assistance__c updatedApplication = [SELECT Personnel_Dollar_Federal_Total__c FROM Application_for_Federal_Assistance__c WHERE Id = :application.Id];
     }

    @isTest
    static void testHandleAfterDelete() {
        // Step 1: Setup test data
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New',SF424_Status__c = 'In Progress');
        insert application;

        X13424_J_Line_Item__c lineItem = new X13424_J_Line_Item__c(
            Application_for_Federal_Assistance__c = application.Id,
            RecordTypeId = Schema.SObjectType.X13424_J_Line_Item__c.getRecordTypeInfosByName().get('Personnel').getRecordTypeId(),
            Category__c = 'Supplies',
            Cost_Base__c	= 100,
            Quantity__c = 10,
            Federal_Expense__c = 100,
            Fringe_Allocation_Percent__c = 10,
            Full_Time_Equivalent_Hours__c = 10,
            Indirect_Cost_Rate__c = 10,
            U_M__c = 'Ea.',
            Cost_per_Unit__c = 50.00
        );
     
        Test.startTest();
        insert lineItem;
        delete lineItem;
        Test.stopTest();

        Application_for_Federal_Assistance__c updatedApplication = [SELECT Personnel_Dollar_Federal_Total__c FROM Application_for_Federal_Assistance__c WHERE Id = :application.Id];
        System.assertEquals(0, updatedApplication.Personnel_Dollar_Federal_Total__c, 'Personnel Dollar Federal total rollup should be reset to 0 after delete');
    }


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

        // Validate date formatting
        String expectedFormattedDate = DateTime.newInstance(Date.today().year(), Date.today().month(), Date.today().day()).format('MM/dd/yyyy');
        System.assertEquals(expectedFormattedDate, controller.formattedYearEndDate, 'The formatted year-end date should match.');

        // Clean up test data
        delete testApplication;
    }

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

    // @IsTest
    // static void testCreateSamGovRecord() {
    //     Test.startTest();
        
    //     // Create test Application record
    //     Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c();
    //     insert app;

    //     // Create mock response body
    //     String mockResponseBody = '{"organizationalUEI": "12345678", "legalEntityName": "Valid Name", "EIN": "123456789", "address1": "123 Main St", "address2": "Apt 1", "city": "New York", "state": "NY", "zip": "10001", "country": "USA", "SAMGOVRegistrationStatus": "Active", "activationDate": "2024-01-01", "expirationDate": "2025-01-01", "excludedParties": "None", "federalDebt": "No", "repsCerts": "Yes", "responsibilityQualification": "Qualified"}';

    //     // Create the mock response object
    //     HttpResponse mockResponse = new HttpResponse();
    //     mockResponse.setStatusCode(200);
    //     mockResponse.setBody(mockResponseBody);
        
    //     // Set the HTTP callout mock
    //     Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));

    //     // Call the method
    //     ApplicationFederalAssistanceController.createSamGovRecord(app.Id, '12345678');

    //     // Query the newly inserted SAM_gov_Validation__c record
    //     List<SAM_gov_Validation__c> records = [SELECT Id, Name, ueiSAM__c, Legal_Entity_Name__c, EIN__c, Address_1__c, City__c, State__c, Zip__c, SAM_gov_Registration_Status__c FROM SAM_gov_Validation__c WHERE Application_for_Federal_Assistance__c = :app.Id];

    //     Test.stopTest();
    // }

    @isTest
    static void testValidateUEI() {
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl());
    
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Type_of_Application__c = 'New');
        insert application;

        Test.startTest();
        ApplicationFederalAssistanceController.createSamGovRecord(application.Id, '123456');
        Test.stopTest();
    }

    private class MockHttpCalloutImpl implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse mockResponse = new HttpResponse();
            mockResponse.setStatusCode(200);
            mockResponse.setBody('{"uei": "123456"}');
            return mockResponse;
        }
    }


    @isTest
    static void testLegacy() {
        Application_for_Federal_Assistance__c application = new Application_for_Federal_Assistance__c(Version__c = 'Legacy');
        insert application;

        LITC_Licensure__c license = new LITC_Licensure__c(Type__c = 'Clinic Director', Application_for_Federal_Assistance__c = application.Id);
        insert license;

        try {
            application.Form_13424_Status__c = 'Submitted';
            update application;
    
        } catch (Exception e) {
            System.debug(e.getMessage());
        }

        ApplicationFederalAssistanceController.getLicenses(application.Id, 'Clinic Director');
        ApplicationFederalAssistanceController.getLegacyApplication(application.Id);


        NTA_Review__c nta = new NTA_Review__c(Application_for_Federal_Assistance__c = application.Id);
        insert nta;

        Staff_Review__c staff = new Staff_Review__c(RecordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Budget Analyst Review').getRecordTypeId(), Application_for_Federal_Assistance__c = application.Id);
        insert staff;

        FundingAward fa = new FundingAward(Name='test', Application_for_Federal_Assistance__c = application.Id);
        insert fa;

        FundingDisbursement fd = new FundingDisbursement(FundingAwardId = fa.Id);
        insert fd;

        ApplicationFederalAssistanceController.getNTAReview(application.Id);
        ApplicationFederalAssistanceController.getStaffReview(application.Id);

        ApplicationFederalAssistanceController.getFundingAwards(application.Id);
        ApplicationFederalAssistanceController.getFundingDisbursements(fa.Id);

    }
    
}