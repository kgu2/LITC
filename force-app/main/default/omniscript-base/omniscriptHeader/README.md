# OmniScript Header (omniscriptHeader)

This component provides OmniScript functionality. It extends from `AggregatesValidation(OmniscriptGroupElement)`.  

### Properties

| Name                 | Scope           | Description                                                  |
| -------------------- | --------------- | ------------------------------------------------------------ |
| prefill              | api (public)    | Omniscript prefill to be applied to the Data JSON            |
| firstRender          | track (private) | Flag that identifies when omniscript first renders           |
| jsonDef              | track (private) | Omniscript JSON Definition                                   |
| jsonData             | track (private) | Omniscript Data JSON                                         |
| scriptHeaderDef      | track (private) | Omniscript script header definition                          |
| hasPrev              | track (private) | Flag that identifies if a previous step exists relative to the current step |
| hasNext              | track (private) | Flag that identifies if a next step exists relative to the current step |
| compLoaded           | track (private) | Flag that identifies if all omniscript components are loaded |
| modalEvents          | track (private) | Array which stories an array of data to be displayed in the omniscript modal |
| stepChartProps       | track (private) | Omniscript step chart properties                             |
| navButton            | track (private) | Omniscript navigation button properties                      |
| contentSldsClass     | track (private) | Classes to be applied to the Lightning omniscript player. Support lightning step chart positioning. |
| spinnerMessage       | track (private) | Spinner message                                              |
| knowledgeLabel       | private         | knowledge component Label                                    |
| _dispOutsideOmni     | private         | whether KB will display outside OmniScript OR not.           |
| _isKbEnabledOnScript | private         | whether KB is enabled OmniScript side OR not.                |

### Methods

| Signature                                     | Scope   | Return Value | Description                                                  |
| --------------------------------------------- | ------- | ------------ | ------------------------------------------------------------ |
| initCompVariables                             | private | Void         | Overwrites inherited initCompVariables.                      |
| connectedCallback()                           | private | Void         | Overwrites native LWC connectedCallback.                     |
| handleStepChartLayout(evt)                    | private | Void         | Handles stepchart responsive layouts. Only applicable in the Lightning LWC player. |
| setStepChartResponsiveHandlers()              | private | Void         | Adds event listeners for step chart responsiveness. Only applicable in the Lightning LWC player. |
| disconnectedCallback()                        | private | Void         | Overwrites native LWC disconnectedCallback.                  |
| renderedCallback()                            | private | Void         | Overwrites inherited renderedCallback.                       |
| applyContentWidth()                           | private | Void         | Applies content width for the omniscript step container. Supports Lightning step chart placement. |
| updateButtons(newIndex, currentIndex = 0)     | private | Void         | Updates the previous and next button labels and classes based on the current step. |
| getPrevStepIndex(index)                       | private | Number       | Gets the immediate previous steps index.                     |
| hasPrevStep(index)                            | private | Boolean      | Determines if a previous step is available.                  |
| hasNextStep(index)                            | private | Boolean      | Determines if a next step is available.                      |
| prevStep(evt)                                 | private | Void         | Event click handler for the previous step navigation.        |
| nextStep(evt)                                 | private | Void         | Event click handler for the next step navigation.            |
| navigateToPrev()                              | private | Void         | Handles the previous step navigation.                        |
| handleErrorModal(index)                       | private | Void         | Handles the functionality for the error modals.              |
| navigateTo(nextIndex, currentIndex = 0)       | private | Void         | Main logic that controls navigation in an omniscript.        |
| handleActionExecution(comp, index)            | private | Void         | Handles the logic for action execution.                      |
| handleActionResp(bSystemFailure, resp, index) | private | Void         | Handles logic after action execution.                        |
| handleSavedForLater(evt)                      | private | Void         | Event handler for Save for Later that is triggered by custom components. |
| updateStep(nextIndex, currentIndex)           | private | Void         | Updates the step content for both the previous and next steps, as needed. |
| setStepVisibility(index, isVisible)           | private | Void         | Sets the step visibility. Updates JSON definition step visibility flag. |
| handleStepChartEvent(evt)                     | private | Void         | Event handler for step chart events.                         |
| handleModalEvent(evt)                         | private | Void         | Handles all modal events.                                    |
| handleActionBtnEvent(evt)                     | private | Void         | Handles action events.                                       |
| handleAutoAdv(evt)                            | private | Void         | Handles auto advancing navigation.                           |
| handleIndexByValue(value)                     | private | Number       | Calculates the index depending on the value.                 |
| handleOmniSetShow(evt)                        | private | Void         | Event listener that updates the bShow for root elements.     |
| handleCustomSaveState(evt)                    | private | Void         | Event listener that handles custom LWC save state.           |
| checkNav(nextIndex, currIndex, showModal = true)                | private | Boolean      | Provides a check between the current step index and incoming step index to ensure navigation is permitted. |
| saveForLater()                                | private | Void         | Handles save for later.                                      |
| performSaveForLater(auto)                     | private | Void         | Performs save for later.                                     |
| notifySaveForLaterError(error)                | private | Void         | Displays a modal with an error from the save for later.      |
| handleContinueInvalidSfl()                    | private | Void         | Handles invalid Safe for Later.                              |
| handleSaveForLater(evt)                       | private | Void         | Handles a save for later request.                            |
| handleSaveForLaterComplete(evt)               | private | Void         | Event handler that is triggered when the save for later is complete. |
| handleFileUploaded(evt)                       | private | Void         | Handles the filesMap array when a file is uploaded.          |
| _reloadDef()                                  | private | Void         | Reloads JSON definition.                                     |
| isKnowledgeEnabled()                          | private | Boolean      | Determines if knowledge is enabled.                          |
| handleError(error)                            | private | Void         | Handles errors.                                              |
| handlePendingUpdates(evt)                     | private | Void         | Handles all events for 'omnipendingupdates'.                 |
| displayModal(config)                          | private | Void         | Displays a modal (default: error modal) based on the config object passed in. |
| handleFormattedData(evt)                      | private | Void         | Event handler for formatting data.                           |
| modifyModalButton(oldButtons)                 | private | Object[]     | Modifies the handleClick for each button to close the modal after click. |
| handleActionExecution(comp, index)            | private | Void         | Handles the logic for action execution.                      |
| markInputAsValid(evt)                         | private | Void         | Event handler that marks inputs as valid.                    |
| markInputAsInvalid(evt)                       | private | Void         | Event handler that marks inputs as invalid.                  |
| initScriptHeaderDef()                         | private | Void         | Initializes scriptHeaderDef.                                 |
| resetFirstStepAccordionActive()               | private | Void         | Resets the first step accordion active in JSON definition.   |
| handleResumeBpDef(bpDef)                      | private | Void         | Handles JSON definition when resume.                         |
| handleUserInfo(userInfo)                      | private | Void         | Handles user information.                                    |