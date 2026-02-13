// import { LightningElement, track, wire } from 'lwc';
// import { refreshApex } from "@salesforce/apex";
// import { NavigationMixin } from 'lightning/navigation';
// import USER_ID from '@salesforce/user/Id';
// import teiComingSoon from '@salesforce/resourceUrl/teiComingSoon'; // replace with your static resource

// import getOnDemandClasses from '@salesforce/apex/teiSessionController.getOnDemandClasses';
// import getContactInfo from '@salesforce/apex/teiSessionController.getContactInfo';

// export default class TeiOnDemand extends NavigationMixin(LightningElement) {
//     @track categories = [];
//     @track showOnDemand = true;
//     @track showVideoPlayBack = false;
//     @track targetClassId = '';
//     @track isLoading = false;
//     @track registrantId = null;
//     @track contactId = null;

//     imageUrl = teiComingSoon; 
//     MAX_PER_ROW = 4;
//     //MAX_VIDEO_COUNT_LENGTH = 4;

//     categoryMap = {
//         'Leadership Fundamentals': {
//             label: 'Leadership Fundamentals',
//             description: null },
//         'Strategic Thinking Fundamentals': {
//             label: 'Strategic Thinking Fundamentals',
//             description: null },
//         'TEIs Leadership Jumpstart Programs': {
//             label: 'TEIs Leadership Jumpstart Programs',
//             description: 'Have you ever wanted to quickly build your capacity in a particular leadership area? ' +
//              'TEI’s Leadership Jumpstart Programs are curated around a topic or theme so you can leverage them ' + 
//              'to grow in areas that matter most to you. These on-demand programs include videos, podcasts, ' + 
//              'reference materials, and activities so you can learn at your own pace.' }
//     };

//     connectedCallback() {
//         // Initialize empty category structure
//         this.categories = Object.keys(this.categoryMap).map(key => ({
//             key,
//             label: this.categoryMap[key].label,
//             description: this.categoryMap[key].description,
//             items: [],
//             hasItems: false
//         }));

//         this.getContactIdEmailInfo();
//     }

//     getContactIdEmailInfo(){
//         getContactInfo({ userId : USER_ID })
//         .then((result) => {
//             if (result != null){
//                 this.contactId = result.Id;
//                 this.contactEmail = result.Email;
                
//                 console.log('getContactId contactId = : ', JSON.stringify(this.contactId));
//                 console.log('getContactEmail contactEmail = : ', JSON.stringify(this.contactEmail));
//             } 
            
//             this.getOnDemandClassesInfo();
//         })
//         .catch((err) => {
//             console.log("getContactEmail error " + err);
//             console.log("getContactEmail message  " + err.message);
//         });
//     }

//     // @wire(getOnDemandClasses)
//     // receivedOnDemandClasses({ error, data }) {
//     //     if (data) {
//     //         console.log(data);
//     //         data.forEach(item => {
//     //             // const classObj = {
//     //             //     Id: item.Id,
//     //             //     Title: item.Title__c,
//     //             //     videoThumbnail: `https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`
//     //             // };

//     //             let classObj = {
//     //                     Id: item.Id,
//     //                     Title: item.Title__c,
//     //                     isVideo: false,
//     //                     hasVideo: false,
//     //                     videoThumbnail: null, //`https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`
//     //                     isClass: false,
//     //                     hasDefaultimage: false
//     //                 };                    

//     //             for (const cat of this.categories) {
//     //                 if (item.On_Demand_Category__c?.includes(cat.key)) {

//     //                     if (item.Type__c?.includes('Video')) {
//     //                         classObj.isVideo = true;
//     //                         if (item.Video_Id__c != 'none'){
//     //                             classObj.videoThumbnail = `https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`;
//     //                             classObj.hasVideo = true;
//     //                         } else {
//     //                             //cat.videoThumbnail = imageUrl;
//     //                             classObj.hasDefaultimage = true;
//     //                         }
//     //                     } else {
//     //                         classObj.isClass = true;
//     //                     }

//     //                     cat.items.push(classObj);
//     //                     cat.hasItems = true;
//     //                 }                    
//     //                 console.log('receivedOnDemandClasses cat.items = : ', JSON.stringify(cat.items));
//     //             }
//     //         });
//     //     } else if (error) {
//     //         console.error('Error fetching videos:', error);
//     //     }
//     // }

//     getOnDemandClassesInfo(){
//         getOnDemandClasses()
//         .then((result) => {
//             if (result != null){
    
//                 console.log(result);
//                 result.forEach(item => {
//                     // const classObj = {
//                     //     Id: item.Id,
//                     //     Title: item.Title__c,
//                     //     videoThumbnail: `https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`
//                     // };

//                     let classObj = {
//                             Id: item.Id,
//                             Title: item.Title__c,
//                             isVideo: false,
//                             hasVideo: false,
//                             videoThumbnail: null, //`https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`
//                             isClass: false,
//                             hasDefaultimage: false
//                         };                    

//                     for (const cat of this.categories) {
//                         if (item.On_Demand_Category__c?.includes(cat.key)) {

//                             if (item.Type__c?.includes('Video')) {
//                                 classObj.isVideo = true;
//                                 if (item.Video_Id__c != 'none'){
//                                     classObj.videoThumbnail = `https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`;
//                                     classObj.hasVideo = true;
//                                 } else {
//                                     //cat.videoThumbnail = imageUrl;
//                                     classObj.hasDefaultimage = true;
//                                 }
//                             } else {
//                                 classObj.isClass = true;
//                             }

