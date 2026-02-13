public with sharing class crmPageLayoutController {    
    
    @Auraenabled(cacheable=true)
    public static Map<String, String> userGroups() { 
        
        system.debug(' START userGroups');
        
        String currentUserId = userInfo.getUserId();
        system.debug(' USER in userGroups: ' + currentUserId);
        
        Map<String, String> result = new Map<String, String>();        
        Map<String, String> allUserGroups = new Map<String, String>();
        //User_Group_View__mdt
		List<User_Group__mdt> listUserGroup = new List<User_Group__mdt>();
        listUserGroup = [SELECT Id, Label, Nickname__c FROM User_Group__mdt]; 
        List<String> allPublicGroups = new List<String>();
        
        system.debug(' All User Group size: ' + listUserGroup.size());

        // Iterate through the User Groups
        if (listUserGroup.size() > 0){
            for (User_Group__mdt rec : listUserGroup ) {                 
                allUserGroups.put(rec.Nickname__c,rec.Label); 
                allPublicGroups.add(rec.Nickname__c);
                system.debug(' User Group Nickname: ' + rec.Nickname__c);                
            }
    	}
        
        // Query to retrieve the Group IDs of public groups the user belongs to
        //List<GroupMember> groupMemberships = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId AND Group.Type = 'Regular'];
        List<GroupMember> groupMemberships = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId  AND GroupMember.Group.Name IN: allPublicGroups];
        
        // List to store the Group IDs
		List<Id> groupIds = new List<Id>();
        system.debug(' All Publis Group that user belong to, size: ' + groupMemberships.size());

        // Iterate through the group memberships to extract the Group IDs
        if (groupMemberships.size() > 0){
            for (GroupMember membership : groupMemberships) {
                groupIds.add(membership.GroupId);
            }
        }

        // Query to retrieve the public groups based on the Group IDs and create the list of public groups that the user belongs to
        List<Group> publicGroups = new List<Group>();
        publicGroups = [SELECT Id, Name FROM Group WHERE Id IN :groupIds];
        system.debug(' My Publis Group size: ' + publicGroups.size());

        if (publicGroups.size() > 0){
            for (Group gr : publicGroups) {
                if (allUserGroups.containsKey(gr.Name)){
                    result.put(gr.Name, allUserGroups.get(gr.Name));
                    system.debug(' Found Result: ' + gr.Name);
                }
            }
        }
        
        return result;
    }    
  
    @Auraenabled(cacheable=true)
    public static Map<String, Map<Boolean, Map<String, String>>> getLayoutFieldsFinal_V5(String objectApiName, String recordId) { 
        
        Map<String, Map<Boolean, Map<String, String>>> layoutFieldsMap = new Map<String, Map<Boolean, Map<String, String>>>();        
        String recordTypeName = '';
        String objApi = objectApiName;
       
        if (objApi == 'Account'){
    		recordTypeName = [Select RecordType.Name From Account Where Id =: recordId].RecordType.Name;
            if (recordTypeName.contains('Person')){
                objApi = 'PersonAccount';
            }
        }
        
        //layoutFieldsMap = getLayoutFieldsNew(objApi);
        layoutFieldsMap = getLayoutFields_V5(objApi, false);
        return layoutFieldsMap;
    } 
    
    @Auraenabled(cacheable=true)
    public static String getAccountRecordType(String recordTypeId) { 
        String recordTypeName = '';
        String objApi = 'Account';
        recordTypeName = Schema.getGlobalDescribe().get(objApi).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
        return recordTypeName;
    }
