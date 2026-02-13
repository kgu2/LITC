import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { getDataHandler } from "omnistudio/utility";
import pubsub from 'omnistudio/pubsub';

export default class OmnistudioTestButton extends OmniscriptBaseMixin(LightningElement) {

    // @api omniJson;
    @api dr_Name;
    // @api inputValue = '';

    // jsonData; 

    // renderedCallback(){
    //     console.log('rendered');
    //     pubsub.register('omniscript_step', {
    //         data: this.handleOmniStepLoadData.bind(this),
    //     });
    // }

    // handleOmniStepLoadData(data) {
    //     console.log('temp' ); 
    //     this.jsonData = data.omniJsonData ;         
    //     console.log('jsonData -- '+ JSON.stringify(this.jsonData)  ); 
    // }
    
    // handleOmniAction(data) {
    //     console.log('in temp2' ); 
    //     this.jsonData = data.omniJsonData ;    
    //     console.log('jsonData -- '+ JSON.stringify(this.jsonData)  ); 
    //   }

    handleClick(){ 
        console.log('in here');
        console.log(JSON.stringify(this.omniJsonDataStr));

        let temp = JSON.stringify(this.omniJsonDataStr)
  
        this.callDataraptor("LITCSubmitForm13424",this.omniJsonDataStr);
    }

    callDataraptor(name,input) {
        let request_data = {
            type: "DataRaptor",
            value: {
                bundleName: name,
                inputMap: input,
                optionsMap: "{}",
            },
        };
        const result = getDataHandler(JSON.stringify(request_data))
            .then((result) => {
                //Get the result and do your post processing
                const jsonResult = JSON.parse(result);
                console.log('DR Result',JSON.stringify(jsonResult));
                return jsonResult;
            }).catch((err) => {
                //Handle your errors
                console.log("error is ", err);
            });
        return result;

    }



    handleSave(event) { 
        const records = event.detail.draftValues.slice().map((draftValue) => { 
            //Convert datatable draft values into record objects
            console.log("draftValue",JSON.stringify(draftValue));
            const fields = Object.assign({}, draftValue);
            return  fields;
        });
        this.draftValues = [];// Clear all datatable draft values
        let tempObject={};
        tempObject.updateList = []; //array to store records to update using load dataraptor also need to use same array name in dataraptor to bind data. 
        records.forEach(data=>{
            tempObject.updateList.push(data); 
        })
        console.log("Outs"+JSON.stringify(tempObject));
         const options = { "isDebug": true, "chainable": false, "resetCache": false, 
                           "ignoreCache": true, "queueableChainable": false, "useQueueableApexRemoting": false }
            const datasource = JSON.stringify({
                type: 'dataraptor',
                value: {
                    bundleName: 'DR_InvokeUpdate',  //This will be dataraptor name(required)
                    inputMap: tempObject,//which contains the values to update(required)
                    optionsMap: options // which contains the options(optional)
                }
            });
            
         getDataHandler(datasource).then(data => { //getDatahandler method to call dataraptor
             console.log('outputload-->'+data);
             this.callSearchaccount();
         }). catch (error=> {
            console.log('error:'+error.body.message);
        });
    }
}