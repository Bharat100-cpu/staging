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

    public static void updateContacts(List<Task> newTasks, Map<Id, Task> oldTasks) {

        Map<Id, Contact> contactsMap = new Map<Id, Contact>();

        if (newTasks != null) {
            for (Task task : newTasks) {
                if (task.Status == 'Completed' && task.WhoId != null) {
                    String whoId = task.WhoId;
                    if(whoId.startsWith('003')) {
                        Contact contact = new Contact();
                        if (!contactsMap.containsKey(whoId)) {
                            contact.Id = whoId;
                        } else {
                            contact = contactsMap.get(whoId);
                        }
                        contact.Last_Activity_Date__c = task.ActivityDate;
                        contact.Days_Since_Last_Activity__c = Date.today().daysBetween(contact.Last_Activity_Date__c);
                        contactsMap.put(contact.Id, contact);
                    }        
                }
            }
        } else {
            Set<Id> contactIds = new Set<Id>();
            for (Task task : oldTasks.values()) {
                if (task.WhoId != null) {
                    String whoId = task.WhoId;
                    if (whoId.startsWith('003')) {
                        contactIds.add(whoId);
                    }
                }
            }

            if (contactIds.isEmpty()) {
                return;
            }

            List<Contact> contactWithRecentTask = [
                SELECT Id, Last_Activity_Date__c, Days_Since_Last_Activity__c,
                    (SELECT Id, ActivityDate, Status, Who.Type 
                    FROM Tasks 
                    WHERE Status = 'Completed' AND Who.Type = 'Contact'
                    ORDER BY ActivityDate DESC 
                    LIMIT 1)
                FROM Contact
                WHERE Id IN : contactIds
            ];

            if (contactWithRecentTask != null) {
                for (Contact contact : contactWithRecentTask) {
                    if (!contact.Tasks.isEmpty()) {
                        List<Task> task = contact.Tasks;
                        contact.Last_Activity_Date__c = task[0].ActivityDate;
                        contact.Days_Since_Last_Activity__c = Date.today().daysBetween(contact.Last_Activity_Date__c);
                    } else {
                        contact.Last_Activity_Date__c = null;
                        contact.Days_Since_Last_Activity__c = null;
                    }
                    contactsMap.put(contact.Id, contact);
                }
            }
        }

        if (!contactsMap.isEmpty() && contactsMap.values() != null) {
            update contactsMap.values();
        }
    }
}