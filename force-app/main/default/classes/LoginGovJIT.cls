//This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.
global class LoginGovJIT implements Auth.SamlJitHandler {
    private class JitException extends Exception{}
      
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,
        String federationIdentifier, Map<String, String> attributes, String assertion) {
           system.debug('~~~ input:' + userId); // User Id
            system.debug('~~~ SAMLSSOProvider' + samlSsoProviderId); // ID of the SSO Setting
            system.debug('~~~ communityId' + communityId); // Id of the community
            system.debug('~~~ portalId' + portalId); // Null
            system.debug('~~~ federationIdentifier' + federationIdentifier); // Federation ID of the user
            system.debug('~~~ attributes' + attributes); //attributes{email=test@treasury.gov, username=314db45e-01a2-4575-964b-92137df88b06}
            system.debug('~~~ assertion' + assertion);
            User u = [SELECT Id, ProfileId FROM User WHERE Id=:userId];
            if(u.ProfileId != System.Label.compprofile)
            {
                u.ProfileId = System.Label.compprofile; 
                try{
                    update u;
                }
                catch(exception e)
                {
                    processError('Error During User Update' + e.getMessage() ,'001 - Create User',federationIdentifier);
                }
                
                
            }
          
           /* if(u.ProfileId == System.Label.compprofile)
                system.debug('~~~~ Same profile for the existing user');
            else
            {
                u.ProfileId = System.Label.compprofile;
                //update u;
                JITUtil.UpdateUserProfile(u.ID, System.Label.compprofile);
            } */
     
    }
    
      global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,String federationIdentifier, Map<String, String> attributes, String assertion) {
            
          system.debug('~~~ Create User'); // User Id
          system.debug('~~~ SAMLSSOProvider' + samlSsoProviderId); // ID of the SSO Setting
          system.debug('~~~ communityId' + communityId); // Id of the community
          system.debug('~~~ portalId' + portalId); // Null
          system.debug('~~~ federationIdentifier' + federationIdentifier); // Federation ID of the user
          system.debug('~~~ attributes' + attributes); //attributes{email=test.user@treasury.gov, username=314db45e-01a2-4575-964b-92137df88b06}
         /* for (String fieldName : attributes.keySet()){
              System.debug('Attribute Key: ' + fieldName);
              System.debug('Attribute Value: ' + attributes.get(fieldName))  ;
           }*/
          system.debug('~~~ assertion' + assertion);
          User u = new User();
          string emailID = '';
          
          if(string.isBlank(federationIdentifier)) processError('No Federation id defined for the user','002 - CreateUSer','No Fed ID');
          if(attributes.containsKey('email')) 
          {
              emailID = attributes.get('email');
              list<contact> CurContact = new list<contact>();
              CurContact = [SELECT Id, AccountId,FirstName,LastName,Title,Email FROM Contact WHERE Email = :emailID Limit 1];
              if(CurContact.size() == 0){
                  // Create Contact with verified flag set to false
                  Account act = new Account();
                  act.Name = 'Account-' + emailID;
                  try{
                      insert act; 
                  }
                  catch(exception e)
                  {
                      processError('Error During Account Creation' + e.getMessage() ,'003A - Create User with Fed id - ' + emailID,federationIdentifier);
                  }
                  
                  Contact cnt = new Contact();
                  cnt.LastName = 'LN-'+ emailID;
                  cnt.Email = emailID;
                  cnt.FirstName = 'FN-' + emailID;
                  cnt.Unverified__c = true;
                  cnt.AccountId = act.id;
                  try{
                      insert cnt; 
                  }
                  catch(exception e)
                  {
                      processError('Error During Contact Creation' + e.getMessage() ,'003B - Create User with Fed id - ' + emailID,federationIdentifier);
                  }
                  CurContact.add(cnt); 
                  
              }  
              // Create User
              U.FirstName = CurContact[0]?.FirstName;
              U.LastName = CurContact[0]?.LastName;
              U.Email = CurContact[0]?.Email;
              U.Title = CurContact[0]?.Title;
              u.FederationIdentifier = federationIdentifier;
              u.Username = CurContact[0]?.Email + '.compport';
              u.ContactId = CurContact[0].Id;
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
              u.ProfileId = System.Label.compprofile;
              
              try{
                  Insert u; 
              }
              catch(exception e)
              {
                  processError('Error During User Creation' + e.getMessage() ,'005 - Create User with Fed id - ' + emailID,federationIdentifier);
              }
              
          }
          else
              processError ('No email in the custom attributes','CreateUSer',federationIdentifier);
          
          return u;
    }
    
    private void  processError(string errorMessage, string source, string FedId)
          {   
              /* ErrorLog__c err = new ErrorLog__c();
                    err.Error_Cause__c = 'Login.gov SSO';
                    err.Error_Message__c = source + ':' + errorMessage;
                    database.insert(err,false);
                    try{
                    
                    }*/
            //   ErrorLogEvent__e errorEvent = new ErrorLogEvent__e();
            //   errorEvent.ErrorMessage__c = source + ':' + errorMessage;
            //   errorEvent.ErrorSource__c = FedId;
              // Call method to publish events
            //   Database.SaveResult results = EventBus.publish(errorEvent);
              throw new JitException(source + ':' + errorMessage);
             
             
          }
    
   


}