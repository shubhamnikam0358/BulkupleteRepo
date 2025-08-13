public with sharing class BulkUpdaterController {

    @AuraEnabled(cacheable=true)
    public static List<String> getObjectList() {
        List<String> sObjects = new List<String>();
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for (String s : gd.keySet()) {
            if (!s.startsWith('Standard') && !gd.get(s).getDescribe().isCustomSetting()) {
                sObjects.add(s);
            }
        }
        return sObjects;
    }

    @AuraEnabled(cacheable=true)
    public static List<SObject> queryRecords(String objectApiName, String fieldName, String filterClause) {
        String query = 'SELECT Id, ' + fieldName + ' FROM ' + objectApiName;
        if (String.isNotBlank(filterClause)) {
            query += ' WHERE ' + filterClause;
        }
        query += ' LIMIT 10000';
        return Database.query(query);
    }

    @AuraEnabled
    public static String updateRecords(String objectApiName, String fieldName, String fieldValue, List<Id> recordIds) {
        if (String.isBlank(objectApiName) || String.isBlank(fieldName) || recordIds == null || recordIds.isEmpty()) {
            return 'Invalid input.';
        }

        List<SObject> recordsToUpdate = new List<SObject>();
        for (Id recId : recordIds) {
            SObject sObj = (SObject) Type.forName('Schema.' + objectApiName).newInstance();
            sObj.put('Id', recId);
            sObj.put(fieldName, fieldValue);
            recordsToUpdate.add(sObj);
        }

        try {
            update recordsToUpdate;
            return 'Updated ' + recordsToUpdate.size() + ' records.';
        } catch (Exception e) {
            return 'Update failed: ' + e.getMessage();
        }
    }

    @AuraEnabled
    public static String deleteRecords(String objectApiName, List<Id> recordIds) {
        if (String.isBlank(objectApiName) || recordIds == null || recordIds.isEmpty()) {
            return 'Invalid input.';
        }

        List<SObject> recordsToDelete = new List<SObject>();
        for (Id recId : recordIds) {
            SObject sObj = (SObject) Type.forName('Schema.' + objectApiName).newInstance();
            sObj.put('Id', recId);
            recordsToDelete.add(sObj);
        }

        try {
            delete recordsToDelete;
            return 'Deleted ' + recordsToDelete.size() + ' records.';
        } catch (Exception e) {
            return 'Delete failed: ' + e.getMessage();
        }
    }
}