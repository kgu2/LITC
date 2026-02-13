@isTest
private class OmniStudioFileControllerTest{
    @isTest
    private static void getContentDocumentIdTest(){
        ContentVersion cv = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.jpg',
            VersionData = Blob.valueOf('Test'),
            origin = 'H'
        );
        insert cv;
        OmniStudioFileController.getContentDocumentId(cv.Id);
        OmniStudioFileController.getContentDocumentId('');
    }

    @isTest
    private static void releatedFilesTest(){
        ContentVersion cv = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.jpg',
            VersionData = Blob.valueOf('Test'),
            origin = 'H'
        );
        insert cv;
        OmniStudioFileController.releatedFiles(cv.Id);
    }

    @isTest
    private static void deleteFilesTest(){
        ContentVersion cv = new ContentVersion(
            Title = 'SampleTitle',
            PathOnClient = 'SampleTitle.jpg',
            VersionData = Blob.valueOf('Test'),
            origin = 'H'
        );
        insert cv;
        OmniStudioFileController.deleteFiles(cv.Id);
    }

}