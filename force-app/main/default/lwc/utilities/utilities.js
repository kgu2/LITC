import { LightningElement, api, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';


export default class Utilities extends NavigationMixin(LightningElement) {

    showNotification(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: 'dismissable'
            }));
    }

}