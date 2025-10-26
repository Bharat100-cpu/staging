public with sharing class OpportunityAccountHandler {
    
    public static void updateTotalWonAmountOnAccount(List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunityMap) {
        if (opportunities == null || opportunities.isEmpty()) {
            return;
        }
        
        Set<Id> accountIds = collectAccountIds(opportunities);
        if (accountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Account> accountMap = queryAccounts(accountIds);
        Map<Id, Date> accountIdToLatestDate = queryLatestClosedWonDates(accountIds);
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        
        for (Opportunity opp : opportunities) {
            Account relatedAccount = accountMap.get(opp.AccountId);
            if (relatedAccount == null) continue;
            
            updateAccountRevenue(relatedAccount, opp, oldOpportunityMap);
            updateAccountLastDealDate(relatedAccount, opp, accountIdToLatestDate, accountsToUpdate);
        }

        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate.values();
            } catch (DmlException e) {
                System.debug('Error updating accounts: ' + e.getMessage());
            }
        }
    }
    
    private static Set<Id> collectAccountIds(List<Opportunity> opportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opportunity : opportunities) {
            if (opportunity.AccountId != null) {
                accountIds.add(opportunity.AccountId);
            }
        }
        return accountIds;
    }
    
    private static Map<Id, Account> queryAccounts(Set<Id> accountIds) {
        return new Map<Id, Account>([
            SELECT Id, Name, Total_Won_Revenue__c, Last_Deal_Closed_Date__c  
            FROM Account 
            WHERE Id IN :accountIds
        ]);
    }
    
    private static Map<Id, Date> queryLatestClosedWonDates(Set<Id> accountIds) {
        List<AggregateResult> latestDates = [
            SELECT AccountId, MAX(CloseDate) latestDate
            FROM Opportunity
            WHERE StageName = 'Closed Won' AND AccountId IN :accountIds
            GROUP BY AccountId
        ];
        
        Map<Id, Date> accountIdToLatestDate = new Map<Id, Date>();
        for (AggregateResult ar : latestDates) {
            accountIdToLatestDate.put((Id)ar.get('AccountId'), (Date)ar.get('latestDate'));
        }
        return accountIdToLatestDate;
    }
    
    private static void updateAccountRevenue(Account relatedAccount, Opportunity opp, Map<Id, Opportunity> oldOpportunityMap) {
        Decimal amount = opp.Amount != null ? opp.Amount : 0;
        if (oldOpportunityMap != null) {
            Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
            if (oldOpp != null && opp.StageName != oldOpp.StageName) {
                if (opp.StageName == 'Closed Won') {
                    try {
                        relatedAccount.Total_Won_Revenue__c = (relatedAccount.Total_Won_Revenue__c != null ? relatedAccount.Total_Won_Revenue__c : 0) + amount;
                    } catch (DmlException e) {
                        System.debug('Error updating account revenue: ' + e.getMessage());
                    }
                }
                else if (oldOpp.StageName == 'Closed Won' && opp.StageName != 'Closed Won') {
                    try {
                        relatedAccount.Total_Won_Revenue__c = (relatedAccount.Total_Won_Revenue__c != null ? relatedAccount.Total_Won_Revenue__c : 0) - amount;
                    } catch (DmlException e) {
                        System.debug('Error updating account revenue: ' + e.getMessage());
                    }
                }
            }
        }
        else {
            if (opp.StageName == 'Closed Won') {
                try {
                    relatedAccount.Total_Won_Revenue__c = (relatedAccount.Total_Won_Revenue__c != null ? relatedAccount.Total_Won_Revenue__c : 0) + amount;
                } catch (DmlException e) {
                    System.debug('Error updating account revenue: ' + e.getMessage());
                }
            }
        }
    }
    
    private static void updateAccountLastDealDate(Account relatedAccount, Opportunity opp, Map<Id, Date> accountIdToLatestDate, Map<Id, Account> accountsToUpdate) {
        if (accountIdToLatestDate.containsKey(opp.AccountId)) {
            Date latestDate = accountIdToLatestDate.get(opp.AccountId);
            if (relatedAccount.Last_Deal_Closed_Date__c != latestDate) {
                relatedAccount.Last_Deal_Closed_Date__c = latestDate;
                accountsToUpdate.put(relatedAccount.Id, relatedAccount);
            }
        }
    }
    
    public static void updateTotalOppCountOnAccount(List<Opportunity> newOpportunities) {
        if (newOpportunities == null || newOpportunities.isEmpty()) {
            return;
        }
        
        Set<Id> accountIds = collectAccountIdsForOppCount(newOpportunities);
        if (accountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Account> accountsToUpdate = buildAccountUpdateMap(accountIds);
        
        if (!accountsToUpdate.isEmpty()) {
            try {
                update accountsToUpdate.values();
            } catch (DmlException e) {
                System.debug('Error updating accounts: ' + e.getMessage());
            }
        }
    }
    
    private static Set<Id> collectAccountIdsForOppCount(List<Opportunity> newOpportunities) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        return accountIds;
    }
    
    private static Map<Id, Account> buildAccountUpdateMap(Set<Id> accountIds) {
        List<AggregateResult> result = [
            SELECT COUNT(Id) opportunities, AccountId 
            FROM Opportunity 
            WHERE AccountId IN :accountIds 
            GROUP BY AccountId
        ];

        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        for (AggregateResult ar : result) {
            Id accountId = (Id)ar.get('AccountId');
            Integer oppCount = (Integer)ar.get('opportunities');
            
            accountsToUpdate.put(accountId, new Account(
                Id = accountId,
                Total_Opportunities__c = oppCount
            ));
        }
        return accountsToUpdate;
    }
}
