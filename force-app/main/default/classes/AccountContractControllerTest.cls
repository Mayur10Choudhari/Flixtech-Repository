@isTest
public class AccountContractControllerTest {
    
    /**
    * @testSetup method to create test data before test execution.
    * This method inserts a test Account and multiple Account_Contract_Clause__c records.
    */
    @testSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(Name = 'Test Account', BillingCountry = 'India');
        insert testAccount;
        
        // Create test clauses
        List<Account_Contract_Clause__c> clauses = new List<Account_Contract_Clause__c>();
        for (Integer i = 0; i < 3; i++) {
            clauses.add(new Account_Contract_Clause__c(Name = 'Clause ' + i, Billing_Country__c = 'India'));
        }
        insert clauses;
    }
    
    /**
    * Test method for AccountContractController.getAccountClauses().
    * Validates that the method returns the correct number of clauses for a given Account.
    */
    @isTest
    static void testGetAccountClauses(){
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        
        Test.startTest();
        List<Account_Contract_Clause__c> result = AccountContractController.getAccountClauses(testAccount.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(3, result.size(), 'There should be exactly one clause returned');
    }
    
    /**
	* Test method for AccountContractController.createAccountContract().
	* Ensures that a contract is successfully created for a given Account and selected clauses.
	*/
    @isTest
    static void testCreateAccountContract() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        List<Account_Contract_Clause__c> clauses = [SELECT Id FROM Account_Contract_Clause__c];
        
        Test.startTest();
        Id contractId = AccountContractController.createAccountContract(testAccount.Id, new List<Id>{clauses[0].Id, clauses[1].Id});
        Test.stopTest();
        
        System.assertNotEquals(null, contractId, 'Account Contract should be created');
        
    }
    
    /**
    * Test method to verify the creation of a contract clause file.
    * This test ensures that when contract clauses are provided, a ContentVersion
    * file is correctly generated and associated with the contract.
    */
    @isTest
    static void testCreateContractClauseFile() {
        Account testAccount = [SELECT Id FROM Account WHERE Name = 'Test Account'];
        List<Account_Contract_Clause__c> clauses = [SELECT Id, Name FROM Account_Contract_Clause__c];
        
        Id contractId = AccountContractController.createAccountContract(testAccount.Id, new List<Id>{clauses[0].Id});
        
        List<String> clauseNames = new List<String>();
        for (Account_Contract_Clause__c clause : clauses) {
            clauseNames.add(clause.Name);
        }
        
        Test.startTest();
        AccountContractController.createContractClauseFile(contractId, clauseNames);
        Test.stopTest();
        
        ContentVersion file = [SELECT Id, Title FROM ContentVersion WHERE FirstPublishLocationId = :contractId];
        System.assertEquals('Selected Account Contract Clauses', file.Title, 'File should be created with correct title');
    }
}