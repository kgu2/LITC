/**
 * Contains trigger handler functions and logic for Application_for_Federal_Assistance__c
 * Contains validations when the application is submitted and logic for inserting/updating the related IndividualApplication
 */
public with sharing class ApplicationforFederalAssiTriggerHandler {

    private Static List<String> errorMessages = new List<String>();   
   
    /**
     * Before Update Trigger Handler. Performs field validations on submit. Validates attachments and licenses.
     * @param newList List of new Application_for_Federal_Assistance__c records.
     * @param oldMap Map of old Application_for_Federal_Assistance__c records.
     */
    public static void beforeUpdate(List<Application_for_Federal_Assistance__c> newList, Map<Id, Application_for_Federal_Assistance__c> oldMap) {

        validateAttachments(oldMap,newList);

        Set<Id> appIdsQTE = new Set<Id>();
        Set<Id> appIds = new Set<Id>();
        List<Id> amendIds = new List<Id>();

        for (Application_for_Federal_Assistance__c record : newList) {
            appIds.add(record.Id);
            Application_for_Federal_Assistance__c oldRecord = oldMap.get(record.Id);

            if ((oldRecord.get('SF424_Status__c') != 'Submitted' && record.get('SF424_Status__c') == 'Submitted')) {
                validateSF424Fields(record);
            }
           
            if (oldRecord.get('Form_13424_Status__c') != 'Submitted' && record.get('Form_13424_Status__c') == 'Submitted' && record.get('Version__c') != 'Legacy') {
                validateForm13424Fields(record);

                if(record.QTE_Identified_Hired__c == 'Yes'){
                    appIdsQTE.add(record.Id);
                }
                
                if (record.get('Type_of_Application__c') == 'Continuation') {
                    // 2.4.25 continuation commented out for now, will open next year
                    // 9.18.25 uncommented
                    validateContinuationFields(record);
                }
            }
            if(oldRecord.get('Status__c') != 'Amendment In Progress'&& record.get('Status__c') == 'Amendment In Progress'){
                amendIds.add(record.Id);
            }

        }

        if (!appIdsQTE.isEmpty()) {
            validateLicenses(appIdsQTE, newList);
        }
        if(!amendIds.isEmpty()){
            ApplicationSnapshotController.createSnapshots(amendIds);
        }
        
        // valdiating legacy application
        Map<Id, Legacy_13424_Application__c> legacyAppMap = new Map<Id, Legacy_13424_Application__c>();
        for (Legacy_13424_Application__c legacyApp : [
            SELECT Id, Name, Application_for_Federal_Assistance__c, 
            Applicant_Experience__c, Applicant_Affliations__c, Applicant_Supervising_Experience__c, Applicant_Networking_Experience__c ,Accounting_Procedures_and_Support_Staff__c, 
            Exp_Tracking_and_Verifying_Method__c, VITA_Site__c, Audits_and_Controls_Plans__c, Financial_Statement__c, QBA_Name_and_Qualifications__c, 
            Qualified_Tax_Expert_QTE__c, Clinic_Director__c, Clinic_Staff__c ,Student_s_Per_Semester_Type__c ,Clinic_Staff_Authorized_to_Represent__c, 
            Time_Tracking__c, Geographic_Area_and_Target_Audience__c, Representation_Services_Type__c ,Consulation_Service_to_be_provided__c ,Educational_Activities_to_be_provided__c,  
            Service_Delivery_Tracking_Plans__c, Publicity_and_Outreach_Methods__c, Clinic_Operation_Hours__c ,Nominal_Fee__c ,In_house_Training__c,  
            Continuing_Professional_Education_CPE__c, Tax_Library_and_Research_Resources__c, Strategy_for_Monitoring_Program_Results__c ,Indicate_Measure_Client_Satisfaction__c ,Educa_Activ_to_Low_Income_First_Year__c, 
            Low_Income_ESL_to_be_reached_First_Year__c, Active_Lawsuits_or_Complaints__c, Federal_Financial_Assistance__c, Civil_Rights_Review_Activity__c, Reasonable_Accommodations__c,
            Data_Compilation_and_Maintenance__c, Public_Display_of_Civil_Rights_Poster__c, 
            Legal_name_of_sponsoring_organization__c, Last_Name__c, First_Name__c, Title__c, Phone_number__c,
            Email_address__c, Street__c, City__c, State__c, ZIP_4_code__c,
            Name_of_clinic__c, Public_telephone_number__c, Clinic_Street__c, Clinic_City__c, Clinic_State__c, Clinic_ZIP_4_code__c,
            Clinic_Mailing_Street__c, Clinic_Mailing_City__c, Clinic_Mailing_State__c, Clinic_Mailing_Zip_4_code__c,
            Clinic_Director_Last_Name__c, Clinic_Director_First_Name__c, Clinic_Director_Telephone_number__c, Clinic_Director_Email_address__c, 
            QTE_Last_name__c, QTE_First_name__c, QTE_Telephone_number__c, QTE_Email_address__c,
            QBA_Last_name__c, QBA_First_name__c, QBA_Telephone_number__c, QBA_Email_address__c, 
            TCO_Last_name__c, TCO_First_name__c, TCO_Title__c, TCO_Telephone_number__c, TCO_Email_address__c, Auditor_Opinion__c, Opinion_Reason_Explanation__c, 
            Clinic_Director_Licenses_Certifications__c, QTE_Licenses_Certifications__c, QTE_Licenses_Other__c, Clinic_Director_Licenses_Other__c, 
            Toll_Free_telephone_number_if_applicabl__c, Year_end_Date_of_Financials__c,
            Single_Audit__c, Audit_Report_Loaded__c
            FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c IN :appIds]) {
            legacyAppMap.put(legacyApp.Application_for_Federal_Assistance__c, legacyApp);
        }

        // legacy file validations
        validateAttachmentsLegacy(oldMap, newList, legacyAppMap);

        // field validations
        for(Application_for_Federal_Assistance__c record : newList){ 
            Legacy_13424_Application__c legacyApp = legacyAppMap.get(record.Id);
            Application_for_Federal_Assistance__c oldRecord = oldMap.get(record.Id);

            if (oldRecord.get('Form_13424_Status__c') != 'Submitted' && record.get('Form_13424_Status__c') == 'Submitted' && record.get('Version__c') == 'Legacy') {
                validateFormLegacy13424Fields(legacyApp);
            }

            // adding errors to a list since can not use addError on related records in this context
            if (!errorMessages.isEmpty()) {
                String fullErrorMessage = String.join(errorMessages, '; \n');
                record.addError(fullErrorMessage);
            }
        }
    }

    /**
     * Contains all field validations for SF424 form
     * @param record The application record to validate.
     */
    private static void validateSF424Fields(Application_for_Federal_Assistance__c record) {
        // applicant information
        if (record.Do_you_have_a_UEI__c == null) record.Do_you_have_a_UEI__c.addError('Applicant information: "Do you have a UEI?" is Required');
        if (record.Do_you_have_a_UEI__c == 'Yes' && record.Organizational_UEI__c == null) record.Organizational_UEI__c.addError('Applicant information: Organizational UEI is required.');
        if (record.Do_you_have_a_UEI__c == 'Yes' && record.UEI_Sam_gov_Validation_Status__c == false) record.UEI_Sam_gov_Validation_Status__c.addError('Applicant information: Sam.Gov UEI must be validated.');
        if (record.Do_you_have_a_UEI__c == 'No' && record.Effort_on_obtaining_a_UEI__c == null) record.Effort_on_obtaining_a_UEI__c.addError('Applicant information: Effort on obtaining a UEI should not be blank.');
        if (record.Do_you_have_a_UEI__c == 'No' && record.Sam_gov_override__c == false) record.Sam_gov_override__c.addError('Applicant information: UEI is required.');

        // organization unit
        if (record.First_Name__c == null) record.First_Name__c.addError('Organization unit: "First Name" is Required');
        if (record.Last_Name__c == null) record.Last_Name__c.addError('Organization unit: "Last Name" is Required');
        if (record.Telephone_Number__c == null) record.Telephone_Number__c.addError('Organization unit: "Telephone Number" is Required');
        if (record.Email__c == null) record.Email__c.addError('Organization unit: "Email" is Required');
        if (record.Telephone_Number__c != null && record.Telephone_Number__c.length() != 10) record.Telephone_Number__c.addError('Organization unit: "Telephone Number" must be 10 digits');

        // type of applicant
        if (record.Type_of_Applicant_1__c == null) record.Type_of_Applicant_1__c.addError('Type of applicant: "Type of Applicant" is Required');
        if (record.Type_of_Applicant_1__c != null && record.Type_of_Applicant_1__c.contains('X. Other (specify)') && record.Type_of_Application_1_Other__c == null) record.Type_of_Application_1_Other__c.addError('Type of applicant: Specification is required when "Type of Applicant" includes "X. Other (specify)".');
        if (record.Type_of_Applicant_1__c != null && record.Type_of_Applicant_1__c.split(';').size() > 3) record.Type_of_Applicant_1__c.addError('Type of applicant: Up to 3 values may be selected for type of applicant.');

        // congressional / project
        if (record.Areas_affected_by_project__c == null) record.Areas_affected_by_project__c.addError('Congressional district / Project info: "Areas affected by project" is Required');
        if (record.Congressional_district_by_project__c == null) record.Congressional_district_by_project__c.addError('Congressional district / Project info: "Congressional Districts" is Required');

        if (record.Is_Applicant_Delinquent_on_Federal_Debt__c == null) record.Is_Applicant_Delinquent_on_Federal_Debt__c.addError('Estimated funding: "Is the Applicant Delinquent on any Federal Debt?" is Required');
        if (record.Is_Applicant_Delinquent_on_Federal_Debt__c == 'Yes' && record.Federal_debt_explanation__c == null) record.Federal_debt_explanation__c.addError('Estimated funding: "If yes, include an explanation" is Required');

        // authorized representative
        if (record.Auth_Rep_First_Name__c == null) record.Auth_Rep_First_Name__c.addError('Authorized representative: "First Name" is Required');
        if (record.Auth_Rep_Last_Name__c == null) record.Auth_Rep_Last_Name__c.addError('Authorized representative: "Last Name" is Required');
        if (record.Auth_Rep_Title__c == null) record.Auth_Rep_Title__c.addError('Authorized representative: "Title" is Required');
        if (record.Auth_Rep_Number__c == null) record.Auth_Rep_Number__c.addError('Authorized representative: "Number" is Required');
        if (record.Auth_Rep_Email__c == null) record.Auth_Rep_Email__c.addError('Authorized representative: "Email" is Required');
        if (record.Auth_Rep_Number__c != null && record.Auth_Rep_Number__c.length() != 10) record.Auth_Rep_Number__c.addError('Authorized representative: "Telephone Number" must be 10 digits');
    }

    /**
     * Contains all field validations for 13424 form
     * @param record The application record to validate.
     */
    private static void validateForm13424Fields(Application_for_Federal_Assistance__c record){ 

        // validations for 'New' non legacy M form 
        if(record.Type_of_Application__c == 'Continuation') return;

        Boolean isESL = record.Clinic_Services_and_Delivery_Model__c == 'ESL Education';
        Boolean isREA = record.Clinic_Services_and_Delivery_Model__c == 'Representation, Education, and Advocacy';

        // clinic information
        if(record.Clinic_Name__c == null) record.Clinic_Name__c.addError('Clinic information: "Clinic Name" is Required');
        if(record.Clinic_Public_telephone_number__c == null) record.Clinic_Public_telephone_number__c.addError('Clinic information: "Public telephone number" is Required');
        if(record.Clinic_Street__c == null) record.Clinic_Street__c.addError('Clinic information: "Clinic street address" is Required');
        if(record.Clinic_City__c == null) record.Clinic_City__c.addError('Clinic information: "Clinic city" is Required');
        if(record.Clinic_State__c == null) record.Clinic_State__c.addError('Clinic information: "Clinic state" is Required');
        if(record.Clinic_Zip_Code__c == null) record.Clinic_Zip_Code__c.addError('Clinic information: "Clinic zip" is Required');
        if(record.Clinic_Zip_Code__c != null && (record.Clinic_Zip_Code__c.length() != 9 && record.Clinic_Zip_Code__c.length() != 5)) record.Clinic_Zip_Code__c.addError('Clinic information: "Clinic zip" must be either 5 digits or 9 digits');

        if(record.Is_clinic_address_same_mailing__c == 'No' && record.Clinic_Mailing_Address__c == null) record.Clinic_Mailing_Address__c.addError('Clinic information: "Clinic mailing address" is Required');
        if(record.Is_clinic_address_same_mailing__c == 'No' && record.Clinic_Mailing_City__c == null) record.Clinic_Mailing_City__c.addError('Clinic information: "Clinic mailing city" is Required');
        if(record.Is_clinic_address_same_mailing__c == 'No' && record.Clinic_Mailing_State__c == null) record.Clinic_Mailing_State__c.addError('Clinic information: "Clinic mailing state" is Required');
        if(record.Is_clinic_address_same_mailing__c == 'No' && record.Clinic_Mailing_Zip_Code__c == null) record.Clinic_Mailing_Zip_Code__c.addError('Clinic information: "Clinic mailing zip" is Required');
        if(record.Is_clinic_address_same_mailing__c == 'No' && record.Clinic_Mailing_Zip_Code__c != null && (record.Clinic_Mailing_Zip_Code__c.length() != 9 && record.Clinic_Mailing_Zip_Code__c.length() != 5)) record.Clinic_Mailing_Zip_Code__c.addError('Clinic information: "Clinic mailing zip" must be either 5 digits or 9 digits');

        if(record.Clinic_Services_and_Delivery_Model__c == null) record.Clinic_Services_and_Delivery_Model__c.addError('Clinic information: "Clinic services and delivery model" is Required');
        if(isREA == true && record.Representation__c == null) record.Representation__c.addError('Clinic information: "Representation" is Required');

        // background
        if(record.Organization_Overview__c == null) record.Organization_Overview__c.addError('Background: "Organization overview" is Required');
        if(record.Type_of_Services_Provided__c == null) record.Type_of_Services_Provided__c.addError('Background: "Service delivery" is Required');
        if(record.Experience__c == null) record.Experience__c.addError('Background: "Experience" is Required');

        // tp, geographic area, etc
        if(record.Language_Access__c == null) record.Language_Access__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Language access" is Required');
        if(record.Language_Options__c != null && record.Language_Options__c.contains('Other') && record.Other_Language_Options__c == null) record.Other_Language_Options__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Other language options" is Required');
        if(record.Reasonable_Accommodations__c == null) record.Reasonable_Accommodations__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Description of reasonable accommodations" is Required');
        if(record.Geographic_Area_and_Target_Audience__c == null) record.Geographic_Area_and_Target_Audience__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Geographic area and target audience" is Required');
        if(record.Partners_and_Networks__c == null) record.Partners_and_Networks__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Partners and networks" is Required');
        if(record.Publicity_and_Outreach_Methods__c == null) record.Publicity_and_Outreach_Methods__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Publicity and outreach methods" is Required');
        if(isREA == true && record.Participation_in_Programs__c == null) record.Participation_in_Programs__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Does the applicant currently participate in either of calendar call/ stuffer letter" is Required');
        if(record.Participation_in_Programs__c == 'No' && record.Future_Participation__c == null) record.Future_Participation__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Does the applicant plan to participate in the future?" is Required');

        // taxpayer services
        if(isREA == true && record.Controversy_Representation_Scope__c == null) record.Controversy_Representation_Scope__c.addError('Taxpayer services : "Controversy representation services" is Required');
        if(isREA == true && record.Consulation_Service_to_be_provided__c == null) record.Consulation_Service_to_be_provided__c.addError('Taxpayer services : "Consultation" is Required');
        if(record.Taxpayer_Education__c == null) record.Taxpayer_Education__c.addError('Taxpayer services : "Taxpayer education" is Required');
        if(record.Advocacy__c == null) record.Advocacy__c.addError('Taxpayer services : "Advocacy" is Required');

        // staffing
        if(isESL == true && record.QTE_Position_filled_by_Volunteer__c == null) record.QTE_Position_filled_by_Volunteer__c.addError('Staffing : "QTE - This position will be filled by a volunteer" is Required');
        if(record.QTE_Identified_Hired__c == null) record.QTE_Identified_Hired__c.addError('Staffing : "QTE - Has the individual who will fulfill this role been identified/hired?" is Required');
        if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Last_name__c == null) record.QTE_Last_name__c.addError('Staffing : "QTE - Last name" is Required');
        if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_First_name__c == null) record.QTE_First_name__c.addError('Staffing : "QTE - First name" is Required');
        if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Telephone_number__c == null) record.QTE_Telephone_number__c.addError('Staffing : "QTE - Telephone number" is Required');
        if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Email_address__c == null) record.QTE_Email_address__c.addError('Staffing : "QTE - Email address" is Required');
        // if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Licenses_Certifications__c == null) record.QTE_Licenses_Certifications__c.addError('Staffing : "QTE - Licenses/Certifications" is Required');
        // if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Licenses_Certifications__c == 'Other' && record.QTE_Other_Licenses_Certifications__c == null) record.QTE_Other_Licenses_Certifications__c.addError('Staffing : "QTE - Other (specify)" is Required');
        // if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Licenses_Certifications__c != 'Enrolled Agent' && record.QTE_State_s_of_Licensure__c == null) record.QTE_State_s_of_Licensure__c.addError('Staffing : "QTE - State(s) of Licensure" is Required');
        // if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Licenses_Certifications__c != 'Enrolled Agent' && record.QTE_License_Number__c == null) record.QTE_License_Number__c.addError('Staffing : "QTE - License number" is Required');
        if(record.QTE_Identified_Hired__c == 'Yes' && record.QTE_Responsibilities_Qualifications__c == null) record.QTE_Responsibilities_Qualifications__c.addError('Staffing : "QTE - Responsibilities and qualifications" is Required');
        if(record.QTE_Identified_Hired__c == 'No' && record.QTE_Job_Description__c == null) record.QTE_Job_Description__c.addError('Staffing : "QTE - Job description" is Required');
        
        Boolean isCD = record.Dual_Role__c != null && record.Dual_Role__c.contains('Clinic Director');
        if(record.Clinic_Director_Identified_Hired__c == 'Yes' && isCD == false && record.Clinic_Director_Last_name__c == null) record.Clinic_Director_Last_name__c.addError('Staffing : "CD - Last name" is Required');
        if(record.Clinic_Director_Identified_Hired__c == 'Yes' && isCD == false && record.Clinic_Director_First_name__c == null) record.Clinic_Director_First_name__c.addError('Staffing : "CD - First name" is Required');
        if(record.Clinic_Director_Identified_Hired__c == 'Yes' && isCD == false && record.Clinic_Director_Telephone_number__c == null) record.Clinic_Director_Telephone_number__c.addError('Staffing : "CD - Telephone number" is Required');
        if(record.Clinic_Director_Identified_Hired__c == 'Yes' && isCD == false && record.Clinic_Director_Email_address__c == null) record.Clinic_Director_Email_address__c.addError('Staffing : "CD - Email address" is Required');
        // if(record.Clinic_Director_Identified_Hired__c == 'Yes' && isCD == false && record.Clinic_Director_Licenses_Certifications__c == 'Other' && record.Clinic_Director_Other_Licenses_Cert__c == null) record.Clinic_Director_Other_Licenses_Cert__c.addError('Staffing : "CD - Other (specify)" is Required');
        if(record.Clinic_Director_Identified_Hired__c == 'Yes' && record.CD_Responsibilities_Qualifications__c == null) record.CD_Responsibilities_Qualifications__c.addError('Staffing : "CD - Responsibilities and qualifications" is Required');
        if(record.Clinic_Director_Identified_Hired__c == 'No' && record.Clinic_Director_Job_Description__c == null) record.Clinic_Director_Job_Description__c.addError('Staffing : "CD - Job description" is Required');

        Boolean isQBA = (record.Dual_Role__c != null && record.Dual_Role__c.contains('Qualified Business Administrator')) || record.Dual_QBA__c == true;
        if(record.QBA_Identified_Hired__c == 'Yes' && isQBA == false && record.QBA_Last_name__c == null) record.QBA_Last_name__c.addError('Staffing : "QBA - Last name" is Required');
        if(record.QBA_Identified_Hired__c == 'Yes' && isQBA == false && record.QBA_First_name__c == null) record.QBA_First_name__c.addError('Staffing : "QBA - First name" is Required');
        if(record.QBA_Identified_Hired__c == 'Yes' && isQBA == false && record.QBA_Telephone_number__c == null) record.QBA_Telephone_number__c.addError('Staffing : "QBA - Telephone number" is Required');
        if(record.QBA_Identified_Hired__c == 'Yes' && isQBA == false && record.QBA_Email_address__c == null) record.QBA_Email_address__c.addError('Staffing : "QBA - Email address" is Required');
        if(record.QBA_Identified_Hired__c == 'Yes' && record.QBA_Responsibilities_Qualifications__c == null) record.QBA_Responsibilities_Qualifications__c.addError('Staffing : "QBA - Responsibilities and qualifications" is Required');
        if(record.QBA_Identified_Hired__c == 'No' && record.QBA_Job_Description__c == null) record.QBA_Job_Description__c.addError('Staffing : "QBA - Provide job description for position and required qualifications for a successful candidate" is Required');
    
        if(record.TCO_Last_name__c == null) record.TCO_Last_name__c.addError('Staffing : "TCO - Last name" is Required');
        if(record.TCO_First_name__c == null) record.TCO_First_name__c.addError('Staffing : "TCO - First name" is Required');
        if(record.TCO_Telephone_number__c == null) record.TCO_Telephone_number__c.addError('Staffing : "TCO - Telephone number" is Required');
        if(record.TCO_Email_address__c == null) record.TCO_Email_address__c.addError('Staffing : "TCO - Email address" is Required');
        if(record.TCO_Title__c == null) record.TCO_Title__c.addError('Staffing : "TCO - Title" is Required');

        if(isREA == true && record.Clinic_Director_US_Tax_Court_Number__c == null && record.QTE_US_Tax_Court_Number__c == null && record.US_Tax_Court_Narrative__c == null) record.US_Tax_Court_Narrative__c.addError('Staffing : "US Tax Court narrative" is Required');
        if(record.Student_s_Per_Semester_Type__c == null) record.Student_s_Per_Semester_Type__c.addError('Staffing : "Student(s) per semester/type" is Required');

        // volunteers
        if(isREA == true && record.Volunteer_Pro_Bono_Panel__c == null) record.Volunteer_Pro_Bono_Panel__c.addError('Volunteers : "Pro bono panel" is Required');
        if(record.Other_Volunteer_Recruitment__c == null) record.Other_Volunteer_Recruitment__c.addError('Volunteers : "Other volunteer recruitment" is Required');
        if(record.Volunteer_Recruitment_and_Retention__c == null) record.Volunteer_Recruitment_and_Retention__c.addError('Volunteers : "Volunteer recruitment and retention" is Required');

        // clinic operations
        if(record.Dates_of_Operation__c == null) record.Dates_of_Operation__c.addError('Clinic operations : "Dates of operation" is Required');
        if(record.Reduction_in_Services__c == true && record.Continuity_of_Services__c == null) record.Continuity_of_Services__c.addError('Clinic operations : "Describe continuity of services" is Required');
        if(record.After_Hours_or_Weekend_Service__c == null) record.After_Hours_or_Weekend_Service__c.addError('Clinic operations : "Describe whether services will be offered after hours or on weekends" is Required');
        if(isREA == true && record.Intake_Process__c == null) record.Intake_Process__c.addError('Clinic operations : "Intake" is Required');
        if(isREA == true && record.Household_Income_Exceeding_250_of_Pover__c == null) record.Household_Income_Exceeding_250_of_Pover__c.addError('Clinic operations : "Household income exceeding 250% of poverty" is Required');
        if(isREA == true && record.Household_Income_Exceeding_250_of_Pover__c == 'Yes' && record.Cases_Exceeding_250_of_FPL_Description__c == null) record.Cases_Exceeding_250_of_FPL_Description__c.addError('Clinic operations : "Cases Exceeding 250% of FPL Description" is Required');
        if(isREA == true && record.Amount_in_Controversy_Limit__c == null) record.Amount_in_Controversy_Limit__c.addError('Clinic operations : "Amount in controversy limit" is Required');
        if(isREA == true && record.Amount_in_Controversy_Limit__c == 'Yes' && record.Cases_Exceed_Amt_in_Contro_Limit_Desc__c == null) record.Cases_Exceed_Amt_in_Contro_Limit_Desc__c.addError('Clinic operations : "Cases Exceeding Amount in Controversy Limit Description" is Required');
        if(isREA == true && record.Nominal_Fee__c == null) record.Nominal_Fee__c.addError('Clinic operations : "Does the clinic plan to charge a nominal fee?" is Required');
        if(isREA == true && record.Nominal_Fee__c == 'Yes' && record.Nominal_Fee_Description__c == null) record.Nominal_Fee_Description__c.addError('Clinic operations : "Nominal fee description" is Required');
        if(isREA == true && record.Case_Management_System__c == null) record.Case_Management_System__c.addError('Clinic operations : "Case Management System" is Required');
        if(isREA == true && record.Case_Assignment_Procedures__c == null) record.Case_Assignment_Procedures__c.addError('Clinic operations : "Describe case assignment procedures" is Required');
        if(isREA == true && record.Case_Monitoring__c == null) record.Case_Monitoring__c.addError('Clinic operations : "Case Monitoring" is Required');
        if(record.Time_Tracking__c == null) record.Time_Tracking__c.addError('Clinic operations : "Time tracking" is Required');
        if(isESL == true && record.Collecting_Taxpayer_Information__c == null) record.Collecting_Taxpayer_Information__c.addError('Clinic operations : "Will program plan to collect taxpayer information to facilitate referral or consultation?" is Required');
        if(isESL == true && record.Collecting_Taxpayer_Information__c == 'Yes' && record.Protecting_Taxpayer_Privacy__c == null) record.Protecting_Taxpayer_Privacy__c.addError('Clinic operations : "Protecting Taxpayer Privacy" is Required');

        // training and resources
        if(record.In_house_Training__c == null) record.In_house_Training__c.addError('Training and resources : "In-house Training" is Required');
        if(record.External_Training__c == null) record.External_Training__c.addError('Training and resources : "External training" is Required');
        if(record.Research_Materials_and_Software__c == null) record.Research_Materials_and_Software__c.addError('Training and resources : "Research materials and software" is Required');

        // financial responsibility
        if(record.Experience_Managing_Grants__c == null) record.Experience_Managing_Grants__c.addError('Financial responsibility : "Describe applicant experience in managing federal grants" is Required');
        if(record.Accounting_Procedures__c == null) record.Accounting_Procedures__c.addError('Financial responsibility : "Provide an overview of the applicant accounting procedures" is Required');
        if(record.Free_Tax_Preparation__c == null) record.Free_Tax_Preparation__c.addError('Financial responsibility : "Does the applicant offer free tax preparation?" is Required');
        // if(record.VITA_or_TCE_Site_Funding__c == null) record.VITA_or_TCE_Site_Funding__c.addError('Financial responsibility : "Does the applicant receive funding to run a VITA or a TCE site" is Required');
        if(record.Tracking_Grant_Expenditures__c == null) record.Tracking_Grant_Expenditures__c.addError('Financial responsibility : "Tracking grant expenditures" is Required');
        if(record.Audits_or_Financial_Reviews__c == null) record.Audits_or_Financial_Reviews__c.addError('Financial responsibility : "Describe the plans for audits or financial reviews" is Required');
        if(record.Financial_Statement_Information__c == null) record.Financial_Statement_Information__c.addError('Financial responsibility : "Information regarding financial statement submitted with this application" is Required');
        if(record.Financial_Statement_Type__c == null) record.Financial_Statement_Type__c.addError('Financial responsibility : "Is the statement Audited or Unaudited" is Required');
        if(record.Financial_Statement_Type__c == 'Audited' && record.Single_Audit_Compliance__c == null) record.Single_Audit_Compliance__c.addError('Financial responsibility : "Was the audit a single audit in accordance with 2 CFR 200.501" is Required');
        if(record.Single_Audit_Compliance__c == 'Yes' && record.Audit_Clearinghouse_Availability__c == null) record.Audit_Clearinghouse_Availability__c.addError('Financial responsibility : "Is a complete copy available on the audit clearinghouse website" is Required');
        if(record.Legal_Services_Corporation_Funding__c == null) record.Legal_Services_Corporation_Funding__c.addError('Financial responsibility : "Legal services corporation funding" is Required');
        if(record.Year_end_Date_of_Financials__c == null) record.Year_end_Date_of_Financials__c.addError('Financial responsibility : "Year-end date of financials submitted" is Required');

        // program information
        if(record.Program_Evaluation__c == null) record.Program_Evaluation__c.addError('Program information : "Program Evaluation" is Required');
        if(record.Program_Improvement__c == null) record.Program_Improvement__c.addError('Program information : "Program improvement" is Required');
        if(record.Program_Numerical_Goals_Narrative__c == null) record.Program_Numerical_Goals_Narrative__c.addError('Program information : "Briefly describe the factors considered in setting the clinic’s numerical goals" is Required');
        if(isREA == true && record.New_Representation_Cases__c == null) record.New_Representation_Cases__c.addError('Program information : "New representation cases" is Required');
        if(isREA == true && record.Consultations_with_Low_Income_ESL__c == null) record.Consultations_with_Low_Income_ESL__c.addError('Program information : "Consultations with low income ESL" is Required');
        if(record.Educational_Activates_to_Low_Income__c == null) record.Educational_Activates_to_Low_Income__c.addError('Program information : "Education for low-income & ESL taxpayers/providers" is Required');
        if(record.Low_Income_ESL_TP_Service_Providers__c == null) record.Low_Income_ESL_TP_Service_Providers__c.addError('Program information : "Low income, ESL Taxpayers reached in educational activities" is Required');

        //Civil rights information
        if(record.Active_Lawsuits_or_Complaints__c == null) record.Active_Lawsuits_or_Complaints__c.addError('Civil rights information : "The applicant has active lawsuits or complaints to report" is Required');
        if(record.Active_Lawsuits_or_Complaints__c == 'Yes' && record.List_of_Active_Lawsuits_or_Complaints__c == null) record.List_of_Active_Lawsuits_or_Complaints__c.addError('Civil rights information : "Lawsuits or complaints" is Required');
        if(record.Federal_Financial_Assistance__c == null) record.Federal_Financial_Assistance__c.addError('Civil rights information : "Provide a list of all pending applications for financial assistance provided by other federal agencies" is Required');
        if(record.Civil_Rights_Review_Activity__c == null) record.Civil_Rights_Review_Activity__c.addError('Civil rights information : "Civil Rights Review Activity" is Required');
        if(record.Data_Compilation_and_Maintenance__c == null) record.Data_Compilation_and_Maintenance__c.addError('Civil rights information : "Does the applicant agree to compile and maintain all required records" is Required');
        if(record.Public_Display_of_Civil_Rights_Poster__c == null) record.Public_Display_of_Civil_Rights_Poster__c.addError('Civil rights information : "Does the applicant agree to display Publication 4053, IRS Civil Rights Poster" is Required');
    }

    /**
     * Contains all legacy field validations for 13424 form
     * @param record The application record to validate.
     */
    
    private static void validateFormLegacy13424Fields(Legacy_13424_Application__c record){ 

        // 13424
        if(record.Legal_name_of_sponsoring_organization__c == null) errorMessages.add('Form 13424 - Applicant information: "Legal name of sponsoring organization" is Required');
        if(record.Last_Name__c == null) errorMessages.add('Form 13424 - Applicant information: "Last name" is Required');
        if(record.First_Name__c == null) errorMessages.add('Form 13424 - Applicant information: "First name" is Required');
        if(record.Title__c == null) errorMessages.add('Form 13424 - Applicant information: "Title" is Required');
        if(record.Phone_number__c == null) errorMessages.add('Form 13424 - Applicant information: "Phone number" is Required');
        if(record.Email_address__c == null) errorMessages.add('Form 13424 - Applicant information: "Email address" is Required');
        if(record.Street__c == null) errorMessages.add('Form 13424 - Applicant information: "Street" is Required');
        if(record.City__c == null) errorMessages.add('Form 13424 - Applicant information: "City" is Required');
        if(record.State__c == null) errorMessages.add('Form 13424 - Applicant information: "State" is Required');
        if(record.ZIP_4_code__c == null) errorMessages.add('Form 13424 - Applicant information: "Zip+4 code" is Required');

        if(record.Name_of_clinic__c == null) errorMessages.add('Form 13424 - Clinic information: "Name of clinic" is Required');
        if(record.Public_telephone_number__c == null) errorMessages.add('Form 13424 - Clinic information: "Public telephone number" is Required');
        if(record.Clinic_Street__c == null) errorMessages.add('Form 13424 - Clinic information: "Street" is Required');
        if(record.Clinic_City__c == null) errorMessages.add('Form 13424 - Clinic information: "City" is Required');
        if(record.Clinic_State__c == null) errorMessages.add('Form 13424 - Clinic information: "State" is Required');
        if(record.Clinic_ZIP_4_code__c == null) errorMessages.add('Form 13424 - Clinic information: "ZIP + 4 code" is Required');

        if(record.Clinic_Mailing_Street__c == null) errorMessages.add('Form 13424 - Clinic information: "Mailing Street" is Required');
        if(record.Clinic_Mailing_City__c == null) errorMessages.add('Form 13424 - Clinic information: "Mailing City" is Required');
        if(record.Clinic_Mailing_State__c == null) errorMessages.add('Form 13424 - Clinic information: "Mailing State" is Required');
        if(record.Clinic_Mailing_Zip_4_code__c == null) errorMessages.add('Form 13424 - Clinic information: "Mailing ZIP + 4 code" is Required');
        if(record.Clinic_Director_Last_Name__c == null) errorMessages.add('Form 13424 - Clinic information: "Clinic director last name" is Required');
        if(record.Clinic_Director_First_Name__c == null) errorMessages.add('Form 13424 - Clinic information: "Clinic director first name" is Required');
        if(record.Clinic_Director_Telephone_number__c == null) errorMessages.add('Form 13424 - Clinic information: "Clinic director telephone" is Required');
        if(record.Clinic_Director_Email_address__c == null) errorMessages.add('Form 13424 - Clinic information: "Clinic director email" is Required');
        if(record.QTE_Last_name__c == null) errorMessages.add('Form 13424 - Clinic information: "QTE Last name" is Required');
        if(record.QTE_First_name__c == null) errorMessages.add('Form 13424 - Clinic information: "QTE First name" is Required');
        if(record.QTE_Telephone_number__c == null) errorMessages.add('Form 13424 - Clinic information: "QTE Telephone" is Required');
        if(record.QTE_Email_address__c == null) errorMessages.add('Form 13424 - Clinic information: "QTE Email" is Required');
        if(record.QBA_Last_name__c == null) errorMessages.add('Form 13424 - Clinic information: "QBA Last name" is Required');
        if(record.QBA_First_name__c == null) errorMessages.add('Form 13424 - Clinic information: "QBA First name" is Required');
        if(record.QBA_Telephone_number__c == null) errorMessages.add('Form 13424 - Clinic information: "QBA telephone" is Required');
        if(record.QBA_Email_address__c == null) errorMessages.add('Form 13424 - Clinic information: "QBA Email" is Required');
        if(record.TCO_Last_name__c == null) errorMessages.add('Form 13424 - Clinic information: "TCO Last name" is Required');
        if(record.TCO_First_name__c == null) errorMessages.add('Form 13424 - Clinic information: "TCO First name" is Required');
        if(record.TCO_Title__c == null) errorMessages.add('Form 13424 - Clinic information: "TCO Title" is Required');
        if(record.TCO_Telephone_number__c == null) errorMessages.add('Form 13424 - Clinic information: "TCO telephone" is Required');
        if(record.TCO_Email_address__c == null) errorMessages.add('Form 13424 - Clinic information: "TCO Email" is Required');

        if(record.ZIP_4_code__c != null && (record.ZIP_4_code__c.length() < 5 || record.ZIP_4_code__c.length() > 10)) errorMessages.add('Form 13424 - Applicant information: "Zip+4 code" must be either 5 to 10 characters');
        if(record.Clinic_ZIP_4_code__c != null && (record.Clinic_ZIP_4_code__c.length() < 5 || record.Clinic_ZIP_4_code__c.length() > 10)) errorMessages.add('Form 13424 - Clinic information: "Zip+4 code" must be either 5 to 10 characters');
        if(record.Clinic_Mailing_Zip_4_code__c != null && (record.Clinic_Mailing_Zip_4_code__c.length() < 5 || record.Clinic_Mailing_Zip_4_code__c.length() > 10)) errorMessages.add('Form 13424 - Clinic information: "Maling Zip+4 code" must be 5 to 10 characters');

        if(record.ZIP_4_code__c != null){
            Matcher regexPost = Pattern.compile('^[0-9-]+$').matcher(record.ZIP_4_code__c);
            if(!regexPost.matches()) errorMessages.add('Form 13424 - Applicant information: "Zip+4 code" must only contain numbers');
        } 
        if(record.Clinic_ZIP_4_code__c != null){
            Matcher regexPost = Pattern.compile('^[0-9-]+$').matcher(record.Clinic_ZIP_4_code__c);
            if(!regexPost.matches()) errorMessages.add('Form 13424 - Clinic information: "Zip+4 code" must only contain numbers');
        } 
        if(record.Clinic_Mailing_Zip_4_code__c != null){
            Matcher regexPost = Pattern.compile('^[0-9-]+$').matcher(record.Clinic_Mailing_Zip_4_code__c);
            if(!regexPost.matches()) errorMessages.add('Form 13424 - Clinic information: "Maling Zip+4 code" must only contain numbers');
        } 

        if (record.Clinic_Director_Licenses_Certifications__c != null && record.Clinic_Director_Licenses_Certifications__c.contains('Other') && record.Clinic_Director_Licenses_Other__c == null) errorMessages.add('Form 13424 - Clinic information: "Licenses - Other (specify)" is required');
        if (record.QTE_Licenses_Certifications__c != null && record.QTE_Licenses_Certifications__c.contains('Other') && record.QTE_Licenses_Other__c == null) errorMessages.add('Form 13424 - Clinic information: "Licenses - Other (specify)" is required');

        if(record.Phone_number__c != null && record.Phone_number__c.length() != 10) errorMessages.add('Form 13424 - Applicant information: "Phone number" must be 10 digits');
        if(record.Public_telephone_number__c != null && record.Public_telephone_number__c.length() != 10) errorMessages.add('Form 13424 - Clinic information: "Public telephone number" must be 10 digits');
        if(record.Toll_Free_telephone_number_if_applicabl__c != null && record.Toll_Free_telephone_number_if_applicabl__c.length() != 10) errorMessages.add('Form 13424 - Clinic information: "Toll-Free telephone number" must be 10 digits');
        if(record.Clinic_Director_Telephone_number__c != null && record.Clinic_Director_Telephone_number__c.length() != 10) errorMessages.add('Form 13424 - Clinic information: "Clinic director telephone" must be 10 digits');
        if(record.QTE_Telephone_number__c != null && record.QTE_Telephone_number__c.length() != 10) errorMessages.add('Form 13424 - Clinic information: "QTE Telephone" must be 10 digits');
        if(record.QBA_Telephone_number__c != null && record.QBA_Telephone_number__c.length() != 10) errorMessages.add('Form 13424 - Clinic information: "QBA telephone" must be 10 digits');
        if(record.TCO_Telephone_number__c != null && record.TCO_Telephone_number__c.length() != 10) errorMessages.add('Form 13424 - Clinic information: "TCO telephone" must be 10 digits');

        // 13424 M

        // background block
        if(record.Applicant_Experience__c == null) errorMessages.add('Form 13424-M - Experience: "Question A." is Required');
        if(record.Applicant_Affliations__c == null) errorMessages.add('Form 13424-M - Experience: "Question B." is Required');
        if(record.Applicant_Supervising_Experience__c == null) errorMessages.add('Form 13424-M - Experience: "Question C." is Required');
        if(record.Applicant_Networking_Experience__c == null) errorMessages.add('Form 13424-M - Experience: "Question D." is Required');
 
        if(record.Accounting_Procedures_and_Support_Staff__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 1." is Required');
        if(record.Exp_Tracking_and_Verifying_Method__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 2." is Required');
        if(record.VITA_Site__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 2i." is Required');
        if(record.Audits_and_Controls_Plans__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 3." is Required');
        if(record.Financial_Statement__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 4." is Required');

        if(record.Financial_Statement__c == 'Audited' && record.Single_Audit__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 4. i" is Required');
        if(record.Financial_Statement__c == 'Audited' && record.Audit_Report_Loaded__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 4. ii" is Required');
        if(record.Financial_Statement__c == 'Audited' && record.Auditor_Opinion__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 4. iii" is Required');

        if(record.Financial_Statement__c == 'Audited' && record.Auditor_Opinion__c != 'Unmodified opinion' && record.Opinion_Reason_Explanation__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 4. iv" is Required');
        if(record.Year_end_Date_of_Financials__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 4. v" is Required');

        if(record.QBA_Name_and_Qualifications__c == null) errorMessages.add('Form 13424-M - Financial responsibility: "Question 5." is Required');

        // program block
        if(record.Qualified_Tax_Expert_QTE__c == null) errorMessages.add('Form 13424-M - Program staff: "Question 1." is Required');
        if(record.Clinic_Director__c == null) errorMessages.add('Form 13424-M - Program staff: "Question 2." is Required');
        if(record.Clinic_Staff__c == null) errorMessages.add('Form 13424-M - Program staff: "Question 2B." is Required');
        if(record.Student_s_Per_Semester_Type__c == null) errorMessages.add('Form 13424-M - Program staff: "Question C." is Required');
        if(record.Clinic_Staff_Authorized_to_Represent__c == null) errorMessages.add('Form 13424-M - Program staff: "Question D." is Required');
        if(record.Time_Tracking__c == null) errorMessages.add('Form 13424-M - Program staff: "Question F." is Required');

        if(record.Geographic_Area_and_Target_Audience__c == null) errorMessages.add('Form 13424-M - Taxpayer services: "Question 1." is Required');
        if(record.Representation_Services_Type__c == null) errorMessages.add('Form 13424-M - Taxpayer services: "Question 2." is Required');
        if(record.Consulation_Service_to_be_provided__c == null) errorMessages.add('Form 13424-M - Taxpayer services: "Question B." is Required');
        if(record.Educational_Activities_to_be_provided__c == null) errorMessages.add('Form 13424-M - Taxpayer services: "Question C." is Required');

        if(record.Service_Delivery_Tracking_Plans__c == null) errorMessages.add('Form 13424-M - Clinic operations: "Question A." is Required');
        if(record.Publicity_and_Outreach_Methods__c == null) errorMessages.add('Form 13424-M - Clinic operations: "Question C." is Required');
        if(record.Clinic_Operation_Hours__c == null) errorMessages.add('Form 13424-M - Clinic operations: "Question D." is Required');
        if(record.Nominal_Fee__c == null) errorMessages.add('Form 13424-M - Clinic operations: "Question E." is Required');

        if(record.In_house_Training__c == null) errorMessages.add('Form 13424-M - Training and resources: "Question A." is Required');
        if(record.Continuing_Professional_Education_CPE__c == null) errorMessages.add('Form 13424-M - Training and resources: "Question B." is Required');
        if(record.Tax_Library_and_Research_Resources__c == null) errorMessages.add('Form 13424-M - Training and resources: "Question C." is Required');

        if(record.Strategy_for_Monitoring_Program_Results__c == null) errorMessages.add('Form 13424-M - Program monitoring, evaluation, and reporting: "Question A." is Required');
        if(record.Indicate_Measure_Client_Satisfaction__c == null) errorMessages.add('Form 13424-M - Program monitoring, evaluation, and reporting: "Question B." is Required');
    
        if(record.Educa_Activ_to_Low_Income_First_Year__c == null) errorMessages.add('Form 13424-M - Program numerical goals: "Question C." is Required');
        if(record.Low_Income_ESL_to_be_reached_First_Year__c == null) errorMessages.add('Form 13424-M - Program numerical goals: "Question D." is Required');


        // civil rights block
        if(record.Active_Lawsuits_or_Complaints__c == null) errorMessages.add('Form 13424-M - Civil rights review: "Question A." is Required');
        if(record.Federal_Financial_Assistance__c == null) errorMessages.add('Form 13424-M - Civil rights review: "Question B." is Required');
        if(record.Civil_Rights_Review_Activity__c == null) errorMessages.add('Form 13424-M - Civil rights review: "Question C." is Required');
        if(record.Reasonable_Accommodations__c == null) errorMessages.add('Form 13424-M - Civil rights review: "Question D." is Required');
        if(record.Data_Compilation_and_Maintenance__c == null) errorMessages.add('Form 13424-M - Civil rights review: "Question E." is Required');
        if(record.Public_Display_of_Civil_Rights_Poster__c == null) errorMessages.add('Form 13424-M - Civil rights review: "Question F." is Required');
    }

    /**
     * Processes validations for file uploads 
     * @param newList List of new Application_for_Federal_Assistance__c records.
     * @param oldMap Map of old Application_for_Federal_Assistance__c records.
     */
    private static void validateAttachments(Map<Id, Application_for_Federal_Assistance__c> oldApplications, List<Application_for_Federal_Assistance__c> newApplications) {

        Set<Id> submittedApplicationIds = new Set<Id>();  // j form file upload
        Set<Id> submitted424_MN_ApplicationIds = new Set<Id>(); // sf424
        Set<Id> submitted424_HOTUV_ApplicationIds = new Set<Id>(); // sf424
        Set<Id> submitted13424ApplicationIds = new Set<Id>(); // m form

        for (Application_for_Federal_Assistance__c newApp : newApplications) {
            Application_for_Federal_Assistance__c oldApp = oldApplications.get(newApp.Id);

            if (oldApp != null && oldApp.Form_13424_J_Status__c != 'Submitted' && newApp.Form_13424_J_Status__c == 'Submitted') {
                submittedApplicationIds.add(newApp.Id);
            }

            if (newApp.get('Type_of_Applicant_1__c') != null && oldApp.get('SF424_Status__c') != 'Submitted' && newApp.get('SF424_Status__c') == 'Submitted' && 
            (String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('M. Nonprofit with 501(c) status') || String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('N. Nonprofit without 501(c) status'))) {
                submitted424_MN_ApplicationIds.add(newApp.Id);
            }    

            if (newApp.get('Type_of_Applicant_1__c') != null && oldApp.get('SF424_Status__c') != 'Submitted' && newApp.get('SF424_Status__c') == 'Submitted' && 
            (String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('H. Public/State Controlled Institution of Higher Education') || 
             String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('O. Private Institution of Higher Education')  ||
             String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('T. Historically Black Colleges and Universities (HBCUs)') ||
             String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('U. Tribally Controlled Colleges and Universities (TCCUs)') ||
             String.valueOf(newApp.get('Type_of_Applicant_1__c')).contains('V. Alaska Native and Native Hawaiian Serving Institutions')
             )) {
                submitted424_HOTUV_ApplicationIds.add(newApp.Id);
            } 
            
            if (oldApp.get('Form_13424_Status__c') != 'Submitted' && newApp.get('Form_13424_Status__c') == 'Submitted'){
                if(newApp.get('Financial_Statement_Type__c') == 'Unaudited'){
                    submitted13424ApplicationIds.add(newApp.Id);
                }
                if(newApp.get('Financial_Statement_Type__c') == 'Audited' && newApp.get('Audit_Clearinghouse_Availability__c') == 'No'){
                    submitted13424ApplicationIds.add(newApp.Id);
                } 
            }  
        }
    
        if (!submitted424_MN_ApplicationIds.isEmpty()) {        
            validateAttachmentsHelper(submitted424_MN_ApplicationIds, 'SF424-Type-of-applicant_MN%', newApplications, 'Type of applicant: File upload - Tax Exempt Determination Letter or Other Proof of Non-Profit Status is required');
        }

        if (!submitted424_HOTUV_ApplicationIds.isEmpty()) {
            validateAttachmentsHelper(submitted424_HOTUV_ApplicationIds, 'SF424-Type-of-applicant_HOTUV%', newApplications, 'Type of applicant: File upload - Proof of Academic Accreditation is required');
        }

        if (!submitted13424ApplicationIds.isEmpty()) {
            validateAttachmentsHelper(submitted13424ApplicationIds, 'SF13424M-Financial Responsibility%', newApplications, 'Financial responsibility : File upload - Most Recent Audited Financial Statement or Unaudited Financial Statement is required');
        } 

        if (!submittedApplicationIds.isEmpty()) {
            List<X13424_J_Line_Item__c> relatedLineItems = [SELECT Id, Application_for_Federal_Assistance__c, Indirect_Cost_Rate_Type__c 
                FROM X13424_J_Line_Item__c 
                WHERE Application_for_Federal_Assistance__c IN :submittedApplicationIds
                AND Indirect_Cost_Rate_Type__c != 'De Minimis'
                AND RecordType.Name = 'Indirect Expenses'
            ];
        
            if (!relatedLineItems.isEmpty()) {
                Set<Id> applicationIdsToValidate = new Set<Id>();
                for (X13424_J_Line_Item__c lineItem : relatedLineItems) {
                    applicationIdsToValidate.add(lineItem.Application_for_Federal_Assistance__c);
                }
                validateAttachmentsHelper(applicationIdsToValidate, 'IndirectExpenseRate%', newApplications, 'Indirect expenses : File upload - Upload a copy of your approved indirect cost rate agreement for each line item');
            }
        }
    }

    /**
     * Helper function to validate file uploads
     * @param applicationIds Set of application IDs
     * @param filePrefix file prefix to check
     * @param newApplications List of new Application_for_Federal_Assistance__c record
     * @param errorMessage error message to display
     */
    private static void validateAttachmentsHelper(Set<Id> applicationIds, String filePrefix, List<Application_for_Federal_Assistance__c> newApplications, String errorMessage){ 
        Set<Id> conDocumentIdsAll = new Set<Id>();
        for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :applicationIds]) {
            conDocumentIdsAll.add(cdl.ContentDocumentId);
        }

        Set<Id> conDocumentIds = new Set<Id>();
        for (ContentVersion cv : [ SELECT ContentDocumentId, ContentDocument.ParentId FROM ContentVersion WHERE ContentDocumentId  IN :conDocumentIdsAll AND File_Prefix__c LIKE :filePrefix]) {
            conDocumentIds.add(cv.ContentDocumentId);
        }

        Set<Id> applicationsWithAttachments = new Set<Id>();
        if(!conDocumentIds.isEmpty()){ 
            for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :conDocumentIds]){ 
                applicationsWithAttachments.add(cdl.LinkedEntityId);
            }
        }
    
        for (Application_for_Federal_Assistance__c newApp : newApplications) {
            if (applicationIds.contains(newApp.Id) && !applicationsWithAttachments.contains(newApp.Id)) {
                newApp.Id.addError(errorMessage);
            }
        }

    }

    private static void validateAttachmentsLegacy(Map<Id, Application_for_Federal_Assistance__c> oldApplications, List<Application_for_Federal_Assistance__c> newApplications, Map<Id, Legacy_13424_Application__c> legacyAppMap) {
        Set<Id> submitted13424ApplicationIds = new Set<Id>(); 

        for (Application_for_Federal_Assistance__c newApp : newApplications) {
            Application_for_Federal_Assistance__c oldApp = oldApplications.get(newApp.Id);
            Legacy_13424_Application__c legacyApp = legacyAppMap.get(newApp.Id);

            if (oldApp.get('Form_13424_Status__c') != 'Submitted' && newApp.get('Form_13424_Status__c') == 'Submitted' && newApp.get('Version__c') == 'Legacy'){
                submitted13424ApplicationIds.add(legacyApp.Id);
            }  
        }

        if (!submitted13424ApplicationIds.isEmpty()) {
            Set<Id> conDocumentIdsAll = new Set<Id>();
            for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId IN :submitted13424ApplicationIds]) {
                conDocumentIdsAll.add(cdl.ContentDocumentId);
            }
    
            Set<Id> conDocumentIds = new Set<Id>();
            for (ContentVersion cv : [ SELECT ContentDocumentId, ContentDocument.ParentId FROM ContentVersion WHERE ContentDocumentId  IN :conDocumentIdsAll AND File_Prefix__c LIKE 'SF13424M-Financial Responsibility%']) {
                conDocumentIds.add(cv.ContentDocumentId);
            }
    
            Set<Id> applicationsWithAttachments = new Set<Id>();
            if(!conDocumentIds.isEmpty()){ 
                for (ContentDocumentLink cdl : [SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :conDocumentIds]){ 
                    applicationsWithAttachments.add(cdl.LinkedEntityId);
                }
            }
        
            for (Application_for_Federal_Assistance__c newApp : newApplications) {
                Legacy_13424_Application__c legacyApp = legacyAppMap.get(newApp.Id);
                if (submitted13424ApplicationIds.contains(legacyApp.Id) && !applicationsWithAttachments.contains(legacyApp.Id)) {
                    errorMessages.add('Form 13424-M - Financial responsibility: File upload - Most Recent Audited Financial Statement or Unaudited Financial Statement is required');
                }
            }
        } 
    }


    /**
     * Processes validations for related license records
     * @param applicationIds Set of application IDs to validate.
     * @param newApplications List of new Application_for_Federal_Assistance__c record
     */
    private static void validateLicenses(Set<Id> applicationIds, List<Application_for_Federal_Assistance__c> newApplications){ 
        Map<Id, List<LITC_Licensure__c>> appToLicensesMap = new Map<Id, List<LITC_Licensure__c>>();
        for (LITC_Licensure__c license : [SELECT Id, Application_for_Federal_Assistance__c FROM LITC_Licensure__c WHERE Application_for_Federal_Assistance__c IN :applicationIds AND Type__c = 'Qualified Tax Expert']) {
            if (!appToLicensesMap.containsKey(license.Application_for_Federal_Assistance__c)) {
                appToLicensesMap.put(license.Application_for_Federal_Assistance__c, new List<LITC_Licensure__c>());
            }
            appToLicensesMap.get(license.Application_for_Federal_Assistance__c).add(license);
        }
        for (Application_for_Federal_Assistance__c app : newApplications) {
            if (!appToLicensesMap.containsKey(app.Id)) {
                app.Name.addError('Staffing : You must add a license/certification for QTE Staff');
            }
        }
    }

    /**
     * After Insert Trigger Handler
     * Creates an Individual Application record when a new application is created
     * @param newList List of new Application_for_Federal_Assistance__c records.
     */
    public static void afterInsert(List<Application_for_Federal_Assistance__c> newList){

        List<IndividualApplication> individualAppsToInsert = new List<IndividualApplication>();
        Map<Id, Id> applicationToIndividualAppMap = new Map<Id, Id>();

        RegulatoryAuthorizationType licenseType = new RegulatoryAuthorizationType(Name='LITC');
        insert licenseType;
        Id licenseTypeId = licenseType.Id;
    
        for (Application_for_Federal_Assistance__c app : newList) {
            IndividualApplication individualApp = new IndividualApplication(ApplicationName = app.Name, Status = 'Draft', Category = 'Permit', LicenseTypeId = licenseTypeId, Related_Business_Account__c = app.Related_Business_Account__c);
            individualAppsToInsert.add(individualApp);
            applicationToIndividualAppMap.put(app.Id, null);
        }

        if (!individualAppsToInsert.isEmpty()) {
            insert individualAppsToInsert;
        }

        for (Integer i = 0; i < individualAppsToInsert.size(); i++) {
            IndividualApplication insertedApp = individualAppsToInsert[i];
            Id applicationId = Trigger.new[i].Id;
            applicationToIndividualAppMap.put(applicationId, insertedApp.Id);
        }
        
        List<Application_for_Federal_Assistance__c> applicationsToUpdate = new List<Application_for_Federal_Assistance__c>();

        for (Application_for_Federal_Assistance__c app : newList) {
            Application_for_Federal_Assistance__c updatedApp = new Application_for_Federal_Assistance__c(Id = app.Id);
            updatedApp.Individual_Application__c = applicationToIndividualAppMap.get(app.Id);
            applicationsToUpdate.add(updatedApp);
        }

        if (!applicationsToUpdate.isEmpty()) {
            update applicationsToUpdate;
        }

        insertLegacyApp(newList);
    }

    /**
     * After Update Trigger Handler
     * Updates status of related Individual Application records when applications are submitted.
     * @param newList List of new Application_for_Federal_Assistance__c records.
     * @param oldMap Map of old Application_for_Federal_Assistance__c records.
     */
    public static void afterUpdate(List<Application_for_Federal_Assistance__c> newList,Map<Id, Application_for_Federal_Assistance__c> oldMap){
        Map<Id, IndividualApplication> individualApplicationMap = new Map<Id, IndividualApplication>();

        for (Application_for_Federal_Assistance__c record : newList) {
            Application_for_Federal_Assistance__c oldRecord = oldMap.get(record.Id);
            if (oldRecord.Status__c != 'Submitted' && record.Status__c == 'Submitted') {
                if (record.Individual_Application__c != null) {
                    individualApplicationMap.put(record.Individual_Application__c, new IndividualApplication(Id = record.Individual_Application__c, Status = 'Submitted'));
                }
            }
        }

        if (!individualApplicationMap.isEmpty()) {
            update individualApplicationMap.values();
        }   
    }

    private static void insertLegacyApp(List<Application_for_Federal_Assistance__c> newList){ 
        List<Legacy_13424_Application__c> legacyApps = new List<Legacy_13424_Application__c>();

        for(Application_for_Federal_Assistance__c app : newList){ 
            if(app.version__c == 'Legacy'){ 
                Legacy_13424_Application__c legacyApp = new Legacy_13424_Application__c(Application_for_Federal_Assistance__c = app.Id);
                legacyApps.add(legacyApp);
            }
        }   

        insert legacyApps;


        Map<Id, Legacy_13424_Application__c> appIdToLegacyAppMap = new Map<Id, Legacy_13424_Application__c>();

        for (Legacy_13424_Application__c legacyApp : legacyApps) {
            appIdToLegacyAppMap.put(legacyApp.Application_for_Federal_Assistance__c, legacyApp);
        }

        List<Application_for_Federal_Assistance__c> appsToUpdate = new List<Application_for_Federal_Assistance__c>();

        for (Application_for_Federal_Assistance__c app : newList) {
            if (app.version__c == 'Legacy' && appIdToLegacyAppMap.containsKey(app.Id)) {
                Application_for_Federal_Assistance__c updatedApp = new Application_for_Federal_Assistance__c(
                    Id = app.Id,
                    Legacy13424Application__c = appIdToLegacyAppMap.get(app.Id).Id 
                );
                appsToUpdate.add(updatedApp);
            }
        }

        update appsToUpdate;
    }


    private static void validateContinuationFields(Application_for_Federal_Assistance__c record){ 
        Boolean isESL = record.Clinic_Services_and_Delivery_Model__c == 'ESL Education';
        Boolean isREA = record.Clinic_Services_and_Delivery_Model__c == 'Representation, Education, and Advocacy';

        if(record.Any_Major_Changes_to_your_program_plan__c == null) record.Any_Major_Changes_to_your_program_plan__c.addError('Clinic information: "Are your reporting major changes to your program plan" is Required');

        if(record.Any_Major_Changes_to_your_program_plan__c == 'Yes'){ 
            if(record.Any_Major_Changes_Geographic_Target__c == null) record.Any_Major_Changes_Geographic_Target__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Geographic area and target audience" is Required');
            if(record.Any_Major_Changes_Partners_Network__c == null) record.Any_Major_Changes_Partners_Network__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Partners and networks" is Required');
            if(record.Any_Major_Changes_Publicity_Outreach__c == null) record.Any_Major_Changes_Publicity_Outreach__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Publicity and outreach" is Required');
            if(record.Any_Major_Changes_GA_US_Tax_Court__c == null && isREA == true) record.Any_Major_Changes_GA_US_Tax_Court__c.addError('Taxpayer access, geographic area and target audience, outreach strategy: "Calendar call/Stuffer letter" is Required');
    
            if(record.Any_Major_Changes_Tax_Representation__c == null && isREA == true) record.Any_Major_Changes_Tax_Representation__c.addError('Taxpayer services: "Representation" is Required');
            if(record.Any_Major_Changes_Tax_Consultation__c == null && isREA == true) record.Any_Major_Changes_Tax_Consultation__c.addError('Taxpayer services: "Consultation" is Required');
            if(record.Any_Major_Changes_Tax_Education__c == null) record.Any_Major_Changes_Tax_Education__c.addError('Taxpayer services: "Taxpayer education" is Required');
            if(record.Any_Major_Changes_Tax_Advocacy__c == null) record.Any_Major_Changes_Tax_Advocacy__c.addError('Taxpayer services: "Advocacy" is Required');
    
            if(record.Any_Major_Changes_Other_Staff__c == null) record.Any_Major_Changes_Other_Staff__c.addError('Staffing: "Other staff" is Required');
            if(record.Any_Major_Changes_Staff_US_Tax_Court__c == null && isREA == true) record.Any_Major_Changes_Staff_US_Tax_Court__c.addError('Staffing: "U.S. Tax Court" is Required');
            if(record.Any_Major_Changes_Students__c == null) record.Any_Major_Changes_Students__c.addError('Staffing: "Students" is Required');
            
            if(record.Any_Major_Changes_Pro_Bono_Panel__c == null && isREA == true) record.Any_Major_Changes_Pro_Bono_Panel__c.addError('Volunteers: "Pro bono panel" is Required');
            if(record.Any_Major_Changes_Other_Vol_Rcrmnt__c == null) record.Any_Major_Changes_Other_Vol_Rcrmnt__c.addError('Volunteers: "Other volunteer recruitment" is Required');
            if(record.Any_Major_Changes_Vol_Rcrmnt_Rt__c == null) record.Any_Major_Changes_Vol_Rcrmnt_Rt__c.addError('Volunteers: "Volunteer recruitment and retention" is Required');
    
            if(record.Any_Major_Changes_Dates_Days_and_Hours__c == null) record.Any_Major_Changes_Dates_Days_and_Hours__c.addError('Clinic operations: "Dates, days, and hours of operation" is Required');
            if(record.Any_Major_Changes_Intake__c == null && isREA == true) record.Any_Major_Changes_Intake__c.addError('Clinic operations: "Intake" is Required');
            if(record.Any_Major_Changes_Household_Income__c == null && isREA == true) record.Any_Major_Changes_Household_Income__c.addError('Clinic operations: "Household income exceeding 250% of poverty" is Required');
            if(record.Any_Major_Changes_Amoun_Controversy__c == null && isREA == true) record.Any_Major_Changes_Amoun_Controversy__c.addError('Clinic operations: "Amount in controversy limit" is Required');
            if(record.Any_Major_Changes_Fees__c == null && isREA == true) record.Any_Major_Changes_Fees__c.addError('Clinic operations: "Fees" is Required');
            if(record.Any_Major_Changes_Case_Management__c == null && isREA == true) record.Any_Major_Changes_Case_Management__c.addError('Clinic operations: "Case management system" is Required');
            if(record.Any_Major_Changes_Case_Assignement__c == null && isREA == true) record.Any_Major_Changes_Case_Assignement__c.addError('Clinic operations: "Case assignment" is Required');
            if(record.Any_Major_Changes_Monitoring__c == null && isREA == true) record.Any_Major_Changes_Monitoring__c.addError('Clinic operations: "Monitoring" is Required');
            if(record.Any_Major_Changes_Time__c == null) record.Any_Major_Changes_Time__c.addError('Clinic operations: "Time" is Required');
            if(record.Any_Major_Changes_Complaint_Procedures__c == null) record.Any_Major_Changes_Complaint_Procedures__c.addError('Clinic operations: "Complaint procedures" is Required');
          
            if(record.Any_Major_Changes_Training_Resource__c == null) record.Any_Major_Changes_Training_Resource__c.addError('Training and resources: "Training/Resource" is Required');
            if(record.Any_Major_Changes_In_house_Training__c == null) record.Any_Major_Changes_In_house_Training__c.addError('Training and resources: "In-house training" is Required');
            if(record.Any_Major_Changes_External_Training__c == null) record.Any_Major_Changes_External_Training__c.addError('Training and resources: "External training" is Required');
            if(record.Any_Major_Changes_Research_Materials__c == null) record.Any_Major_Changes_Research_Materials__c.addError('Training and resources: "Research materials and software " is Required');
    
            if(record.Any_Major_Changes_Financial_Experience__c == null) record.Any_Major_Changes_Financial_Experience__c.addError('Financial responsibility: "Experience" is Required');
            if(record.Any_Major_Changes_Accounting_Procedure__c == null) record.Any_Major_Changes_Accounting_Procedure__c.addError('Financial responsibility: "Accounting procedures" is Required');
            if(record.Any_Major_Changes_Free_Tax_Preparation__c == null) record.Any_Major_Changes_Free_Tax_Preparation__c.addError('Financial responsibility: "Free tax preparation" is Required');
            if(record.Any_Major_Changes_Tracking_Grant__c == null) record.Any_Major_Changes_Tracking_Grant__c.addError('Financial responsibility: "Tracking Grant Expenditures" is Required');
            if(record.Any_Major_Changes_Audits_Fin_Reviews__c == null) record.Any_Major_Changes_Audits_Fin_Reviews__c.addError('Financial responsibility: "Audits or financial reviews" is Required');
        
            if(record.Any_Major_Changes_Program_Evaluation__c == null) record.Any_Major_Changes_Program_Evaluation__c.addError('Program information: "Program evaluation" is Required');
            if(record.Any_Major_Changes_Improvement__c == null) record.Any_Major_Changes_Improvement__c.addError('Program information: "Program improvement" is Required');
        }
    }
}