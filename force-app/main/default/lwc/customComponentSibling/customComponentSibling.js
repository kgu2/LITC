import { LightningElement, track } from 'lwc';
import pubsub from 'c/pubsub';

export default class CustomComponentSibling extends LightningElement {
    @track pubsubEventList = [];
    @track oaEventList = [];
    @track wpmFilteredList = [];
    @track wpmKey = 'OmniScript-Messaging';

    _wpmAllEventsList = [];
    _pubsubEventIndex = 0;
    _oaEventIndex = 0;
    _wpmEventIndex = 0;

    connectedCallback() {
        this._handleActionObject = {
            data: this.handleOmniAction.bind(this),
        };
        this._handleLoadedObject = {
            data: this.handleOmniInit.bind(this),
        };
        this._handleDataJsonObject = {
            data: this.handleOmniJson.bind(this),
        };
        this._handleStepLoadObject = {
            data: this.handleStepLoad.bind(this),
        };
        this._handleStepUnloadObject = {
            data: this.handleStepUnload.bind(this),
        };
        this._handleCancelObject = {
            data: this.handleCancel.bind(this),
        };
        this._handleSflObject = {
            data: this.handleSfl.bind(this),
        };

        // PubSub Event Listeners
        pubsub.register('omniscript_action', this._handleActionObject);
        pubsub.register('omniscript_loaded', this._handleLoadedObject);
        pubsub.register('omniscript_datajson', this._handleDataJsonObject);
        pubsub.register('omniscript_step', this._handleStepLoadObject);
        pubsub.register('omniscript_step_unload', this._handleStepUnloadObject);
        pubsub.register('omniscript_cancel', this._handleCancelObject);
        pubsub.register('omniscript_save_for_later', this._handleSflObject);

        // WPM Event Listener
        this._handleMessageEvent = this.handleMessageEvent.bind(this);
        window.addEventListener('message', this._handleMessageEvent, false);

        // OA PubSub Event Listener (mimics vtag)
        this._handleOAObject = {
            track: this.handleOAEvents.bind(this),
        };
        pubsub.register('OmniAnalyticsChannel', this._handleOAObject);
    }

    disconnectedCallback() {
        pubsub.unregister('omniscript_action', this._handleActionObject);
        pubsub.unregister('omniscript_loaded', this._handleLoadedObject);
        pubsub.unregister('omniscript_datajson', this._handleDataJsonObject);
        pubsub.unregister('omniscript_step', this._handleStepLoadObject);
        pubsub.unregister('omniscript_step_unload', this._handleStepUnloadObject);
        pubsub.unregister('omniscript_cancel', this._handleCancelObject);
        pubsub.unregister('omniscript_save_for_later', this._handleSflObject);
        pubsub.unregister('OmniAnalyticsChannel', this._handleOAObject);
        window.removeEventListener('message', this._handleMessageEvent);
    }

    handleMessageEvent(event) {
        if (event.data) {
            for (let key in event.data) {
                if (key) {
                    this._wpmAllEventsList.push({
                        node: key,
                        payload: JSON.stringify(event.data[key]),
                        key: `wpm${this._wpmEventIndex++}`,
                    });

                    if (key === this.wpmKey) {
                        this.filterWpmPayload();
                    }
                }
            }
        }
    }

    filterWpmPayload(event) {
        if (event && event.target && event.target.value != null) {
            this.wpmKey = event.target.value;
        }

        this.wpmFilteredList = this._wpmAllEventsList.filter(eventData => {
            return eventData.node === this.wpmKey;
        });
    }

    handleOAEvents(event) {
        this.oaEventList.push({
            name: event.event,
            payload: JSON.stringify(event.value),
            key: `oa${this._oaEventIndex++}`,
        });
    }

    handleOmniAction(data) {
        this.pubsubEventList.push({ name: 'omniscript_action', data: JSON.stringify(data), key: `omniscript_action${this._pubsubEventIndex++}` });
    }

    handleOmniInit(data) {
        this.pubsubEventList.push({ name: 'omniscript_loaded', data: JSON.stringify(data), key: `omniscript_loaded${this._pubsubEventIndex++}` });
    }

    handleOmniJson(data) {
        this.pubsubEventList.push({ name: 'omniscript_datajson', data: JSON.stringify(data), key: `omniscript_datajson${this._pubsubEventIndex++}` });
    }

    handleStepLoad(data) {
        this.pubsubEventList.push({ name: 'omniscript_step', data: JSON.stringify(data), key: `omniscript_step${this._pubsubEventIndex++}` });
    }

    handleStepUnload(data) {
        this.pubsubEventList.push({
            name: 'omniscript_step_unload',
            data: JSON.stringify(data),
            key: `omniscript_step_unload${this._pubsubEventIndex++}`,
        });
    }

    handleCancel(data) {
        this.pubsubEventList.push({ name: 'omniscript_cancel', data: JSON.stringify(data), key: `omniscript_cancel${this._pubsubEventIndex++}` });
    }

    handleSfl(data) {
        this.pubsubEventList.push({
            name: 'omniscript_save_for_later',
            data: JSON.stringify(data),
            key: `omniscript_save_for_later${this._pubsubEventIndex++}`,
        });
    }
}
