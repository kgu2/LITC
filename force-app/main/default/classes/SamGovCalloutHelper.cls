/**
 * @description This class contains logic to make an HttpResponse to the Mulesoft SamGov API to validate a UEI.
 */

public with sharing class SamGovCalloutHelper {
    
    /**
     * This method makes an HttpResponse to the Mulesoft SamGov API to validate a UEI.
     * This function simply returns the response. Error handling must be handled afterwards wherever this function is called.
     * 
     * @param uei The UEI to be validated.
     * @return Map<String, Object> containing the API response.
     * 
     * 
     */
    public static Map<String, Object> validateUEI(String uei) {
        Map<String, Object> results = new Map<String, Object>();
        HttpRequest req = new HttpRequest();
        initializeAPISettings();

        // gets authentication details from custom metadata
        String endpoint = apiSettings.get('baseUrl') != null ? (apiSettings.get('baseUrl').value__c + uei) : ''; 
        String clientId = apiSettings.get('client_id') != null ? (apiSettings.get('client_id').value__c) : ''; 
        String clientSecret = apiSettings.get('client_secret') != null ? (apiSettings.get('client_secret').value__c) : ''; 

        System.debug(endpoint);
        System.debug(clientId);
        System.debug(clientSecret);

        req.setEndpoint(endpoint);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setHeader('client_id', clientId); 
        req.setHeader('client_secret', clientSecret);
        req.setTimeout(5000);
        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() == 200) {
            results = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
            System.debug(results);
            for (String key : results.keySet()) {
                System.debug(key);
            }
            
        } else{ 
            System.debug('ERROR: Received status code ' + res.getStatusCode());
            System.debug('Response body: ' + res.getBody());
        }
    
        return results;
    }

    public static Sam_gov_Validation__c createSamGovRecord(Map<String, Object> samResults) {
        Sam_gov_Validation__c sam = new Sam_gov_Validation__c();
        sam.ueiSAM__c = (String)samResults.get('organizationalUEI');
        sam.Legal_Entity_Name__c = (String)samResults.get('legalEntityName');
        sam.EIN__c = (String)samResults.get('EIN');
        sam.Address_1__c = (String)samResults.get('address1');
        sam.Address_2__c = (String)samResults.get('address2');
        sam.City__c = (String)samResults.get('city');
        sam.State__c = (String)samResults.get('state');
        sam.Zip__c = (String)samResults.get('zip');
        sam.Country__c = (String)samResults.get('country'); 

        sam.SAM_gov_Registration_Status__c = (String)samResults.get('SAMGOVRegistrationStatus'); 
        sam.Activation_Date__c = (String)samResults.get('activationDate') != null ? Date.valueOf((String)samResults.get('activationDate')) : null; 
        sam.Expiration_Date__c = (String)samResults.get('expirationDate') != null ? Date.valueOf((String)samResults.get('expirationDate')) : null;
        sam.Excluded_Parties__c = (String)samResults.get('excludedParties'); 
        sam.Federal_Debt__c = (String)samResults.get('federalDebt'); 
        sam.Reps_Certs__c = (String)samResults.get('repsCerts'); 
        sam.Responsibility_Qualification__c = (String)samResults.get('responsibilityQualification'); 

        sam.Name = (String)samResults.get('organizationalUEI');
        sam.Congressional_District__c = (String)samResults.get('congressionalDistrict');
        
        return sam;
    }
    /**
     * variable to hold api settings
     */
    private static Map<String, Sam_Gov_Api_Settings__mdt> apiSettings {get;set;}

    /**
     * gets API settings from custom metadata Sam_Gov_Api_Settings__mdt
     */
    public static void initializeAPISettings(){
        if (apiSettings == null) {
            apiSettings = new Map<String, Sam_Gov_Api_Settings__mdt>();
            for (Sam_Gov_Api_Settings__mdt setting : [SELECT DeveloperName,MasterLabel, Value__c FROM Sam_Gov_Api_Settings__mdt]) {
                apiSettings.put(setting.MasterLabel, setting);
            }
        }
    }
}