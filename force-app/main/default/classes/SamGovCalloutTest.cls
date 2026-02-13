@isTest
private class SamGovCalloutTest {
    @isTest
    static void testValidateUEI() {
        // Mock HTTP Callout
        Application_for_Federal_Assistance__c app = [SELECT Id, Name, Organizational_UEI__c FROM Application_for_Federal_Assistance__c LIMIT 1];
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"uei": "123456", "status": "valid"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));
        
        SamGovCallout.UEIInput testInput = new SamGovCallout.UEIInput();
        testInput.apps = new List<Application_for_Federal_Assistance__c>();
        testInput.apps.add(app);
        //testInput.uei = '123456';
        List<SamGovCallout.UEIInput> inputList = new List<SamGovCallout.UEIInput>{ testInput };

        List<SamGovCallout.UEIResult> results = SamGovCallout.validateUEI(inputList);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertEquals(true, results[0].success, 'Success should be true');
        System.assertNotEquals(null, results[0].responseData, 'Response Data should not be null');
        System.assertEquals(null, results[0].errorMessage, 'Error Message should be null');
    }

    @isTest
    static void testValidateUEITwo() {
        // Mock HTTP Callout
        Application_for_Federal_Assistance__c app = [SELECT Id, Name, Organizational_UEI__c FROM Application_for_Federal_Assistance__c LIMIT 1];

        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"uei": "123456", "errorDetails": "valid"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));
        
        SamGovCallout.UEIInput testInput = new SamGovCallout.UEIInput();
        testInput.apps = new List<Application_for_Federal_Assistance__c>();
        testInput.apps.add(app);
        List<SamGovCallout.UEIInput> inputList = new List<SamGovCallout.UEIInput>{ testInput };
        for(Integer i = 0; i < 10; i++){ 
            inputList.add(testInput);
        }

        List<SamGovCallout.UEIResult> results = SamGovCallout.validateUEI(inputList);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(11, results.size(), 'There should be one result');
        System.assertEquals(false, results[0].success, 'Success should be true');
        // System.assertNotEquals(null, results[0].responseData, 'Response Data should not be null');
        System.assertNotEquals(null, results[0].errorMessage, 'Error Message should not be null');
        System.assertNotEquals(null, results[0].samValidationDataToCreate);
    }
    @isTest
    static void testValidateUEIHasSam() {
        // Mock HTTP Callout
        Application_for_Federal_Assistance__c app = [SELECT Id, Name, Organizational_UEI__c FROM Application_for_Federal_Assistance__c LIMIT 1];
        Sam_gov_Validation__c sam = new Sam_gov_Validation__c(Name = '123456', Application_for_Federal_Assistance__c = app.Id);
        insert sam;
        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"uei": "123456", "status": "valid"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));
        
        SamGovCallout.UEIInput testInput = new SamGovCallout.UEIInput();
        testInput.apps = new List<Application_for_Federal_Assistance__c>();
        testInput.apps.add(app);
        //testInput.uei = '123456';
        List<SamGovCallout.UEIInput> inputList = new List<SamGovCallout.UEIInput>{ testInput };

        List<SamGovCallout.UEIResult> results = SamGovCallout.validateUEI(inputList);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertEquals(true, results[0].success, 'Success should be true');
        System.assertNotEquals(null, results[0].responseData, 'Response Data should not be null');
        System.assertEquals(null, results[0].errorMessage, 'Error Message should be null');
    }
    @isTest
    static void testValidateUEITwoHasSam() {
        // Mock HTTP Callout
        Application_for_Federal_Assistance__c app = [SELECT Id, Name, Organizational_UEI__c FROM Application_for_Federal_Assistance__c LIMIT 1];
        Sam_gov_Validation__c sam = new Sam_gov_Validation__c(Name = '123456', Application_for_Federal_Assistance__c = app.Id);
        insert sam;

        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"uei": "123456", "errorDetails": "valid"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));
        
        SamGovCallout.UEIInput testInput = new SamGovCallout.UEIInput();
        testInput.apps = new List<Application_for_Federal_Assistance__c>();
        testInput.apps.add(app);
        List<SamGovCallout.UEIInput> inputList = new List<SamGovCallout.UEIInput>{ testInput };
        for(Integer i = 0; i < 10; i++){ 
            inputList.add(testInput);
        }

        List<SamGovCallout.UEIResult> results = SamGovCallout.validateUEI(inputList);
        Test.stopTest();

        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(11, results.size(), 'There should be one result');
        System.assertEquals(false, results[0].success, 'Success should be false');
        // System.assertNotEquals(null, results[0].responseData, 'Response Data should not be null');
        System.assertNotEquals(null, results[0].errorMessage, 'Error Message should not be null');
        System.assertNotEquals(null, results[0].samValidationDataToCreate);
    }
    @isTest
    static void testValidateMultiPass() {
        // Mock HTTP Callout
        List<Application_for_Federal_Assistance__c> apps = [SELECT Id, Name, Organizational_UEI__c FROM Application_for_Federal_Assistance__c];
        Sam_gov_Validation__c sam = new Sam_gov_Validation__c(Name = '123456', Application_for_Federal_Assistance__c = apps[0].Id);
        insert sam;

        Set<Id> appIds = (new Map<Id, Application_for_Federal_Assistance__c>(apps)).keySet();

        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"uei": "123456", "status": "valid"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));
        
        SamGovCallout.UEIInput testInput = new SamGovCallout.UEIInput();
        testInput.apps = new List<Application_for_Federal_Assistance__c>();
        testInput.apps.add(apps[0]);
        testInput.apps.add(apps[1]);
        List<SamGovCallout.UEIInput> inputList = new List<SamGovCallout.UEIInput>{ testInput };
        // for(Integer i = 0; i < 10; i++){ 
        //     inputList.add(testInput);
        // }
        // inputList.add(testInput);
        List<SamGovCallout.UEIResult> results = SamGovCallout.validateUEI(inputList);
        Test.stopTest();
        List<SAM_gov_Validation__C> samGovs = [SELECT Id, Name FROM Sam_Gov_Validation__c WHERE Application_for_Federal_Assistance__c in :appIds];
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertEquals(true, results[0].success, 'Success should be true');
        // System.assertNotEquals(null, results[0].responseData, 'Response Data should not be null');
        System.assertEquals(null, results[0].errorMessage, 'Error Message should be null');
        System.assertEquals(null, results[0].samValidationDataToCreate);
        System.assertEquals(2, samGovs.size(), 'There should be two SAM Gov Validation records.');
    }

    @isTest
    static void testValidateMultiFail() {
        // Mock HTTP Callout
        List<Application_for_Federal_Assistance__c> apps = [SELECT Id, Name, Organizational_UEI__c FROM Application_for_Federal_Assistance__c];
        Sam_gov_Validation__c sam = new Sam_gov_Validation__c(Name = '123456', Application_for_Federal_Assistance__c = apps[0].Id);
        insert sam;

        Set<Id> appIds = (new Map<Id, Application_for_Federal_Assistance__c>(apps)).keySet();

        Test.startTest();
        HttpResponse mockResponse = new HttpResponse();
        mockResponse.setStatusCode(200);
        mockResponse.setBody('{"uei": "123456", "errorDetails": "valid"}');
        Test.setMock(HttpCalloutMock.class, new MockHttpCalloutImpl(mockResponse));
        
        SamGovCallout.UEIInput testInput = new SamGovCallout.UEIInput();
        testInput.apps = new List<Application_for_Federal_Assistance__c>();
        testInput.apps.add(apps[0]);
        testInput.apps.add(apps[1]);
        List<SamGovCallout.UEIInput> inputList = new List<SamGovCallout.UEIInput>{ testInput };
        // for(Integer i = 0; i < 10; i++){ 
        //     inputList.add(testInput);
        // }
        // inputList.add(testInput);
        List<SamGovCallout.UEIResult> results = SamGovCallout.validateUEI(inputList);
        Test.stopTest();
        List<SAM_gov_Validation__C> samGovs = [SELECT Id, Name FROM Sam_Gov_Validation__c WHERE Application_for_Federal_Assistance__c in :appIds];
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'There should be one result');
        System.assertEquals(true, results[0].success, 'Success should be true');
        // System.assertNotEquals(null, results[0].responseData, 'Response Data should not be null');
        System.assertEquals(null, results[0].errorMessage, 'Error Message should be null');
        System.assertEquals(null, results[0].samValidationDataToCreate);
        System.assertEquals(2, samGovs.size(), 'There should be two SAM Gov Validation records.');
    }
    @TestSetup
    static void makeData(){
        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Organizational_UEI__c = '123456'
        );
        insert app;
        Application_for_Federal_Assistance__c app2 = new Application_for_Federal_Assistance__c(
            Organizational_UEI__c = '1234567'
        );
        insert app2;
    }

    // Mock HTTP Callout Implementation
    private class MockHttpCalloutImpl implements HttpCalloutMock {
        private HttpResponse mockResponse;

        public MockHttpCalloutImpl(HttpResponse response) {
            this.mockResponse = response;
        }

        public HttpResponse respond(HttpRequest req) {
            return mockResponse;
        }
    }
}