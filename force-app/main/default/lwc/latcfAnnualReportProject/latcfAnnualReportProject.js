import { LightningElement, wire, api, track } from 'lwc';
import { deleteRecord, getFieldValue, getRecord, updateRecord } from 'lightning/uiRecordApi';
import FileUtilities from 'c/fileUtilities';
import getInfrastructureFields from '@salesforce/apex/LATCFComplianceController.getInfrastructureFields';


export default class LatcfAnnualReportProject extends FileUtilities {

    @api reportId;
    @api recordId;
    @api allocationAmount;
    @api disableEdits;

    @track totals = {
        one : {
            cumulativeObl : 0, cumulativeExp : 0, currentPeriodObl : 0, currentPeriodExp : 0
        }, 
        two : {
            cumulativeObl : 0, cumulativeExp : 0, currentPeriodObl : 0, currentPeriodExp : 0
        },
        three : {
            cumulativeObl : 0, cumulativeExp : 0, currentPeriodObl : 0, currentPeriodExp : 0
        },
        four : {
            cumulativeObl : 0, cumulativeExp : 0, currentPeriodObl : 0, currentPeriodExp : 0
        }
    };

    @track grandTotal = {
        cumulativeObl : 0, cumulativeExp : 0, currentPeriodObl : 0, currentPeriodExp : 0
    }

    @track remainingAllocation;

    @track statusIncomplete = {one : false, two : false, three : false, four : false}
    @track showHelpPopoverOne; showHelpPopoverTwo; showHelpPopoverThree; showHelpPopoverFour; showHelpPopoverFive

    // validations
    @track showCumulativeOblNeg; showCumulativeExpNeg;
    @track showCurrentPeriodOblError; showCurrentPeriodExpError
    @track showCumulativeOblError; showCumulativeExpError;
    @track showCumulativeExpGreaterObl; showCurrentPeriodExpGreaterObl

    @track initialCumulativeOblNeg1; initialCumulativeOblNeg2; initialCumulativeOblNeg3; initialCumulativeOblNeg4;
    @track initialCumulativeExpNeg1; initialCumulativeExpNeg2; initialCumulativeExpNeg3; initialCumulativeExpNeg4;
    @track initialCumulativeExpGreatObl1; initialCumulativeExpGreatObl2; initialCumulativeExpGreatObl3; initialCumulativeExpGreatObl4;

    @track hasRendered = false;

    renderedCallback(){ 
        // only get the totals once on render when page first loads
        // do something else other than hard code a time...
        if(!this.hasRendered){ 
            setTimeout(()=>{ 
                console.log("GETTING SUMMARY")
                this.handleInitialValidations();
                this.getCheckboxValues();
                this.getTotalSummary();
                this.getErrorSummary();
                this.getGrandTotal();
                this.dispatchEvent(new CustomEvent('getwait', { detail: true }));
            }, 9000); 

        }
        this.hasRendered = true;
        this.handleInitialValidations();
    }


    handleError(event){ 
        console.log(JSON.stringify(event.detail));
    }

    handleSave(field, value){ 
        updateRecord({fields: {Id: this.reportId, [field]: value}});
    }

