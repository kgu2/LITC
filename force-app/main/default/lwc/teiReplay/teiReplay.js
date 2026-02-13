import { LightningElement, track, wire } from 'lwc';
import getTEIReplayVideos from '@salesforce/apex/teiPortalController.getTEIReplayVideos';
import getRegistrant from '@salesforce/apex/teiPortalController.getRegistrant';
import createRegistrant from "@salesforce/apex/teiSessionController.createRegistrant";
import getContactId from '@salesforce/apex/teiPortalController.getContactId';
import communityBasePath from '@salesforce/community/basePath';
import { refreshApex } from "@salesforce/apex";
import { NavigationMixin } from 'lightning/navigation';

export default class TeiReplay extends NavigationMixin(LightningElement) {
    @track categories = [];
    @track showTEIReplay = true;
    @track showVideoPlayBack = false;
    @track classId = '';
    @track isLoading = false;
    @track registrantId = null;
    @track contactId = '';
    
    MAX_VIDEO_COUNT_LENGTH = 4;

    categoryMap = {
        'Authors': 'Authors',
        'Career Resources': 'Career Resources',
        'CEOs and Industry Leaders': 'CEOs and Industry Leaders',
        'Leadership(history, econ..)': 'Leadership (history, econ..)',
        'Panels': 'Panels',
        'Vault': 'Vault',
        'Wellness': 'Wellness'
    };

    showAlwaysFieldByCategory = {
        'Authors': 'Show_Always_Authors__c',
        'Career Resources': 'Show_Always_Career_Resources__c',
        'CEOs and Industry Leaders': 'Show_Always_CEOs_Industry_Leaders__c',
        'Leadership(history, econ..)': 'Show_Always_Leadership_history_econ__c',
        'Panels': 'Show_Always_Panels__c',
        'Vault': 'Show_Always_Vault__c',
        'Wellness': 'Show_Always_Wellness__c'
    };

    connectedCallback() {
        // Initialize empty category structure
        this.categories = Object.keys(this.categoryMap).map(key => ({
            key,
            label: this.categoryMap[key],
            items: [],
            hasItems: false
        }));

        this.populateTEIReplayVideos();
        
    }

    @wire(getContactId)
    receivedContactId({ error, data }) {
        if (data) {
            this.contactId = data;
            console.log("contact Id: ", this.contactId);
        } else if (error) {
            console.error('Error fetching videos:', error);
        }
    }

    async populateTEIReplayVideos() {
        var data = await getTEIReplayVideos();
        if (data) {
            console.log(data);
            data.forEach(video => {
                const videoObj = {
                    Id: video.Id,
                    Title: video.Title__c,
                    videoThumbnail: `https://img.youtube.com/vi/${video.Video_Id__c}/hqdefault.jpg`, 
                    fullObj: video
                };

                for (var cat of this.categories) {
                    if (video.Video_Categories__c?.includes(cat.key)) {
                        cat.items.push(videoObj);
                        cat.hasItems = true;
                    }
                }
            });

            this.applyRotationLogic();

            this.categories.forEach(e => {
                if(e.hasItems == true){
                    e.hasItems = false;
                }else if(e.hasItems == false){
                    e.hasItems = true;
                }
            });

            console.log(JSON.stringify(this.categories));

            setTimeout(() => {
                this.categories.forEach(e => {
                    if(e.hasItems){
                        e.hasItems = false;
                    }else{
                        e.hasItems = true;
                    }
                });
            }, 0);
        }
    }

    applyRotationLogic() {
        const toTs = (d) => (d ? new Date(d).getTime() : 0);

        this.categories = this.categories.map((cat) => {
            const flagField = this.showAlwaysFieldByCategory[cat.key];
            const items = Array.isArray(cat.items) ? cat.items : [];

            if (!flagField || items.length === 0) {
                return {
                    ...cat,
                    items: items.slice(0, this.MAX_VIDEO_COUNT_LENGTH),
                    hasItems: items.length > 0
                };
            }

            const pinned = [];
            const regular = [];

            for (const item of items) {
                const full = item.fullObj || {};
                const isPinned = Boolean(full[flagField]);
                (isPinned ? pinned : regular).push(item);
            }

            // newest → oldest within each bucket
            pinned.sort((a, b) => toTs(b.fullObj?.CreatedDate) - toTs(a.fullObj?.CreatedDate));
            regular.sort((a, b) => toTs(b.fullObj?.CreatedDate) - toTs(a.fullObj?.CreatedDate));

            const merged = [...pinned, ...regular];

            // Enforce max length (4)
            const limited = merged.slice(0, this.MAX_VIDEO_COUNT_LENGTH);

            return {
                ...cat,
                items: limited,
                hasItems: limited.length > 0
            };
        });
    }

    handleViewAllVideos(event){
        event.preventDefault();
        var category = event.currentTarget.dataset.label;
        const base = communityBasePath.endsWith('/') ? communityBasePath : `${communityBasePath}/`;

        if(category == 'Leadership (history, econ..)'){
            window.location.assign(`${base}tei-all-videos?category=Leadership`);
        }else{
            window.location.assign(`${base}tei-all-videos?category=${category}`);
        }
    }

    async reloadData(){
        this.isLoading = true;
        await refreshApex(this.receivedTEIReplayVideos);
        this.showTEIReplay = true;
        this.showVideoPlayBack = false;
        this.isLoading = false;
    }

    async handleLaunchVideo(event){
        this.classId = event.currentTarget.dataset.id;

        this.isLoading = true;

        var registrantList = await getRegistrant({classId: this.classId, contactId: this.contactId});
        if(registrantList.length == 0){
            this.registrantId = null;
        }else{
            this.registrantId = registrantList[0].Id;
        }

        this.isLoading = false;
 
        console.log('handleLaunchVideo this.classId ', this.recordId);
        console.log('handleLaunchVideo this.contactId ', this.contactId);
        console.log('handleLaunchVideo this.registrantId ', this.registrantId);
               
        let fields = { Class__c: this.classId, Contact__c : this.contactId, Session_Info__c : null, Type__c : 'Registrant', Status__c : 'Registered' };        
 
        if ((this.registrantId != null)){
           
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-video?recordId=${this.classId}&registrantId=${this.registrantId}&contactId=${this.contactId}&fromWhere=TEIReplay`
                }
            });
 
        } else {          
            createRegistrant({record : fields})
            .then(result => {
                 console.log('createRegistrant created ', result)
 
                if (result != null && result != undefined){
                    this.registrantId = result;
 
                    this[NavigationMixin.Navigate]({
                        type: "standard__webPage",
                        attributes: {
                            url: `/tei-video?recordId=${this.classId}&registrantId=${this.registrantId}&contactId=${this.contactId}&fromWhere=TEIReplay`
                        }
                    });
                   
                }
                           
            })
            .catch(error => {                
                console.log('createRegistrant  error', error);
                console.log('createRegistrant error message', error.message);                
            });
        }    
   
    }

    handleNavToSelection(event){
        var label = event.currentTarget.dataset.label;
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: `/tei-course-list?videoCategories=${label}`
            },
        },
            true,
        );
    }

    handleSearchNav() {
		this[NavigationMixin.Navigate]({
			type: "standard__webPage",
			attributes: {
				url: "/tei-course-list",
			},
		},
			true,
		);
    }
}