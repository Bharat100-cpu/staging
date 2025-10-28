trigger OrderItemTrigger on OrderItem (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert || Trigger.isUpdate) {
            OrderItemInventoryHelper.processOrderItemInventory(Trigger.new, Trigger.oldMap);
        }
    }

    if (Trigger.isAfter) {
        if (Trigger.isInsert || Trigger.isUpdate || Trigger.isDelete) {
            OrderItemInventoryHelper.processOrderItemInventoryAdjustments(Trigger.new, Trigger.oldMap);
        }
    }
}
