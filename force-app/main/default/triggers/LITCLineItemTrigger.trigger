trigger LITCLineItemTrigger on X13424_J_Line_Item__c (after insert, after update, after delete) {
    LitcLineItemTriggerHandler.handleEvent();
}