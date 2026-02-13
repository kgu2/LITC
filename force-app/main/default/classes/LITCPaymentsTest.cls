@isTest
public with sharing class LITCPaymentsTest {

    @isTest
    static void setupTestData() {
        LITC_Payment__c payment = new LITC_Payment__c(Document_Number__c='123');
        insert payment;
    }
}