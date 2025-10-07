trigger CaseTrigger on Case (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore) {
        
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            CaseTriggerHandler.createFollowUpTask(Trigger.new);
        }
    }
}