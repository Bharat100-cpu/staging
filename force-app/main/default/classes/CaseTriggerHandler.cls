public with sharing class CaseTriggerHandler {
    
    public static void createFollowUpTask(List<Case> cases) {

        List<Task> tasksToInsert = new List<Task>();
        for (Case caseObj : cases) {
            Task task = new Task();
            task.Subject = 'Follow up on new case: ' + caseObj.CaseNumber;
            task.Status = 'Not Started';
            if (caseObj.Priority != null) {
                task.Priority = caseObj.Priority;
            }
            task.OwnerId = caseObj.OwnerId;
            task.WhatId = caseObj.Id;
            tasksToInsert.add(task);
        }

        if(!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }
}