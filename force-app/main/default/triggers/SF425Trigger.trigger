trigger SF425Trigger on SF425_Form__c (before insert, before update) {
    if (Trigger.isBefore && Trigger.isUpdate) {
        LITCReportingController.handleBeforeUpdateSF425(Trigger.new, Trigger.oldMap);
    }

}