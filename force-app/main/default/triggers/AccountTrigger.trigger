trigger AccountTrigger on Account (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Trigger.isAfter) {
        if(Trigger.isInsert) {
            AccountTriggerHelper.createPrimaryContactForIndustryAccount(trigger.newMap);
        }
    }
}