/**********************************************************************************
* Name  : LWCUploadController
* Author :  
* Desc  : used for File upload related LWC components
* Created On : Unknown
* Test classes : LWCUploadControllerTests
*
* Modification Log:
* ----------------------------------------------------------------------
* Developer      Date       Description  
* ----------------------------------------------------------------------
**********************************************************************************/
public class LWCUploadController {

    /**
     * Updates ContentVersion records with a given file prefix
     *
     * @param recordId The ID of the parent record.
     * @param uploadIds List of ContentDocumentIds of the uploaded files.
     * @param prefix The file prefix to assign.
     * @param showFilesOnPortal Whether the files should be visible to all users.
     */
    @AuraEnabled
    public static string updateRecord(String recordId, list< String > uploadIds, String prefix, Boolean showFilesOnPortal){
        if( uploadIds == null || uploadIds.size() == 0 )
            return 'No Files Provided';

        List<ContentVersion> versions = [SELECT Id, File_Prefix__c, Description FROM ContentVersion WHERE ContentDocumentId IN : uploadIds];

        for( ContentVersion v : versions )
        { 
            v.File_Prefix__c = prefix;
            v.Description = 'Additional Documents';
        }

        update versions;

        if(showFilesOnPortal != null && showFilesOnPortal == true) {

            List<ContentDocumentLink> links = [SELECT Id, ContentDocumentId, Visibility FROM ContentDocumentLink WHERE ContentDocumentId IN : uploadIds];

            for(ContentDocumentLink link : links) {

                link.Visibility = 'AllUsers';
            }

            update links;
        }

        return 'Success';
    }


    /**
     * Retrieves related files linked to a parent record.
     *
     * @param idParent The ID of the parent record.
     * @param prefix file prefix to filter results.
     * @param fileCount file count
     * @return A list of ContentVersion records.
     */
    @AuraEnabled(cacheable=true)
    public static list<ContentVersion> releatedFiles(Id idParent, String prefix, String fileCount){
        if(prefix == null || prefix == '')
        {

        }
        list<id> lstConDocs = new list<id>();
        list<id> parentIds = new list<id>();
        parentIds.add(idParent);
        for(ContentDocumentLink cntLink : [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :idParent]) {
            lstConDocs.add(cntLink.ContentDocumentId);
        }
        if(!lstConDocs.isEmpty()) {
            if(prefix == null || prefix == '')
                return [SELECT Id, Title, ContentDocumentId, CreatedDate, File_Prefix__c  
                        FROM ContentVersion 
                        WHERE ContentDocumentId IN :lstConDocs ];
            else
                return [SELECT Id, Title, ContentDocumentId, CreatedDate, File_Prefix__c 
                        FROM ContentVersion 
                        WHERE ContentDocumentId IN :lstConDocs 
                        AND (File_Prefix__c = :prefix OR File_Prefix__c ='Previous1')];
        }
        else {
            return null;
        }
    }
    
    /**
     * Generates a public download URL for a ContentDocument.
     *
     * @param contentDocumentId The ID of the ContentDocument
     * @param program program
     */
    @AuraEnabled
    public static String generateDownloadURLs(string contentDocumentId, String program){
        ContentVersion cv = new ContentVersion();
        cv = [SELECT Id,ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =: contentDocumentId AND File_Prefix__c != null LIMIT 1];
        ContentDistribution contentDistribution = generateContentDistribution(cv.Id);
        return contentDistribution.ContentDownloadUrl;
    }

    /**
     * Creates a public ContentDistribution record for a file.
     *
     * @param contentVersionId The ID of the ContentVersion.
     */
    public static ContentDistribution generateContentDistribution(String contentVersionId) {
        ContentDistribution contentDistribution = new ContentDistribution();
        System.debug('here');
        contentDistribution.Name = 'PSP Compliance Request';
        contentDistribution.ContentVersionId = contentVersionId;
        contentDistribution.PreferencesAllowViewInBrowser= false;
        contentDistribution.PreferencesLinkLatestVersion=true;
        contentDistribution.PreferencesNotifyOnVisit=false;
        contentDistribution.PreferencesPasswordRequired=false;
        contentDistribution.PreferencesAllowOriginalDownload= true;

        insert contentDistribution;


        return [SELECT Id, ContentDownloadUrl,ContentVersionId,DistributionPublicUrl,PreferencesPasswordRequired 
                FROM ContentDistribution WHERE Id =: contentDistribution.Id LIMIT 1];

    }

    /**
     * Deletes a public download URL for a file.
     *
     * @param contentVersionId The ID of the ContentVersion.
     */
    @AuraEnabled
    public static String deleteURL(string contentVersionId) {
        deleteDistribution(contentVersionId);
        return 'success';
    }

    /**
     * Deletes a ContentDistribution record 
     *
     * @param contentVersionId The ID of the ContentVersion.
     */
    @Future
    public static void deleteDistribution(string contentVersionId) {
        sleep(5000);
        ContentDistribution distribs = [SELECT Id FROM ContentDistribution WHERE ContentVersionId =: contentVersionId LIMIT 1];
        update distribs;
    }

    /**
     * Delays execution for a specified duration.
     *
     * @param milliSeconds The duration to pause 
     */
    public static void sleep(Long milliSeconds)
    {
        Long timeDiff = 0;
        DateTime firstTime = System.now();
        do
        {
            timeDiff = System.now().getTime() - firstTime.getTime();
        }
        while(timeDiff <= milliSeconds);
    }

    /**
     * Saves a file to a record by creating a content version and contentDocumentLink
     *
     * @param recordId The ID of the record to link the file to
     * @param base64Data The base64-encoded file data
     * @param fileName The file name
     */
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


    @AuraEnabled
    public static String generatePDF(String recordId, String vfPageName, String prefix) {
   
        PageReference pdf = new PageReference('/apex/' + vfPageName);
        pdf.getParameters().put('id', recordId);

        Blob body;
        try {
            body = pdf.getContent();
        } catch (VisualforceException e) {
            body = Blob.valueOf('PDF FAILED TO GENERATE');
        }

        // Create ContentVersion
        ContentVersion cVersion = new ContentVersion();
        cVersion.ContentLocation = 'S';
        cVersion.PathOnClient = prefix + '.pdf';
        cVersion.Origin = 'C';
        cVersion.OwnerId = UserInfo.getUserId();
        cVersion.Title = prefix + '.pdf';
        cVersion.File_Prefix__c = prefix;
        cVersion.VersionData = body;
        insert cVersion;

        // Link to record
        Id conDocument = [
            SELECT ContentDocumentId 
            FROM ContentVersion 
            WHERE Id = :cVersion.Id 
            LIMIT 1
        ].ContentDocumentId;

        ContentDocumentLink cDocLink = new ContentDocumentLink();
        cDocLink.ContentDocumentId = conDocument;
        cDocLink.LinkedEntityId = recordId;
        cDocLink.ShareType = 'I';
        cDocLink.Visibility = 'AllUsers';
        insert cDocLink;

        // Create public distribution link
        ContentDistribution cd = new ContentDistribution();
        cd.Name = prefix + ' PDF';
        cd.ContentVersionId = cVersion.Id;
        cd.PreferencesAllowViewInBrowser = true;
        cd.PreferencesLinkLatestVersion = true;
        cd.PreferencesNotifyOnVisit = false;
        cd.PreferencesPasswordRequired = false;
        cd.PreferencesAllowOriginalDownload = true;
        insert cd;

        cd = [SELECT Id, DistributionPublicUrl  FROM ContentDistribution WHERE Id = :cd.Id LIMIT 1];
        return cd.DistributionPublicUrl;
    }

}