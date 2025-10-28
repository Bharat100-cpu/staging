trigger OrderTrigger on Order (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            OrderInventoryHelper.processOrderStatusChanges(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            OrderInventoryHelper.processOrderStatusChangeAdjustments(Trigger.new, Trigger.oldMap);
        }
    }
}
