import { LightningElement, track, wire } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTranscriptRecord from '@salesforce/apex/teiPortalController.getTranscriptRecord';
import updateRegistrantStatus from '@salesforce/apex/teiPortalController.updateRegistrantStatus';
import withdrawRegistrantSeries from "@salesforce/apex/teiSessionController.withdrawRegistrantSeries";
import { loadScript } from "lightning/platformResourceLoader";
import JSPDF from '@salesforce/resourceUrl/sbecs_jspdf';
import JSPDF_AUTO_TABLE from '@salesforce/resourceUrl/sbecs_jspdfAutoTable';
import teiPDFLogo from '@salesforce/resourceUrl/teiPDFLogo';

import getTotalCompletedClasses from '@salesforce/apex/teiCompletedClassCounter.getTotalCompletedClasses';

export default class TrainingTranscript extends NavigationMixin(LightningElement) {
    @track statusFilter = 'Upcoming';
    @track sortOption = '---';
    @track searchKeyword = '';
    @track currentPage = 1;
    @track openDropdownId = null;
    @track userName = '';
    @track useless = 0;
    @track isLoading = false;
    @track isModalOpen = false;
    @track isMenuOpen = false;
    @track canCloseActionMenue = false;
    @track showWithdraw = false;
    @track isSeries = false;
    @track isWaitlist = false;

    @track currentRegistrantIdForArchived = '';

    @track trainings = [];
    @track filteredTraining = [];
    @track curClassId = '';
    @track contactId = '';

    @track fileName;
    jsPDFLoaded;

    @track completions;
    @track completionsHours;
    @track completionsTotal;

    @track exportDataList = [];
    @track columnName = [
        { header: 'Title', dataKey: 'title' },
        { header: 'Status', dataKey: 'registrantStatus' },
        { header: 'Training Type', dataKey: 'type' },
        { header: 'Completion Date', dataKey: 'completionDateValue' }
    ];

    renderedCallback() {
        Promise.all([loadScript(this, JSPDF), loadScript(this, JSPDF_AUTO_TABLE)])
            .then(() => {
                console.log('JSPDF Loaded');
                this.jsPDFLoaded = true;
            })
            .catch(() => {
                console.log('not loaded');
            });
    }

    handleExportPDF() {
        console.log(JSON.stringify(this.filteredTraining));
        console.log(JSON.stringify(this.columnName));

        const {
            jsPDF
        } = window.jspdf;
        const doc = new jsPDF('l', 'mm', 'a4', {});

        const img = new Image();
        img.src = teiPDFLogo;

        img.onload = () => {
            // Compute logo size while maintaining aspect ratio
            const desiredWidth = 35; // mm 
            const aspectRatio = img.height / img.width;
            const logoHeight = desiredWidth * aspectRatio;

            // Center the logo horizontally
            const pageWidth = doc.internal.pageSize.getWidth();
            const x = (pageWidth - desiredWidth) / 2;
            const y = 10; // top margin

            doc.addImage(img, 'PNG', x, y, desiredWidth, logoHeight);

            // Add header text below the logo
            let textY = y + logoHeight + 10;
            doc.setFontSize(16);
            doc.text(`Transcript: ${this.userName}`, 10, textY);

            textY += 10;
            // doc.setFontSize(12);
            // doc.text(
            //     `Wondering where your training has gone or how to find your certificate?`,
            //     10,
            //     textY
            // );
            // textY += 10;
            // doc.text(
            //     `Training that is completed moves to a Completed section within your Transcript.`,
            //     10,
            //     textY
            // );

            // Add table after the header
            doc.autoTable({
                startY: textY + 15,
                columns: this.columnName,
                body: this.filteredTraining
            });

            doc.save(this.fileName);
            this.isMenuOpen = false;
        };
    }

    statusOptions = [
        { label: 'Upcoming', value: 'Upcoming'},
        { label: 'All', value: 'All' },
        // { label: 'Active', value: 'Active' },
        { label: 'Completed', value: 'Completed' },
        { label: 'Archived', value: 'Archived' },
        { label: 'Waitlist', value: 'Waitlist' },
        { label: 'Withdrawn', value: 'Withdrawn' },
    ];

