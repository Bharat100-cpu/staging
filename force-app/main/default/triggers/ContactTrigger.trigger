trigger ContactTrigger on Contact (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            ContactTriggerHelper.validateContacts(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            ContactTriggerHelper.validateContacts(Trigger.new, Trigger.oldMap);
        }
    }

    if(Trigger.isAfter) {
        if (Trigger.isInsert) {
            ContactTriggerHelper.calculateHealthScore(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            ContactTriggerHelper.calculateHealthScore(Trigger.new, Trigger.oldMap);
        }
    }
}