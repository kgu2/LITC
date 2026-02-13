import {LightningElement} from 'lwc';
import pubsub from 'omnistudio/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import omniscriptBaseAction from 'omnistudio/omniscriptBaseAction'

export default class omniscriptCustomListener extends omniscriptBaseAction {

    connectedCallback() {
        console.log('I AM HERE')
        pubsub.register('omniscript_action', {
            data: this.handleOmniActionData.bind(this),
        });
    }

    handleOmniActionData(data) {
        console.log('Data => ' + JSON.stringify(data));
        //ShowToastEvent from here
    }

    // handle different events here...show toast on save, show toast on no sam.gov, etc.
}