public with sharing class crmAdminSettingsController {
    
   
    @Auraenabled(cacheable=true)
    public static String currentUserId() {         
        return System.userInfo.getUserId();
    }       
        
    
    @Auraenabled(cacheable=true)
    public static boolean isAdmin() { 
        
        system.debug(' START crmAdminSettingsController');        
        boolean result = false;
        
        //get user ID
        String currentUserId = userInfo.getUserId();
        system.debug(' USER: ' + currentUserId);
        
        List<PermissionSetAssignment> permissionSetAssignments = [ SELECT PermissionSet.Name FROM PermissionSetAssignment WHERE AssigneeId = :currentUserId ];

        // Iterate through the permission set assignments
        for (PermissionSetAssignment assignment : permissionSetAssignments) {
            String permissionSetName = assignment.PermissionSet.Name;
            
            if (permissionSetName.contains('Admin') || permissionSetName.contains('T_128_09_43_34_1')){
                result = true;
            }
           // String permissionSetNamespacePrefix = assignment.PermissionSet.NamespacePrefix;
            // Process the permission set name as needed //005BZ000001VWcYYAW//User_Group_Administrator
            system.debug(' permissionSetName: ' + permissionSetName);            
        }
        
        return result;
    }
        
    @Auraenabled(cacheable=true)
    public static Map<String, String> userGroups() { 
        
        system.debug(' START userGroups');
        
        String currentUserId = userInfo.getUserId();
        system.debug(' USER in userGroups: ' + currentUserId);
        
        Map<String, String> result = new Map<String, String>();
        
        Map<String, String> allUserGroups = new Map<String, String>();
        //User_Group_View__mdt
		List<User_Group__mdt> listUserGroup = new List<User_Group__mdt>();
        listUserGroup = [SELECT Id, Group_Name__c, Nickname__c FROM User_Group__mdt]; 
        List<String> allPublicGroups = new List<String>();
        
        system.debug(' All User Group size: ' + listUserGroup.size());

        // Iterate through the User Groups
        if (listUserGroup.size() > 0){
            for (User_Group__mdt rec : listUserGroup ) {                 
                allUserGroups.put(rec.Nickname__c,rec.Group_Name__c); 
                allPublicGroups.add(rec.Nickname__c);
                system.debug(' User Group Nickname: ' + rec.Nickname__c);                
            }
    	}
        
        // Query to retrieve the Group IDs of public groups the user belongs to
        //List<GroupMember> groupMemberships = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId AND Group.Type = 'Regular'];
        List<GroupMember> groupMemberships = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId AND GroupMember.Group.Name IN: allPublicGroups];
        
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
    public static List<String> objectList() { 
        
        system.debug(' START objectList');
        
        Map<String, String> userGroup = new  Map<String, String>();        
        List<User_Group_Object__mdt> userGroupObjects = new List<User_Group_Object__mdt>();
        List<String> listObjects = new List<String>();            
        
        String userGroupNickname;        
        userGroup = userGroups();       
        
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        if (userGroupNickname != null){
            userGroupObjects = [SELECT Id, Object_API__c FROM User_Group_Object__mdt WHERE User_Group_Nickname__c =: userGroupNickname];
            system.debug(' userGroupObjects size: ' + userGroupObjects.size());
            
            if(userGroupObjects.size() > 0){
                for( User_Group_Object__mdt obj : userGroupObjects){
                    listObjects.add(obj.Object_API__c);
                    system.debug(' userGroup Object: ' + obj.Object_API__c);
            	}
                
                listObjects.sort();
                system.debug(' listObjects size: ' + listObjects.size());           
            }    
           
        }
        
        return listObjects;        
    }
    
    @Auraenabled(cacheable=true)
    public static Map<String, String> objectLayoutList() { 
        
        system.debug(' START objectLayoutList');
        
        Map<String, String> userGroup = new  Map<String, String>();
        List<Layout_Manager__c> userGroupLayouts = new List<Layout_Manager__c>();
        Map<String, String> listLayouts = new Map<String, String>();
        
        String userGroupNickname;
        
        userGroup = userGroups();
        system.debug(' userGroupNickname size: ' + userGroupNickname);
        
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        if (userGroupNickname != null){            
            userGroupLayouts = [SELECT Id, Name FROM Layout_Manager__c WHERE Group_Name__c =: userGroupNickname AND Active__c =: true ];
            system.debug(' userGroupLayouts size: ' + userGroupLayouts.size());
            
            if(userGroupLayouts.size() > 0){
                for( Layout_Manager__c lt : userGroupLayouts){
                    //listLayouts.add(lt.Name);
                    listLayouts.put(lt.Id, lt.Name);
                    system.debug(' userGroupLayouts: ' + lt.Name);
            	}
                
               // listLayouts.sort();
                system.debug(' listObjects size: ' + listLayouts.size());           
            }  
        }
        
        return listLayouts;        
    }

    @Auraenabled(cacheable=true)
    public static Map<String, Map<String, Map<Boolean, List<String>>>> allLayouts() { 
        
        system.debug(' START allLayouts ##################');
        Map<String, Map<String, Map<Boolean, List<String>>>> layoutFieldsMap = new Map<String, Map<String, Map<Boolean, List<String>>>>();
        
        Map<String, String> userGroup = new  Map<String, String>();
        List<Layout_Manager__c> userGroupLayouts = new List<Layout_Manager__c>();
        List<User_Group_Object__mdt> userGroupObjects = new List<User_Group_Object__mdt>();
        List<String> listObjects = new List<String>(); 
        List<String> listLayouts = new List<String>(); 
        
        String userGroupNickname;
        
        userGroup = userGroups();
    //    system.debug(' userGroupNickname size: ' + userGroupNickname);
        
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        if (userGroupNickname != null){
            
            userGroupObjects = [SELECT Id, Object_API__c FROM User_Group_Object__mdt WHERE User_Group_Nickname__c =: userGroupNickname];
        //    system.debug(' userGroupObjects size: ' + userGroupObjects.size());
            
            if(userGroupObjects.size() > 0){
                for( User_Group_Object__mdt obj : userGroupObjects){
                    listObjects.add(obj.Object_API__c);
                    system.debug(' userGroup Object: ' + obj.Object_API__c);
                    
                    List<Metadata.Metadata> tempPageLayouts = new List<Metadata.Metadata >();
                    String layoutNameUG = null;
            		String layoutNameObj = null;
                    String objectApiName = obj.Object_API__c;
            		String objectApiNameModified = objectApiName;
                    if(objectApiName.contains('__c')){
                        objectApiNameModified = objectApiName.removeEndIgnoreCase('__c');
                        objectApiNameModified = objectApiNameModified.replaceAll('_', ' ');
                    }            
                       
                	layoutNameUG = objectApiName + '-' + userGroupNickname + '_Layout';                         
					layoutNameObj = objectApiName + '-' + objectApiNameModified + ' Layout';
                    
                    tempPageLayouts = Metadata.Operations.retrieve(        
                        Metadata.MetadataType.Layout, new List<String>{layoutNameUG}                 
                    );
                //    system.debug('Group Object API pageLayouts IS ' + tempPageLayouts.size());
                
                    if (tempPageLayouts.size() > 0)
                    {
                        String temp = layoutNameUG + '_XXXXXXX';
                        //listLayouts.add(layoutNameUG); 
                        listLayouts.add(temp);
                    }
                    else{
                        tempPageLayouts = Metadata.Operations.retrieve(        
                            Metadata.MetadataType.Layout, new List<String>{layoutNameObj} 
                            //Metadata.MetadataType.Layout, layoutNames            
                        );
                        if (tempPageLayouts.size() > 0)
                    	{
                            String temp = layoutNameObj + '_XXXXXXX';
                        	listLayouts.add(temp);
                        	//listLayouts.add(layoutNameObj);
                        }
                    }
                }
                
                listObjects.sort();
            }                    
            
            userGroupLayouts = [SELECT Id, Name FROM Layout_Manager__c WHERE Group_Name__c =: userGroupNickname AND Active__c =: true ];
           // system.debug(' userGroupLayouts size: ' + userGroupLayouts.size());
            
            if(userGroupLayouts.size() > 0){
                for( Layout_Manager__c lt : userGroupLayouts){
                    listLayouts.add(lt.Name);  
                   // system.debug(' userGroupLayouts: ' + lt.Name);                  
             	}                
            }
            
            listLayouts.sort();
            
            if (listLayouts.size() > 0){
                for(String oneLayout : listLayouts){
                    
                    Boolean defaultLayout = false;
                    String thisLayout = oneLayout;
                    if (oneLayout.contains('_XXXXXXX')){
                        defaultLayout = true;
                        thisLayout = oneLayout.replace('_XXXXXXX', '');
                    } 
                    
                    system.debug(' user Group Layouts: ' + thisLayout); 
                    
                    List<Metadata.Metadata> pageLayouts = new List<Metadata.Metadata >();
                    List<String> layoutFields = new List<String>();                     
                    pageLayouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String>{thisLayout});
                
                    integer ind = 0;
        			integer totalColumns = 0;
                    if(pageLayouts.size() > 0){
                        
                        Map<String, Map<Boolean, List<String>>> tempLayoutFieldsMap = new Map<String, Map<Boolean,List<String>>>(); //Map<Section, Map<IsFirstColumn, Field API Name>>
                        
                        // Get the describe result for the object
                        List<String> tempArrayObj = thisLayout.split('-');
                        String thisObjAPI = tempArrayObj[0];
                        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(thisObjAPI);
                        
                        for( Metadata.Metadata objPageLayout :pageLayouts ){                            
                            
                            Metadata.Layout layout = (Metadata.Layout)objPageLayout;                            
                            
                            for(Metadata.LayoutSection section :layout.layoutSections){                        
                                system.debug('SECTION NAME IS ' + section.label);
                                system.debug('SECTION detailHeading IS ' + section.detailHeading);
     
                                List<String> tempFieldsClm1 = new List<String>();
                                List<String> tempFieldsClm2 = new List<String>();
                                
                                if ((ind != 0) && (totalColumns == 0)) totalColumns = ind;
                                ind = 0;

                                if (section.label != 'Custom Links'){
                                    
                                    for(Metadata.LayoutColumn column :section.layoutColumns){            
                                        
                                        ind++;

                                        if(column.layoutItems != null){          				
                                            
                                            for(Metadata.LayoutItem item :column.layoutItems){
                                                
                                              	String strFieldAPI = item.field;
                                                String fieldLabel = '';
    											if (strFieldAPI != null) {
                                                    try {
                                                        // Get the describe field result for the field
                                                        Schema.DescribeFieldResult fieldDescribe = objectType.getDescribe().fields.getMap().get(strFieldAPI).getDescribe();
                                                                                                    
                                                        // Get the field label
                                                        fieldLabel = fieldDescribe.getLabel();
                                                        
                                                       // System.debug('FIELD API NAME IS ' + strFieldAPI);
                                                       // System.debug('FIELD LABEL IS ' + fieldLabel); 
                                                        
                                                    } catch (Exception e) {
                                                        System.debug('Error retrieving label for field: ' + strFieldAPI + ', error: ' + e.getMessage());
                                                    }
                                                }                                                
                                                
                                                layoutFields.add(item.field);  
                                                
                                                String strField = fieldLabel; // + ' ( ' + strFieldAPI + ' ) ';
                                                String strBehavior = item.behavior.name();
                                                if ((strBehavior == 'Required') || (strBehavior == 'Readonly')) strField = fieldLabel + ' ( *' + strBehavior + ' ) ';
                                                    //strField = fieldLabel + ' ( ' + strFieldAPI + ', *' + strBehavior + ' ) ';
                                                
                                                if (ind == 1) {
                                                    //tempFieldsClm1.add(item.field);
                                                    tempFieldsClm1.add(strField);
                                                } else if (ind == 2){
                                                    //tempFieldsClm2.add(item.field);
                                                    tempFieldsClm2.add(strField);
                                                }
                                                
                                            }   // for(Metadata.LayoutItem item :column.layoutItems) 
                                            
                                        }   //if(column.layoutItems != null)
                                        
                                        Map<Boolean, List<String>> tempMapClmAll = new Map<Boolean, List<String>>();
                                        tempMapClmAll.put(true, tempFieldsClm1);
                                        tempMapClmAll.put(false, tempFieldsClm2);

                                        //Method does not exist or incorrect signature: void put(String, Map<Boolean,List<String>>) from the type Map<String,Map<Boolean,String>>
                                        String tempSection = section.label;
                                        /*
                                        if (section.detailHeading){
                                             tempSection = section.label + ' (header is visible)'; 
                                        }
                                        else if (!section.detailHeading){
                                            tempSection = section.label + ' (header is hidden)';
                                        }
*/
                                        tempLayoutFieldsMap.put(tempSection, tempMapClmAll); //Map<Section, Map<IsFirstColumn, Field API Name>> 
                                        //tempLayoutFieldsMap.put(section.label, tempMapClmAll); //Map<Section, Map<IsFirstColumn, Field API Name>>
                                        
                                        
                                    }   //for(Metadata.LayoutColumn column :section.layoutColumns)
                                    
        
                                }   //if (section.label != 'Custom Links')
                                
                            }   //for(Metadata.LayoutSection section :layout.layoutSections)                           
                            
                        }   //for( Metadata.Metadata objPageLayout :pageLayouts )
                        
                        List<String> tempArray = thisLayout.split('-');
                        String tempObjName1 = tempArray[0].removeEndIgnoreCase('__c');
                        String tempObjName2 = tempObjName1.replaceAll('_', ' ');
                            
                        String modifiedLayout = tempObjName2 + ' - ' + tempArray[1];                        
                        
                        if(defaultLayout){
                           // List<String> tempArray = thisLayout.split('-');
                          //  modifiedLayout = tempArray[0] + '-' + 'Default (' + tempArray[1] + ')';
                            modifiedLayout = modifiedLayout + ' as Default';
                        }
                        
                        //Map<String, Map<String, Map<Boolean, List<String>>>>
                        //layoutFieldsMap.put(modifiedLayout, layoutFields);
                        layoutFieldsMap.put(modifiedLayout, tempLayoutFieldsMap);
                        
                    }   //if(pageLayouts.size() > 0)
                    
                }   //for(String oneLayout : listLayouts)  
                
            }   //if (listLayouts.size() > 0)
                
        }    

        return layoutFieldsMap;        
    }
    
    
    @Auraenabled(cacheable=true)
    public static List<String> layoutAssignmentList() { 
        
        system.debug(' START layoutAssignmentList');
        
        Map<String, String> userGroup = new  Map<String, String>();
        List<Layout_Assignment__C> userGroupAssignments = new List<Layout_Assignment__C>();
         List<String> layoutAssignments = new List<String>();
        
        String userGroupNickname;
        
        userGroup = userGroups();
        
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        if (userGroupNickname != null){            
            userGroupAssignments = [SELECT Id, User__r.Name, Layout_Manager__r.Name FROM Layout_Assignment__C WHERE Layout_Manager__r.Group_Name__c =: userGroupNickname AND Active__c =: true ];
            system.debug(' userGroupAssignments size: ' + userGroupAssignments.size());
            
            if(userGroupAssignments.size() > 0){
                for( Layout_Assignment__C la : userGroupAssignments){
                   // layoutAssignments.push(la.Name, la.User__c);
                    String temp = la.Id + ';' + la.Layout_Manager__r.Name  + ';' + la.User__r.Name;
                    
                    layoutAssignments.add(temp);                    
                    system.debug(' layoutAssignments: ' + temp);
            	}
                
                //layoutAssignments.sort();
                system.debug(' layoutAssignments size: ' + layoutAssignments.size());           
            }  
        }
        
        return layoutAssignments;        
    }
    
     @Auraenabled(cacheable=true)
    public static Map<String, String> usersList() { 
        
        system.debug(' START usersList');
        
        String currentUserId = userInfo.getUserId();
        system.debug(' USER in userGroups: ' + currentUserId);
        
        List<User_Group__mdt> listUserGroup = new List<User_Group__mdt>();
        listUserGroup = [SELECT Id, Group_Name__c, Nickname__c FROM User_Group__mdt]; 
        List<String> allPublicGroups = new List<String>();
        
        system.debug(' All User Group size: ' + listUserGroup.size());

        // Iterate through the User Groups
        if (listUserGroup.size() > 0){
            for (User_Group__mdt rec : listUserGroup ) {              
                 allPublicGroups.add(rec.Nickname__c);
                system.debug(' User Group Nickname: ' + rec.Nickname__c);                
            }
    	}
        
        List<GroupMember> groupMemberships = [SELECT GroupId FROM GroupMember WHERE UserOrGroupId = :currentUserId AND GroupMember.Group.Name IN: allPublicGroups LIMIT 1];
        String groupId = groupMemberships[0].GroupId;
        system.debug('groupId: ' + groupId);
        
        List<GroupMember> usersInGroup = new List<GroupMember>();
        List<Id> usersId = new List<Id>();
        List<User> nameUsers = new List<User>();
        List<String> usersList = new List<String>(); 
        Map<String, String> result = new Map<String, String>();
        
        if (groupId != null){            
            usersInGroup = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =: groupId ];
            system.debug(' usersInGroup size: ' + usersInGroup.size());
            
            if(usersInGroup.size() > 0){
                for( GroupMember uig : usersInGroup){
                    usersId.add(uig.UserOrGroupId);                   
            	}        
                system.debug(' usersList size: ' + usersId.size()); 
                
                if (usersId.size() > 0){
                    nameUsers = [ SELECT Id, Name FROM User WHERE Id IN: usersId ];
                    for( User rec : nameUsers){
                        result.put(rec.Id, rec.Name);
                        system.debug(' user ID: ' + rec.Id);
                        system.debug(' user Name: ' + rec.Name);
                    }
                }
            }  
        }
        
        return result;        
    }
 
    /*
     @Auraenabled
    public static void updateLayoutsOld(String groupName, List<String> newLayouts) { 
        

		system.debug(' START updateLayouts');
        system.debug(' groupName: ' + groupName);
        system.debug(' newLayouts: ' + newLayouts);
        
        List<Layout_Manager__c> groupLayouts = new List<Layout_Manager__c>();
        groupLayouts = [SELECT Id, Name FROM Layout_Manager__c WHERE Group_Name__c =: groupName AND Active__c =: true ];
        system.debug(' groupLayouts size: ' + groupLayouts.size());

        List<Layout_Assignment__C> currentAssignments = new List<Layout_Assignment__C>();
        currentAssignments = [SELECT Id, User__r.Id, Layout_Manager__r.Name, Active__c FROM Layout_Assignment__C WHERE Layout_Manager__r.Group_Name__c =: groupName AND Layout_Manager__r.Active__c =: true ];
        system.debug(' currentAssignments size: ' + currentAssignments.size());
            
        if(currentAssignments.size() > 0){
            for( Layout_Assignment__C la : currentAssignments){
                // layoutAssignments.push(la.Name, la.User__c);
                //String temp = la.Id + ';' + la.Layout_Manager__r.Name; //  + ';' + la.User__r.Name;                                  
               // system.debug(' layoutAssignments: ' + temp);
               // system.debug(' Active__c: ' + la.Active__c); 
                //la.Active__c = true;
                //update la;
                delete la;
            }                     
        }  
        
        Integer ind = 0;
        if (groupLayouts.size() > 0){            
            if (newLayouts.size() > 0){
                for (Layout_Manager__c lm : groupLayouts){
                    system.debug(' Layout_Manager__c Name : ' + lm.Name);
                    for(String record : newLayouts){
                        system.debug(' newLayouts record : ' + record); 
                        //"Test_Object__c~005BZ000001UyMMYA0~Default"
                        List<String> rec = record.split('~');
                        String name = rec[0] + '-' + rec[2];
                        system.debug(' Name after split : ' + name); 
                        if ((lm.Name == name)){ //if ((rec[2] != 'Default') && (lm.Name == name)){
                            system.debug(' inside incert : ' + name);
                            ind++;
                            Layout_Assignment__c layoutAssignment = new Layout_Assignment__c();
                            layoutAssignment.Name = rec[0] + '_' + ind;
                            layoutAssignment.Layout_Manager__c = lm.Id;
                            layoutAssignment.User__c = rec[1];
                            layoutAssignment.Active__c = true;
                            insert layoutAssignment;                    
                        }
                    }
                }
            } 
        }
    }   
*/  

     @Auraenabled
    public static void updateLayouts(String groupName, List<String> newLayouts) { 
        

		system.debug(' START updateLayouts');
        system.debug(' groupName: ' + groupName);
        system.debug(' newLayouts: ' + newLayouts);
        
        List<GroupMember> groupMemberships = [SELECT GroupId FROM GroupMember WHERE GroupMember.Group.Name =: groupName LIMIT 1];
        String groupId = groupMemberships[0].GroupId;
        
        List<GroupMember> usersInGroup = new List<GroupMember>();
        List<Id> allGroupId = new List<Id>();
        if (groupId != null){            
            usersInGroup = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId =: groupId ];
            system.debug(' usersInGroup size: ' + usersInGroup.size());
            for( GroupMember gm : usersInGroup){
                system.debug(' usersInGroup id : ' + gm.UserOrGroupId);
                allGroupId.add(gm.UserOrGroupId);
            }
        }
        
        List<Layout_Manager__c> groupLayouts = new List<Layout_Manager__c>();
        groupLayouts = [SELECT Id, Name FROM Layout_Manager__c WHERE Group_Name__c =: groupName AND Active__c =: true ];
        system.debug(' groupLayouts size: ' + groupLayouts.size());

        List<Layout_Assignment__C> currentAssignments = new List<Layout_Assignment__C>();
        currentAssignments = [SELECT Id, User__r.Id, Layout_Manager__r.Name, Active__c FROM Layout_Assignment__C WHERE Layout_Manager__r.Group_Name__c =: groupName AND Layout_Manager__r.Active__c =: true ];
        system.debug(' currentAssignments size: ' + currentAssignments.size());
            
        if(currentAssignments.size() > 0){
            for( Layout_Assignment__C la : currentAssignments){
                // layoutAssignments.push(la.Name, la.User__c);
                //String temp = la.Id + ';' + la.Layout_Manager__r.Name; //  + ';' + la.User__r.Name;                                  
               // system.debug(' layoutAssignments: ' + temp);
               // system.debug(' Active__c: ' + la.Active__c); 
                if (allGroupId.contains(la.User__r.Id)){
                    la.Active__c = false;
                    update la;
                }
                //delete la;
            }                     
        }  

		List<Layout_Assignment__C> newAssignments = new List<Layout_Assignment__C>();
        newAssignments = [SELECT Id, User__r.Id, Layout_Manager__r.Id, Layout_Manager__r.Name, Active__c FROM Layout_Assignment__C WHERE Layout_Manager__r.Group_Name__c =: groupName];
        system.debug(' newAssignments size: ' + newAssignments.size());
        
        Integer ind = 0;
        if (groupLayouts.size() > 0){            
            if (newLayouts.size() > 0){
                for (Layout_Manager__c lm : groupLayouts){
                    system.debug(' Layout_Manager__c Name : ' + lm.Name);
                    for(String record : newLayouts){
                        system.debug(' newLayouts record : ' + record); 
                        //"Test_Object__c~005BZ000001UyMMYA0~Default"
                        List<String> rec = record.split('~');
                        String name = rec[0] + '-' + rec[2];
                        if (allGroupId.contains(rec[1])){
                            //new code
                            Integer count = 0;
                            for( Layout_Assignment__C la : newAssignments){
                                if((name == la.Layout_Manager__r.Name) && (rec[1] == la.User__r.Id)){
                                    la.Active__c = true;
                                    update la; 
                                    count++;
                                }                           
                            }  
                            
                            if (count == 0){                        
                                if ((lm.Name == name)){ //if ((rec[2] != 'Default') && (lm.Name == name)){
                                    system.debug(' inside incert : ' + name);
                                    ind++;
                                    Layout_Assignment__c layoutAssignment = new Layout_Assignment__c();
                                    layoutAssignment.Name = rec[0] + '_' + ind;
                                    layoutAssignment.Layout_Manager__c = lm.Id;
                                    layoutAssignment.User__c = rec[1];                            
                                    layoutAssignment.Active__c = true;
                                    insert layoutAssignment;                    
                                }
                            }
                        } //if (allGroupId.contains(rec[1]))
                    }
                }
            } //if (newLayouts.size() > 0)
        } //if (groupLayouts.size() > 0)
    }   


	 @Auraenabled(cacheable=true)
    public static String groupAnnouncement() { 
        
        system.debug(' START getAnnouncement');
        
        String result; 
        String userGroupNickname;
        List<Announcement_Manager__c> announcement = new List<Announcement_Manager__c>();
        Map<String, String> userGroup = new  Map<String, String>();                 
        userGroup = userGroups();       
        
        if (userGroup.size()> 0){            
            for( String key : userGroup.keySet()){
                userGroupNickname = key;
                system.debug(' userGroupNickname: ' + userGroupNickname);
            }
        }
        
        if (userGroupNickname != null){
            announcement = [SELECT Id, Announcement__c FROM Announcement_Manager__c WHERE Name =: userGroupNickname LIMIT 1];
            result = announcement[0].Announcement__c;
            system.debug(' result : ' + result);  
         }
        
        return result;        
    }  
    
    @Auraenabled
    public static void updateAnnouncement(String groupName, String newDescription) { 
        
        system.debug(' START updateAnnouncement');
        system.debug(' groupName : ' + groupName);  
        system.debug(' newDescription : ' + newDescription);  
        
        List<Announcement_Manager__c> announcement = new List<Announcement_Manager__c>();
        announcement = [SELECT Id FROM Announcement_Manager__c WHERE Name =: groupName LIMIT 1];
        
        system.debug(' result announcement : ' + announcement.size()); 
        
        if (announcement.size() > 0){
            String recId = announcement[0].Id;
            Announcement_Manager__c announcementRec = new Announcement_Manager__c( Id = recId, Announcement__c = newDescription );
            update announcementRec;
        }         
    }    
   

}