public with sharing class AccountContactCreator {
    
    public static void createPrimaryContactForIndustryAccount(Map<Id,Account> newAccountsMap) {
        // Process contact creation for banking accounts
        processContactCreationForBankingAccounts(newAccountsMap);
    }
    
    private static void processContactCreationForBankingAccounts(Map<Id,Account> newAccountsMap) {
        // Get existing banking accounts with contacts
        Map<Id, Boolean> existingBankingAccounts = getExistingBankingAccounts(newAccountsMap);
        
        // Create contacts for accounts that don't have banking contacts
        List<Contact> contactsToInsert = createContactsForNewBankingAccounts(newAccountsMap, existingBankingAccounts);
        
        // Insert contacts if any exist
        if (!contactsToInsert.isEmpty()) {
            // Validate CRUD permission before DML operation
            if (Schema.sObjectType.Contact.isCreateable()) {
                insert contactsToInsert;
            }
        }
    }
    
    private static Map<Id, Boolean> getExistingBankingAccounts(Map<Id,Account> newAccountsMap) {
        Map<Id, Boolean> result = new Map<Id, Boolean>();
        
        for (AggregateResult ar : [
            SELECT AccountId, COUNT(Id) cnt
            FROM Contact
            WHERE AccountId IN :newAccountsMap.keySet()
              AND Account.Industry = 'Banking'
            GROUP BY AccountId
        ]) {
            result.put((Id) ar.get('AccountId'), true);
        }

        for(Id accId : newAccountsMap.keySet()) {
            if(!result.containsKey(accId)) {
                result.put(accId, false);
            }
        }
        
        return result;
    }
    
    private static List<Contact> createContactsForNewBankingAccounts(Map<Id,Account> newAccountsMap, Map<Id, Boolean> existingBankingAccounts) {
        List<Contact> contactsToInsert = new List<Contact>();
        
        for (Account acc : newAccountsMap.values()) {
            if (existingBankingAccounts.containsKey(acc.Id) && !existingBankingAccounts.get(acc.Id)) {
                Contact con = new Contact();
                con.LastName = acc.Name;
                con.Email = 'test@example.com';
                con.AccountId = acc.Id;
                contactsToInsert.add(con);
            }
        }
        
        return contactsToInsert;
    }
}