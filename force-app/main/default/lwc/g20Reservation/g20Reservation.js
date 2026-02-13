import { LightningElement, api, track, wire } from 'lwc';
import getRoomAvailibility from '@salesforce/apex/EventRegistrationController.getRoomAvailibility';
import getMeetings from '@salesforce/apex/EventRegistrationController.getMeetings';
import { refreshApex } from '@salesforce/apex';
import { getWaveTemplateReleaseNotes } from 'lightning/analyticsWaveApi';

const columns = [
    { label: 'Meeting name', fieldName: 'Name', type: 'text' },
    { label: 'Room', fieldName: 'Room_Name__c', type: 'text' },
    {
        label: 'Status',
        fieldName: 'Status__c',
        type: 'text',
    },
    {
        label: 'Start',
        fieldName: 'Start_Date_Time__c',
        type: 'date',
        typeAttributes: {
            month:"short",
            year:"numeric",
            day:"numeric",
            hour:"numeric",
            minute:"2-digit",
            timeZoneName:"short"
            
        }
    },
    {
        label: 'End',
        fieldName: 'End_Date_Time__c',
        type: 'date',
        typeAttributes: {
            month:"short",
            year:"numeric",
            day:"numeric",
            hour:"numeric",
            minute:"2-digit",
            timeZoneName:"short"
            
        }
    }
];
export default class G20Reservation extends LightningElement {
    @api eventId;
    @api contactId;

    @track roomAvailResults;
    @track roomAvailData;
    @track roomAvailStatic;

    @track meetingsResults;
    @track meetings;
    @track showTable = false;

    @track selectedSlots = [];
    columns = columns;

    //filters
    @track dayOptions = [];
    @track selectedButtons = [];
    @track selectedRooms = [];
    @track roomOptions = [];
    @track filterCapacity;
    /*
    //Structure for table:
    All data: [
        Date 1:{
            TimeSlots:[
                TimeSlot1:{
                    StartTime: XX:XX.XX
                    EndTime: XX:XX.XX
                    EventBlocks:[
                        Block 1:{
                            Room Name:
                            Capacity:
                            Available?
                        },
                        Block 2:{
                            Room Name:
                            Capacity:
                            Available?
                        }
                    ]
                },
                TimeSlot2:{

                }
            ]
        }
        Date 2:{

        }
    ]
    */
    @wire(getRoomAvailibility,{blockDuration:30})
    setRoomAvailibility(results){
        this.roomAvailResults = results;
        let data = results.data;
        let error = results.error;
        if(data){
            let tempRecords = [];
            // console.log(data);
            // console.log(JSON.stringify(data));
            let tempRoomOptions = [];
            let tempRoomStrings = [];
            let tempDayOptions = [];
            data.forEach(date => {
                let tempRecord = Object.assign({}, date);
                let tempTimeSlotList = [];
                for(var key in date.timeSlots){
                    let ts = Object.assign({},date.timeSlots[key]);
                    let dateTime = new Date(key);
                    ts.time = dateTime.toISOString();
                    tempTimeSlotList.push(ts);
                }
                tempRecord.timeSlotList = tempTimeSlotList;
                tempRecord.columnCount = tempRecord.roomNames.length + 1;
                tempRecord.roomNames.forEach(room=>{
                    let tempRoom = Object.assign({}, room);
                    if(!tempRoomStrings.includes(room.name)){
                        tempRoom.buttonVariant = '';
                        tempRoom.buttonSelect = false;
                        tempRoomOptions.push(tempRoom);
                        tempRoomStrings.push(room.name);
                    }
                });

                // console.log(tempRecord.columnCount);
                tempRecord.classSizing = 'column' + tempRecord.columnCount;
                let dayOption = {};
                dayOption.eventDate = tempRecord.eventDate;
                dayOption.buttonSelect = false;
                dayOption.buttonVariant = '';
                tempDayOptions.push(dayOption);

                // tempRecord.buttonVariant = '';
                // tempRecord.buttonSelect = false;
                tempRecords.push(tempRecord);    
            });//.catch(error=>console.error(error));s
            this.roomAvailData = tempRecords;
            this.roomAvailStatic = tempRecords;
            // console.log(JSON.stringify(tempRoomOptions));
            this.roomOptions = tempRoomOptions;
            this.dayOptions = tempDayOptions;

        }
        if(error){
            console.error(error);
        }
    }
    @wire(getMeetings,{contactId:'$contactId'})
    setMeetings(results){
        // console.log(results);
        this.meetingsResults = results;
        let data = results.data;
        let error = results.error;
        if(data){
            this.meetings = data;
            this.showTable = this.meetings.length>0;
        }
        if(error) console.error(error);
    }

