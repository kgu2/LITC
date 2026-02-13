import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

//import ProfileName from '@salesforce/schema/User.Profile.Name';
import getClass from "@salesforce/apex/teiSessionController.getClass";
//import getSessions from "@salesforce/apex/teiSessionController.getSessions";
import getSessionsTranscript  from "@salesforce/apex/teiSessionController.getSessionsTranscript";
//import getContactId from "@salesforce/apex/teiSessionController.getContactId";
import getContactInfo from "@salesforce/apex/teiSessionController.getContactInfo";

import getRegistrant from "@salesforce/apex/teiSessionController.getRegistrant";
import createRegistrant from "@salesforce/apex/teiSessionController.createRegistrant";
import notifyMe from "@salesforce/apex/teiSessionController.notifyMe";

export default class TeiClassTranscript extends NavigationMixin(LightningElement) {

   // @api recordId;
   // @api fromWhere;
   recordId;
   fromWhere;
    isTranscriptView = false;

    @track classTitle = "";
    @track classInfo = "";
    @track classDuration;
    allSessions = [];
    allSessionsTrns = [];
    totalNumberSessions = 0;
    hasSessions = false;
    totalNumberSessionsTrns = 0;    
    hasSessionsTrns = false;

    type;
    isSession = false;
    isVideo = false;
    isCurriculum = false;

    isDebug = true;

    showClass = true;
    showSession = false;
    showVideo = false;
    showTEIBehaviorPolicy = false;
    showTEICancellationPolicy = false;
    //showMore = false;

    recorded = 'This class will not be recorded.'; //'This session will be recorded.'; 'This session will not be recorded.';
    provider;
    topic;
    targetAudience;
    accessMethod;
    contactHours;
    contactMinutes;
    contactTraining = 'Contact Hours';
    alignment;
    isMobile;
    numberRequired;
    numberInSeries;
    attendance = 'N/A'; 
    deadline;

    registrantId;
    status;
    isCompleted;
    contactId;
    contactEmail;
    error;

    isPreview = false;

    notifyMe = '';
    inNotifyMe = false;

    registered = 0;
    attended = 0;
    noShow = 0;
    incomplete = 0;
    completed = 0;
    seriesCompleted = false;
    lastSessionDay;

    certificateUrl;
   

    connectedCallback() {  
        
        const urlParams = new URLSearchParams(window.location.search);
        this.recordId = urlParams.get('recordId');
        
        console.log('Outer connectedCallback fromWhere: ', this.fromWhere);

        this.isMobile = window.matchMedia("(max-width: 768px)").matches;
        if (this.isDebug) { 
            console.log('Outer connectedCallback usrID: ', USER_ID);
            console.log('Outer connectedCallback recordID: ', this.recordId);
            console.log('Outer connectedCallback isMobile: ', this.isMobile); 
        } 

        const currentURL = window.location.href;
        
        if (currentURL.includes('TEI_Class__c')) {
            console.log('The URL includes TEI_Class__c');
            this.isPreview = true;
        } else {
            console.log('The URL does not include TEI_Class__c');
        }

        this.getContactIdEmailInfo();
        //this.getClassInfo(); if (this.fromWhere == 'Transcript')
    }   
    
    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         this.recordId = currentPageReference.state.recordId;
    //         // if (this.fromWhere == 'Transcript') {
    //         //     this.isTranscriptView = true;
    //         //     this.showMore = true;
    //         // }
    //     }
    //     console.log('@wire(CurrentPageReference) fromWhere:', this.recordId);        
    // }
    
    get containerStyle(){
        if(this.fromWhere == 'Calendar'){
            return '';
        }else{
            return 'slds-p-around_xx-large';
        }
    }

    // get certificateUrl() {
    //     return `/apex/teiCertificatePDF?id=` + this.registrantId;
    // }
    
