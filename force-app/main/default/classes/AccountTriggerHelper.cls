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
}