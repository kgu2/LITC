trigger StaffReviewTrigger on Staff_Review__c (after update) {
    if(trigger.isUpdate && trigger.isAfter){
        StaffReviewTriggerHandler.afterUpdate((List<Staff_Review__c>)trigger.new);
    }
}