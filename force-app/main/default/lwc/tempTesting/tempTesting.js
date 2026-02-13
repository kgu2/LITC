import { LightningElement } from 'lwc';
import pubsub from 'omnistudio/pubsub';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
// import omniscriptBaseAction from 'omnistudio/omniscriptBaseAction'

export default class TempTesting extends LightningElement {

    connectedCallback() {
        console.log('in connectedCallback');


        pubsub.register('omniscript_action', {
            data: this.handleOmniActionData.bind(this),
        });

        // pubsub.register('omniscript_step', {
        //     data: this.handleOmniStepLoadData.bind(this),
        // });
    }

    handleOmniActionData(data) {
        console.log('Data => ' + JSON.stringify(data));
    }

    handleClick(){ 
        console.log('in click')

        let temp = this.template.querySelector('c-temp-temp-english');
        let tempButton = this.template.querySelector('c-button');
        let dr = this.template.querySelector('omnistudio-omniscript-dr-post-action');


        console.log(temp);
        console.log(tempButton);
        console.log(dr);
    }
    
}