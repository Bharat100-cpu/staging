trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            ContactEmailValidator.validateContacts(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            ContactEmailValidator.validateContacts(Trigger.new, Trigger.oldMap);
        }
    }

    if(Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContactHealthScoreCalculator.calculateHealthScore(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            ContactHealthScoreCalculator.calculateHealthScore(Trigger.new, Trigger.oldMap);
            ContactPrimarySyncManager.updatePrimaryContactDetailsOnAccount(Trigger.new, Trigger.oldMap);
        }
    }
}