//                             cat.items.push(classObj);
//                             cat.hasItems = true;
//                         }                    
//                         console.log('receivedOnDemandClasses cat.items = : ', JSON.stringify(cat.items));
//                     }
//                 });
//             }
//         }).catch((err) => {
//             console.log("getContactEmail error " + err);
//             console.log("getContactEmail message  " + err.message);
//         });
//     }

//     async reloadData(){
//         this.isLoading = true;
//         await refreshApex(this.receivedOnDemandClasses);
//         this.showOnDemand = true;
//         this.showVideoPlayBack = false;
//         this.isLoading = false;
//     }

//     // handleVideoNav(event) {
//     //     this.targetClassId = event.currentTarget.dataset.id;
//     //     this.showOnDemand = false;
//     //     this.showVideoPlayBack = true;
//     // }

//     handleNavToClass(event) {
//         event.stopPropagation();
//         this[NavigationMixin.Navigate]({
//             type: "standard__recordPage",
//             attributes: {
//                 objectApiName: "TEI_Class__c",
//                 actionName: "view",
//                 recordId: event.currentTarget.dataset.id
//             }
//         });
//     }
    
// }

import { LightningElement, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import USER_ID from '@salesforce/user/Id';
import teiComingSoon from '@salesforce/resourceUrl/teiComingSoon';
import getOnDemandClasses from '@salesforce/apex/teiSessionController.getOnDemandClasses';
import getContactInfo from '@salesforce/apex/teiSessionController.getContactInfo';

export default class TeiOnDemand extends NavigationMixin(LightningElement) {
  @track categories = [];
  @track showOnDemand = true;
  @track showVideoPlayBack = false;
  @track isLoading = false;
  @track contactId = null;

  imageUrl = teiComingSoon;
  MAX_PER_ROW = 4;

  categoryMap = {
    'Leadership Fundamentals': { label: 'Leadership Fundamentals', description: null },
    'Strategic Thinking Fundamentals': { label: 'Strategic Thinking Fundamentals', description: null },
    'TEIs Leadership Jumpstart Programs': {
      label: 'TEIs Leadership Jumpstart Programs',
      description:
        'Have you ever wanted to quickly build your capacity in a particular leadership area? ' +
        'TEI’s Leadership Jumpstart Programs are curated around a topic or theme so you can leverage them ' +
        'to grow in areas that matter most to you. These on-demand programs include videos, podcasts, ' +
        'reference materials, and activities so you can learn at your own pace.'
    }
  };

  connectedCallback() {
    this.categories = Object.keys(this.categoryMap).map(key => ({
      key,
      label: this.categoryMap[key].label,
      description: this.categoryMap[key].description,
      items: [],
      displayItems: [],
      hasItems: false,
      expanded: false,
      showToggle: false,
      showAllLabel: 'Show All'
    }));
    this.getContactIdEmailInfo();
  }

  getContactIdEmailInfo() {
    getContactInfo({ userId: USER_ID })
      .then(result => {
        if (result) {
          this.contactId = result.Id;
        }
        this.getOnDemandClassesInfo();
      })
      .catch(err => console.error('Contact info error', err));
  }

  getOnDemandClassesInfo() {
    getOnDemandClasses()
      .then(result => {
        if (!result) return;

        result.forEach(item => {
          const classObj = {
            Id: item.Id,
            Title: item.Title__c,
            isVideo: false,
            hasVideo: false,
            videoThumbnail: null,
            isClass: false,
            hasDefaultimage: false
          };

          for (const cat of this.categories) {
            if (item.On_Demand_Category__c?.includes(cat.key)) {

              // 🟢 Special rule: Jumpstart = always Class (never Video)
              if (cat.key === 'TEIs Leadership Jumpstart Programs') {
                classObj.isClass = true;
                classObj.hasVideo = false;
                classObj.hasDefaultimage = false;
              } 
              else if (item.Type__c?.includes('Video')) {
                classObj.isVideo = true;
                if (item.Video_Id__c && item.Video_Id__c !== 'none') {
                  classObj.videoThumbnail = `https://img.youtube.com/vi/${item.Video_Id__c}/hqdefault.jpg`;
                  classObj.hasVideo = true;
                } else {
                  classObj.hasDefaultimage = true;
                }
              } 
              else {
                classObj.isClass = true;
              }

              cat.items.push(classObj);
              cat.hasItems = true;
            }
          }
        });

        // Sort newest first and set display arrays
        this.categories.forEach(cat => {
          cat.items.reverse();
          cat.displayItems = cat.items.slice(0, this.MAX_PER_ROW);
          cat.showToggle = cat.items.length > this.MAX_PER_ROW;
        });
      })
      .catch(err => console.error('On-Demand load error', err));
  }

  toggleShowAll(event) {
    const key = event.currentTarget.dataset.key;
    this.categories = this.categories.map(cat => {
      if (cat.key === key) {
        cat.expanded = !cat.expanded;
        cat.displayItems = cat.expanded ? cat.items : cat.items.slice(0, this.MAX_PER_ROW);
        cat.showAllLabel = cat.expanded ? 'Show Less' : 'Show All';
      }
      return cat;
    });
  }

  handleNavToClass(event) {
    this[NavigationMixin.Navigate]({
      type: 'standard__recordPage',
      attributes: {
        objectApiName: 'TEI_Class__c',
        actionName: 'view',
        recordId: event.currentTarget.dataset.id
      }
    });
  }
}