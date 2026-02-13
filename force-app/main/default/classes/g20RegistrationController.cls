public with sharing class g20RegistrationController {

    @AuraEnabled(cacheable=true)
    public static List<G20_Event__c> getG20Event() {
        List<G20_Event__c> apps = new List<G20_Event__c>();
        for (G20_Event__c app : [SELECT Id, Name FROM G20_Event__c]){ 
            apps.add(app);
        }
        return apps;
    }

    @AuraEnabled
    public static void relinkFile(Id contentDocumentId, Id newParentId) {
        try {
            List<ContentDocumentLink> existingLinks = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :contentDocumentId];
            List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();

            for (ContentDocumentLink link : existingLinks) {
                if (String.valueOf(link.LinkedEntityId).startsWith('003')) {
                    linksToDelete.add(link);
                }
            }

            if (!linksToDelete.isEmpty()) delete linksToDelete;

            insert new ContentDocumentLink(
                ContentDocumentId = contentDocumentId,
                LinkedEntityId = newParentId,
                ShareType = 'V',
                Visibility = 'AllUsers'
            );

        } catch (Exception e) {
            throw new AuraHandledException('Error relinking file: ' + e.getMessage());
        }
    }
}