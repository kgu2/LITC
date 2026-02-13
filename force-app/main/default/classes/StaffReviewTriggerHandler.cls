public with sharing class StaffReviewTriggerHandler {

    public static void afterUpdate(List<Staff_Review__c> newReviews) {
        Set<Id> ntaIds = new Set<Id>();

        List<Staff_Review__c> poStaffUpdates = new List<Staff_Review__c>();

        Id aaRecordType = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Advocacy Analyst Review').getRecordTypeId();
        Id roRecordType = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Reviewing Official Review').getRecordTypeId();

        Map<Id, Staff_Review__c> aaReviewByNta = new Map<Id, Staff_Review__c>();

        for (Staff_Review__c sr : newReviews) {
            ntaIds.add(sr.NTA_Review__c);
            
            // prepopulate PO review fields
            if (sr.Program_Office_Review__c != null) {
                Staff_Review__c poReview = new Staff_Review__c(Id = sr.Program_Office_Review__c);

                if(sr.Reviewing_Official_Summary__c != null){ 
                    poReview.Reviewing_Official_Summary__c = sr.Reviewing_Official_Summary__c;
                }
                if(sr.AA_Narrative_Summary__c != null){ 
                    if(sr.Application_Type_v2__c == 'NCCs under 30'){ 
                        poReview.Program_Review_Summary__c = sr.AA_Narrative_Summary__c;
                    }
                    poReview.AA_Narrative_Summary__c = sr.AA_Narrative_Summary__c;
                }
                if(sr.Financial_Review_Comments__c != null){ 
                    poReview.Financial_Review_Comments__c = sr.Financial_Review_Comments__c;
                }

                poStaffUpdates.add(poReview);
            }

            if (sr.RecordTypeId == aaRecordType) {
                aaReviewByNta.put(sr.NTA_Review__c, sr);
            }
        }
        if (!poStaffUpdates.isEmpty()) {
            update poStaffUpdates;
        }

        List<Staff_Review__c> roReviewRecords = new List<Staff_Review__c>();

        // prepopulate RO review fields from AA record
        for (Staff_Review__c ro : [SELECT Id, NTA_Review__c, Clinic_Display_Growth__c, Overnight_Support__c, Oversight_Support_Effective__c, Grantee_Conference_Contribution__c, 
            Contribution_Explanation__c, Top_33_Percentile__c, Any_Significant_Developments__c, Specific_Developments__c, Recommend_Funding__c, What_level__c, 
            Dollar_Amount__c, Funding_Explanation__c, Conditions_on_Funding__c, Conditions_for_Funding__c, Other_Explanation__c, AA_Narrative_Summary__c
         FROM Staff_Review__c WHERE RecordTypeId = :roRecordType AND NTA_Review__c IN :aaReviewByNta.keySet()]) {
            Staff_Review__c aaReview = aaReviewByNta.get(ro.NTA_Review__c);

            ro.Clinic_Display_Growth__c = aaReview.Clinic_Display_Growth__c;
            ro.Overnight_Support__c = aaReview.Overnight_Support__c;
            ro.Oversight_Support_Effective__c = aaReview.Oversight_Support_Effective__c;
            ro.Grantee_Conference_Contribution__c = aaReview.Grantee_Conference_Contribution__c;
            ro.Contribution_Explanation__c = aaReview.Contribution_Explanation__c;
            ro.Top_33_Percentile__c = aaReview.Top_33_Percentile__c;
            ro.Any_Significant_Developments__c = aaReview.Any_Significant_Developments__c;
            ro.Specific_Developments__c = aaReview.Specific_Developments__c;
            ro.Recommend_Funding__c = aaReview.Recommend_Funding__c;
            ro.What_level__c = aaReview.What_level__c;
            ro.Dollar_Amount__c = aaReview.Dollar_Amount__c;
            ro.Funding_Explanation__c = aaReview.Funding_Explanation__c;
            ro.Conditions_on_Funding__c = aaReview.Conditions_on_Funding__c;
            ro.Conditions_for_Funding__c = aaReview.Conditions_for_Funding__c;
            ro.Other_Explanation__c = aaReview.Other_Explanation__c;
            ro.Reviewing_Official_Summary__c = aaReview.AA_Narrative_Summary__c;
            roReviewRecords.add(ro);
        }

        if (!roReviewRecords.isEmpty()) {
            update roReviewRecords;
        }


        Map<Id, List<Staff_Review__c>> ntaToStaffReviews = new Map<Id, List<Staff_Review__c>>();
        for (Staff_Review__c sr : [SELECT Id, NTA_Review__c, Review_Status__c, RecordType.Name, Risk_Score__c, Risk_Comments__c, AA_Narrative_Summary__c, 
        Financial_Review_Comments__c, Reviewing_Official_Summary__c, Program_Review_Summary__c  FROM Staff_Review__c WHERE NTA_Review__c IN :ntaIds]) {
            if (!ntaToStaffReviews.containsKey(sr.NTA_Review__c)) {
                ntaToStaffReviews.put(sr.NTA_Review__c, new List<Staff_Review__c>());
            }
            ntaToStaffReviews.get(sr.NTA_Review__c).add(sr);
        }

        Map<Id, NTA_Review__c> existingNTAs = new Map<Id, NTA_Review__c>(
            [SELECT Id, AA_Review_Completed_Date__c, BA_Review_Completed_Date__c, RO_Review_Completed_Date__c, Program_Review_Completed_Date__c, 
                    AA_Risk_Score__c, AA_Risk_Comments__c, BA_Risk_Comments__c, BA_Risk_Score__c, 
                    AA_Summary__c, BA_Summary__c, PO_Summary__c, RO_Summary__c
             FROM NTA_Review__c WHERE Id IN :ntaIds]
        );

        List<NTA_Review__c> ntaUpdates = new List<NTA_Review__c>();

        // populate nta fields
        for (Id ntaId : ntaToStaffReviews.keySet()) {
            List<Staff_Review__c> staffReviews = ntaToStaffReviews.get(ntaId);
            NTA_Review__c nta = new NTA_Review__c(Id = ntaId);

            for (Staff_Review__c sr : staffReviews) {

                if (sr.RecordType.Name == 'Advocacy Analyst Review') {
                    nta.Advocacy_Analyst_Review_Status__c = sr.Review_Status__c;
                    nta.AA_Risk_Score__c = sr.Risk_Score__c;
                    nta.AA_Risk_Comments__c = sr.Risk_Comments__c;
                    nta.AA_Summary__c = sr.AA_Narrative_Summary__c;

                    if(existingNTAs.get(nta.Id).AA_Review_Completed_Date__c == null && sr.Review_Status__c == 'Complete'){
                        nta.AA_Review_Completed_Date__c = Date.today();
                    }
                } else if (sr.RecordType.Name == 'Budget Analyst Review') {
                    nta.Budget_Analyst_Review_Status__c = sr.Review_Status__c;
                    nta.BA_Risk_Score__c = sr.Risk_Score__c;
                    nta.BA_Risk_Comments__c = sr.Risk_Comments__c;
                    nta.BA_Summary__c = sr.Financial_Review_Comments__c;

                    if(existingNTAs.get(nta.Id).BA_Review_Completed_Date__c == null && sr.Review_Status__c == 'Complete'){
                        nta.BA_Review_Completed_Date__c = Date.today();
                    }

                } else if (sr.RecordType.Name == 'Reviewing Official Review') {
                    nta.Reviewing_Official_Review_Status__c = sr.Review_Status__c;
                    nta.RO_Summary__c = sr.Reviewing_Official_Summary__c;

                    if(existingNTAs.get(nta.Id).RO_Review_Completed_Date__c == null && sr.Review_Status__c == 'Complete'){
                        nta.RO_Review_Completed_Date__c = Date.today();
                    }
                } else if (sr.RecordType.Name == 'Program Office Review') {
                    nta.Program_Office_Review_Status__c = sr.Review_Status__c;
                    nta.PO_Summary__c = sr.Program_Review_Summary__c;

                    if(existingNTAs.get(nta.Id).Program_Review_Completed_Date__c == null && sr.Review_Status__c == 'Complete'){
                        nta.Program_Review_Completed_Date__c = Date.today();
                    }

                    if(sr.Review_Status__c == 'Complete'){ 
                        nta.Review_Status__c = 'Staff Review Complete';
                    }
                }
            }

            ntaUpdates.add(nta);
        }

        if (!ntaUpdates.isEmpty()) {
            update ntaUpdates;
        }
    }
}