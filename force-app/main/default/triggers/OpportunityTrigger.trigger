trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update, after delete, after undelete) {

    if(Trigger.isBefore) {
        if(Trigger.isInsert) {
            OpportunityTriggerHandler.updateProbability(Trigger.new, Trigger.oldMap);
            OpportunityTriggerHandler.setPriorityOnOppInsertAndUpdate(Trigger.new);
            OpportunityTriggerHandler.closeDateValidationAndProbabilityPrediction(Trigger.new);
            OpportunityTriggerHandler.createTaskOnOpportunityAmountChange(Trigger.new, Trigger.oldMap);
        }
        if(Trigger.isUpdate) {
            OpportunityTriggerHandler.updateProbability(Trigger.new, Trigger.oldMap);
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