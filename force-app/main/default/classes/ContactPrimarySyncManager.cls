public with sharing class ContactPrimarySyncManager {
    
    // =======================
    // Primary Contact sync to Account
    // =======================
    public static void updatePrimaryContactDetailsOnAccount(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        if (shouldSkipPrimarySync(newContacts)) {
            return;
        }

        enforcePrimarySyncSecurity();

        // 1) Derive intent
        PrimaryChangeIntents intents = new PrimaryChangeIntents();
        derivePrimaryChangeIntents(newContacts, oldContacts, intents);

        if (intents.accountsBecomingPrimary.isEmpty() && intents.accountsClearingPrimary.isEmpty()) {
            return;
        }

        // 2) Uncheck existing primaries for accounts that will have a new primary
        List<Contact> contactsToUncheck = queryExistingPrimariesToUncheck(intents.accountsBecomingPrimary.keySet(), newContacts);

        // 3) Build account updates
        Map<Id, Account> accountsToUpdate = buildAccountsToUpdate(intents);

        // 4) DML
        if (!contactsToUncheck.isEmpty()) {
            update contactsToUncheck;
        }
        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
        }
    }

    private static void enforcePrimarySyncSecurity() {
        // Security checks
        if (!Schema.sObjectType.Contact.isAccessible()) {
            throw new SecurityException('Insufficient access: Contact read permission is required.');
        }
        if (!Schema.sObjectType.Contact.isUpdateable()) {
            throw new SecurityException('Insufficient access: Contact update permission is required.');
        }
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('Insufficient access: Account update permission is required.');
        }
    }

    private static Boolean shouldSkipPrimarySync(List<Contact> newContacts) {
        return newContacts == null || newContacts.isEmpty();
    }

    private static List<Contact> queryExistingPrimariesToUncheck(Set<Id> affectedAccountIds, List<Contact> newContacts) {
        List<Contact> contactsToUncheck = new List<Contact>();
        if (!affectedAccountIds.isEmpty()) {
            for (Contact existingPrimary : [
                SELECT Id, AccountId, Primary_Contact__c
                FROM Contact
                WHERE Primary_Contact__c = true
                  AND AccountId IN :affectedAccountIds
                  AND Id NOT IN :newContacts
            ]) {
                existingPrimary.Primary_Contact__c = false;
                contactsToUncheck.add(existingPrimary);
            }
        }
        return contactsToUncheck;
    }

    private static Map<Id, Account> buildAccountsToUpdate(PrimaryChangeIntents intents) {
        // 3) Build account updates
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();

        // a) Clear accounts explicitly unmarked as primary
        for (Id accId : intents.accountsClearingPrimary) {
            accountsToUpdate.put(accId, makeClearingAccount(accId));
        }
        // b) Set phone/email for accounts gaining a new primary
        for (Id accId : intents.accountsBecomingPrimary.keySet()) {
            Contact c = intents.accountsBecomingPrimary.get(accId);
            accountsToUpdate.put(accId, makeAccountForPrimary(c));
        }
        return accountsToUpdate;
    }

    private static void derivePrimaryChangeIntents(
        List<Contact> newContacts,
        Map<Id, Contact> oldContacts,
        PrimaryChangeIntents intents
    ) {
        for (Contact nc : newContacts) {
            if (nc == null || nc.AccountId == null) {
                continue;
            }

            Contact oc = (oldContacts == null) ? null : oldContacts.get(nc.Id);
            if (isBecomingPrimary(nc, oc)) {
                intents.accountsBecomingPrimary.put(nc.AccountId, nc);
            } else if (isUncheckingPrimary(nc, oc)) {
                intents.accountsClearingPrimary.add(nc.AccountId);
            }
        }
    }

    private static Boolean isBecomingPrimary(Contact newC, Contact oldC) {
        final Boolean nowPrimary = (newC != null && newC.Primary_Contact__c);
        final Boolean wasPrimary = (oldC != null && oldC.Primary_Contact__c);
        return nowPrimary && !wasPrimary;
    }

    private static Boolean isUncheckingPrimary(Contact newC, Contact oldC) {
        final Boolean nowPrimary = (newC != null && newC.Primary_Contact__c);
        final Boolean wasPrimary = (oldC != null && oldC.Primary_Contact__c);
        return !nowPrimary && wasPrimary;
    }

    private static Account makeAccountForPrimary(Contact c) {
        return new Account(
            Id = c.AccountId,
            Phone = c.Phone,
            Primary_Contact_Email__c = c.Email
        );
    }

    private static Account makeClearingAccount(Id accountId) {
        return new Account(
            Id = accountId,
            Phone = '',
            Primary_Contact_Email__c = ''
        );
    }
    
    @TestVisible
    private class PrimaryChangeIntents {
        Map<Id, Contact> accountsBecomingPrimary = new Map<Id, Contact>();
        Set<Id> accountsClearingPrimary = new Set<Id>();
    }
}
