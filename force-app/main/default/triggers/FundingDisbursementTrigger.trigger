trigger FundingDisbursementTrigger on FundingDisbursement (before insert, before update, after update, after insert, after delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        FundingDisbursementTriggerHandler.handleAfterUpdate(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        FundingDisbursementTriggerHandler.handleAfterInsert(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        FundingDisbursementTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}