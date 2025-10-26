trigger InvoiceTrigger on Invoice__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            InvoiceTriggerHandler.updateStatus(Trigger.new);
        }
        if (Trigger.isUpdate) {
            InvoiceTriggerHandler.updateStatus(Trigger.new);
        }
    }
}
