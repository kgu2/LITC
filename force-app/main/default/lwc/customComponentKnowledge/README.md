## ns/customComponentKnowledge
This is an example for standalone knowledge component.


* [ns/customComponentKnowledge](#markdown-header-nscustomcomponentknowledge)
    * [module.exports](#markdown-header-moduleexports-lightningelement) ⇐ LightningElement ⏏
        * [.knowledgeLabel](#markdown-header-customcomponentknowledgeknowledgelabel-string) : String
        * [.kbOptions](#markdown-header-customcomponentknowledgekboptions-object) : Object
        * [.layout](#markdown-header-customcomponentknowledgelayout-string) : String
        * [.omniscriptKey](#markdown-header-customcomponentknowledgeomniscriptkey-string) : String
        * [.tempRender](#markdown-header-customcomponentknowledgetemprender-boolean) : Boolean
        * [.connectedCallback()](#markdown-header-customcomponentknowledgeconnectedcallback-void) ⇒ Void
        * [.render()](#markdown-header-customcomponentknowledgerender-template) ⇒ Template

### module.exports ⇐ LightningElement ⏏
Default exported class CustomComponentKnowledge.

**Kind**: Exported class  
**Extends**: LightningElement  
#### customComponentKnowledge.knowledgeLabel : String
- Set knowledge label

**Kind**: instance property of module.exports  
**Scope**: private  
#### customComponentKnowledge.kbOptions : Object
- knowledge options object

**Kind**: instance property of module.exports  
**Scope**: private  
#### customComponentKnowledge.layout : String
Stores theme layout.

**Kind**: instance property of module.exports  
**Scope**: public (api)  
#### customComponentKnowledge.omniscriptKey : String
Stores Omniscript Key.

**Kind**: instance property of module.exports  
**Scope**: public (api)  
#### customComponentKnowledge.tempRender : Boolean
Checks whether template needs to render or not.

**Kind**: instance property of module.exports  
**Scope**: private (track)  
#### customComponentKnowledge.connectedCallback() ⇒ Void
Setting up knowledge options

**Kind**: instance method of module.exports  
**Scope**: private  
#### customComponentKnowledge.render() ⇒ Template
Overwrites the native LWC render.

**Kind**: instance method of module.exports  
**Scope**: private  
