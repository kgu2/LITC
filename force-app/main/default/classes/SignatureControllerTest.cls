@isTest
public with sharing class SignatureControllerTest {
    @testSetup
    static void setupTestData() {
        // Create a test Account to use as the recordId
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
    }

    @isTest
    static void testSaveFile() {
        // Get the test Account record
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Define test data
        String fileName = 'TestFile.txt';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf('Test file content'));
        
        Test.startTest();
        
        // Call the method
        SignatureController.saveFile(testAccount.Id, base64Data, fileName);
        
        Test.stopTest();
        
        // Validate ContentVersion record was created
        ContentVersion cv = [SELECT Id, Title, VersionData FROM ContentVersion WHERE Title = :fileName LIMIT 1];
        System.assertNotEquals(null, cv, 'ContentVersion should have been created');
        System.assertEquals(fileName, cv.Title, 'File name should match');
        
        // Validate ContentDocumentLink was created
        ContentDocumentLink cdl = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId = :testAccount.Id LIMIT 1];
        System.assertNotEquals(null, cdl, 'ContentDocumentLink should have been created');
        System.assertEquals(testAccount.Id, cdl.LinkedEntityId, 'LinkedEntityId should match testAccount Id');
    }
}