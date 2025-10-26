public with sharing class OpportunityTeamHandler {
    
    // Main entry point method with reduced complexity
    public static void createOpportunityTeam(
        Map<Id, Opportunity> newOpportunityMap, 
        Map<Id, Opportunity> oldOpportunities
    ) {
        // Early exit if no opportunities to process
        if (newOpportunityMap == null || newOpportunityMap.isEmpty()) {
            return;
        }
        
        // Filter opportunities that need processing
        Set<Id> opportunityIds = getOpportunitiesToProcess(newOpportunityMap, oldOpportunities);
        if (opportunityIds.isEmpty()) {
            return;
        }
        
        // Process opportunities to create team members
        processOpportunities(newOpportunityMap, opportunityIds, oldOpportunities);
    }
    
    // Filter opportunities that require team member updates
    private static Set<Id> getOpportunitiesToProcess(
        Map<Id, Opportunity> newOpportunityMap, 
        Map<Id, Opportunity> oldOpportunities
    ) {
        Set<Id> opportunityIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        
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
        
        return opportunityIds;
    }
    
    // Main processing logic for creating team members
    private static void processOpportunities(
        Map<Id, Opportunity> newOpportunityMap, 
        Set<Id> opportunityIds,
        Map<Id, Opportunity> oldOpportunities
    ) {
        // Query Account Owners and their Managers
        Map<Id, Account> accountMap = getAccountMap(opportunityIds);
        if (accountMap.isEmpty()) {
            return;
        }
        
        // Get CEO user
        User ceo = getCeoUser();
        
        // Query existing team members
        Map<String, OpportunityTeamMember> existingTeamMembers = getExistingTeamMembers(opportunityIds);
        
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
            
            // Determine team members based on opportunity criteria
            addAppropriateTeamMembers(
                teamMembersToInsert, 
                existingTeamMembers, 
                opp, 
                relatedAccount, 
                ceo
            );
        }
        
        // Insert new team members with CRUD validation
        if (!teamMembersToInsert.isEmpty()) {
            insertTeamMembersWithCRUDValidation(teamMembersToInsert);
        }
    }
    
    // Get account map with owner and manager info
    private static Map<Id, Account> getAccountMap(Set<Id> opportunityIds) {
        Set<Id> accountIds = new Set<Id>();
        for (Opportunity opp : [SELECT AccountId FROM Opportunity WHERE Id IN :opportunityIds]) {
            if (opp.AccountId != null) {
                accountIds.add(opp.AccountId);
            }
        }
        
        return new Map<Id, Account>([
            SELECT Id, OwnerId, Owner.ManagerId 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
    }
    
    // Get CEO user with proper error handling
    private static User getCeoUser() {
        try {
            return [
                SELECT Id 
                FROM User 
                WHERE Name = 'Bharat Kumar' 
                AND IsActive = true 
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug('CEO user not found: ' + e.getMessage());
            return null;
        }
    }
    
    // Get existing team members for the opportunities
    private static Map<String, OpportunityTeamMember> getExistingTeamMembers(Set<Id> opportunityIds) {
        Map<String, OpportunityTeamMember> existingTeamMembers = new Map<String, OpportunityTeamMember>();
        for (OpportunityTeamMember member : [
            SELECT Id, OpportunityId, UserId, TeamMemberRole
            FROM OpportunityTeamMember 
            WHERE OpportunityId IN :opportunityIds
        ]) {
            String key = member.OpportunityId + '-' + member.UserId + '-' + member.TeamMemberRole;
            existingTeamMembers.put(key, member);
        }
        return existingTeamMembers;
    }
    
    // Add appropriate team members based on opportunity stage and amount
    private static void addAppropriateTeamMembers(
        List<OpportunityTeamMember> teamMembersList,
        Map<String, OpportunityTeamMember> existingMembers,
        Opportunity opp,
        Account relatedAccount,
        User ceo
    ) {
        Id accountOwnerId = relatedAccount.OwnerId;
        Id managerUserId = relatedAccount.Owner.ManagerId;
        
        // Rule 1: Prospecting or Qualification
        if (opp.StageName == 'Prospecting' || opp.StageName == 'Qualification') {
            addTeamMember(
                teamMembersList, 
                existingMembers, 
                opp.Id, 
                accountOwnerId, 
                'Sales Rep', 
                'Read'
            );
        }
        
        // Rule 2: Proposal/Price Quote or Negotiation/Review
        else if (opp.StageName == 'Proposal/Price Quote' || opp.StageName == 'Negotiation/Review') {
            addTeamMember(
                teamMembersList, 
                existingMembers, 
                opp.Id, 
                accountOwnerId, 
                'Sales Rep', 
                'Read'
            );
            
            if (managerUserId != null) {
                addTeamMember(
                    teamMembersList, 
                    existingMembers, 
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
                teamMembersList, 
                existingMembers, 
                opp.Id, 
                accountOwnerId, 
                'Sales Rep', 
                'Read'
            );
            
            if (managerUserId != null) {
                addTeamMember(
                    teamMembersList, 
                    existingMembers, 
                    opp.Id, 
                    managerUserId, 
                    'Sales Manager', 
                    'Read'
                );
            }
            
            if (ceo != null) {
                addTeamMember(
                    teamMembersList, 
                    existingMembers, 
                    opp.Id, 
                    ceo.Id, 
                    'Executive Sponsor', 
                    'Read'
                );
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
    
    // Helper method to insert team members with CRUD validation and proper error handling
    private static void insertTeamMembersWithCRUDValidation(List<OpportunityTeamMember> teamMembersToInsert) {
        try {
            // Check CRUD permissions before DML operation
            if (Schema.sObjectType.OpportunityTeamMember.isCreateable()) {
                insert teamMembersToInsert;
            } else {
                System.debug('CRUD permission denied for OpportunityTeamMember insert');
            }
        } catch (DmlException e) {
            System.debug('Error inserting team members: ' + e.getMessage());
        }
    }
}
