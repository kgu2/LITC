global class SBeCS_CRMRegHandler implements Auth.RegistrationHandler {
    //JIT Handler Exception
    private class JitException extends Exception {}

    global User createUser(Id portalId, Auth.UserData data) {
        system.debug('~~~ Inside Create User');
        system.debug('~~~ Auth.UserDate --> ' + data);
        string federationIdentifier = data.email;

        //Find Contact with given email:
        List < Contact > conList = [SELECT Id, email FROM Contact WHERE email =: federationIdentifier];

        //No Contact with the email
        if (conList.size() == 0) {
            //**TO DO**
            Account acc = new Account();
            Contact con = new Contact();
            User u = new User();
            
            return u;
        }
        //Found Contact with the email
        else {
            //Find user with the email
            list < user > userList = [Select Id, ProfileId, federationidentifier from User where federationidentifier =: federationIdentifier];

            //Found user with the email
            if (userList.size() > 0) {
                User u = userList[0];
                u.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'SBeCS Community Login'][0].Id;
            
                update u;
                
                return u;
            }
            //Did not find user with the email
            else {
                User U = new User();
                // Create User
                U.FirstName = conList[0]?.FirstName;
                U.LastName = conList[0]?.LastName;
                U.Email = conList[0]?.Email;
                U.Title = conList[0]?.Title;
                u.FederationIdentifier = federationIdentifier;
                u.Username = conList[0]?.Email + '.sbecs';
                u.ContactId = conList[0].Id;
                String alias = '';
                if (u.FirstName == null) {
                    alias = u.LastName;
                } else {
                    alias = u.FirstName.charAt(0) + u.LastName;
                }
                if (alias.length() > 5) {
                    alias = alias.substring(0, 5);
                }
                u.Alias = alias;
                u.LanguageLocaleKey = 'en_US';
                u.LocaleSidKey = 'en_US';
                u.TimeZoneSidKey = 'America/New_York';
                u.EmailEncodingKey = 'ISO-8859-1';
                u.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'SBeCS Community Login'][0].Id;

                // think insert is automatic? just need to return?
                // Insert u;
                
                return u;
            }
        }
    }
    
    global void updateUser(Id userId, Id portalId, Auth.UserData data){
        system.debug('~~~ Inside Update User');
        system.debug('~~~ Auth.UserDate --> ' + data);
        User currentUser = upsertUser(data);
    }
        
    private User upsertUser(Auth.UserData data){
        //string identifier = data.identifier;
        string identifier = data.email;
        // Todo create user if thats the requirements
        list<user> currentUser = new list<user>();
           currentUser =[Select Id from User where federationidentifier = :identifier];
        if(currentUser.size() > 0)
            return currentUser[0];
        else
            throw new JitException('User with Id - ' + identifier + ' not found');
        
    }
}