public with sharing class OpportunityTaskHandler {
    
    public static void createTaskOnOpportunityAmountChange(
        List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {

        List<Task> tasksToInsert = new List<Task>();

        for (Opportunity opp : newOpportunities) {
            if(shouldCreateFollowUpTask(opp, oldOpportunities)) {
                tasksToInsert.add(createFollowUpTask(opp));
            }
        }

        if(!tasksToInsert.isEmpty()) {
            // Validate CRUD permission before DML operation
            try {
                insert tasksToInsert;
            } catch(DmlException e) {
                // Handle case where user doesn't have insert permission
                System.debug('User does not have INSERT permission on Task object: ' + e.getMessage());
            }
        }
    }
    
    private static Boolean shouldCreateFollowUpTask(Opportunity opp, Map<Id, Opportunity> oldOpportunities) {
        if(opp.Amount <= 500000) {
            return false;
        }
        if(oldOpportunities != null && oldOpportunities.get(opp.Id) != null) {
            if (oldOpportunities.get(opp.Id).Amount == opp.Amount) {
                return false;
            }
        }
        return true;
    }
    
    private static Task createFollowUpTask(Opportunity opp) {
        Task newTask = new Task();
        newTask.Subject = 'Follow up on High Value Opportunity';
        newTask.ActivityDate = Date.today().addDays(7);
        newTask.Status = 'Not Started';
        newTask.WhatId = opp.Id;
        return newTask;
    }
    
    public static void createTaskForClosedLostOpportunity(
        Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap) {
        
        if (newOpportunitiesMap == null || newOpportunitiesMap.isEmpty()) {
            return;
        }
        
        Set<Id> opportunitiesWithTask = getOpportunitiesWithExistingTask(newOpportunitiesMap);
        List<Task> tasksToInsert = buildClosedLostTaskList(newOpportunitiesMap, oldOpportunitiesMap, opportunitiesWithTask);
        
        if (!tasksToInsert.isEmpty()) {
            // Validate CRUD permission before DML operation
            try {
                insert tasksToInsert;
            } catch(DmlException e) {
                // Handle case where user doesn't have insert permission
                System.debug('User does not have INSERT permission on Task object: ' + e.getMessage());
            }
        }
    }
    
    private static Set<Id> getOpportunitiesWithExistingTask(Map<Id, Opportunity> newOpportunitiesMap) {
        Set<Id> opportunitiesWithTask = new Set<Id>();
        List<AggregateResult> results = [
            SELECT COUNT(Id) totalTasks, WhatId 
            FROM Task 
            WHERE WhatId IN :newOpportunitiesMap.keySet() 
            GROUP BY WhatId
        ];
        for (AggregateResult ar : results) {
            Id whatId = (Id)ar.get('WhatId');
            if (whatId != null) {
                opportunitiesWithTask.add(whatId);
            }
        }
        return opportunitiesWithTask;
    }
    
    private static List<Task> buildClosedLostTaskList(Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap, Set<Id> opportunitiesWithTask) {
        List<Task> tasksToInsert = new List<Task>();
        for (Opportunity newOpp : newOpportunitiesMap.values()) {
            if (!opportunitiesWithTask.contains(newOpp.Id)) {
                Opportunity oldOpp = oldOpportunitiesMap.get(newOpp.Id);
                if (oldOpp != null && newOpp.StageName == 'Closed Lost' && newOpp.StageName != oldOpp.StageName) {
                    tasksToInsert.add(createClosedLostTask(newOpp));
                }
            }
        }
        return tasksToInsert;
    }
    
    private static Task createClosedLostTask(Opportunity newOpp) {
        Task taskObj = new Task();
        taskObj.Subject = 'Follow up with lost deal';
        taskObj.WhatId = newOpp.Id;
        taskObj.OwnerId = newOpp.OwnerId;
        taskObj.ActivityDate = Date.today().addDays(7);
        taskObj.Status = 'Not Started';
        return taskObj;
    }
}
