public with sharing class GeneratePDFFromFlow {
    public class Request {
        @InvocableVariable(required=true)
        public Id recordId;
    }
    public class Response {
        @InvocableVariable
        public Id contentVersionId;
    }
    @InvocableMethod(label='Generate PDF From Flow')
    public static List<Response> generatePDF(List<Request> requests) {
        List<Response> results = new List<Response>();
        for(Request req : requests) {
            PageReference pdfPage = Page.PDFGeneratorPage;
            pdfPage.getParameters().put('id', req.recordId);
            // Blob pdfBlob = pdfPage.getContentAsPDF();
            Blob pdfBlob;
            try {
                pdfBlob = pdfPage.getContent();
            } catch (VisualforceException e) {
                pdfBlob = Blob.valueOf('PDF FAILED TO GENERATE');
            }
            ContentVersion cv = new ContentVersion();
            cv.Title = 'PDF';
            cv.PathOnClient = 'PDF.pdf';
            cv.VersionData = pdfBlob;
            cv.Origin = 'H';
            cv.FirstPublishLocationId =  req.recordId;
            insert cv;
            Response res = new Response();
            res.contentVersionId = cv.Id; // return to Flow
            results.add(res);
        }
        return results;
    }
}