trigger TaskTrigger on Task (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            TaskTriggerHandler.updateContacts(Trigger.new, Trigger.oldMap);   
        }
        if (Trigger.isUpdate) {
            TaskTriggerHandler.updateContactLastInterationDate(Trigger.new, Trigger.oldMap);
            TaskTriggerHandler.updateContacts(Trigger.new, Trigger.newMap);
        }
        if (Trigger.isDelete) {
            TaskTriggerHandler.updateContacts(Trigger.new, Trigger.oldMap);   
        }
    }
}