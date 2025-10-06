trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            OpportunityTriggerHandler.setPriorityOnOppInsertAndUpdate(Trigger.new);
            OpportunityTriggerHandler.closeDateValidationAndProbabilityPrediction(Trigger.new);
            OpportunityTriggerHandler.createTaskOnOpportunityAmountChange(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            OpportunityTriggerHandler.setPriorityOnOppInsertAndUpdate(Trigger.new);
            OpportunityTriggerHandler.closeDateValidationAndProbabilityPrediction(Trigger.new);
            OpportunityTriggerHandler.createTaskOnOpportunityAmountChange(Trigger.new, Trigger.oldMap);
        }
    }
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            OpportunityTriggerHandler.updateTotalWonAmountOnAccount(Trigger.new, Trigger.oldMap);
        }
        if (Trigger.isUpdate) {
            OpportunityTriggerHandler.updateTotalWonAmountOnAccount(Trigger.new, Trigger.oldMap);
        }
    }
}