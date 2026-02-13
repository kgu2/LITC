trigger SiteVisitTrigger on Site_Visit__c (before insert, after insert, before update, after update) {
    if (Trigger.isBefore && Trigger.isInsert) {
        SiteVisitTriggerHandler.beforeInsert(Trigger.new);
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        SiteVisitTriggerHandler.afterUpdate(Trigger.new);
    }
}