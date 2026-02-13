public class ContentDocumentLinkTriggerHandler {
    public static void afterInsert(List<ContentDocumentLink> records) {

        Set<Id> registrationIds = new Set<Id>();
        for (ContentDocumentLink link : records) {
            registrationIds.add(link.LinkedEntityId);
        }

        if (registrationIds.isEmpty()) return;

        Map<Id, G20_Event_Registration__c> regMap = new Map<Id, G20_Event_Registration__c>(
            [SELECT Id, DI_First_Name__c, DI_Last_Name__c FROM G20_Event_Registration__c WHERE Id IN :registrationIds]
        );

        if (regMap.isEmpty()) return;


        Map<Id, G20_Event_Registration__c> docToRegMap = new Map<Id, G20_Event_Registration__c>();
        for (ContentDocumentLink link : records) {
            if (regMap.containsKey(link.LinkedEntityId)) {
                docToRegMap.put(link.ContentDocumentId, regMap.get(link.LinkedEntityId));
            }
        }

        if (docToRegMap.isEmpty()) return;


        List<ContentVersion> versionsToUpdate = [SELECT Id, Title, ContentDocumentId, File_Prefix__c FROM ContentVersion WHERE IsLatest = true AND ContentDocumentId IN :docToRegMap.keySet()];

        for (ContentVersion cv : versionsToUpdate) {
            G20_Event_Registration__c reg = docToRegMap.get(cv.ContentDocumentId);
            if (reg != null) {
                cv.Title = reg.DI_First_Name__c + '.' + reg.DI_Last_Name__c + '.Passport Photo';
            }
        }

        if (!versionsToUpdate.isEmpty()) {
            update versionsToUpdate;
        }

        List<G20_Event_Registration__c> regsToUpdate = new List<G20_Event_Registration__c>();
        String baseUrl = URL.getOrgDomainURL().toExternalForm();
        System.debug(baseUrl);

        for (ContentDocumentLink link : records) {
            G20_Event_Registration__c reg = regMap.get(link.LinkedEntityId);
            if (reg != null) {
                reg.Download_Link__c = baseUrl + '/sfc/servlet.shepherd/document/download/' + link.ContentDocumentId;
                reg.ContentDocumentId__c = link.ContentDocumentId;
                regsToUpdate.add(reg);
            }
        }

        if (!regsToUpdate.isEmpty()) {
            update regsToUpdate;
        }
    }
}
