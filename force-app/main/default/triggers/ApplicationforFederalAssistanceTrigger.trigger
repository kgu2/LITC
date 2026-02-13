trigger ApplicationforFederalAssistanceTrigger on Application_for_Federal_Assistance__c (
    before insert, 
    before update, 
    after insert, 
    after update,
    after delete
) {
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {

        } else if (Trigger.isUpdate) {
            ApplicationforFederalAssiTriggerHandler.beforeUpdate(Trigger.new, Trigger.oldMap);
        } 
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ApplicationforFederalAssiTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isUpdate) {
            ApplicationforFederalAssiTriggerHandler.afterUpdate(Trigger.new, Trigger.oldMap);
        } 
    }
    }