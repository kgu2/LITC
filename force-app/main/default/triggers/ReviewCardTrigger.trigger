trigger ReviewCardTrigger on Review_Card__c (after insert, before insert, after update) {

    if(trigger.isInsert && trigger.isAfter){
        ReviewCardHandler.afterInsert((List<Review_Card__c>)trigger.new);
    }
    if(trigger.isUpdate && trigger.isAfter){
        ReviewCardHandler.afterUpdate((List<Review_Card__c>)trigger.new);
    }

}