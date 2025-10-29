public with sharing class LeadAssignmentHelper {
    public class AssignmentResult {
        public Map<Id, Id> leadToOwner = new Map<Id, Id>();
        public Map<Id, String> leadToNotes = new Map<Id, String>();
        public Map<Id, LeadAssignmentSelector.RepDTO> repDeltas = new Map<Id, LeadAssignmentSelector.RepDTO>();
        public Id unassignedQueueId;
    }

    private static final String STATUS_REOPEN = 'Open - Not Contacted';
    private static final String STATUS_UNASSIGNED = 'Unassigned - Needs Review';
    public static final String UNASSIGNED_QUEUE_NAME = 'Unassigned Leads';

    // Static storage to carry rep updates from before to after context
    private static Map<Id, Integer> repIncrementMap = new Map<Id, Integer>();
    private static Map<Id, Datetime> repLastAssignedMap = new Map<Id, Datetime>();

    public static void clearRepDeltas() {
        repIncrementMap.clear();
        repLastAssignedMap.clear();
    }

    public static Map<Id, Integer> getRepIncrementMap() {
        return repIncrementMap;
    }
    public static Map<Id, Datetime> getRepLastAssignedMap() {
        return repLastAssignedMap;
    }

    public static Boolean isQueueId(Id ownerId) {
        if (ownerId == null) return false;
        // Queue Ids are Group Ids with prefix typically '00G'
        return String.valueOf(ownerId).startsWith('00G');
    }

    public static Boolean shouldAutoAssign(Lead newL, Lead oldL) {
        // Only auto-assign:
        // - On insert AND (no owner or owner is the unassigned queue)
        // - On update when status changes from 'Unqualified' to 'Open - Not Contacted' AND (no owner or owner is queue)
        if (Trigger.isInsert) {
            return newL.OwnerId == null || isQueueId(newL.OwnerId);
        }
        if (Trigger.isUpdate && oldL != null) {
            Boolean statusReopen = (oldL.Status == 'Unqualified' && newL.Status == STATUS_REOPEN);
            if (!statusReopen) return false;
            return newL.OwnerId == null || isQueueId(newL.OwnerId);
        }
        return false;
    }

    public static AssignmentResult assignLeads(List<Lead> leads) {
        AssignmentResult res = new AssignmentResult();
        if (leads == null || leads.isEmpty()) return res;

        // Filter target leads
        List<Lead> targets = new List<Lead>();
        for (Lead l : leads) {
            Lead oldL = Trigger.isUpdate ? Trigger.oldMap.get(l.Id) : null;
            if (shouldAutoAssign(l, oldL)) {
                targets.add(l);
            }
        }
        if (targets.isEmpty()) {
            // still cache queue id for any fallback update from outside calls
            res.unassignedQueueId = LeadAssignmentSelector.getQueueIdByName(UNASSIGNED_QUEUE_NAME);
            return res;
        }

        // Collect referenced territories and sources from target leads
        Set<String> territories = new Set<String>();
        for (Lead l : targets) {
            if (!String.isBlank(l.Territory__c)) {
                territories.add(l.Territory__c);
            }
        }

        // Load eligible reps by territory (Is_Active__c = true already applied)
        Map<String, List<LeadAssignmentSelector.RepDTO>> repsByTerritory = LeadAssignmentSelector.getActiveRepsByTerritory(territories);
        // Cache queue id
        res.unassignedQueueId = LeadAssignmentSelector.getQueueIdByName(UNASSIGNED_QUEUE_NAME);

        Datetime nowTs = System.now();

        // Process each lead
        for (Lead l : targets) {
            List<LeadAssignmentSelector.RepDTO> territoryReps = repsByTerritory.get(l.Territory__c);
            LeadAssignmentSelector.RepDTO chosen = findBestMatch(l, territoryReps);

            if (chosen != null) {
                // Assign to user
                res.leadToOwner.put(l.Id, chosen.userId);
                String note = buildAssignmentNotes(chosen, l, true, true);
                res.leadToNotes.put(l.Id, note);

                // Track rep deltas for later update
                Integer inc = repIncrementMap.get(chosen.id);
                repIncrementMap.put(chosen.id, (inc == null ? 1 : inc + 1));
                repLastAssignedMap.put(chosen.id, nowTs);
            } else {
                // Fallback to Queue
                if (res.unassignedQueueId != null) {
                    res.leadToOwner.put(l.Id, res.unassignedQueueId);
                    res.leadToNotes.put(l.Id, 'No eligible rep: inactive or at capacity. Routed to Unassigned Leads.');
                    // Also set status on the record itself; caller will apply
                    l.Status = STATUS_UNASSIGNED;
                }
            }
        }

        return res;
    }

    private static String buildAssignmentNotes(LeadAssignmentSelector.RepDTO rep, Lead l, Boolean territoryMatch, Boolean specialtyConsidered) {
        List<String> parts = new List<String>();
        parts.add('Assigned to UserId ' + rep.userId);
        if (territoryMatch) {
            parts.add('Territory match: ' + l.Territory__c);
        }
        if (!String.isBlank(l.Lead_Source_Category__c) && specialtyConsidered) {
            // Mention specialty if matches
            if (multiselectContains(rep.specialties, l.Lead_Source_Category__c)) {
                parts.add('Specialty: ' + l.Lead_Source_Category__c);
            }
        }
        return String.join(parts, ' - ');
    }

    private static Boolean hasCapacity(LeadAssignmentSelector.RepDTO rep) {
        // Business rule: null/0 capacity = ineligible
        if (rep.maxCapacity == null || rep.maxCapacity == 0) return false;
        Integer current = rep.currentCount == null ? 0 : rep.currentCount;
        return current < rep.maxCapacity;
    }

    private static Boolean multiselectContains(String semiColonDelimited, String candidate) {
        if (String.isBlank(semiColonDelimited) || String.isBlank(candidate)) return false;
        Set<String> tokens = new Set<String>();
        for (String tok : semiColonDelimited.split(';')) {
            if (!String.isBlank(tok)) tokens.add(tok.trim().toLowerCase());
        }
        return tokens.contains(candidate.trim().toLowerCase());
    }

    public static LeadAssignmentSelector.RepDTO findBestMatch(Lead l, List<LeadAssignmentSelector.RepDTO> reps) {
        if (reps == null || reps.isEmpty()) return null;

        // Stage 1: filter active already ensured; enforce capacity
        List<LeadAssignmentSelector.RepDTO> capacityOk = new List<LeadAssignmentSelector.RepDTO>();
        for (LeadAssignmentSelector.RepDTO r : reps) {
            if (r.isActive == true && hasCapacity(r)) {
                capacityOk.add(r);
            }
        }
        if (capacityOk.isEmpty()) return null;

        // Stage 2: specialty+territory (territory already scoped, but keep structure)
        String src = l.Lead_Source_Category__c;
        List<LeadAssignmentSelector.RepDTO> tierA = new List<LeadAssignmentSelector.RepDTO>();
        if (!String.isBlank(src)) {
            for (LeadAssignmentSelector.RepDTO r : capacityOk) {
                if (multiselectContains(r.specialties, src)) {
                    tierA.add(r);
                }
            }
        }

        // Stage 3: territory-only
        List<LeadAssignmentSelector.RepDTO> tierB = new List<LeadAssignmentSelector.RepDTO>();
        if (tierA.isEmpty()) {
            // since all reps are already by territory, tierB == capacityOk
            tierB.addAll(capacityOk);
        }

        List<LeadAssignmentSelector.RepDTO> finalSet = !tierA.isEmpty() ? tierA : tierB;
        if (finalSet.isEmpty()) return null;

        // Round-robin: choose least recently assigned, then lowest current count, then lowest id
        finalSet.sort(new RepComparator());

        return finalSet[0];
    }

    // Dedicated comparator to avoid anonymous inner class parsing issues
    public class RepComparator implements System.Comparator<LeadAssignmentSelector.RepDTO> {
        public Integer compare(LeadAssignmentSelector.RepDTO a, LeadAssignmentSelector.RepDTO b) {
            Datetime la = a.lastAssigned;
            Datetime lb = b.lastAssigned;
            if (la == null && lb != null) return -1;
            if (la != null && lb == null) return 1;
            if (la != null && lb != null) {
                Long ta = la.getTime();
                Long tb = lb.getTime();
                if (ta != tb) return ta < tb ? -1 : 1;
            }
            Integer ca = a.currentCount == null ? 0 : a.currentCount;
            Integer cb = b.currentCount == null ? 0 : b.currentCount;
            if (ca != cb) return ca < cb ? -1 : 1;

            return String.valueOf(a.id).compareTo(String.valueOf(b.id));
        }
    }

    // Apply results to in-flight records in a before trigger
    public static void applyAssignments(List<Lead> leads, AssignmentResult res) {
        if (res == null) return;
        for (Lead l : leads) {
            if (res.leadToOwner.containsKey(l.Id)) {
                l.OwnerId = res.leadToOwner.get(l.Id);
            }
            if (res.leadToNotes.containsKey(l.Id)) {
                l.Assignment_Notes__c = res.leadToNotes.get(l.Id);
            }
        }
    }

    // Commit updates to Sales_Rep_Assignment__c in after trigger using static deltas
    public static void commitRepUpdates() {
        if (repIncrementMap.isEmpty() && repLastAssignedMap.isEmpty()) return;

        List<Sales_Rep_Assignment__c> toUpdate = new List<Sales_Rep_Assignment__c>();
        for (Id repId : repIncrementMap.keySet()) {
            Integer inc = repIncrementMap.get(repId);
            Datetime ts = repLastAssignedMap.get(repId);
            Sales_Rep_Assignment__c row = new Sales_Rep_Assignment__c(
                Id = repId,
                Current_Lead_Count__c = null,
                Last_Assignment_DateTime__c = ts
            );
            toUpdate.add(row);
        }
        // Need current counts to add increments safely; query partial and add
        if (!toUpdate.isEmpty()) {
            Map<Id, Sales_Rep_Assignment__c> fresh = new Map<Id, Sales_Rep_Assignment__c>([
                SELECT Id, Current_Lead_Count__c
                FROM Sales_Rep_Assignment__c
                WHERE Id IN :repIncrementMap.keySet()
            ]);
            for (Sales_Rep_Assignment__c upd : toUpdate) {
                Sales_Rep_Assignment__c cur = fresh.get(upd.Id);
                Integer baseCount = cur.Current_Lead_Count__c == null ? 0 : Integer.valueOf(cur.Current_Lead_Count__c);
                Integer inc = repIncrementMap.get(upd.Id);
                upd.Current_Lead_Count__c = baseCount + (inc == null ? 0 : inc);
            }
            update toUpdate;
        }

        // clear after commit
        clearRepDeltas();
    }
}
