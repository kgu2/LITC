
public with sharing class SF424Controller {

    @AuraEnabled
    public static Boolean handleFileUploadValidation(String recordId){
        Application_for_Federal_Assistance__c app = [SELECT Id, Name FROM Application_for_Federal_Assistance__c WHERE Id = :recordId limit 1];
  
        map< Id, map< String, Boolean > > fileProvidedByRequestIdByType = new map< Id, map< String, Boolean > >();
    
        fileProvidedByRequestIdByType.put( app.Id, new map< String, Boolean >{
            'project' => false
        });
        
        map< String, String > appIdByContentVersionId = new map< String, String >();
        for( ContentDocumentLink cdl :[SELECT ContentDocumentId, LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId in :fileProvidedByRequestIdByType.keySet()]){
            appIdByContentVersionId.put( cdl.ContentDocumentId, cdl.LinkedEntityId );
        }
    
        for( ContentVersion cv :[SELECT ContentDocumentId, File_Prefix__c FROM ContentVersion WHERE ContentDocumentId in :appIdByContentVersionId.keySet() AND IsLatest = true ]){
            String appId = appIdByContentVersionId.get( cv.ContentDocumentId );
            fileProvidedByRequestIdByType.get(appId).put( cv.File_Prefix__c, true );
        }
    
        if(fileProvidedByRequestIdByType.get( app.Id ).get( 'project' ) == false) { 
            return true;
        }

        return false;
        
    }   


    @AuraEnabled
    public static string generatePDF(String recordId){
      PageReference pdf = Page.SF424PDF;
      pdf.getParameters().put('id',recordId);
      
      Blob body;
      
      try {
          body = pdf.getContent();
      } catch (VisualforceException e) {
          body = Blob.valueOf('PDF FAILED TO GENERATE');
      }

      ContentVersion cVersion = new ContentVersion();
      cVersion.ContentLocation = 'S'; 
      cVersion.PathOnClient = 'SF424.pdf';
      cVersion.Origin = 'C';
      cVersion.OwnerId = system.UserInfo.getUserId();
      cVersion.Title = 'SF424.pdf';
      cVersion.File_Prefix__c = 'SF424PDF';
      cVersion.VersionData = body;
      Insert cVersion;
      
      Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;

      ContentDocumentLink cDocLink = new ContentDocumentLink();
      cDocLink.ContentDocumentId = conDocument;
      cDocLink.LinkedEntityId = recordId;
      cDocLink.ShareType = 'I';
      cDocLink.Visibility = 'AllUsers';
      Insert cDocLink;

      ContentDistribution cd = new ContentDistribution();
      cd.Name = 'SF424 PDF';
      cd.ContentVersionId = cVersion.Id;
      cd.PreferencesAllowViewInBrowser= true;
      cd.PreferencesLinkLatestVersion=true;
      cd.PreferencesNotifyOnVisit=false;
      cd.PreferencesPasswordRequired=false;
      cd.PreferencesAllowOriginalDownload= true;
      insert cd;  
      
      cd = [select Id, DistributionPublicUrl from ContentDistribution where Id = :cd.Id limit 1];
      return cd.DistributionPublicUrl;
    }

}
