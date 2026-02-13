import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { getDataHandler } from "omnistudio/utility";

// const columns = [
//     { label: 'Federal expense', fieldName: 'fieldOne',hideDefaultActions: true, editable: true, type: 'currency'},
//     { label: 'Match expense', fieldName: 'fieldTwo', hideDefaultActions: true, editable: true, type: 'currency'},
//     { label: 'Total', fieldName: 'fieldThree', hideDefaultActions: true, type: 'currency'},
// ];

[
    { label: 'Federal expense', fieldName: 'fieldOne',hideDefaultActions: true, editable: true, type: 'currency'},
    { label: 'Match expense', fieldName: 'fieldTwo', hideDefaultActions: true, editable: true, type: 'currency'},
    { label: 'Total', fieldName: 'fieldThree', hideDefaultActions: true, type: 'currency'},
]

export default class OmnistudioCustomDataTable extends OmniscriptBaseMixin(LightningElement)  {

    // @api dr_Name;

    @track columns;
    @track records;
    @track saveDraftValues = [];

    @api testing;

    connectedCallback(){ 
        console.log('rendejghred');
        let request_data = {
            type: "DataRaptor",
            value: {bundleName: 'testDatatableLoad'}
        };
        const result = getDataHandler(JSON.stringify(request_data))
            .then((result) => {
                const jsonResult = JSON.parse(result);
                console.log('DR Result',JSON.stringify(jsonResult));

          
                console.log(typeof jsonResult);
                this.records = jsonResult;
                return jsonResult;
            }).catch((err) => {

                console.log("error is ", err);
            });

    
            this.columns = JSON.parse(this.testing);
    }

    handleDataTableSave(event) {
        this.saveDraftValues = event.detail.draftValues;
        const recordInputs = this.saveDraftValues.slice().map(draft => {
            const fields = Object.assign({}, draft);
            return { fields };
        });
        const promises = recordInputs.map(recordInput => {
            // updateRecord(recordInput);
            
            // call DRload
            console.log(recordInput);
            console.log(JSON.stringify(recordInput));
        });
        Promise.all(promises).then(() => {
            console.log('SUCCESS')
            // this.showNotification('Updating...', 'Your Record has been updated.', 'success');
        }).catch(error => {
            console.log(error);
        }).finally(() => {
            this.saveDraftValues = [];
                    // call getDataDR
        });

    


    }


    // on load get all nodes from JSON, 
    // pass in list of labels and list of nodes -> create columns based on passed in info
    // on datatable instead of updateRecord maybe call DR load function.

    // callSearchaccount() {
    //     if (this.accountName != null && this.accountName != undefined && this.accountName != '') {//accountName contains the search value
    //         this.isSearchButtonClicked = true;
    //         let tempObject={
    //             name:this.accountName// add filter values to your request(you can add single/multiple input params)
    //         }
    //         const options = { "isDebug": true, "chainable": false, "resetCache": false, "ignoreCache": true,
    //                           "queueableChainable": false, "useQueueableApexRemoting": false }
    //         const datasource = JSON.stringify({  //datasource contains the params which need to pass
    //             type: 'dataraptor',
    //             value: {
    //                 bundleName: 'DR_getAccounts',  //This will be dataraptor name(required)
    //                 inputMap: tempObject, // which contains the filter values(optional)
    //                 optionsMap: options // which contains the options(optional)
    //             }
    //         });

    //         getDataHandler(datasource).then(data => { //getDatahandler method to call dataraptor
    //         console.log(data);
    //             let Jsondata = JSON.parse(data); // you will get output data as JSON, you need to use PARSE method to convert into Object array
    //             //console.log('output--->', JSON.stringify(Jsondata[0].acc));
    //             let JsonArray = Jsondata[0].acc;// where acc is the object/json varaible declared on dataraptor
    //             if (Array.isArray(JsonArray))// to check whether results has single/multiple account records
    //                 this.accountList = Jsondata[0].acc;
    //             else {
    //                 let tempArray = [];
    //                 tempArray.push(JsonArray);
    //                 this.accountList = tempArray;// pass data to lwc datatable
    //             }
    //         }).catch(err => {
    //             console.error(`Error fetching data ==> ${JSON.stringify(err)}`);

    //         });
    //     }
    // }
}