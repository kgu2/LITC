trigger FundingAwardTrigger on FundingAward (before insert, before update, after update, after insert, after delete) {
    if (Trigger.isAfter && Trigger.isUpdate) {
        FundingAwardTriggerHandler.handleAfterUpdate(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isInsert) {
        FundingAwardTriggerHandler.handleAfterInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isInsert) {
        FundingAwardTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isUpdate) {
        FundingAwardTriggerHandler.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
    if (Trigger.isDelete) {
        FundingAwardTriggerHandler.handleAfterDelete(Trigger.old);
    }
}