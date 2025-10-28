public with sharing class AutoCloseCaseQueueable {

    private List<Case> newCases = new List<Case>();
    
    public AutoCloseCaseQueueable(List<Case> newCases) {
        this.newCases = newCases;
    }

    public void execute(QueueableContext qc) {
        List<Case> casesToUpdate = new List<Case>();
        for (Case caseObj : newCases) {
            if (caseObj.Priority == 'High' && caseObj.Status != 'Closed') {
                Date lastModifiedDate = (Date)caseObj.LastModifiedDate;
                Date fiveDaysBeforeDate = Date.today().addDays(-5);
                Integer daysBetween = fiveDaysBeforeDate.daysBetween(lastModifiedDate);
                if (daysBetween > 5) {
                    caseObj.Status = 'Closed';
                    caseObj.Reason = 'No Response from Customer.';
                    casesToUpdate.add(caseObj);
                }
            }
        }
        if (!casesToUpdate.isEmpty()) {
            update casesToUpdate;
        }
    }
}