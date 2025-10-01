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

    public static void createTaskOnOpportunityAmountChange(
        List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {

        List<Task> tasksToInsert = new List<Task>();

        for (Opportunity opp : newOpportunities) {
            if(opp.Amount > 500000) {
                if(oldOpportunities != null && oldOpportunities.get(opp.Id) != null) {
                    if (oldOpportunities.get(opp.Id).Amount == opp.Amount) return;
                }
                Task newTask = new Task();
                newTask.Subject = 'Follow up on High Value Opportunity';
                newTask.ActivityDate = Date.today().addDays(7);
                newTask.Status = 'Not Started';
                tasksToInsert.add(newTask);
            }
        }

        if(!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}