    clickBox(event){
        let selectedValue = event.currentTarget.dataset.value;
        let tempSelectedSlots = [];
        let tempRoomAvail = [];
        this.roomAvailData.forEach(date =>{
            let tempDate = Object.assign({}, date);

            let tempTimeSlotList = [];
            let tempSelected = [];
            let eventLoc;
            let tempError;
            let tempSelectedStart;
            let tempSelectedEnd;
            let tempSelectedStartDisplay;
            let tempSelectedEndDisplay;
            tempDate.timeSlotList.forEach(ts =>{
                let tempTS = Object.assign({}, ts);
                let tempBlocks = [];
                tempTS.timeBlocks.forEach(block=>{
                    let tempBlock = Object.assign({}, block);
                    tempBlock.mismatch = false;
                    if(tempBlock.blockId === selectedValue){
                        tempBlock.selected = !tempBlock.selected;
                    }
                    if(tempBlock.selected){ 
                        tempSelectedSlots.push(tempBlock);
                        tempSelected.push(tempBlock);
                        eventLoc = eventLoc == undefined ? tempBlock.eventLoc : eventLoc;
                        // console.log('eventLoc', eventLoc);
                        // console.log('tempBlock.eventLoc', tempBlock.eventLoc);
                        if(eventLoc != tempBlock.eventLoc){ 
                            tempError = 'Please select time blocks from only one room at a time.';
                            tempBlock.mismatch = true;
                        }
                        if(tempSelectedEnd == undefined){
                            // console.log('1');
                            tempSelectedEnd = tempTS.endDateTime;
                            // console.log('1');

                            tempSelectedEndDisplay = tempTS.endTimeDisplay;
                            // console.log('1');

                        }else if(tempTS.endDateTime > tempSelectedEnd){
                            // console.log('11');

                            tempSelectedEnd = tempTS.endDateTime;
                            tempSelectedEndDisplay = tempTS.endTimeDisplay;
                        }
                        if(tempSelectedStart == undefined){
                            // console.log('2');

                            tempSelectedStart = tempTS.startDateTime;
                            tempSelectedStartDisplay = tempTS.time;
                        }else if(tempTS.startDateTime < tempSelectedStart){
                            // console.log('22');

                            tempSelectedStart = tempTS.StartDateTime;
                            tempSelectedStartDisplay = tempTS.time;
                        }
                        // tempSelectedEnd = tempSelectedEnd== undefined? tempTS.endDateTime : tempTS.endDateTime > tempSelectedEnd ? tempTS.endDateTime : tempSelectedEnd;
                        // tempSelectedStart = tempSelectedStart==undefined? tempTS.startDateTime : tempTS.startDateTime < tempSelectedStart ? tempTS.startDateTime : tempSelectedStart;
                    }
                    tempBlock.class = tempBlock.mismatch? 'mismatch' : tempBlock.selected ? 'selected' : '';
                    tempBlocks.push(tempBlock);
                });
                tempTS.timeBlocks = tempBlocks;
                tempTimeSlotList.push(tempTS);
            });
            tempDate.selectedRows = tempSelected;
            tempDate.showSelected = tempSelected.length > 0;
            tempDate.timeSlotList = tempTimeSlotList;
            tempDate.selectedStart = tempSelectedStart;
            tempDate.selectedEnd = tempSelectedEnd;
            tempDate.selectedStartDisplay = tempSelectedStartDisplay;
            tempDate.selectedEndDisplay = tempSelectedEndDisplay;
            tempDate.selectedRoom = eventLoc;
            tempDate.error = tempError == undefined ? false : tempError;
            tempRoomAvail.push(tempDate);
        });
        this.selectedSlots = tempSelectedSlots;

        this.roomAvailData = tempRoomAvail;
        tempBlock.selected = true;
    }
    filterCapacity(event){
        console.log(event.target.value);
    }
    toggleDayFilter(event){
        if(this.selectedButtons.includes(event.target.value)){
            this.selectedButtons = this.selectedButtons.filter(result=>{
                return result != event.target.value;
            });
        }else{
            this.selectedButtons.push(event.target.value);
        }
        console.log(this.selectedButtons);
        let tempDayOptions = [];
        this.dayOptions.forEach(day=>{
            let tempDay = Object.assign({}, day);
            tempDay.buttonSelect = this.selectedButtons.includes(tempDay.eventDate);
            tempDay.buttonVariant = tempDay.buttonSelect ? 'brand' : '';
            tempDayOptions.push(tempDay);
        });
        this.dayOptions = tempDayOptions;
        this.recalculateFilter();
    }
    toggleRoomFilter(event){
        if(this.selectedRooms.includes(event.target.value)){
            this.selectedRooms = this.selectedRooms.filter(result=>{
                return result != event.target.value;
            });
        }else{
            this.selectedRooms.push(event.target.value);
        }
        let tempRoomOptions = [];
        this.roomOptions.forEach(room=>{
            let tempRoom = Object.assign({}, room);
            tempRoom.buttonSelect = this.selectedRooms.includes(tempRoom.name);
            tempRoom.buttonVariant = tempRoom.buttonSelect ? 'brand' : '';
            tempRoomOptions.push(tempRoom);
        });
        this.roomOptions = tempRoomOptions;
        this.recalculateFilter();
    }
    recalculateFilter(){
        // let day = event.target.value;
        let tempStatic = [];
        let tempFiltered = [];
        let useFilters = this.selectedButtons.length > 0;
        let roomOptionsfilter = false;

        this.roomAvailStatic.forEach(date=>{
            let tempDate = Object.assign({}, date);
            let tempTimeSlots = [];
            if(this.selectedRooms.length > 0){
                let tempRoomList = tempDate.roomNames.filter(result=>{
                    return this.selectedRooms.includes(result.name);
                });
                tempDate.roomNames = tempRoomList;
            }
            tempDate.timeSlotList.forEach(ts=>{
                let tempTS = Object.assign({}, ts);
                if(this.selectedRooms.length > 0){
                    tempTS.timeBlocks = tempTS.timeBlocks.filter(result=>{
                        return this.selectedRooms.includes(result.roomName);
                    })
                }
                tempTimeSlots.push(tempTS);

            });
            tempDate.timeSlotList = tempTimeSlots;
            if(useFilters){
                if(this.selectedButtons.includes(tempDate.eventDate)){
                    tempFiltered.push(tempDate);
                }
            }else{
                tempFiltered.push(tempDate);
            }
            
        });
        // this.roomAvailStatic = tempStatic;

        // let availRoomFilters = useFilters ? tempFiltered : tempStatic;
        this.roomAvailData = tempFiltered;

    }

    handleError(event){ 
        console.log('in error')
        console.log(JSON.stringify(event.detail));
    }
    handleSuccess(event){
        refreshApex(this.meetingsResults);
        refreshApex(this.roomAvailResults);
    }
    get showCreate(){return this.selectedSlots.length > 0;}
}