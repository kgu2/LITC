import { LightningElement, api, track, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import { OmniscriptBaseMixin } from 'omnistudio/omniscriptBaseMixin';

export default class teiForm extends OmniscriptBaseMixin(LightningElement){

//currentPageReference = null;
//uuid = null; // Params from Url
isPreview = true;
@track noUUID = false

    /*wire function run automatically on page load */
    @wire(CurrentPageReference)
    getStateParameters() {
        let url = window.location.href;
        const urlParam = url.match(/error=([^&]+)/);
        if(urlParam){
            console.log("urlParam " + urlParam);
            const longValue = urlParam ? urlParam[1] : null;
            console.log("longValue " + longValue);
            const value = longValue.slice(-36)
            
            console.log("value " + value);
            this.omniUpdateDataJson(value);
    
            let tempURL = window.location.pathname;
            if (tempURL.includes("/s/")) {
                this.isPreview = false;
            }
        } else{
            this.noUUID = true;
            this.omniUpdateDataJson("error");
            console.error('error: no url uuid parameter provided');
        }
    }
}