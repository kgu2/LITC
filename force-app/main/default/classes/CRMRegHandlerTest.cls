@isTest
private class CRMRegHandlerTest {

    @isTest static void runTest()
    {
        string userEmail = 'test.user@treasury.gov';
        string empId = '12345';
        string identifier = 'test.user@treasury.gov';
        string identifier2 = 'test.user2@treasury.gov';
        string firstName = 'FirstName';
        string lastName = 'LastName';
        
        Profile userProfile = [SELECT Id FROM Profile WHERE Name='Standard User'];
        User U = new user(FirstName = firstName,
                          lastName= lastName,
                          Email=userEmail,
                          FederationIdentifier=identifier,
                          Username=userEmail,
                          Alias='test',
                          ProfileId = userProfile.Id,
                          TimeZoneSidKey = 'America/New_York',
                          LocaleSidKey = 'en_US',
                          EmailEncodingKey = 'UTF-8',
                          LanguageLocaleKey = 'en_US');
        insert U;
        Map<string,string> currentuserauthData = new Map<string,string>{
            'email'=> userEmail,
            'emplid' => empId,
            'identifier' => identifier             
        };
        Map<string,string> newuserauthData = new Map<string,string>{
            'email'=> userEmail,
            'emplid' => empId,
            'identifier' => identifier2             
        };
        Auth.UserData uData = new Auth.UserData(identifier,firstName,lastName,null,userEmail,null,identifier,null,null,null,currentuserauthData);
        
        
            //Auth.UserDate --> UserData:[attributeMap={email=Rahul.Badal@treasury.gov, emplid=991324, sub=Rahul.Badal@treasury.gov}, email=Rahul.Badal@treasury.gov, firstName=null, fullName=null, identifier=Rahul.Badal@treasury.gov, lastName=null, link=null, locale=null, provider=Open ID Connect, siteLoginUrl=null, username=null
        CRMRegHandler jithandler = new CRMRegHandler();
        id portalID;
        test.starttest();
        User authorizedUser = jithandler.createUser(portalID,uData);
        
        jithandler.updateUser(authorizedUser.Id,portalID,uData);
        udata.attributeMap = newuserauthData;
        udata.identifier = identifier2;
        
        try{
             User newUser = jithandler.createUser(portalID,uData);
        }
        catch(exception ex)
        {
           Assert.areEqual(ex.getmessage(),'User with Id - ' + identifier2 + ' not found');
        }
        Test.stopTest();
        
    }
}