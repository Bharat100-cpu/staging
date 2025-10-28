trigger TaskTrigger on Task (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            TaskTriggerHandler.updateContactLastInterationDate(Trigger.new, Trigger.oldMap);
        }
    }
}