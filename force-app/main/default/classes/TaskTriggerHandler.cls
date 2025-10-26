public with sharing class TaskTriggerHandler {
    
    public static void updateContactLastInterationDate(List<Task> newTasks, Map<Id, Task> oldTaskMap) {

        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        for (Task taskObj : newTasks) {
            if (oldTaskMap.containsKey(taskObj.Id)) {
                Task oldTask = oldTaskMap.get(taskObj.Id);
                Id currentRecordId = taskObj.WhoId;
                String objectName = currentRecordId.getSObjectType().getDescribe().getName();
                if (taskObj.Status != oldTask.Status 
                && taskObj.Status == 'Completed' 
                && taskObj.WhoId != null
                && objectName == 'Contact') {
                    Contact con = new Contact();
                    con.Id = taskObj.WhoId;
                    con.Last_Interaction_Date__c = taskObj.ActivityDate;
                    Contact existingContact = contactsToUpdate.get(con.Id);
                    if (existingContact == null || existingContact.Last_Interaction_Date__c < taskObj.ActivityDate) {
                        contactsToUpdate.put(con.Id, con);
                    }
                }
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            update contactsToUpdate.values();
        }
    }
}
