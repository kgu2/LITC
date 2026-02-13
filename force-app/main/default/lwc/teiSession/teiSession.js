import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import USER_ID from '@salesforce/user/Id';
import ProfileName from '@salesforce/schema/User.Profile.Name';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import createRegistrant from "@salesforce/apex/teiSessionController.createRegistrant";
import createRegistrantSeries from "@salesforce/apex/teiSessionController.createRegistrantSeries";
import getRegistrant from "@salesforce/apex/teiSessionController.getRegistrant";
import withdrawWaitlist from "@salesforce/apex/teiSessionController.withdrawWaitlist";
import withdrawRegistrantSeries from "@salesforce/apex/teiSessionController.withdrawRegistrantSeries";
import updateRegistrantStatus from '@salesforce/apex/teiPortalController.updateRegistrantStatus';

export default class TeiSession extends NavigationMixin(LightningElement) {

   // getSessions = :  [{"Id":"a15SK000003esjSYAQ","Title__c":"Test Title",
   //"Start_Time__c":"2025-06-01T19:00:00.000Z","End_Time__c":"2025-06-01T19:00:00.000Z",
   //"Learning_Event__c":"a14SK00000b9vrNYAQ","Learning_Event__r":{"Id":"a14SK00000b9vrNYAQ"}},
   //{"Id":"a15SK000003ggdsYAA","Title__c":"Test Title 3","Start_Time__c":"2025-06-01T19:00:00.000Z","End_Time__c":"2025-06-01T19:00:00.000Z","Learning_Event__c":"a14SK00000b9vrNYAQ","Learning_Event__r":{"Id":"a14SK00000b9vrNYAQ"}}]

    //@api recordId;
    @api title;
    @api sessionId;
    @api startTime;
    @api endTime;
    @api accessMethod;
    @api provider;
    @api registrationsMaximum;
    @api registrationDeadline;
    @api waitlistRegistrationDeadline;
    @api topic;
    @api recordedSession;
    @api targetAudience;
    @api trainingHours;
    @api trainingMinutes;
    @api alignment;
    @api isMobile;
    @api capacityRemaining;
    @api allowWaitlisting;
    @api waitlistCapacityRemaining;
    @api classId; 
    @api contactId;
    @api registrantId;
    @api isSeries;

    @track isLoading = false;
    @track isModalOpen = false;

    showDetails = false;
    showDetailsLabel = 'View Details';
    
    registerLabel; // = 'Register';
    regType; // = 'Registrant';
    regStatus; //Registered, Withdrawn
    withdrawLabel; // = 'Register';   
    registered;
    waitlisted = false;
    message = '';

    showTeiWithdraw = false;
    showRegister;
    canRegister = false;
    canWaitlist = false;

    isDropdownOpen = false;
    isArchived = false;
    dropDownValue = [];
    dropDownButtonLabel = '';

    fromWhere = 'session';
   
   
    connectedCallback(){
        document.addEventListener('click', this.closeOnOutside);
        console.log('Inner connectedCallback, classId = ', this.classId);
        console.log('Inner connectedCallback, sessionId = ', this.sessionId);
        console.log('Inner connectedCallback, contactId = ', this.contactId);
        console.log('Inner connectedCallback, registrantId = ', this.registrantId);
        this.checkRegistrationDeadline();
        //this.getRegistrantType();
    }

    disconnectedCallback() {
        document.removeEventListener('click', this.handleOutsideClick);
    }

    checkRegistrationDeadline(){
        let currentMoment = new Date();

        if (this.registrationDeadline != null && this.registrationDeadline != undefined){
            let regDeadline = new Date(this.registrationDeadline);
            this.canRegister = currentMoment < regDeadline;
        }

        if (this.waitlistRegistrationDeadline != null && this.waitlistRegistrationDeadline != undefined){
            let waitlistDeadline = new Date(this.waitlistRegistrationDeadline);        
            this.canWaitlist = currentMoment < waitlistDeadline;
        }

        console.log('checkRegistrationDeadline, currentMoment = ', currentMoment);
        console.log('checkRegistrationDeadline, regDeadline = ', this.registrationDeadline);
        console.log('checkRegistrationDeadline, waitlistDeadline = ', this.waitlistRegistrationDeadline);
        console.log('checkRegistrationDeadline, canRegister = ', this.canRegister);
        console.log('checkRegistrationDeadline, canWaitlist = ', this.canWaitlist);

        this.getRegistrantType();
    }

    // setRegistrantFallback() {
    //     this.registered = false;
    //     this.registrantId = null;
    //     console.log('getRegistrantType regType = Not registered');
    
