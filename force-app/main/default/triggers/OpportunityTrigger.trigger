trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            OpportunityTriggerHandler.setPriorityOnOppInsertAndUpdate(Trigger.new);
        }
        if(Trigger.isUpdate) {
            OpportunityTriggerHandler.setPriorityOnOppInsertAndUpdate(Trigger.new);
        }
    }
}