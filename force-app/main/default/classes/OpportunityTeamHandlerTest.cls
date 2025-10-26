@isTest
public class OpportunityTeamHandlerTest {
    
    @isTest
    static void testCreateOpportunityTeam() {
        // Create test account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        // Create test user
        User testUser = new User(
            Alias = 'testuser',
            Email = 'testuser@example.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Test User',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Standard User'].Id,
            Username = 'testuser@example.com'
        );
        insert testUser;
        
        // Create test opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Amount = 50000,
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        
        insert opp;
        
        // Test the method
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>{opp.Id => opp};
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        OpportunityTeamHandler.createOpportunityTeam(newOppMap, oldOppMap);
        
        // Verify team member was created
        List<OpportunityTeamMember> teamMembers = [SELECT Id FROM OpportunityTeamMember WHERE OpportunityId = :opp.Id];
        System.assert(teamMembers.size() >= 1, 'Should create at least one team member');
    }
}
