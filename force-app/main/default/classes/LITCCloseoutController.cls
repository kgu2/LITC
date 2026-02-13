public with sharing class LITCCloseoutController {
    
    @AuraEnabled
    public static void runChecks(String recordId){ 
        FundingAward fa = [
            SELECT Id, Application_for_Federal_Assistance__c, LITC_Reporting_L_Form__c, SF425_Form__c,
            All_disbursements_accepted__c , All_Reporting_Forms_Accepted__c , All_Reporting_Forms_Submitted__c  
            FROM FundingAward WHERE ID =: recordId];
        
        List<LITC_Reporting_Form__c> forms = [
            SELECT Id, Name, RecordType.Name FROM LITC_Reporting_Form__c 
            WHERE Application_for_Federal_Assistance__c =: fa.Application_for_Federal_Assistance__c
            AND RecordType.Name = 'Form 13424-L' ORDER BY CreatedDate desc LIMIT 1];
        
        List<SF425_Form__c> sfForms= [
            SELECT Id, Application_for_Federal_Assistance__c, Status__c, Review_Status__c
            FROM SF425_Form__c 
            WHERE Application_for_Federal_Assistance__c =: fa.Application_for_Federal_Assistance__c ORDER BY CreatedDate desc LIMIT 1];
         
        List<LITC_Payment__c> payments= [
            SELECT Id, Name, Funding_Award__c
            FROM LITC_Payment__c 
            WHERE Funding_Award__c =: fa.Id ORDER BY CreatedDate desc LIMIT 1];

        if (!forms.isEmpty()) {
            fa.LITC_Reporting_L_Form__c = forms[0].Id;
        }
        if (!sfForms.isEmpty()) {
            fa.SF425_Form__c = sfForms[0].Id;
        }
        if (!payments.isEmpty()) {
            fa.LITC_Payment__c = payments[0].Id;
        }

        List<FundingDisbursement> disbursements = [SELECT Id, Name, Recipient_Status__c FROM FundingDisbursement WHERE FundingAwardId =: fa.Id];
    
        fa.All_disbursements_accepted__c = true;
        if(!disbursements.isEmpty()){ 
            for(FundingDisbursement FundingDisbursement : disbursements){ 
                if(FundingDisbursement.Recipient_Status__c != 'Accepted'){ 
                    fa.All_disbursements_accepted__c = false;
                    break;
                }
            }
        }

        // List<LITC_Payment__c> allPayments = [SELECT Id, Name, Funding_Award__c FROM LITC_Payment__c WHERE Funding_Award__c =: fa.Id];
        // fa.PMS_Figures_Validated__c = true;

        // if(!allPayments.isEmpty()){ 
        //     for(LITC_Payment__c payment : allPayments){ 
        //         if(form.Review_Status__c != 'Accepted'){ 
        //             fa.All_Reporting_Forms_Accepted__c = false;
        //             break;
        //         }
        //     }
        // }


        List<LITC_Reporting_Form__c> allReportingForms = [
            SELECT Id, Name, RecordType.Name, Status__c, Review_Status__c FROM LITC_Reporting_Form__c 
            WHERE Application_for_Federal_Assistance__c =: fa.Application_for_Federal_Assistance__c];

        List<SF425_Form__c> allSfForms= [
            SELECT Id, Application_for_Federal_Assistance__c, Status__c, Review_Status__c
            FROM SF425_Form__c 
            WHERE Application_for_Federal_Assistance__c =: fa.Application_for_Federal_Assistance__c];

        fa.All_Reporting_Forms_Accepted__c = true;
        fa.All_Reporting_Forms_Submitted__c = true;

        if(!allReportingForms.isEmpty()){ 
            for(LITC_Reporting_Form__c form : allReportingForms){ 
                if(form.Review_Status__c != 'Accepted'){ 
                    fa.All_Reporting_Forms_Accepted__c = false;
                    break;
                }
            }
            for(LITC_Reporting_Form__c form : allReportingForms){ 
                if(form.Status__c != 'Submitted'){ 
                    fa.All_Reporting_Forms_Submitted__c = false;
                    break;
                }
            }
        }

        if(!allSfForms.isEmpty()){ 
            for(SF425_Form__c form : allSfForms){ 
                if(form.Review_Status__c != 'Accepted'){ 
                    fa.All_Reporting_Forms_Accepted__c = false;
                    break;
                }
            }
            for(SF425_Form__c form : allSfForms){ 
                if(form.Status__c != 'Submitted'){ 
                    fa.All_Reporting_Forms_Submitted__c = false;
                    break;
                }
            }
        }

        update fa;        
        
    }
}