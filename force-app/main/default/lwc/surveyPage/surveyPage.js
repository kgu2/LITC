import { LightningElement, api, track, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class SurveyPage extends NavigationMixin(LightningElement) {

    @track recordId;
    @track surveyType;

    @track currentPageReference; 

    @track question1;
    @track question2;
    @track question3;
    @track question4;
    

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
       if(currentPageReference) {
           this.recordId = currentPageReference.state.id;
           this.surveyType = currentPageReference.state.type;
           console.log(this.recordId);
           console.log(this.surveyType)
       } else{
           console.log('error: could not get current page reference');
       }
    }

    renderedCallback(){ 
        var surveyRatings = this.template.querySelectorAll('c-survey-rating');

        surveyRatings.forEach(ratings => {
            ratings.addEventListener('keydown', function(event) {
                if (event.keyCode == 13 || event.keyCode == 38 || event.keyCode == 39) {
                    event.preventDefault();
                    ratings.increment();
                }
                if (event.keyCode == 37 || event.keyCode == 40) {
                    event.preventDefault();
                    ratings.decrement();
                }
            });
        });

    }

    navigateHome(){
        this[NavigationMixin.Navigate]({
            type: 'comm__namedPage',
                attributes: {
                    pageName: 'home'
            }
        })
    }

    handleError(event){
        event.preventDefault();
        console.log(JSON.stringify(event));
    }

    save() {
        this.navigateHome();
        this.showNotification('Submitting...', 'Thank you for submitting the survey!', 'success');
    }

    handleCancel(){
        this.navigateHome();
    }

    showNotification(ntf_Title, ntf_Message, ntf_Variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: ntf_Title,
                message: ntf_Message,
                variant: ntf_Variant,
                mode: 'dismissable'
            }),
        );
    }

    handleSubmit(event){
        event.preventDefault();
        const fields = event.detail.fields;

       // add different survey types here
        if(this.litc){ 
            fields.Survey_Question_Navigation__c = this.question1;
            fields.Survey_Question_Certification__c = this.question2;
            fields.Survey_Question_Overall__c = this.question3;
        }

        this.template.querySelector('.' + this.surveyType).submit(fields);
    }

    handleChange(event){
        let data = JSON.parse(JSON.stringify(event.detail));
        if(data.questionNumber === '1')  this.question1 = data.rating; 
        if(data.questionNumber === '2')  this.question2 = data.rating; 
        if(data.questionNumber === '3')  this.question3 = data.rating; 
        if(data.questionNumber === '4')  this.question4 = data.rating; 
    }

    //handle different survey types here
    get litc(){ 
        return this.surveyType == 'LITC';
    }
}