    getClassInfo(){
        getClass({ classId: this.recordId })
        .then((result) => {
            if (result != null){
                //if (this.isDebug) { console.log('getClassInfo getClass = : ', JSON.stringify(result)); }
                
                this.classTitle = result.Title__c;
                this.classInfo = '<div style="max-width: 95%;">' + result.Details__c + '</div>';   
                this.type = result.Type__c;
                this.notifyMe = result.Notify_Me__c;
                if (this.type == 'Event'){
                    this.numberInSeries = result.Number_in_Series__c;
                    this.numberRequired = result.Number_Required_in_the_Series__c;
                    if (this.numberInSeries == null || this.numberInSeries == undefined) this.numberInSeries = 1;
                    if (this.numberRequired == null || this.numberRequired == undefined) this.numberRequired = 1;
                }
                //this.classDuration = result.Training_Hours__c; 
                if (result.Recorded_Session__c == 'Yes') this.recorded = 'This class will be recorded.';  
                this.provider = result.Training_Provider__c;

                this.topic = result.Topic_s__c;
                if (this.topic != null && this.topic != undefined) this.topic = this.topic.replaceAll(';', '; ');

                this.targetAudience = result.Target_Audiance__c;
                if (this.targetAudience != null && this.targetAudience != undefined) this.targetAudience = this.targetAudience.replaceAll(';', '; ');
                
                this.accessMethod = result.Access_Method__c;
                this.contactHours = result.TEI_Training_Hours__c;
                this.contactMinutes = result.Training_Minutes__c;

                this.alignment = result.Alignment__c;
                if (this.alignment != null && this.alignment != undefined) this.alignment = this.alignment.replaceAll(';', '; ');
                
                if (this.contactHours > 1) {
                    this.classDuration = this.contactHours + ' hours ' + this.contactMinutes + ' minutes';
                } else if (this.contactHours == 1) {
                    this.classDuration = this.contactHours + ' hour ' + this.contactMinutes + ' minutes';
                } else if (this.contactMinutes == 0){
                    this.classDuration = this.contactMinutes + ' minutes';
                }
                
                if (this.type == 'Event'){
                    this.isSession = true;                    
                    this.getSessionsTrnsInfo();                    
                } else if (this.type == 'Video'){
                    this.isVideo = true;
                    this.contactTraining = 'Training Hours';
                    this.getRegistrantInfo();
                } else if (this.type == 'Curriculum'){
                    this.isCurriculum = true;
                }                 
            }		
        })
        .catch((err) => {
            console.log("getClassInfo error " + err);
            console.log("getClassInfo message  " + err.message);
        });
    }

    getContactIdEmailInfo(){
        getContactInfo({ userId : USER_ID })
        .then((result) => {
            if (result != null){
                this.contactId = result.Id;
                this.contactEmail = result.Email;
                this.error = undefined;
                console.log('getContactId contactId = : ', JSON.stringify(this.contactId));
                console.log('getContactEmail contactEmail = : ', JSON.stringify(this.contactEmail));
            }
            this.getClassInfo();
        })
        .catch((err) => {
            console.log("getContactEmail error " + err);
            console.log("getContactEmail message  " + err.message);
        });
    }

