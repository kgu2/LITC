public with sharing class NTA_Review_PDF_Controller {
    public String fileName {get; set;}
    public Legacy_13424_Application__c legacyApp {get;set;}
    public Application_for_Federal_Assistance__c newApp {get;set;}

    public Legacy_13424_Application__c previousYearLegacyApp {get;set;}
    public LITC_Reporting_Form__c previousYEReport {get;set;}
    public LITC_Reporting_Form__c previousInterimReport {get;set;}

    public ApplicationReview intakeReview {get;set;}
    public Staff_Review__c pdStaffReview {get;set;}
    public Staff_Review__c aaStaffReview {get;set;}
    public Staff_Review__c baStaffReview {get;set;}
    public Staff_Review__c roStaffReview {get;set;}
    public Review_Card__c level2RC {get;set;}

    public Integer grantYear {get;set;}

    // public FundingOpportunity fundingAward {get;set;}
    // public FundingOpportunity fundingOpportunity {get;set;}
    
    public NTA_Review_PDF_Controller(ApexPages.StandardController stdController) {
        fileName = 'Temp File Name';

        String currentUserId = System.UserInfo.getUserId();
        Id ntaId = stdController.getRecord().Id;
        NTA_Review__c nta = [SELECT Id, Application_for_Federal_Assistance__c, Version__c, Application_for_Federal_Assistance__r.Grant_Year__c, Application_for_Federal_Assistance__r.Related_Business_Account__c  FROM NTA_Review__c WHERE Id =: ntaId ];
       
        newApp = [SELECT Id, Name FROM Application_for_Federal_Assistance__c WHERE Id = : nta.Application_for_Federal_Assistance__c];

        if(nta.Version__c == 'Legacy') legacyApp = [SELECT Id, Name, New_representation_cases_First_Year__c,Consulta_w_Low_Income_ESL_First_Year__c,
        Educa_Activ_to_Low_Income_First_Year__c,Low_Income_ESL_to_be_reached_First_Year__c
        FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c = : newApp.Id LIMIT 1];
        
        List<ApplicationReview> ars = [SELECT Id, Name, First_Year_Funded__c FROM ApplicationReview WHERE NTA_Review__c =: ntaId];
        if(ars.size()>0){intakeReview = ars[0];}
        List<Review_Card__c> rcs = [SELECT Id, Name, Notes__c, Score__c, Weighted_Score__c FROM Review_Card__c WHERE NTA_Review__c =: ntaId AND RecordType.Name = 'Level 2'];
        if(rcs.size()>0){
            level2RC = rcs[0];
        }
        for(Staff_Review__c sr : [SELECT Id, Conditions_for_Funding__c, Dollar_Amount__c, Name, Financial_Review_Comments__c, RecordType.Name, AA_Proposed_Conditions__c,
        Recommend_Funding__c, Reviewing_Official_Summary__c, Program_Review_Summary__c, AA_Narrative_Summary__c, Reviewer__c
        FROM Staff_Review__c WHERE NTA_Review__c =: ntaId]){
            if(sr.RecordType.Name == 'Advocacy Analyst Review') aaStaffReview = sr;
            else if(sr.RecordType.Name == 'Budget Analyst Review') baStaffReview = sr;
            else if(sr.RecordType.Name == 'Reviewing Official Review') roStaffReview = sr;
            else if(sr.RecordType.Name == 'Program Office Review') pdStaffReview = sr;
        }

        grantYear = String.isBlank(nta.Application_for_Federal_Assistance__r.Grant_Year__c) ? 2026 : Integer.valueOf(nta.Application_for_Federal_Assistance__r.Grant_Year__c);
        String prevGrantYear1 = String.valueOf(grantYear - 1);
        String prevGrantYear2 = String.valueOf(grantYear - 2);

        // dynamically pull previous grant year application and prev reporting forms, can also just add looksup to prev application / reports on the nta record.

        // get previous application's goals
        List<Application_for_Federal_Assistance__c> previousYearApps = [SELECT Id, Name FROM Application_for_Federal_Assistance__c WHERE Grant_Year__c =: prevGrantYear1 AND Related_Business_Account__c =: nta.Application_for_Federal_Assistance__r.Related_Business_Account__c];
        List<Application_for_Federal_Assistance__c> previousYearApps2 = [SELECT Id, Name FROM Application_for_Federal_Assistance__c WHERE Grant_Year__c =: prevGrantYear2 AND Related_Business_Account__c =: nta.Application_for_Federal_Assistance__r.Related_Business_Account__c];

        // get most recent previous app
        Application_for_Federal_Assistance__c previousYearApp;
        Application_for_Federal_Assistance__c previousYearApp2;

        // get most recent previous year's reports
        List<LITC_Reporting_Form__c> previousInterimReports = new List<LITC_Reporting_Form__c>();
        List<LITC_Reporting_Form__c> previousYEReports = new List<LITC_Reporting_Form__c>();

        if(previousYearApps.size() > 0){ 
            previousYearApp = previousYearApps[previousYearApps.size() - 1];
            System.debug(previousYearApp);

            List<Legacy_13424_Application__c> prevYearLegacyApps = [SELECT Id, Name, New_representation_cases_First_Year__c, 
            Consulta_w_Low_Income_ESL_First_Year__c, Educa_Activ_to_Low_Income_First_Year__c,Low_Income_ESL_to_be_reached_First_Year__c 
            FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c = : previousYearApp.Id];

            if(prevYearLegacyApps.size() > 0) previousYearLegacyApp = prevYearLegacyApps[0];

            previousInterimReports = [
                SELECT Id, 
                GP_New_case_goal__c, GP_Consultations_goal__c, GP_Education_events_goal__c, GP_Education_attendees_goal__c, 
                New_Cases__c, Total_Number_Educational_Activities__c, EA_Total_Attendees__c, USTC_Consultations__c,
                Starting_Inventory__c, Closing_Case_Inventory__c, Total_Number_Outreach_Activities__c, 
                Controversy_tax_returns__c, Ancillary_tax_returns__c, 
                Account_Management_Rollup__c, Exam_Rollup__c, Collection_Rollup__c, Appeal_Rollup__c,
                Litigation_Rollup__c, Miscellaneous_Rollup__c, Total_Number_TAS_Cases__c, Clinical_Program_Rollup__c, 
                U_S_Tax_Court_Entry_of_Appearance__c, U_S_Tax_Court_Power_of_Attorney__c, Total_Consultations__c, 
                Offer_In_Compromise_OIC__c, Currently_Not_Collectible_CNC__c, Levies__c, Liens__c, Nonfiler__c, 
                Identity_theft__c, Innocent_spouse__c, Earned_income_tax_credit__c, Small_business_issues__c, 
                Dollars_refunded_to_taxpayers__c, Decrease_in_tax_liabilities_penalties__c, 
                DL_Return_Preparer_Fraud__c, Suspected_return_preparer_fraud__c,
                DL_Account_Management__c, DL_Appeal__c, DL_Appearance__c, DL_Beginning_Inventory__c, DL_Clinical_Program__c, DL_Collection__c, DL_Consultation__c, DL_Consults__c, DL_Educational__c, 
                DL_Ending_Inventory__c, DL_Exam__c, DL_Litigation__c, DL_Miscellaneous__c, DL_New_Cases__c, DL_No_Appearance__c, DL_Outreach_Activities__c, DL_TAS_Referrals__c, DL_Tax_Returns_Controversy__c, DL_Tax_Returns_ESL__c, DL_Taxpayers_Ed__c
                FROM LITC_Reporting_Form__c 
                WHERE Reporting_period__c = 'Interim report (January 1 through June 30)' AND Grant_Year__c =: prevGrantYear1 AND Application_for_Federal_Assistance__c =: previousYearApp.Id AND Record_Type_Name__c = 'Form 13424-R'];
        }

        if(previousYearApps2.size() > 0){ 
            previousYearApp2 = previousYearApps2[previousYearApps2.size() - 1];
            previousYEReports = [
                SELECT Id,
                GP_New_case_goal__c, GP_Consultations_goal__c, GP_Education_events_goal__c, GP_Education_attendees_goal__c, 
                New_Cases__c, Total_Number_Educational_Activities__c, EA_Total_Attendees__c, USTC_Consultations__c,
                Starting_Inventory__c, Closing_Case_Inventory__c, Total_Number_Outreach_Activities__c, 
                Controversy_tax_returns__c, Ancillary_tax_returns__c, 
                Account_Management_Rollup__c, Exam_Rollup__c, Collection_Rollup__c, Appeal_Rollup__c,
                Litigation_Rollup__c, Miscellaneous_Rollup__c, Total_Number_TAS_Cases__c, Clinical_Program_Rollup__c, 
                U_S_Tax_Court_Entry_of_Appearance__c, U_S_Tax_Court_Power_of_Attorney__c, Total_Consultations__c, 
                Offer_In_Compromise_OIC__c, Currently_Not_Collectible_CNC__c, Levies__c, Liens__c, Nonfiler__c, 
                Identity_theft__c, Innocent_spouse__c, Earned_income_tax_credit__c, Small_business_issues__c, 
                Dollars_refunded_to_taxpayers__c, Decrease_in_tax_liabilities_penalties__c, 
                DL_Return_Preparer_Fraud__c, Suspected_return_preparer_fraud__c,
                DL_Account_Management__c, DL_Appeal__c, DL_Appearance__c, DL_Beginning_Inventory__c, DL_Clinical_Program__c, DL_Collection__c, DL_Consultation__c, DL_Consults__c, DL_Educational__c, 
                DL_Ending_Inventory__c, DL_Exam__c, DL_Litigation__c, DL_Miscellaneous__c, DL_New_Cases__c, DL_No_Appearance__c, DL_Outreach_Activities__c, DL_TAS_Referrals__c, DL_Tax_Returns_Controversy__c, DL_Tax_Returns_ESL__c, DL_Taxpayers_Ed__c
                FROM LITC_Reporting_Form__c 
                WHERE Reporting_period__c = 'Year-End report (January 1 through December 31)' AND Grant_Year__c =: prevGrantYear2 AND Application_for_Federal_Assistance__c =: previousYearApp2.Id AND Record_Type_Name__c = 'Form 13424-R'];
        }
    
        if(previousInterimReports.size() > 0){ 
            previousInterimReport = previousInterimReports[previousInterimReports.size() - 1];
        }
        if(previousYEReports.size() > 0){ 
            previousYEReport = previousYEReports[previousYEReports.size() - 1];
        }
    }
    
    public static Map<String, String> generatePDF(List<String> recordIds)
    {
        Set<Id> appIds = new Set<Id>();
        Map<Id, NTA_Review__c> ntaMap = new Map<Id, NTA_Review__c>();

        for (NTA_Review__c nta : [SELECT Id, Application_for_Federal_Assistance__c, Application_for_Federal_Assistance__r.State__c, Application_for_Federal_Assistance__r.Legal_Name__c FROM NTA_Review__c WHERE Id IN :recordIds]) {
            appIds.add(nta.Application_for_Federal_Assistance__c);
            ntaMap.put(nta.Id, nta);
        }

        Map<Id, FundingAward> appToFA = new Map<Id, FundingAward>();

        for (FundingAward fa : [SELECT Id, Application_for_Federal_Assistance__c, FundingOpportunityId, FundingOpportunity.Fund_Loading_FY__c FROM FundingAward WHERE Application_for_Federal_Assistance__c IN :appIds]) {
            appToFA.put(fa.Application_for_Federal_Assistance__c, fa);
        }

        Map<Id, FundingAward> ntaToFA = new Map<Id, FundingAward>();

        for (Id ntaId : ntaMap.keySet()) {
            Id appId = ntaMap.get(ntaId).Application_for_Federal_Assistance__c;
            if (appToFA.containsKey(appId)) {
                ntaToFA.put(ntaId, appToFA.get(appId));
            }
        }

      
        PageReference pdf = Page.NTAReview;
        String concatBlobHex = '';
        List<ContentVersion> cvs = new List<ContentVersion>();
        for(String recordId : recordIds){
            pdf.getParameters().put('id',recordId);
            Blob blobBody;
            try {
                blobBody = pdf.getContent();
            } catch (VisualforceException e) {
                blobBody = Blob.valueOf('PDF FAILED TO GENERATE');
            }

            NTA_Review__c rec = ntaMap.get(recordId);
            String fo = '';
            if(ntaToFA.get(recordId) != null){ 
                fo = ntaToFA.get(recordId).FundingOpportunity.Fund_Loading_FY__c + '-';
            }
        
            String filename = fo + rec.Application_for_Federal_Assistance__r.State__c + '-NTA-' + rec.Application_for_Federal_Assistance__r.Legal_Name__c;

            concatBlobHex += EncodingUtil.convertToHex(blobBody);
            ContentVersion cVersion = new ContentVersion();
            cVersion.File_Prefix__c = 'ApplicationPDF';
            cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
            cVersion.PathOnClient = 'NTA.pdf';//File name with extention
            cVersion.Origin = 'C';//C-Content Origin. H-Chatter Origin.
            cVersion.OwnerId = system.UserInfo.getUserId();//Owner of the file
            cVersion.Title = filename;//Name of the file
            cVersion.VersionData = blobBody;//File content
            cvs.add(cVersion);
        }
        insert cvs;
        List<Id> cvIds = new List<Id>();
        for(ContentVersion cVersion : cvs){
            System.debug(cVersion.Id);
            cvIds.add(cVersion.id);
        }
        

        
       
        Map<String, String> conDocMap = new Map<String,String>();
        //After saved the Content Verison, get the ContentDocumentId
        for(ContentVersion conVer : [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :cvIds]){
            conDocMap.put((String)conVer.Id, (String)conVer.ContentDocumentId);
        }
        System.debug(conDocMap);
        return conDocMap;

    }


    /*FOR FLOW USAGE*/
    /**
     * Invocable method to generate NTA Review PDFs from generate PDF flow
     * 
     * @param inputList A list of ids to create PDFs
     * @return A link to download the generated pdfs
     */
    @InvocableMethod(label='Create NTA Review PDFs' description='Creates PDFs for NTA reviews from a VF page and stores them in a zip')
    public static List<PDFResult> generatePDFsInvocable(List<PDFInput> inputList) {
        // List<String> recordIds = new List<String>();
        Map<String, String> generateResult;
        for(PDFInput input: inputList) {
            System.debug(input.recordIds + 'input.recordIds');
            generateResult = generatePDF(input.recordIds.split(','));

        }
        List<String> conDocs = generateResult.values();
        PDFResult result = new PDFResult();
        result.success = true;
        result.responseData = String.join(conDocs, ',');
        result.errorMessage = '';
        List<PDFResult> results = new List<PDFResult>();

        results.add(result);
        return results;
    }
    public class PDFInput {
        @InvocableVariable(label='recordIds' required=true)
        public String recordIds;
    }

    public class PDFResult {
        @InvocableVariable(label='Success' required=true)
        public Boolean success;

        @InvocableVariable(label='Response Data' required=false)
        public String responseData;

        @InvocableVariable(label='Error Message' required=false)
        public String errorMessage;
    }
}