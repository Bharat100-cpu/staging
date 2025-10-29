public with sharing class LeadAssignmentBatchReset implements Database.Batchable<Sales_Rep_Assignment__c> {
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, Current_Lead_Count__c
            FROM Sales_Rep_Assignment__c
            WHERE Current_Lead_Count__c > 0
        ]);
    }

    public void execute(Database.BatchableContext bc, List<Sales_Rep_Assignment__c> scope) {
        List<Sales_Rep_Assignment__c> toUpdate = new List<Sales_Rep_Assignment__c>();
        for (Sales_Rep_Assignment__c sra : scope) {
            sra.Current_Lead_Count__c = 0;
            toUpdate.add(sra);
        }
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Optional: logging or notifications
    }
}
