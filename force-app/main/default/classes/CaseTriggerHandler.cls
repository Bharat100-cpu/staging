public with sharing class CaseTriggerHandler {
    
    public static void createFollowUpTask(List<Case> cases) {
        // Check object-level CRUD: user must have create access on Task
        if (!Schema.sObjectType.Task.isCreateable()) {
            // No permission to create Task records, safely exit
            return;
        }

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

        if (!tasksToInsert.isEmpty()) {
            // Enforce field-level security before DML
            SObjectAccessDecision accessDecision = Security.stripInaccessible(
                AccessType.CREATABLE,
                tasksToInsert
            );
            List<Task> insertableTasks = (List<Task>) accessDecision.getRecords();

            if (!insertableTasks.isEmpty()) {
                insert insertableTasks;
            }
        }
    }
}
