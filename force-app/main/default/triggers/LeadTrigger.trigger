trigger LeadTrigger on Lead (before insert, before update, after insert, after update) {
    if (Trigger.isBefore) {
        // Assign in before context so OwnerId/Notes are set prior to DML
        LeadAssignmentHelper.AssignmentResult res = LeadAssignmentHelper.assignLeads(Trigger.new);
        LeadAssignmentHelper.applyAssignments(Trigger.new, res);
    }
    if (Trigger.isAfter) {
        // Commit Sales_Rep_Assignment__c counter updates once per transaction
        if (Trigger.isInsert || Trigger.isUpdate) {
            LeadAssignmentHelper.commitRepUpdates();
        }
    }
}
