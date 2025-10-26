@isTest
public class OpportunityTaskHandlerTest {
    
    @isTest
    static void testCreateTaskOnOpportunityAmountChange() {
        // Create test opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            Amount = 600000,
            CloseDate = Date.today(),
            AccountId = Test.data.createAccount().Id
        );
        
        insert opp;
        
        // Test the method
        List<Opportunity> newOpps = new List<Opportunity>{opp};
        Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>();
        
        OpportunityTaskHandler.createTaskOnOpportunityAmountChange(newOpps, oldOpps);
        
        // Verify task was created
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task for high value opportunity');
    }
    
    @isTest
    static void testCreateTaskForClosedLostOpportunity() {
        // Create test opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Closed Lost',
            Amount = 50000,
            CloseDate = Date.today(),
            AccountId = Test.data.createAccount().Id
        );
        
        insert opp;
        
        // Test the method
        Map<Id, Opportunity> newOpps = new Map<Id, Opportunity>{opp.Id => opp};
        Map<Id, Opportunity> oldOpps = new Map<Id, Opportunity>();
        
        OpportunityTaskHandler.createTaskForClosedLostOpportunity(newOpps, oldOpps);
        
        // Verify task was created
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :opp.Id];
        System.assertEquals(1, tasks.size(), 'Should create one task for closed lost opportunity');
    }
}
