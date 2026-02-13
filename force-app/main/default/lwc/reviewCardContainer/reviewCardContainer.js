import { LightningElement, api, track, wire } from 'lwc'; 
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getQuestions from '@salesforce/apex/ReviewCardController.getQuestions';
import getSummaryQuestions from '@salesforce/apex/ReviewCardController.getSummaryQuestions';
import { getRecord, getFieldValue, getRecordNotifyChange } from 'lightning/uiRecordApi';
import STATUS from '@salesforce/schema/Review_Card__c.Status__c';
import { refreshApex } from '@salesforce/apex';
import utilities from 'c/utilities';
import { updateRecord } from 'lightning/uiRecordApi';
import SCORE from '@salesforce/schema/Review_Card__c.Score__c';
import VERSION from '@salesforce/schema/Review_Card__c.Version__c';

const fields = [STATUS, SCORE, VERSION];

export default class ReviewCardContainer extends utilities {

    @api recordId;
    @track questions;

    @api sectionQuestions = [];
    @api sections = [];

    @track score;
    @track reviewStatus;
    @track version;

    @track activeTab;

    @track totalScore; totalMaxScore; totalWeights; totalScoredPoints;

    @track summaryAnswerId;
    @track summaryQuestions;

    // summary tab
    @track selectedSummaryId;
    @track selectedSummaryName;
    @track showEditSummaryModal;

    @wire(getRecord, { recordId: '$recordId', fields: fields })
    setReviewcardData({ error, data }) {
        if(data){
            this.score = getFieldValue(data, SCORE);
            this.reviewStatus = getFieldValue(data, STATUS);
            this.version = getFieldValue(data, VERSION);
        }
        else if(error){ console.log(error);}
    }

    @wire(getQuestions, { recordId: '$recordId' })
    setReviewQuestions(result) {
        this.result = result
        if (result.data) {
            console.log(result.data);

            getSummaryQuestions({recordId: this.recordId}).then(res=>{ 
                console.log(res);
                this.summaryQuestions = res;

                // map the questions to each section
                const sectionMap = {};
                result.data.forEach(question => {
                    if (!sectionMap[question.Section__c]) {
                        sectionMap[question.Section__c] = { 
                            questions: [], 
                            totalScore: 0, 
                            maxScore: 0, 
                            weight: question.Section_Weight__c
                        };
                    }
                    sectionMap[question.Section__c].questions.push(question);
                    if(question.Score__c) sectionMap[question.Section__c].totalScore += question.Score__c;
                });

                // convert object to array
                this.questions = Object.keys(sectionMap).map(section => ({
                    sectionName: section,
                    questions: sectionMap[section].questions,
                    totalScore: sectionMap[section].totalScore,
                    maxScore: (sectionMap[section].questions.length * 5),
                    weight: sectionMap[section].weight,
                    weightedScore: sectionMap[section].totalScore / (sectionMap[section].questions.length * 5) * ((sectionMap[section].weight)),
                    tabClass: ''
                }));

                console.log(JSON.stringify(this.questions));

                // calculate totals 
                const totalScores = this.questions.reduce((acc, section) => {
                    acc.totalScore += section.totalScore;
                    acc.maxScore += section.maxScore;
                    acc.weight += section.weight;
                    acc.weightedScore += section.weightedScore;
                    return acc;
                }, { totalScore: 0, maxScore: 0, weight: 0, weightedScore: 0 });
                
                this.totalScore = totalScores.totalScore;
                this.totalMaxScore = totalScores.maxScore;
                this.totalWeights = totalScores.weight;
                this.totalScoredPoints = totalScores.weightedScore;

                // set defaults
                const backgroundItem = res.find(i => i.Section_Summary__c === 'Background');
                this.summaryAnswerId = backgroundItem ? backgroundItem.Id : null;

                if(!this.activeTab) this.activeTab = this.questions[0].sectionName;
                this.updateTabClasses();

                if(this.summaryQuestions){ 
                    let question = this.summaryQuestions.find(i => i.Section_Summary__c === this.activeTab);
                    this.summaryAnswerId = question ? question.Id : null;
                }
            }).catch(error=>{ 
                console.log(error);
            })
            
        } else if (result.error) {
            console.log(result.error);
        }
    }

