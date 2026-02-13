public with sharing class LITCPaymentsTriggerHandler {
    public static void handleBeforeInsert(List<LITC_Payment__c> payments) {
        Set<String> documentNumbers = new Set<String>();

        for(LITC_Payment__c payment : payments){ 
            if(payment.Document_Number__c != null){ 
                documentNumbers.add(payment.Document_Number__c);
            }
        }

        Map<String, Id> documentNumberToFA = new Map<String,Id>();

        for(FundingAward award : [SELECT Id, Name, Payment_Identifier__c FROM FundingAward WHERE Payment_Identifier__c IN: documentNumbers]){ 
            documentNumberToFA.put(award.Payment_Identifier__c, award.Id);
        }

        for(LITC_Payment__c payment : payments){ 
            if(documentNumberToFA.containsKey(payment.Document_Number__c)){ 
                payment.Funding_Award__c = documentNumberToFA.get(payment.Document_Number__c);
            }
        }


    }
}