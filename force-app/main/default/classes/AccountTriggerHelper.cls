public with sharing class AccountTriggerHelper {
    
    public static void createPrimaryContactForIndustryAccount(Map<Id,Account> newAccountsMap) {

        Map<Id, Boolean> result = new Map<Id, Boolean>();
        for(AggregateResult ar : [SELECT AccountId, COUNT(Id) cnt 
                                  FROM Contact 
                                  WHERE AccountId  IN :newAccountsMap.keySet() 
                                  AND Account.Industry = 'Banking' 
                                  GROUP BY AccountId]) {
            result.put((Id)ar.get('AccountId'), true);
        }

        for(Id accId : newAccountsMap.keySet()) {
            if(!result.containsKey(accId)) {
                result.put(accId, false);
            }
        }

        List<Contact> contactsToInsert = new List<Contact>();
        for(Account acc: newAccountsMap.values()) {
            if(result.containsKey(acc.Id) && !result.get(acc.Id)) {
                Contact con = new Contact();
                con.LastName = acc.Name;
                con.Email = acc.Name + '@example.com';
                con.Role__c = 'Primary';
                con.Primary_Role__c = true;
                con.AccountId = acc.Id;
                contactsToInsert.add(con);
            }
        }

        if(!contactsToInsert.isEmpty()) {
            try {
                insert contactsToInsert;
            } catch (Exception e) {
                System.debug('message : ' + e.getMessage());
                throw new AuraHandledException(e.getMessage());
            }
        }
    }

    public static void insertTask(List<Account> accounts) {

        List<Task> tasksToInsert = new List<Task>();
        for (Account account : accounts) {
            Task task = new Task();
            task.Subject = 'Welcome Call';
            task.Status = 'Not Started';
            task.Priority = 'High';
            task.ActivityDate = Date.today().addDays(3);
            task.WhatId = account.Id;
            task.OwnerId = account.OwnerId;
            tasksToInsert.add(task);
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    public static void setRating(List<Account> newAccounts, Map<Id, Account> oldAccounts) {

        for (Account account : newAccounts) {
            if (!oldAccounts.isEmpty()) {
                Account oldAccount = oldAccounts.get(account.Id);
                if (account.AnnualRevenue == oldAccount.AnnualRevenue) {
                    continue;
                }
            }
            if (account.AnnualRevenue > 1000000) {
                account.Rating = 'Hot';
            } else if (account.AnnualRevenue > 500000 && account.AnnualRevenue < 999999) {
                account.Rating = 'Warm';
            } else if (account.AnnualRevenue < 500000 && account.AnnualRevenue != 0) {
                account.Rating = 'Cold';
            } else if (account.AnnualRevenue == null || account.AnnualRevenue == 0) {
                account.Rating = '';
            }
        }
    }

    public static void accountValidationToDelete(List<Account> accounts) {

        Set<Id> accountIds = new Set<Id>();
        for (Account account : accounts) {
            accountIds.add(account.Id);
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

        for (Account accountObj : accounts) {
            if (accountsWithOppCount.containsKey(accountObj.Id) && accountsWithOppCount.get(accountObj.Id) > 0) {
                accountObj.addError('Cannot delete Account with related Opportunities. Please close or delete all Opportunities first.');
            }
        }
    }
}