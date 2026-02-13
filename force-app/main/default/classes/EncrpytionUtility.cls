public with sharing class EncrpytionUtility {

    public static String encryptRecordId(String recordId) {
        Blob data = Crypto.encryptWithManagedIV('AES256', getKey(), Blob.valueOf(recordId));
        return EncodingUtil.urlEncode(EncodingUtil.convertToHex(data) ,'UTF-8') ;
    }

    @AuraEnabled
    public static String decryptRecordId(String encryptedString) {
        String sCleanLink = EncodingUtil.urlDecode(encryptedString,'UTF-8');
        Blob decryptedBlob = Crypto.decryptWithManagedIV('AES256', getKey(), EncodingUtil.convertFromHex(sCleanLink));
        return decryptedBlob.toString();
    } 

    private static Blob getKey() {
        if (Test.isRunningTest()) {
            return Blob.valueOf('12345678901234567890qwertyuiopas');
        }
        Encryption_Setting__mdt encrpytionKey = [SELECT Key__c FROM Encryption_Setting__mdt LIMIT 1];
        return Blob.valueOf(encrpytionKey.Key__c);
    }   
}

    