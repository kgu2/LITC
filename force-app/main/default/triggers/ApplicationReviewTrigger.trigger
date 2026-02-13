trigger ApplicationReviewTrigger on ApplicationReview (before insert, after update) {
    if (Trigger.isAfter) {
        if (Trigger.isupdate) {
            ApplicationReviewTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}