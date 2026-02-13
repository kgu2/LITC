global class CRMRegHandler implements Auth.RegistrationHandler{
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
        string identifier = '';
        CAIAUserDataJSON caiaJSON = CAIAUserDataJSON.parse(JSON.Serialize(data));
        identifier = caiaJSON.attributeMap.emplid;
        if(string.isempty(identifier))
        {
            // Check for UUID as step 2 check
            identifier = checkforapprovedDomain(caiaJSON);
            system.debug('---> Step 2 identifier' + identifier);
             if(string.isempty(identifier))
            	processError('NoapprovedFedID', data); 
        }
        // Todo create user if thats the requirements
        list<user> currentUser = new list<user>();
        currentUser = [Select Id from User where federationidentifier = :identifier];
        if(currentUser.size() > 0)
            return currentUser[0];
        else
        {
            // Log Error
           
               processError(identifier, data); 
           
            
            return null;        
        }
        
        
    }
    
    private void  processError(string identifier, Auth.UserData data)
    {
        ErrorLogEvent__e errorEvent = new ErrorLogEvent__e();
        errorEvent.ErrorMessage__c = JSON.Serialize(data);
        errorEvent.ErrorSource__c = 'CRMRegHandler';
        errorEvent.ErrorType__c = 'SSO Error';
        errorEvent.Salesforce_ID__c = identifier;
        // Call method to publish events
        Database.SaveResult results = EventBus.publish(errorEvent);
         if (!Test.isRunningTest()) {
        throw new JitException('User with Id - ' + identifier + ' not found');
         }
    }
    
    private string checkforapprovedDomain(CAIAUserDataJSON caiaJSON){
        return caiaJSON.attributeMap.uuid;
    }
}