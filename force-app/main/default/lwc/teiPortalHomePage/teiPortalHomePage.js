import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from "lightning/navigation";
import getClass from '@salesforce/apex/teiPortalController.getClass';
import getUserName from '@salesforce/apex/teiPortalController.getUserName';
import getAnnouncement from '@salesforce/apex/teiPortalController.getAnnouncement';
import getUpcomingClass from '@salesforce/apex/teiPortalController.getUpcomingClass';
import teiFooterLogo from '@salesforce/resourceUrl/teiFooterLogo';
import teiCornerstoneLogo from '@salesforce/resourceUrl/teiCornerstoneLogo';
import teiBadge1 from '@salesforce/resourceUrl/teiBadge1';
import teiBadge2 from '@salesforce/resourceUrl/teiBadge2';
import teiFlower from '@salesforce/resourceUrl/teiFlower';

export default class TeiPortalHomePage extends NavigationMixin(LightningElement) {
    teiFooterLogo = teiFooterLogo;
    teiCornerstoneLogo = teiCornerstoneLogo;
    teiBadge1 = teiBadge1;
    teiBadge2 = teiBadge2;
	teiFlower = teiFlower;

	carouselImages = [
		{ src: teiFooterLogo, alt: "Badge 1", caption: "Badge 1" },
		{ src: teiBadge1, alt: "Badge 2", caption: "Badge 2" },
		{ src: teiBadge2, alt: "Badge 2", caption: "Badge 2" },
	];

    @track inPersonClass = [];
    @track virtualClass = [];
    @track annoucements = [];
	@track upcomingClass = [];
	@track currentRegistrantId = '';
	@track isSeries = false;
	@track showWithdraw = false;
    @track isLoading = true;
    @track useless = 0;
	@track userName = '';

	@wire(getUserName)
	receivedUserName({error, data}){
		if(data){
			this.userName = data;
		}else if(error){
			console.log(error);
		}
	}

	@wire(getUpcomingClass, {contactId: "", useless: "$useless"})
	receivedUpcomingClass({ error, data }) {
		if(data){
			var classList = [];
			var videoList = [];

			data.forEach(e => {
				if(e.startDate != 'N/A'){
					classList.push(e);
				}else{
					videoList.push(e);
				}
			});

			this.upcomingClass = classList.concat(videoList);
		}else if(error){
			console.log(error);
		}
	}

    @wire(getClass, { useless: "$useless"})
	receivedClass({ error, data }) {
		if(data) {
            data.inPerson.forEach(e => {
                this.inPersonClass.push({
                    'Id': e.Id,
                    'date': e.Class_Date__c,
                    'text': e.Title__c
                })
            });
            data.virtual.forEach(e => {
                this.virtualClass.push({
                    'Id': e.Id,
                    'date': e.Class_Date__c,
                    'text': e.Title__c
                })
            });

            console.log(JSON.stringify(this.inPersonClass));
            console.log(JSON.stringify(this.virtualClass));
		}else if(error){
			console.log(error);
		}
	}

    @wire(getAnnouncement, { useless: "$useless"})
	receivedAnnoucement({ error, data }) {
		if(data) {
            data.forEach(e => {
                var temp = {};
				temp.Id = e.Id;
                // temp.Details__c = e.Details__c.replace(/<\/?[^>]+(>|$)/g, '');
				temp.Details__c = e.Details__c;
                temp.Date__c = e.Date__c;
                if(e.Class__c == null || e.Class__c == undefined || e.Class__c == ""){
                    temp.hasClassLink = false;
                }else{
                    temp.hasClassLink = true;
                }
                temp.Class__c = e.Class__c;

                this.annoucements.push(temp);
            });
		}else if(error){
			console.log(error);
		}
	}

	handleUpcomingClassNav(event){
		var type = event.currentTarget.dataset.type;
		var videoId = event.currentTarget.dataset.videoid;
		var registrantId = event.currentTarget.dataset.registrantid;
		var classId = event.currentTarget.dataset.classid;
		var action = event.currentTarget.dataset.action;
		var contactId = event.currentTarget.dataset.contactid;

        if(type == 'Video'){
            this[NavigationMixin.Navigate]({
                type: "standard__webPage",
                attributes: {
                    url: `/tei-video?recordId=${classId}&registrantId=${registrantId}&contactId=${contactId}&fromWhere=HomePage`
                },
            },
                true,
            );
        }else if(action == 'Withdraw'){
			this.currentRegistrantId = registrantId;
			this.isSeries = event.currentTarget.dataset.isseries;
			this.showWithdraw = true;
		}else{
			this[NavigationMixin.Navigate]({
				type: "standard__recordPage",
				attributes: {
					objectApiName: "TEI_Class__c",
					actionName: "view",
					recordId: classId
				}
			});
		}
		
		console.log('type', type);
		console.log('videoId', videoId)
		console.log('registrantId', registrantId)
		console.log('classId', classId)
		console.log('action', action)
	}

	handleResetWithdraw(){
		this.showWithdraw = false;
		this.isSeries = '';
	}

    navToClass(event){
		var id = event.currentTarget.dataset.id;
		
        if(id == null || id == undefined || id == ""){
            return;
        }

        console.log(event.currentTarget.dataset.id);
		this[NavigationMixin.Navigate]({
			type: "standard__recordPage",
			attributes: {
				objectApiName: "TEI_Class__c",
				actionName: "view",
				recordId: id
			}
		});
    }

    navToEventCalendar(){
		this[NavigationMixin.Navigate]({
			type: "standard__webPage",
			attributes: {
				url: "/event-calendar",
			},
		},
			true,
		);
	}

    navToToolKit(){
		this[NavigationMixin.Navigate]({
			type: "standard__webPage",
			attributes: {
				url: "/leader-toolkit",
			},
		},
			true,
		);
    }

    navToRepaly(){
		this[NavigationMixin.Navigate]({
			type: "standard__webPage",
			attributes: {
				url: "/tei-replay",
			},
		},
			true,
		);
    }

	navToOnDemand(){
		this[NavigationMixin.Navigate]({
			type: "standard__webPage",
			attributes: {
				url: "/tei-demand",
			},
		},
			true,
		);
	}

    navToTranscript(){
		this[NavigationMixin.Navigate]({
			type: "standard__webPage",
			attributes: {
				url: "/transcript",
			},
		},
			true,
		);
    }
}