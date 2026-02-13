public with sharing class SF425ReportingController {
    public SF425ReportingController() {

    }
    @AuraEnabled(cacheable=true)
    public static List<SF425_Form__c> getReportsLITC() {
        List<SF425_Form__c> apps = new List<SF425_Form__c>();
        for (SF425_Form__c app : [SELECT Id, Name, Status__c, Reporting_Type__c, Reporting_Period_Full__c, Report_Type__c, Submission_Deadline__c, RecordType.Name FROM SF425_Form__c]){ 
            apps.add(app);
        }
        return apps;
    }
    @AuraEnabled(cacheable=true)
    public static Contact getCurrentContactInformation() {
        String currentUserId = System.UserInfo.getUserId();
        User u = [Select u.ContactId from User u where u.Id = :currentUserId];
        Id contactb = u.contactID;
        Contact c = [SELECT Name, FirstName, LastName, MiddleName, Suffix,  Email, Title, Phone, LITC_Role_v2__c, Id FROM Contact WHERE Id =: contactb];
        return c;
    }
}