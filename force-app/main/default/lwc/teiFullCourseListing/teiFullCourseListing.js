import {LightningElement,track,wire} from 'lwc';
import getGlobalSearchResult from '@salesforce/apex/teiPortalController.getGlobalSearchResult';
import getAllClassRecord from '@salesforce/apex/teiPortalController.getAllClassRecord';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';

export default class TeiFullCourseListing extends NavigationMixin(LightningElement) {
    @track searchTerm = '';
    @track searchCategory = 'Training';
    @track searchSubCategory = ['Video', 'Event']; 
    @track results = [];
    @track currentPage = 1;

    pageSize = 5;

    @track startDate;
    @track endDate;
    @track locationValue;

    isLoading = false;

    connectedCallback() {
        this.presetFields();
    }

    async presetFields() {
        const urlParams = new URLSearchParams(window.location.search);

        const pageId = urlParams.get('pageId');
        const searchTerm = urlParams.get('SearchTerm');
        const startDate = urlParams.get('startDate');
        const endDate = urlParams.get('endDate');

        this.searchTerm = searchTerm ?? '';
        this.searchSubCategory = ['Video', 'Event']; 

        // Normalize dates
        this.startDate = this.isValidDate(startDate) ? new Date(startDate).toISOString().slice(0, 10) : null;
        this.endDate = this.isValidDate(endDate) ? new Date(endDate).toISOString().slice(0, 10) : null;

        // Automatically trigger search on load
        await this.handleSearch();

        if (pageId) {
            this.currentPage = Number(pageId) || 1;
        }
    }

    @wire(getAllClassRecord)
    receivedClassRecord({
        error,
        data
    }) {
        if (data && this.results.length === 0) {
            this.results = data.map((e) => {
                const plain = e.Details__c ? e.Details__c.replace(/<[^>]*>/g, '') : '';
                return {
                    id: e.Id,
                    title: e.Title__c,
                    type: e.Type__c,
                    source: e.Training_Provider__c,
                    description: plain,
                    shortenDescription: this.trimToMax330(plain),
                };
            }).sort((a, b) => a.title.localeCompare(b.title));
        } else if (error) {
            console.error(error);
        }
    }

    get categoryOptions() {
        return [{
            label: 'Training',
            value: 'Training'
        }];
    }

    get subCategoryOptions() {
        if (this.searchCategory === 'Training') {
            return [{
                    label: 'Video',
                    value: 'Video'
                },
                {
                    label: 'Event',
                    value: 'Event'
                },
                {
                    label: 'Online Class',
                    value: 'Online Class'
                },
                {
                    label: 'Curriculum',
                    value: 'Curriculum'
                },
            ];
        }
        return [];
    }

    get locationOptions() {
        return [{
                label: '',
                value: ''
            },
            {
                label: 'TEI',
                value: 'TEI'
            },
        ];
    }

    get paginatedResults() {
        const start = (this.currentPage - 1) * this.pageSize;
        return this.results.slice(start, start + this.pageSize);
    }

    get totalPages() {
        return Math.ceil((this.results.length || 0) / this.pageSize) || 1;
    }

    get isFirstPage() {
        return this.currentPage === 1;
    }

    get isLastPage() {
        return this.currentPage === this.totalPages;
    }

    handleStartDateChange(event) {
        this.startDate = event.target.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.target.value;
    }

    handleLocationChange(event) {
        this.locationValue = event.detail.value;
    }

    handleSearchInput(event) {
        this.searchTerm = event.target.value;
    }

    handleCategoryChange(event) {
        this.searchCategory = event.detail.value;
    }

    handleSubCategoryChange(event) {
        this.searchSubCategory = event.detail.value || ['Video', 'Event'];
    }

    handleKeyDown(event) {
        if (event.key === 'Enter') {
            this.handleSearch();
        }
    }

    async handleSearch() {
        if (!this.searchCategory) {
            this.notify('Error', 'Please provide a search category', 'error');
            return;
        }
        if (!this.searchSubCategory || this.searchSubCategory.length === 0) {
            this.notify('Error', 'Please select a subcategory', 'error');
            return;
        }
        if (this.startDate && this.endDate) {
            if (new Date(this.startDate) > new Date(this.endDate)) {
                this.notify('Error', 'Start date is after end date', 'error');
                return;
            }
        }

        this.isLoading = true;
        this.results = [];

        const subcats = Array.isArray(this.searchSubCategory) ? this.searchSubCategory : ['Video', 'Event'];

        try {
            const tempRes = await getGlobalSearchResult({
                searchTerm: this.searchTerm || '',
                category: this.searchCategory,
                subcategory: subcats,
                startDate: this.startDate || null,
                endDate: this.endDate || null,
                location: this.locationValue || null,
            });

            this.results = (tempRes || []).map((e) => {
                const plain = e.Details__c ? e.Details__c.replace(/<[^>]*>/g, '') : '';
                return {
                    id: e.Id,
                    title: e.Title__c,
                    type: e.Type__c,
                    source: e.Training_Provider__c,
                    description: plain,
                    shortenDescription: this.trimToMax330(plain),
                };
            }).sort((a, b) => a.title.localeCompare(b.title));

            this.currentPage = 1;
        } catch (err) {
            console.error(err);
            this.notify('Error', 'Search failed. Please try again.', 'error');
        } finally {
            this.isLoading = false;
        }
    }

    handleNav(event) {
        const subcats = Array.isArray(this.searchSubCategory) ? this.searchSubCategory : [];
        const hasVideo = subcats.includes('Video');
        const hasEvent = subcats.includes('Event');

        const startDate = this.startDate || '';
        const endDate = this.endDate || '';

        const url =
            `/tei-class/${event.currentTarget.dataset.id}` +
            `?FromWhere=FullCourseListing` +
            `&pageId=${this.currentPage}` +
            `&SearchTerm=${encodeURIComponent(this.searchTerm || '')}` +
            `&VideoCategory=${hasVideo}` +
            `&EventCategory=${hasEvent}` +
            `&startDate=${startDate}` +
            `&endDate=${endDate}`;

        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url
            },
        });
    }

    handleNextPage() {
        if (this.currentPage < this.totalPages) {
            this.currentPage += 1;
        }
    }

    handlePrevPage() {
        if (this.currentPage > 1) {
            this.currentPage -= 1;
        }
    }

    trimToMax330(str) {
        if (!str) return '';
        return str.length > 330 ? `${str.slice(0, 330)}...` : str;
    }

    isValidDate(d) {
        if (!d) return false;
        const t = Date.parse(d);
        return !Number.isNaN(t);
    }

    notify(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant,
                mode: 'dismissable',
            })
        );
    }
}