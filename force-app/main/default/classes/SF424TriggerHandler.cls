public with sharing class SF424TriggerHandler {
    public static void handleBeforeUpdate(List<Application_for_Federal_Assistance__c> appsToProcessSubmission) {
        for( Application_for_Federal_Assistance__c app : appsToProcessSubmission ){ 
            if (app.Legal_Name__c == null) app.Legal_Name__c.addError('Applicant information : "Legal name"  is Required');
            if (app.Organizational_UEI__c == null) app.Organizational_UEI__c.addError('Applicant information : "Organizational UEI"  is Required');
            if (app.Street_1__c == null) app.Street_1__c.addError('Applicant information : "Street"  is Required');
            if (app.City__c == null) app.City__c.addError('Applicant information : "City"  is Required');
            if (app.State__c == null) app.State__c.addError('Applicant information : "State"  is Required');
            if (app.Zip_Postal_Code__c == null) app.Zip_Postal_Code__c.addError('Applicant information : "Zip/Postal code"  is Required');
            if (app.Country__c == null) app.Country__c.addError('Applicant information : "Country"  is Required');
            if (app.First_Name__c == null) app.First_Name__c.addError('Organization unit : "First name"  is Required');
            if (app.Last_Name__c == null) app.Last_Name__c.addError('Organization unit : "Last name"  is Required');
            if (app.Telephone_Number__c == null) app.Telephone_Number__c.addError('Organization unit : "Telephone number"  is Required');
            if (app.Email__c == null) app.Email__c.addError('Organization unit : "Email"  is Required');
            if (app.Type_of_Applicant_1__c == null) app.Type_of_Applicant_1__c.addError('Organization unit : "Type of applicant"  is Required');
            if (app.Type_of_Applicant_1__c != null && app.Type_of_Applicant_1__c.contains('Other (specify)') && app.Type_of_Application_1_Other__c == null) app.Type_of_Application_1_Other__c.addError('Organization unit : "Other (specify)"  is Required');
            if (app.Type_of_Applicant_2__c != null && app.Type_of_Applicant_2__c.contains('Other (specify)') && app.Type_of_Applicant_2_Other__c == null) app.Type_of_Applicant_2_Other__c.addError('Organization unit : "Other (specify)"  is Required');
            if (app.Type_of_Applicant_3__c != null && app.Type_of_Applicant_3__c.contains('Other (specify)') && app.Type_of_Applicant_3_Other__c == null) app.Type_of_Applicant_3_Other__c.addError('Organization unit : "Other (specify)"  is Required');
            if (app.Name_of_Federal_Agency__c == null) app.Name_of_Federal_Agency__c.addError('Organization unit : "Name of federal agency" is Required');
            // if (app.Title_Applicant_Project__c == null) app.Title_Applicant_Project__c.addError('Organization unit : "Descriptive title of applicant project" is Required');


            if(app.Zip_Postal_Code__c != null){
                Matcher regexPost = Pattern.compile('\\d{5}$|\\d{5}-\\d{4}$').matcher(app.Zip_Postal_Code__c);
                if(!regexPost.matches()) app.Zip_Postal_Code__c.addError('Applicant information : Zip/Postal code must be entered in its correct format.');
            } 

        }
    }
    
}