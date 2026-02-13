@isTest
public class PDFEmailTest {
    
    @isTest
    static void testGeneratePDF() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact c = new Contact(LastName = 'Test Contact', Email = 'test@example.com');
        insert c;
        
        GeneratePDFFromFlow.Request req = new GeneratePDFFromFlow.Request();
        req.recordId = acc.Id;
        
        Test.startTest();
        List<GeneratePDFFromFlow.Response> results = GeneratePDFFromFlow.generatePDF(
            new List<GeneratePDFFromFlow.Request>{ req }
        );

        PageReference pageRef = Page.PDFGeneratorPage; 
        pageRef.getParameters().put('id', c.Id);
        Test.setCurrentPage(pageRef);
        PDFGeneratorController controller = new PDFGeneratorController();

        Test.stopTest();

    
       

 
    }
}