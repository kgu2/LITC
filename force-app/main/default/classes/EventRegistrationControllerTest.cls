@isTest
public with sharing class EventRegistrationControllerTest {
    public EventRegistrationControllerTest() {

    }
    @TestSetup
    static void makeData(){
        G20_Event__c event = new G20_Event__c();
        event.Name = 'Test Event';
        event.Start_Date__c = Date.newInstance(2025, 12, 12);
        event.End_Date__c = Date.newInstance(2025, 12, 13);
        insert event;

        G20_Room__c room = new G20_Room__c();
        room.Name = 'Room 1';
        room.Max_Occupants__c = 10;
        insert room;

        G20_Event_Location__c er = new G20_Event_Location__c();
        er.Room__c = room.Id;
        er.G20_Event__c = event.Id;
        er.Name = 'Event Name';
        er.Event_Availability_Start__c = DateTime.newInstance(2025, 12, 12, 07, 00, 00);
        er.Event_Availability_End__c = DateTime.newInstance(2025, 12, 12, 19, 00, 00);
        insert er;
        


        Account acc = new Account();
        acc.Name = 'Test';
        insert acc;

        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName = 'Test';
        con.Account = acc;
        insert con;

        G20_Meeting__c meeting = new G20_Meeting__c();
        meeting.Event_Location__c = er.Id;
        meeting.Start_Date_Time__c = DateTime.newInstance(2025, 12, 12, 16, 37, 55);
        meeting.End_Date_Time__c = DateTime.newInstance(2025, 12, 12, 17, 37, 55);
        meeting.Meeting_Contact__c = con.Id;
        insert meeting;

    }
    @isTest
    static void getEventAvailibility(){
        G20_Event__c event = [SELECT Id FROM G20_Event__c LIMIT 1];
        String eventId = event.Id;
        //List<G20_Event_Location__c> meetings = EventRegistrationController.getRoomAvailibility((String)event.Id);
        List<EventRegistrationController.DateSlot> locs = EventRegistrationController.getRoomAvailibility(eventId, 30);
    }

    @isTest
    static void getMeetings(){
        Contact con = [SELECT Id FROM Contact LIMIT 1];
        List<G20_Meeting__c> meetings = EventRegistrationController.getMeetings((String)con.Id);
    }
}