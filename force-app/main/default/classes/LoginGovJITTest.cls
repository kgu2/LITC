@isTest
private class LoginGovJITTest {
    
     @isTest static void runTest()
     {
       Profile p = [SELECT Id FROM Profile WHERE Name = 'Cares Act Community Login'];
        Id samlSsoProviderId;
        Id communityId;
        Id portalId;
                
        Account a = new Account(Name = 'Test Account');
        insert a;
        Contact c = new Contact(AccountId = a.Id, LastName = 'TEST', Email = 'sso1.test@treasury.gov');
        insert c;
        Contact badc = new Contact(AccountId = a.Id, LastName = 'TEST2');
        insert badc;
         
         
         
        string email = 'sso1.test@treasury.gov';
        string userName = email + '.comport';
         string assertion = 'test';
           Map<String, String> attribs = new Map<String, String> {
            'email' => email,
            'username' => '314db45e-01a2-4575-964b-92137df88b06'
        };
            
       Map<String, String> missingattribs = new Map<String, String> {
            'email' => 'sso2.test@treasury.gov',
            'username' => '314db45e-01a2-4575-964b-92137df88b06'
        };
        LoginGovJIT handler = new LoginGovJIT();
         Test.startTest();
         user U = new User();
         U = handler.createUser(samlSsoProviderId,communityId,communityId,email,attribs,assertion);
         handler.updateUser(U.id,samlSsoProviderId,communityId,communityId,email,attribs,assertion);
         // Bad create JIT exception
         try{
             user U2 = new User();
         U2 = handler.createUser(samlSsoProviderId,communityId,communityId,'sso3.test@treasury.gov',missingattribs,assertion);
         }
         catch(exception e)
         {
             
         }
         
         Test.stopTest();   

     }

}