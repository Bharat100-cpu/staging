trigger AccountTrigger on Account (
    before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
        }
    }
    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            AccountTriggerHelper.insertTask(Trigger.new);
            AccountTriggerHelper.createPrimaryContactForIndustryAccount(trigger.newMap);
        }
    }
}