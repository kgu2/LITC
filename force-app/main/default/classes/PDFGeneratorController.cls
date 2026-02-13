public with sharing class PDFGeneratorController {
    public Contact contact { get; set; }

    public PDFGeneratorController() {
        Id contactId = ApexPages.currentPage().getParameters().get('id');
        if (contactId != null) {
            contact = [SELECT Id, Name, Email FROM Contact WHERE Id = :contactId LIMIT 1];
        }
    }
}