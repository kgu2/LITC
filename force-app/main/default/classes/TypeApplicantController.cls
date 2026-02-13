public with sharing class TypeApplicantController {

    public Application_for_Federal_Assistance__c application { get; set; }
    public Application_for_Federal_Assistance__c application_soql { get; set; }
    public String formattedTitle { get; private set; }
    public String areasAffectedbyProject { get; private set; }
    public String congressDistrictByProject { get; private set; }
    public String caller { get; set; }
    public Boolean IsOtherSelected { get; set; }
    public Boolean IsClinicDirectorOther { get; set; }
    public Boolean IsQTEOther { get; set; }
    public Boolean IsClinicMailingAddress { get; set; }
    public Boolean IsOrganizationOverviewPresent { get; set; }
    public Boolean IsExperiencePresent { get; set; }
    public Boolean IsTypeOfServicesProvidedPresent { get; set; }
    public Boolean IsClinicNamePresent { get; set; }
    public Boolean IsClinicTollFreeNumberPresent { get; set; }
    public Boolean IsClinicWebsitePresent { get; set; }
    public Boolean IsClinicStreetPresent { get; set; }
    public Boolean IsClinicStatePresent { get; set; }
    public Boolean IsClinicServicesModelPresent { get; set; }
    public Boolean IsClinicPublicPhonePresent { get; set; }
    public Boolean IsClinicFaxPresent { get; set; }
    public Boolean IsClinicCityPresent { get; set; }
    public Boolean IsClinicZipCodePresent { get; set; }
    public Boolean IsRepresentationPresent { get; set; }
    public Boolean IsClinicDirectorFirstNamePresent { get; set; }
    public Boolean IsClinicDirectorSuffixPresent { get; set; }
    public Boolean IsClinicDirectorEmailPresent { get; set; }
    public Boolean IsClinicDirectorLicensesPresent { get; set; }
    public Boolean IsClinicDirectorLastNamePresent { get; set; }
    public Boolean IsClinicDirectorMiddleInitialPresent { get; set; }
    public Boolean IsClinicDirectorTelephonePresent { get; set; }
    public Boolean IsQTEFirstNamePresent { get; set; }
    public Boolean IsQTELastNamePresent { get; set; }
    public Boolean IsQTESuffixPresent { get; set; }
    public Boolean IsQTEEmailPresent { get; set; }
    public Boolean IsQTEMiddleInitialPresent { get; set; }
    public Boolean IsQTETelephonePresent { get; set; }
    public Boolean IsQTELicensesPresent { get; set; }
    public Boolean IsQBAFirstNamePresent { get; set; }
    public Boolean IsQBALastNamePresent { get; set; }
    public Boolean IsQBASuffixPresent { get; set; }
    public Boolean IsQBAEmailPresent { get; set; }
    public Boolean IsQBAMiddleInitialPresent { get; set; }
    public Boolean IsQBAPhonePresent { get; set; }
    public Boolean IsTCOFirstNamePresent { get; set; }
    public Boolean IsTCOLastNamePresent { get; set; }
    public Boolean IsTCOSuffixPresent { get; set; }
    public Boolean IsTCOEmailPresent { get; set; }
    public Boolean IsTCOMiddleInitialPresent { get; set; }
    public Boolean IsTCOTitlePresent { get; set; }
    public Boolean IsTCOTelephonePresent { get; set; }
    public Boolean IsLanguageAccessPresent { get; set; }
    public Boolean IsOtherLanguageOptionsPresent { get; set; }
    public Boolean IsReasonableAccommodationsPresent { get; set; }
    public Boolean IsGeographicAreaPresent { get; set; }
    public Boolean IsTotalPopulationPresent { get; set; }
    public Boolean IsPartnersAndNetworksPresent { get; set; }
    public Boolean IsPublicityAndOutreachPresent { get; set; }
    public Boolean IsParticipationInProgramsPresent { get; set; }
    public Boolean IsParticipationTypesPresent { get; set; }
    public Boolean IsFutureParticipationPresent { get; set; }
    public Boolean IsControversyRepresentationScopePresent { get; set; }
    public Boolean IsConsultationServiceProvidedPresent { get; set; }
    public Boolean IsTaxpayerEducationPresent { get; set; }
    public Boolean IsAdvocacyPresent { get; set; }
    public Boolean IsQTEPositionFilledByVolunteerPresent { get; set; }
    public Boolean IsQTEIdentifiedHiredPresent { get; set; }
    public Boolean IsQTELicenseNumberPresent { get; set; }
    public Boolean IsQTEUSTaxCourtNumberPresent { get; set; }
    public Boolean IsQTEResponsibilitiesQualificationsPresent { get; set; }
    public Boolean IsQTEJobDescriptionPresent { get; set; }
    public Boolean IsClinicDirectorIdentifiedHiredPresent { get; set; }
    public Boolean IsClinicDirectorStatesOfLicensurePresent { get; set; }
    public Boolean IsClinicDirectorLicenseNumberPresent { get; set; }
    public Boolean IsClinicDirectorUSTaxCourtNumberPresent { get; set; }
    public Boolean IsClinicDirectorResponsibilitiesQualificationsPresent { get; set; }
    public Boolean IsClinicDirectorJobDescriptionPresent { get; set; }
    public Boolean IsQBALicensesCertificationsPresent { get; set; }
    public Boolean IsQBAIdentifiedHiredPresent { get; set; }
    public Boolean IsQBAResponsibilitiesQualificationsPresent { get; set; }
    public Boolean IsQBAJobDescriptionPresent { get; set; }
    public Boolean IsUSTaxCourtNarrativePresent { get; set; }
    public Boolean IsStudentsPerSemesterTypePresent { get; set; }
    public Boolean IsStudentPermissionToBeObtainedPresent { get; set; }
    public Boolean IsVolunteerProBonoPanelPresent { get; set; }
    public Boolean IsOtherVolunteerRecruitmentPresent { get; set; }
    public Boolean IsDatesOfOperationPresent { get; set; }
    public Boolean IsContinuityOfServicesPresent { get; set; }
    public Boolean IsDay1HoursPresent { get; set; }
    public Boolean IsDay2HoursPresent { get; set; }
    public Boolean IsDay3HoursPresent { get; set; }
    public Boolean IsDay4HoursPresent { get; set; }
    public Boolean IsDay5HoursPresent { get; set; }
    public Boolean IsDay6HoursPresent { get; set; }
    public Boolean IsDay7HoursPresent { get; set; }
    public Boolean IsHoursExceptionsForEmergenciesPresent { get; set; }
    public Boolean IsAfterHoursOrWeekendServicePresent { get; set; }
    public Boolean IsIntakeProcessPresent { get; set; }
    public Boolean IsHouseholdIncomeExceeding250Present { get; set; }
    public Boolean IsCasesExceeding250DescriptionPresent { get; set; }
    public Boolean IsAmountInControversyLimitPresent { get; set; }
    public Boolean IsCasesExceedingAmountDescriptionPresent { get; set; }
    public Boolean IsNominalFeePresent { get; set; }
    public Boolean IsNominalFeeDescriptionPresent { get; set; }
    public Boolean IsCaseManagementSystemPresent { get; set; }
    public Boolean IsCaseAssignmentProceduresPresent { get; set; }
    public Boolean IsCaseMonitoringPresent { get; set; }
    public Boolean IsTimeTrackingPresent { get; set; }
    public Boolean IsCollectingTaxpayerInformationPresent { get; set; }
    public Boolean IsProtectingTaxpayerPrivacyPresent { get; set; }
    public Boolean IsComplaintProceduresPresent { get; set; }
    public Boolean IsTrainingAndResourcesPresent { get; set; }
    public Boolean IsInHouseTrainingPresent { get; set; }
    public Boolean IsExternalTrainingPresent { get; set; }
    public Boolean IsResearchMaterialsAndSoftwarePresent { get; set; }
    public Boolean IsExperienceManagingGrantsPresent { get; set; }
    public Boolean IsAccountingProceduresPresent { get; set; }
    public Boolean IsFreeTaxPreparationPresent { get; set; }
    public Boolean IsVITAOrTCESiteFundingPresent { get; set; }
    public Boolean IsTrackingGrantExpendituresPresent { get; set; }
    public Boolean IsAuditsOrFinancialReviewsPresent { get; set; }
    public Boolean IsFinancialStatementInformationPresent { get; set; }
    public Boolean IsFinancialStatementTypePresent { get; set; }
    public Boolean IsSingleAuditCompliancePresent { get; set; }
    public Boolean IsAuditClearinghouseAvailabilityPresent { get; set; }
    public Boolean IsLegalServicesCorporationFundingPresent { get; set; }
    public Boolean IsProgramEvaluationPresent { get; set; }
    public Boolean IsProgramImprovementPresent { get; set; }
    public Boolean IsProgramNumericalGoalsNarrativePresent { get; set; }
    public Boolean IsNewRepresentationCasesPresent { get; set; }
    public Boolean IsConsultationsWithLowIncomeESLPresent { get; set; }
    public Boolean IsActiveLawsuitsOrComplaintsPresent { get; set; }
    public Boolean IsListOfActiveLawsuitsOrComplaintsPresent { get; set; }
    public Boolean IsFederalFinancialAssistancePresent { get; set; }
    public Boolean IsCivilRightsReviewActivityPresent { get; set; }
    public Boolean IsDataCompilationAndMaintenancePresent { get; set; }
    public Boolean IsPublicDisplayOfCivilRightsPosterPresent { get; set; }
  
    public String formattedYearEndDate {
        get {
            return getFormattedYearEndDate();
        }
    }

    public TypeApplicantController(ApexPages.StandardController stdController) {
        this.application = (Application_for_Federal_Assistance__c)stdController.getRecord();
        Id recordId = stdController.getId();

        // Query the record explicitly with the required fields
        this.application_soql = [
            SELECT Id, Organization_Overview__c, Experience__c, Type_of_Services_Provided__c,
            Clinic_Name__c, Clinic_Toll_Free_tele_num_if_applicable__c,Title_Applicant_Project__c,
            Areas_affected_by_project__c,Congressional_district_by_project__c, 
            Clinic_Website_address_if_applicable__c, Clinic_Mailing_Address__c, 
            Clinic_Street__c, Clinic_State__c, Clinic_Services_and_Delivery_Model__c, 
            Clinic_Public_telephone_number__c, Clinic_FAX_number__c, Clinic_City__c, 
            Clinic_Zip_Code__c, Representation__c, Type_of_Applicant_1__c, 
            Clinic_Director_Licenses_Certifications__c, QTE_Licenses_Certifications__c, 
            Organizational_UEI__c, Year_end_Date_of_Financials__c, 
            Clinic_Director_First_name__c, Clinic_Director_Suffix__c, 
            Clinic_Director_Email_address__c, Clinic_Director_Last_name__c, 
            Clinic_Director_Middle_initial__c, Clinic_Director_Telephone_number__c, 
            QTE_First_name__c, QTE_Last_name__c, QTE_Suffix__c, QTE_Email_address__c, 
            QTE_Middle_initial__c, QTE_Telephone_number__c, 
            QBA_First_name__c, QBA_Last_name__c, QBA_Suffix__c, 
            QBA_Email_address__c, QBA_Middle_initial__c, QBA_Telephone_number__c,
            TCO_First_name__c, TCO_Last_name__c, TCO_Suffix__c, TCO_Email_address__c, 
            TCO_Middle_initial__c, TCO_Title__c, TCO_Telephone_number__c,
            Language_Access__c, Other_Language_Options__c, Reasonable_Accommodations__c, 
            Geographic_Area_and_Target_Audience__c, Total_Population__c, 
            Partners_and_Networks__c, Publicity_and_Outreach_Methods__c, 
            Participation_in_Programs__c, Participation_Types__c, Future_Participation__c,
            Controversy_Representation_Scope__c, Consulation_Service_to_be_provided__c, 
            Taxpayer_Education__c, Advocacy__c,QTE_Position_filled_by_Volunteer__c, QTE_Identified_Hired__c, QTE_License_Number__c, 
            QTE_US_Tax_Court_Number__c, QTE_Responsibilities_Qualifications__c, QTE_Job_Description__c, 
            Clinic_Director_Identified_Hired__c, Clinic_Director_State_s_of_Licensure__c, 
            Clinic_Director_License_Number__c, Clinic_Director_US_Tax_Court_Number__c, 
            CD_Responsibilities_Qualifications__c, Clinic_Director_Job_Description__c, 
            QBA_Licenses_Certifications__c, QBA_Identified_Hired__c, QBA_Responsibilities_Qualifications__c, 
            QBA_Job_Description__c, US_Tax_Court_Narrative__c, Student_s_Per_Semester_Type__c, 
            Student_Permission_to_be_Obtained__c, Volunteer_Pro_Bono_Panel__c, Other_Volunteer_Recruitment__c,
            Dates_of_Operation__c, Continuity_of_Services__c, 
            Day_1_Hours__c, Day_2_Hours__c, 
            Day_3_Hours__c, Day_4_Hours__c, Day_5_Hours__c, Day_6_Hours__c, Day_7_Hours__c, 
            Hours_Exceptions_for_Emergencies__c, After_Hours_or_Weekend_Service__c, Intake_Process__c,
             Household_Income_Exceeding_250_of_Pover__c, Cases_Exceeding_250_of_FPL_Description__c, 
        Amount_in_Controversy_Limit__c, Cases_Exceed_Amt_in_Contro_Limit_Desc__c, 
        Nominal_Fee__c, Nominal_Fee_Description__c, Case_Management_System__c, 
        Case_Assignment_Procedures__c, Case_Monitoring__c, Time_Tracking__c, 
        Collecting_Taxpayer_Information__c, Protecting_Taxpayer_Privacy__c, 
        Complaint_Procedures__c, Training_and_Resources__c, In_house_Training__c, 
        External_Training__c, Research_Materials_and_Software__c, 
        Experience_Managing_Grants__c, Accounting_Procedures__c, Free_Tax_Preparation__c, 
        VITA_or_TCE_Site_Funding__c, Tracking_Grant_Expenditures__c, 
        Audits_or_Financial_Reviews__c, Financial_Statement_Information__c, 
        Financial_Statement_Type__c, Single_Audit_Compliance__c, 
        Audit_Clearinghouse_Availability__c, Legal_Services_Corporation_Funding__c, 
        Program_Evaluation__c, Program_Improvement__c, 
        Program_Numerical_Goals_Narrative__c, New_Representation_Cases__c, 
        Consultations_with_Low_Income_ESL__c, Active_Lawsuits_or_Complaints__c, 
        List_of_Active_Lawsuits_or_Complaints__c, Federal_Financial_Assistance__c, 
        Civil_Rights_Review_Activity__c, Data_Compilation_and_Maintenance__c, 
        Public_Display_of_Civil_Rights_Poster__c
            FROM Application_for_Federal_Assistance__c
            WHERE Id = :recordId
        ];
        this.caller = ApexPages.currentPage().getParameters().get('caller');
        this.IsOtherSelected = getIsOtherSelected();
        this.IsClinicDirectorOther = getIsClinicDirectorOther();
        this.IsQTEOther = getIsQTEOther();
        this.IsClinicMailingAddress = getClinicMailingAddress();
        this.IsOrganizationOverviewPresent = getOrganizationOverviewPresent();
        this.IsExperiencePresent = getExperiencePresent();
        this.IsTypeOfServicesProvidedPresent = getTypeOfServicesProvidedPresent();
        this.IsClinicNamePresent = getClinicNamePresent();
        this.IsClinicTollFreeNumberPresent = getClinicTollFreeNumberPresent();
        this.IsClinicWebsitePresent = getClinicWebsitePresent();
        this.IsClinicStreetPresent = getClinicStreetPresent();
        this.IsClinicStatePresent = getClinicStatePresent();
        this.IsClinicServicesModelPresent = getClinicServicesModelPresent();
        this.IsClinicPublicPhonePresent = getClinicPublicPhonePresent();
        this.IsClinicFaxPresent = getClinicFaxPresent();
        this.IsClinicCityPresent = getClinicCityPresent();
        this.IsClinicZipCodePresent = getClinicZipCodePresent();
        this.IsRepresentationPresent = getRepresentationPresent();
        this.IsClinicDirectorFirstNamePresent = getClinicDirectorFirstNamePresent();
        this.IsClinicDirectorSuffixPresent = getClinicDirectorSuffixPresent();
        this.IsClinicDirectorEmailPresent = getClinicDirectorEmailPresent();
        this.IsClinicDirectorLicensesPresent = getClinicDirectorLicensesPresent();
        this.IsClinicDirectorLastNamePresent = getClinicDirectorLastNamePresent();
        this.IsClinicDirectorMiddleInitialPresent = getClinicDirectorMiddleInitialPresent();
        this.IsClinicDirectorTelephonePresent = getClinicDirectorTelephonePresent();
        this.IsQTEFirstNamePresent = getQTEFirstNamePresent();
        this.IsQTELastNamePresent = getQTELastNamePresent();
        this.IsQTESuffixPresent = getQTESuffixPresent();
        this.IsQTEEmailPresent = getQTEEmailPresent();
        this.IsQTEMiddleInitialPresent = getQTEMiddleInitialPresent();
        this.IsQTETelephonePresent = getQTETelephonePresent();
        this.IsQTELicensesPresent = getQTELicensesPresent();
        this.IsQBAFirstNamePresent = getQBAFirstNamePresent();
        this.IsQBALastNamePresent = getQBALastNamePresent();
        this.IsQBASuffixPresent = getQBASuffixPresent();
        this.IsQBAEmailPresent = getQBAEmailPresent();
        this.IsQBAMiddleInitialPresent = getQBAMiddleInitialPresent();
        this.IsQBAPhonePresent = getQBAPhonePresent();
        this.IsTCOFirstNamePresent = getTCOFirstNamePresent();
        this.IsTCOLastNamePresent = getTCOLastNamePresent();
        this.IsTCOSuffixPresent = getTCOSuffixPresent();
        this.IsTCOEmailPresent = getTCOEmailPresent();
        this.IsTCOMiddleInitialPresent = getTCOMiddleInitialPresent();
        this.IsTCOTitlePresent = getTCOTitlePresent();
        this.IsTCOTelephonePresent = getTCOTelephonePresent();
        this.IsLanguageAccessPresent = getLanguageAccessPresent();
        this.IsOtherLanguageOptionsPresent = getOtherLanguageOptionsPresent();
        this.IsReasonableAccommodationsPresent = getReasonableAccommodationsPresent();
        this.IsGeographicAreaPresent = getGeographicAreaPresent();
        this.IsTotalPopulationPresent = getTotalPopulationPresent();
        this.IsPartnersAndNetworksPresent = getPartnersAndNetworksPresent();
        this.IsPublicityAndOutreachPresent = getPublicityAndOutreachPresent();
        this.IsParticipationInProgramsPresent = getParticipationInProgramsPresent();
        this.IsParticipationTypesPresent = getParticipationTypesPresent();
        this.IsFutureParticipationPresent = getFutureParticipationPresent();      
        this.IsControversyRepresentationScopePresent = getControversyRepresentationScopePresent();
        this.IsConsultationServiceProvidedPresent = getConsultationServiceProvidedPresent();
        this.IsTaxpayerEducationPresent = getTaxpayerEducationPresent();
        this.IsAdvocacyPresent = getAdvocacyPresent();
        this.IsQTEPositionFilledByVolunteerPresent = getQTEPositionFilledByVolunteerPresent();
        this.IsQTEIdentifiedHiredPresent = getQTEIdentifiedHiredPresent();
        this.IsQTELicenseNumberPresent = getQTELicenseNumberPresent();
        this.IsQTEUSTaxCourtNumberPresent = getQTEUSTaxCourtNumberPresent();
        this.IsQTEResponsibilitiesQualificationsPresent = getQTEResponsibilitiesQualificationsPresent();
        this.IsQTEJobDescriptionPresent = getQTEJobDescriptionPresent();
        this.IsClinicDirectorIdentifiedHiredPresent = getClinicDirectorIdentifiedHiredPresent();
        this.IsClinicDirectorStatesOfLicensurePresent = getClinicDirectorStatesOfLicensurePresent();
        this.IsClinicDirectorLicenseNumberPresent = getClinicDirectorLicenseNumberPresent();
        this.IsClinicDirectorUSTaxCourtNumberPresent = getClinicDirectorUSTaxCourtNumberPresent();
        this.IsClinicDirectorResponsibilitiesQualificationsPresent = getClinicDirectorResponsibilitiesQualificationsPresent();
        this.IsClinicDirectorJobDescriptionPresent = getClinicDirectorJobDescriptionPresent();
        this.IsQBALicensesCertificationsPresent = getQBALicensesCertificationsPresent();
        this.IsQBAIdentifiedHiredPresent = getQBAIdentifiedHiredPresent();
        this.IsQBAResponsibilitiesQualificationsPresent = getQBAResponsibilitiesQualificationsPresent();
        this.IsQBAJobDescriptionPresent = getQBAJobDescriptionPresent();
        this.IsUSTaxCourtNarrativePresent = getUSTaxCourtNarrativePresent();
        this.IsStudentsPerSemesterTypePresent = getStudentsPerSemesterTypePresent();
        this.IsStudentPermissionToBeObtainedPresent = getStudentPermissionToBeObtainedPresent();
        this.IsVolunteerProBonoPanelPresent = getVolunteerProBonoPanelPresent();
        this.IsOtherVolunteerRecruitmentPresent = getOtherVolunteerRecruitmentPresent();
        this.IsDatesOfOperationPresent = getDatesOfOperationPresent();
        this.IsContinuityOfServicesPresent = getContinuityOfServicesPresent();
        // this.IsDay1HoursPresent = getDay1HoursPresent();
        // this.IsDay2HoursPresent = getDay2HoursPresent();
        // this.IsDay3HoursPresent = getDay3HoursPresent();
        // this.IsDay4HoursPresent = getDay4HoursPresent();
        // this.IsDay5HoursPresent = getDay5HoursPresent();
        // this.IsDay6HoursPresent = getDay6HoursPresent();
        // this.IsDay7HoursPresent = getDay7HoursPresent();
        this.IsHoursExceptionsForEmergenciesPresent = getHoursExceptionsForEmergenciesPresent();
        this.IsAfterHoursOrWeekendServicePresent = getAfterHoursOrWeekendServicePresent();
        this.IsIntakeProcessPresent = getIntakeProcessPresent();
        this.IsHouseholdIncomeExceeding250Present = getHouseholdIncomeExceeding250Present();
        this.IsCasesExceeding250DescriptionPresent = getCasesExceeding250DescriptionPresent();
        this.IsAmountInControversyLimitPresent = getAmountInControversyLimitPresent();
        this.IsCasesExceedingAmountDescriptionPresent = getCasesExceedingAmountDescriptionPresent();
        this.IsNominalFeePresent = getNominalFeePresent();
        this.IsNominalFeeDescriptionPresent = getNominalFeeDescriptionPresent();
        this.IsCaseManagementSystemPresent = getCaseManagementSystemPresent();
        this.IsCaseAssignmentProceduresPresent = getCaseAssignmentProceduresPresent();
        this.IsCaseMonitoringPresent = getCaseMonitoringPresent();
        this.IsTimeTrackingPresent = getTimeTrackingPresent();
        this.IsCollectingTaxpayerInformationPresent = getCollectingTaxpayerInformationPresent();
        this.IsProtectingTaxpayerPrivacyPresent = getProtectingTaxpayerPrivacyPresent();
        this.IsComplaintProceduresPresent = getComplaintProceduresPresent();
        this.IsTrainingAndResourcesPresent = getTrainingAndResourcesPresent();
        this.IsInHouseTrainingPresent = getInHouseTrainingPresent();
        this.IsExternalTrainingPresent = getExternalTrainingPresent();
        this.IsResearchMaterialsAndSoftwarePresent = getResearchMaterialsAndSoftwarePresent();
        this.IsExperienceManagingGrantsPresent = getExperienceManagingGrantsPresent();
        this.IsAccountingProceduresPresent = getAccountingProceduresPresent();
        this.IsFreeTaxPreparationPresent = getFreeTaxPreparationPresent();
        this.IsVITAOrTCESiteFundingPresent = getVITAOrTCESiteFundingPresent();
        this.IsTrackingGrantExpendituresPresent = getTrackingGrantExpendituresPresent();
        this.IsAuditsOrFinancialReviewsPresent = getAuditsOrFinancialReviewsPresent();
        this.IsFinancialStatementInformationPresent = getFinancialStatementInformationPresent();
        this.IsFinancialStatementTypePresent = getFinancialStatementTypePresent();
        this.IsSingleAuditCompliancePresent = getSingleAuditCompliancePresent();
        this.IsAuditClearinghouseAvailabilityPresent = getAuditClearinghouseAvailabilityPresent();
        this.IsLegalServicesCorporationFundingPresent = getLegalServicesCorporationFundingPresent();
        this.IsProgramEvaluationPresent = getProgramEvaluationPresent();
        this.IsProgramImprovementPresent = getProgramImprovementPresent();
        this.IsProgramNumericalGoalsNarrativePresent = getProgramNumericalGoalsNarrativePresent();
        this.IsNewRepresentationCasesPresent = getNewRepresentationCasesPresent();
        this.IsConsultationsWithLowIncomeESLPresent = getConsultationsWithLowIncomeESLPresent();
        this.IsActiveLawsuitsOrComplaintsPresent = getActiveLawsuitsOrComplaintsPresent();
        this.IsListOfActiveLawsuitsOrComplaintsPresent = getListOfActiveLawsuitsOrComplaintsPresent();
        this.IsFederalFinancialAssistancePresent = getFederalFinancialAssistancePresent();
        this.IsCivilRightsReviewActivityPresent = getCivilRightsReviewActivityPresent();
        this.IsDataCompilationAndMaintenancePresent = getDataCompilationAndMaintenancePresent();
        this.IsPublicDisplayOfCivilRightsPosterPresent = getPublicDisplayOfCivilRightsPosterPresent();

        this.formattedTitle = formatString(this.application_soql.Title_Applicant_Project__c);
        this.areasAffectedbyProject = formatString(this.application_soql.Areas_affected_by_project__c);
        this.congressDistrictByProject = formatString(this.application_soql.Congressional_district_by_project__c);
        
    }

    public String formatString(String input) {
        if (String.isEmpty(input)) {
            return input; // Return as-is if input is empty
        }

        String result = ''; // Start with an empty string

        // Split after the first 40 characters
        if (input.length() > 52) {
            result += input.substring(0, 48) + ' '; // Append the first 40 characters
            input = input.substring(52); // Remaining string
        } else {
            return input; // No need to split if less than 40 characters
        }

        // Add spaces after every 65 characters for the remaining string
        Integer chunkSize = 78;
        while (input.length() > chunkSize) {
            result += input.substring(0, chunkSize) + ' ';
            input = input.substring(chunkSize);
        }

        // Append the remaining part
        result += input;

        return result.trim();
    }

    private Boolean getIsOtherSelected() {
        if (caller == 'SF424') {
            return application.Type_of_Applicant_1__c != null &&
                   application.Type_of_Applicant_1__c.contains('X. Other (specify)');
        } else {
            return false;
        }
    }

    private Boolean getIsClinicDirectorOther() {
        if (caller == 'SF13424M') {
            return application.Clinic_Director_Licenses_Certifications__c != null && application.Clinic_Director_Licenses_Certifications__c.contains('Other');
        } else {
            return false;
        }
    }

    private Boolean getIsQTEOther() {
        if (caller == 'SF13424M') {
            return application.QTE_Licenses_Certifications__c != null &&
                   application.QTE_Licenses_Certifications__c.contains('Other');
        } else {
            return false;
        }
    }

    private Boolean getClinicMailingAddress() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Mailing_Address__c) ? true : false;
        } else  {
            return false;
        }
    }

    private Boolean getOrganizationOverviewPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Organization_Overview__c);
        } else {
            return false;
        }
    }

    private Boolean getExperiencePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Experience__c);
        } else {
            return false;
        }
    }

    private Boolean getTypeOfServicesProvidedPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Type_of_Services_Provided__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Name__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicTollFreeNumberPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Toll_Free_tele_num_if_applicable__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicWebsitePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Website_address_if_applicable__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicStreetPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Street__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicStatePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_State__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicServicesModelPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Services_and_Delivery_Model__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicPublicPhonePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Public_telephone_number__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicFaxPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_FAX_number__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicCityPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_City__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicZipCodePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Zip_Code__c);
        } else {
            return false;
        }
    }

    private Boolean getRepresentationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Representation__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorFirstNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_First_name__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorSuffixPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Suffix__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorEmailPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Email_address__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorLicensesPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Licenses_Certifications__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorLastNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Last_name__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorMiddleInitialPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Middle_initial__c);
        } else {
            return false;
        }
    }

    private Boolean getClinicDirectorTelephonePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Telephone_number__c);
        } else {
            return false;
        }
    }

    private Boolean getQTEFirstNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_First_name__c);
        } else {
            return false;
        }
    }

    private Boolean getQTELastNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Last_name__c);
        } else {
            return false;
        }
    }

    private Boolean getQTESuffixPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Suffix__c);
        } else {
            return false;
        }
    }

    private Boolean getQTEEmailPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Email_address__c);
        } else {
            return false;
        }
    }

    private Boolean getQTEMiddleInitialPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Middle_initial__c);
        } else {
            return false;
        }
    }

    private Boolean getQTETelephonePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Telephone_number__c);
        } else {
            return false;
        }
    }

    private Boolean getQTELicensesPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Licenses_Certifications__c);
        } else {
            return false;
        }
    }

    private Boolean getQBAFirstNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_First_name__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBALastNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Last_name__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBASuffixPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Suffix__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBAEmailPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Email_address__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBAMiddleInitialPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Middle_initial__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBAPhonePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Telephone_number__c);
        } else {
            return false;
        }
    }
    private Boolean getTCOFirstNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_First_name__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTCOLastNamePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_Last_name__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTCOSuffixPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_Suffix__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTCOEmailPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_Email_address__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTCOMiddleInitialPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_Middle_initial__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTCOTitlePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_Title__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTCOTelephonePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.TCO_Telephone_number__c);
        } else {
            return false;
        }
    }
   
    private Boolean getLanguageAccessPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Language_Access__c);
        } else {
            return false;
        }
    }
    
    private Boolean getOtherLanguageOptionsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Other_Language_Options__c);
        } else {
            return false;
        }
    }
    
    private Boolean getReasonableAccommodationsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Reasonable_Accommodations__c);
        } else {
            return false;
        }
    }
    
    private Boolean getGeographicAreaPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Geographic_Area_and_Target_Audience__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTotalPopulationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Total_Population__c);
        } else {
            return false;
        }
    }
    
    private Boolean getPartnersAndNetworksPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Partners_and_Networks__c);
        } else {
            return false;
        }
    }
    
    private Boolean getPublicityAndOutreachPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Publicity_and_Outreach_Methods__c);
        } else {
            return false;
        }
    }
    
    private Boolean getParticipationInProgramsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Participation_in_Programs__c);
        } else {
            return false;
        }
    }
    
    private Boolean getParticipationTypesPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Participation_Types__c);
        } else {
            return false;
        }
    }
    
    private Boolean getFutureParticipationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Future_Participation__c);
        } else {
            return false;
        }
    }
    private Boolean getControversyRepresentationScopePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Controversy_Representation_Scope__c);
        } else {
            return false;
        }
    }
    
    private Boolean getConsultationServiceProvidedPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Consulation_Service_to_be_provided__c);
        } else {
            return false;
        }
    }
    
    private Boolean getTaxpayerEducationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Taxpayer_Education__c);
        } else {
            return false;
        }
    }
    
    private Boolean getAdvocacyPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Advocacy__c);
        } else {
            return false;
        }
    }
        
    private Boolean getQTEPositionFilledByVolunteerPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Position_filled_by_Volunteer__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQTEIdentifiedHiredPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Identified_Hired__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQTELicenseNumberPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_License_Number__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQTEUSTaxCourtNumberPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_US_Tax_Court_Number__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQTEResponsibilitiesQualificationsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Responsibilities_Qualifications__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQTEJobDescriptionPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QTE_Job_Description__c);
        } else {
            return false;
        }
    }
    
    private Boolean getClinicDirectorIdentifiedHiredPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Identified_Hired__c);
        } else {
            return false;
        }
    }
    
    private Boolean getClinicDirectorStatesOfLicensurePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_State_s_of_Licensure__c);
        } else {
            return false;
        }
    }
    
    private Boolean getClinicDirectorLicenseNumberPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_License_Number__c);
        } else {
            return false;
        }
    }
    
    private Boolean getClinicDirectorUSTaxCourtNumberPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_US_Tax_Court_Number__c);
        } else {
            return false;
        }
    }
    
    private Boolean getClinicDirectorResponsibilitiesQualificationsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.CD_Responsibilities_Qualifications__c);
        } else {
            return false;
        }
    }
    
    private Boolean getClinicDirectorJobDescriptionPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Clinic_Director_Job_Description__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBALicensesCertificationsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Licenses_Certifications__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBAIdentifiedHiredPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Identified_Hired__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBAResponsibilitiesQualificationsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Responsibilities_Qualifications__c);
        } else {
            return false;
        }
    }
    
    private Boolean getQBAJobDescriptionPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.QBA_Job_Description__c);
        } else {
            return false;
        }
    }
    
    private Boolean getUSTaxCourtNarrativePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.US_Tax_Court_Narrative__c);
        } else {
            return false;
        }
    }
    
    private Boolean getStudentsPerSemesterTypePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Student_s_Per_Semester_Type__c);
        } else {
            return false;
        }
    }
    
    private Boolean getStudentPermissionToBeObtainedPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Student_Permission_to_be_Obtained__c);
        } else {
            return false;
        }
    }
    
    private Boolean getVolunteerProBonoPanelPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Volunteer_Pro_Bono_Panel__c);
        } else {
            return false;
        }
    }
    
    private Boolean getOtherVolunteerRecruitmentPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Other_Volunteer_Recruitment__c);
        } else {
            return false;
        }
    }
    private Boolean getDatesOfOperationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Dates_of_Operation__c);
        } else {
            return false;
        }
    }
    
    private Boolean getContinuityOfServicesPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Continuity_of_Services__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay1HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_1_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay2HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_2_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay3HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_3_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay4HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_4_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay5HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_5_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay6HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_6_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getDay7HoursPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Day_7_Hours__c);
        } else {
            return false;
        }
    }
    
    private Boolean getHoursExceptionsForEmergenciesPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Hours_Exceptions_for_Emergencies__c);
        } else {
            return false;
        }
    }
    
    private Boolean getAfterHoursOrWeekendServicePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.After_Hours_or_Weekend_Service__c);
        } else {
            return false;
        }
    }
    
    private Boolean getIntakeProcessPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Intake_Process__c);
        } else {
            return false;
        }
    }
        
    private Boolean getHouseholdIncomeExceeding250Present() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Household_Income_Exceeding_250_of_Pover__c);
        }
        return false;
    }
    
    private Boolean getCasesExceeding250DescriptionPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Cases_Exceeding_250_of_FPL_Description__c);
        }
        return false;
    }
    
    private Boolean getAmountInControversyLimitPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Amount_in_Controversy_Limit__c);
        }
        return false;
    }
    
    private Boolean getCasesExceedingAmountDescriptionPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Cases_Exceed_Amt_in_Contro_Limit_Desc__c);
        }
        return false;
    }
    
    private Boolean getNominalFeePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Nominal_Fee__c);
        }
        return false;
    }
    
    private Boolean getNominalFeeDescriptionPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Nominal_Fee_Description__c);
        }
        return false;
    }
    
    private Boolean getCaseManagementSystemPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Case_Management_System__c);
        }
        return false;
    }
    
    private Boolean getCaseAssignmentProceduresPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Case_Assignment_Procedures__c);
        }
        return false;
    }
    
    private Boolean getCaseMonitoringPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Case_Monitoring__c);
        }
        return false;
    }
    
    private Boolean getTimeTrackingPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Time_Tracking__c);
        }
        return false;
    }
    
    private Boolean getCollectingTaxpayerInformationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Collecting_Taxpayer_Information__c);
        }
        return false;
    }
    
    private Boolean getProtectingTaxpayerPrivacyPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Protecting_Taxpayer_Privacy__c);
        }
        return false;
    }
    
    private Boolean getComplaintProceduresPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Complaint_Procedures__c);
        }
        return false;
    }
    
    private Boolean getTrainingAndResourcesPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Training_and_Resources__c);
        }
        return false;
    }
    
    private Boolean getInHouseTrainingPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.In_house_Training__c);
        }
        return false;
    }
    
    private Boolean getExternalTrainingPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.External_Training__c);
        }
        return false;
    }
    
    private Boolean getResearchMaterialsAndSoftwarePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Research_Materials_and_Software__c);
        }
        return false;
    }
    
    private Boolean getExperienceManagingGrantsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Experience_Managing_Grants__c);
        }
        return false;
    }
    
    private Boolean getAccountingProceduresPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Accounting_Procedures__c);
        }
        return false;
    }
    
    private Boolean getFreeTaxPreparationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Free_Tax_Preparation__c);
        }
        return false;
    }
    
    private Boolean getVITAOrTCESiteFundingPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.VITA_or_TCE_Site_Funding__c);
        }
        return false;
    }
    
    private Boolean getTrackingGrantExpendituresPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Tracking_Grant_Expenditures__c);
        }
        return false;
    }
    
    private Boolean getAuditsOrFinancialReviewsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Audits_or_Financial_Reviews__c);
        }
        return false;
    }
    
    private Boolean getFinancialStatementInformationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Financial_Statement_Information__c);
        }
        return false;
    }
    
    private Boolean getFinancialStatementTypePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Financial_Statement_Type__c);
        }
        return false;
    }
    
    private Boolean getSingleAuditCompliancePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Single_Audit_Compliance__c);
        }
        return false;
    }
    
    private Boolean getAuditClearinghouseAvailabilityPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Audit_Clearinghouse_Availability__c);
        }
        return false;
    }
    
    private Boolean getLegalServicesCorporationFundingPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Legal_Services_Corporation_Funding__c);
        }
        return false;
    }
    
    private Boolean getProgramEvaluationPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Program_Evaluation__c);
        }
        return false;
    }
    
    private Boolean getProgramImprovementPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Program_Improvement__c);
        }
        return false;
    }
    
    private Boolean getProgramNumericalGoalsNarrativePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Program_Numerical_Goals_Narrative__c);
        }
        return false;
    }
    
    private Boolean getNewRepresentationCasesPresent() {
        if (caller == 'SF13424M') {
            return application_soql.New_Representation_Cases__c != null && application_soql.New_Representation_Cases__c != 0;
        }
        return false;
    }
    
    private Boolean getConsultationsWithLowIncomeESLPresent() {
        if (caller == 'SF13424M') {
            return application_soql.Consultations_with_Low_Income_ESL__c != null && application_soql.Consultations_with_Low_Income_ESL__c != 0;
        }
        return false;
    }
    
    private Boolean getActiveLawsuitsOrComplaintsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Active_Lawsuits_or_Complaints__c);
        }
        return false;
    }
    
    private Boolean getListOfActiveLawsuitsOrComplaintsPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.List_of_Active_Lawsuits_or_Complaints__c);
        }
        return false;
    }
    
    private Boolean getFederalFinancialAssistancePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Federal_Financial_Assistance__c);
        }
        return false;
    }
    
    private Boolean getCivilRightsReviewActivityPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Civil_Rights_Review_Activity__c);
        }
        return false;
    }
    
    private Boolean getDataCompilationAndMaintenancePresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Data_Compilation_and_Maintenance__c);
        }
        return false;
    }
    
    private Boolean getPublicDisplayOfCivilRightsPosterPresent() {
        if (caller == 'SF13424M') {
            return !String.isBlank(application_soql.Public_Display_of_Civil_Rights_Poster__c);
        }
        return false;
    }
    
    
    private String getFormattedYearEndDate() {
        if (application.Year_end_Date_of_Financials__c != null) {
            Date yearEndDate = application.Year_end_Date_of_Financials__c;
            // Convert Date to DateTime and format as MM/dd/yyyy
            return DateTime.newInstance(yearEndDate.year(), yearEndDate.month(), yearEndDate.day()).format('MM/dd/yyyy');
        }
        return null;
    }
}