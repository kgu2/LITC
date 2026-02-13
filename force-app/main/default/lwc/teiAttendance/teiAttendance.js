import { LightningElement, api, wire, track } from 'lwc';
import getSessionsByClass from '@salesforce/apex/teiAttendanceController.getSessionsByClass';
import getRegistrants from '@salesforce/apex/teiAttendanceController.getRegistrants';
import updateAttendance from '@salesforce/apex/teiAttendanceController.updateAttendance';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class teiAttendance extends LightningElement {

    @api recordId;
    @track sessions = [];
    @track sessionOptions = [];
    @track selectedSession;
    @track registrantsData = [];
    wiredRegistrantsResult;

    editMode = false;

    readonlyColumns = [
        // { label: 'Registrant Name', fieldName: 'ContactName', type: 'text' },
        // { label: 'Status', fieldName: 'Status__c', type: 'text' }
        {
            label: 'Registrant Record',
            fieldName: 'recordUrl',
            type: 'url',
            typeAttributes: {
                label: { fieldName: 'RegistrantName' }
                ,target: '_blank'
            }
        },
        { label: 'Registrant Name', fieldName: 'ContactName', type: 'text' },
        { label: 'Status', fieldName: 'Status__c', type: 'text' },
        {
            label: 'Transcript Start Date',
            fieldName: 'Transcript_Start_Date__c',
            type: 'date',
            typeAttributes: {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit'
            }
        }
    ];

    // Fetch sessions
    @wire(getSessionsByClass, { classId: '$recordId' })
    wiredSessions({ data, error }) {
        if (data) {
            this.sessions = data;
            this.sessionOptions = data;
            if (this.sessionOptions.length === 1) {
                this.selectedSession = this.sessionOptions[0].value;
            }
        } else if (error) {
            this.showToast('Error loading sessions', error.body.message, 'error');
        }
    }

    get noSessions() {
        return this.sessions && this.sessions.length === 0;
    }
    get hasSingleSession() {
        return this.sessions && this.sessions.length === 1;
    }
    get hasMultipleSessions() {
        return this.sessions && this.sessions.length > 1;
    }
    get showRegistrants() {
        return this.selectedSession && this.registrantsData;
    }

    get singleSessionTitle() {
        // return this.sessions && this.sessions.length === 1
        //     ? this.sessions[0].label // title is before the dash
        //     : '';

        if (this.sessions && this.sessions.length === 1) {
            const s = this.sessions[0];
            return {
                label: s.label,
                url: '/' + s.value
            };
        }
        return null;
    }

    get selectedSessionLink() {
        if (this.selectedSession && this.sessions && this.sessions.length > 1) {
            const selected = this.sessions.find(s => s.value === this.selectedSession);
            if (selected) {
                return {
                    label: selected.label,
                    url: '/' + selected.value
                };
            }
        }
        return null;
    }

    handleSessionChange(event) {
        this.selectedSession = event.detail.value;
    }

    // Fetch registrants
    // @wire(getRegistrants, { sessionId: '$selectedSession' })
    // wiredRegistrants(result) {
    //     this.wiredRegistrantsResult = result;
    //     if (result.data) {
    //         this.registrantsData = result.data.map(r => ({
    //             Id: r.Id,
    //             ContactName: r.Contact__r ? r.Contact__r.Name : '',
    //             Status__c: r.Status__c,
    //             isCompleted: r.Status__c === 'Completed'
    //         }));
    //     } else if (result.error) {
    //         this.showToast('Error loading registrants', result.error.body.message, 'error');
    //     }
    // }
    @wire(getRegistrants, { sessionId: '$selectedSession' })
    wiredRegistrants(result) {
        this.wiredRegistrantsResult = result;
        if (result.data) {
            this.registrantsData = result.data.map(r => ({
                Id: r.Id,
                RegistrantName: r.Name, // registrant record name
                recordUrl: '/' + r.Id,  // clickable link
                ContactName: r.Contact__r ? r.Contact__r.Name : '',
                Status__c: r.Status__c,
                Transcript_Start_Date__c: r.Transcript_Start_Date__c,
                isCompleted: r.Status__c === 'Completed'
            }));
        } else if (result.error) {
            this.showToast('Error loading registrants', result.error.body.message, 'error');
        }
    }

    // Switch to edit mode
    enableEditMode() {
        this.editMode = true;
    }

    cancelEditMode() {
        this.editMode = false;
    }

    // Handle checkbox toggle
    handleCheckboxChange(event) {
        const regId = event.target.dataset.id;
        const checked = event.target.checked;
        this.registrantsData = this.registrantsData.map(r =>
            r.Id === regId ? { ...r, isCompleted: checked } : r
        );
    }

    // Submit attendance
    handleSubmit() {
        const attendanceMap = {};
        this.registrantsData.forEach(r => {
            attendanceMap[r.Id] = r.isCompleted;
        });

        updateAttendance({ attendanceMap })
            .then(() => {
                this.showToast('Success', 'Attendance updated successfully.', 'success');
                this.editMode = false;
                return refreshApex(this.wiredRegistrantsResult);
            })
            .catch(error => {
                this.showToast('Error updating attendance', error.body.message, 'error');
            });
    }

    // Toast utility
    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}