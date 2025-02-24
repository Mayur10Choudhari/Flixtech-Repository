public with sharing class AccountContractController {
    
    /**
     * Retrieves a list of Account Contract Clauses based on the Billing Country of an existing Account.
     * @return List of Account_Contract_Clause__c records matching the Billing Country.
     */
    @AuraEnabled(cacheable=true)
    public static List<Account_Contract_Clause__c> getAccountClauses(Id recordId) {
        Account acc = [SELECT BillingCountry FROM Account WHERE id=:recordId];
        return [SELECT Id, Name FROM Account_Contract_Clause__c WHERE Billing_Country__c = :acc.BillingCountry];
    }

    /**
     * Creates a new Account Contract and associates it with the specified Account and selected Clauses.
     * @param accountId The Id of the Account for which the contract is being created.
     * @param clauseIds A list of Ids representing the contract clauses to be linked to the new contract.
     * @return The Id of the newly created Account_Contract__c record.
     * @throws AuraHandledException if invalid data is provided (null accountId or empty clause list).
     */
    @AuraEnabled
    public static Id createAccountContract(Id accountId, List<Id> clauseIds) {
        List<Account_Contract_Clause__c> clausesToUpdate = New List<Account_Contract_Clause__c>();
        if (accountId == null || clauseIds.isEmpty()) {
            throw new AuraHandledException('Invalid data provided.');
        }
        
        Account_Contract__c newContract = new Account_Contract__c(
            Name = 'New Account Contract - ' + System.today(),
            Account__c = accountId
        );
        insert newContract;
        
        for(Id inst: clauseIds){
            Account_Contract_Clause__c clause = new Account_Contract_Clause__c();
            clause.Id = inst;
            clause.Account_Contract__c = newContract.Id;
            clausesToUpdate.add(clause);
        }
        if(!clausesToUpdate.isEmpty()){
            update clausesToUpdate;    
        }

        return newContract.Id;
    }

    /**
     * Creates a text file containing the selected contract clauses and attaches it to the given contract.
     * @param contractId The Id of the Account Contract to which the file will be attached.
     * @param clauseNames A list of clause names to be included in the file.
     * @throws AuraHandledException if invalid data is provided (null contractId or empty clause list).
     */
    @AuraEnabled
    public static void createContractClauseFile(Id contractId, List<String> clauseNames) {
        if (contractId == null || clauseNames.isEmpty()) {
            throw new AuraHandledException('Invalid data provided.');
        }

        ContentVersion file = new ContentVersion();
        file.Title = 'Selected Account Contract Clauses';
        file.PathOnClient = 'SelectedClauses.txt';
        file.VersionData = Blob.valueOf('Selected Account Contract Clauses:\n' + String.join(clauseNames, '\n'));
        file.FirstPublishLocationId = contractId;
        insert file;
    }
}