public with sharing class OpportunityTriggerHandler {
    
    public static void setPriorityOnOppInsertAndUpdate(List<Opportunity> newOpportunities) {

        for (Opportunity opp : newOpportunities) {
            if(opp.Amount > 100000) {
                opp.Priority__c = 'High';
            }
            else if (opp.Amount > 50000 && opp.Amount <= 100000) {
                opp.Priority__c = 'Medium';
            }
            else if (opp.Amount <= 50000) {
                opp.Priority__c = 'Low';
            }
        }
    }

    public static void createTaskOnOpportunityAmountChange(
        List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOpportunities) {

        List<Task> tasksToInsert = new List<Task>();

        for (Opportunity opp : newOpportunities) {
            if(opp.Amount > 500000) {
                if(oldOpportunities != null && oldOpportunities.get(opp.Id) != null) {
                    if (oldOpportunities.get(opp.Id).Amount == opp.Amount) return;
                }
                Task newTask = new Task();
                newTask.Subject = 'Follow up on High Value Opportunity';
                newTask.ActivityDate = Date.today().addDays(7);
                newTask.Status = 'Not Started';
                tasksToInsert.add(newTask);
            }
        }

        if(!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    public static void closeDateValidationAndProbabilityPrediction(List<Opportunity> newOpportunities) {

        Date today = Date.today();
        Map<String, Integer> stageProbabilityMap = new Map<String, Integer>{
            'Prospecting' => 10,
            'Negotiation/Review' => 75
        };

        for (Opportunity opp : newOpportunities) {
            if (opp.CloseDate < today) {
                opp.CloseDate.addError('Date cannot be in the past.');
            }

            if (String.isNotBlank(opp.StageName) && stageProbabilityMap.containsKey(opp.StageName)) {
                opp.Probability = stageProbabilityMap.get(opp.StageName);
            }
        }
    }
    
    public static void updateTotalWonAmountOnAccount(List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunityMap) {
        
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opportunity : opportunities) {
            accountIds.add(opportunity.AccountId);
        }

        Map<Id, Account> accountMap = new Map<Id, Account>();
        if (!accountIds.isEmpty()) {
            List<Account> accounts = [
                SELECT Id, Name, Total_Won_Revenue__c, Last_Deal_Closed_Date__c  
                FROM Account 
                WHERE Id IN : accountIds
            ];
            for (Account account : accounts) {
                if (!accountMap.containsKey(account.Id)) {
                    accountMap.put(account.Id, account);
                }
            }
        }

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

        List<Opportunity> aggregatedOpportunities = [
            SELECT Id, Name, CloseDate, AccountId
            FROM Opportunity
            WHERE StageName = 'Closed Won'
            AND AccountId IN :accountIdToLatestDate.keySet()
            AND CloseDate IN :accountIdToLatestDate.values()
        ];

        Map<Id, Opportunity> aggregatedOppMap = new Map<Id, Opportunity>();
        for (Opportunity opportunity : aggregatedOpportunities) {
            if (!aggregatedOppMap.containsKey(opportunity.Id)) {
                aggregatedOppMap.put(opportunity.Id, opportunity);
            }
        }

        List<Account> accountsToUpdate = new List<Account>();
        Map<Id, List<Opportunity>> accountWithOpportunities = new Map<Id, List<Opportunity>>();
        if (!accountMap.isEmpty()) {
            for (Opportunity opp : opportunities) {
                Account relatedAccount = accountMap.get(opp.AccountId);
                Decimal amount = opp.Amount != null ? opp.Amount : 0;
                if (oldOpportunityMap != null) {
                    Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
                    if (opp.StageName != oldOpp.StageName) {
                        if (opp.StageName == 'Closed Won') {
                            relatedAccount.Total_Won_Revenue__c += amount;
                            accountsToUpdate.add(relatedAccount);
                        }
                        else if (oldOpp.StageName == 'Closed Won' && opp.StageName != 'Closed Won') {
                            relatedAccount.Total_Won_Revenue__c -= amount;
                            accountsToUpdate.add(relatedAccount);
                        }
                    }
                }
                else {
                    if (opp.StageName == 'Closed Won') {
                        relatedAccount.Total_Won_Revenue__c += amount;
                        accountsToUpdate.add(relatedAccount);
                    }
                }

                if (relatedAccount.Last_Deal_Closed_Date__c != opp.CloseDate) {
                    relatedAccount.Last_Deal_Closed_Date__c = opp.CloseDate;
                }
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }

    public static void updateProbability(
        List<Opportunity> opportunities, Map<Id, Opportunity> oldOpportunitiesMap) {

        Map<String, Integer> stageProbabilityMap = new Map<String, Integer>{
            'Prospecting' => 10,
            'Qualification' => 25,
            'Proposal/Price Quote' => 50,
            'Negotiation/Review' => 75,
            'Closed Won' => 100,
            'Closed Lost' => 0
        };

        for (Opportunity opp : opportunities) {
            if (oldOpportunitiesMap != null) {
                if (oldOpportunitiesMap.containsKey(opp.Id)) {
                    Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
                    if (opp.StageName != oldOpp.StageName) {
                        opp.Probability = stageProbabilityMap.get(opp.StageName);
                    }
                }
            } else {
                opp.Probability = stageProbabilityMap.get(opp.StageName);
            }
        }
    }

    public static void updateTotalOppCountOnAccount(List<Opportunity> newOpportunities) {

        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : newOpportunities) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }

        List<AggregateResult> result = [
            SELECT COUNT(Id) opportunities, AccountId 
            FROM Opportunity 
            WHERE AccountId IN : accountIds 
            GROUP BY AccountId
        ];

        List<Account> accountsToUpdate = new List<Account>();
        for (AggregateResult ar : result) {
            Account acc = new Account();
            acc.Id = (String)ar.get('AccountId');
            acc.Total_Opportunities__c = (Integer)ar.get('opportunities');
            accountsToUpdate.add(acc);
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate;
        }
    }
}