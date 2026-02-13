import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CurrentPageReference } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';

//import ProfileName from '@salesforce/schema/User.Profile.Name';
import getClass from "@salesforce/apex/teiSessionController.getClass";
import getSessions from "@salesforce/apex/teiSessionController.getSessions";
//import getSessionsTranscript  from "@salesforce/apex/teiSessionController.getSessionsTranscript";
//import getContactId from "@salesforce/apex/teiSessionController.getContactId";
import getContactInfo from "@salesforce/apex/teiSessionController.getContactInfo";

import getRegistrant from "@salesforce/apex/teiSessionController.getRegistrant";
import createRegistrant from "@salesforce/apex/teiSessionController.createRegistrant";
import notifyMe from "@salesforce/apex/teiSessionController.notifyMe";
import getFiles from "@salesforce/apex/teiClassFilesController.getFiles";

export default class TeiClass extends NavigationMixin(LightningElement) {

    @api recordId;
    @api fromWhere;
    isTranscriptView = false;

    @track classTitle = "";
    @track classInfo = "";
    @track classDuration;
    @track hasFiles = false;
    @track classFiles;

    allSessions = [];
    allSessionsTrns = [];
    totalNumberSessions = 0;
    hasSessions = false;
    totalNumberSessionsTrns = 0;
    hasSessionsTrns = false;

    type;
    classStatus;
    isSession = false;
    isVideo = false;
    isCurriculum = false;
    isOnDemand = false;

    isDebug = false;

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
    alignment;
    isMobile;
    numberRequired;
    numberInSeries;
    isSeries = false;
    attendance = 'N/A'; 

    registrantId;
    status;
    contactId;
    contactEmail;
    error;

    isPreview = false;

    notifyMe = '';
    inNotifyMe = false;

    titleObserver;
    desiredTitle = '';

    setDocTitle(title) {
        this.desiredTitle = title ?? '';

        // 1) Set on next frame (after DOM updates)
        requestAnimationFrame(() => { document.title = this.desiredTitle; });

        // 2) For a short window, re-apply if something else overwrites it
        if (this.titleObserver) { this.titleObserver.disconnect(); }
        const titleEl = document.querySelector('title');
        if (!titleEl) { return; }

        this.titleObserver = new MutationObserver(() => {
            if (document.title !== this.desiredTitle) {
                document.title = this.desiredTitle;
            }
        });
        this.titleObserver.observe(titleEl, { childList: true, characterData: true, subtree: true });

        // Stop observing after 2 seconds to avoid leaks
        setTimeout(() => {
            if (this.titleObserver) {
                this.titleObserver.disconnect();
                this.titleObserver = null;
            }
        }, 2000);
    }

    disconnectedCallback() {
        if (this.titleObserver) {
            this.titleObserver.disconnect();
            this.titleObserver = null;
        }
    }


    connectedCallback() {       
        
        if (this.isDebug) {console.log('Outer connectedCallback fromWhere: ', this.fromWhere);}

        this.isMobile = window.matchMedia("(max-width: 768px)").matches;
        if (this.isDebug) { 
            console.log('Outer connectedCallback usrID: ', USER_ID);
            console.log('Outer connectedCallback recordID: ', this.recordId);
            console.log('Outer connectedCallback isMobile: ', this.isMobile); 
        } 

        const currentURL = window.location.href;
        
        if (currentURL.includes('TEI_Class__c')) {
            if (this.isDebug) {console.log('The URL includes TEI_Class__c');}
            this.isPreview = true;
        } else {
            if (this.isDebug) {console.log('The URL does not include TEI_Class__c');}
        }

        this.getContactIdEmailInfo();
        //this.getClassInfo(); if (this.fromWhere == 'Transcript')
    }   

    
    // @wire(CurrentPageReference)
    // getStateParameters(currentPageReference) {
    //     if (currentPageReference) {
    //         this.fromWhere = currentPageReference.state.fromWhere;
    //         if (this.fromWhere == 'Transcript') {
    //             this.isTranscriptView = true;
    //             //this.showMore = true;
    //         }
    //     }
    //     console.log('@wire(CurrentPageReference) fromWhere:', this.fromWhere);        
    // }

    get fromSearch(){
        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);

        const FromWhere = urlParams.get('FromWhere');

        if (this.isDebug) { console.log('FromWhere', FromWhere); }

        if(FromWhere){
            return true;
        }