    getSessionsTrnsInfo(){
        getSessionsTranscript({ classId : this.recordId, contactId : this.contactId })
        .then((result) => {
            console.log('getSessionsTranscript result = '+ JSON.stringify(result));
            console.log('getSessionsTranscript result lenght = '+ result.length);
            if (result != null){
                this.allSessionsTrns = result;
                this.totalNumberSessionsTrns = result.length;
                if (this.totalNumberSessionsTrns > 0) {
                    this.hasSessionsTrns = true;
                    this.deadline = result[0].FormattedDeadline;
                    this.seriesCompleted = result[0].SeriesCompleted;
                    this.registrantId = result[0].registrantId;
                    console.log('getSessionsTranscript seriesCompleted = '+ this.seriesCompleted);

                    //"Registered, Attended, No Show, Incomplete, Withdrawn, Waitlist Expired, Completed"
                    for(var i = 0; i < this.totalNumberSessionsTrns; i++) {
                        if (i !=0 ) { 
                            this.attendance = this.attendance + ', ';
                        } else {
                            this.attendance = '';
                        }
                        
                        console.log('getSessionsTranscript i = '+ i);

                        this.attendance = this.attendance + 'Part ' + result[i].index + ' - ';
                        if (result[i].Status == 'No Show'){
                            this.attendance = this.attendance + 'No Show';
                        } else if ((result[i].Status == 'Attended') || (result[i].Status == 'Completed')){
                            this.attendance = this.attendance + 'Attended';
                        } else {
                            this.attendance = this.attendance + 'N/A';
                        }

                        if (i == (this.totalNumberSessionsTrns - 1)){                           
                            let lastSessionDateStr = result[i].FormattedEndTime;
                            this.lastSessionDay = new Date(lastSessionDateStr);
                            console.log("getSessionsTranscript lastSessionDateStr =  " + lastSessionDateStr);
                            console.log("getSessionsTranscript this.lastSessionDay =  " + this.lastSessionDay);
                        }    

                            // Check if it's in the past or future
                            // if (this.lastSessionDay.getTime() < now.getTime()) {
                            //     console.log('Date is in the past');
                            // } else {
                            //     console.log('Date is in the future');
                            // }                        
                    }

                    if ( (this.totalNumberSessionsTrns == 1) || (result[0].Status == 'Withdrawn') || (result[0].Status == 'Waitlist Expired')) { 
                        this.status = result[0].Status;
                        if (this.status == 'Completed') this.isCompleted = true;
                    } else if (this.seriesCompleted) {
                        this.status = 'Completed';
                        this.isCompleted = true;    
                    } else {

                        let now = new Date();

                        for(var i = 0; i < this.totalNumberSessionsTrns; i++) {
                            switch (result[i].Status) {
                                case 'Registered':
                                    this.registered++;
                                    console.log('Option A selected');
                                    break;
                                case 'Attended':
                                    this.attended++;
                                    console.log('Option B selected');
                                    break;
                                case 'No Show':
                                    this.noShow++;
                                    console.log('Option C selected');
                                    break;
                                case 'Incomplete':
                                    this.incomplete++;
                                    console.log('Option D selected');
                                    break;
                                case 'Completed':
                                    this.completed++;
                                    console.log('Option G selected');
                                    break;
                                default:
                                    console.log('Default option selected');
                            }
                        }
                        if (this.registered == this.totalNumberSessionsTrns) {
                            this.status = 'Registered';
                        } else if (this.completed == this.numberRequired) {
                            this.status = 'Completed';
                            this.isCompleted = true;
                        } else if ((this.completed < this.numberRequired) && (this.completed > 0) && (this.lastSessionDay.getTime() > now.getTime())) {
                            this.status = 'In Progress';
                        } else if ((this.lastSessionDay.getTime() < now.getTime())) {
                            this.status = 'Incomplete';
                        } else {
                            console.log('getSessionsTranscript date of the last settion is missing');
                        }

                        console.log("getSessionsTranscript this.registered =  " + this.registered);
                        console.log("getSessionsTranscript this.attended =  " + this.attended);
                        console.log("getSessionsTranscript this.noShow =  " + this.noShow);
                        console.log("getSessionsTranscript this.incomplete =  " + this.incomplete);
                        console.log("getSessionsTranscript this.completed =  " + this.completed);
                        console.log("getSessionsTranscript this.totalNumberSessionsTrns =  " + this.totalNumberSessionsTrns);
                        console.log("getSessionsTranscript this.numberRequired =  " + this.numberRequired);
                        console.log("getSessionsTranscript this.lastSessionDay =  " + this.lastSessionDay);
                        console.log("getSessionsTranscript now.getTime =  " + now.getTime);
                        console.log("getSessionsTranscript this.status =  " + this.status);

                    }
                } 
                if (this.isDebug) { console.log('getSessionsTrnsInfo totalNumberSessions = : ', JSON.stringify(this.totalNumberSessions)); } 
                if (this.isDebug) { console.log('getSessionsTrnsInfo inNotifyMe = : ', JSON.stringify(this.inNotifyMe)); }  
                if (this.isDebug) { console.log('getSessionsTrnsInfo isCompleted = : ', JSON.stringify(this.isCompleted)); }                       
            }	            
            
        })
        .catch((err) => {
            console.log("getSessionsTrnsInfo error " + err);
            console.log("getSessionsTrnsInfo message  " + err.message);
        });
    }

    getRegistrantInfo(){
        getRegistrant({ classId : this.recordId, sessionId : null, contactId : this.contactId })
        .then((result) => {
            if (result != null && result != undefined){
                this.registrantId = result.Id; 
                this.status = result.Status__c; 
                this.certificateUrl = `/apex/teiCertificatePDF?id=${this.registrantId}`;
                console.log("getRegistrant this.registrantId =  " + this.registrantId);              
            } 
        })
        .catch((err) => {
            console.log("getRegistrant err result  " + err.message);
            this.registrantId = null;
        });
    }

