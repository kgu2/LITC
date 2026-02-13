import { LightningElement, track } from 'lwc';
import { OmniscriptActionCommonUtil } from 'c/omniscriptActionUtils';
import { getNamespaceDotNotation } from 'c/omniscriptInternalUtils';
import { OmniscriptBaseMixin } from 'c/omniscriptBaseMixin';
import tmpl from './customComponentAction.html';

export default class CustomComponentAction extends OmniscriptBaseMixin(LightningElement) {
    @track spinnerEnabled = false;

    _ns = getNamespaceDotNotation();
    _actionUtilClass;

    connectedCallback() {
        this._actionUtilClass = new OmniscriptActionCommonUtil();
    }

    triggerQueueable() {
        this.spinnerEnabled = true;

        const options = {
            input: JSON.stringify(this.omniJsonData),
            vlcClass: 'LwcTest',
            vlcMethod: 'lwctest',
            useQueueableApexRemoting: true,
        };

        const params = {
            input: JSON.stringify(this.omniJsonData),
            sClassName: `${this._ns}VFActionFunctionController.VFActionFunctionControllerOpen`,
            sMethodName: 'runActionFunction',
            options: JSON.stringify(options),
        };

        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then(resp => {
                this.spinnerEnabled = false;

                const respObj = JSON.parse(resp.result.responseResult);
                this.omniApplyCallResp(respObj);
            })
            .catch(error => {
                window.console.log(error, 'error');
            });
    }

    triggerContinuation() {
        this.spinnerEnabled = true;

        const options = {
            input: JSON.stringify(this.omniJsonData),
            vlcClass: 'QeRemoteAction2',
            vlcMethod: 'populateElements',
            useContinuation: true,
        };

        const params = {
            input: JSON.stringify(this.omniJsonData),
            sClassName: 'QeRemoteAction2',
            sMethodName: 'populateElements',
            options: JSON.stringify(options),
        };

        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then(resp => {
                this.spinnerEnabled = false;
                this.omniApplyCallResp(resp.result);
            })
            .catch(error => {
                window.console.log(error, 'error');
            });
    }

    triggerChainable() {
        this.spinnerEnabled = true;

        const options = {
            chainable: true,
        };

        const params = {
            input: JSON.stringify(this.omniJsonData),
            sClassName: `${this._ns}IntegrationProcedureService`,
            sMethodName: 'Test_Chainable',
            options: JSON.stringify(options),
        };

        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then(resp => {
                this.spinnerEnabled = false;
                this.omniApplyCallResp(resp.result);
            })
            .catch(error => {
                window.console.log(error, 'error');
            });
    }

    triggerFuture() {
        this.spinnerEnabled = true;

        const options = {
            useFuture: true,
        };

        const params = {
            input: JSON.stringify(this.omniJsonData),
            sClassName: `${this._ns}IntegrationProcedureService`,
            sMethodName: 'Test_Chainable',
            options: JSON.stringify(options),
        };

        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then(resp => {
                this.spinnerEnabled = false;
                this.omniApplyCallResp(resp.result);
            })
            .catch(error => {
                window.console.log(error, 'error');
            });
    }

    triggerRemote() {
        this.spinnerEnabled = true;

        const params = {
            input: '{}',
            sClassName: 'LwcTest',
            sMethodName: 'lwctest',
            options: '{}',
        };

        this._actionUtilClass
            .executeAction(params, null, this, null, null)
            .then(resp => {
                this.spinnerEnabled = false;
                this.omniApplyCallResp(resp.result);
                //for longer remote calls to run in the background while on a different step,
                //use this.omniApplyCallResp(resp.result, true)
            })
            .catch(error => {
                window.console.log(error);
            });
    }

    triggerRemote2() {
        const options = {
            input: JSON.stringify(this.omniJsonData),
            vlcClass: 'LwcTest',
            vlcMethod: 'lwctest',
            useQueueableApexRemoting: true,
        };

        const params = {
            input: JSON.stringify(this.omniJsonData),
            sClassName: `${this._ns}VFActionFunctionController.VFActionFunctionControllerOpen`,
            sMethodName: 'runActionFunction',
            options: JSON.stringify(options),
        };

        this.omniRemoteCall(params, true)
            .then(response => {
                // response will have result node and error node
                window.console.log(response, 'response');
            })
            .catch(error => {
                window.console.log(error, 'error');
            });
    }

    render() {
        return tmpl;
    }
}
