import { LightningElement, track, api } from 'lwc';
import GenericInvoke2 from '@salesforce/apexContinuation/BusinessProcessDisplayController.GenericInvoke2';

//************ omni integration ************************************
import { OmniscriptBaseMixin } from 'c/omniscriptBaseMixin';
//******************************************************************

//************ omni integration ************************************
// add omniscript integration mixin to your component
// example:
// change -
// export default class CustomComponentWithMixin extends LightningElement
// to -
// export default class CustomComponentWithMixin extends OmniscriptBaseMixin(LightningElement)
//******************************************************************
export default class CustomComponentWithMixin extends OmniscriptBaseMixin(LightningElement) {
    @track products = [];
    @track cart = [];

    /*  Added property passed into component from OmniScript  */
    _lastSearched;
    _brand;

    //************ omni integration ************************************
    // Example of connecting @api property brand to the omniscript's data json node
    // OmniScript Designer setup - Custom Lightning Web Component element
    // "customAttributes": [
    //    {
    //        "source": "%Step1:Text1%",
    //        "name": "brand"
    //    }
    // ]
    //******************************************************************

    @api
    get brand() {
        return this._brand;
    }
    set brand(value) {
        if (value && value !== this._lastSearched) {
            this.remoteMethod(value);
            this._lastSearched = value;
        }
    }

    /**
     * Code written by the user to restore internal state and the UI state
     */
    restoreSaveState() {
        //************ omni integration ************************************
        // Calling the mixin utility function omniGetSaveState to retrieve the state saved
        let stateData = this.omniGetSaveState();
        let stateDataCleared = this.omniGetSaveState(this.omniJsonDef.name + '-$Vlocity.cleared');
        //******************************************************************

        //************ omni integration ************************************
        // You can also access OmniScript's entire data json
        window.console.log(this.omniJsonData);
        //******************************************************************

        // restore state if there is a omniCustomState
        if (stateData && !stateDataCleared) {
            this.cart = stateData;
            // creating table to check for items in cart
            let isInCart = this.cart.reduce((data, cartItem) => {
                if (cartItem.name) {
                    data[cartItem.name] = true;
                }
                return data;
            }, {});

            // restore ui for cart
            for (let i = 0; i < this.products.length; i++) {
                let name = this.products[i].name;
                this.products[i].isInCart = isInCart[name] ? true : false;
            }
        }
    }

    connectedCallback() {
        if (!this._lastSearched || this.products.length < 1) {
            this.remoteMethod(this._lastSearched).then(() => {
                this.restoreSaveState();
            });
        } else {
            this.restoreSaveState();
        }
    }

    remoteMethod(data) {
        data = data || '';
        const param = {
            sClassName: 'LwcTest',
            sMethodName: 'lwcphones',
            // updated to accept function parameters
            input: JSON.stringify({ input: data }),
            options: '{}',
        };
        return GenericInvoke2(param)
            .then(result => {
                const resp = JSON.parse(result);
                this.products = resp.results.map(item => {
                    item.isInCart = false;
                    return item;
                });
            })
            .catch(error => {
                window.console.log(error);
            });
    }

    addToCart(event) {
        let alreadyAdded = false;
        let pIndex = event.target.getAttribute('data-prod-index');
        let product = this.products[pIndex];
        for (let i = 0; i < this.cart.length; i++) {
            if (this.cart[i].name === product.name) {
                alreadyAdded = true;
                break;
            }
        }
        if (!alreadyAdded) {
            product.isInCart = true;
            this.cart.push({
                name: product.name,
                retailPrice: product.retailPrice,
                monthlyPrice: product.monthlyPrice,
            });
            // calls inherited via mixin
            //************ omni integration ************************************
            // Calling the mixin utility function omniUpdateDataJson to update OmniScript with your own input
            this.omniUpdateDataJson(this.cart);
            //******************************************************************

            //************ omni integration ************************************
            // Calling the mixin utility function omniSaveState to save your component's current state within OmniScript
            this.omniSaveState(this.cart, this.omniJsonDef.name, true);
            //******************************************************************
        }

        this.omniValidate();
    }

    removeFromCart(event) {
        let pIndex = event.target.getAttribute('data-prod-index');
        let product = this.products[pIndex];
        for (let i = 0; i < this.cart.length; i++) {
            if (this.cart[i].name === product.name) {
                product.isInCart = false;
                this.cart.splice(i, 1);
                this.omniUpdateDataJson(this.cart);
                this.omniSaveState(this.cart);
                break;
            }
        }

        // Update validation state after selection.
        this.omniValidate();
    }

    // checkValidity example, the user has to have at least 2 items in the cart
    @api checkValidity() {
        return this.cart.length >= 2;
    }
}
