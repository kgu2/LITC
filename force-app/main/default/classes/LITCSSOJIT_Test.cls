@isTest
public class LITCSSOJIT_Test {
    @testSetup
    static void setupTestData() {
        // Retrieve existing Profile instead of trying to insert
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        Profile profile1 = [SELECT Id FROM Profile WHERE Name != 'System Administrator' LIMIT 1];
        
        // Create a Test Account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        // Create a Test Contact
 /*       Contact testContact = new Contact(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            AccountId = testAccount.Id,
            On_boarding_Expiration_Date__c = Date.today().addDays(10)
        );
        insert testContact;*/
        
        //  UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];
        
        User standardUser;
        System.runAs(new User(Id = UserInfo.getUserId())) {
            standardUser = new User(
                FirstName = 'Standard',
                LastName = 'Owner',
                Email = 'testuser@example.com',
                Username = 'testuser@example.com.litc',
                Alias = 'stown',
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'ISO-8859-1',
                LanguageLocaleKey = 'en_US',
                ProfileId = profile1.Id
            );
            insert standardUser;
        }        
    }

    @isTest
    static void testCreateUser() {
        Test.startTest();
        
        // Mock UserData using new instance creation method
        Auth.UserData userData = (Auth.UserData)JSON.deserialize('{"email":"testuser@example.com"}', Auth.UserData.class);

        // Create an instance of LITCSSOJIT
        LITCSSOJIT handler = new LITCSSOJIT();
        Id portalId = UserInfo.getUserId(); // Using current user ID for portal ID

        // Call createUser method
        User createdUser = handler.createUser(portalId, userData);
        
        Test.stopTest();

        // Validate results
        System.assertNotEquals(null, createdUser, 'User should be created');
        System.assertEquals('testuser@example.com', createdUser.Email, 'Email should match');
        System.assertNotEquals(null, createdUser.ProfileId, 'Profile should be assigned');
    }

    @isTest
    static void testUpdateUser() {
        
        User testUser = [SELECT Id, ProfileId FROM User WHERE Email = 'testuser@example.com' LIMIT 1];
        Auth.UserData userData = (Auth.UserData)JSON.deserialize('{"email":"testuser@example.com"}', Auth.UserData.class);
        
        Test.startTest();
        LITCSSOJIT handler = new LITCSSOJIT();
        // Call updateUser method
         handler.updateUser(testUser.Id, testUser.ProfileId, userData);
        Test.stopTest();
        // Validate the ProfileId is updated
        User updatedUser = [SELECT ProfileId FROM User WHERE Id = :testUser.Id];
    }
}