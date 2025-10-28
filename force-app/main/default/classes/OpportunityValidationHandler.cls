public with sharing class OpportunityValidationHandler {
    
    public static void closeDateValidationAndProbabilityPrediction(List<Opportunity> newOpportunities) {
        Date today = Date.today();
        Map<String, Integer> stageProbabilityMap = new Map<String, Integer>{
            'Prospecting' => 10,
            'Negotiation/Review' => 75
        };

        for (Opportunity opp : newOpportunities) {
            validateCloseDate(today, opp);
            updateProbabilityFromStage(stageProbabilityMap, opp);
        }
    }
    
    private static void validateCloseDate(Date today, Opportunity opp) {
        if (opp.CloseDate < today) {
            opp.CloseDate.addError('Date cannot be in the past.');
        }
    }
    
    private static void updateProbabilityFromStage(Map<String, Integer> stageProbabilityMap, Opportunity opp) {
        if (String.isNotBlank(opp.StageName) && stageProbabilityMap.containsKey(opp.StageName)) {
            opp.Probability = stageProbabilityMap.get(opp.StageName);
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
                updateOpportunityProbability(opp, oldOpportunitiesMap, stageProbabilityMap);
            }
        }
        
        private static void updateOpportunityProbability(Opportunity opp, Map<Id, Opportunity> oldOpportunitiesMap, Map<String, Integer> stageProbabilityMap) {
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