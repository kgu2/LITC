({
    // doInit: function(component, event, helper) {
    //     // Initialization logic if needed
    // },
    
    // handleClose: function(component, event, helper) {
    //     // Handle closing logic, if any, when LWC signals it's done
    //     $A.get("e.force:closeQuickAction").fire(); // Close the action modal
    // }

    // handleSuccess: function(component, event, helper) {
    //     // Handle the success event from the LWC
    //     var recordId = event.getParam("response").id;
    //     var navEvt = $A.get("e.force:navigateToSObject");
    //     navEvt.setParams({
    //         "recordId": recordId,
    //         "slideDevName": "related"
    //     });
    //     navEvt.fire();

    //     $A.get("e.force:closeQuickAction").fire();

    // }

    //handleSuccess: function(component, event, helper) {
        // Handle the success event from the LWC
        // var recordId = event.getParam('recordId');

        // component.find("navigation")
        //     .navigate({
        //         "type" : "standard__recordPage",
        //         "attributes": {
        //             "recordId"      : recordId,
        //             "actionName"    : "view"   //clone, edit, view
        //         }
        //     }, true);

        // var navEvt = $A.get("e.force:navigateToSObject");
        // navEvt.setParams({
        //     "recordId": recordId,
        //     "slideDevName": "detail"
        // });
        // navEvt.fire();

        //$A.get("e.force:closeQuickAction").fire();

    //}
})