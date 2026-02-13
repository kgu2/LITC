public with sharing class SignatureController {
    @AuraEnabled
    public static void saveFile(Id recordId, String base64Data, String fileName) {
        try {
            ContentVersion contentVersion = new ContentVersion();
            contentVersion.Title = fileName;
            contentVersion.PathOnClient = fileName;
            contentVersion.VersionData = EncodingUtil.base64Decode(base64Data);
            insert contentVersion;

            ContentDocumentLink contentDocumentLink = new ContentDocumentLink();
            contentDocumentLink.LinkedEntityId = recordId;
            contentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
            contentDocumentLink.ShareType = 'V';
            contentDocumentLink.Visibility = 'AllUsers';
            insert contentDocumentLink;
        } catch (Exception ex) {
            throw new AuraHandledException('Error saving file: ' + ex.getMessage());
        }
    }
}