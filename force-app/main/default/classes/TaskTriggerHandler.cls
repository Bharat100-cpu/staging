public with sharing class TaskTriggerHandler {
    
    public static void updateContactLastInterationDate(List<Task> newTasks, Map<Id, Task> oldTaskMap) {

        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();

        for (Task taskObj : newTasks) {
            if (oldTaskMap.containsKey(taskObj.Id)) {
                Task oldTask = oldTaskMap.get(taskObj.Id);
                Id currentRecordId = taskObj.WhoId;
                String ObjectName = currentRecordId.getSObjectType().getDescribe().getName();
                System.debug('status : ' + taskObj.Status);
                System.debug('old status ' + oldTask.Status);
                System.debug('who id : ' + taskObj.Id);
                System.debug('who : ' + taskObj.Who);
                if (taskObj.Status != oldTask.Status 
                && taskObj.Status == 'Completed' 
                && taskObj.WhoId != null
                && ObjectName == 'Contact') {
                    Contact con = new Contact();
                    con.Id = taskObj.WhoId;
                    con.Last_Interaction_Date__c = taskObj.ActivityDate;
                    if (contactsToUpdate.containsKey(con.Id)) {
                        Contact existingContact = contactsToUpdate.get(con.Id);
                        if (existingContact.Last_Interaction_Date__c < taskObj.ActivityDate) {
                            contactsToUpdate.put(con.Id, con);
                        }
                    } else {
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