/**
 *  Main controller for handling actions related to Application for Federal Assistance.
 */
public with sharing class ApplicationFederalAssistanceController {

    /**
     * Function to generate a PDF for an application
     *
     * @param recordId ID of the application 
     * @param name The name of form to generate
     * @return The public URL for the generated PDF.
     */
    @AuraEnabled
    public static string generatePDF(String recordId, String name){
        PageReference pdf;

        // rework these...
        if(name == 'SF424') pdf = Page.SF424PDF;
        if(name == '13424-J') pdf = Page.SF13424JPDF;
        if(name == '13424-M') {
            pdf = Page.SF13424MPDF;
            pdf.getParameters().put('caller','SF13424M');
        }

        // legacy form
        if(name == '13424') {
            pdf = Page.LITCLegacy13424;
            Legacy_13424_Application__c legacyApp = [SELECT ID, Name FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c =: recordId LIMIT 1];
            pdf.getParameters().put('id', legacyApp.ID);
        }
    
        if(name != '13424'){ 
            pdf.getParameters().put('id',recordId);
        }
        
        Blob body;
        
        try {
            body = pdf.getContent();
        } catch (VisualforceException e) {
            body = Blob.valueOf('PDF FAILED TO GENERATE');
        }

        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S'; 
        cVersion.PathOnClient = name + '.pdf';
        cVersion.Origin = 'C';
        cVersion.OwnerId = system.UserInfo.getUserId();
        cVersion.Title = name + '.pdf';
        cVersion.File_Prefix__c = name;
        cVersion.VersionData = body;
        Insert cVersion;
        
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;

        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;
        cDocLink.LinkedEntityId = recordId;
        cDocLink.ShareType = 'I';
        cDocLink.Visibility = 'AllUsers';
        Insert cDocLink;

        ContentDistribution cd = new ContentDistribution();
        cd.Name = name;
        cd.ContentVersionId = cVersion.Id;
        cd.PreferencesAllowViewInBrowser= true;
        cd.PreferencesLinkLatestVersion=true;
        cd.PreferencesNotifyOnVisit=false;
        cd.PreferencesPasswordRequired=false;
        cd.PreferencesAllowOriginalDownload= true;
        insert cd;  
        
        cd = [select Id, DistributionPublicUrl from ContentDistribution where Id = :cd.Id limit 1];
        return cd.DistributionPublicUrl;
    }

    /**
     * Gets the list of all applications
     *
     * @return list of Application_for_Federal_Assistance__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Application_for_Federal_Assistance__c> getApplications() {
        List<Application_for_Federal_Assistance__c> apps = new List<Application_for_Federal_Assistance__c>();
        for (Application_for_Federal_Assistance__c app : [SELECT Id, Name, Submission_Deadline__c, Status__c, Type_of_Application__c, Funding_Decision_Recipient_Response__c, Version__c FROM Application_for_Federal_Assistance__c]){ 
            apps.add(app);
        }
        return apps;
    }

    /**
     * Gets the list of all line items for an application by record type.
     *
     * @param appId Id of the application
     * @param type The record type name of the line item
     * @return list of X13424_J_Line_Item__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<X13424_J_Line_Item__c> getLineItemsByType(String appId, String type) {
        List<X13424_J_Line_Item__c> lineItems = new List<X13424_J_Line_Item__c>();

        for (X13424_J_Line_Item__c item : [
            SELECT 
                Id, Description__c, Quantity__c, U_M__c, Cost_per_Unit__c, Total__c, Notes__c,   
                Personnel_Name__c, Position__c, LITC_FTE__c, Total_Allocated_Salary__c, Dollar_Federal__c, Dollar_Match__c,
                Total_Cost__c, Total_Allocated_Cost__c,
                Category__c, Percentage__c, 
                Indirect_Cost_Federal__c, Indirect_Cost_Rate_Type__c, Agency_who_issued_ICRA__c, 
                Matching_Funds_Type__c, Matching_Funds_Amont__c
            FROM X13424_J_Line_Item__c WHERE Application_for_Federal_Assistance__c =: appId AND RecordType.name =: type]){ 
            lineItems.add(item);
        }
        return lineItems;
    }

    /**
     * Gets the list of Other Staff records for an application
     *
     * @param appId Id of the application
     * @return A list of Other_Staff__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Other_Staff__c> getOtherStaff(String appId) {
        List<Other_Staff__c> lineItems = new List<Other_Staff__c>();

        for (Other_Staff__c item : [
            SELECT 
                Id, Other_Staff_Application_Affirms__c, Name, Application_for_Federal_Assistance__c, Other_Staff_First_Name__c, 
                Other_Staff_Last_Name__c, Other_Staff_Licenses_Certifications__c, Other_Staff_Middle_Initial__c, Other_Staff_Responsibilities_Qualf__c, 
                Other_Staff_Suffix__c, Other_License_Certfication__c
            FROM Other_Staff__c WHERE Application_for_Federal_Assistance__c =: appId]){ 
            lineItems.add(item);
        }
        return lineItems;
    }

    /**
     * Gets the list of license records for an application
     *
     * @param appId Id of the application
     * @return A list of LITC_Licensure__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<LITC_Licensure__c> getLicenses(String appId, String type) {
        List<LITC_Licensure__c> licenses = new List<LITC_Licensure__c>();

        for (LITC_Licensure__c item : [SELECT Id, Name, Other_explanation__c, Type__c, U_S_Tax_Court_number__c, Application_Affirmation__c, Application_for_Federal_Assistance__c, Jurisdiction__c, License_number__c, Licensure__c FROM LITC_Licensure__c WHERE Application_for_Federal_Assistance__c =: appId AND Type__c =: type]){ 
            licenses.add(item);
        }
        return licenses;
    }

    /**
     * Gets the rollup summary fields for an application
     *
     * @param recordId Id of the application
     * @return The Application_for_Federal_Assistance__c record
     */
    @AuraEnabled(cacheable=true)
    public static Application_for_Federal_Assistance__c getRollupFields(String recordId) {
        Application_for_Federal_Assistance__c app = [
            SELECT ID, Donated_Goods_and_Services_Total__c, Personnel_Dollar_Federal_Total__c, Personnel_Dollar_Match_Total__c, 
                Fringe_Dollar_Federal_Total__c, Fringe_Dollar_Match_Total__c, Supplies_etc_Dollar_Federal_Total__c, Supplies_etc_Dollar_Match_Total__c, 
                Indirect_Expenses_Federal_Total__c, Matching_Funds_Total__c, Total_Matching_Funds__c
            FROM Application_for_Federal_Assistance__c WHERE Id =: recordId];
        return app;
    }

    /**
     * Validates a UEI and creates the SAM.gov record if it does not exist
     *
     * @param applicationId The Id of the application
     * @param uei The UEI to validate
     */
    @AuraEnabled
    public static void createSamGovRecord(String applicationId, String uei) {
        try {
            List<SAM_gov_Validation__c> records= [SELECT Id, Name, ueiSAM__c, Application_for_Federal_Assistance__c FROM SAM_gov_Validation__c WHERE ueiSAM__c =: uei AND Application_for_Federal_Assistance__c =: applicationId];

            if (records.isEmpty()) { 
                SAM_gov_Validation__c sam = new SAM_gov_Validation__c();
                Map<String, Object> samResults = new Map<String, Object>();
                samResults = SamGovCalloutHelper.validateUEI(uei);

                if(samResults != null){ 
                    sam.ueiSAM__c = (String)samResults.get('organizationalUEI');
                    sam.Legal_Entity_Name__c = (String)samResults.get('legalEntityName');
                    sam.EIN__c = (String)samResults.get('EIN');
                    sam.Address_1__c = (String)samResults.get('address1');
                    sam.Address_2__c = (String)samResults.get('address2');
                    sam.City__c = (String)samResults.get('city');
                    sam.State__c = (String)samResults.get('state');
                    sam.Zip__c = (String)samResults.get('zip');
                    sam.Country__c = (String)samResults.get('country'); 
    
                    sam.SAM_gov_Registration_Status__c = (String)samResults.get('SAMGOVRegistrationStatus'); 
                    sam.Activation_Date__c = (String)samResults.get('activationDate') != null ? Date.valueOf((String)samResults.get('activationDate')) : null; 
                    sam.Expiration_Date__c = (String)samResults.get('expirationDate') != null ? Date.valueOf((String)samResults.get('expirationDate')) : null;
                    sam.Excluded_Parties__c = (String)samResults.get('excludedParties'); 
                    sam.Federal_Debt__c = (String)samResults.get('federalDebt'); 
                    sam.Reps_Certs__c = (String)samResults.get('repsCerts'); 
                    sam.Responsibility_Qualification__c = (String)samResults.get('responsibilityQualification'); 
                    sam.Congressional_District__c = (String)samResults.get('congressionalDistrict');
                    
    
                    sam.Name = (String)samResults.get('organizationalUEI');
                    sam.Application_for_Federal_Assistance__c = applicationId;
    
                    insert sam;
                }
            }
        
        } catch (Exception e) {System.debug(e.getMessage());}
    }

    /**
     * Gets a list of counties for a given state
     *
     * @param state The state to get the counties for
     * @return list of County_to_State_Mapping__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<County_to_State_Mapping__c> getCounties(String state) {
        List<County_to_State_Mapping__c> counties = new List<County_to_State_Mapping__c>();
        for (County_to_State_Mapping__c county : [SELECT Id, County_Name__c, State_Abbr__c, Name FROM County_to_State_Mapping__c WHERE State_Abbr__c =: state ORDER BY County_Name__c ASC]){ 
            counties.add(county);
        }
        return counties;
    }

    /**
     * Gets a list of districts for a given state
     *
     * @param state The state to get the districts for
     * @return list of Congressional_District_118__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Congressional_District_118__c> getDistricts(String state) {
        List<Congressional_District_118__c> districts = new List<Congressional_District_118__c>();
        for (Congressional_District_118__c district : [SELECT Id, District__c, State__c, Name FROM Congressional_District_118__c WHERE State__c =: state ORDER BY District__c ASC]){ 
            districts.add(district);
        }
        return districts;
    }

    /**
     * Gets the account of the currently logged-in user
     *
     * @return The Account ID of the current logged-in user
     */
    @AuraEnabled(cacheable=true)
    public static string getAffiliatedAccount() {
        String currentUserId = System.UserInfo.getUserId();
        String accountId = null;
        
        User u = [SELECT Id, ContactId, Contact.AccountId FROM User WHERE Id = :currentUserId limit 1];
        if(u.ContactId != null) { 
          accountId = u.Contact.AccountId; 
        }
        return accountId;   
    }

    /**
     * Gets a list of files for a record
     *
     * @param recordId The Id of the application
     * @return list of ContentDocumentLink records 
     */
    @AuraEnabled
    public static List<ContentDocumentLink> fetchFiles(String recordId) {
        try {
            List<ContentDocumentLink> getFiles = [SELECT ContentDocumentId, ContentDocument.ContentModifiedDate, ContentDocument.OwnerId, ContentDocument.Title,ContentDocument.ContentSize, LinkedEntityId, ContentDocument.CreatedDate, ContentDocument.FileType FROM ContentDocumentLink WHERE LinkedEntityId =: recordId Order by ContentDocument.CreatedDate desc];                      
            return getFiles;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Creates a new Application for Federal Assistance record
     * If the Account has a Recipient UEI, it validates the UEI and autopopulates the results
     *
     * @param appType The type of application 
     * @param projectPeriod The project period for the application
     * @param accountId The Id of the account
     * @return The created Application_for_Federal_Assistance__c record
     */
    @AuraEnabled
    public static Application_for_Federal_Assistance__c createNewApplication(String appType, String projectPeriod, String accountId) {
        Account acct = [SELECT ID, Recipient_UEI__c FROM Account WHERE Id =: accountId];
        Map<String, Object> samResults = new Map<String, Object>();
        Application_for_Federal_Assistance__c newApp = new Application_for_Federal_Assistance__c();
        newApp.Project_Period__c = projectPeriod;
        newApp.Related_Business_Account__c = accountId;
        newApp.Type_of_Application__c = appType;

        if (acct.Recipient_UEI__c != null) {
            try{ 
                samResults = SamGovCalloutHelper.validateUEI(acct.Recipient_UEI__c);
                System.debug(samResults);

                if(samResults != null){ 
                    newApp.Do_you_have_a_UEI__c = 'Yes';
                    newApp.UEI_Sam_gov_Validation_Status__c = true;
                    newApp.Legal_Name__c = (String)samResults.get('legalEntityName');
                    newApp.Street_1__c = (String)samResults.get('address1');
                    newApp.Street_2__c = (String)samResults.get('address2');
                    newApp.Employer_Taxpayer_Number__c = (String)samResults.get('EIN');
                    newApp.City__c = (String)samResults.get('city');
                    newApp.State__c = (String)samResults.get('state');
                    newApp.Country__c = (String)samResults.get('country'); 
                    newApp.Zip_Postal_Code__c = (String)samResults.get('zip');
                    newApp.Organizational_UEI__c = (String)samResults.get('organizationalUEI');
                }
            } catch(Exception e){ 
                System.debug(e.getMessage());
            }
        }

        insert newApp;
        return newApp;
    }

    @AuraEnabled
    public static Application_for_Federal_Assistance__c createContinuationApplication(String projectPeriod, String accountId) {
        try {
            Application_for_Federal_Assistance__c mostRecentApplication = [
                SELECT Related_Business_Account__c, Id, Clinic_Name__c, Clinic_Public_telephone_number__c, Clinic_Toll_Free_tele_num_if_applicable__c, Clinic_FAX_number__c, 
                Clinic_Website_address_if_applicable__c, Clinic_Street__c, Is_clinic_address_same_mailing__c, Clinic_Mailing_Address__c, 
                Clinic_Services_and_Delivery_Model__c, Representation__c, Organization_Overview__c, 
                Type_of_Services_Provided__c, Experience__c, Language_Access__c, In_Person_or_On_Staff_Assistance__c, 
                Language_Options__c, Other_Language_Options__c, All_other_Languages_Interpreter_Services__c, All_Languages_other_than_English__c, 
                Reasonable_Accommodations__c, Geographic_Area_and_Target_Audience__c, Partners_and_Networks__c, 
                Publicity_and_Outreach_Methods__c, Participation_in_Programs__c, Participation_Types__c, Future_Participation__c, 
                Controversy_Representation_Scope__c, Consulation_Service_to_be_provided__c, Taxpayer_Education__c, Advocacy__c, 
                QTE_Position_filled_by_Volunteer__c, QTE_Identified_Hired__c, QTE_Last_name__c, QTE_First_name__c, QTE_Middle_initial__c, 
                QTE_Suffix__c, QTE_Telephone_number__c, QTE_Email_address__c, QTE_Licenses_Certifications__c, QTE_Other_Licenses_Certifications__c, 
                QTE_State_s_of_Licensure__c, QTE_License_Number__c, QTE_US_Tax_Court_Number__c, QTE_Application_Affirms__c, QTE_Responsibilities_Qualifications__c,
                QTE_Job_Description__c, Dual_Role__c, Clinic_Director_Identified_Hired__c, Clinic_Director_Last_name__c, Clinic_Director_First_name__c, 
                Clinic_Director_Middle_initial__c, Clinic_Director_Suffix__c, Clinic_Director_Telephone_number__c, Clinic_Director_Email_address__c, 
                Clinic_Director_Licenses_Certifications__c, Clinic_Director_Other_Licenses_Cert__c, Clinic_Director_State_s_of_Licensure__c, 
                Clinic_Director_License_Number__c, Clinic_Director_US_Tax_Court_Number__c, Clinic_Director_Application_Affirms__c, CD_Responsibilities_Qualifications__c, 
                Clinic_Director_Job_Description__c, Dual_QBA__c, QBA_Identified_Hired__c, QBA_Last_name__c, QBA_First_name__c, QBA_Middle_initial__c, QBA_Suffix__c, 
                QBA_Telephone_number__c, QBA_Email_address__c, QBA_Licenses_Certifications__c, QBA_Responsibilities_Qualifications__c, QBA_Job_Description__c, 
                TCO_Last_name__c, TCO_First_name__c, TCO_Middle_initial__c, TCO_Suffix__c, TCO_Telephone_number__c, TCO_Email_address__c, TCO_Title__c, 
                US_Tax_Court_Narrative__c, Student_Narrative__c, Student_s_Per_Semester_Type__c, Student_Special_Appearance_Authorizing__c, Student_Permission_to_be_Obtained__c,
                Volunteer_Pro_Bono_Panel__c, Other_Volunteer_Recruitment__c, Volunteer_Recruitment_and_Retention__c, Dates_of_Operation__c, 
                Reduction_in_Services__c, Continuity_of_Services__c, 
                Day_1_Hours__c, Day_2_Hours__c, Day_3_Hours__c, Day_4_Hours__c, Day_5_Hours__c, Day_6_Hours__c, Day_7_Hours__c,
                Hours_Exceptions_for_Emergencies__c, After_Hours_or_Weekend_Service__c, Intake_Process__c, Household_Income_Exceeding_250_of_Pover__c, 
                Cases_Exceeding_250_of_FPL_Description__c, Amount_in_Controversy_Limit__c, Cases_Exceed_Amt_in_Contro_Limit_Desc__c, 
                Nominal_Fee__c, Nominal_Fee_Description__c, Case_Management_System__c, Case_Assignment_Procedures__c, Case_Monitoring__c, 
                Time_Tracking__c, Collecting_Taxpayer_Information__c, Protecting_Taxpayer_Privacy__c, Complaint_Procedures__c, 
                Training_and_Resources__c, In_house_Training__c, External_Training__c, Research_Materials_and_Software__c, 
                Experience_Managing_Grants__c, Accounting_Procedures__c, Free_Tax_Preparation__c, VITA_or_TCE_Site_Funding__c, Tracking_Grant_Expenditures__c, 
                Audits_or_Financial_Reviews__c, Financial_Statement_Information__c, Financial_Statement_Type__c, Single_Audit_Compliance__c, 
                Audit_Clearinghouse_Availability__c, Legal_Services_Corporation_Funding__c, Year_end_Date_of_Financials__c,
                Program_Evaluation__c, Program_Improvement__c, Program_Numerical_Goals_Narrative__c, Numerical_goals_for_year_one__c, 
                New_Representation_Cases__c, Consultations_with_Low_Income_ESL__c, Educational_Activates_to_Low_Income__c, Low_Income_ESL_TP_Service_Providers__c, 
                Active_Lawsuits_or_Complaints__c, List_of_Active_Lawsuits_or_Complaints__c, Federal_Financial_Assistance__c, Civil_Rights_Review_Activity__c, 
                Data_Compilation_and_Maintenance__c, Public_Display_of_Civil_Rights_Poster__c, 
                Full_Time_Equivalent_Hours__c, Effort_on_obtaining_a_UEI__c, Organizational_UEI__c, UEI_Sam_gov_Validation_Status__c, 
                Legal_Name__c, Employer_Taxpayer_Number__c, Street_1__c, Street_2__c, City__c, State__c, County__c, 
                Zip_Postal_Code__c, Country__c, Province__c, First_Name__c, Middle_Name__c, Last_Name__c, 
                Department_Name__c, Division_Name__c, Suffix__c, Organization_Unit_Title__c, Organizational_Affliation__c, 
                Telephone_Number__c, Email__c, Fax__c, Type_of_Applicant_1__c, Type_of_Application_1_Other__c, 
                Congressional_district_by_project__c, Areas_affected_by_project__c, Auth_Rep_First_Name__c, 
                Auth_Rep_Middle_Name__c, Auth_Rep_Last_Name__c, Auth_Rep_Title__c, Auth_Rep_Number__c, Auth_Rep_Email__c, Auth_Rep_Fax__c, Grant_Year__c
                
                FROM Application_for_Federal_Assistance__c WHERE (Status__c = 'Submitted' OR Status__c = 'Amendment Submitted') AND Related_Business_Account__c =: accountId ORDER BY Grant_Year__c DESC LIMIT 1];

       
                // clone child records.
                Application_for_Federal_Assistance__c clonedApp = mostRecentApplication.clone(false, true, false, false);
                clonedApp.Project_Period__c = projectPeriod;
                clonedApp.Related_Business_Account__c = accountId;
                clonedApp.Type_of_Application__c = 'Continuation';
                clonedApp.Previous_Application__c = mostRecentApplication.Id;
                insert clonedApp;
                system.debug('RS999 clonedApp :' +clonedApp);
                Id parentId = mostRecentApplication.Id;
                system.debug('RS999 parentId  :' +parentId );
                List<Other_Staff__c> relatedOtherStaff = [
                    SELECT Id, Name, Application_for_Federal_Assistance__c, License_number__c, Other_License_Certfication__c, 
                    Other_Staff_Application_Affirms__c, Other_Staff_First_Name__c, Other_Staff_Last_Name__c, Other_Staff_Licenses_Certifications__c, Other_Staff_Middle_Initial__c, 
                    Other_Staff_Responsibilities_Qualf__c, Other_Staff_Suffix__c, State_of_licensure__c, U_S_tax_court_number__c 
                    FROM Other_Staff__c 
                    WHERE Application_for_Federal_Assistance__c = :parentId
                ];
            
			system.debug('RS999 relatedOtherStaff  :' +relatedOtherStaff );
            
            List<Other_Staff__c> clonedOtherStaff = new List<Other_Staff__c>();
            for (Other_Staff__c record : relatedOtherStaff) {
                Other_Staff__c clonedRecord = record.clone(false, true, false, false);
                clonedRecord.Application_for_Federal_Assistance__c = clonedApp.Id;
                clonedOtherStaff.add(clonedRecord);
            }

            if (!clonedOtherStaff.isEmpty()) {
                insert clonedOtherStaff;
            }

            Schema.DescribeSObjectResult describeResult = Schema.getGlobalDescribe().get('X13424_J_Line_Item__c').getDescribe();
            List<String> fieldNames = new List<String>();
            for (Schema.SObjectField field : describeResult.fields.getMap().values()) {
                fieldNames.add(field.getDescribe().getName());
            }
            String query = 'SELECT ' + String.join(fieldNames, ', ') + ' FROM X13424_J_Line_Item__c' +
                        ' WHERE Application_for_Federal_Assistance__c' + ' = :parentId';
            List<X13424_J_Line_Item__c> relatedLineItems = Database.query(query);

            List<X13424_J_Line_Item__c> clonedLineItems = new List<X13424_J_Line_Item__c>();
            for (X13424_J_Line_Item__c record : relatedLineItems) {
                X13424_J_Line_Item__c clonedRecord = record.clone(false, true, false, false);
                clonedRecord.Application_for_Federal_Assistance__c = clonedApp.Id;
                clonedLineItems.add(clonedRecord);
            }

            if (!clonedLineItems.isEmpty()) {
                insert clonedLineItems;
            }
            
            return clonedApp;
        } catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
    }

    /**
     * Validates a UEI and returns the response 
     *
     * @param uei The UEI to validate
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> validateUEI(String uei){ 
        return SamGovCalloutHelper.validateUEI(uei);
    }


    /**
     * Gets the legacy application record for an application
     *
     * @param appId Id of the application
     * @return The Legacy_13424_Application__c record
     */
    @AuraEnabled(cacheable=true)
    public static List<Legacy_13424_Application__c> getLegacyApplication(String appId) {
        List<Legacy_13424_Application__c> myApps = new List<Legacy_13424_Application__c>();
        for(Legacy_13424_Application__c app : [SELECT ID, Name FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c =: appId LIMIT 1]){ 
            myApps.add(app);
        }
        return myApps;
    }

    /**
     * Gets the NTA Review record for an application
     *
     * @param appId Id of the application
     * @return The NTA_Review__c record
     */
    @AuraEnabled(cacheable=true)
    public static List<NTA_Review__c> getNTAReview(String appId) {
        List<NTA_Review__c> myApps = new List<NTA_Review__c>();
        for(NTA_Review__c app : 
            [SELECT ID, Name, NTA_Award_Amount__c, Funding_Decision_Reason__c, Funding_Decision_Status__c
            , Application_for_Federal_Assistance__c, Review_Status__c, NTA_Conditions__c, NTA_Conditions_Other__c,  BA_Summary__c 
            FROM NTA_Review__c WHERE Application_for_Federal_Assistance__c =: appId LIMIT 1]){ 
            myApps.add(app);
        }
        return myApps;
    }

    @AuraEnabled(cacheable=true)
    public static List<Staff_Review__c> getStaffReview(String appId) {
        List<Staff_Review__c> myApps = new List<Staff_Review__c>();
        for(Staff_Review__c app : [SELECT ID, Name, Personnel__c, Fringe_Benefits__c, Travel__c, Equipment__c, Supplies__c, Contractual__c, Other_Expenses__c, Indirect_Charges__c, Matching_Fund__c FROM Staff_Review__c WHERE Application_for_Federal_Assistance__c =: appId AND RecordType.Name = 'Budget Analyst Review' LIMIT 1]){ 
            myApps.add(app);
        }
        return myApps;
    }

    @AuraEnabled(cacheable=true)
    public static List<FundingAward> getFundingAwards(String appId) {
        List<FundingAward> myApps = new List<FundingAward>();
        for(FundingAward app : [SELECT ID, Name, Status, Amount, Disbursement_Total__c, Review_Status__c FROM FundingAward WHERE Application_for_Federal_Assistance__c =: appId]){ 
            myApps.add(app);
        }
        return myApps;
    }

    @AuraEnabled(cacheable=true)
    public static List<FundingDisbursement> getFundingDisbursements(String awardId) {
        List<FundingDisbursement> myApps = new List<FundingDisbursement>();
        for(FundingDisbursement app : [SELECT ID, Name, Amount, Status, Recipient_Comments__c, Recipient_Status__c, DisbursementDate FROM FundingDisbursement WHERE FundingAwardId =: awardId]){ 
            myApps.add(app);
        }
        return myApps;
    }
}