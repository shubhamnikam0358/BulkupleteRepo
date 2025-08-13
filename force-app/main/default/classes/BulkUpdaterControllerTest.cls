@IsTest
private class BulkUpdaterControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = new List<Account>();
        for(Integer i = 0; i < 5; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Industry = 'Technology'
            ));
        }
        insert testAccounts;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for(Integer i = 0; i < 3; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test'+i+'@example.com'
            ));
        }
        insert testContacts;
    }
    
@IsTest
static void testGetObjectList() {
    // Get all actual objects in the org for comparison
    Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    Set<String> allObjects = globalDescribe.keySet();
    
    Test.startTest();
    List<String> result = BulkUpdaterController.getObjectList();
    Test.stopTest();
    
    // Convert to set for easier comparison
    Set<String> resultSet = new Set<String>(result);
    
    // 1. Verify the list isn't empty
    System.assert(!result.isEmpty(), 'Object list should not be empty');
    
    // 2. Verify it includes expected standard objects
    System.assert(resultSet.contains('Account'), 'Should include Account object');
    System.assert(resultSet.contains('Contact'), 'Should include Contact object');
    
    // 3. Verify it excludes objects starting with 'Standard'
    for (String objName : resultSet) {
        System.assert(!objName.startsWith('Standard'), 
            'Should not include objects starting with "Standard": ' + objName);
    }
    
    // 4. Verify it excludes custom settings (where we can check)
    for (String objName : resultSet) {
        Schema.SObjectType objType = globalDescribe.get(objName);
        if (objType != null) {
            System.assert(!objType.getDescribe().isCustomSetting(), 
                'Should not include custom settings: ' + objName);
        }
    }
    
    // 5. Verify the count makes sense (should be most objects minus excluded ones)
    Integer customSettingCount = 0;
    Integer standardPrefixedCount = 0;
    for (String objName : allObjects) {
        Schema.SObjectType objType = globalDescribe.get(objName);
        if (objType.getDescribe().isCustomSetting()) {
            customSettingCount++;
        }
        if (objName.startsWith('Standard')) {
            standardPrefixedCount++;
        }
    }
    
    // The result should have approximately (all objects - custom settings - standard prefixed)
    Integer expectedMinCount = allObjects.size() - customSettingCount - standardPrefixedCount - 10; // buffer
    System.assert(result.size() >= expectedMinCount, 
        'Result count seems too low. Expected at least ' + expectedMinCount + ' but got ' + result.size());
}
    
    @IsTest
    static void testQueryRecordsWithFilter() {
        String filter = 'Industry = \'Technology\'';
        
        Test.startTest();
        List<SObject> results = BulkUpdaterController.queryRecords('Account', 'Name, Industry', filter);
        Test.stopTest();
        
        System.assert(!results.isEmpty(), 'Should return records with filter');
        for(SObject obj : results) {
            Account acc = (Account)obj;
            System.assertEquals('Technology', acc.Industry, 'Filter should only return Technology accounts');
        }
    }
    
    @IsTest
    static void testQueryRecordsInvalidObject() {
        Boolean exceptionThrown = false;
        
        Test.startTest();
        try {
            List<SObject> results = BulkUpdaterController.queryRecords('InvalidObject', 'Name', '');
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();
        
        System.assert(exceptionThrown, 'Should throw exception for invalid object');
    }
    
    @IsTest
    static void testUpdateRecordsSuccess() {
        List<Account> accounts = [SELECT Id, Name FROM Account];
        List<Id> accountIds = new List<Id>();
        for(Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        String newName = 'Updated Name';
        
        Test.startTest();
        String result = BulkUpdaterController.updateRecords('Account', 'Name', newName, accountIds);
        Test.stopTest();
        
        System.assertEquals('Updated ' + accountIds.size() + ' records.', result, 'Should return success message');
        
        List<Account> updatedAccounts = [SELECT Id, Name FROM Account WHERE Id IN :accountIds];
        for(Account acc : updatedAccounts) {
            System.assertEquals(newName, acc.Name, 'Name should be updated');
        }
    }
    
    @IsTest
    static void testUpdateRecordsInvalidInput() {
        Test.startTest();
        String result1 = BulkUpdaterController.updateRecords('', 'Name', 'Value', new List<Id>{'001000000000001'});
        String result2 = BulkUpdaterController.updateRecords('Account', '', 'Value', new List<Id>{'001000000000001'});
        String result3 = BulkUpdaterController.updateRecords('Account', 'Name', 'Value', null);
        String result4 = BulkUpdaterController.updateRecords('Account', 'Name', 'Value', new List<Id>());
        Test.stopTest();
        
        System.assertEquals('Invalid input.', result1, 'Should validate object name');
        System.assertEquals('Invalid input.', result2, 'Should validate field name');
        System.assertEquals('Invalid input.', result3, 'Should validate recordIds not null');
        System.assertEquals('Invalid input.', result4, 'Should validate recordIds not empty');
    }
    
 @IsTest
static void testUpdateRecordsFailure() {
    // Test data setup
    Account testAccount = new Account(Name = 'Test Account');
    insert testAccount;

    // Scenario 1: Invalid object name
    Test.startTest();
    String result1 = BulkUpdaterController.updateRecords('', 'Name', 'New Name', new List<Id>{testAccount.Id});
    String result2 = BulkUpdaterController.updateRecords('InvalidObject', 'Name', 'New Name', new List<Id>{testAccount.Id});
    Test.stopTest();
    
    System.assertEquals('Invalid input.', result1, 'Should reject empty object name');
    System.assert(result2.startsWith('Update failed:'), 'Should fail for invalid object');

    // Scenario 2: Invalid field name
    Test.startTest();
    String result3 = BulkUpdaterController.updateRecords('Account', '', 'New Name', new List<Id>{testAccount.Id});
    String result4 = BulkUpdaterController.updateRecords('Account', 'InvalidField', 'New Name', new List<Id>{testAccount.Id});
    Test.stopTest();
    
    System.assertEquals('Invalid input.', result3, 'Should reject empty field name');
    System.assert(result4.startsWith('Update failed:'), 'Should fail for invalid field');

    // Scenario 3: Invalid record IDs
    Test.startTest();
    String result5 = BulkUpdaterController.updateRecords('Account', 'Name', 'New Name', null);
    String result6 = BulkUpdaterController.updateRecords('Account', 'Name', 'New Name', new List<Id>());
    String result7 = BulkUpdaterController.updateRecords('Account', 'Name', 'New Name', new List<Id>{'001000000000000'});
    Test.stopTest();
    
    System.assertEquals('Invalid input.', result5, 'Should reject null recordIds');
    System.assertEquals('Invalid input.', result6, 'Should reject empty recordIds');
    System.assert(result7.startsWith('Update failed:'), 'Should fail for invalid record ID');

    // Scenario 4: Field validation failure
    Test.startTest();
    String result8 = BulkUpdaterController.updateRecords('Account', 'Name', null, new List<Id>{testAccount.Id});
    Test.stopTest();
    
    System.assert(result8.startsWith('Update failed:'), 'Should fail for validation rules: ' + result8);

    // Scenario 5: Required field missing (using Phone as example)
    if (Schema.sObjectType.Account.fields.Phone.isCreateable()) {
        Account accWithPhone = new Account(Name = 'Phone Test', Phone = '1234567890');
        insert accWithPhone;
        
        Test.startTest();
        String result9 = BulkUpdaterController.updateRecords('Account', 'Phone', null, new List<Id>{accWithPhone.Id});
        Test.stopTest();
        
        System.assert(result9.startsWith('Update failed:'), 'Should fail for required field removal');
    }
}
    
    @IsTest
    static void testDeleteRecordsSuccess() {
        List<Contact> contacts = [SELECT Id FROM Contact];
        List<Id> contactIds = new List<Id>();
        for(Contact con : contacts) {
            contactIds.add(con.Id);
        }
        
        Test.startTest();
        String result = BulkUpdaterController.deleteRecords('Contact', contactIds);
        Test.stopTest();
        
        System.assertEquals('Deleted ' + contactIds.size() + ' records.', result, 'Should return success message');
        
        List<Contact> remainingContacts = [SELECT Id FROM Contact WHERE Id IN :contactIds];
        System.assertEquals(0, remainingContacts.size(), 'All contacts should be deleted');
    }
    
    @IsTest
    static void testDeleteRecordsInvalidInput() {
        Test.startTest();
        String result1 = BulkUpdaterController.deleteRecords('', new List<Id>{'003000000000001'});
        String result2 = BulkUpdaterController.deleteRecords('Contact', null);
        String result3 = BulkUpdaterController.deleteRecords('Contact', new List<Id>());
        Test.stopTest();
        
        System.assertEquals('Invalid input.', result1, 'Should validate object name');
        System.assertEquals('Invalid input.', result2, 'Should validate recordIds not null');
        System.assertEquals('Invalid input.', result3, 'Should validate recordIds not empty');
    }
    
  @IsTest
static void testDeleteRecordsFailure() {
    // Create test data that will cause deletion to fail
    Account parentAccount = new Account(Name = 'Parent Account');
    insert parentAccount;
    
    Account childAccount = new Account(
        Name = 'Child Account',
        ParentId = parentAccount.Id
    );
    insert childAccount;
    
    // Try to delete the parent account (should fail due to child account)
    List<Id> accountIds = new List<Id>{parentAccount.Id};
    
    Test.startTest();
    String result = BulkUpdaterController.deleteRecords('Account', accountIds);
    Test.stopTest();
    
    // Verify the parent account still exists
    List<Account> remainingAccounts = [SELECT Id FROM Account WHERE Id = :parentAccount.Id];
    System.assertEquals(1, remainingAccounts.size(), 'Parent account should not be deleted due to child record');
    
    // Verify the error message
    System.assert(
        result != null && result.startsWith('Delete failed:'), 
        'Expected failure message but got: ' + result
    );
}
}