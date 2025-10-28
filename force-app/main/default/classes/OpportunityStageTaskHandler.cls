public with sharing class OpportunityStageTaskHandler {
    private static final String LAST_STAGE_TASK_CREATED_FIELD = 'Last_Stage_Task_Created__c';
    public static void handleStageChanges(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunitiesMap) {
        if (newOpportunities == null || newOpportunities.isEmpty()) {
            return;
        }
        List<Task> tasksToCreate = new List<Task>();
        List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOpportunitiesMap != null ? oldOpportunitiesMap.get(opp.Id) : null;
            if (oldOpp == null || oldOpp.StageName == null || oldOpp.StageName == opp.StageName) {
                continue;
            }
            if (shouldCreateTasksForStageChange(opp, oldOpp)) {
                tasksToCreate.addAll(createTasksForStageChange(opp, oldOpp));
                if (shouldCreateTasksForStage(opp.StageName)) {
                    Opportunity oppToUpdate = new Opportunity(Id = opp.Id);
                    oppToUpdate.Last_Stage_Task_Created__c = opp.StageName;
                    opportunitiesToUpdate.add(oppToUpdate);
                }
            }
        }
        if (!tasksToCreate.isEmpty()) {
            try {
                insert tasksToCreate;
            } catch (DmlException e) {
                System.debug('Error creating tasks: ' + e.getMessage());
            }
        }
        if (!opportunitiesToUpdate.isEmpty()) {
            try {
                update opportunitiesToUpdate;
            } catch (DmlException e) {
                System.debug('Error updating Last_Stage_Task_Created__c field: ' + e.getMessage());
            }
        }
    }
    private static Boolean shouldCreateTasksForStageChange(Opportunity opp, Opportunity oldOpp) {
        String lastStageCreated = (String)opp.get(LAST_STAGE_TASK_CREATED_FIELD);
        if (lastStageCreated == null || lastStageCreated == '') {
            return shouldCreateTasksForStage(opp.StageName);
        }
        if (lastStageCreated == opp.StageName) {
            return false;
        }
        return shouldCreateTasksForStage(opp.StageName);
    }
    private static Boolean shouldCreateTasksForStage(String stageName) {
        return stageName != null && (
            stageName.equals('Needs Analysis') ||
            stageName.equals('Proposal/Price Quote') ||
            stageName.equals('Negotiation/Review') ||
            stageName.equals('Closed Won')
        );
    }
    private static List<Task> createTasksForStageChange(Opportunity opp, Opportunity oldOpp) {
        List<Task> tasks = new List<Task>();
        if (opp.StageName == 'Needs Analysis') {
            tasks.add(createNeedsAnalysisTask(opp));
        } else if (opp.StageName == 'Proposal/Price Quote') {
            tasks.add(createProposalTask(opp));
        } else if (opp.StageName == 'Negotiation/Review') {
            tasks.addAll(createNegotiationTasks(opp));
        } else if (opp.StageName == 'Closed Won') {
            tasks.add(createClosedWonTask(opp));
        }
        return tasks;
    }
    private static Task createNeedsAnalysisTask(Opportunity opp) {
        Task task = new Task();
        task.Subject = 'Complete Needs Analysis Document';
        task.Priority = 'Normal';
        task.Status = 'Not Started';
        task.ActivityDate = Date.today().addDays(5);
        task.OwnerId = opp.OwnerId;
        task.WhatId = opp.Id;
        return task;
    }
    private static Task createProposalTask(Opportunity opp) {
        Task task = new Task();
        task.Subject = 'Send Proposal to Customer';
        task.Priority = 'High';
        task.Status = 'Not Started';
        task.ActivityDate = Date.today().addDays(3);
        task.OwnerId = opp.OwnerId;
        task.WhatId = opp.Id;
        return task;
    }
    private static List<Task> createNegotiationTasks(Opportunity opp) {
        List<Task> tasks = new List<Task>();
        Task task1 = new Task();
        task1.Subject = 'Review contract terms with customer';
        task1.Priority = 'High';
        task1.ActivityDate = Date.today().addDays(2);
        task1.OwnerId = opp.OwnerId;
        task1.WhatId = opp.Id;
        tasks.add(task1);
        User owner = [SELECT Id, ManagerId FROM User WHERE Id = :opp.OwnerId LIMIT 1];
        if (owner.ManagerId != null) {
            Task task2 = new Task();
            task2.Subject = 'Approve discount requests for ' + opp.Name;
            task2.Priority = 'High';
            task2.ActivityDate = Date.today().addDays(2);
            task2.OwnerId = owner.ManagerId;
            task2.WhatId = opp.Id;
            tasks.add(task2);
        }
        return tasks;
    }
    private static Task createClosedWonTask(Opportunity opp) {
        Task task = new Task();
        task.Subject = 'Schedule onboarding call for ' + opp.Account.Name;
        task.Priority = 'High';
        task.ActivityDate = Date.today().addDays(1);
        task.OwnerId = opp.Account.OwnerId;
        task.WhatId = opp.Id;
        return task;
    }
}
