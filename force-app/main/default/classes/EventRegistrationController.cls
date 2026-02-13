public with sharing class EventRegistrationController {

    @AuraEnabled(cacheable=true)
    public static List<DateSlot> getRoomAvailibility(String eventId, Integer blockDuration){
        /*
            block duration should be in minutes - default 30
        */
        blockDuration = blockDuration != null && blockDuration !=0 ? blockDuration : 30;
        try {
            Map<String, DateSlot> dateSlots = new Map<String, DateSlot>();
            List<G20_Event_Location__c> eventRooms = [SELECT Id, Event_Location_Date__c, Event_Availability_Start__c, Event_Availability_End__c, Room__r.Max_Occupants__c, Room__r.Name,
                (SELECT Id, Status__c, End_Date_Time__c, Start_Date_Time__c FROM G20_Meetings__r)
            FROM G20_Event_Location__c
            WHERE G20_Event__c =: eventId
            AND Hide_from_Portal__c = false
            Order By Event_Location_Date__c, Display_Order__c ASC];

            List<AggregateResult> ars = [SELECT MIN(Event_Availability_Start__c) start, MAX(Event_Availability_End__c) end, Event_Location_Date__c FROM G20_Event_Location__c WHERE G20_Event__c =: eventId GROUP BY Event_Location_Date__c Order By Event_Location_Date__c ASC];
            for(AggregateResult ar : ars){
                DateTime startT = DateTime.valueOf(ar.get('start'));
                DateTime endT  = DateTime.valueOf(ar.get('end'));
                DateSlot ds = new DateSlot(Date.valueOf(ar.get('Event_Location_Date__c')).format(), startT, endT);
                ds.roomNames = new List<Map<String,String>>();
                Integer blockCount = (Integer) ((endT.getTime() - startT.getTime()))/1000/60/blockDuration;
                Map<String, TimeSlot> timeSlots =new Map<String, TimeSlot>();

                for(Integer i = 0; i<blockCount; i++){
                    Integer startOffset = i*blockDuration;
                    DateTime startBlockDT = startT.addMinutes(startOffset) ;
                    DateTime endBlockDT = startT.addMinutes(startOffset + blockDuration);
                    Time startBlockTime = startBlockDT.timeGmt();
                    TimeSlot ts = new TimeSlot(startBlockDT, startBlockDT.addMinutes(blockDuration), String.valueOf(startBlockTime), String.valueOf(startBlockTime.addMinutes(blockDuration)), endBlockDT.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ'),startBlockTime, startBlockTime.addMinutes(blockDuration));
                    ts.timeBlocks = new List<TimeBlock>();
                    timeSlots.put(startBlockDT.format(), ts);
                }
                ds.timeSlots = timeSlots;
                dateSlots.put(Date.valueOf(ar.get('Event_Location_Date__c')).format(), ds);
            }
            for(G20_Event_Location__c loc: eventRooms){
                System.debug('loc--');
                System.debug(loc);
                DateSlot ds = dateSlots.get(loc.Event_Location_Date__c.format());

                ds.roomNames.add(new Map<String,String>{'name'=>loc.Room__r.Name, 'capacity'=>String.valueOf(loc.Room__r.Max_Occupants__c) });
                Map<String, TimeSlot> timeSlots = ds.timeSlots;


                for(String tsKey : timeSlots.keySet()){
                    TimeSlot ts = timeSlots.get(tsKey);
                    String blockId = loc.Event_Location_Date__c + '#' + loc.Id + '#' + String.valueOf(ts.startDateTime.time()) + '#' + String.valueOf(ts.endDateTime.time());
                
                    Boolean available = ts.startDateTime>=loc.Event_Availability_Start__c && ts.endDateTime <=loc.Event_Availability_End__c;
                    for(G20_Meeting__c meeting : loc.G20_Meetings__r){
                        available = (meeting.Start_Date_Time__c<= ts.startDateTime && meeting.Start_Date_Time__c<ts.endDateTime)&&((meeting.End_Date_Time__c> ts.startDateTime && meeting.End_Date_Time__c>=ts.endDateTime)||(ts.startDateTime < meeting.End_Date_Time__c && ts.endDateTime > meeting.End_Date_Time__c))?false : available;
                    }
                    TimeBlock tb = new TimeBlock(ts.startDateTime.time(), ts.endDateTime.time(), blockId, available, !available, loc.Id, loc.Room__r.Max_Occupants__c, loc.Room__r.Name);
                    ts.timeBlocks.add(tb);

                }    

            }
            return dateSlots.values();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled(cacheable=true)
    public static List<G20_Meeting__c> getMeetings(String contactId){
        Contact con = [SELECT AccountId, Delegation_International_Organization__c FROM Contact WHERE Id =: contactId LIMIT 1];
        Id accId = con.AccountId;
        String delegation = con.Delegation_International_Organization__c;
        List<G20_Meeting__c> meetings = [SELECT Room_Name__c, Name, Id, Status__c, End_Date_Time__c, Start_Date_Time__c, Delegation__c FROM G20_Meeting__c WHERE Meeting_Contact__r.AccountId =: accId AND Delegation__c =: delegation ORDER BY Start_Date_Time__c ASC];
        return meetings;
    }
    public class DateSlot{
        @AuraEnabled
        public String eventDate {get;set;}
        
        @AuraEnabled
        public Map<String, TimeSlot> timeSlots {get;set;}

        @AuraEnabled
        public Datetime startTime {get;set;}

        @AuraEnabled
        public Datetime endTime {get;set;}

        @AuraEnabled
        public List<Map<String, String>> roomNames {get;set;}


        public DateSlot(String eventDate, Datetime startTime, Datetime endTime){
            this.eventDate = eventDate;
            this.startTime = startTime;
            this.endTime = endTime;
        }
    }
    public class TimeSlot{
        @AuraEnabled
        public Datetime startDateTime {get;set;}
        @AuraEnabled
        public Datetime endDateTime {get;set;}
        @AuraEnabled
        public Time startTimeT {get;set;}
        @AuraEnabled
        public Time endTimeT {get;set;}
        @AuraEnabled
        public String startTime {get;set;}
        @AuraEnabled
        public String endTime {get;set;}
        @AuraEnabled
        public List<TimeBlock> timeBlocks {get;set;}
        @AuraEnabled
        public String endTimeDisplay {get;set;}

        public TimeSlot(Datetime startDateTime, Datetime endDateTime, String startTime, String endTime, String endTimeDisplay, Time startTimeT, Time endTimeT){
            this.startDateTime = startDateTime;
            this.endDateTime = endDateTime;
            this.startTime = startTime;
            this.endTime = endTime;
            this.endTimeDisplay = endTimeDisplay;
            this.startTimeT = startTimeT;
            this.endTimeT = endTimeT;
        }
    }
    public class TimeBlock{
        @AuraEnabled
        public Time startTime {get;set;}
        @AuraEnabled
        public Time endTime {get;set;}
        @AuraEnabled
        public String blockId {get;set;}
        @AuraEnabled
        public Boolean available {get;set;}
        @AuraEnabled
        public Boolean disabled {get;set;}
        @AuraEnabled
        public Id eventLoc {get;set;}
        @AuraEnabled
        public Decimal capacity{get;set;}
        @AuraEnabled
        public String roomName{get;set;}
        @AuraEnabled
        public Boolean selected{get;set;}
        @AuraEnabled
        public String displayClass{get;set;}
        
        public TimeBlock(Time startTime, Time endTime, String blockId, Boolean available, Boolean disabled, Id eventLoc, Decimal capacity, String roomName){
            this.startTime = startTime;
            this.endTime = endTime;
            this.blockId = blockId;
            this.available = available;
            this.disabled = disabled;
            this.eventLoc = eventLoc;
            this.capacity = capacity;
            this.roomName = roomName;
            this.selected = false;
            this.displayClass = disabled ? 'disabled' : 'standard';
        }
    }


}