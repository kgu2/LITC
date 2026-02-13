public with sharing class FundingAwardTriggerHandler {

    public static void handleBeforeUpdate( List<FundingAward> awards, Map<Id, FundingAward> oldMap) {
        FundingAwardTriggerHandler.populateFieldsUpdate(awards, oldMap);   
    }

    public static void handleAfterUpdate( List<FundingAward> awards ) {
        FundingAwardTriggerHandler.calculateRollup(awards);   
        FundingAwardTriggerHandler.populateFieldsAfterUpdate(awards);   
    }
    public static void handleAfterInsert( List<FundingAward> awards ) {
        FundingAwardTriggerHandler.calculateRollup(awards);   
        FundingAwardTriggerHandler.populateFundingOpportunity(awards);  
    }
    public static void handleBeforeInsert( List<FundingAward> awards ) {
        FundingAwardTriggerHandler.populateFields(awards);   
        FundingAwardTriggerHandler.populateOriginalFundingAward(awards);  
    }
    public static void handleAfterDelete( List<FundingAward> awards ) {
        FundingAwardTriggerHandler.calculateRollup(awards);   
    }

    public static void populateFields(List<FundingAward> awards) {
        Set<Id> accountIds = new Set<Id>();
        Set<Id> appIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();

        for (FundingAward fa : awards) {
            if (fa.AwardeeId != null) accountIds.add(fa.AwardeeId);
            if (fa.Application_for_Federal_Assistance__c != null) appIds.add(fa.Application_for_Federal_Assistance__c);
            if (fa.FundingOpportunityId != null) oppIds.add(fa.FundingOpportunityId);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>(
            [SELECT Id, AA_Assignment__c FROM Account WHERE Id IN :accountIds]
        );

        Map<Id, Application_for_Federal_Assistance__c> appMap = new Map<Id, Application_for_Federal_Assistance__c>(
            [SELECT Id, Project_Start_Date_Formula__c, Project_End_Date_Formula__c FROM Application_for_Federal_Assistance__c WHERE Id IN :appIds]
        );

        Map<Id, FundingOpportunity> oppMap = new Map<Id, FundingOpportunity>(
            [SELECT Id, Name FROM FundingOpportunity WHERE Id IN :oppIds]
        );

        List<User> users = [SELECT Id FROM User WHERE Email = 'tamara.a.borland@irs.gov' LIMIT 1];
        Id record;

        if (!users.isEmpty()) {
            record = users[0].Id;
        }


        for (FundingAward fa : awards) {
            Account acc = accountMap.get(fa.AwardeeId);
            if (acc != null) {
                fa.AA_Assignment__c = acc.AA_Assignment__c;
            }

            fa.GMO_Assignment__c = record;


            Application_for_Federal_Assistance__c app = appMap.get(fa.Application_for_Federal_Assistance__c);
            if (app != null) {
                fa.Period_of_Performance_Start_Date__c = app.Project_Start_Date_Formula__c;
                fa.Period_of_Performance_End_Date__c = app.Project_End_Date_Formula__c;
            }

            FundingOpportunity opp = oppMap.get(fa.FundingOpportunityId);
            if (opp != null) {
                fa.FY_Account_Number__c = opp.Name;
            }

            fa.Document_Number__c = fa.Award_Number__c;


            String terms = 
                '<p>By accepting funds under this grant, the Grant Recipient agrees to comply with the following terms and conditions for the grant:</p> <br/> <p>(1) Requirements and limitations set forth in 26 U.S.C. ß 7526 and legislation appropriating federal funds for this award.</p> <br/> <p>(2) The Uniform Guidance at 2 C.F.R. Part 200 (April 2024 Revision), and the Treasury Department’s implementation of the Uniform Guidance at 2 C.F.R. Part 1000 (December 2014 and June 2, 2021). </p> <br/> <p>(3) IRS Publication 3319, 2025 Grant Application Package and Guidelines found at <a href="https://www.irs.gov/pub/irs-pdf/p3319.pdf" target="_blank">https://www.irs.gov/pub/irs-pdf/p3319.pdf</a></p> <br/> <p>(4) Assurances found in Publication 3319, pages 15, 65, and in Standard Form 424, Assurances and Certifications and Authorized Representative</p> <br/> <p>(5) <b>Period of Performance.</b> The approved Period of Performance is the approved length of the project which may be 1, 2, or 3 years. It is' +
                'found on line 26. See 2 C.F.R. ß 200.1, Definitions.</p> <br/> <p>(6) <b>Budget Period.</b> The budget period covers the current calendar grant year only. It is found on line 19 . See 2 C.F.R. ß 200.1, Definitions.</p> <br/> <p>(7) <b>Funding for Future Budget Periods.</b> or grantees with an approved multi-year period of performance, funding for future budget periods is not guaranteed. Future funding is subject to the availability of federal funds and continued program authority as well as grantee’s satisfactory performance and compliance with the terms and conditions of the federal award. </p> <br/> <p>(8) <b>Match Funding.</b> Funds used to meet the required dollar for dollar match may not be used as matching funds in support of any other federal program. Generally, federal funds may not be used as matching funds by the grant recipient for the LITC program. </p> <br/> <p>(9) <b>Prohibition on use of funds for certain purchases.</b> Compliance with 2 C.F.R. ß 200.216, prohibits the' +
                'use of federal funds on certain telecommunications and video surveillance services or equipment.</p> <br/> <p>(10) <b>Requirement regarding deposit account.</b> The Grant Recipient must maintain advance payments of federal awards in interest-bearing accounts, unless certain exceptions found at 2 C.F.R. ß 200.305(b)(8) apply. </p> <br/> <p>(11) <b>Timing of requests for Disbursements.</b> Recipients must limit request of advance payments to the minimum amounts needed and be timed with actual, immediate cash requirements of the recipient to carry out the purpose of the approved project.</p> <br/> <p>(12) <b>Termination.</b> The IRS may terminate this agreement for reasons of default or failure of the Grant Recipient to perform their obligations under this agreement, as well as for malfeasance, illegal conduct, and/or management practices by the Grant Recipient that jeopardize the ethical operations and implementation of this agreement. In any of the above cases, the IRS will notify the' +
                'Grant Recipient in writing of its intent to terminate the agreement and the causes for such a decision. Grant Recipients should be aware that 2 C.F.R. ß 200.340 strengthens the ability of the IRS to terminate federal awards, to the greatest extent authorized by law, when the federal award no longer effectuates the program goals.</p> <br/> <p><b>Specific Registration and Additional Reporting Requirements</b></p>' + 
                '<p>(13) <b>Requirement for Sam.gov Registration.</b> Unless exempted from this requirement under 2 C.F.R. ß 25.110, the Grant Recipient must maintain current information in the System for Award Management. This includes information on the Grant Recipient’s immediate and highest-level owner and subsidiaries, as well as on all of the Grant Recipient’s predecessors that have been awarded a federal contract or federal financial assistance within the last three years, if applicable, until the Grant Recipient submits the final financial report required under this federal award or receives the final payment, whichever is later. This requires that the Grant Recipient review and update the information at least annually after the initial registration, and more frequently if required by changes in the Grant Recipient’s information or another Federal award term. See Appendix A to 2 C.F.R. Part 25.Definitions. For the purposes of this award term: System for Award Management (SAM.gov) means the' +
                'Federal repository into which a recipient must provide the information required for the conduct of business as a recipient. Additional information about registration procedures may be found in SAM.gov (currently at https://www.sam.gov). Unique entity identifier means the universal identifier assigned by SAM.gov to uniquely identify an entity. Entity is defined at 2 CFR 25.400 and includes all of the following types as defined in 2 CFR 200.1: (1) Non-Federal entity; (2) Foreign organization;(3) Foreign public entity;(4) Domestic for-profit organization; and (5) Federal agency. [89 FR 30111, Apr. 22, 2024, as amended at 89 FR 79732, Oct. 1, 2024] [Provisions related to sub-awards are omitted as generally sub-awards are not authorized under this program.]</p> <br/> <p>(14) <b>Reporting of Recipient Integrity and Performance.</b> <br/> (a) General reporting requirements. <br/> <div style="margin-left: 20px">(1) If the total value of your active grants, cooperative agreements, and' +
                'procurement contracts from all Federal agencies exceeds $10,000,000 for any period of time during the period of performance of this Federal award, then you as the recipient must ensure the information available in the responsibility/qualification records through the System for Award Management (SAM.gov), about civil, criminal, or administrative proceedings described in paragraph (b) of this award term is current and complete. This is a statutory requirement under section 872 of Public Law 110-417, as amended (41 U.S.C. 2313). As required by section 3010 of Public Law 111-212, all information posted in responsibility/qualification records in SAM.gov on or after April 15, 2011 (except past performance reviews required for Federal procurement contracts) will be publicly available.</div> (b) Proceeding about Which You Must Report <div style="margin-left: 20px"> (1) You must submit the required information about each proceeding that— <div style="margin-left: 20px"> (i) Is in connection with' +
                'the award or performance of a grant, cooperative agreement, or procurement contract from the Federal Government; </div> <div style="margin-left: 20px"> (ii) Reached its final disposition during the most recent five-year period; and </div> <div style="margin-left: 20px"> (iii) Is one of the following— <div style="margin-left: 20px"> (A) A criminal proceeding that resulted in a conviction; </div> <div style="margin-left: 20px"> (B) A civil proceeding that resulted in a finding of fault and liability and payment of a monetary fine, penalty, reimbursement, restitution, or damages of $5,000 or more; </div> <div style="margin-left: 20px"> (C) An administrative proceeding that resulted in a finding of fault and liability and your payment of either a monetary fine or penalty of $5,000 or more or reimbursement, restitution, or damages in excess of $100,000; or </div> <div style="margin-left: 20px"> (D) Any other criminal, civil, or administrative proceeding if— <' + 
                '(1) It could have led to an outcome described in paragraph (b)(1)(iii)(A) through (C); </div> <div style="margin-left: 20px"> (2) It had a different disposition arrived at by consent or compromise with an acknowledgment of fault on your part; and </div> <div style="margin-left: 20px"> (3) The requirement in this award term to disclose information about the proceeding does not conflict with applicable laws and regulations. </div> </div> </div> </div> </p> <br/> <p>Enter the required information in SAM.gov for each proceeding described in paragraph (b) of this award term. You do not need to submit the information a second time under grants and cooperative agreements that you received if you already provided the information in SAM.gov because you were required to do so under Federal procurement contracts that you were awarded.</p> <br/> <p>(d) Reporting Frequency. During any period of time when you are subject to the requirement in paragraph (a) of this award term, you must report' +
                'proceedings information in SAM.gov for the most recent five-year period, either to report new information about a proceeding that you have not reported previously or affirm that there is no new information to report. If you have Federal contract, grant, and cooperative agreement awards with a cumulative total value greater than $10,000,000, you must disclose semiannually any information about the criminal, civil, and administrative proceedings. <br/> (e) Definitions. For purposes of this award term—Administrative proceeding means a non-judicial process that is adjudicatory in nature to make a determination of fault or liability (for example, Securities and Exchange Commission Administrative proceedings, Civilian Board of Contract Appeals proceedings, and Armed Services Board of Contract Appeals proceedings). This includes proceedings at the Federal and State level but only in connection with the performance of a federal contract or grant. It does not include audits, site visits,' +
                'corrective plans, or inspection of deliverables. Conviction means a judgment or conviction of a criminal offense by any court of competent jurisdiction, whether entered upon a verdict or a plea, and includes a conviction entered upon a plea of nolo contendere. Total value of currently active grants, cooperative agreements, and procurement contracts includes the value of the Federal share already received plus any anticipated Federal share under those awards (such as continuation funding).</p> <br/> <p>(15) <b>Reporting Subawards and Executive Compensation.</b> [As generally the LITC does not allow subawards, provisions related to subawards are omitted but can be found at Appendix A to Part 170, Title 2]. (b) Reporting total compensation of recipient executives for entities — <div style="margin-left: 20px"> (1) Applicability. The recipient must report the total compensation for each of the recipient\'s five most highly compensated executives for the preceding completed fiscal year if:' +
                '<div style="margin-left: 20px"> (i) The total Federal funding authorized to date under this Federal award equals or exceeds $30,000; </div> <div style="margin-left: 20px"> (ii) in the preceding fiscal year, the recipient received: <div style="margin-left: 20px"> (A) 80 percent or more of the recipient\'s annual gross revenues from Federal procurement contracts (and subcontracts) and Federal awards (and subawards) subject to the Transparency Act; and </div> <div style="margin-left: 20px"> (B) $25,000,000 or more in annual gross revenues from Federal procurement contracts (and subcontracts) and Federal awards (and subawards) subject to the Transparency Act; and, </div> </div> <div style="margin-left: 20px"> (iii) The public does not have access to information about the compensation of the executives through periodic reports filed under section 13(a) or 15(d) of the Securities Exchange Act of 1934 (15 U.S.C. 78m(a), 78o(d)) or section 6104 of the Internal Rev';


            fa.General_Terms_and_Conditions__c = terms;
        }

        
    }

    public static void populateFieldsUpdate(List<FundingAward> awards, Map<Id, FundingAward> oldMap) {
        for (FundingAward fa : awards) {
            FundingAward oldRecord = oldMap.get(fa.Id);

            if(oldRecord.get('Closeout_status__c') != 'Closeout Completed' && fa.Closeout_status__c == 'Closeout Completed'){ 
                fa.Status = 'Closed';
                fa.Date_Closeout_Completed__c = System.today();
                fa.Closeout_Completed_By__c = UserInfo.getUserId();
            }

            // if(oldRecord.get('Grant_Account_Ready_to_Close_Out__c') != 'Yes' && fa.Grant_Account_Ready_to_Close_Out__c == 'Yes'){ 
            //     fa.Date_Payment_Account_Closed__c = System.today();
            //     fa.Date_Grant_Account_Closed__c = System.today();
            // }
        }
            
    }

    // private static void calculateCount(List<FundingAward> awards){
    
    //     Set<Id> opportunityIds = new Set<Id>();
    //     for (FundingAward fa : awards) {
    //         opportunityIds.add(fa.FundingOpportunityId);
    //     }

    //     Map<Id, Integer> existingCounts = new Map<Id, Integer>();
    //     if (!opportunityIds.isEmpty()) {
    //         List<AggregateResult> groupedResults = [SELECT FundingOpportunityId, COUNT(Id) totalCounts FROM FundingAward WHERE FundingOpportunityId IN :opportunityIds GROUP BY FundingOpportunityId];

    //         for (AggregateResult ar : groupedResults) {
    //             existingCounts.put((Id)ar.get('FundingOpportunityId'), (Integer)ar.get('totalCounts'));
    //         }
    //     }


    //     Map<Id, Integer> nextCounts = new Map<Id, Integer>(existingCounts);
    //     for (FundingAward fa : awards) {
    //         Id oppId = fa.FundingOpportunityId;
    //         Integer count = nextCounts.get(oppId);
    //         if (count == null) count = 0;
    //         fa.Amendment_Number__c = count;
    //         nextCounts.put(oppId, count + 1); 
    //     }
    // }


    private static void calculateRollup(List<FundingAward> awards){ 
        Set<Id> fundingOppIds = new Set<Id>();
        for(FundingAward aw: awards){ 
            fundingOppIds.add(aw.FundingOpportunityId);
        }

        List<FundingAward> allAwards = [SELECT Id, Name, Amount, FundingOpportunityId, Disbursement_Total__c FROM FundingAward WHERE FundingOpportunityId In: fundingOppIds AND Status != 'Cancelled'];

        Map<Id, Decimal> oppIdToTotalAmount = new Map<Id, Decimal>();
        Map<Id, Decimal> oppIdToTotalDisbursed = new Map<Id, Decimal>();

        for (FundingAward award : allAwards) {
            Decimal existingTotal = oppIdToTotalAmount.containsKey(award.FundingOpportunityId) ? oppIdToTotalAmount.get(award.FundingOpportunityId) : 0;
            Decimal awardAmount = award.Amount != null ? award.Amount : 0;
            oppIdToTotalAmount.put(award.FundingOpportunityId, existingTotal + awardAmount);

            Decimal existingTotalDisbursement = oppIdToTotalDisbursed.containsKey(award.FundingOpportunityId) ? oppIdToTotalDisbursed.get(award.FundingOpportunityId) : 0;
            Decimal disbursementAmount = award.Disbursement_Total__c != null ? award.Disbursement_Total__c : 0;
            oppIdToTotalDisbursed.put(award.FundingOpportunityId, existingTotalDisbursement + disbursementAmount);
        }

        // for deleting, zero records left
        for (Id oppId : fundingOppIds) {
            if (!oppIdToTotalAmount.containsKey(oppId)) {
                oppIdToTotalAmount.put(oppId, 0);
            }
            if (!oppIdToTotalDisbursed.containsKey(oppId)) {
                oppIdToTotalDisbursed.put(oppId, 0);
            }
        }

        List<FundingOpportunity> oppsToUpdate = [SELECT Id, Total_Award_Amount__c FROM FundingOpportunity WHERE Id IN :oppIdToTotalAmount.keySet()];

        for (FundingOpportunity opp : oppsToUpdate) {
            opp.Total_Award_Amount__c = oppIdToTotalAmount.get(opp.Id);
            opp.Disbursement_Total__c= oppIdToTotalDisbursed.get(opp.Id);
        }

        if (!oppsToUpdate.isEmpty()) {
            update oppsToUpdate;
        }
    }

    private static void populateFieldsAfterUpdate(List<FundingAward> awards){ 

        Set<Id> appIds = new Set<Id>();
        for(FundingAward fa: awards){ 
            if(fa.Closeout_status__c == 'Closeout Completed'){ 
                appIds.add(fa.Application_for_Federal_Assistance__c);
            }
        }

        List<Application_for_Federal_Assistance__c> apps = [SELECT ID, Status__c FROM Application_for_Federal_Assistance__c WHERE Id IN: appIds];

        for(Application_for_Federal_Assistance__c app: apps){
            if(app.status__c != 'Closed') app.status__c = 'Closed';
        }

        if (!apps.isEmpty()) {
            update apps;
        }
    }

    private static void populateOriginalFundingAward(List<FundingAward> awards) {

        // For year 1 FA's, there is no previous FA
        Set<Id> accountIds = new Set<Id>();
        for (FundingAward fa : awards) {
            if (fa.Performance_Year__c != '01') {
                accountIds.add(fa.AwardeeId);
            }
        }

        System.debug(accountIds);

        Map<Id, Id> accountToYear1AwardId = new Map<Id, Id>();
        Map<Id, Id> accountToYear2AwardId = new Map<Id, Id>();

        if (!accountIds.isEmpty()) {
            List<FundingAward> priorAwards = [
                SELECT Id, AwardeeId, Performance_Year__c, CreatedDate
                FROM FundingAward
                WHERE Performance_Year__c IN ('01', '02')
                AND AwardeeId IN :accountIds
                ORDER BY CreatedDate DESC 
            ];

            for (FundingAward fa : priorAwards) {
                if (fa.Performance_Year__c == '01' && !accountToYear1AwardId.containsKey(fa.AwardeeId)) {
                    accountToYear1AwardId.put(fa.AwardeeId, fa.Id);
                } else if (fa.Performance_Year__c == '02' && !accountToYear2AwardId.containsKey(fa.AwardeeId)) {
                    accountToYear2AwardId.put(fa.AwardeeId, fa.Id);
                }
            }
        }

         System.debug(accountToYear1AwardId);
         System.debug(accountToYear2AwardId);

        // Populate year 1 funding award for year 2 and year 3
        for (FundingAward fa : awards) {
            if (fa.Performance_Year__c != '01') {
                Id acctId = fa.AwardeeId;
                if (accountToYear1AwardId.containsKey(acctId)) {
                    fa.Funding_Award__c = accountToYear1AwardId.get(acctId);
                } 
                // year 3 FA will populate previous year 2 FA if can't find Year 1
                else if (fa.Performance_Year__c == '03' && accountToYear2AwardId.containsKey(acctId)) {
                    fa.Funding_Award__c = accountToYear2AwardId.get(acctId);
                }
            }
        }
    }

    private static void populateFundingOpportunity(List<FundingAward> awards){ 

        Map<Id, Id> appToFO = new Map<Id, Id>();


        for(FundingAward award : awards){
            if(award.Application_for_Federal_Assistance__c != null && award.FundingOpportunityId != null){ 
                appToFO.put(award.Application_for_Federal_Assistance__c, award.FundingOpportunityId);
            }  
        } 

        Map<Id, FundingOpportunity> foMap = new Map<Id, FundingOpportunity>([SELECT Id, Name FROM FundingOpportunity WHERE Id IN :appToFO.values()]);

        Map<Id, String> appToFOName = new Map<Id, String>();

        for(Id appId : appToFO.keySet()){
            if(foMap.containsKey(appToFO.get(appId))){
                appToFOName.put(appId, foMap.get(appToFO.get(appId)).Name);
            }
        }

        List<Application_for_Federal_Assistance__c> apps = [SELECT ID, Funding_Opportunity_Number__c FROM Application_for_Federal_Assistance__c WHERE Id IN: appToFO.keySet()];
        for(Application_for_Federal_Assistance__c app : apps){ 
            app.Funding_Opportunity_Number__c = appToFOName.get(app.Id);
        }

        if (!apps.isEmpty()) {
            update apps;
        }

       
    }


}