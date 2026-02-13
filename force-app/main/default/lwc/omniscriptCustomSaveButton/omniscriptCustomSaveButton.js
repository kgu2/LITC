import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
import { getDataHandler } from "omnistudio/utility";

import validateUEI from '@salesforce/apex/ApplicationFederalAssistanceController.validateUEI';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class OmnistudioCustomSaveButton extends OmniscriptBaseMixin(LightningElement)  {

    @api drName;
    @api label;

    handleClick(){ 
        // this.callDataraptor(this.drName, this.omniJsonDataStr);
        let updatedData = JSON.parse(JSON.stringify(this.omniJsonData)); 
        let uei = updatedData.Step1_FormSF424.Block_Applicant_Information.Organizational_UEI__c;

        let errorMessage = 'The UEI you entered is invalid. Please ensure the UEI is exactly 12 alphanumeric characters with no spaces or special characters.'

        validateUEI({uei : uei}).then(res=>{ 
            console.log(res);
            if(res.errorDetails){ 
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Error',
                    message: errorMessage,
                    // message: res.errorDetails,
                    variant: 'error',
                    mode: 'dismissable'
                }));
                return;
            } else{ 
                updatedData.Step1_FormSF424.Block_Applicant_Information.UEI_Sam_gov_Validation_Status__c = true;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Legal_Name__c = res.legalEntityName;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Street_1__c = res.address1;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Street_2__c = res.address2;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Employer_Taxpayer_Number__c = res.EIN;
                updatedData.Step1_FormSF424.Block_Applicant_Information.City__c = res.city;
                updatedData.Step1_FormSF424.Block_Applicant_Information.State__c = res.state;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Country__c = res.country;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Zip_Postal_Code__c = res.zip;
                updatedData.Step1_FormSF424.Block_Applicant_Information.Organizational_UEI__c = res.organizationalUEI;                
                this.omniApplyCallResp(updatedData);
                console.log(res);

                this.dispatchEvent(new ShowToastEvent({
                    title: 'Success',
                    message: 'UEI Validated',
                    variant: 'success',
                    mode: 'dismissable'
                }))
            }
        }).catch(error=>{ 
            console.log(error);
        })
    }

    callDataraptor(name, input) {
        console.log('in here');
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
                console.log(result);
                const jsonResult = JSON.parse(result);
                return jsonResult;
            }).catch((err) => {
                console.log(err);
            });
        return result;
    }
}