    handleRefresh(){ 
        refreshApex(this.result);

        console.log('REFRESHING')


    }

    handleOnActive(event){ 
        this.activeTab = event.target.value;
        this.updateTabClasses();

        console.log('in handleOnActive')
        if(this.summaryQuestions){ 
            let question = this.summaryQuestions.find(i => i.Section_Summary__c === this.activeTab);
            this.summaryAnswerId = question ? question.Id : null;
            console.log('SUmmary answer id');
            console.log(this.summaryAnswerId);
        }
    }

    handleSubmitRC(event){ 
        event.preventDefault();

        let hasScored =  this.result.data.every(obj => obj.Score__c !== null && obj.Score__c !== undefined);

        if(!hasScored){ 
            this.showNotification('Error', 'All questions must be scored', 'error');
        } else{ 
            this.template.querySelector('.submitForm').submit();
            updateRecord({ fields: { Id: this.recordId, 'Status__c': 'Submitted', 'Weighted_Score__c' : this.totalScoredPoints} }).then(()=>{
                this.showNotification('Success', 'Review card submitted', 'success');
                getRecordNotifyChange([{recordId: this.recordId}]);
            }).catch(error=>{
                console.log(error);
            })
        }
    }

    navigateToQuestion(event){
         const questionId = event.target.dataset.key;
         if (questionId) {
            const targetElement = this.template.querySelector(`c-review-question[data-key="${questionId}"]`);
            if (targetElement) {
                // targetElement.scrollIntoView({ behavior: "smooth", block: "start" });
                const element = targetElement.getBoundingClientRect();
                window.scrollTo({
                    top: (window.scrollY + element.top) - 200,
                    behavior: "smooth"
                });
            }
        }
    }

    handleSave(field, value){ 
        updateRecord({fields: {Id: this.recordId, [field]: value}});
    }
    autosave(event){ 
        this.handleSave(event.target.fieldName, event.target.value);
    }

    handleSaveV2(field, value){ 
        updateRecord({fields: {Id: this.summaryAnswerId, [field]: value}});
    }
    autosaveV2(event){ 
        this.handleSaveV2(event.target.fieldName, event.target.value);
    }

    autosaveV3(event){ 
        updateRecord({fields: {Id: this.selectedSummaryId, [event.target.fieldName]: event.target.value}});
    }

    handleNav(event){ 
        const sectionNames = this.questions.map(item => item.sectionName);
        if (!sectionNames.includes('Submit')) {
            sectionNames.push('Submit');
        }

        const currentIndex = sectionNames.indexOf(this.activeTab);

        if (event.target.label === "Next" && currentIndex < sectionNames.length - 1) {
            this.activeTab = sectionNames[currentIndex + 1];
        } else if (event.target.label === "Back" && currentIndex > 0) {
            this.activeTab = sectionNames[currentIndex - 1];
        }
        this.template.querySelector('lightning-tabset').activeTabValue = this.activeTab

        console.log(JSON.stringify(sectionNames))
    }

    handleSummarySectionClick(event){ 
        this.showEditSummaryModal = false;

        let summaryQuestion = this.summaryQuestions.find((question) => question.Section_Summary__c == event.target.dataset.value);

        setTimeout(() => {
            if(summaryQuestion) {
                this.selectedSummaryId = summaryQuestion.Id;
                this.selectedSummaryName = summaryQuestion.Section_Summary__c;
            }
            this.showEditSummaryModal = true;
        }, 350); 

    }

    closeEditSummaryModal(){
        this.showEditSummaryModal = false;
    }
    
    updateTabClasses() {
        this.questions = this.questions.map(group => ({
            ...group,
            tabClass: this.activeTab === group.sectionName ? 'slds-show' : 'slds-hide'
        }));
    }
    get showSubmitTab(){
        return this.activeTab === 'Submit' ? 'slds-show' : 'slds-hide';
    }
    get totalPoints(){ 
        return (this.result.data.length) * 5;
    }

    get disableEdits(){ 
        return this.reviewStatus === 'Submitted';
    }
    get isNotSubmitted(){ 
        return this.reviewStatus !== 'Submitted';
    }

    get isNotFirstTab(){
        return this.activeTab !== 'Background';
    }
    get isNotLastTab(){
        return this.activeTab !== 'Submit';
    }

}