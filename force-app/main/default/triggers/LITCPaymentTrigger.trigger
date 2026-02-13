trigger LITCPaymentTrigger on LITC_Payment__c (before insert, after insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        LITCPaymentsTriggerHandler.handleBeforeInsert(Trigger.new);
    }
}