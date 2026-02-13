/**
 * @description This class provides an Invocable method to validate a given UEI through the Mulesoft SamGov API.
 */

public with sharing class SamGovCallout {

    /**
     * Invocable method to validate a given UEI through the Mulesoft SamGov API.
     * 
     * @param inputList A list of UEIs to validate
     * @return List<UEIResult> A list of objects containing success status, response data, and error messages
     * if inputList is greater than 10, UEIResult will contain failures
     */
    @InvocableMethod(label='Validate UEI' description='Validates a given UEI through mulesoft SamGov API')
    public static List<UEIResult> validateUEI(List<UEIInput> inputList) {
        List<UEIResult> results = new List<UEIResult>();

        for (UEIInput input : inputList) {
             UEIResult result = new UEIResult();
             List<String> errorMessages = new List<String>();

            if(input.apps.size() > 1){
                Map<Id, Application_for_Federal_Assistance__c> appMap = new Map<Id, Application_for_Federal_Assistance__c> (input.apps);
                getMultiValidation(new List<Id>(appMap.keySet()));
                result.success = true;
                result.responseData = 'Check in later for results of this job.';
            }else{
                List<SAM_Gov_Validation__c> samValidationData = new List<SAM_Gov_Validation__c>();
                List<SAM_Gov_Validation__c> samValidationDataToCreate = new List<SAM_Gov_Validation__c>();

                Map<Id, Application_for_Federal_Assistance__c> appList = new Map<Id, Application_for_Federal_Assistance__c>(input.apps);
                //check size of appList. Run asynchronous job if greater than XXX (what is our limit - 100? That's still going to take a while. So maybe 10)
                Map<Id, SAM_gov_Validation__C> samValidationMap = new Map<Id, SAM_gov_Validation__C>();
                for(SAM_gov_Validation__c samValidation : [SELECT Id, Application_for_Federal_Assistance__c FROM SAM_gov_Validation__C WHERE Application_for_Federal_Assistance__c IN :appList.keySet()]){
                    samValidationMap.put(samValidation.Application_for_Federal_Assistance__c, samValidation);
                }
                for(Application_for_Federal_Assistance__c app : appList.values()){
                    app.Sam_gov_Re_run_Date__c = System.now();
                    Map<String, Object> response = SamGovCalloutHelper.validateUEI(app.Organizational_UEI__c);
                    if (response.containsKey('errorDetails')) {
                        result.success = false;
                        errorMessages.add(app.Name + ' | ' + app.Organizational_UEI__c + ': ' + (String)response.get('errorDetails'));
                        app.UEI_Sam_gov_Validation_Status__c = false;
                        Sam_Gov_Validation__c sam = new Sam_Gov_Validation__c();
                        sam.ueiSAM__c = app.Organizational_UEI__c;
                        sam.SAM_gov_Registration_Status__c = 'Invalid UEI'; 
                        sam.Activation_Date__c = null; 
                        sam.Expiration_Date__c = null;
                        sam.Name = app.Organizational_UEI__c == null ? 'NO UEI': app.Organizational_UEI__c;
                        if(samValidationMap.containsKey(app.Id)){
                            sam.Id = samValidationMap.get(app.Id).Id;
                            samValidationData.add(sam);
                        }else{
                            sam.Application_for_Federal_Assistance__c = app.Id;
                            samValidationDataToCreate.add(sam);
                        }
                    } else {
                        result.success = true;
                        result.responseData = JSON.serialize(response);
                        Sam_Gov_Validation__c sam = SamGovCalloutHelper.createSamGovRecord(response);
                        if(samValidationMap.containsKey(app.Id)){
                            sam.Id = samValidationMap.get(app.Id).Id;
                            samValidationData.add(sam);
                        }else{
                            sam.Application_for_Federal_Assistance__c = app.Id;
                            samValidationDataToCreate.add(sam);
                        }
                        // Updating the information on the application record - only if we got a response from sam.gov
                        app.Do_you_have_a_UEI__c = 'Yes';
                        app.UEI_Sam_gov_Validation_Status__c = true;
                        app.Legal_Name__c = (String)response.get('legalEntityName');
                        app.Street_1__c = (String)response.get('address1');
                        app.Street_2__c = (String)response.get('address2');
                        app.Employer_Taxpayer_Number__c = (String)response.get('EIN');
                        app.City__c = (String)response.get('city');
                        app.State__c = (String)response.get('state');
                        app.Country__c = (String)response.get('country'); 
                        app.Zip_Postal_Code__c = (String)response.get('zip');
                    }
                }
                result.samValidationData = samValidationData;
                result.samValidationDataToCreate = samValidationDataToCreate;
                result.appsToUpdate = appList.values();
            }
                
            
            if(errorMessages.size()!=0) {result.errorMessage = String.join(errorMessages, '<br/>');}

            results.add(result);
        }

        return results;
    }
    @future(callout=true)
    public static void getMultiValidation(List<Id> appIds)
    {   
         // Perform a callout to an external service
         
            List<SAM_Gov_Validation__c> samValidationData = new List<SAM_Gov_Validation__c>();
            List<Application_for_Federal_Assistance__c> appUpdates = new List<Application_for_Federal_Assistance__c>();
            //List<SAM_Gov_Validation__c> samValidationDataToCreate = new List<SAM_Gov_Validation__c>();

            List<Application_for_Federal_Assistance__c> appList = [SELECT Id,Organizational_UEI__c FROM Application_for_Federal_Assistance__c WHERE Id IN :appIds];
            //check size of appList. Run asynchronous job if greater than XXX (what is our limit - 100? That's still going to take a while. So maybe 10)
            Map<Id, SAM_gov_Validation__C> samValidationMap = new Map<Id, SAM_gov_Validation__C>();
            for(SAM_gov_Validation__c samValidation : [SELECT Id, Application_for_Federal_Assistance__c FROM SAM_gov_Validation__C WHERE Application_for_Federal_Assistance__c IN :appIds]){
                samValidationMap.put(samValidation.Application_for_Federal_Assistance__c, samValidation);
            }
            for(Application_for_Federal_Assistance__c app : appList){
                Map<String, SObject> result = runSamGovValidation(app, samValidationMap.get(app.Id));
                samValidationData.add((Sam_Gov_Validation__c)result.get('sam'));
                appUpdates.add((Application_for_Federal_Assistance__c)result.get('app'));
            }

            upsert samValidationData;

            update appUpdates;
        
    }

    private static Map<String, SObject> runSamGovValidation(Application_for_Federal_Assistance__c app, Sam_Gov_Validation__c samInput){

        Sam_Gov_Validation__c sam;

        app.Sam_gov_Re_run_Date__c = System.now();
        Map<String, Object> response = SamGovCalloutHelper.validateUEI(app.Organizational_UEI__c);
        if (response.containsKey('errorDetails')) {
            // result.success = false;
            // errorMessages.add(app.Name + ' | ' + app.Organizational_UEI__c + ': ' + (String)response.get('errorDetails'));
            sam = new Sam_Gov_Validation__c();
            app.UEI_Sam_gov_Validation_Status__c = false;
            sam.ueiSAM__c = app.Organizational_UEI__c;
            sam.SAM_gov_Registration_Status__c = 'Invalid UEI'; 
            sam.Activation_Date__c = null; 
            sam.Expiration_Date__c = null;
            sam.Name = app.Organizational_UEI__c == null ? 'NO UEI': app.Organizational_UEI__c;
        } else {
            sam = SamGovCalloutHelper.createSamGovRecord(response);
            // Updating the information on the application record - only if we got a response from sam.gov
            app.Do_you_have_a_UEI__c = 'Yes';
            app.UEI_Sam_gov_Validation_Status__c = true;
            app.Legal_Name__c = (String)response.get('legalEntityName');
            app.Street_1__c = (String)response.get('address1');
            app.Street_2__c = (String)response.get('address2');
            app.Employer_Taxpayer_Number__c = (String)response.get('EIN');
            app.City__c = (String)response.get('city');
            app.State__c = (String)response.get('state');
            app.Country__c = (String)response.get('country'); 
            app.Zip_Postal_Code__c = (String)response.get('zip');
        }
        sam.Application_for_Federal_Assistance__c = app.Id;
        sam.Id = samInput == null ? null : samInput.Id;

        return new Map<String, SObject>{
            'sam' => sam,
            'app' => app
        };
    }

    /**
     * Data structure for UEI input used in the invocable method
     */
    public class UEIInput {
        // @InvocableVariable(label='UEIs' required=true)
        // public List<String> ueis;
        @InvocableVariable(label='Apps' required=true)
        public List<Application_for_Federal_Assistance__c> apps;
    }

    /**
     * Data structure for UEI output results. Contains success status, API response data, and error messages
     */
    public class UEIResult {
        @InvocableVariable(label='Success' required=true)
        public Boolean success;

        @InvocableVariable(label='Response Data' required=false)
        public String responseData;

        @InvocableVariable(label='SamValidation Data' required=false)
        public List<SAM_gov_Validation__C> samValidationData;

        @InvocableVariable(label='Error Message' required=false)
        public String errorMessage;

        @InvocableVariable(label='ApplicationUpdate' required=false)
        public List<Application_for_Federal_Assistance__c> appsToUpdate;

        @InvocableVariable(label='SamValidation Data to Create' required=false)
        public List<SAM_gov_Validation__C> samValidationDataToCreate;
    }
}