public without sharing class ContentVersionTriggerHandler {

    public static void afterInsert(List<ContentVersion> records){ 
        List < ContentDocumentLink > listCDLs = new List < ContentDocumentLink >();
        for ( ContentVersion objCV : records ) {
            if ( String.isNotBlank( objCV.Guest_Record_File_Upload__c ) ) {
                ContentDocumentLink objCDL = new ContentDocumentLink();
                objCDL.LinkedEntityId = objCV.Guest_Record_File_Upload__c;
                objCDL.ContentDocumentId = objCV.ContentDocumentId;
                listCDLs.add( objCDL );
            }
        }
        
        if ( listCDLs.size() > 0 ) {
            insert listCDLs;
        }
    }     
}