        return false;
    }

    handleBack(){

        const queryString = window.location.search;
        const urlParams = new URLSearchParams(queryString);

        const FromWhere = urlParams.get('FromWhere');
        const pageId = urlParams.get('pageId');
        const SearchTerm = urlParams.get('SearchTerm');
        const VideoCategory = urlParams.get('VideoCategory');
        const EventCategory = urlParams.get('EventCategory');
        const startDate = urlParams.get('startDate');
        const endDate = urlParams.get('endDate');

        if(FromWhere == 'GlobalSearch'){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-course-list?pageId=${pageId}&SearchTerm=${SearchTerm}&VideoCategory=${VideoCategory}&EventCategory=${EventCategory}`
                }
            });
        }
        if(FromWhere == 'FullCourseListing'){
                if (this.isDebug) { console.log('startDate', startDate); }
                if (this.isDebug) { console.log('endDate', endDate);}
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-full-course-listing?pageId=${pageId}&SearchTerm=${SearchTerm}&VideoCategory=${VideoCategory}&EventCategory=${EventCategory}&startDate=${startDate}&endDate=${endDate}`
                }
            });
        }
    }
    
    get containerStyle(){
        if(this.fromWhere == 'Calendar'){
            return '';
        }else{
            return 'slds-p-around_xx-large';
        }
    }
    
    getClassInfo(){
        getClass({ classId: this.recordId })
        .then((result) => {
            if (result != null){
                //if (this.isDebug) { console.log('getClassInfo getClass = : ', JSON.stringify(result)); }
                
                this.classTitle = result.Title__c;

                if(this.fromWhere != 'Calendar'){
                    this.setDocTitle(this.classTitle);
                }

                this.classInfo = '<div style="max-width: 95%;">' + result.Details__c + '</div>';   
                this.type = result.Type__c;
                this.classStatus = result.Status__c;
                this.notifyMe = result.Notify_Me__c;
                this.isOnDemand = result.On_Demand__c;
                if (this.type == 'Event'){
                    this.numberInSeries = result.Number_in_Series__c;
                    this.numberRequired = result.Number_Required_in_the_Series__c;
                    if (this.numberInSeries == null || this.numberInSeries == undefined) this.numberInSeries = 1;
                    if (this.numberRequired == null || this.numberRequired == undefined) {
                        this.numberRequired = 1;
                    } else {
                        this.isSeries = true;
                    }
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
                    this.getSessionsInfo();
                    this.getFilesInfo();
                    // if (this.isTranscriptView){
                    //     this.getSessionsTrnsInfo();
                    // }
                } else if (this.type == 'Video'){
                    this.isVideo = true;
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

    getFilesInfo(){
        getFiles({ classId: this.recordId })
        .then((result) => {
            if (result != null){
                this.classFiles = result;
                this.hasFiles = result && result.length > 0;
                if (this.isDebug) { console.log('getFilesInfo classFiles = : ', JSON.stringify(result)); }
                if (this.isDebug) { console.log('getFilesInfo hasFiles = : ', JSON.stringify(this.hasFiles)); }
            }		
        })
        .catch((err) => {
            console.log("getFilesInfo error " + err);
            console.log("getFilesInfo message  " + err.message);
        });
    }

    // getContactInfo(){
    //     getContactId({ userId : USER_ID })
    //     .then((result) => {
    //         if (result != null){
    //             this.contactId = result;
    //             this.error = undefined;
    //             this.getContactEmailInfo();
    //             console.log('getContactId contactId = : ', JSON.stringify(this.contactId));
    //         }

    //         this.getClassInfo();
    //     })
    //     .catch((err) => {
    //         console.log("getContactId error " + err);
    //         console.log("getContactId message  " + err.message);
    //     });
    // }

    getContactIdEmailInfo(){
        getContactInfo({ userId : USER_ID })
        .then((result) => {
            if (result != null){
                this.contactId = result.Id;
                this.contactEmail = result.Email;
                this.error = undefined;
                if (this.isDebug) {
                    console.log('getContactId contactId = : ', JSON.stringify(this.contactId));
                    console.log('getContactEmail contactEmail = : ', JSON.stringify(this.contactEmail));
                }
            }
            this.getClassInfo();
        })
        .catch((err) => {
            console.log("getContactEmail error " + err);
            console.log("getContactEmail message  " + err.message);
        });
    }

    getSessionsInfo(){
        getSessions({ classId: this.recordId })
        .then((result) => {
            if (result != null){
                this.allSessions = result;
                this.totalNumberSessions = this.allSessions.length;
                if (this.totalNumberSessions > 0) {
                    this.hasSessions = true;
                } else if (this.notifyMe != null && this.notifyMe != undefined) {
                    this.inNotifyMe = this.notifyMe.includes(this.contactEmail);                   
                }
                if (this.isDebug) { console.log('getSessionsInfo totalNumberSessions = : ', JSON.stringify(this.totalNumberSessions)); } 
                if (this.isDebug) { console.log('getSessionsInfo inNotifyMe = : ', JSON.stringify(this.inNotifyMe)); }                       
            }	            
            
        })
        .catch((err) => {
            console.log("getSessionsInfo error " + err);
            console.log("getSessionsInfo message  " + err.message);
        });
    }

    // getSessionsTrnsInfo(){
    //     getSessionsTranscript({ classId : this.recordId, contactId : this.contactId })
    //     .then((result) => {
    //         console.log('getSessionsTranscript result = ', result);
    //         if (result != null){
    //             this.allSessionsTrns = result;
    //             this.totalNumberSessionsTrns = this.allSessionsTrns.length;
    //             if (this.totalNumberSessionsTrns > 0) {
    //                 this.hasSessionsTrns = true;
    //             } 
    //             if (this.isDebug) { console.log('getSessionsInfo totalNumberSessions = : ', JSON.stringify(this.totalNumberSessions)); } 
    //             if (this.isDebug) { console.log('getSessionsInfo inNotifyMe = : ', JSON.stringify(this.inNotifyMe)); }                       
    //         }	            
            
    //     })
    //     .catch((err) => {
    //         console.log("getSessionsTrnsInfo error " + err);
    //         console.log("getSessionsTrnsInfo message  " + err.message);
    //     });
    // }

    getRegistrantInfo(){
        getRegistrant({ classId : this.recordId, sessionId : null, contactId : this.contactId })
        .then((result) => {
            if (result != null && result != undefined){
                this.registrantId = result.Id; 
                this.status = result.Status__c; 
                if (this.isDebug) {console.log("getRegistrant this.registrantId =  " + this.registrantId); }             
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
            : 'slds-box slds-p-around_medium panel'; // with border
    }
}