    openBehaviorPolicy() {  
        this.showClass = false;
        this.showSession = false;
        this.showTEIBehaviorPolicy = true;
        this.showTEICancellationPolicy = false;           
    }

    openCancellationPolicy() {  
        this.showClass = false;
        this.showSession = false;
        this.showTEIBehaviorPolicy = false;
        this.showTEICancellationPolicy = true;           
    }

    openClass(){
        this.showClass = true;
        this.showSession = false;
        this.showTEIBehaviorPolicy = false;
        this.showTEICancellationPolicy = false;
    }

    // openShowMoreLess(){
    //     this.showMore = !this.showMore;
    // }

    navigateToTeiBehaviorPolicy() {  
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/tei-behavior-policy'
            }
        });        
    }

    navigateToTeiCancellationPolicy() {  
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            type: 'standard__webPage',
            attributes: {
                url: '/tei-cancellation-policy'
            }
        });       
    }

    handleLaunchVideo(){

        if (this.isDebug) { console.log('handleLaunchVideo this.classId ', this.recordId); }
        if (this.isDebug) { console.log('handleLaunchVideo this.contactId ', this.contactId); }
        if (this.isDebug) { console.log('handleLaunchVideo this.registrantId ', this.registrantId); }
        if (this.isDebug) { console.log('handleLaunchVideo this.isPreview ', this.isPreview); }
        
        let fields = { Class__c: this.recordId, Contact__c : this.contactId, Session_Info__c : null, Type__c : 'Registrant', Status__c : 'Registered' };        

            if ((this.registrantId != null) || (this.isPreview == true)){
                this.showClass = false;
                this.showSession = false;
                this.showVideo = true;
                this.showTEIBehaviorPolicy = false;
                this.showTEICancellationPolicy = false;
                //this.showMore = false;
    
            } else {           
                createRegistrant({record : fields})
                .then(result => {
                    if (this.isDebug) { console.log('createRegistrant created ', result); }

                    if (result != null && result != undefined){

                        this.registrantId = result;

                        // this.dispatchEvent(
                        //     new ShowToastEvent({
                        //         title: 'Success',
                        //         message: this.message,
                        //         variant: 'Success'
                        //     })
                        // );

                        // setTimeout(() => {
                        //     location.reload();
                        // }, 1000);

                        this.showClass = false;
                        this.showSession = false;
                        this.showVideo = true;
                        this.showTEIBehaviorPolicy = false;
                        this.showTEICancellationPolicy = false;
                        //this.showMore = false;
                    } 
                                
                })
                .catch(error => {                
                    console.log('createRegistrant  error', error);
                    console.log('createRegistrant error message', error.message);                
                });
            }    
       
    }

    handleVideoUpdate(event){
        let details = event.dateil;
        this.showClass = true;
        this.showSession = false;
        this.showTEIBehaviorPolicy = false;
        this.showTEICancellationPolicy = false;
        this.showVideo = false;
           
    }

    handleNotifyMe(){
        notifyMe({classId : this.recordId, email : this.contactEmail})
        .then(result => {
            if (this.isDebug) { console.log('notifyMe updated ', result); }
            
            this.dispatchEvent(
                new ShowToastEvent({
                    title: 'Success',
                    message: 'You will be notified by email when a session is added to the class',
                    variant: 'Success'
                })
            );

            setTimeout(() => {
                location.reload();
            }, 1000);             
                                
        })
        .catch(error => {                
            console.log('notifyMe  error', error);
            console.log('notifyMe error message', error.message);                
        });

    }

    get containerClass() {
        return this.isMobile
            ? '' //slds-p-around_xx-small' // no border
            : 'slds-box slds-p-around_medium'; // with border
    }

    handleViewCertificates(){
        console.log('Registrant ID:', this.registrantId);
        //const url = `/apex/teiCertificatePDF?id=${this.registrantId}`; //a1DSK000000Icy52AC
        const url = `/TEIConnect/apex/teiCertificatePDF?Id=${this.registrantId}`;
        console.log('url:', url);
        window.open(url, '_blank');
    }
}