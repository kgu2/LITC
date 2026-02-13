public with sharing class SiteVisitTriggerHandler {
    public static void beforeInsert(List<Site_Visit__c> visits) {
    
        Set<Id> accountIds = new Set<Id>();
        for (Site_Visit__c visit : visits) {
            accountIds.add(visit.Related_Business_Account__c);
        }

        System.debug(accountIds);

        Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, AA_Assignment__c FROM Account WHERE Id IN :accountIds]);


        Map<Id, Application_for_Federal_Assistance__c> acctToApp = new Map<Id, Application_for_Federal_Assistance__c>();
        List<Application_for_Federal_Assistance__c> apps = [
            SELECT Id, Grant_Year__c, Related_Business_Account__c, (SELECT Id FROM NTA_Reviews__r LIMIT 1)  
            FROM Application_for_Federal_Assistance__c
            WHERE Related_Business_Account__c IN :accountIds
            ORDER BY Grant_Year__c DESC
        ];

        for (Application_for_Federal_Assistance__c app : apps) {
            if (!acctToApp.containsKey(app.Related_Business_Account__c)) {
                acctToApp.put(app.Related_Business_Account__c, app);
            }
        }

        System.debug(acctToApp);

        for (Site_Visit__c visit : visits) {
            Application_for_Federal_Assistance__c app = acctToApp.get(visit.Related_Business_Account__c);
            if (app != null) {
                visit.Application_for_Federal_Assistance__c = visit.Application_for_Federal_Assistance__c == null ? app.Id : visit.Application_for_Federal_Assistance__c;
                if (!app.NTA_Reviews__r.isEmpty()) {
                    visit.Most_recent_NTA__c = visit.Most_recent_NTA__c == null? app.NTA_Reviews__r[0].Id : visit.Most_recent_NTA__c;
                }
            }

            Account account = accountMap.get(visit.Related_Business_Account__c);
            visit.Assigned_Advocacy_Analyst__c = visit.Assigned_Advocacy_Analyst__c== null? account.AA_Assignment__c: visit.Assigned_Advocacy_Analyst__c;
        }
    }


    public static void afterUpdate(List<Site_Visit__c> visits){ 
        Map<Id, Site_Visit__c> acctToVisit = new Map<Id, Site_Visit__c>();
        for (Site_Visit__c visit : visits) {
            if (!acctToVisit.containsKey(visit.Related_Business_Account__c)) {
                acctToVisit.put(visit.Related_Business_Account__c, visit);
            }
        }


        List<Account> accountsToUpdate = new List<Account>();

        for(Account acc : [SELECT Id, Name, Potential_Visit_Flag__c FROM Account WHERE Id IN: acctToVisit.keySet()]){ 
            Site_Visit__c visit = acctToVisit.get(acc.Id);
            acc.Potential_Visit_Flag__c = visit.Potential_Visit_Flag__c;
            accountsToUpdate.add(acc);
        }

        if(!accountsToUpdate.isEmpty()){ 
            update accountsToUpdate;
        }
    }
}