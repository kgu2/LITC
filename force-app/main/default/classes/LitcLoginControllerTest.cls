@isTest
public class LitcLoginControllerTest {
    @testSetup
    static void setupTestData() {
        
          Profile userProfile1 = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // // Retrieve a valid UserRole for the Account Owner
        // UserRole userRole1 = [SELECT Id FROM UserRole LIMIT 1];
        
        // Create a Standard User with a role (Account Owner)
        User accountOwner1 = new User(
            FirstName = 'Standard',
            LastName = 'Owner',
            Email = 'standardowner@example.com',
            Username = 'standardowner@example.com.litc',
            Alias = 'stown',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US',
            ProfileId = userProfile1.Id
        );
        insert accountOwner1;
                // Create a Test Account owned by the Standard User
        Contact testContact; 
        Contact testContact1;
        System.runAs(accountOwner1) {
            Account testAccount = new Account(Name = 'Test Account', OwnerId = accountOwner1.Id);
            insert testAccount;
            
            // Create a Test Contact associated with the Account
            testContact = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testuser@example.com',
                AccountId = testAccount.Id,
                Unverified__c = true,
                On_boarding_Expiration_Date__c = Date.today().addDays(10)
            );
            insert testContact;
            
                testContact1 = new Contact(
                FirstName = 'Test',
                LastName = 'User',
                Email = 'testuser1@example.com',
                AccountId = testAccount.Id,
                Unverified__c = true,
                On_boarding_Expiration_Date__c = Date.today().addDays(10)
            );
            insert testContact1;
        }
        
        
        // Retrieve the profile for the community user
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        
        // Retrieve a valid UserRole for the Account Owner
        // UserRole userRole = [SELECT Id FROM UserRole LIMIT 1];
        
        // Create a Standard User with a role (Account Owner)
        // User accountOwner = new User(
        //     FirstName = 'Standard',
        //     LastName = 'Owner',
        //     Email = 'standardowner1@example.com',
        //     Username = 'standardowner1@example.com.litc',
        //     Alias = 'stown',
        //     TimeZoneSidKey = 'America/New_York',
        //     LocaleSidKey = 'en_US',
        //     EmailEncodingKey = 'ISO-8859-1',
        //     LanguageLocaleKey = 'en_US',
        //     ProfileId = userProfile.Id,
        //     ContactId = testContact.id
        // );
        // insert accountOwner;
        

    }
    
    @isTest
    static void testGetUnverified() {
        User accountOwner = [SELECT Id FROM User WHERE Email = 'standardowner@example.com' LIMIT 1];
        System.runAs(accountOwner) {
            Test.startTest();
            Boolean isUnverified = LitcLoginController.getUnverified();
            Test.stopTest();
            //System.assertEquals(true, isUnverified, 'Unverified flag should be true');
        }
    }
    
    @isTest
    static void testCreateRecord() {
        User accountOwner = [SELECT Id FROM User WHERE Email = 'standardowner@example.com' LIMIT 1];
        System.runAs(accountOwner) {
            Test.startTest();
            Map<String, Object> fields = new Map<String, Object>();
            fields.put('FirstName', 'New');
            fields.put('LastName', 'Contact');
            fields.put('Email', 'newcontact@example.com');
            Id contactId = LitcLoginController.createRecord('Contact', fields);
            Test.stopTest();
            System.assertNotEquals(null, contactId, 'Contact should be created successfully');
        }
    }
    
    @isTest
    static void testDeleteRecord() {
        User accountOwner = [SELECT Id FROM User WHERE Email = 'standardowner@example.com' LIMIT 1];
        System.runAs(accountOwner) {
            Contact testContact = [SELECT Id FROM Contact where Email = 'testuser1@example.com' LIMIT 1];
            Test.startTest();
            LitcLoginController.deleteRecord('Contact', testContact.Id);
            Test.stopTest();
            System.assertEquals(0, [SELECT COUNT() FROM Contact WHERE Id = :testContact.Id], 'Contact should be deleted');
        }
    }
    
    @isTest
    static void testupdateRecord() {
        User accountOwner = [SELECT Id FROM User WHERE Email = 'standardowner@example.com' LIMIT 1];
        System.runAs(accountOwner) {
            Contact testContact = [SELECT Id FROM Contact where Email = 'testuser1@example.com' LIMIT 1];
            
            Map<String, Object> fieldsToUpdate = new Map<String, Object>{
                'LastName' => 'Updated User',
                    'Email' => 'updateduser@example.com'
                    };
                        
            Test.startTest();
            LitcLoginController.updateRecord( testContact.Id,'Contact',fieldsToUpdate);
            Test.stopTest();
        }
    }    
    
    @isTest
    static void testMisc() {
        User accountOwner = [SELECT Id FROM User WHERE Email = 'standardowner@example.com' LIMIT 1];
        Account testaccount = [SELECT Id FROM Account LIMIT 1];
        Account testAccount1 = new Account(Name = 'Test Account', OwnerId = accountOwner.Id,ParentId = testaccount.id );
        insert testAccount1;        
        Contact testContact = [SELECT Id FROM Contact where Email = 'testuser1@example.com' LIMIT 1];
        Test.startTest();
        LitcLoginController.getMyAccount(testaccount.Id);
        LitcLoginController.getMyRole();
        LitcLoginController.getRelatedContacts(testaccount.Id);
        LitcLoginController.getAllRelatedContacts(testContact.id);
        LitcLoginController.updateOnboardingExpirationDate(testContact.id,date.today());
        LitcLoginController.getChildAccounts(testAccount1.id);
        Test.stopTest();
    } 
    
    
}