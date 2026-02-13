trigger G20EventRegistrationTrigger on G20_Event_Registration__c (after insert) {
    List<G20_Event_Registration__c> updates = new List<G20_Event_Registration__c>();

    for (G20_Event_Registration__c reg : Trigger.new) {
        G20_Event_Registration__c updateRec = new G20_Event_Registration__c(Id = reg.Id, Access_Token__c = EncrpytionUtility.encryptRecordId(reg.Id));
        updates.add(updateRec);
    }

    if (!updates.isEmpty()) {
        update updates;
    }
}
