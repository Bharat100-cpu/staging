public with sharing class ContactHealthScoreCalculator {
    
    // =======================
    // Rollup-ish: Account health score
    // =======================
    public static void calculateHealthScore(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        if (shouldSkipHealthScore(newContacts, oldContacts)) {
            return;
        }

        enforceHealthScoreSecurity();

        Set<Id> accountIds = collectAccountIds(newContacts, oldContacts);
        if (accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountsById = queryAccountsById(accountIds);
        if (accountsById.isEmpty()) {
            return;
        }

        List<AggregateResult> contactRollups = aggregateContactsByAccount(accountIds);
        if (contactRollups.isEmpty()) {
            return;
        }

        List<Account> toUpdate = buildAccountRollups(accountsById, contactRollups);
        
        if (!toUpdate.isEmpty()) {
            update toUpdate; // object/field updateability enforced in security guard
        }
    }

    private static Boolean shouldSkipHealthScore(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> accountIds = collectAccountIds(newContacts, oldContacts);
        return accountIds.isEmpty();
    }

    private static List<Account> buildAccountRollups(Map<Id, Account> accountsById, List<AggregateResult> contactRollups) {
        List<Account> toUpdate = new List<Account>();
        for (AggregateResult ar : contactRollups) {
            Id accId = (Id) ar.get('AccountId');
            Account acc = accountsById.get(accId);
            if (acc == null) {
                continue;
            }
            Integer total = (Integer) ar.get('contacts');
            if (acc.Number_of_Contacts__c == total) {
                continue; // avoid unnecessary DML
            }
            acc.Number_of_Contacts__c = total;
            acc.Health_Score__c = deriveHealthScore(total);
            toUpdate.add(acc);
        }
        return toUpdate;
    }

    private static void enforceHealthScoreSecurity() {
        // CRUD on Contact (read)
        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new SecurityException('Insufficient access: Contact read permission is required.');
        }
        // CRUD on Account (read + update)
        if (!Schema.sObjectType.Account.isAccessible()) {
            throw new SecurityException('Insufficient access: Account read permission is required.');
        }
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('Insufficient access: Account update permission is required.');
        }
        // FLS: read + update on the fields used
        if (!Account.Number_of_Contacts__c.getDescribe().isAccessible()
            || !Account.Health_Score__c.getDescribe().isAccessible()) {
            throw new SecurityException('Insufficient field access: Account fields read permission is required.');
        }
        if (!Account.Number_of_Contacts__c.getDescribe().isUpdateable()
            || !Account.Health_Score__c.getDescribe().isUpdateable()) {
            throw new SecurityException('Insufficient field access: Account fields update permission is required.');
        }
    }

    private static Set<Id> collectAccountIds(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        Set<Id> ids = new Set<Id>();
        if (oldContacts != null) {
            for (Contact c : oldContacts.values()) {
                if (c != null && c.AccountId != null) {
                    ids.add(c.AccountId);
                }
            }
        }
        if (newContacts != null) {
            for (Contact c : newContacts) {
                if (c != null && c.AccountId != null) {
                    ids.add(c.AccountId);
                }
            }
        }
        return ids;
    }

    private static Map<Id, Account> queryAccountsById(Set<Id> accountIds) {
        Map<Id, Account> mapById = new Map<Id, Account>();
        if (accountIds == null || accountIds.isEmpty()) {
            return mapById;
        }
        for (Account acc : [
            SELECT Id, Name, Number_of_Contacts__c, Health_Score__c
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            mapById.put(acc.Id, acc);
        }
        return mapById;
    }

    private static List<AggregateResult> aggregateContactsByAccount(Set<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return new List<AggregateResult>();
        }
        return [
            SELECT AccountId, COUNT(Id) contacts
            FROM Contact
            WHERE AccountId IN :accountIds
            GROUP BY AccountId
        ];
    }

    private static String deriveHealthScore(Integer totalContacts) {
        if (totalContacts == null) {
            return 'Low';
        }
        if (totalContacts > 10) {
            return 'High';
        }
        if (totalContacts > 5) {
            return 'Medium';
        }
        return 'Low';
    }
}