    sortOptions = [
        { label: '---', value: '---' },
        { label: 'Title', value: 'Title' },
        { label: 'Status', value: 'Status' },
        //{ label: 'Date Added', value: 'Date Added' },
        { label: 'Training Type', value: 'Training Type' },
        { label: 'Completion Date', value: 'Completion Date' },
    ];

    @wire(getTotalCompletedClasses)
    receivedTotalCompletedClasses({ error, data }) {
        if (data) {
            console.log(data);
            
            //Completed__c, action:check            
            //this.completions = data.Contact[0].Completed__c;
            this.completionsTotal = data;
            console.log('this.completionsTotal =  ', data);
            
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getTranscriptRecord, { contactId: '', 'useless': '$useless' })
    receivedTranscriptRecord({ error, data }) {
        if (data) {
            console.log(data);
            data.Registrant.forEach(e => {
                var temp = {
                    id: e.registrantId,
                    regType: e.regType,
                    classId: e.classId,
                    title: e.title,
                    classStatus: e.classStatus,
                    registrantStatus: e.registrantStatus,
                    isCompleted: e.registrantStatus == 'Completed' ? true : false,
                    isArchived: e.isArchived,
                    type: e.type,
                    isEvent: e.type == 'Event' ? true : false,
                    videoId: e.videoId ? e.videoId : '',
                    completionDate: e.completionDate ? `• Completed Date : ${this.formatDateTime(e.completionDate)}` : '',
                    completionDateValue: e.completionDate ? e.completionDate : null,
                    seriesCompletionDate: e.seriesCompletionDate ? `• Series Completed Date : ${this.formatDateTime(e.seriesCompletionDate)}` : '',
                    seriesCompletionDateValue: e.seriesCompletionDate ? e.seriesCompletionDate : null,
                    startDate: e.Transcript_Start_Date__c,
                    isPastStartDate: e.isPastStartDate,
                    isDropdownOpen: false,
                    dropDownValue: e.dropDownValue,
                    dropDownButtonLabel: e.dropDownButtonLabel,
                    isSeries: e.isSeries,
                    seriesComplete: e.seriesComplete
                }
                console.log('title:' + temp.title);
                console.log('series?' + temp.isSeries);
                console.log('series complete?' + temp.seriesComplete);
                
                if(temp.isSeries){
                    if(!temp.seriesComplete){
                        temp.completionDate = '';
                        temp.completionDateValue = null;
                        temp.registrantStatus = 'Registered';
                        temp.isCompleted = false;
                    }else{
                        // temp.registrantStatus = 'Completed';
                        //For cases where student has met the series requirement but the last session has not happened, set to in progress. 
                        //Else is to catch cases where student has met the series requirement without attending the last session(the one displayed for the series)
                        if(!temp.isPastStartDate){
                            temp.registrantStatus = 'In Progress';
                        }else{
                            temp.registrantStatus = 'Completed';
                        }
                        temp.completionDate = temp.seriesCompletionDate;
                        temp.completionDateValue = temp.seriesCompletionDateValue;
                    }
                }

                if (temp.type == 'Event' && 
                    (temp.registrantStatus == 'Registered' || 
                    temp.registrantStatus == 'In Progress' || 
                    temp.registrantStatus == 'Waitlisted')) {
                        if (temp.startDate != null) {
                            temp.title = `${temp.title} (Starts ${temp.startDate})`;
                        } else {
                            console.log(`${temp.title} transcript start date is empty`);
                        }
                }

                this.trainings.push(temp);
                this.filteredTraining = this.trainings.filter(e => { return ['In Progress', 'Registered', 'Waitlisted'].includes(e.registrantStatus)});
            });

            //Total_Training_Time__c, Completed__c, action:check
            this.userName = data.Contact[0].Name;
            this.contactId = data.Contact[0].Id;
            this.completions = data.Contact[0].Completed__c;
            this.completionsHours = data.Contact[0].Total_Training_Time__c;
            this.fileName = `${this.userName} Transcript.pdf`;
        } else if (error) {
            console.error(error);
        }
    }


    handleResetWithdraw() {
        this.showWithdraw = false;
    }

    formatDateTime(str) {
        const date = new Date(str);

        // Helper to pad single digits
        const pad = (n) => n.toString().padStart(2, '0');

        const mm = pad(date.getMonth() + 1);
        const dd = pad(date.getDate());
        const yyyy = date.getFullYear();

        let hours = date.getHours();
        const minutes = pad(date.getMinutes());
        const ampm = hours >= 12 ? 'PM' : 'AM';

        hours = hours % 12;
        hours = hours ? hours : 12; // 0 => 12

        return `${mm}/${dd}/${yyyy} ${pad(hours)}:${minutes} ${ampm}`;
    }

    toggleMenu(event) {
        event.stopPropagation();
        if (this.isMenuOpen) {
            this.isMenuOpen = false;
            this.canCloseActionMenue = false;
        } else {
            this.isMenuOpen = true;
            this.canCloseActionMenue = true;
        }
    }

    runTranscriptReport() {
        console.log('Run Transcript Report clicked');
        this.isMenuOpen = false;
        // Add actual logic here
    }

    handleStatusPicklistChange(event) {
        this.statusFilter = event.target.value;
        this.searchKeyword = '';

        if (this.statusFilter == 'All') {
            this.isWaitlist = false;
            this.filteredTraining = this.trainings;
        } else if (this.statusFilter == 'Upcoming') {
            this.isWaitlist = false;
            this.filteredTraining = this.trainings.filter(e => {
                // return e.classStatus == 'Active'
                return ['In Progress', 'Registered', 'Waitlisted'].includes(e.registrantStatus)
            });
        } else if (this.statusFilter == 'Completed') {
            this.isWaitlist = false;
            this.filteredTraining = this.trainings.filter(e => {
                return e.isCompleted == true
            });
        } else if (this.statusFilter == 'Archived') {
            this.isWaitlist = false;
            this.filteredTraining = this.trainings.filter(e => {
                return e.isArchived == true
            });
        } else if (this.statusFilter == 'Waitlist') {
            this.isWaitlist = true;
            this.filteredTraining = this.trainings.filter(e => {
                return e.registrantStatus == 'Waitlisted'
            });
        } else if (this.statusFilter == 'Withdrawn') {
            this.isWaitlist = false;
            this.filteredTraining = this.trainings.filter(e => {
                return e.registrantStatus == 'Withdrawn';
            });
        }
    }

    handleSortPicklistChange(event) {
        this.sortOption = event.target.value;

        if (this.sortOption == 'Title') {
            this.filteredTraining.sort((a, b) => a.title.localeCompare(b.title));
        } else if (this.sortOption == 'Status') {
            this.filteredTraining.sort((a, b) => a.registrantStatus.localeCompare(b.registrantStatus));
        } else if (this.sortOption == 'Training Type') {
            this.filteredTraining.sort((a, b) => a.type.localeCompare(b.type));
        } else if (this.sortOption == 'Completion Date') {
            this.filteredTraining.sort((a, b) => {
                const dateA = a.completionDateValue ? new Date(a.completionDateValue) : null;
                const dateB = b.completionDateValue ? new Date(b.completionDateValue) : null;

                if (!dateA && !dateB) return 0;     // both are null/undefined
                if (!dateA) return 1;               // a is null → goes after b
                if (!dateB) return -1;              // b is null → goes after a

                return dateA - dateB;               // normal date comparison
            });
        }
    }

    handleSearchPicklistChange(event) {
        this.searchKeyword = event.target.value

        this.sortOption = '---';

        if (this.searchKeyword.trim() == '') {
            this.filteredTraining = this.trainings;

            return;
        }

        var parts = this.searchKeyword.split(' ');

        console.log(JSON.stringify(parts));

        this.statusFilter = 'All';

        this.filteredTraining = this.trainings.filter(e => {
            var titleArray = e.title.split(' ');

            var set1 = new Set(parts);
            var hasCommon = titleArray.some(item => set1.has(item));

            return hasCommon;
        });
    }

    toggleDropdown(event) {
        event.stopPropagation();
        const id = event.target.dataset.id;

        if (id != this.openDropdownId) {
            this.closeAllDropDown(event);
        }

        if (this.openDropdownId == null) {
            this.openDropdownId = id;

            for (let i = 0; i < this.trainings.length; ++i) {
                this.trainings[i].isDropdownOpen = false;

                if (this.trainings[i].id == id) {
                    this.trainings[i].isDropdownOpen = true;
                }
            }
        } else {
            this.openDropdownId = null;

            for (let i = 0; i < this.trainings.length; ++i) {
                if (this.trainings[i].id == id) {
                    this.trainings[i].isDropdownOpen = false;
                }
            }
        }

        console.log(JSON.stringify(this.trainings));
    }

    closeDropdown(event) {
        event.stopPropagation();
        const id = event.target.dataset.id;

        if (this.openDropdownId == null) {
            this.openDropdownId = id;

            for (let i = 0; i < this.trainings.length; ++i) {
                this.trainings[i].isDropdownOpen = false;

                if (this.trainings[i].id == id) {
                    this.trainings[i].isDropdownOpen = true;
                }
            }
        } else {
            this.openDropdownId = null;

            for (let i = 0; i < this.trainings.length; ++i) {
                if (this.trainings[i].id == id) {
                    this.trainings[i].isDropdownOpen = false;
                }
            }
        }

        this.openDropdownId = null;
    }

    handleNavToClass(event) {
        event.stopPropagation();
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
                objectApiName: "TEI_Class__c",
                actionName: "view",
                recordId: event.currentTarget.dataset.id
            }
        });
    }

    handleNavToSelection(event) {

        console.log('handleNavToSelection', this.curClassId);

        event.stopPropagation();
        this.curClassId = event.target.dataset.id;
        var curRegistrantId = event.target.dataset.registrantid;
        var type = event.target.dataset.type;
        var regType = event.target.dataset.regType;
        var isSeries = event.target.dataset.series;
        var label = event.target.dataset.label;

        console.log('curClassId', this.curClassId);
        console.log('type', type);
        console.log('regType', regType);
        console.log('label', label);




        //rita added in case of waitlist to Remove from waitlist
        if (label == 'Remove from Waitlist') {

            withdrawRegistrantSeries({
                registrantId: curRegistrantId,
                reason: '',
                comment: '',
                isSeries: isSeries
            }).then(result => {
                if (this.isDebug) { console.log('withdrawWaitlist updated, Acrive = ', result); }

                if (result != null && result != undefined && result == false) {
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'You have been removed from the Waitlist',
                            variant: 'Success',
                            mode: 'dismissable'
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
        } else if (label == 'View Certificate') {
            const location = window.location.href.toString();
            if(window.location.href == 'https://teiconnect.treasury.gov/teiconnect/s/transcript'){
                window.open(`/apex/teiCertificatePDF?Id=${curRegistrantId}`, '_blank');
            }else{
                window.open(`/TEIConnect/apex/teiCertificatePDF?Id=${curRegistrantId}`, '_blank');
            }
        } else {
            if (type == 'Video') {
                this[NavigationMixin.Navigate]({
                    type: "standard__webPage",
                    attributes: {
                        url: `/tei-video?recordId=${this.curClassId}&registrantId=${curRegistrantId}&contactId=${this.contactId}&fromWhere=TEI%20Transcript`
                    },
                },
                    true,
                );
            } else if (type == 'Event') {
                if (label == 'View Certificate') {
                    const location = window.location.href.toString();
                    if(window.location.href == 'https://teiconnect.treasury.gov/teiconnect/s/transcript'){
                        window.open(`/apex/teiCertificatePDF?Id=${curRegistrantId}`, '_blank');
                    }else{
                        window.open(`/TEIConnect/apex/teiCertificatePDF?Id=${curRegistrantId}`, '_blank');
                    }
                } else {
                    this[NavigationMixin.Navigate]({
                        type: "standard__webPage",
                        attributes: {
                            url: `/tei-class-transcript?recordId=${this.curClassId}`
                        },
                    },
                        true,
                    );
                    // this[NavigationMixin.Navigate]({
                    //     type: "standard__recordPage",
                    //     attributes: {
                    //         objectApiName: "TEI_Class__c",
                    //         actionName: "view",
                    //         recordId: this.curClassId
                    //     },
                    //     state: {
                    //         fromWhere: 'Transcript'
                    //     }
                    // });
                }
            } else if (type == 'Online Class'){
                if (label == 'View Training Details'){
                    this[NavigationMixin.Navigate]({
                        type: "standard__webPage",
                        attributes: { url: `/tei-class-transcript?recordId=${this.curClassId}`},
                    },
                    true,);
                }
            }
        }
    }

    async handleActionSelection(event) {
        event.stopPropagation();
        this.isLoading = true;
        var label = event.target.dataset.label;
        var registrantid = event.target.dataset.registrantid;
        var classid = event.target.dataset.classid;
        var isSeries = event.target.dataset.series;

        console.log('label', label);
        console.log('registrantid', registrantid);
        console.log('classid', classid);

        if (label == 'Launch') {
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-video?recordId=${classid}&registrantId=${registrantid}&contactId=${this.contactId}&fromWhere=TEI%20Transcript`
                },
            },
                true,
            );
        } else if (label == 'View Certificate') {
            const location = window.location.href.toString();
            if(window.location.href == 'https://teiconnect.treasury.gov/teiconnect/s/transcript'){
                window.open(`/apex/teiCertificatePDF?Id=${registrantid}`, '_blank');
            }else{
                window.open(`/TEIConnect/apex/teiCertificatePDF?Id=${registrantid}`, '_blank');
                
            }
        } else if (label == 'Withdraw') {
            this.currentRegistrantIdForArchived = registrantid;
            this.showWithdraw = true;

        }
        else if (label == 'Mark Complete') {
            var res = await updateRegistrantStatus({
                recordId: registrantid,
                status: 'Completed'
            });

            console.log(res);
            if (res == 'Success') {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'Successfully Marked Completed',
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

            this.closeDropdown(event);

            window.location.reload();
        } else if (label == 'View Training Details') {
            this.closeDropdown(event);
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-class-transcript?recordId=${classid}`
                },
            },
                true,
            );
            // this[NavigationMixin.Navigate]({
            //     type: "standard__recordPage",
            //     attributes: {
            //         objectApiName: "TEI_Class__c",
            //         actionName: "view",
            //         recordId: classid
            //     },
            //     state: {
            //         fromWhere: 'Transcript'
            //     }
            // });
        } else if (label == 'Move to Archived Transcript') {
            this.currentRegistrantIdForArchived = registrantid;
            this.isModalOpen = true;
        } else if (label == 'Restore From Archived Transcript') {
            var res = await updateRegistrantStatus({
                recordId: registrantid,
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

            this.closeDropdown(event);

            window.location.reload();
        } else if (label == 'Remove from Waitlist') {

            var res = await withdrawRegistrantSeries({
                registrantId: registrantid,
                reason: '',
                comment: '',
                isSeries: isSeries
            });

            console.log('Remove from Waitlist result = ', res);

            if (res != null && res != undefined && res == false) {
                const event = new ShowToastEvent({
                    title: 'Success',
                    message: 'You have been removed from the Waitlist',
                    variant: 'success',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);

                setTimeout(() => {
                    location.reload();
                }, 2000);
            } else {
                console.log('withdrawWaitlist  error', error);
                console.log('withdrawWaitlist error message', error.message);

                const event = new ShowToastEvent({
                    title: 'Error',
                    message: 'Error  removing from the Waitlist',
                    variant: 'error',
                    mode: 'dismissable'
                });
                this.dispatchEvent(event);

            }
            //this.currentRegistrantIdForArchived = registrantid;
            //this.isModalOpen = true;
        }

        this.isLoading = false;
    }

    async handleMoveToArchive(event) {
        event.stopPropagation();
        this.isLoading = true;

        var res = await updateRegistrantStatus({
            recordId: this.currentRegistrantIdForArchived,
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

        this.closeDropdown(event);

        this.isLoading = false;

        window.location.reload();
    }

    closeModal(event) {
        event.stopPropagation();
        this.isModalOpen = false;
    }

    closeAllDropDown(event) {
        event.stopPropagation();

        for (let i = 0; i < this.trainings.length; ++i) {
            this.trainings[i].isDropdownOpen = false;
        }

        this.openDropdownId = null;

        if (this.canCloseActionMenue && this.isMenuOpen) {
            this.canCloseActionMenue = false;
            this.isMenuOpen = false;
        }
    }
}