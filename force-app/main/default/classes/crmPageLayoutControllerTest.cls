@isTest 
public class crmPageLayoutControllerTest { 
    
    @testSetup
    static void setupTestData() {
        
        
        // Create Groups and Group Members
        Group publicGroup = new Group(
            Name = 'TG1',
            Type = 'Regular'
        );
        insert publicGroup;

        GroupMember groupMember = new GroupMember(
            GroupId = publicGroup.Id,
            UserOrGroupId = UserInfo.getUserId()
        );
        insert groupMember;
        
    }
    
    @isTest
    static void testUserGroups() {
        Test.startTest();
        Map<String, String> userGroups = crmPageLayoutController.userGroups();
        Test.stopTest();

        System.assertNotEquals(null, userGroups, 'Expected at least one user group');
   }
    
    @isTest
    static void testGetDefaultMasterRecordId() {
        
        // Create test data
        Case cs = new Case();
        cs.Status = 'New';
        cs.Default_Master_Record__c = true;
        insert cs;
        
        Test.startTest();
        Id defaultMasterRecordId = crmPageLayoutController.getDefaultMasterRecordId('Case');
        Test.stopTest();

        System.assertNotEquals(null, defaultMasterRecordId, 'Expected a default master record ID');
    }
    
    @isTest
    static void testGetLayoutFieldsFinal_V5() {
        
        Account a = new Account( Name = 'Test Account');
        insert a;
        
        Account acc = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        Map<String, Map<Boolean, Map<String, String>>> layoutFieldsMap = crmPageLayoutController.getLayoutFieldsFinal_V5('Account', acc.Id);
        Test.stopTest();

        System.assertNotEquals(null, layoutFieldsMap, 'Expected a non-null layout fields map');
    }
    
    @isTest 
    static void testGetLayoutFields1() { 
        
        // Create test data
        Account a = new Account();
        a.Name = 'Test';
        insert a;
        
        // Create a Layout_Manager__c record with a Name that matches the expected format
		Layout_Manager__c layoutManager = new Layout_Manager__c(Name = 'Account-Account Layout');
		insert layoutManager;
        
        // Create a Layout_Assignment__c record and associate it with the created Layout_Manager__c record
        List<Layout_Assignment__c> assignments = new List<Layout_Assignment__c>();
        assignments.add(new Layout_Assignment__c(User__c = UserInfo.getUserId(), Layout_Manager__c = layoutManager.Id));
        insert assignments;
        
        // Call the getLayoutFieldsNew method with a valid objectApiName 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFields_V5('Account', false); 
        Test.stopTest(); 
        
        // Verify the result 
	     //  System.assertEquals(3, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
     }
    
    @isTest 
    static void testGetLayoutFieldsUpdated() { 
        
        // Create test data
        Account a = new Account();
        a.Name = 'Test';
        insert a;
        
        // Create a Layout_Manager__c record with a Name that matches the expected format
		Layout_Manager__c layoutManager = new Layout_Manager__c(Name = 'Account-Account Layout');
		insert layoutManager;
        
        // Create a Layout_Assignment__c record and associate it with the created Layout_Manager__c record
        List<Layout_Assignment__c> assignments = new List<Layout_Assignment__c>();
        assignments.add(new Layout_Assignment__c(User__c = UserInfo.getUserId(), Layout_Manager__c = layoutManager.Id));
        insert assignments;
        
        // Call the getLayoutFieldsNew method with a valid objectApiName 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFields_V5('Account', true); 
        Test.stopTest(); 
        
        // Verify the result 
	     //  System.assertEquals(3, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
     }
    
    @isTest 
    static void testGetLayoutFieldsUpdated2() { 
        
        // Create test data
        Account a = new Account();
        a.Name = 'Test';
        insert a;
        
        // Create a Layout_Manager__c record with a Name that matches the expected format
		Layout_Manager__c layoutManager = new Layout_Manager__c(Name = 'Account-Account Layout');
		insert layoutManager;
        
        // Create a Layout_Assignment__c record and associate it with the created Layout_Manager__c record
        List<Layout_Assignment__c> assignments = new List<Layout_Assignment__c>();
        assignments.add(new Layout_Assignment__c(User__c = UserInfo.getUserId(), Layout_Manager__c = layoutManager.Id));
        insert assignments;
        
        // Call the getLayoutFieldsNew method with a valid objectApiName 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFields_V5('Account', false); 
        Test.stopTest(); 
        
        // Verify the result 
	     //  System.assertEquals(3, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
     }
    
    @isTest 
    static void testGetLayoutFields2() { 
        
        // Create test data
        Account acc = new Account();
        acc.Name = 'Test Account New';
        insert acc;
              
        // Call the getLayoutFieldsNew method with a valid objectApiName, use default layout 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFields_V5('Account', false); 
        Test.stopTest(); 
        
        // Verify the result 
        //System.assertEquals(2, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
      
     }
 /*   
    @isTest 
    static void testGetLayoutFields3() { 
        
        // Create test data
        Account acc = new Account();
        acc.Name = 'Test Person Account New';
        insert acc;
              
        // Call the getLayoutFieldsNew method with a valid objectApiName, use default layout 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFields_V5('PersonAccount', false); 
        Test.stopTest(); 
        
        // Verify the result 
        //System.assertEquals(2, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
      
     }
*/
    
    @isTest 
    static void testGetLayoutFieldsFinal() { 
        
        // Create test data
        Account acc = new Account();
        acc.Name = 'Test Account';
        insert acc;
              
        // Call the getLayoutFieldsNew method with a valid objectApiName, use default layout 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFieldsFinal_V5('Account', acc.Id); 
        Test.stopTest(); 
        
        // Verify the result 
        //System.assertEquals(2, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
      
     }
    
    @isTest 
    static void testGetLayoutFieldsAccount() { 
        
        // Create test data
        List<RecordType> recType = [Select Id From RecordType Where SObjectType = 'Account'];
        Account acc = new Account();
        acc.Name = 'Test Another Account';
        acc.RecordTypeId = recType[0].Id;
        insert acc;
              
        // Call the getLayoutFieldsNew method with a valid objectApiName, use default layout 
        Test.startTest(); 
        Map<String, Map<Boolean, Map<String, String>>> result = crmPageLayoutController.getLayoutFieldsAccount_V5(recType[0].Id); 
        Test.stopTest(); 
        
        // Verify the result 
        //System.assertEquals(2, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
      
     }    
    
    
    /*
    @isTest static void testGetLayoutFields3() { 
        
        // Create test data
        Test_Object__c tb = new Test_Object__c();
        tb.Name = 'Test 3';
        insert tb;
              
        // Call the getLayoutFieldsNew method with a valid objectApiName, use default layout 
        Test.startTest(); 
        List<String> result = crmPageLayoutController.getLayoutFields('Test_Object__c'); 
        Test.stopTest(); 
        
        // Verify the result 
        //System.assertEquals(2, result.size());
        System.assertNotEquals(null, result, 'Result should not be null');
      
     }
*/
         
}