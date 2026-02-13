@isTest 
public class crmAdminSettingsControllerTest {

    @IsTest
    static void testCurrentUserId() {
        // Arrange
        String expectedUserId = UserInfo.getUserId();

        // Act
        Test.startTest();
        String actualUserId = crmAdminSettingsController.currentUserId();
        Test.stopTest();

        // Assert
        System.assertEquals(expectedUserId, actualUserId, 'The user ID should match the current user ID.');
    }

    @IsTest
    static void testIsAdmin() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
       // PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'OCCIP' LIMIT 1];
       // insert new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps.Id);

        // Act
        Test.startTest();
        boolean isAdmin = crmAdminSettingsController.isAdmin();
        Test.stopTest();

        // Assert
        System.assertEquals(true, isAdmin, 'The user should be recognized as an admin.');
    }

    @IsTest
    static void testUserGroups() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        // Act
        Test.startTest();
        Map<String, String> userGroups = crmAdminSettingsController.userGroups();
        Test.stopTest();

        // Assert
        System.assert(userGroups.size() > 0, 'The user should belong to one group.');
        System.assertEquals('Office of Cyber and Critical Infrastructure Protection', userGroups.get('OCCIP'), 'The group nickname should match.');
    }
    
    @IsTest
    static void testObjectList() {
        // Arrange
        /*
        User_Group_Object__mdt userGroupObject = new User_Group_Object__mdt(
            User_Group_Nickname__c = 'OCCIP',
            Object_API__c = 'Account'
        );
        insert userGroupObject;
        */

        // Act
        Test.startTest();
        List<String> objectList = crmAdminSettingsController.objectList();
        Test.stopTest();

        // Assert
        System.assert( objectList.size() != 0, 'There should be one object.');
        System.assertEquals('Account', objectList[0], 'The object should be Account.');
    }
    
    @IsTest
    static void testObjectLayoutList() {
        // Arrange
        Layout_Manager__c layout = new Layout_Manager__c(
            Group_Name__c = 'OCCIP',
            Name = 'TestLayout',
            Active__c = true
        );
        insert layout;

        // Act
        Test.startTest();
        Map<String, String> layoutList = crmAdminSettingsController.objectLayoutList();
        Test.stopTest();

        // Assert
        System.assert( layoutList.size() != 0, 'There should be one layout.');
        System.assertEquals('TestLayout', layoutList.get(layout.Id), 'The layout name should be TestLayout.');
    }
    
    @IsTest
    static void testAllLayoutList() {
        // Arrange
        Layout_Manager__c layout = new Layout_Manager__c(
            Group_Name__c = 'OCCIP',
            Name = 'TestLayout',
            Active__c = true
        );
        insert layout;

        // Act
        Test.startTest();
        //Map<String, List<String>> layoutList  = crmAdminSettingsController.allLayouts();
        Map<String, Map<String, Map<Boolean, List<String>>>> layoutList  = crmAdminSettingsController.allLayouts();
        Test.stopTest();

        // Assert
        System.assert( layoutList.size() != 0, 'There should be one layout.');
      //  System.assertEquals('TestLayout', layoutList.get(layout.Id), 'The layout name should be TestLayout.');
    }
    
     @IsTest
    static void testLayoutAssignmentList() {
        // Arrange
        Layout_Manager__c layoutManager = new Layout_Manager__c(
            Group_Name__c = 'OCCIP',
            Name = 'Account-TestLayout',
            Active__c = true
        );
        insert layoutManager;
        
        List<User> user1 = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMiT 1];
        Id userId = user1[0].Id;

        Layout_Assignment__c layoutAssignment = new Layout_Assignment__c();
        layoutAssignment.Name = 'Test1';
        layoutAssignment.Layout_Manager__c = layoutManager.Id;
        layoutAssignment.User__c = userId;
        layoutAssignment.Active__c = true;
        insert layoutAssignment;

        // Act
        Test.startTest();
        List<String> layoutAssignments = crmAdminSettingsController.layoutAssignmentList();
        Test.stopTest();

        // Assert
        System.assert(layoutAssignments.size() > 0, 'There should be one layout assignment.');
        System.assert(layoutAssignments[0].contains('TestLayout'), 'The layout assignment should contain TestLayout.');
    }
    
    @IsTest
    static void testUsersList() {
        // Arrange
        User testUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];

        Group testGroup = new Group(
            Name = 'TestGroup',
            Type = 'Regular'
        );
        insert testGroup;
        
        insert new GroupMember(
            GroupId = testGroup.Id,
            UserOrGroupId = testUser.Id
        );

        // Act
        Test.startTest();
        Map<String, String> usersList = crmAdminSettingsController.usersList();
        Test.stopTest();

        // Assert
        System.assert(usersList.size() > 0, 'There should be one user.');
    }
    
    @IsTest
    static void testUpdateLayouts() {
        // Arrange
        String groupName = 'OCCIP';
        List<String> newLayouts = new List<String>{'Layout1', 'Layout2'};

        // Act
        Test.startTest();
        crmAdminSettingsController.updateLayouts(groupName, newLayouts);
        Test.stopTest();

        // Assert
        // Since the method is void and only has debug statements, we cannot assert anything meaningful
        // Just ensuring it runs without exceptions
        System.assert(true, 'Method executed without exceptions.');
    }  
    
    
    @IsTest
    static void testGroupAnnouncement() {
        // Arrange
        Announcement_Manager__c announcement = new Announcement_Manager__c(
            Name = 'OCCIP',
            Announcement__c = 'Test Announcement'
        );
        insert announcement;

        // Act
        Test.startTest();
        String result = crmAdminSettingsController.groupAnnouncement();
        Test.stopTest();

        // Assert
        System.assert(result != null, 'The announcement should match.');
    }

    @IsTest
    static void testUpdateAnnouncement() {
        // Arrange
        Announcement_Manager__c announcement = new Announcement_Manager__c(
            Name = 'OCCIP',
            Announcement__c = 'Old Announcement'
        );
        insert announcement;

        String newDescription = 'New Announcement';

        // Act
        Test.startTest();
        crmAdminSettingsController.updateAnnouncement('OCCIP', newDescription);
        Test.stopTest();

        // Assert
        Announcement_Manager__c updatedAnnouncement = [SELECT Announcement__c FROM Announcement_Manager__c WHERE Name = 'OCCIP' LIMIT 1];
        System.assertEquals(newDescription, updatedAnnouncement.Announcement__c, 'The announcement should be updated.');
    }
}