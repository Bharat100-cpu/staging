public with sharing class ContactTriggerHelper {
    
    // =======================
    // Validation: Email unique per Account
    // =======================
    public static void validateContacts(List<Contact> newContacts, Map<Id, Contact> oldMap) {
        ContactEmailValidator.validateContacts(newContacts, oldMap);
    }

    // =======================
    // Rollup-ish: Account health score
    // =======================
    public static void calculateHealthScore(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        ContactHealthScoreCalculator.calculateHealthScore(newContacts, oldContacts);
    }

    // =======================
    // Primary Contact sync to Account
    // =======================
    public static void updatePrimaryContactDetailsOnAccount(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        ContactPrimarySyncManager.updatePrimaryContactDetailsOnAccount(newContacts, oldContacts);
    }
}