/*    
    @Auraenabled(cacheable=true)
    public static String getObjectRecordType(String recordTypeId, String objectApiName) { 
        String recordTypeName = '';
        String objApi = objectApiName;
        
        recordTypeName = Schema.getGlobalDescribe().get(objApi).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
        return recordTypeName;
    }
    
    @Auraenabled(cacheable=true)
    public static  Id  getObjectRecordTypeId(String objectApiName) { 
        
        system.debug('getObjectRecordTypeId');
        Id recordTypeId = null;
        String recTypeName; 
        
        Map<String, String> userGroup = new  Map<String, String>();   
        String userGroupNickname;        
        userGroup = userGroups();      
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        List<User_Group_Record_Type__mdt> recTypeUserGroup = new List<User_Group_Record_Type__mdt>();
        recTypeUserGroup = [SELECT Id, Record_Type_Name__c FROM User_Group_Record_Type__mdt WHERE User_Group_Nickname__c =: userGroupNickname AND Object_API__c =: objectApiName LIMIT 1 ]; 
        
        if (recTypeUserGroup.size() > 0) recTypeName = recTypeUserGroup[0].Record_Type_Name__c;
        system.debug(' recTypeName  ' + recTypeName);

        if (recTypeName != null) recordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType =: objectApiName AND Name =: recTypeName LIMIT 1 ].Id;
        system.debug('recordTypeId ' + recordTypeId); 
        
        return recordTypeId;
    }
 */   
        
    @Auraenabled(cacheable=false)
    public static  Id  getDefaultMasterRecordId(String objectApiName) { 
        
        system.debug('getDefaultMasterRecordId, Object API Name IS ' + objectApiName);
        
        Id recordTypeId = null;
        Id defaultMasterRecordId = null;
        String recTypeName; 
        
        Map<String, String> userGroup = new  Map<String, String>();   
        String userGroupNickname;        
        userGroup = userGroups();      
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        List<User_Group_Record_Type__mdt> recTypeUserGroup = new List<User_Group_Record_Type__mdt>();
        recTypeUserGroup = [SELECT Id, Record_Type_Name__c FROM User_Group_Record_Type__mdt WHERE User_Group_Nickname__c =: userGroupNickname AND Object_API__c =: objectApiName LIMIT 1 ]; 
        
        if (recTypeUserGroup.size() > 0) recTypeName = recTypeUserGroup[0].Record_Type_Name__c;
        system.debug('getDefaultMasterRecordId, recTypeName  ' + recTypeName);

        if (recTypeName != null) recordTypeId = [ SELECT Id FROM RecordType WHERE SObjectType =: objectApiName AND Name =: recTypeName LIMIT 1 ].Id;
        system.debug('getDefaultMasterRecordId, recordTypeId ============= ' + recordTypeId); 
        
        if (recordTypeId != null) {
            SObjectType sObjectType = Schema.getGlobalDescribe().get(objectApiName);
            system.debug('getDefaultMasterRecordId, sObjectType =============== ' + sObjectType);
            if (sObjectType == null) throw new IllegalArgumentException('Invalid Object API Name: ' + objectApiName);
            
            // Find the default master record 
            String query = 'SELECT Id, Default_Master_Record__c FROM ' + sObjectType + ' WHERE Default_Master_Record__c = true AND RecordTypeId = \'' + recordTypeId + '\'';
            
            List<SObject> recDefMaster = Database.query(query);
            defaultMasterRecordId = recDefMaster[0].Id;
            system.debug('getDefaultMasterRecordId, recordTypeId ============= ' + defaultMasterRecordId);
        }        

        return defaultMasterRecordId;
    }
     
    @Auraenabled(cacheable=true)
    public static Map<String, Map<Boolean, Map<String, String>>> getLayoutFieldsAccount_V5(String recordTypeId) { 
        
        Map<String, Map<Boolean, Map<String, String>>> layoutFieldsMap = new Map<String, Map<Boolean, Map<String, String>>>();        
        String recordTypeName = '';
        String objApi = 'Account';

        recordTypeName = Schema.getGlobalDescribe().get(objApi).getDescribe().getRecordTypeInfosById().get(recordTypeId).getName();
        if (recordTypeName.contains('Person')){
                objApi = 'PersonAccount';
        }
        system.debug('Object API layoutName IS ' + objApi);
        
        layoutFieldsMap = getLayoutFields_V5(objApi, true);
        return layoutFieldsMap;
    }     
    
    @Auraenabled(cacheable=true)
    public static Map<String, Map<Boolean, Map<String, String>>> getLayoutFields_V5(String objectApiName, boolean isNewRec) { 
        
        system.debug('Object API NAME IS ' + objectApiName);
        
        //limit the query to the object api name as in lwc
        List<Layout_Assignment__C> assignments = [Select Id, Layout_Manager__r.Name FROM Layout_Assignment__C WHERE user__c =: userInfo.getUserId()  AND Active__c =: true ];
        
        List<String> layoutNames = new List<String>();
        List<String> layoutFields = new List<String>();
        
        Map<String, Map<Boolean, Map<String, String>>> layoutFieldsMap = new Map<String, Map<Boolean, Map<String, String>>>();
        
        Map<String, String> userGroup = new  Map<String, String>();   
        String userGroupNickname;        
        userGroup = userGroups();      
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        boolean isDefault = true;
        
        if (assignments.size() > 0){
            for(Layout_Assignment__C la : assignments){
                
                String lmName = la.Layout_Manager__r.Name;
                List<String> subNames = lmName.split('-');
                
                if (subNames[0] == objectApiName){
                    layoutNames.add(la.Layout_Manager__r.Name);
                    system.debug('Layout_Manager__r.Name IS ' + la.Layout_Manager__r.Name);
                }
            }
        }
        
        if (layoutNames.size() > 0){
            isDefault = false;
        }
        
        //if use a defaul layout:
        //list<Metadata.Metadata > pageLayouts = Metadata.Operations.retrieve(
    	//	Metadata.MetadataType.Layout, new list<String>{'Case-Case Layout'}
		//);
        //if layoutnames.size == 0, requery for layout managet where the default = true
        //make sure queries are limited though sharing rules to the account or "user group" 
        List<Metadata.Metadata > pageLayouts = new List<Metadata.Metadata >();
        
        if(isDefault){
            
            String layoutNameUG = null;
            String layoutNameObj = null;
            String objectApiNameModified = objectApiName;
            if(objectApiName.contains('__c')){
                objectApiNameModified = objectApiName.removeEndIgnoreCase('__c');
                objectApiNameModified = objectApiNameModified.replaceAll('_', ' ');
            }
            
            if (userGroupNickname != null){            
                layoutNameUG = objectApiName + '-' + userGroupNickname + '_Layout'; 
                system.debug('layoutNameUG IS ' + layoutNameUG);
            } 
                    
            //String layoutName = objectApiName + '-' + objectApiName + ' Layout';
            layoutNameObj = objectApiName + '-' + objectApiNameModified + ' Layout';
            system.debug('Object API layoutName IS ' + layoutNameObj);        
            
            pageLayouts = Metadata.Operations.retrieve(        
                Metadata.MetadataType.Layout, new List<String>{layoutNameUG}                 
            );
            system.debug('Group layoutNameUG pageLayouts IS ' + pageLayouts.size());
                
            if (pageLayouts.size() == 0)
            {
                pageLayouts = Metadata.Operations.retrieve(        
                    Metadata.MetadataType.Layout, new List<String>{layoutNameObj}                     
                    //Metadata.MetadataType.Layout, layoutNames            
                );
                system.debug('Group layoutNameObj pageLayouts IS ' + pageLayouts.size());
            }
            
            system.debug('Object Final pageLayouts IS ' + pageLayouts.size());
            
        } else {
            
            pageLayouts = Metadata.Operations.retrieve(        
                //Metadata.MetadataType.Layout, new list<String>{'Account-Rita_Account'}
                Metadata.MetadataType.Layout, layoutNames            
            );
            system.debug('Object Custom pageLayouts IS ' + pageLayouts.size());
        }
         
        //additional logic can be added to these loops to help structure lwc sections and columns
        integer ind = 0;
        integer totalColumns = 0;
        if(pageLayouts.size() > 0){
            for( Metadata.Metadata objPageLayout :pageLayouts ){
            
                Metadata.Layout layout = (Metadata.Layout)objPageLayout;
            
                for(Metadata.LayoutSection section :layout.layoutSections){
                    
                    system.debug('SECTION NAME IS ' + section.label);
                    
                    Map<String, String> tempFieldsClm1 = new Map<String, String>();
                    Map<String, String> tempFieldsClm2 = new Map<String, String>();
                    
                    if ((ind != 0) && (totalColumns == 0)) totalColumns = ind;
                    ind = 0;
                    
                    if (section.label != 'Custom Links'){
                        
                        //List<String> tempFields = new List<String>();
                        for(Metadata.LayoutColumn column :section.layoutColumns){
                            
                            ind++;
                            system.debug('COLUMN NUMBER IS ' + ind);
                            system.debug('COLUMN info IS ' + column);
                            
                            if(column.layoutItems != null){            				
                                
                                for(Metadata.LayoutItem item :column.layoutItems){
                                    
                                    //add conditional logic for standard lookup fields to remove "Id" from the list of fields
                                    system.debug('FIELD API NAME IS ' + item.field);                                    
                                    layoutFields.add(item.field);
                                    
                                    String strBehavior = item.behavior.name();
                                    system.debug('FIELD API behavior ' + strBehavior);
                                    
                                    
                                    //tempFields.add(item.field);
                                    if ((objectApiName == 'PersonAccount') && (item.field == 'Name') && (isNewRec)){
                                        if (ind == 1) {
                                           // tempFieldsClm1.add('Salutation');
                                            tempFieldsClm1.put('FirstName', strBehavior);
                                            tempFieldsClm1.put('MiddleName', strBehavior);
                                            tempFieldsClm1.put('LastName', strBehavior);
                                            tempFieldsClm1.put('Suffix', strBehavior);
                                        } else if (ind == 2){
                                           // tempFieldsClm2.add('Salutation', item.field);
                                            tempFieldsClm2.put('FirstName', strBehavior);
                                            tempFieldsClm2.put('MiddleName', strBehavior);
                                            tempFieldsClm2.put('LastName', strBehavior);
                                            tempFieldsClm2.put('Suffix', strBehavior);
                                        }                                        
                                    } else {                                    
                                        if (ind == 1) {
                                            tempFieldsClm1.put(item.field, strBehavior);
                                        } else if (ind == 2){
                                            tempFieldsClm2.put(item.field, strBehavior);
                                        }
                                    } 
                                    
                                }        
                            } 
                            
                            Map<Boolean, Map<String, String>> tempMapClmAll = new Map<Boolean, Map<String, String>>();
                            tempMapClmAll.put(true, tempFieldsClm1);
                            tempMapClmAll.put(false, tempFieldsClm2);
                            
                            layoutFieldsMap.put(section.label, tempMapClmAll);                        
                            //Map<String, Map<Boolean, String>> = Map<Section, Map<IsFirstColumn, Field API Name>>
                            
                        }                                         
                    }
                }
                system.debug('TOTAL COLUMNS ' + totalColumns);
            }
        }
        
        return layoutFieldsMap;
    }    
 
 
    /*
     

   // @Auraenabled(cacheable=true)
   // @InvocableMethod(label='Layout Fields' description='Layout Fields')
    
 */   
}