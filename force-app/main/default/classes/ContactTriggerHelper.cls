public with sharing class ContactTriggerHelper {
    /**
     * Call from before insert / before update.
     * @param newContacts Trigger.new
     * @param oldMap Trigger.oldMap (pass null for inserts)
     */
    public static void validateContacts(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        if (newContacts == null || newContacts.isEmpty()) return;

        // 1) Normalize emails first (trim + lower)
        for (Contact c : newContacts) {
            if (String.isNotBlank(c.Email)) {
                c.Email = c.Email.trim().toLowerCase();
            }
        }

        // 2) Collect keys to validate and detect intra-batch duplicates
        Set<Id> accountIds = new Set<Id>();
        Set<String> emails = new Set<String>();
        Map<String, List<Contact>> newKeyToContacts = new Map<String, List<Contact>>();
        List<Contact> toValidate = new List<Contact>();

        for (Contact c : newContacts) {
            // only validate when both AccountId and Email are present
            if (c.AccountId == null || String.isBlank(c.Email)) continue;

            // on update: skip if neither Email nor AccountId changed (after normalization)
            if (oldMap != null && oldMap.containsKey(c.Id)) {
                Contact oldC = oldMap.get(c.Id);
                String oldEmail = oldC.Email == null ? null : oldC.Email.trim().toLowerCase();
                Id oldAccountId = oldC.AccountId;
                if (String.valueOf(c.Email) == String.valueOf(oldEmail) && c.AccountId == oldAccountId) {
                    continue; // nothing meaningful changed — skip expensive validation
                }
            }

            toValidate.add(c);
            accountIds.add(c.AccountId);
            emails.add(c.Email);

            String key = c.AccountId + '::' + c.Email;
            if (!newKeyToContacts.containsKey(key)) newKeyToContacts.put(key, new List<Contact>());
            newKeyToContacts.get(key).add(c);
        }

        // 3) Fail fast for duplicates within the same transaction (same Account+Email)
        for (String k : newKeyToContacts.keySet()) {
            List<Contact> contactList = newKeyToContacts.get(k);
            if (contactList.size() > 1) {
                for (Contact c : contactList) {
                    c.addError('Duplicate email for the same Account in this operation.');
                }
            }
        }

        // 4) If nothing else to validate, return
        if (toValidate.isEmpty() || emails.isEmpty() || accountIds.isEmpty()) return;

        // 5) Query existing contacts that share Email AND AccountId (single SOQL)
        List<Contact> existing = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE Email IN :emails
              AND AccountId IN :accountIds
        ];

        // map existing by composite key (accountId::email)
        Map<String, List<Contact>> existingMap = new Map<String, List<Contact>>();
        for (Contact ec : existing) {
            if (ec.AccountId == null || String.isBlank(ec.Email)) continue;
            String ecEmail = ec.Email.trim().toLowerCase();
            String key = ec.AccountId + '::' + ecEmail;
            if (!existingMap.containsKey(key)) existingMap.put(key, new List<Contact>());
            existingMap.get(key).add(ec);
        }

        // 6) Validate each contact against DB results (exclude itself on update)
        for (Contact c : toValidate) {
            String key = c.AccountId + '::' + c.Email;
            if (existingMap.containsKey(key)) {
                for (Contact ec : existingMap.get(key)) {
                    // if existing record is not the current record (insert: c.Id == null)
                    if (ec.Id != c.Id) {
                        c.addError('A Contact with this email already exists on the same Account.');
                        break;
                    }
                }
            }
        }
    }
}