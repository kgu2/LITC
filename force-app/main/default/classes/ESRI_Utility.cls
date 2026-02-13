global with sharing class ESRI_Utility {
    public class DateException extends Exception {}
    public class QueryBuilderException extends Exception {}
    public class DataRowException extends Exception {}

    //constructor
    public ESRI_Utility() {
        
    }

    /*this function calls the Mulesoft API in Treasury that interacts with ESRI
    https://www.esri.com/en-us/arcgis/open-vision/initiatives/developer-api  BS*/
    @AuraEnabled(cacheable=true)
    public static string getEsriData(String addresses){

            System.debug('in getEsriData' + addresses);
            HttpRequest req = new HttpRequest();

            req.setTimeout(60000);
            req.setMethod('POST');
            req.setEndpoint(apiSettings.get('baseURL').Value__c);
            req.setHeader('client_id', apiSettings.get('clientID').Value__c);
            req.setHeader('client_secret', apiSettings.get('clientSecret').Value__c);
            req.setHeader('Content-Type', apiSettings.get('contentType').Value__c);
            req.setBody(addresses.capitalize());

            Http exampleHTTP = new Http();
            HttpResponse callResponse = exampleHTTP.send(req);
            String jsonBody;
            String callError = callResponse.getStatus();
            Integer callStatus = callResponse.getStatusCode();
            System.debug('call errors = ' + callError + ' code =  ' + callStatus);
            jsonBody = callResponse.getBody();
            System.debug('body result = ' + jsonBody);
            System.debug('untyped:' + JSON.deserializeUntyped(jsonBody));
            //Parse body
            List<ESRIgeoCode> returnEsriData = ParseEsriJson(jsonBody);
            //test data bc treasury api is down.
            System.debug('esri return = ' + returnEsriData);
            if(returnEsriData.size() == 0){//if API doesn't respond.
                returnEsriData = noDataReturned(1);
            }
            //end test data.
            return JSON.serialize(returnEsriData[0]);
        }

            /*this function calls the Mulesoft API in Treasury that interacts with ESRI
        https://www.esri.com/en-us/arcgis/open-vision/initiatives/developer-api  BS*/
    @AuraEnabled(cacheable=true)
    public static  List<ESRIgeoCode> getEsriDataBulk(Integer numberOfAddresses, String addresses){

            System.debug('in getEsriData' + addresses);
            HttpRequest req = new HttpRequest();

            req.setTimeout(60000);
            req.setMethod('POST');
            req.setEndpoint(apiSettings.get('baseURL').Value__c);
            req.setHeader('client_id', apiSettings.get('clientID').Value__c);
            req.setHeader('client_secret', apiSettings.get('clientSecret').Value__c);
            req.setHeader('Content-Type', apiSettings.get('contentType').Value__c);
            req.setBody(addresses);
            System.debug(req);
            System.debug(req.getHeader('client_id'));
            System.debug(req.getHeader('client_secret'));
            System.debug(req.getHeader('Content-Type'));
            Http exampleHTTP = new Http();
            HttpResponse callResponse = exampleHTTP.send(req);
            String jsonBody;
            
            jsonBody = callResponse.getBody();
            System.debug('jsonBody>>>');
            System.debug(jsonBody);
            String callError = callResponse.getStatus();
            Integer callCode = callResponse.getStatusCode();

            if(callCode==200){
                List<ESRIgeoCode> returnEsriData = ParseEsriJson(jsonBody);           
                System.debug(returnEsriData.size());
                return (returnEsriData);
            }
            else{
                System.debug('callError>>> ' + callError);
                System.debug('callError>>> ' + callCode);
                System.debug(callResponse.toString());
                throw new AuraHandledException('ESRI Error: ' + callCode + ' ' + callError);


            }
        }
            
    public static List<ESRIgeoCode> ParseEsriJson(String jsonBody){
        System.debug(jsonBody);
        JSONParser parser = JSON.createParser(jsonBody);
        List<ESRIgeoCode> listToReturn = new List<ESRIgeoCode>();
        ESRIgeoCode geoCodeObj = new ESRIgeoCode(); 
        while(parser.nextToken() != null){
            if(parser.getCurrentToken() == System.JSONToken.START_ARRAY) {
                while (parser.nextToken() != null) {
                    String Match_addr, StAddr, City, Region, RegionAbbr, Postal, PostalPlus4, Score;
                    if(parser.getCurrentToken() == System.JSONToken.START_OBJECT){
                        geoCodeObj = new ESRIgeoCode();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='OBJECTID')){
                        parser.nextToken();
                        geoCodeObj.OBJECTID = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='Match_addr')){
                        parser.nextToken();
                        geoCodeObj.Match_addr = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='StAddr')){
                        parser.nextToken();
                        geoCodeObj.StAddr = parser.getText();
                    }
                    else  if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='City')){
                        parser.nextToken();
                        geoCodeObj.City = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='Subregion')){
                        parser.nextToken();
                        geoCodeObj.Subregion = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='Region')){
                        parser.nextToken();
                        geoCodeObj.Region = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='RegionAbbr')){
                        parser.nextToken();
                        geoCodeObj.RegionAbbr = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='Postal')){
                        parser.nextToken();
                        geoCodeObj.Postal = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='PostalExt')){
                        parser.nextToken();
                        geoCodeObj.PostalExt = parser.getText();
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='score')){
                        parser.nextToken();
                        geoCodeObj.Score = Decimal.valueOf(parser.getText());
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='addr_type')){
                        parser.nextToken();
                        geoCodeObj.addr_type = (parser.getText());
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='status')){
                        parser.nextToken();
                        geoCodeObj.status = (parser.getText());
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='X')){
                        parser.nextToken();
                        geoCodeObj.xCord = Decimal.valueOf(parser.getText());
                    }
                    else if((parser.getCurrentToken() == System.JSONToken.FIELD_NAME) && (parser.getText() =='Y')){
                        parser.nextToken();
                        geoCodeObj.yCord = Decimal.valueOf(parser.getText());
                    }

                    else if((parser.getCurrentToken() == System.JSONToken.END_OBJECT)){
                        listToReturn.add(geoCodeObj);
                    }
                    else if(parser.getCurrentToken() == System.JSONToken.END_ARRAY){
                        break;
                    }
                    else{
                        System.debug('CURRENTTOKEN:'+parser.getCurrentToken());
                        System.debug('CURRENTTEXT:'+parser.getText());
                    }
                }
            }
        }
        return listToReturn;
    }

            
    /* function taken from Dalton's UploadValidation class
    * Check records from JSON on Recipient for errors then populating those errors onto the JSON File previous return map<String, list<Object>>
    */
    @AuraEnabled
    public static map<String, list<Object>> runUploadAddressValidation(Integer idx, String docId, String sObjectName, list<Object> warnings, list<Object> scope, list<Object> headers, String filename, Integer startRow, Integer startColumn){
            System.debug('docId = ' + docId);
            Integer recordsChecked = 0;
            Integer rowMax = Integer.valueOf(apiSettings.get('maxRows').Value__c);
            Integer maxRows = Math.min(idx + rowMax, scope.size() - idx);
            Integer rows = maxRows + idx;

            Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe(); 
            Schema.SObjectType obj = gd.get(sObjectName.trim());
            Map<String, Schema.SObjectField> fm = obj.getDescribe().fields.getMap();//field map

            String tempJSON = JSON.serialize(scope);
            list<Object> templist = (list<Object>)JSON.deserializeUntyped(tempJSON);//deserializes each json line into objects
            list<sObject> records = new list<sObject>();  //hold individual records pulled out of the whole json
            Map<Integer, sObject> recordsByIndex = new Map<Integer, sObject>();//Use objectId passed by by ESRI to find associated records
            //String to hold all addresses and pass to esri
            String addressString = '['; 
            // Loop through records at a time
            for( Integer i = idx; i < rows; i++ ) { 
                sObject record = obj.newSObject();  //make a new generic object
                Map<String,Object> objRecord = (Map<String,Object>)templist.get(i);//pulls one row from the json and makes it an object.

                for(String key : objRecord.keySet()) {
                    if(key == 'attributes')
                        continue;
                   
                    String myType = fm.get( key.toLowerCase().trim() ).getDescribe().getType().name();  //gets the type of api field using the passed in object type
                    System.debug('key>>>' + key);
                    Object myValue;
                    if(objRecord.get(key) != null){
                        myValue  = UploadValidation.formatValue(myType, '' + objRecord.get(key));  //uses custom code in UploadValidation to get the value.
                        try{
                            record.put(key, myValue);  //creates a complete map of field api names and associated values pulled from the xcel doc
                        }catch(Exception e){
                            System.debug(e);
                        }
                    }
                    
                }
                String addString = buildAddressString(objRecord, i, sObjectName);
                if(addString!=null) addressString = addressString + addString;
                records.add(record);
                recordsByIndex.put(i, record);
                recordsChecked++;
            }
            //need to trim the last comma off.
            addressString = addressString.removeEnd(',') + ']';
            list<ESRIgeoCode> addressSuggestions = getEsriDataBulk(maxRows, addressString);//call out
            System.debug('addressSuggestions>>' + addressSuggestions);
            System.debug('size>>' + addressSuggestions.size());
            if(addressSuggestions.size()>0 && addressSuggestions[0].status.contains('Error')){
                    Map<String, list<Object>> retMap = new Map<String, list<Object>>();
                    retMap.put('callError', new List<Object>{(Object)addressSuggestions[0].OBJECTID});
                    retMap.put('callCode', new List<Object>{(Object)addressSuggestions[0].status});
                    throw new AuraHandledException('Error with ESRI Address Check API: ' + String.valueOf(addressSuggestions[0].status) + ' ' + String.valueOf(addressSuggestions[0].OBJECTID));
                    //return retMap;
            }
            Integer index = idx;
            Integer indexOfCheckedRecords = 0;
            warnings = new list<Object>();
            list<Object> esriAddresses = new list<Object>();
            ESRI_Field_Mapping__mdt fieldMap = fieldMapping.get(sObjectName);
            for(ESRIgeoCode gc : addressSuggestions){
                if (Integer.valueOf(gc.score) < 90){

                    String AddressNotFound = 'Unable to confirm address, closest match is: ';  //holds string that is the fieldName with error : 
                    System.debug('Making Errors...');
                    //make error row for Address 1... not sure how to handle 2 and 3.
                    map<String, Object> rowErrorAddress = makeErrorRow(recordsByIndex,  index,  startRow, startColumn, fieldMap.address1__c, sObjectName, headers, gc, gc.StAddr, AddressNotFound);
                    map<String, Object> rowErrorCity = makeErrorRow(recordsByIndex,  index,  startRow, startColumn + 3, fieldMap.city__c, sObjectName, headers, gc, gc.City, 'city');
                    map<String, Object> rowErrorState = makeErrorRow(recordsByIndex,  index,  startRow, startColumn + 4, fieldMap.state__c, sObjectName, headers, gc, gc.RegionAbbr, 'state');
                    map<String, Object> rowErrorZip = makeErrorRow(recordsByIndex,  index,  startRow, startColumn + 5, fieldMap.zip__c,sObjectName, headers, gc, gc.Postal, 'zip');
                    
                    warnings.add(rowErrorAddress);
                    warnings.add(rowErrorState);
                    warnings.add(rowErrorCity);
                    warnings.add(rowErrorZip);


                }
                Map<String,Object> esriAdd = new Map<String,Object>();
                esriAdd.put('index', index);
                esriAdd.put(fieldMap.esriAdd1__c,gc.StAddr);
                esriAdd.put(fieldMap.esriCity__c,gc.City);
                if(fieldMap.esriStateAbbr__c!=null)esriAdd.put(fieldMap.esriStateAbbr__c,gc.RegionAbbr);
                esriAdd.put(fieldMap.esriZip__c,gc.Postal);
                esriAddresses.add(esriAdd);
                // records[index].put(fieldMap.esriAdd1__c, (String)gc.StAddr);
                indexOfCheckedRecords++;
                index++;
            }

            map<String, list<Object>> mapJSONErrorsAndRecords = new map<String, list<Object>>{
                'records' => templist,
                'warnings' => warnings,
                'rows' => new list<Object>{(Object)scope.size()},
                'rowsExecuted' => new list<Object>{(Object)(recordsChecked + idx)},
                'esriAddresses' => esriAddresses
            };
            System.debug('records>>>');
            System.debug(String.valueOf(templist));
            if(docId!=null){
                ContentVersion cv = [SELECT ContentDocumentId FROM ContentVersion WHERE ContentDocumentId =: docId LIMIT 1];
            	System.debug(mapJSONErrorsAndRecords);
                String JSONString = JSON.serialize(mapJSONErrorsAndRecords);
                Blob Blobdata = Blob.valueof(JSONString);
    
                ContentVersion conVer = new ContentVersion();
                conVer.ContentDocumentId = docId;
                conVer.ContentLocation = 'S';
                conVer.PathOnClient = filename + '.txt';
                conVer.Title = filename;
                conVer.VersionData = Blobdata;
                insert conVer;
    
                mapJSONErrorsAndRecords.put('docId', new list<Object>{(Object)cv.ContentDocumentId});
            }

            System.debug('mapJSONErrorsAndRecords : ' +mapJSONErrorsAndRecords);
        return mapJSONErrorsAndRecords;
    }

    private static map<String, Object> makeErrorRow(Map<Integer, sObject> recordsByIndex, Integer index, Integer startRow, Integer startColumn, String field, String sObjectName, list<Object> headers, ESRIgeoCode gc, String suggestedComponent, String msg ){
        map<Integer,String> columnLetters = new map<Integer,String>{
            1   =>  'A', 2   =>  'B', 3   =>  'C', 4   =>  'D', 5   =>  'E', 6   =>  'F',
            7   =>  'G', 8   =>  'H', 9   =>  'I', 10   =>  'J', 11   =>  'K', 12   =>  'L',
            13   =>  'M', 14   =>  'N', 15   =>  'O', 16   =>  'P', 17   =>  'Q', 18   =>  'R',
            19   =>  'S', 20   =>  'T', 21   =>  'U', 22   =>  'V', 23   =>  'W', 24   =>  'X',
            25   =>  'Y', 26   =>  'Z', 27 => 'AA', 28 => 'AB', 29 => 'AC', 30 => 'AD', 31=>'AE',
            32 => 'AF', 33 => 'AG', 34 => 'AH', 35 => 'AI', 36=>'AJ', 37 => 'AK', 38 =>'AL',
            39 => 'AM', 40=>'AN', 41=>'AO',42=>'AP', 43=>'AQ', 44=>'AR',45=>'AS',
            46=>'AT', 47=> 'AU', 48=>'AV', 49=>'AW', 50=>'AX',51=>'AY', 52=>'AZ'
        };
        ESRI_Field_Mapping__mdt fieldMap = fieldMapping.get(sObjectName);
        String warningMessage = '';  //holds string that is the fieldName with error : 
        String newVal;
        String esriField;
        sObject errorAward = (sObject)recordsByIndex.get(Integer.valueOf(gc.OBJECTID));
        Integer ind = Integer.valueOf(gc.OBJECTID);
        map<String, Object> rowError = new map<String, Object>();//map of string / objects that details for each error.
        rowError.put('row', ind + startRow);
        rowError.put('column', columnLetters.get(headers.indexOf(fieldMap.address1__c) + startColumn));
        rowError.put('field', field);//throwing a null here.
        System.debug('errorAward.('+field+': ' + errorAward.get(field));
        System.debug('errorAward: '+ (errorAward));
        rowError.put('esriUsed', fieldMap.esriUsed__c);
        rowError.put('value', errorAward.get(field));//this is just saving the same value as what's in the address
        //go through the fields associated with addresses and add error msg that included suggested address.
        if(field == fieldMap.address1__c){
            //build specific error msg here.
            warningMessage += msg + ' ' + gc.Match_Addr;
        }
        else {
            warningMessage+= 'Suggested ' + msg + ': ';
        }

        if(field == fieldMap.address1__c){
            esriField = fieldMap.esriAdd1__c;
            newVal = gc.StAddr;
        } else if(field ==fieldMap.city__c){
            esriField = fieldMap.esriCity__c;
            newVal = gc.City;
        } else if(field==fieldMap.state__c){
            esriField = fieldMap.esriStateAbbr__c;
            newVal = gc.RegionAbbr;
        } else if(field==fieldMap.zip__c){
            esriField=fieldMap.esriZip__c;
            newVal = gc.Postal;
        } else{
            newVal = null;
        }
        if(field!=fieldMap.address1__c){  
            if(newVal!=''){
                warningMessage += newVal;
            }else{
                warningMessage = msg + ' not found';
            }
        }
        rowError.put('newValue', newVal);
        rowError.put('esriField', esriField);
        rowError.put('warningMessage', warningMessage);
        if(newVal == errorAward.get(field)){
            return null;
        }
        System.debug(rowError);
        return rowError;
    }
    
    //Function creates an address string to send to the mulesoft api at treasury.  A complete string should look like:
    // '[{"OBJECTID": 110,"CITY": "Arlington","State_Territory": "VA","Recipient_s_Street_Address": "5005 Columbia ","Postal_Code": "22294","PostalExt": ""}]' BS march 2022
    private static string buildAddressString(Map<String,Object> objRecord, Integer ObjectId, String sObjectName){
        String inputAddress1, inputAddress2, inputAddress3;
        String city, state, postCode;
        String regEx = '[\"\n\r]';
        ESRI_Field_Mapping__mdt fieldMap = fieldMapping.get(sObjectName);
        //if the country is outside of the US, do not check the address
        if(fieldMap.Country__c!=null&&fieldMap.Country__c!='' && objRecord.get(fieldMap.Country__c)!='US') return null;
        inputAddress1 = objRecord.get(fieldMap.address1__c) != null ? ((String)objRecord.get(fieldMap.address1__c)).replaceAll(regEx, '').capitalize() : '';
        inputAddress2 = objRecord.get(fieldMap.address2__c) != null ? ((String)objRecord.get(fieldMap.address2__c)).replaceAll(regEx, '').capitalize(): '';
        inputAddress3 = objRecord.get(fieldMap.address3__c) != null ? ((String)objRecord.get(fieldMap.address3__c)).replaceAll(regEx, '').capitalize(): '';
        city = objRecord.get(fieldMap.city__c) != null ? ((String)objRecord.get(fieldMap.city__c)).replaceAll(regEx, '').capitalize(): '';
        state = objRecord.get(fieldMap.state__c) != null ? ((String)objRecord.get(fieldMap.state__c)).replaceAll(regEx, '').capitalize(): '';
        postCode = objRecord.get(fieldMap.zip__c) != null ? ((String)objRecord.get(fieldMap.zip__c)).replaceAll(regEx, '').capitalize(): '';
        String addressString = '{"OBJECTID":'+ ObjectId + ',"CITY":"'+city+'","State_Territory":"'+state+'","Recipient_s_Street_Address":"'+inputAddress1 + ' ' + inputAddress2 + ' ' + inputAddress3 + '","Postal_Code":"'+ postCode+'","PostalExt":""},';
        System.debug('addressString = ' + addressString);
        return addressString;
    }
                    
    /*example json address request string.
    String testString = '[{"OBJECTID": 110,"City": "Elizabeth","State_Territory": "Nj","Recipient_s_Street_Address": "10 Elizabethtown Plaza, 6th Floor","Postal_Code": "07207","PostalExt": "3451"},'+
    '{"OBJECTID": 113,"City": "Roscommon","State_Territory": "MI","Recipient_s_Street_Address": "11628 King Road","Postal_Code": "48653","PostalExt": ""}]';
    */

    //Provide dummydata in the event that ESRIAPI Service is down.
    private static List<ESRIgeoCode> noDataReturned(Integer numberOfAddresses){
        List<ESRIgeoCode> dummydata = new List<ESRIgeoCode>();
            //test data bc treasury api is down.
        for(Integer i =0; i < numberOfAddresses; i++){
            ESRIgeoCode toReturn = new ESRIgeoCode();
            toReturn.StAddr = 'Address ' + i + ' No Response';
            toReturn.OBJECTID = String.valueOf(i);
            toReturn.City = 'No Response ' + i;
            toReturn.Postal = '';
            toReturn.PostalExt = '';
            toReturn.Match_Addr = 'ESRI API did not respond '+ i;
            toReturn.RegionAbbr = '';
            toReturn.xCord = 0;
            toReturn.yCord = 0;
            toReturn.score = 89;
            dummydata.add(toReturn);
        }
        return (dummydata);
    }
    @AuraEnabled
    public static boolean checkESRIActive(String objectApiName){
        try {
            ESRI_Field_Mapping__mdt fieldMap = fieldMapping.get(objectApiName);
            return fieldMap.Active__c;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    //object to hold returned ESRI Data
    global class ESRIgeoCode{
        public String OBJECTID {get;set;}
        public String Match_addr {get;set;}
        public Decimal score {get;set;}
        public String Region {get;set;}//State
        public String Subregion {get;set;}//county
        public String addrType {get;set;}//you don't need two of these.
        public String StAddr {get;set;} //street address.
        public String City {get;set;}
        public String RegionAbbr {get;set;} //state abbreviation
        public String Postal {get;set;}
        public String PostalExt {get;set;}
        public String addr_type {get;set;}//point address, street address
        public String status {get;set;}
        public Decimal xCord {get;set;} //long
        public Decimal yCord {get;set;}//lat

        public Map<String, Object> dataMap {
            get { // make the key the value of the field label of the metadata record - needed for GeocodingProcessBatchalbe.updateRecords
            if (dataMap == null) {
                dataMap = new Map<String, Object>();
            }
            return dataMap;
            }set;}
    }
    //Object to hold map of ESRI api settings
    private static Map<String, ESRI_Api_Setting__mdt> apiSettings {
        get {
            //populate only if apiSettings is null
            if (apiSettings == null) {
                apiSettings = new Map<String, ESRI_Api_Setting__mdt>();
                //Query the Custom Metadata and add it to the Map
                //Query against Custom Metadata does not count against the SOQL query Limit
                for (ESRI_Api_Setting__mdt setting : [Select DeveloperName,MasterLabel, Value__c from ESRI_Api_Setting__mdt]) {
                    apiSettings.put(setting.MasterLabel, setting);
                }
            }
            return apiSettings;
        }
        //Blank Setter Method
        set {
        }
    }
    //Object to hold map of ESRI field mappings
    private static Map<String, ESRI_Field_Mapping__mdt> fieldMapping {
        get{
            if(fieldMapping == null){
                fieldMapping = new Map<String, ESRI_Field_Mapping__mdt>();
                //query custom metadata and add to map - doesn't count against soql query limit
                for(ESRI_Field_Mapping__mdt fieldmap : [SELECT Object_Name__c, Active__c, address1__c, address2__c, address3__c, city__c, esriAdd1__c, esriCity__c, esriStateAbbr__c, esriUsed__c, esriZip__c, state__c, zip__c, zip_4__c, Country__c FROM ESRI_Field_Mapping__mdt]){
                    fieldMapping.put(fieldmap.Object_Name__c, fieldmap);
                }
            }
            return fieldMapping;
        }
        set{
        }
    }
   
}