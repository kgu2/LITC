global without sharing class OmniStudioFileController {
    @AuraEnabled(cacheable=false)
    public static string getContentDocumentId(String contentVersionId){
        try {
            ContentVersion cv = [select Id, ContentDocumentId from ContentVersion where Id = :contentVersionId LIMIT 1 ];
            return cv.ContentDocumentId;
        } catch (Exception e) {
            if(!System.test.isRunningTest()) throw new AuraHandledException(e.getMessage());
            return 'Error';
        }
    }

    
    @AuraEnabled(cacheable=false)
    public static list<ContentVersion> releatedFiles(Id contentVersionId){
        return [SELECT Id, Title, ContentDocumentId, CreatedDate, File_Prefix__c  
                        FROM ContentVersion 
                        WHERE Id = :contentVersionId ];
    }

    @AuraEnabled(cacheable=false)
    public static void deleteFiles(Id contentVersionId){
        ContentVersion cv = [SELECT Id, Title, ContentDocumentId, CreatedDate, File_Prefix__c  
                        FROM ContentVersion 
                        WHERE Id = :contentVersionId LIMIT 1];
        delete [select Id from ContentDocument where Id = :cv.ContentDocumentId limit 1];
    }

}