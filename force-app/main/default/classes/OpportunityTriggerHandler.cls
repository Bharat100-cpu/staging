public with sharing class OpportunityTriggerHandler {
    public static void setPriorityOnOppInsertAndUpdate(List<Opportunity> newOpportunities) {
        OpportunityPriorityHandler.setPriorityOnOppInsertAndUpdate(newOpportunities);
    }
    
    public static void createTaskOnOpportunityAmountChange(
        List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {
        OpportunityTaskHandler.createTaskOnOpportunityAmountChange(newOpportunities, oldOpportunities);
    }
    
    public static void closeDateValidationAndProbabilityPrediction(List<Opportunity> newOpportunities) {
        OpportunityValidationHandler.closeDateValidationAndProbabilityPrediction(newOpportunities);
    }
    
    public static void updateProbability(
            List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        OpportunityValidationHandler.updateProbability(opportunities, oldOpportunitiesMap);
    }
    
    public static void updateTotalWonAmountOnAccount(List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunityMap) {
        OpportunityAccountHandler.updateTotalWonAmountOnAccount(opportunities, oldOpportunityMap);
    }
    
    public static void updateTotalOppCountOnAccount(List<Opportunity> newOpportunities) {
        OpportunityAccountHandler.updateTotalOppCountOnAccount(newOpportunities);
    }
    
    public static void createTaskForClosedLostOpportunity(
        Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap) {
        OpportunityTaskHandler.createTaskForClosedLostOpportunity(newOpportunitiesMap, oldOpportunitiesMap);
    }
    
    public static void createContractOnOpportunityClose(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOppMap) {
        OpportunityContractHandler.createContractOnOpportunityClose(newOpportunities, oldOppMap);
    }
    
    public static void createOpportunityTeam(
        Map<Id, Opportunity> newOpportunityMap, 
        Map<Id, Opportunity> oldOpportunities) {
        OpportunityTeamHandler.createOpportunityTeam(newOpportunityMap, oldOpportunities);
    }
    
    public static void handleStageBasedTasks(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        OpportunityStageTaskHandler.handleStageChanges(newOpportunities, oldOpportunitiesMap);
    }
}
