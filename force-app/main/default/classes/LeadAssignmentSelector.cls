public with sharing class LeadAssignmentSelector {
    public class RepDTO {
        public Id id;
        public Id userId;
        public String territory;
        public Boolean isActive;
        public Integer currentCount;
        public Integer maxCapacity;
        public Datetime lastAssigned;
        public String specialties; // Multiselect picklist raw string

        public RepDTO(Sales_Rep_Assignment__c sra) {
            this.id = sra.Id;
            this.userId = sra.User__c;
            this.territory = sra.Territory__c;
            this.isActive = sra.Is_Active__c;
            this.currentCount = (Integer)(sra.Current_Lead_Count__c == null ? 0 : sra.Current_Lead_Count__c.intValue());
            this.maxCapacity = (Integer)(sra.Max_Lead_Capacity__c == null ? 0 : sra.Max_Lead_Capacity__c.intValue());
            this.lastAssigned = sra.Last_Assignment_DateTime__c;
            this.specialties = sra.Lead_Source_Specialty__c;
        }
    }

    private static Map<String, Id> queueNameToId = new Map<String, Id>();

    public static Map<String, List<RepDTO>> getActiveRepsByTerritory(Set<String> territories) {
        Map<String, List<RepDTO>> result = new Map<String, List<RepDTO>>();
        if (territories == null || territories.isEmpty()) {
            return result;
        }
        List<Sales_Rep_Assignment__c> rows = [
            SELECT Id, User__c, Territory__c, Is_Active__c,
                   Current_Lead_Count__c, Max_Lead_Capacity__c, Last_Assignment_DateTime__c,
                   Lead_Source_Specialty__c
            FROM Sales_Rep_Assignment__c
            WHERE Is_Active__c = true
              AND Territory__c IN :territories
        ];
        for (Sales_Rep_Assignment__c sra : rows) {
            RepDTO dto = new RepDTO(sra);
            List<RepDTO> bucket = result.get(dto.territory);
            if (bucket == null) {
                bucket = new List<RepDTO>();
                result.put(dto.territory, bucket);
            }
            bucket.add(dto);
        }
        return result;
    }

    public static Id getQueueIdByName(String queueName) {
        if (String.isBlank(queueName)) return null;
        if (queueNameToId.containsKey(queueName)) {
            return queueNameToId.get(queueName);
        }
        // Group is the SObject for Queues; filter by Type = 'Queue' and Name
        List<Group> gs = [
            SELECT Id, Name, Type
            FROM Group
            WHERE Type = 'Queue' AND Name = :queueName
            LIMIT 1
        ];
        Id qId = (gs.isEmpty() ? null : gs[0].Id);
        queueNameToId.put(queueName, qId);
        return qId;
    }
}
