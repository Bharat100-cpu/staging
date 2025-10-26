public with sharing class InvoiceTriggerHandler {
    
    public static void updateStatus(List<Invoice__c> newInvoices) {

        Date today = Date.today();
        for (Invoice__c invoice : newInvoices) {
            if (invoice.Status__c == 'Paid') {
                invoice.Overdue__c = false;
            }
            else if (invoice.Status__c == 'Cancelled') {
                invoice.Amount__c = 0;
            }
            if (invoice.Due_Date__c != null && today > invoice.Due_Date__c 
                && invoice.Status__c != 'Paid') {
                invoice.Overdue__c = true;
            }
        }
    }
}
