/**
 * @module ns/customComponentKnowledge
 * @description This is an example for standalone knowledge component.
 */
import { LightningElement, api, track } from 'lwc';
import tmpl from './customComponentKnowledge.html';
import GetUserInfo from '@salesforce/apex/BusinessProcessDisplayController.GetUserInfo';

/**
 * Default exported class CustomComponentKnowledge.
 * @extends LightningElement
 * @typicalname CustomComponentKnowledge
 */
export default class CustomComponentKnowledge extends LightningElement {
    /**
     * @type {String} - Set knowledge label
     * @scope private
     */
    knowledgeLabel = 'Outside Knowledge Base';

    /**
     * @type {Object} - knowledge options object
     * @scope private
     */
    kbOptions = {};

    /**
     * @scope public (api)
     * @type {String}
     * @description Stores theme layout.
     */
    @api layout;

    /**
     * @scope public (api)
     * @type {String}
     * @description Stores Omniscript Key.
     */
    @api omniscriptKey;

    /**
     * @scope private (track)
     * @type {Boolean}
     * @description Checks whether template needs to render or not.
     */
    @track tempRender;

    /**
     * @description Setting up knowledge options
     * @returns {Void}
     * @scope private
     */
    connectedCallback() {
        GetUserInfo().then(resp => {
            resp = JSON.parse(resp);
            this.kbOptions = {
                sClassName: resp.namespacePrefix + '.DefaultKnowledgeOmniScriptIntegration',
                sMethodName: 'searchArticle',
                input: '{}',
                options: JSON.stringify({
                    typeFilter: '',
                    remoteTimeout: 30000,
                    dataCategoryCriteria: '',
                    keyword: '',
                    publishStatus: 'Online',
                    language: 'English',
                    lkObj: resp.namespacePrefix + 'Knowledge__kav',
                }),
                label: {
                    label: 'Step1',
                },
                displayLabel: '',
                isKbEnabledOnStep: true,
                kbArticleBodyParam: {
                    sClassName: resp.namespacePrefix + '.DefaultKnowledgeOmniScriptIntegration',
                    sMethodName: 'getArticleBody',
                    input: '{}',
                    options: JSON.stringify({
                        typeFilter: '',
                        remoteTimeout: 30000,
                        dataCategoryCriteria: '',
                        keyword: '',
                        publishStatus: 'Online',
                        language: 'English',
                        aType: resp.namespacePrefix + 'Knowledge__kav',
                    }),
                    label: {
                        label: 'Step1',
                    },
                },
                lightningKBObjName: resp.namespacePrefix + 'Knowledge__kav',
                knowledgeArticleTypeQueryFieldsMap: {
                    INFO: resp.namespacePrefix + 'knowledgeTest__c,' + resp.namespacePrefix + 'Text__c',
                    FAQ: resp.namespacePrefix + 'knowledgeTest__c,' + resp.namespacePrefix + 'Text__c',
                    Blog: resp.namespacePrefix + 'knowledgeTest__c,' + resp.namespacePrefix + 'Text__c',
                },
                lightningKBEnable: true,
            };
            this.tempRender = true;
        });
    }

    /**
     * @scope private
     * @description Overwrites the native LWC render.
     * @returns {Template}
     */
    render() {
        return tmpl;
    }
}
