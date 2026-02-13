trigger NTAReviewTrigger on NTA_Review__c (after update, before update, after insert) {

    if (Trigger.isBefore && Trigger.isUpdate) {
        NTAReviewTriggerHandler.beforeUpdate(Trigger.new);
    }
    if (Trigger.isAfter && Trigger.isUpdate) {
        NTAReviewTriggerHandler.processNTAReview(Trigger.new, Trigger.oldMap);

        NTAReviewTriggerHandler.processDeleteRCs(Trigger.new, Trigger.oldMap);
    }
    if(Trigger.isAfter && Trigger.isInsert){ 
        NTAReviewTriggerHandler.afterInsert(Trigger.new);
    }
}