    //     if (this.capacityRemaining > 0) {
    //         this.showRegister = true;
    //         this.registerLabel = 'Register';
    //         this.regType = 'Registrant';
    //         this.regStatus = 'Registered';
    //         this.message = 'You have been registered for the Class';
    //     } else if (this.allowWaitlisting === 'Yes' && this.waitlistCapacityRemaining > 0) {
    //         this.showRegister = true;
    //         this.registerLabel = 'Add to Waitlist';
    //         this.regType = 'Waitlist';
    //         this.message = 'You have been added to the Waitlist';
    //     } else {
    //         this.showRegister = false;
    //     }
    // }

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
                this.showRegister = false;
                if (this.regType == 'Waitlist'){ 
                    this.waitlisted = true;
                    this.withdrawLabel = 'Remove from Waitlist';
                    this.message = 'You have been removed from the Waitlist';
                    console.log('getRegistrantType this.registerLabel = : ', JSON.stringify(this.registerLabel));
                } else {
                    this.withdrawLabel = 'Withdraw';
                        this.dropDownButtonLabel = 'View Traning Details';
                        if (this.canRegister){
                            this.dropDownValue = [
                                'Withdraw',
                                'View Training Details',
                                this.isArchived ? 'Restore From Archived Transcript' : 'Move to Archived Transcript'
                            ];
                        } else {
                            this.dropDownValue = [
                                'View Training Details',
                                this.isArchived ? 'Restore From Archived Transcript' : 'Move to Archived Transcript'
                            ];
                        }

                    console.log('getRegistrantType this.registerLabel = : ', JSON.stringify(this.registerLabel));
                }
            } else {
                this.registered = false;
                console.log('getRegistrantType regType = : Not registered');
                if (this.capacityRemaining > 0) {
                    this.showRegister = true;
                    this.registerLabel = 'Register';
                    this.regType = 'Registrant';
                    this.regStatus = 'Registered';     //Registered, Withdrawn
                    this.message = 'You have been registered for the Class';
                } else if (this.allowWaitlisting == 'Yes' && this.waitlistCapacityRemaining > 0){
                    this.showRegister = true;
                    this.registerLabel = 'Add to Waitlist';
                    this.regType = 'Waitlist';
                    this.regStatus = 'Waitlisted';
                    //Registered, Withdrawn
                    this.message = 'You have been added to the Waitlist';
                } else{
                    this.showRegister = false;
                }
            }
        })
        .catch((err) => {
            console.log("getRegistrant err result  " + err.message);

            this.registered = false;
                console.log('getRegistrantType regType = : Not registered');
                if (this.capacityRemaining > 0) {
                    this.showRegister = true;
                    this.registerLabel = 'Register';
                    this.regType = 'Registrant';
                    this.regStatus = 'Registered';   //Registered, Withdrawn
                    this.message = 'You have been registered for the Class';
                } else if (this.allowWaitlisting == 'Yes' && this.waitlistCapacityRemaining > 0){
                    this.showRegister = true;
                    this.registerLabel = 'Add to Waitlist';
                    this.regType = 'Waitlist';
                    this.regStatus = 'Waitlisted';
                    //Registered, Withdrawn
                    this.message = 'You have been added to the Waitlist';
                } else{
                    this.showRegister = false;
                }
        });
    }

    get topicStr(){
        if (this.topic != null && this.topic != undefined){
            return this.topic.replaceAll(';', '; ');
        }
        else {
            return this.topic;
        }
    }

    get targetAudienceStr(){
        if (this.targetAudience != null && this.targetAudience != undefined){
            return this.targetAudience.replaceAll(';', '; ');
        }
        else {
            return this.targetAudience;
        }
    }

    get alignmentStr(){
        if (this.alignment != null && this.alignment != undefined){
            return this.alignment.replaceAll(';', '; ');
        }
        else {
            return this.alignment;
        }        
    }

    get monthName(){
        if (!this.startTime) return '';
        const date = new Date(this.startTime);
        return date.toLocaleString('en-US',  {month: 'short'});     //'Jul'    
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
    
    get formattedDeadline(){
        if (!this.registrationDeadline) return '';
        const dateDeadline = new Date(this.registrationDeadline);
        
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

        const dealineStr = dateDeadline.toLocaleString('en-US',  dateOptions);        
        return `${dealineStr}`;
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

    handleViewDetails(){
        this.showDetails = !this.showDetails;
        if (this.showDetails){
            this.showDetailsLabel = 'Hide Details';
        } else {
            this.showDetailsLabel = 'View Details';
        }
    }

    handleRegister(){
        this.isLoading = true;
        //let recImput = { apiName: 'MINT_Artist__c', fields : fields };
        let fields = { Class__c: this.classId, Contact__c : this.contactId, Session_Info__c : this.sessionId, Type__c : this.regType, Status__c : this.regStatus };

        if (this.classId != null && this.classId != undefined && this.contactId != null && this.contactId != undefined && this.sessionId != null && this.sessionId != undefined){

            //createRecord(recImput)
            //createRegistrant({record : fields})
            createRegistrantSeries({inputRecord : fields, isSeries : this.isSeries})
            .then(result => {
                if (this.isDebug) { console.log('createRegistrant created ', result); }

                if (result != null && result != undefined){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: this.message,
                            variant: 'Success'
                        })
                    );

                    setTimeout(() => {
                        location.reload();
                    }, 1000);
                }else{
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Error',
                            message: 'Error performing requested action.',
                            variant: 'error'
                        })
                    );
                    this.isLoading = false;
                } 
                               
            })
            .catch(error => {                
                console.log('createRegistrant  error', error);
                console.log('createRegistrant error message', error.message);                
            });
        } else { console.log('createRegistrant data is null '); this.isLoading = false;}
       
    }

    handleWithdraw(){
        if (this.regType == 'Waitlist'){

            if (this.isDebug) { console.log('withdrawWaitlist Start '); }        
            //withdrawWaitlist({registrantId : this.registrantId, reason : this.reason, comment : this.comment})
            withdrawRegistrantSeries({registrantId : this.registrantId, reason : this.reason, comment : this.comment, isSeries : this.isSeries})
            .then(result => {
                if (this.isDebug) { console.log('withdrawWaitlist updated, Acrive = ', result); }

                if (result != null && result != undefined && result == false){
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: this.message,
                            variant: 'Success'
                        })
                    );

                    setTimeout(() => {
                        location.reload();
                    }, 2000);
                } 
                               
            })
            .catch(error => {                
                console.log('withdrawWaitlist  error', error);
                console.log('withdrawWaitlist error message', error.message);  
                
                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'Error  removing from the Waitlist',
                        variant: 'error',
                        mode: 'dismissable'
                    })
                );
            });

        } else {
            this.showTeiWithdraw = true;
            this.showDetails = false;
        }
    }

    handleUpdate(event){
        this.showTeiWithdraw = event.dateil;
    }

    handleNavToSelection(event) {
        event.stopPropagation();
        
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: `/tei-class-transcript?recordId=${this.classId}`
            },
        },
            true,
        );        
    }

    toggleDropdown(event) {
        //event.stopPropagation();
        this.isDropdownOpen = !this.isDropdownOpen;

        if (this.isDropdownOpen) {
           // Defer attaching the listener so we don't catch the same click
            setTimeout(() => {
                document.addEventListener('click', this.handleOutsideClick);
            }, 0);
       } else {
           document.removeEventListener('click', this.handleOutsideClick);
       }
        
        // setTimeout(() => {
        //     this.isDropdownOpen = false;
        // }, 15000);
    }

    handleOutsideClick = (event) => {
        // In Shadow DOM, composedPath() is the most reliable way to detect “inside”
        const path = typeof event.composedPath === 'function' ? event.composedPath() : null;

        const clickedInside =
            (path && path.includes(this.template.host)) ||
            this.template.contains(event.target);

        if (!clickedInside) {
            this.isDropdownOpen = false;
            document.removeEventListener('click', this.handleOutsideClick);
        }
    };
    
    async handleActionSelection(event) {
        event.stopPropagation();
       // this.isLoading = true;

        var label = event.target.dataset.label;        
        console.log('label', label);
        
        if (label == 'Withdraw') {
            this.showTeiWithdraw = true;
            this.showDetails = false;
            this.isDropdownOpen = false;
        } else if (label == 'View Training Details') {
            this.isDropdownOpen = false;
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-class-transcript?recordId=${this.classId}`
                },
            },
                true,
            );            
        } else if (label == 'Move to Archived Transcript') {
            this.isModalOpen = true;
            this.isDropdownOpen = false;
        } else if (label == 'Restore From Archived Transcript') {
            var res = await updateRegistrantStatus({
                recordId: this.registrantId,
                status: 'Remove Archived'
            });
            console.log(res);
            if (res == 'Success') {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Successfully Restored From Archived',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            } else {
                console.log(error);

                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Error Updating Record',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);
            }

            this.isDropdownOpen = false;
            
            window.location.reload();
        }

        //this.isLoading = false;
    }

    async handleMoveToArchive(event) {
        event.stopPropagation();
        //this.isLoading = true;

        var res = await updateRegistrantStatus({
            recordId: this.registrantId,
            status: 'Archived'
        });
        console.log(res);
        if (res == 'Success') {
            const event = new ShowToastEvent({
                title: 'Success',
                message: 'Successfully Archived',
                variant: 'success',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        } else {
            console.log(error);

            const event = new ShowToastEvent({
                title: 'Error',
                message: 'Error Updating Record',
                variant: 'error',
                mode: 'dismissable'
            });
            this.dispatchEvent(event);
        }

        //this.closeDropdown(event);
        this.isDropdownOpen = false;
        //this.isLoading = false;

        window.location.reload();
    }

    closeModal(event) {
        event.stopPropagation();
        this.isModalOpen = false;
    }
    
}