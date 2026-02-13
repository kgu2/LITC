trigger LineItemSnapshotTrigger on X13424_J_Line_Item_Snapshot__c (after insert, after update, after delete) {
    LineItemSnapshotTriggerHandler.handleEvent();
}