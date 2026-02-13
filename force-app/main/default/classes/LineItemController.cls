public with sharing class LineItemController {
    public Id applicationId { get; set; }
    public Application_for_Federal_Assistance__c application { get; set; }
    public List<X13424_J_Line_Item__c> lineItems13424J { get; set; }

    public LineItemController() {
        // Retrieve the ID of the master record from the URL
        applicationId = ApexPages.currentPage().getParameters().get('id');
        
        // Query the master record
        application = [SELECT Id, Name 
                       FROM Application_for_Federal_Assistance__c 
                       WHERE Id = :applicationId];
        
        // Query related line items
        lineItems13424J = [SELECT Description__c, Quantity__c, U_M__c, Cost_per_Unit__c, Total_Cost__c 
                     FROM X13424_J_Line_Item__c 
                     WHERE Application_for_Federal_Assistance__c = :applicationId];
    }
}