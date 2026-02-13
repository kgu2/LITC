import { LightningElement, api } from 'lwc';

export default class App605Instructions extends LightningElement {

    @api recipType;
    @api secondTranche;

    handleNav(event){
        //console.log(event.target.name)
        const selectedEvent = new CustomEvent("changetab", {
            detail: event.target.name
        });
        this.dispatchEvent(selectedEvent);
    }

    get county(){ 
        return this.recipType == 'Eligible Revenue Sharing County';
    }

    get tribal(){ 
        return this.recipType == 'Tribal Government';
    }
}