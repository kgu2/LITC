public with sharing class FundingDisbursementTriggerHandler {
    public static void handleAfterUpdate( List<FundingDisbursement> disbursements ) {   
    }
    public static void handleAfterInsert( List<FundingDisbursement> disbursements ) {
        FundingDisbursementTriggerHandler.populateFieldsOnInsert(disbursements);   
    }

    public static void handleBeforeUpdate( List<FundingDisbursement> disbursements, Map<Id, FundingDisbursement> oldMap ) {
        FundingDisbursementTriggerHandler.populateFieldsUpdate(disbursements, oldMap);  
    }

    private static void populateFieldsUpdate(List<FundingDisbursement> disbursements, Map<Id, FundingDisbursement> oldMap){ 
        for(FundingDisbursement fd: disbursements){ 
            FundingDisbursement oldFd = oldMap.get(fd.Id);

            if (fd.Recipient_Status__c == 'Rejected' && oldFd.Recipient_Status__c != 'Rejected') {
                fd.Review_Status__c = 'Rejected';
            }
            if (fd.Review_Status__c == 'Issued' && oldFd.Review_Status__c != 'Issued') {
                fd.DisbursementDate = Date.today();
            }
        }
    }

    private static void populateFieldsOnInsert(List<FundingDisbursement> disbursements){ 
        Map<Id, FundingDisbursement> fundingAwardToDisbursement = new Map<Id, FundingDisbursement>();

        for(FundingDisbursement fd: disbursements){ 
            fundingAwardToDisbursement.put(fd.FundingAwardId, fd);
        }

        List<FundingAward> appsToUpdate = [SELECT Id, Name, Review_Status__c, Federal_Funds_Obligated_This_Action_v2__c FROM FundingAward WHERE Id IN :fundingAwardToDisbursement.keySet()];

        for (FundingAward fa : appsToUpdate) {
            FundingDisbursement fd = fundingAwardToDisbursement.get(fa.Id);
            fa.Federal_Funds_Obligated_This_Action_v2__c = fd.Amount;
        }

        if (!appsToUpdate.isEmpty()) {
            update appsToUpdate;
        }
    }

}