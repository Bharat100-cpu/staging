@isTest
public class OpportunityContractHandlerTest {
    
    @isTest
    static void testCreateContractOnOpportunityClose() {
        // Create test account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        // Create test opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Won',
            Amount = 50000,
            CloseDate = Date.today(),
            AccountId = acc.Id
        );
        
        insert opp;
        
        // Test the method
        List<Opportunity> newOpps = new List<Opportunity>{opp};
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        
        OpportunityContractHandler.createContractOnOpportunityClose(newOpps, oldOppMap);
        
        // Verify contract was created
        List<Contract> contracts = [SELECT Id FROM Contract WHERE AccountId = :acc.Id];
        System.assertEquals(1, contracts.size(), 'Should create one contract for closed won opportunity');
    }
}
