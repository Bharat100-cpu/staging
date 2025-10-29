public with sharing class LeadAssignmentSchedule implements Schedulable {
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new LeadAssignmentBatchReset(), 200);
    }
}
