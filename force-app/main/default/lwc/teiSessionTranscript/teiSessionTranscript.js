import { LightningElement, track, api, wire } from "lwc";
import USER_ID from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getRegistrant from "@salesforce/apex/teiSessionController.getRegistrant";


export default class TeiSessionTranscript extends LightningElement {

   // getSessions = :  [{"Id":"a15SK000003esjSYAQ","Title__c":"Test Title",
   //"Start_Time__c":"2025-06-01T19:00:00.000Z","End_Time__c":"2025-06-01T19:00:00.000Z",
   //"Learning_Event__c":"a14SK00000b9vrNYAQ","Learning_Event__r":{"Id":"a14SK00000b9vrNYAQ"}},
   //{"Id":"a15SK000003ggdsYAA","Title__c":"Test Title 3","Start_Time__c":"2025-06-01T19:00:00.000Z","End_Time__c":"2025-06-01T19:00:00.000Z","Learning_Event__c":"a14SK00000b9vrNYAQ","Learning_Event__r":{"Id":"a14SK00000b9vrNYAQ"}}]

    @api partNmb;
    @api title;
    @api sessionId;
    @api startTime;
    @api endTime;
    @api accessMethod;    
    @api trainingHours;
    @api trainingMinutes;
    @api isMobile;    
    @api classId; 
    @api contactId;
    registrantId;

    regType; // = 'Registrant';
    regStatus; //Registered, Withdrawn
    registered;

    connectedCallback(){
        console.log('Inner connectedCallback, classId = ', this.classId);
        console.log('Inner connectedCallback, sessionId = ', this.sessionId);
        console.log('Inner connectedCallback, contactId = ', this.contactId);
        console.log('Inner connectedCallback, registrantId = ', this.registrantId);
        
        this.getRegistrantType();
    }
    

    getRegistrantType(){
        getRegistrant({ classId : this.classId, sessionId : this.sessionId, contactId : this.contactId })
        .then((result) => {
            if (result != null && result != undefined){
                this.regType = result.Type__c;
                this.error = undefined;
                console.log('getRegistrantType regType = : ', JSON.stringify(this.regType));
                console.log('getRegistrantType compare  = : ', JSON.stringify(this.regType == 'Waitlist'));
                this.registered = true;
                this.registrantId = result.Id;
                
            } else {
                console.log('getRegistrantType regType = : Not registered');                
            }
        })
        .catch((err) => {
            console.log("getRegistrant err result  " + err.message);
            this.registered = false;                
        });
    }

    get monthName(){
        if (!this.startTime) return '';
        const date = new Date(this.startTime);
        return date.toLocaleString('en-US',  {month: 'short'});     //'Jul'    
    }

    get partNumber(){
        if (!this.partNmb) return 1;
        const nmb = this.partNmb + 1;
        return nmb;     //'Jul'    
    }

    get dayNumber(){
        if (!this.startTime) return '';
        const date = new Date(this.startTime);
        return date.getDate().toString();     //'17'    
    }

    get formattedRange(){
        if (!this.startTime || !this.endTime) return '';
        const dateStart = new Date(this.startTime);
        const dateEnd = new Date(this.endTime);

        const dateOptions = {
            weekday: 'short',
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZoneName: 'short'
        };

        const timeOptions = {
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZoneName: 'short'
        };

        const startStr = dateStart.toLocaleString('en-US',  dateOptions);
        const endStr = dateEnd.toLocaleString('en-US',  timeOptions);

        return `${startStr} - ${endStr}`;
    }
    
    get sessionDuration(){
        let sessionDurationStr = '';
        if (this.trainingHours > 1) {
            sessionDurationStr =  this.trainingHours + ' hours ' + this.trainingMinutes + ' minutes';
        } else if (this.trainingHours == 1) {
            sessionDurationStr =  this.trainingHours + ' hour ' + this.trainingMinutes + ' minutes';
        } else if (this.trainingHours == 0){
            sessionDurationStr =  this.trainingMinutes + ' minutes';
        } 
        console.log('sessionDuration sessionDuration = : ', JSON.stringify(sessionDurationStr));
        return `${sessionDurationStr}`;
    }

    get formattedStartDay(){
        if (!this.startTime) return '';
        const dateStart = new Date(this.startTime);
        
        const dateOptions = {
            weekday: 'short',
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZoneName: 'short'
        };

        const startStr = dateStart.toLocaleString('en-US',  dateOptions);        
        return `${startStr}`;
    }

    get formattedEndDay(){
        if (!this.endTime) return '';
        const dateEnd = new Date(this.endTime);
        
        const dateOptions = {
            weekday: 'short',
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: 'numeric',
            minute: '2-digit',
            hour12: true,
            timeZoneName: 'short'
        };

        const endStr = dateEnd.toLocaleString('en-US',  dateOptions);        
        return `${endStr}`;
    }

}