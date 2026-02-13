@isTest
public class G20SSORegHandlerTest {
    
     @isTest static void runTest()
    {
        string userEmail = 'test.user@gmail.com';
        string empId = '12345';
        string identifier = 'test.user@gmail.com';
        string firstName = 'FirstName';
        string lastName = 'LastName';
       
        Account testAccount = new Account(Name = 'G20 Parent Account');
        insert testAccount;
        Contact testContact = new Contact(FirstName = firstName,LastName = lastName,Email = userEmail,AccountId = testAccount.Id);
        insert testContact;
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'G20 Community Login User' LIMIT 1];
     
       
        Map<string,string> currentuserauthData = new Map<string,string>{
            'email'=> userEmail,
            'emplid' => empId,
            'identifier' => identifier             
        };
        Auth.UserData uData = new Auth.UserData(identifier,firstName,lastName,null,userEmail,null,identifier,null,null,null,currentuserauthData);
        Auth.UserData uDataNoUser = new Auth.UserData('NoEmail@gmail.com',firstName,lastName,null,'NoEmail@gmail.com',null,'NoEmail@gmail.com',null,null,null,currentuserauthData);
        //Auth.UserDate --> UserData:[attributeMap={email=Rahul.Badal@treasury.gov, emplid=991324, sub=Rahul.Badal@treasury.gov}, email=Rahul.Badal@treasury.gov, firstName=null, fullName=null, identifier=Rahul.Badal@treasury.gov, lastName=null, link=null, locale=null, provider=Open ID Connect, siteLoginUrl=null, username=null
        G20SSORegHandler jithandler = new G20SSORegHandler();
        id portalID;
        test.starttest();
        User authorizedUser = jithandler.createUser(portalID,uData);
        jithandler.updateUser(authorizedUser.id,portalID,uData);
        // Negative test
         User unauthorizedUser = jithandler.createUser(portalID,uDataNoUser);
        
        Test.stopTest();
        
    }
    
}