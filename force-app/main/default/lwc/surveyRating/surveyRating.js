import { LightningElement, track, api } from "lwc";

export default class SurveyRating extends LightningElement {

    @api questionNumber;
    @track rating;

    @api typeAlt;

    renderedCallback(){
        const topDiv = this.template.querySelector('.rate');
        topDiv.scrollIntoView({behavior: "smooth", block: "center", inline: "nearest"});
    }

    handleRatingChange(event) {
        this.rating = event.target.value;

        const selectedEvent = new CustomEvent("starvaluechange", {detail: {
            'rating': this.rating, 
            'questionNumber': this.questionNumber
        }});
        this.dispatchEvent(selectedEvent);
    }


    @api
    increment(){ 
        if (this.typeAlt == true){
            if(this.rating == undefined) this.rating = 'Very Ineffective';
                else if(this.rating == 'Very Ineffective') this.rating = 'Ineffective';
                else if(this.rating == 'Ineffective') this.rating = 'Neutral';
                else if(this.rating == 'Neutral') this.rating = 'Effective';
                else if(this.rating == 'Effective') this.rating = 'Very Effective';
                else if(this.rating == 'Very Effective') this.rating = 'Very Ineffective';
        }

        else{
            if(this.rating == undefined) this.rating = 'Highly Dissatisfied';
            else if(this.rating == 'Highly Dissatisfied') this.rating = 'Dissatisfied';
            else if(this.rating == 'Dissatisfied') this.rating = 'Neutral';
            else if(this.rating == 'Neutral') this.rating = 'Satisfied';
            else if(this.rating == 'Satisfied') this.rating = 'Highly Satisfied';
            else if(this.rating == 'Highly Satisfied') this.rating = 'Highly Dissatisfied';
        }
        this.template.querySelector("input[value='" + this.rating + "']").checked = true;
        
        const selectedEvent = new CustomEvent("starvaluechange", {detail: {
            'rating': this.rating, 
            'questionNumber': this.questionNumber
        }});
        this.dispatchEvent(selectedEvent);
    }

    @api 
    decrement(){ 

        if (this.typeAlt == true){
            if(this.rating == undefined) this.rating = 'Very Effective';
                else if(this.rating == 'Very Effective') this.rating = 'Effective';
                else if(this.rating == 'Effective') this.rating = 'Neutral';
                else if(this.rating == 'Neutral') this.rating = 'Ineffective';
                else if(this.rating == 'Ineffective') this.rating = 'Very Ineffective';
                else if(this.rating == 'Very Ineffective') this.rating = 'Very Effective';
        }
        
        else{
        if(this.rating == undefined) this.rating = 'Highly Satisfied';
        else if(this.rating == 'Highly Satisfied') this.rating = 'Satisfied';
        else if(this.rating == 'Satisfied') this.rating = 'Neutral';
        else if(this.rating == 'Neutral') this.rating = 'Dissatisfied';        
        else if(this.rating == 'Dissatisfied') this.rating = 'Highly Dissatisfied';
        else if(this.rating == 'Highly Dissatisfied') this.rating = 'Highly Satisfied';
        }

        this.template.querySelector("input[value='" + this.rating + "']").checked = true;
        
        const selectedEvent = new CustomEvent("starvaluechange", {detail: {
            'rating': this.rating, 
            'questionNumber': this.questionNumber
        }});
        this.dispatchEvent(selectedEvent);
    }

}