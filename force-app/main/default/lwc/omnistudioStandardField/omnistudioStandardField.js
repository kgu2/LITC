import { LightningElement, api } from 'lwc';
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';
export default class OmnistudioStandardField extends OmniscriptBaseMixin(LightningElement) {
    @api fieldAPI;
    @api objectAPI;
    @api label;
    @api storedValue; //used to load value that exists in omniscript json
    @api helptext;
    @api styleClass;
    @api required = false;
    onFieldChange(e){
        var result = e.target.value;
        console.log(result);
        this.omniUpdateDataJson(result);
    }
}