public with sharing class FundingAwardPDFController {

    public Legacy_13424_Application__c legacyApp {get;set;}
    public Application_for_Federal_Assistance__c newApp {get;set;}
    public List<FundingDisbursement> disbursements {get;set;}

    public FundingDisbursement disbursement {get;set;}
    public FundingAward award {get;set;}

    public String congressionalDistrict { get; set; }

    public Double disbursementTotals { get; set; }
    public Double directCost20a { get; set; }
    public Double indirectCost20b { get; set; }

    public Double field24 { get; set; }

    public FundingAwardPDFController(ApexPages.StandardController stdController) {
        String currentUserId = System.UserInfo.getUserId();
        Id fundingAwardId = stdController.getRecord().Id;
        award = [SELECT Id, Name, Application_for_Federal_Assistance__c, Application_for_Federal_Assistance__r.Congressional_district_by_project__c, AwardeeId, 
        Application_for_Federal_Assistance__r.Total_Federal_Expenses__c, Application_for_Federal_Assistance__r.Indirect_Expenses_Federal_Total__c, 
        Application_for_Federal_Assistance__r.Total_Direct_Charges_Total_Formula__c, Application_for_Federal_Assistance__r.Total_Direct_Charges_Federal_Formula__c, 
        Funding_Award__c, LITC_Reporting_L_Form__c, LITC_Reporting_L_Form__r.Total_Match_Expenses__c, 
        LITC_Reporting_L_Form__r.Total_Federal_Expenses__c, LITC_Reporting_L_Form__r.Indirect_Expenses_Federal_Total__c, 
        LITC_Reporting_L_Form__r.Total_Direct_Charges_Total_Formula__c, LITC_Reporting_L_Form__r.Total_Direct_Charges_Federal_Formula__c, 
        Application_for_Federal_Assistance__r.Total_Match_Expenses__c, Closeout_status__c, Total_Federal_and_Non_Federal_Approved__c
        FROM FundingAward WHERE Id =: fundingAwardId ];
       
        List<Legacy_13424_Application__c> legacyApps = [SELECT Id, Name, Clinic_Director_Last_name__c, Clinic_Director_First_Name__c, 
        Clinic_Director_Telephone_number__c, Clinic_Director_Email_address__c
         FROM Legacy_13424_Application__c WHERE Application_for_Federal_Assistance__c = : award.Application_for_Federal_Assistance__c LIMIT 1];
        if(legacyApps.size() > 0){ 
           legacyApp = legacyApps[0];
        }

        disbursements = [SELECT ID, Name, Amount, Status, Recipient_Comments__c, Recipient_Status__c, DisbursementDate FROM FundingDisbursement WHERE FundingAwardId =: fundingAwardId];
        
        // 24 = total match expenses from the Application. If generated from closeout pull total match expenses from L form
        if(award.Closeout_status__c == 'Closeout Completed'){ 
            field24 = award.LITC_Reporting_L_Form__r.Total_Match_Expenses__c;
        } else{ 
            field24 = award.Application_for_Federal_Assistance__r.Total_Match_Expenses__c;
        }
    
        // grabs the most recent disbursement
        if(disbursements.size() > 0){ 
            disbursement = disbursements[disbursements.size() - 1];
        }
        
        String value = award.Application_for_Federal_Assistance__r.Congressional_district_by_project__c;
        if (value != null) {
            String replaced = value.replace(';', ', ');
            this.congressionalDistrict = replaced.length() > 475 ? replaced.substring(0, 472) + '...' : replaced;
        } else {
            this.congressionalDistrict = null;
        }

        // Get all FA's linked to the account
        List<FundingAward> allFAs = [
            SELECT Id, Performance_Year__c, CreatedDate, Disbursement_Total__c, Total_Federal_and_Non_Federal_Approved__c FROM FundingAward 
            WHERE AwardeeId = :award.AwardeeId AND Performance_Year__c IN ('01', '02', '03') ORDER BY CreatedDate DESC
        ];

        FundingAward year1;
        FundingAward year2;
        FundingAward year3;

        // grab the most recent year 1, 2, 3
        for (FundingAward fa : allFAs) {
            if (fa.Performance_Year__c == '01' && year1 == null) {
                year1 = fa;
            } else if (fa.Performance_Year__c == '02' && year2 == null) {
                year2 = fa;
            } else if (fa.Performance_Year__c == '03' && year3 == null) {
                year3 = fa;
            }

            // once we grab the first 3 stop
            if (year1 != null && year2 != null && year3 != null) break;
        }

        List<FundingAward> fundingAwardsPeriod = new List<FundingAward>();

        // grab any subsequent year 2, or year 3
        if (year1 != null) {
            fundingAwardsPeriod.add(year1);
            if (year2 != null && year2.CreatedDate > year1.CreatedDate) fundingAwardsPeriod.add(year2);
            if (year3 != null && year3.CreatedDate > year1.CreatedDate) fundingAwardsPeriod.add(year3);
        } else if (year2 != null) {
            fundingAwardsPeriod.add(year2);
            if (year3 != null && year3.CreatedDate > year2.CreatedDate) fundingAwardsPeriod.add(year3);
        } else if (year3 != null) {
            fundingAwardsPeriod.add(year3);
        }

        // 27 = Sum of all (25) all NOAs for that cycle

        disbursementTotals = 0;

        for(FundingAward fa : fundingAwardsPeriod){ 
            // disbursementTotals += fa.Disbursement_Total__c;
            disbursementTotals += fa.Total_Federal_and_Non_Federal_Approved__c;
        }

        // calculations for 20a. and 20b.
        Double fedExpenses = award.Application_for_Federal_Assistance__r.Total_Federal_Expenses__c;
        Double indirectCost = award.Application_for_Federal_Assistance__r.Indirect_Expenses_Federal_Total__c;
        Double currentDisbursementAmount = disbursement.Amount != null ? disbursement.Amount : 0;

        // not sure if this should be total direct charges federal or the fed + match
        Double totalDirectCharges = award.Application_for_Federal_Assistance__r.Total_Direct_Charges_Federal_Formula__c;

        if (fedExpenses != null && fedExpenses != 0) {
            directCost20a = (currentDisbursementAmount / fedExpenses) * totalDirectCharges;
            indirectCost20b = (currentDisbursementAmount / fedExpenses) * indirectCost;
        } else {
            directCost20a = 0;
            indirectCost20b = 0;
        }
    
    }



    @AuraEnabled
    public static string generatePDF(String recordId, String disbursementId){
        String name = 'FundingAward';

        PageReference pdf = Page.FundingAward;
        pdf.getParameters().put('id',recordId);

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
        cDocLink.LinkedEntityId = disbursementId;
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
}