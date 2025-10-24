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
                    if (oldOpportunities.get(opp.Id).Amount == opp.Amount) continue;
                }
                Task newTask = new Task();
                newTask.Subject = 'Follow up on High Value Opportunity';
                newTask.ActivityDate = Date.today().addDays(7);
                newTask.Status = 'Not Started';
                newTask.WhatId = opp.Id;
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
            if (opportunity.AccountId != null) {
                accountIds.add(opportunity.AccountId);
            }
        }

        if (accountIds.isEmpty()) return;

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Name, Total_Won_Revenue__c, Last_Deal_Closed_Date__c  
            FROM Account 
            WHERE Id IN :accountIds
        ]);

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

        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        
        for (Opportunity opp : opportunities) {
            Account relatedAccount = accountMap.get(opp.AccountId);
            if (relatedAccount == null) continue;

            Decimal amount = opp.Amount != null ? opp.Amount : 0;
            
            if (oldOpportunityMap != null) {
                Opportunity oldOpp = oldOpportunityMap.get(opp.Id);
                if (opp.StageName != oldOpp.StageName) {
                    if (opp.StageName == 'Closed Won') {
                        relatedAccount.Total_Won_Revenue__c = (relatedAccount.Total_Won_Revenue__c != null ? relatedAccount.Total_Won_Revenue__c : 0) + amount;
                        accountsToUpdate.put(relatedAccount.Id, relatedAccount);
                    }
                    else if (oldOpp.StageName == 'Closed Won' && opp.StageName != 'Closed Won') {
                        relatedAccount.Total_Won_Revenue__c = (relatedAccount.Total_Won_Revenue__c != null ? relatedAccount.Total_Won_Revenue__c : 0) - amount;
                        accountsToUpdate.put(relatedAccount.Id, relatedAccount);
                    }
                }
            }
            else {
                if (opp.StageName == 'Closed Won') {
                    relatedAccount.Total_Won_Revenue__c = (relatedAccount.Total_Won_Revenue__c != null ? relatedAccount.Total_Won_Revenue__c : 0) + amount;
                    accountsToUpdate.put(relatedAccount.Id, relatedAccount);
                }
            }

            if (accountIdToLatestDate.containsKey(opp.AccountId)) {
                Date latestDate = accountIdToLatestDate.get(opp.AccountId);
                if (relatedAccount.Last_Deal_Closed_Date__c != latestDate) {
                    relatedAccount.Last_Deal_Closed_Date__c = latestDate;
                    accountsToUpdate.put(relatedAccount.Id, relatedAccount);
                }
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
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
            if (oldOpportunitiesMap != null && oldOpportunitiesMap.containsKey(opp.Id)) {
                Opportunity oldOpp = oldOpportunitiesMap.get(opp.Id);
                if (opp.StageName != oldOpp.StageName && stageProbabilityMap.containsKey(opp.StageName)) {
                    opp.Probability = stageProbabilityMap.get(opp.StageName);
                }
            } else if (stageProbabilityMap.containsKey(opp.StageName)) {
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

        if (accountIds.isEmpty()) return;

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

        if (!accountsToUpdate.isEmpty()) {
            update accountsToUpdate.values();
        }
    }

    public static void createTaskForClosedLostOpportunity(
        Map<Id, Opportunity> newOpportunitiesMap, Map<Id, Opportunity> oldOpportunitiesMap) {
        
        List<Task> tasksToInsert = new List<Task>();

        List<AggregateResult> results = [
            SELECT COUNT(Id) totalTasks, WhatId 
            FROM Task 
            WHERE WhatId IN :newOpportunitiesMap.keySet() 
            GROUP BY WhatId
        ];

        Set<Id> opportunitiesWithTask = new Set<Id>();
        for (AggregateResult ar : results) {
            Id whatId = (Id)ar.get('WhatId');
            if (whatId != null) {
                opportunitiesWithTask.add(whatId);
            }
        }

        for (Opportunity newOpp : newOpportunitiesMap.values()) {
            if (!opportunitiesWithTask.contains(newOpp.Id)) {
                Opportunity oldOpp = oldOpportunitiesMap.get(newOpp.Id);
                if (oldOpp != null && newOpp.StageName == 'Closed Lost' && newOpp.StageName != oldOpp.StageName) {
                    Task taskObj = new Task();
                    taskObj.Subject = 'Follow up with lost deal';
                    taskObj.WhatId = newOpp.Id;
                    taskObj.OwnerId = newOpp.OwnerId;
                    taskObj.ActivityDate = Date.today().addDays(7);
                    taskObj.Status = 'Not Started';
                    tasksToInsert.add(taskObj);
                }
            }
        }

        if (!tasksToInsert.isEmpty()) {
            insert tasksToInsert;
        }
    }

    public static void createContractOnOpportunityClose(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOppMap) {
        Map<Id, Opportunity> validOpportunitiesMap = new Map<Id, Opportunity>();
        List<Contract> contractsToInsert = new List<Contract>();
        List<Asset> assetsToInsert = new List<Asset>();

        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOppMap?.get(opp.Id);
            if (oldOpp != null && opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName) {
                validOpportunitiesMap.put(opp.Id, opp);

                Contract contract = new Contract();
                contract.AccountId = opp.AccountId;
                contract.Status = 'Draft';
                contract.ContractTerm = 12;
                contract.StartDate = opp.CloseDate;
                contractsToInsert.add(contract);
            }
        }

        if (validOpportunitiesMap.isEmpty()) return;

        List<OpportunityLineItem> oppLineItems = [
            SELECT Id, OpportunityId, Product2Id, Quantity, UnitPrice, TotalPrice, ServiceDate, Description, Name 
            FROM OpportunityLineItem
            WHERE OpportunityId IN :validOpportunitiesMap.keySet()
        ];

        if (!oppLineItems.isEmpty()) {
            for (OpportunityLineItem oli : oppLineItems) {
                Opportunity opportunity = validOpportunitiesMap.get(oli.OpportunityId);
                Asset assetObj = new Asset();
                assetObj.AccountId = opportunity.AccountId;
                assetObj.Product2Id = oli.Product2Id;
                assetObj.Quantity = oli.Quantity;
                assetObj.Status = 'In Approval Process';
                assetObj.PurchaseDate = oli.ServiceDate;
                assetObj.OwnerId = opportunity.OwnerId;
                assetObj.Name = oli.Name;
                assetsToInsert.add(assetObj);
            }
        }

        if (!contractsToInsert.isEmpty()) {
            insert contractsToInsert;
        }

        if(!assetsToInsert.isEmpty()) {
            insert assetsToInsert;
        }
    }

    public static void createOpportunityTeam(
        Map<Id, Opportunity> newOpportunityMap, 
        Map<Id, Opportunity> oldOpportunities
    ) {
        
        // Collect Account IDs that need processing
        Set<Id> accountIds = new Set<Id>();
        Set<Id> opportunityIds = new Set<Id>();
        
        for (Opportunity opp : newOpportunityMap.values()) {
            // Skip if no stage or amount change
            if (oldOpportunities != null && oldOpportunities.containsKey(opp.Id)) {
                Opportunity oldOpp = oldOpportunities.get(opp.Id);
                if (opp.StageName == oldOpp.StageName && opp.Amount == oldOpp.Amount) {
                    continue;
                }
            }
            
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
                opportunityIds.add(opp.Id);
            }
        }
        
        if (accountIds.isEmpty()) {
            return;
        }
        
        // Query Account Owners and their Managers
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, OwnerId, Owner.ManagerId 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        // Get CEO user
        User ceo = null;
        try {
            ceo = [
                SELECT Id 
                FROM User 
                WHERE Name = 'Bharat Kumar' 
                AND IsActive = true 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('CEO user not found: ' + e.getMessage());
        }
        
        // Query existing team members
        Map<String, OpportunityTeamMember> existingTeamMembers = new Map<String, OpportunityTeamMember>();
        for (OpportunityTeamMember member : [
            SELECT Id, OpportunityId, UserId, TeamMemberRole
            FROM OpportunityTeamMember 
            WHERE OpportunityId IN :opportunityIds
        ]) {
            String key = member.OpportunityId + '-' + member.UserId + '-' + member.TeamMemberRole;
            existingTeamMembers.put(key, member);
        }
        
        // Prepare team members to insert
        List<OpportunityTeamMember> teamMembersToInsert = new List<OpportunityTeamMember>();
        
        // Process each opportunity
        for (Opportunity opp : newOpportunityMap.values()) {
            if (!opportunityIds.contains(opp.Id)) {
                continue;
            }
            
            Account relatedAccount = accountMap.get(opp.AccountId);
            if (relatedAccount == null) {
                continue;
            }
            
            Id accountOwnerId = relatedAccount.OwnerId;
            Id managerUserId = relatedAccount.Owner.ManagerId;
            
            // Rule 1: Prospecting or Qualification
            if (opp.StageName == 'Prospecting' || opp.StageName == 'Qualification') {
                addTeamMember(
                    teamMembersToInsert, 
                    existingTeamMembers, 
                    opp.Id, 
                    accountOwnerId, 
                    'Sales Rep', 
                    'Read'
                );
            }
            
            // Rule 2: Proposal/Price Quote or Negotiation/Review
            else if (opp.StageName == 'Proposal/Price Quote' || opp.StageName == 'Negotiation/Review') {
                addTeamMember(
                    teamMembersToInsert, 
                    existingTeamMembers, 
                    opp.Id, 
                    accountOwnerId, 
                    'Sales Rep', 
                    'Read'
                );
                
                if (managerUserId != null) {
                    addTeamMember(
                        teamMembersToInsert, 
                        existingTeamMembers, 
                        opp.Id, 
                        managerUserId, 
                        'Sales Manager', 
                        'Read'
                    );
                }
            }
            
            // Rule 3: Closed Won with Amount >= $100,000
            else if (opp.StageName == 'Closed Won' && opp.Amount != null && opp.Amount >= 100000) {
                addTeamMember(
                    teamMembersToInsert, 
                    existingTeamMembers, 
                    opp.Id, 
                    accountOwnerId, 
                    'Sales Rep', 
                    'Read'
                );
                
                if (managerUserId != null) {
                    addTeamMember(
                        teamMembersToInsert, 
                        existingTeamMembers, 
                        opp.Id, 
                        managerUserId, 
                        'Sales Manager', 
                        'Read'
                    );
                }
                
                if (ceo != null) {
                    addTeamMember(
                        teamMembersToInsert, 
                        existingTeamMembers, 
                        opp.Id, 
                        ceo.Id, 
                        'Executive Sponsor', 
                        'Read'
                    );
                }
            }
        }
        
        // Insert new team members
        if (!teamMembersToInsert.isEmpty()) {
            try {
                insert teamMembersToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting team members: ' + e.getMessage());
            }
        }
    }
    
    // Helper method for creating opportunity team members
    private static void addTeamMember(
        List<OpportunityTeamMember> teamMembersList,
        Map<String, OpportunityTeamMember> existingMembers,
        Id opportunityId,
        Id userId,
        String role,
        String accessLevel
    ) {
        if (userId == null) {
            return;
        }
        
        String key = opportunityId + '-' + userId + '-' + role;
        if (!existingMembers.containsKey(key)) {
            teamMembersList.add(new OpportunityTeamMember(
                OpportunityId = opportunityId,
                UserId = userId,
                TeamMemberRole = role,
                OpportunityAccessLevel = accessLevel
            ));
            existingMembers.put(key, new OpportunityTeamMember());
        }
    }
}