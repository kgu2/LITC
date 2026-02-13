import OmniscriptText from 'c/omniscriptText';

export default class CustomTextElementValidation extends OmniscriptText {
    doCustomValidation() {
        if (this.childInput.value === 'foo') {
            this.childInput.setCustomValidity('No foo!');
        } else {
            this.childInput.setCustomValidity('');
        }
    }
}
