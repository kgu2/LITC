/**
 * Trigger handler class for the Review_Card__c and NTA_Review__c objects
 * Contains logic to generating review answers, updating lookups, and maintaining application data
 */
public with sharing class Review_Card_Handler {

    /**
     * Processes after insert logic for Review_Card__c. Creates review answers and populates Level 2 lookups on level 1 review ansers
     * @param reviewCards List of new Review_Card__c records
     */
    public static void afterInsert(List<Review_Card__c> reviewCards) {
        createReviewAnswers(reviewCards);
        populateLevelTwoLookups(reviewCards);
    }

    /**
     * Creates Review_Answer__c for each review question when review cards are generated
     * @param reviewCards List of new Review_Card__c records
     */
    private static void createReviewAnswers(List<Review_Card__c> reviewCards){ 
        // grab template Ids
        set<Id> templateIds = new set<Id>();
        for (Review_Card__c card : reviewCards){
            templateIds.add(card.Review_Template__c);
        }
               
        // get review questions
        List<Review_Question__c> questions = [SELECT Id, Review_Template__c, Question_ID__c, Name, Section__c FROM Review_Question__c WHERE Review_Template__c IN : templateIds];
    
        map<Id, List<Review_Question__c>> templateIdToQuestions = new map<Id, List<Review_Question__c>>();
        Map<Id, Set<String>> templateIdToSections = new Map<Id, Set<String>>();

        // maps template Id to review questions and template Id to unique sections
        for (Review_Question__c question : questions){
            if (templateIdToQuestions.get(question.Review_Template__c) == null){ 
                templateIdToQuestions.put(question.Review_Template__c, new list<Review_Question__c>());
            }
            templateIdToQuestions.get(question.Review_Template__c).add(question);

            if (templateIdToSections.get(question.Review_Template__c) == null){ 
                templateIdToSections.put(question.Review_Template__c, new Set<String>());
            }
            templateIdToSections.get(question.Review_Template__c).add(question.Section__c);
        }
        
        list<Review_Answer__c> reviewAnswers = new list<Review_Answer__c>();

        // create review answers for each review question
        for (Review_Card__c card : reviewCards){
            if(templateIdToQuestions.get(card.Review_Template__c) != null){
                list<Review_Question__c> cardQuestions = templateIdToQuestions.get(card.Review_Template__c);
                for (Review_Question__c question : cardQuestions){ 
                    reviewAnswers.add(new Review_Answer__c(Review_Card__c = card.Id, Review_Question__c = question.Id, Name = question.Question_ID__c));
                }    
            } 

            //create an additional review answer for each unique section
            if(templateIdToSections.get(card.Review_Template__c) != null){
                for(String section : templateIdToSections.get(card.Review_Template__c)){ 
                    reviewAnswers.add(new Review_Answer__c(Review_Card__c = card.Id, Name = 'Summary', Section_Summary__c = section, Summary__c = true));
                }
            }
        }

        insert reviewAnswers;
    }

    /**
     * When Level 2 Review Cards are created, link answers for all level 1 review cards to Level 2 answers
     * Also prepopulate the level 2 score if all Level 1 answers are the same
     * @param reviewCards List of new Review_Card__c records
     */
    private static void populateLevelTwoLookups(List<Review_Card__c> reviewCards) {
        Id levelOneRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 1').getRecordTypeId();
        Id levelTwoRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 2').getRecordTypeId();

        // get lvl 2 review card ids
        Set<Id> level2CardIds = new Set<Id>();
        for (Review_Card__c rc : reviewCards) {
            if (rc.recordTypeId == levelTwoRecordType) {
                level2CardIds.add(rc.Id);
            }
        }

        if (level2CardIds.isEmpty()) return;
    
        // get all level 2 review answers and map them by question id
        Map<String, Review_Answer__c> questionToLevel2AnswerMap = new Map<String, Review_Answer__c>();

        List<Review_Answer__c> level2Answers = [SELECT Id, Question_ID__c, Review_Card__c, Score__c  FROM Review_Answer__c WHERE Review_Card__c IN :level2CardIds ORDER BY Question_ID__c];
        for (Review_Answer__c answer : level2Answers) {
            questionToLevel2AnswerMap.put(answer.Question_ID__c, answer);
        }
    
        //  get level 1 review cards submitted linked to same NTA record
        Set<Id> applicationIds = new Set<Id>();
        for (Review_Card__c rc : reviewCards) {
            applicationIds.add(rc.NTA_Review__c);
        }

        List<Review_Card__c> existingLevel1Cards = [SELECT Id, Name, NTA_Review__c FROM Review_Card__c WHERE NTA_Review__c IN :applicationIds AND RecordTypeId = :levelOneRecordType AND Status__c =: 'Submitted'];
    
        if (existingLevel1Cards.isEmpty()) return;
    
        // Maps level 1 review cards to review answers
        Map<Id, List<Review_Answer__c>> level1CardToAnswersMap = new Map<Id, List<Review_Answer__c>>();
    
        List<Review_Answer__c> level1Answers = [SELECT Id, Question_ID__c, Review_Card__c, Level_2_Review_Answer__c, Score__c  FROM Review_Answer__c WHERE Review_Card__c IN :existingLevel1Cards ORDER BY Question_ID__c];
    
        for (Review_Answer__c answer : level1Answers) {
            if (!level1CardToAnswersMap.containsKey(answer.Review_Card__c)) {
                level1CardToAnswersMap.put(answer.Review_Card__c, new List<Review_Answer__c>());
            }
            level1CardToAnswersMap.get(answer.Review_Card__c).add(answer);
        }

        // populates all Level 1 Review Answers lookup with the level 2 review answer
        List<Review_Answer__c> answersToUpdate = new List<Review_Answer__c>();
    
        for (List<Review_Answer__c> answers : level1CardToAnswersMap.values()) {
            for (Review_Answer__c answer : answers) {
                if (questionToLevel2AnswerMap.containsKey(answer.Question_ID__c)) {
                    answer.Level_2_Review_Answer__c = questionToLevel2AnswerMap.get(answer.Question_ID__c).Id;
                    answersToUpdate.add(answer);
                }
            }
        }
    
        if (!answersToUpdate.isEmpty()) {
            update answersToUpdate;
        }    
    

        Map<String, Set<Decimal>> questionToLevel1AnswersMap = new Map<String, Set<Decimal>>();
    
        // map question ID to unique scores
        for (Review_Answer__c answer : level1Answers) {
            if (!questionToLevel1AnswersMap.containsKey(answer.Question_ID__c)) {
                questionToLevel1AnswersMap.put(answer.Question_ID__c, new Set<Decimal>());
            }
            questionToLevel1AnswersMap.get(answer.Question_ID__c).add(answer.Score__c);
        }
    
        Map<String, Decimal> questionToMatchingScoreMap = new Map<String, Decimal>(); 

        // Checks Level 1 Scores are the same across all review cards and maps question Id to that score
        for (String questionId : questionToLevel1AnswersMap.keySet()) {
            Set<Decimal> uniqueAnswers = questionToLevel1AnswersMap.get(questionId);
            if (uniqueAnswers.size() == 1) { 
                questionToMatchingScoreMap.put(questionId, uniqueAnswers.iterator().next());
            }
        }
    
        List<Review_Answer__c> level2AnswersToUpdate = new List<Review_Answer__c>();
    
        // Update Level 2 review answers if lvl 1 review answers are the same
        for (String questionId : questionToMatchingScoreMap.keySet()) {
            if (questionToLevel2AnswerMap.containsKey(questionId)) {
                Review_Answer__c level2Answer = questionToLevel2AnswerMap.get(questionId);
                level2Answer.Score__c = questionToMatchingScoreMap.get(questionId);
                level2AnswersToUpdate.add(level2Answer);
            }
        }

        if (!level2AnswersToUpdate.isEmpty()) {
            update level2AnswersToUpdate;
        }
    }

    /**
     * Processes after update logic for Review_Card__c. When Level 2 review cards are updated, update the related application.
     * @param reviewCards List of updated Review_Card__c
     */
    public static void afterUpdate(List<Review_Card__c> reviewCards) {
        Id levelTwoRecordType = Schema.SObjectType.Review_Card__c.getRecordTypeInfosByName().get('Level 2').getRecordTypeId();

        Map<Id, String> reviewCardWeaknesses = new Map<Id, String>();

        Map<Id, Review_Card__c> ntaToReviewCard = new Map<Id, Review_Card__c>();
    
        // map NTA record to level 2 review card weakness
        for (Review_Card__c reviewCard : reviewCards) {
            if (reviewCard.NTA_Review__c != null && reviewCard.RecordTypeId == levelTwoRecordType) {
                reviewCardWeaknesses.put(reviewCard.NTA_Review__c, reviewCard.Weaknesses__c);

                ntaToReviewCard.put(reviewCard.NTA_Review__c, reviewCard);
            }
        }

        Map<Id, String> appWeaknessUpdates = new Map<Id, String>();

        List<NTA_Review__c> ntaRecords = new List<NTA_Review__c>();

        // map application to weaknesses field
        for (NTA_Review__c ntaReview : [SELECT Id, Application_for_Federal_Assistance__c, Level_2_Review_Card_Weighted_Score__c, Review_Status__c FROM NTA_Review__c WHERE Id IN :reviewCardWeaknesses.keySet()]) {
            if (ntaReview.Application_for_Federal_Assistance__c != null) {
                appWeaknessUpdates.put(ntaReview.Application_for_Federal_Assistance__c, reviewCardWeaknesses.get(ntaReview.Id));
            }

            if(ntaToReviewCard.get(ntaReview.Id).get('Weighted_Score__c') != null){ 
                ntaReview.Level_2_Review_Card_Weighted_Score__c = (Double)ntaToReviewCard.get(ntaReview.Id).get('Weighted_Score__c');

                ntaRecords.add(ntaReview);
            }

            if(ntaReview.Review_Status__c == 'Technical Review Started' && ntaToReviewCard.get(ntaReview.Id).get('Status__c') == 'Submitted'){ 
                ntaReview.Review_Status__c = 'Technical Review Submitted';
                ntaRecords.add(ntaReview);
            }
                
        }

        if(!ntaRecords.isEmpty()){ 
            update ntaRecords;
        }

        // update applications
        if (!appWeaknessUpdates.isEmpty()) {
            List<Application_for_Federal_Assistance__c> appsToUpdate = new List<Application_for_Federal_Assistance__c>();
            
            for (Application_for_Federal_Assistance__c app : [SELECT Id, Lvl_2_Review_Card_Weaknesses__c FROM Application_for_Federal_Assistance__c WHERE Id IN :appWeaknessUpdates.keySet()]) {
                app.Lvl_2_Review_Card_Weaknesses__c = appWeaknessUpdates.get(app.Id);
                appsToUpdate.add(app);
            }

            if (!appsToUpdate.isEmpty()) {
                update appsToUpdate;
            }
        }
    }
}