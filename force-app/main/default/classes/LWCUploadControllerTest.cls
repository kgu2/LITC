/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* @name             LWCUploadControllerTests
* @description      Test class for LWCUploadController class.
* ────────────────────────────────────────────────────────────────────────────────────────────────── 
*/
@isTest
public class LWCUploadControllerTest {
    
    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * @methodname		setup
     * @description		Test data setup method.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param    		none
     * @return   		void
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */       
    @istest 
    static void runTest_DEFAULT_SUCCESS() {
        
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        
        LWCUploadController lwc = new LWCUploadController();        
        ContentVersion cv = new ContentVersion();
        String fileName = 'temptestfile.txt'; 
        String base64Data = 'VGVzdCBTdHJpbmc=';
        String fileCount = '1';
        String prefix = 'prefix';
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.File_Prefix__c = 'helloWorld';
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        Insert cv;
        
        ContentVersion cv1 = new ContentVersion();
        String fileName1 = 'temptestfile1.txt'; 
        String base64Data1 = 'VGVzdCBTdHJpbmc=';
        String fileCount1 = '1';
        String prefix1 = 'prefix';
        cv1.Title = fileName1;
        cv1.PathOnClient = '/' + fileName1;
        cv1.File_Prefix__c = 'helloWorld';
        cv1.VersionData = EncodingUtil.base64Decode(base64Data1);
        Insert cv1;
 
        
        
        Id conDocument = 
            [SELECT ContentDocumentId 
             FROM ContentVersion 
             WHERE Id =:cv.Id].ContentDocumentId;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = conDocument;//Add ContentDocumentId
        link.LinkedEntityId = a.Id;//Add attachment parentId
        link.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        link.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
        insert link;
               
 
        try{
            LWCUploadController.releatedFiles(a.Id, prefix, fileCount);
        } catch(Exception e) {
            system.debug('caught error');
        }
        
        list< String > uploadIds  = new list< String >();
        uploadIds.add(conDocument);
        
        LWCUploadController.updateRecord(cv.ContentDocumentId, null, prefix, false);
        LWCUploadController.updateRecord(cv.ContentDocumentId, uploadIds, prefix, false);


        String tempURL1 = LWCUploadController.generateDownloadURLs(conDocument, 'ERA');
        
        LWCUploadController.deleteURL(cv.Id);        
    }
    
	/**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * @methodname		runTest_PREPEND_PREFIX_SUCCESS
     * @description		Default test of all class methods.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param    		none
     * @return   		void
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */     
    @istest 
    static void runTest_PREPEND_PREFIX_SUCCESS() {
        
        Account a = new Account();
        a.Name = 'Test Account';
        insert a;
        
        LWCUploadController lwc = new LWCUploadController();        
        ContentVersion cv = new ContentVersion();
        String fileName = 'temptestfile.txt'; 
        String base64Data = 'VGVzdCBTdHJpbmc=';
        String fileCount = '1';
        String prefix = 'MIP_Matrix';
        cv.Title = fileName;
        cv.PathOnClient = '/' + fileName;
        cv.File_Prefix__c = prefix;
        cv.VersionData = EncodingUtil.base64Decode(base64Data);
        Insert cv;
        
        Id conDocument = 
            [SELECT ContentDocumentId 
             FROM ContentVersion 
             WHERE Id =:cv.Id].ContentDocumentId;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = conDocument;//Add ContentDocumentId
        link.LinkedEntityId = a.Id;//Add attachment parentId
        link.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        link.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
        insert link;
        
        // LWCUploadController.saveFile(cv.ContentDocumentId, fileName, base64Data);
        try{
            // RA-765 Replaced accessor method with new method based on ContentDocumentLink
            // object in order to support unlinking files
 
            // Legacy accessor ContentVersion method
            LWCUploadController.releatedFiles(a.Id, prefix, fileCount);
        } catch(Exception e) {
            system.debug('caught error');
        }
        
        list< String > uploadIds  = new list< String >();
        uploadIds.add(conDocument);
        
        LWCUploadController.updateRecord(cv.ContentDocumentId, null, prefix, false);
        LWCUploadController.updateRecord(cv.ContentDocumentId, uploadIds, prefix, false);
        
        //LWCUploadController.generateContentDistribution(cv.Id);
        
        // Invoke generateDownloadURLs method with Program = "ANY"
        String tempURL = LWCUploadController.generateDownloadURLs(conDocument, 'ANY');
        
      
        LWCUploadController.deleteURL(cv.Id);        
    }    
    
    /**
     * ───────────────────────────────────────────────────────────────────────────────────────────────┐
     * @methodname		prependFilePrefix_PREFIX_FOUND_SUCCESS
     * @description		Test for prependFilePrefix() method.
     * ────────────────────────────────────────────────────────────────────────────────────────────────
     * @param    		none
     * @return   		void
     * ───────────────────────────────────────────────────────────────────────────────────────────────┘
     */     


     @isTest
     static void testSaveFile() {
         // Get the test Account record
         Account testAccount = new Account();
         testAccount.Name = 'Test Account';
         insert testAccount;
         
         // Define test data
         String fileName = 'TestFile.txt';
         String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));

        LWCUploadController.saveFile(testAccount.Id, base64Data, fileName);
         
         Test.startTest();
         
         // Call the method
         LWCUploadController.saveFile(testAccount.Id, base64Data, fileName);
         
         Test.stopTest();
     }

    @isTest
     static void testGeneratePDF() {
         Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c();
         insert app;

        String pdfUrl = LWCUploadController.generatePDF(app.Id, 'SF424', 'test');
     }
 
}