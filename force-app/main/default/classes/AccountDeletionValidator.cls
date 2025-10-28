public with sharing class AccountDeletionValidator {
    
    public static void validateAccountToDelete(List<Account> accounts) {
        Map<Id, Integer> accountsWithOppCount = getAccountsWithOpenOpportunities(accounts);
        validateAccountDeletion(accounts, accountsWithOppCount);
    }
    
    private static Map<Id, Integer> getAccountsWithOpenOpportunities(List<Account> accounts) {
        Set<Id> accountIds = new Set<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
        }

        // Validate CRUD permission before SOQL operation
        if (!Schema.sObjectType.Opportunity.isAccessible()) {
            throw new System.SecurityException('Insufficient permissions to access Opportunity records');
        }

        List<AggregateResult> result = [
            SELECT COUNT(Id) totalOpps, AccountId  
            FROM Opportunity 
            WHERE AccountId IN : accountIds AND StageName != 'Closed'
            GROUP BY AccountId
        ];

        Map<Id, Integer> accountsWithOppCount = new Map<Id, Integer>();
        for (AggregateResult ag : result) {
            accountsWithOppCount.put((Id)ag.get('AccountId'), (Integer)ag.get('totalOpps'));
        }
        
        return accountsWithOppCount;
    }
    
    private static void validateAccountDeletion(List<Account> accounts, Map<Id, Integer> accountsWithOppCount) {
        for (Account accountObj : accounts) {
            if (accountsWithOppCount.containsKey(accountObj.Id) && accountsWithOppCount.get(accountObj.Id) > 0) {
                accountObj.addError('Cannot delete Account with related Opportunities. Please close or delete all Opportunities first.');
            }
        }
    }
}