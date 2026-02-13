trigger LITCReportingFormTrigger on LITC_Reporting_Form__c (before insert, before update, after update, after insert, after delete) {
    if (Trigger.isAfter && Trigger.isInsert) {
        LITCReportingController.generateLineItems(Trigger.new);
    }

    if (Trigger.isBefore && Trigger.isUpdate) {
        LITCReportingController.handleBeforeUpdate(Trigger.new, Trigger.oldMap);
    }
}