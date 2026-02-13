@isTest
public with sharing class ReviewTest {
    @testSetup
    static void setupTestData() {
        // Create a Review Template
        Review_Template__c template = new Review_Template__c(Name = 'LITC Application template');
        insert template;

        Review_Template__c legacyTemplate = new Review_Template__c(Name = 'LITC Legacy Application Template');
        insert legacyTemplate;

        // Create Review Questions
        List<Review_Question__c> questions = new List<Review_Question__c>();
        for (Integer i = 0; i < 3; i++) {
            questions.add(new Review_Question__c(Name = 'Question ' + i, Review_Template__c = template.Id, Question_ID__c = 'Q' + i));
        }
        insert questions;

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Type_of_Applicant_1__c = 'M. Nonprofit with 501(c) status',
            Email__c = 'test@example.com',
            Organizational_UEI__c = 'UEI123456789',
            UEI_Sam_gov_Validation_Status__c = true);
        insert app;

        // Create NTA Review
        NTA_Review__c ntaReview = new NTA_Review__c(Review_Status__c = 'Intake Review Started', Application_for_Federal_Assistance__c = app.Id);
        insert ntaReview;

        Id levelOneRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 1').getRecordTypeId();
        Id levelTwoRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 2').getRecordTypeId();

        // Create Level 1 Review Cards
        List<Review_Card__c> reviewCards = new List<Review_Card__c>();
        for (Integer i = 0; i < 2; i++) {
            reviewCards.add(new Review_Card__c(Name = 'Review Card ' + i, Review_Template__c = template.Id, NTA_Review__c = ntaReview.Id,RecordTypeId = levelOneRecordType,Status__c = 'Submitted' ));
        }
        insert reviewCards;

        // Create Level 2 Review Cards
        List<Review_Card__c> reviewCards2 = new List<Review_Card__c>();
        for (Integer i = 0; i < 2; i++) {
            reviewCards2.add(new Review_Card__c(Name = 'Review Card ' + i, Review_Template__c = template.Id, NTA_Review__c = ntaReview.Id,RecordTypeId = levelTwoRecordType,Status__c = 'Submitted' ));
        }
        insert reviewCards2;     
        
        update reviewCards2;


        Staff_Review__c sr1 = new Staff_Review__c(NTA_Review__c = ntaReview.Id,
            recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Advocacy Analyst Review').getRecordTypeId());
        insert sr1;

        Staff_Review__c sr2 = new Staff_Review__c(NTA_Review__c = ntaReview.Id, recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Budget Analyst Review').getRecordTypeId());
        insert sr2;

        Staff_Review__c sr3= new Staff_Review__c(NTA_Review__c = ntaReview.Id, recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Program Office Review').getRecordTypeId());
        insert sr3;

        Staff_Review__c sr4 = new Staff_Review__c(NTA_Review__c = ntaReview.Id, Program_Office_Review__c = sr3.Id, AA_Narrative_Summary__c='test', Reviewing_Official_Summary__c = 'test', recordTypeId = Schema.SObjectType.Staff_Review__c.getRecordTypeInfosByName().get('Reviewing Official Review').getRecordTypeId());
        insert sr4;

 
        update sr4;

        update sr1;
    }

    @isTest
    static void testAfterInsertReviewCardHandler() {
        List<Review_Card__c> newReviewCards = [SELECT Id,Review_Template__c,RecordTypeId,NTA_Review__c FROM Review_Card__c];
        Test.startTest();
        Review_Card_Handler.afterInsert(newReviewCards);
        Test.stopTest();

       // System.assertEquals(6, [SELECT COUNT() FROM Review_Answer__c], 'Review answers should be created.');
    }

    @isTest
    static void testAfterUpdateReviewCardHandler() {
        List<Review_Card__c> newReviewCards = [SELECT Id,Review_Template__c,RecordTypeId,NTA_Review__c, Weaknesses__c, Weighted_Score__c FROM Review_Card__c];
        Test.startTest();
        Review_Card_Handler.afterUpdate(newReviewCards);
        Test.stopTest();
    }

    @isTest
    static void testProcessNTAReview() {
        List<NTA_Review__c> newReviews = [SELECT Id,Application_for_Federal_Assistance__c,Review_Status__c, Version__c, NTA_Denial_Reasons__c,Efficiency_Score__c  FROM NTA_Review__c];
        Map<Id, NTA_Review__c> oldReviewsMap = new Map<Id, NTA_Review__c>();
        
        Test.startTest();
        NTAReviewTriggerHandler.processNTAReview(newReviews, oldReviewsMap);
        Test.stopTest();
        
        //System.assertEquals(3, [SELECT COUNT() FROM Review_Card__c WHERE Status__c = 'Not Submitted']);
    }

    @isTest
    static void testNTAReviewTrigger() {
        NTA_Review__c ntaReview = [SELECT Id FROM NTA_Review__c LIMIT 1];
        ntaReview.Review_Status__c = 'Passed Intake Review';
        Test.startTest();
        update ntaReview;
        Test.stopTest();
        
        System.assertEquals('Passed Intake Review', [SELECT Review_Status__c FROM NTA_Review__c WHERE Id = :ntaReview.Id].Review_Status__c);

        Application_for_Federal_Assistance__c myApp = new Application_for_Federal_Assistance__c();
        insert myApp;

        NTA_Review__c test = new NTA_Review__c(Application_for_Federal_Assistance__c = myApp.Id);
        insert test;

        test.Review_Status__c = 'Passed Intake Review';
        update test;
    }

    @isTest
    static void testGetQuestions() {
            Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Type_of_Applicant_1__c = 'M. Nonprofit with 501(c) status',
            Email__c = 'test@example.com',
            Organizational_UEI__c = 'UEI123456789',
            UEI_Sam_gov_Validation_Status__c = true);
            insert app;

            Legacy_13424_Application__c legacy = new Legacy_13424_Application__c(Application_for_Federal_Assistance__c = app.Id);
            insert legacy;
        List<Review_Card__c> reviewCards = [SELECT Id FROM Review_Card__c];
        List<String> fieldNames = new List<String>{ 'Name' };
        Test.startTest();
        List<Review_Answer__c> questions = ReviewCardController.getQuestions(reviewCards[0].Id);
        ReviewCardController.getApplicationFields(app.Id, fieldNames);
        ReviewCardController.getLevel2RCs(app.Id);
        ReviewCardController.getLevel1RCs(app.Id);
        ReviewCardController.getSummaryQuestions(app.Id);
        ReviewCardController.getLegacyApplicationFields(app.Id, new List<String>{'Name'});
        Test.stopTest();
        
        System.assertNotEquals(null, questions, 'Questions should be returned.');
    }

    @isTest
    static void testCreateLevel2RC() {
        List<NTA_Review__c> reviews = [SELECT Id FROM NTA_Review__c];
        Test.startTest();
        String newRCId = ReviewCardController.createLevel2RC(reviews[0].Id);
        Test.stopTest();

        System.assertNotEquals(null, newRCId, 'A Level 2 Review Card should be created.');
    }

    @isTest
    static void testApplicationReviewTrigger() {

        Application_for_Federal_Assistance__c app = new Application_for_Federal_Assistance__c(
            Type_of_Application__c = 'New',
            SF424_Status__c = 'In Progress',
            Form_13424_Status__c = 'In Progress',
            Type_of_Applicant_1__c = 'M. Nonprofit with 501(c) status',
            Email__c = 'test@example.com',
            Organizational_UEI__c = 'UEI123456789',
            UEI_Sam_gov_Validation_Status__c = true);
            insert app;

        RegulatoryAuthorizationType regauthtype = new RegulatoryAuthorizationType(Name='Fee-based Financial Institution',RegulatoryAuthCategory='License');
        insert regauthtype;

        id regauthtypeId = regauthtype.id;

        IndividualApplication individualApp = new IndividualApplication(
            ApplicationName = app.Name,
            Status = 'In Progress',
            Category = 'Permit',
            LicenseTypeId = regauthtype.id
        );
        insert individualApp;

        List<ApplicationReview> appReviews = new List<ApplicationReview>();
        appReviews.add(new ApplicationReview(
            ApplicationId = individualApp.id,Intake_Status__c = 'Intake Needs Review', 
            Application_for_Federal_Assistance__c = app.Id,
            NTA_Review__c = [SELECT Id FROM NTA_Review__c LIMIT 1].Id));
        insert appReviews;
        
        Map<Id, ApplicationReview> oldMap = new Map<Id, ApplicationReview>(appReviews);
        for (ApplicationReview ar : appReviews) {
            ar.Intake_Status__c = 'Passed Intake Review';
        }

        Test.startTest();
        update appReviews;
        Test.stopTest();

        System.assertEquals(1, [SELECT COUNT() FROM NTA_Review__c WHERE Review_Status__c = 'Passed Intake Review']);
    }
}