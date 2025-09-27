public with sharing class OpportunityTriggerHandler {
    
    public static void setPriorityOnOppInsertAndUpdate(List<Opportunity> newOpportunities) {

        for (Opportunity opp : newOpportunities) {
            if(opp.Amount > 100000) {
                opp.Priority__c = 'High';
            }
            else if (opp.Amount > 50000 && opp.Amount <= 100000) {
                opp.Priority__c = 'Medium';
            }
            else if (opp.Amount <= 50000) {
                opp.Priority__c = 'Low';
            }
        }
    }
}