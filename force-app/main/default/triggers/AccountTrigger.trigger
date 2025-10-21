trigger AccountTrigger on Account (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            AccountTriggerHelper.setRating(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isUpdate) {
            AccountTriggerHelper.setRating(Trigger.new, Trigger.oldMap);
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            AccountTriggerHelper.insertTask(Trigger.new);
            AccountTriggerHelper.createPrimaryContactForIndustryAccount(trigger.newMap);
        }
    }
}