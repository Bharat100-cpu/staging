public with sharing class AccountTaskCreator {
    
    public static void insertTask(List<Account> accounts) {
        List<Task> tasksToInsert = new List<Task>();
        for (Account account : accounts) {
            Task task = new Task();
            task.Subject = 'Welcome Call';
            task.Status = 'Not Started';
            task.Priority = 'High';
            task.ActivityDate = Date.today().addDays(3);
            task.WhatId = account.Id;
            task.OwnerId = account.OwnerId;
            tasksToInsert.add(task);
        }

        if (!tasksToInsert.isEmpty()) {
            // Validate CRUD permission before DML operation
            if (Schema.sObjectType.Task.isCreateable()) {
                insert tasksToInsert;
            } else {
                // Handle the case where user doesn't have create permission
                System.debug('User does not have create permission for Task object');
                // Optionally throw an exception or handle gracefully
                // For now, just log and continue
                System.debug('Skipping task creation due to insufficient permissions');
            }
        }
    }
}
