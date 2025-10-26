public with sharing class OpportunityContractHandler {
    
    public static void createContractOnOpportunityClose(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOppMap) {
        if (newOpportunities == null || newOpportunities.isEmpty()) {
            return;
        }
        
        Map<Id, Opportunity> validOpportunitiesMap = collectValidOpportunities(newOpportunities, oldOppMap);
        if (validOpportunitiesMap.isEmpty()) {
            return;
        }
        
        List<Contract> contractsToInsert = createContracts(validOpportunitiesMap);
        List<Asset> assetsToInsert = createAssets(validOpportunitiesMap, oldOppMap);
        
        insertContracts(contractsToInsert);
        insertAssets(assetsToInsert);
    }
    
    private static Map<Id, Opportunity> collectValidOpportunities(List<Opportunity> newOpportunities, Map<Id, Opportunity> oldOppMap) {
        Map<Id, Opportunity> validOpportunitiesMap = new Map<Id, Opportunity>();
        for (Opportunity opp : newOpportunities) {
            Opportunity oldOpp = oldOppMap?.get(opp.Id);
            if (oldOpp != null && opp.StageName == 'Closed Won' && opp.StageName != oldOpp.StageName) {
                validOpportunitiesMap.put(opp.Id, opp);
            }
        }
        return validOpportunitiesMap;
    }
    
    private static List<Contract> createContracts(Map<Id, Opportunity> validOpportunitiesMap) {
        List<Contract> contractsToInsert = new List<Contract>();
        for (Opportunity opp : validOpportunitiesMap.values()) {
            Contract contract = new Contract();
            contract.AccountId = opp.AccountId;
            contract.Status = 'Draft';
            contract.ContractTerm = 12;
            contract.StartDate = opp.CloseDate;
            contractsToInsert.add(contract);
        }
        return contractsToInsert;
    }
    
    private static List<Asset> createAssets(Map<Id, Opportunity> validOpportunitiesMap, Map<Id, Opportunity> oldOppMap) {
        List<Asset> assetsToInsert = new List<Asset>();
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
        return assetsToInsert;
    }
    
    private static void insertContracts(List<Contract> contractsToInsert) {
        if (!contractsToInsert.isEmpty()) {
            try {
                insert contractsToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting contracts: ' + e.getMessage());
            }
        }
    }
    
    private static void insertAssets(List<Asset> assetsToInsert) {
        if(!assetsToInsert.isEmpty()) {
            try {
                insert assetsToInsert;
            } catch (DmlException e) {
                System.debug('Error inserting assets: ' + e.getMessage());
            }
        }
    }
}
