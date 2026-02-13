import OmniscriptText from 'c/omniscriptText';

export default class CustomTextElementMasking extends OmniscriptText {
    _pattern = '00000';
    applyCallResp(evtjson, bApi = false, bValidation = false) {
        if (typeof evtjson === 'string') {
            super.applyCallResp(evtjson.padStart(this._pattern.length, '0'), bApi, bValidation);
        } else {
            super.applyCallResp(evtjson, bApi, bValidation);
        }
    }
}
