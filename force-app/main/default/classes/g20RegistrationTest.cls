@isTest
public with sharing class g20RegistrationTest {

    @TestSetup
    static void setupData(){
        G20_Event__c myEvent = new G20_Event__c(Name = 'test', Start_Date__c= Datetime.now(), End_Date__c = Datetime.now());
        insert myEvent;

        G20_Event_Registration__c registration = new G20_Event_Registration__c(G20_Event__c = myEvent.id);
        insert registration;
    }

    @isTest static void runTest(){
        G20_Event_Registration__c myRegistration = [SELECT ID, Access_Token__c FROM G20_Event_Registration__c LIMIT 1];
        G20_Event__c myEvent = [SELECT ID FROM G20_Event__c LIMIT 1];

        String recId = EncrpytionUtility.decryptRecordId(myRegistration.Access_Token__c);

        List<G20_Event__c> myEvents = g20RegistrationController.getG20Event();

        Map<String, Object> fields = new Map<String, Object>{
            'Name' => 'test', 
            'Date_of_Birth__c' => '1995-05-10', 
            'Departure_Date_Time__c' => '2025-01-15 09:30:00',
            'G20_Event__c' => myEvent.Id
        };
        Id createdRecId = g20GuestRegistrationController.createRecord('G20_Event_Registration__c', fields, false);
        g20GuestRegistrationController.updateRecord(myRegistration.Id, 'G20_Event_Registration__c', fields);
        g20GuestRegistrationController.getAllRegistrations();

        Contact cv = new Contact(FirstName='test', LastName='test2');
        insert cv;

        g20GuestRegistrationController.getRegistrations(cv.Id);
        g20GuestRegistrationController.getRecordByToken(myRegistration.Access_Token__c);

    }

    @istest 
    static void runTestFiles() {

        G20_Event_Registration__c myRegistration = [SELECT ID, Access_Token__c FROM G20_Event_Registration__c LIMIT 1];
        
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
        cv1.Guest_Record_File_Upload__c = myRegistration.Id;
        Insert cv1;
 
        Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
        
        ContentDocumentLink link = new ContentDocumentLink();
        link.ContentDocumentId = conDocument;//Add ContentDocumentId
        link.LinkedEntityId = a.Id;//Add attachment parentId
        link.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
        link.Visibility = 'AllUsers';//AllUsers, InternalUsers, SharedUsers
        insert link;
            
        g20RegistrationController.relinkFile(conDocument, myRegistration.Id);

        List<ContentVersion> cvs = g20GuestRegistrationController.fetchFilesV2(myRegistration.Id);
 
    }
   
}