    autosave(event){ 

        if(event.target.dataset.type === 'cumulativeObl'){ 
            let showError = false;
            const fields = this.template.querySelectorAll("[data-category='" + event.target.dataset.category + "']");
            fields.forEach(field=>{ 
                if(field.value && field.value < 0){ 
                    showError = true
                }
            })

            if(event.target.dataset.category === 'one')this.initialCumulativeOblNeg1 = showError;
            if(event.target.dataset.category === 'two')this.initialCumulativeOblNeg2 = showError;
            if(event.target.dataset.category === 'three')this.initialCumulativeOblNeg3 = showError;
            if(event.target.dataset.category === 'four')this.initialCumulativeOblNeg4 = showError;
        }

        if(event.target.dataset.type === 'cumulativeExp'){ 
            let showError = false;
            const fields = this.template.querySelectorAll("[data-category='" + event.target.dataset.category + "']");
            fields.forEach(field=>{ 
                if(field.value && field.value < 0){ 
                    showError = true
                }
            })

            if(event.target.dataset.category === 'one')this.initialCumulativeExpNeg1 = showError;
            if(event.target.dataset.category === 'two')this.initialCumulativeExpNeg2 = showError;
            if(event.target.dataset.category === 'three')this.initialCumulativeExpNeg3 = showError;
            if(event.target.dataset.category === 'four')this.initialCumulativeExpNeg4 = showError;
        }

        if(event.target.dataset.type === 'cumulativeObl' || event.target.dataset.type === 'cumulativeExp'){ 
            let showError = false;
            const fieldObl = this.template.querySelectorAll("[data-category='" + event.target.dataset.category + "'][data-type='cumulativeObl']");
            const fieldExp = this.template.querySelectorAll("[data-category='" + event.target.dataset.category + "'][data-type='cumulativeExp']");

            fieldExp.forEach((field,index)=>{ 
                console.log(field.value);
                if( (fieldObl[index].value != null && field.value != null) && (fieldObl[index].value != '' && field.value != '') && Number.parseFloat(field.value) > Number.parseFloat(fieldObl[index].value)){ 
                    showError =true;
                }
            })
   
            if(event.target.dataset.category === 'one')this.initialCumulativeExpGreatObl1 = showError;
            if(event.target.dataset.category === 'two')this.initialCumulativeExpGreatObl2 = showError;
            if(event.target.dataset.category === 'three')this.initialCumulativeExpGreatObl3 = showError;
            if(event.target.dataset.category === 'four')this.initialCumulativeExpGreatObl4 = showError;
        }



        this.handleSave(event.target.fieldName, event.target.value);
        this.getTotals(event.target.dataset.category, event.target.dataset.type);
        this.getErrors(event.target.dataset.category);
        this.getGrandTotal();

        // if(event.target.value != null && event.target.value < 0 &&  event.target.dataset.type === 'cumulativeObl'){ 
        //     console.log("ERRRO")
        // } else{ 
        //     this.handleSave(event.target.fieldName, event.target.value);
        //     this.getTotals(event.target.dataset.category, event.target.dataset.type);
        //     this.getErrors(event.target.dataset.category);
        //     this.getGrandTotal();
        // }
    }

    @api handleTEST(){ 
        // event.preventDefault();
        // const fields = event.detail.fields;
        // this.template.querySelector('lightning-record-edit-form').submit(fields);

        const test = this.template.querySelectorAll('lightning-input-field');
        const updateFields = { Id: this.reportId };

        test.forEach((input) => {
            updateFields[input.fieldName] = input.value;
        });

        updateRecord({ fields: updateFields }).then(()=>{
            console.log("RECORD SAVED")
        }).catch(error=>{
            console.error(error);
        })
        

    }

    handleCheckbox(event){ 
        let value = event.target.checked == true ? 'Yes' : 'No'
        updateRecord({fields: {Id: this.reportId, [event.target.dataset.fieldName]: value}});
    }

    getTotals(category, type){ 
        const fields = this.template.querySelectorAll("[data-category='" + category + "'][data-type='" + type + "']");
        let temp = 0;
        fields.forEach(field => {
            if(!field.value){ 
                // console.log("ERROR NAN - " + field.fieldName);
            } else{ 
                temp += parseFloat(field.value);
            }
        });
        this.totals[category][type] = temp;
        console.log(temp);
    }

    getErrors(category){ 
        let temp = false;
        const fields = this.template.querySelectorAll("[data-category='" + category + "']");
        fields.forEach(field => {
            if(field.value == null || !field.value.toString()){ 
                temp = true;
            } 
        });   
        this.statusIncomplete[category] = temp;
    }

    // gets the totals for all categories
    getGrandTotal(){ 
        let temp1 = 0, temp2 = 0, temp3 = 0, temp4 = 0;
        Object.entries(this.totals).forEach(category=>{ 
            temp1 += Number.parseFloat(category[1].cumulativeObl);
            temp2 += Number.parseFloat(category[1].cumulativeExp);
            temp3 += Number.parseFloat(category[1].currentPeriodObl);
            temp4 += Number.parseFloat(category[1].currentPeriodExp);
        });

        this.grandTotal.cumulativeObl = temp1.toFixed(2);
        this.grandTotal.cumulativeExp = temp2.toFixed(2);
        this.grandTotal.currentPeriodObl = temp3.toFixed(2);
        this.grandTotal.currentPeriodExp = temp4.toFixed(2);

        this.dispatchEvent(new CustomEvent('gettotals', { detail: this.grandTotal }));


        this.remainingAllocation =  this.allocationAmount - this.grandTotal.cumulativeExp ;

        // handle Validations for Grand Totals
        this.getValidations();
    }


    // these are used for when the page first loads to get the totals and error summary

    // gets all totals for each category
    getTotalSummary(){ 
        Object.entries(this.totals).forEach(category=>{ 
            for(let keys in category[1]){ 
                this.getTotals(category[0], keys);
            }
        });
    }

