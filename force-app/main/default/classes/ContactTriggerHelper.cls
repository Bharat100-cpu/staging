public with sharing class ContactTriggerHelper {
    
    public static void validateContacts(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        if (newContacts == null || newContacts.isEmpty()) return;

        for (Contact c : newContacts) {
            if (String.isNotBlank(c.Email)) {
                c.Email = c.Email.trim().toLowerCase();
            }
        }

        Set<Id> accountIds = new Set<Id>();
        Set<String> emails = new Set<String>();
        Map<String, List<Contact>> newKeyToContacts = new Map<String, List<Contact>>();
        List<Contact> toValidate = new List<Contact>();

        for (Contact c : newContacts) {
            if (c.AccountId == null || String.isBlank(c.Email)) continue;

            if (oldMap != null && oldMap.containsKey(c.Id)) {
                Contact oldC = oldMap.get(c.Id);
                String oldEmail = oldC.Email == null ? null : oldC.Email.trim().toLowerCase();
                Id oldAccountId = oldC.AccountId;
                if (String.valueOf(c.Email) == String.valueOf(oldEmail) && c.AccountId == oldAccountId) {
                    continue;
                }
            }

            toValidate.add(c);
            accountIds.add(c.AccountId);
            emails.add(c.Email);

            String key = c.AccountId + '::' + c.Email;
            if (!newKeyToContacts.containsKey(key)) newKeyToContacts.put(key, new List<Contact>());
            newKeyToContacts.get(key).add(c);
        }

        for (String k : newKeyToContacts.keySet()) {
            List<Contact> contactList = newKeyToContacts.get(k);
            if (contactList.size() > 1) {
                for (Contact c : contactList) {
                    c.addError('Duplicate email for the same Account in this operation.');
                }
            }
        }

        if (toValidate.isEmpty() || emails.isEmpty() || accountIds.isEmpty()) return;

        List<Contact> existing = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE Email IN :emails
              AND AccountId IN :accountIds
        ];

        Map<String, List<Contact>> existingMap = new Map<String, List<Contact>>();
        for (Contact ec : existing) {
            if (ec.AccountId == null || String.isBlank(ec.Email)) continue;
            String ecEmail = ec.Email.trim().toLowerCase();
            String key = ec.AccountId + '::' + ecEmail;
            if (!existingMap.containsKey(key)) existingMap.put(key, new List<Contact>());
            existingMap.get(key).add(ec);
        }

        for (Contact c : toValidate) {
            String key = c.AccountId + '::' + c.Email;
            if (existingMap.containsKey(key)) {
                for (Contact ec : existingMap.get(key)) {
                    if (ec.Id != c.Id) {
                        c.addError('A Contact with this email already exists on the same Account.');
                        break;
                    }
                }
            }
        }
    }

    public static void calculateHealthScore(List<Contact> newContacts, Map<Id, Contact> oldContacts) {

        Set<Id> accountIds = new Set<Id>();
        if (oldContacts != null) {
            for (Contact con : oldContacts.values()) {
                accountIds.add(con.AccountId);
            }
        }
        for (Contact con : newContacts) {
            accountIds.add(con.AccountId);
        }

        List<Account> relatedAccounts = [SELECT Id, Name, Number_of_Contacts__c, Health_Score__c FROM Account WHERE Id IN : accountIds];

        Map<Id, Account> accountsMap = new Map<Id, Account>();
        if (relatedAccounts != null) {
            for (Account acc : relatedAccounts) {
               if (!accountsMap.containsKey(acc.Id)) {
                    accountsMap.put(acc.Id, acc);
               }
            }
        }

        List<AggregateResult> results = [SELECT AccountId, COUNT(Id) contacts FROM Contact WHERE AccountId IN : accountIds GROUP BY AccountId];
        List<Account> accountsToUpdate = new List<Account>();

        for (AggregateResult ar : results) {
            if (accountsMap != null) {
                Id accountId = (String)ar.get('AccountId');
                if (accountsMap.containsKey(accountId)) {
                    Account relatedAccount = accountsMap.get(accountId);
                    Integer totalContacts = (Integer)ar.get('contacts');
                    if(totalContacts != relatedAccount.Number_of_Contacts__c) {
                        if (totalContacts > 10) {
                            relatedAccount.Health_Score__c = 'High';
                        } else if(totalContacts > 5 && totalContacts <= 10) {
                            relatedAccount.Health_Score__c = 'Medium';
                        } else if(totalContacts <= 5) {
                            relatedAccount.Health_Score__c = 'Low';
                        }
                    }
                    relatedAccount.Number_of_Contacts__c = totalContacts;
                    accountsToUpdate.add(relatedAccount);
                }
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}