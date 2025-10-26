@isTest
public class OpportunityAccountHandlerTest {
    
    @isTest
    static void testUpdateTotalWonAmountOnAccount() {
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
        List<Opportunity> opportunities = new List<Opportunity>{opp};
        Map<Id, Opportunity> oldOpportunityMap = new Map<Id, Opportunity>();
        
        OpportunityAccountHandler.updateTotalWonAmountOnAccount(opportunities, oldOpportunityMap);
        
        // Verify account was updated
        Account updatedAcc = [SELECT Id, Total_Won_Revenue__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(50000, updatedAcc.Total_Won_Revenue__c, 'Account total won revenue should be updated');
    }
    
    @isTest
    static void testUpdateTotalOppCountOnAccount() {
        // Create test account
        Account acc = new Account(
            Name = 'Test Account'
        );
        insert acc;
        
        // Create test opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        for(Integer i = 0; i < 3; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                StageName = 'Prospecting',
                Amount = 50000,
                CloseDate = Date.today(),
                AccountId = acc.Id
            );
            opportunities.add(opp);
        }
        insert opportunities;
        
        // Test the method
        OpportunityAccountHandler.updateTotalOppCountOnAccount(opportunities);
        
        // Verify account was updated
        Account updatedAcc = [SELECT Id, Total_Opportunities__c FROM Account WHERE Id = :acc.Id];
        System.assertEquals(3, updatedAcc.Total_Opportunities__c, 'Account total opportunities should be updated');
    }
}
