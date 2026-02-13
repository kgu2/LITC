/* This LWC is used to Display a rich text field in an Omnistuido omniscript.  
 * This class was written bc at the time of writting the variant="label-hidden" property 
 * dosen't work with rich text fields. 
 * If you don't need to hide the label, then you can easily use the omnistudioStandarField
 * That LWC will respect the properties of the associated salesforce field.  
 * In this class you have to create all your own validations.
 * Ben Scott 15 oct 2024
 */

import { LightningElement, api, track } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
export default class Omnistudio_RichTextField extends OmniscriptBaseMixin(LightningElement) {
    @api fieldAPI;
    @api objectAPI;
    @api label;
    @api storedValue; //used to load value that exists in omniscript json
    @api helptext;
    @api styleClass;
    @api required = false;
    @api characterLimit = 5000; //sets limit to how many characters can be in the rich text field.  Number needs to be lower than the rich text field you are storing the data in.
    @track errorMessage;
    @track validity = true;
    //requiredCheck = false;
    @api minLength = 0;// 
    @api mode;
    @track isEditMode = false;
    @track isReadOnlyMode = false;
    @track showCharacterLimit = false;
    foundStoredValue = false;

    /*went with a rendered Callback here, bc the stored value dosenot get loaded fast enough to check
      for a value in the connected callback.  This checks to see if there was a passed in (stored value),
      if so, then validation is set to true and users don't need to click in the text box to clear 'requied' warning
      when edditing an app.  
    */
    renderedCallback(){
        
        if(this.required && this.foundStoredValue == false && (this.storedValue == null || this.storedValue == '')){
            this.validity = false;
            this.errorMessage = "This field is required";
        }
        else if(this.required && this.foundStoredValue == false && (this.storedValue != null || this.storedValue != '')){
            console.log('rc true valididt');
            if(this.storedValue.length > this.characterLimit){
               this.validity = false;
               this.showCharacterLimit = true;
               this.errorMessage = "You have exceeded the max length.";
            }
            else{
                this.validity = true;
            }
            //only do this once.
            this.foundStoredValue = true;
            const fields = this.template.querySelectorAll('lightning-input-rich-text');
                fields.forEach((element) =>{
                    console.log(element);
                // This needs to be here, or it makes you hit the next button twice.
                var event = new Event('blur');
                element.dispatchEvent(event);
            });
        }
    }

    connectedCallback() {
        if(this.mode != 'readonly'){
            this.isEditMode = true;
        }
        else if(this.mode == 'readonly'){
            //console.log('set readonly mode');
            this.isReadOnlyMode = true;
        }
    }


    /*lets omnistudio know if imput is valid or not*/
    @api checkValidity() {
       console.log('checking validity  = ' + this.validity);
       if(this.mode == 'readonly'){
        return true;
       }
       else{
        return this.validity;
        }
      }

    //checks the validation.  Will keep the next button from working in validation is false.
    validateOnBlur() {
        // when parameter is true, sets the variable : showValidation to true
        this.omniValidate(true);
     }
   
    onFieldChange(e){
        var result = e.target.value;
        this.omniUpdateDataJson(result);
        //checks to see if input is too large.  Limit can be passed in from OmniScript.
        if(result.length > this.characterLimit){
            this.validity = false;
            this.showCharacterLimit = true;
            this.errorMessage = "You have exceeded the max length.";
        } 
        //reset flags if short enough
        else {
            this.validity = true;
            this.showCharacterLimit = false;
            this.errorMessage = ""; 
        }
    }
}