    // gets all errors for all categories
    getErrorSummary(){ 
        this.getErrors('one');
        this.getErrors('two');
        this.getErrors('three');
        this.getErrors('four');
    }

    // validations for all cumulative values
    getValidations(){ 
        console.log('in getValdiations');
        console.log(this.grandTotal.currentPeriodExp);
        console.log(this.grandTotal.cumulativeExp);
        
        this.showCumulativeOblNeg = Number.parseFloat(this.grandTotal.cumulativeObl) < 0;
        this.showCumulativeExpNeg = Number.parseFloat(this.grandTotal.cumulativeExp) < 0;
        this.showCurrentPeriodExpError = Number.parseFloat(this.grandTotal.currentPeriodExp) > Number.parseFloat(this.grandTotal.cumulativeExp);
        this.showCurrentPeriodOblError = Number.parseFloat(this.grandTotal.currentPeriodObl) > Number.parseFloat(this.grandTotal.cumulativeObl);
        this.showCumulativeOblError = Number.parseFloat(this.grandTotal.cumulativeObl) > Number.parseFloat(this.allocationAmount);
        this.showCumulativeExpError = Number.parseFloat(this.grandTotal.cumulativeExp) > Number.parseFloat(this.allocationAmount);
        this.showCumulativeExpGreaterObl = Number.parseFloat(this.grandTotal.cumulativeExp) > Number.parseFloat(this.grandTotal.cumulativeObl);
    }

    // initial validations prevent saving of fields
    handleInitialValidations(){ 
        let showError1 = false; 
        let showError2 = false; 
        let showError3 = false; 
        let showError4 = false; 
        let showErrorExp1 = false;
        let showErrorExp2 = false;
        let showErrorExp3 = false;
        let showErrorExp4 = false;
        let showErrorExpGreatObl1 = false;
        let showErrorExpGreatObl2 = false;
        let showErrorExpGreatObl3 = false;
        let showErrorExpGreatObl4 = false;

        const fields1 = this.template.querySelectorAll("[data-category='one'][data-type='cumulativeObl']");
        const fields2 = this.template.querySelectorAll("[data-category='two'][data-type='cumulativeObl']");
        const fields3 = this.template.querySelectorAll("[data-category='three'][data-type='cumulativeObl']");
        const fields4 = this.template.querySelectorAll("[data-category='four'][data-type='cumulativeObl']");
        const fieldsExp1 = this.template.querySelectorAll("[data-category='one'][data-type='cumulativeExp']");
        const fieldsExp2 = this.template.querySelectorAll("[data-category='two'][data-type='cumulativeExp']");
        const fieldsExp3 = this.template.querySelectorAll("[data-category='three'][data-type='cumulativeExp']");
        const fieldsExp4 = this.template.querySelectorAll("[data-category='four'][data-type='cumulativeExp']");

        fields1.forEach(field=>{ 
            if(field.value && field.value < 0){ 
                showError1 = true
            }
        })
        fields2.forEach(field=>{ 
            if(field.value && field.value < 0){ 
                showError2 = true
            }
        })
        fields3.forEach(field=>{ 
            if(field.value && field.value < 0){ 
                showError3 = true
            }
        })
        fields4.forEach(field=>{ 
            if(field.value && field.value < 0){ 
                showError4 = true
            }
        })

        fieldsExp1.forEach((field, index)=>{ 
            if(field.value && field.value < 0){ 
                showErrorExp1 = true
            }
            if( (fields1[index].value != null && field.value != null) && (fields1[index].value !== '' && field.value !== '') && Number.parseFloat(field.value) > Number.parseFloat(fields1[index].value)){
                showErrorExpGreatObl1 =true;
            }
        })

        fieldsExp2.forEach((field, index)=>{ 
            if(field.value && field.value < 0){ 
                showErrorExp2 = true
            }
            if( (fields2[index].value != null && field.value != null) && (fields2[index].value !== '' && field.value !== '') && Number.parseFloat(field.value) > Number.parseFloat(fields2[index].value)){ 
                showErrorExpGreatObl2 =true;
            }
        })

        fieldsExp3.forEach((field, index)=>{ 
            if(field.value && field.value < 0){ 
                showErrorExp3 = true
            }
            if( (fields3[index].value != null && field.value != null) && (fields3[index].value !== '' && field.value !== '') && Number.parseFloat(field.value) > Number.parseFloat(fields3[index].value)){ 
                showErrorExpGreatObl3 =true;
            }
        })

        fieldsExp4.forEach((field, index)=>{ 
            if(field.value && field.value < 0){ 
                showErrorExp4 = true
            }
            if( (fields4[index].value != null && field.value != null) && (fields4[index].value !== '' && field.value !== '') && Number.parseFloat(field.value) > Number.parseFloat(fields4[index].value)){ 
                showErrorExpGreatObl4 =true;
            }
        })

        this.initialCumulativeOblNeg1 = showError1;
        this.initialCumulativeOblNeg2 = showError2;
        this.initialCumulativeOblNeg3 = showError3;
        this.initialCumulativeOblNeg4 = showError4;
        this.initialCumulativeExpNeg1 = showErrorExp1;
        this.initialCumulativeExpNeg2 = showErrorExp2;
        this.initialCumulativeExpNeg3 = showErrorExp3;
        this.initialCumulativeExpNeg4 = showErrorExp4;
        this.initialCumulativeExpGreatObl1 = showErrorExpGreatObl1;
        this.initialCumulativeExpGreatObl2 = showErrorExpGreatObl2;
        this.initialCumulativeExpGreatObl3 = showErrorExpGreatObl3;
        this.initialCumulativeExpGreatObl4 = showErrorExpGreatObl4;

        console.log(this.initialCumulativeExpGreatObl1)
    }

