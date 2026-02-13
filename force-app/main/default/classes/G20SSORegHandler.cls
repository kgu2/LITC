global class G20SSORegHandler implements Auth.RegistrationHandler{
    //JIT Handler Exception
    private class JitException extends Exception {}
    
    global User createUser(Id portalId, Auth.UserData data){
        system.debug('~~~ Inside Create User');
        return upsertUser(data);
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        system.debug('~~~ Inside Update User');
        User currentUser = upsertUser(data);
    }
    
    private User upsertUser(Auth.UserData data){
        
        string identifier = data.email;
        list<user> currentUser = new list<user>();
        // Not trusting on Salesforce Auth Events
        currentUser = [Select Id,ProfileId from User where federationidentifier = :identifier];
        Id profileId = [SELECT Id, Name FROM Profile WHERE Name = 'G20 Community Login User'][0].Id;
        
        //Not allowing users from other portal to enter here
       if(currentUser.size() > 0)
            return currentUser[0];
        else
           return createUser(data,profileId); 
        
    }
    
       
    private user createUser(Auth.UserData data,Id ProfileID)
    {
        User u = new User();
        Id AccountID = [select ID from Account where name like 'G20 Parent Account'].Id;
        List<contact> listcnt = new list<contact>();
        listcnt = [Select Id,FirstName,LastName,Email from Contact where AccountId = :AccountID and Email = :data.email limit 1];
        if(listcnt.size() == 0){
          processError(data);
          return null;
        }
        Contact cnt = listcnt[0];
        // creates the user
        U.FirstName = cnt.FirstName;
        U.LastName = cnt?.LastName;
        U.Email = data.email;
        u.FederationIdentifier = data.email;
        u.Username = data.email + '.G20';
        u.ContactId = cnt.Id;
        String alias = '';
        if(u.FirstName == null) {
            alias = u.LastName;
        } else {
            alias = u.FirstName.charAt(0) + u.LastName;
        }
        if(alias.length() > 5) {
            alias = alias.substring(0, 5);
        }
        u.Alias = alias;
        u.LanguageLocaleKey='en_US';
        u.LocaleSidKey='en_US';
        u.TimeZoneSidKey= 'America/New_York';
        u.EmailEncodingKey = 'ISO-8859-1';
        u.ProfileId = ProfileID;
        return u;
    }
    
    private void  processError(Auth.UserData data)
    {
        ErrorLogEvent__e errorEvent = new ErrorLogEvent__e();
        errorEvent.ErrorMessage__c = JSON.Serialize(data);
        errorEvent.ErrorSource__c = 'G20 Reg handler';
        errorEvent.ErrorType__c = 'SSO Error';
        errorEvent.Salesforce_ID__c = data.email;
        // Call method to publish events
        Database.SaveResult results = EventBus.publish(errorEvent);
         if (!Test.isRunningTest()) {
        throw new JitException('User not found');
         }
    }
    
    
}