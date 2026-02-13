/**
 *  This class handles the Just In Time provisioning (JIT) for the LITC portal. 
 *  It implements the Auth.RegistrationHandler interface to create new users or update existing users
 */
global class LITCSSOJIT implements Auth.RegistrationHandler {

    /**
     * Custom exception class for handling JIT errors
     */
    private class JitException extends Exception {}


    /**
     * updateUser function updates an existing user's profile if it does not match LITC
     * 
     * @param userId Id of the user to be updated
     * @param portalId Specified portal Id
     * @param data Authentication user data
     */
    global void updateUser(Id userId, Id portalId, Auth.UserData data) {
        System.debug('in updateUser');
        String identifier = data.email;

        System.debug(data);

        List<User> currentUsers = [SELECT Id, ProfileId FROM User WHERE FederationIdentifier = :identifier];

        if(currentUsers.size() > 0)
            User currentUser =  currentUsers[0];
        else
            throw new JitException('User with Id - ' + identifier + ' not found');
    }

    /**
     * createUser function creates a new user record. 
     * Checks if a contact with the provided email address exists. 
     * If not, creates a temporary unverified Contact and Account.
     * 
     * @param portalId Specified portal Id
     * @param data Authentication user data
     * @return The new user record
    */
    global User createUser(Id portalId, Auth.UserData data) {
        System.debug('in createUser');

        String identifier = data.email;
        List<User> currentUser = new List<User>();
        currentUser =[SELECT Id FROM User WHERE federationidentifier = :identifier];

        if (!currentUser.isEmpty()) {
            return currentUser[0];
        }

        User u = new User();
        string emailID = data.email;
        list<contact> CurContact = new list<contact>();

        // query for an existing contact with given email
        CurContact = [SELECT Id, AccountId,FirstName,LastName,Title,Email,On_boarding_Expiration_Date__c FROM Contact WHERE Email = :emailID Limit 1];

        // if no contact found, create a temp unverified contact and account
        if(CurContact.size() == 0){
            Account act = new Account();
            act.Name = 'Account-' + emailID;
            try{
                insert act; 
            }
            catch(exception e){
                throw new JitException('Error During Account Creation' + e.getMessage() + ' -' + emailID);
            }
            
            Contact cnt = new Contact();
            cnt.LastName = 'LN-'+ emailID;
            cnt.Email = emailID;
            cnt.FirstName = 'FN-' + emailID;
            cnt.Unverified__c = true;
            cnt.AccountId = act.id;
            try{
                insert cnt; 
            } catch(exception e){
                throw new JitException('Error During Contact Creation' + e.getMessage() + ' -' + emailID);
            }
            CurContact.add(cnt); 
        } else{ 

            // if contact found, check the expiration date, throw error if date is past
            if (CurContact[0].On_boarding_Expiration_Date__c < date.today()){
                throw new JitException('Your contact registration window has expired. Please ask your Authorizing Official to extend your registration deadline. For further assistance, contact support at LITCGrants@treasury.gov. ' + ' -' + emailID);
            }
        }

        // creates the user
        U.FirstName = CurContact[0]?.FirstName;
        U.LastName = CurContact[0]?.LastName;
        U.Email = CurContact[0]?.Email;
        U.Title = CurContact[0]?.Title;
        u.FederationIdentifier = emailID;
        u.Username = CurContact[0]?.Email + '.litc';
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
        u.ProfileId = [SELECT Id, Name FROM Profile WHERE Name = 'LITC Customer Community Login'][0].Id;
                
        return u;
    }

}