    // gets checkbox values on load
    getCheckboxValues(){ 
        getInfrastructureFields({recordId : this.reportId}).then(data=>{ 
            for (const [key, value] of Object.entries(data)) {
                if(value == 'Yes'){ 
                    let field = this.template.querySelector("[data-field-name='" + key + "']");
                    if(field){ 
                        field.checked = true;
                    }
                }
            }
        }).catch(error=>{ 
            console.log(error);
        })
    }


    showPopover(event) {
        this.showHelpPopoverOne = event.target.name == 'iconOne'
        this.showHelpPopoverTwo = event.target.name == 'iconTwo'
        this.showHelpPopoverThree = event.target.name == 'iconThree'
        this.showHelpPopoverFour = event.target.name == 'iconFour'
        this.showHelpPopoverFive = event.target.name == 'iconFive'
    }

    closePopover(event){ 
        this.showHelpPopoverOne = !event.target.name == 'iconOne';
        this.showHelpPopoverTwo = !event.target.name == 'iconTwo';
        this.showHelpPopoverThree = !event.target.name == 'iconThree';
        this.showHelpPopoverFour = !event.target.name == 'iconFour';
        this.showHelpPopoverFive = !event.target.name == 'iconFive'
    }

    get anyErrors(){ 
        return this.showCumulativeOblNeg || this.showCumulativeExpNeg || this.showCurrentPeriodExpError || this.showCurrentPeriodOblError || this.showCumulativeOblError || this.showCumulativeExpError || this.showCumulativeExpGreaterObl; 
    }


    get stylingTotalOne(){ 
        return this.showCumulativeOblNeg || this.showCumulativeOblError ? 'color: #D0021B' : 'color: #31B722' 
    }

    get stylingTotalTwo(){ 
        return this.showCumulativeExpNeg || this.showCumulativeExpError || this.showCumulativeExpGreaterObl ? 'color: #D0021B' : 'color: #31B722' 
    }

    get stylingTotalThree(){ 
        return this.showCurrentPeriodOblError ? 'color: #D0021B' : 'color: #31B722' 
    }

    get stylingTotalFour(){ 
        return this.showCurrentPeriodExpError || this.showCurrentPeriodExpGreaterObl ? 'color: #D0021B' : 'color: #31B722' 
    }

    // returns true if any errors, this gets called in the parent component
    @api getTrueIfErrors(){ 
        return this.showCumulativeOblNeg || this.showCumulativeExpNeg || this.showCurrentPeriodExpError || this.showCurrentPeriodOblError || this.showCumulativeOblError || this.showCumulativeExpError || this.showCumulativeExpGreaterObl ||
            this.statusIncomplete.one || this.statusIncomplete.two || this.statusIncomplete.three || this.statusIncomplete.four ||
            this.initialCumulativeOblNeg1 || this.initialCumulativeOblNeg2 || this.initialCumulativeOblNeg3 || this.initialCumulativeOblNeg4 ||
            this.initialCumulativeExpNeg1 || this.initialCumulativeExpNeg2 || this.initialCumulativeExpNeg3 || this.initialCumulativeExpNeg4 ||
            this.initialCumulativeExpGreatObl1 || this.initialCumulativeExpGreatObl2 || this.initialCumulativeExpGreatObl3 || this.initialCumulativeExpGreatObl4 ;
    }

 
}