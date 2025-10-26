public with sharing class OpportunityPriorityHandler {
    
    public static void setPriorityOnOppInsertAndUpdate(List<Opportunity> newOpportunities) {
        for (Opportunity opp : newOpportunities) {
            opp.Priority__c = getPriorityForOpportunity(opp.Amount);
        }
    }
    
    private static String getPriorityForOpportunity(Decimal amount) {
        if(amount > 100000) {
            return 'High';
        }
        else if (amount > 50000 && amount <= 100000) {
            return 'Medium';
        }
        else {
            return 'Low';
        }
    }
}
