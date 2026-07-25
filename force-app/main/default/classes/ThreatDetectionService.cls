public class ThreatDetectionService {

    public static List<Threat_Score__c> calculateScores(List<Security_Event__c> events) {
        Set<Id> userIds = new Set<Id>();
        Set<String> eventTypes = new Set<String>();

        for (Security_Event__c evt : events) {
            userIds.add(evt.User__c);
            eventTypes.add(evt.Event_Type__c);
        }

        Map<Id, User> userMap = new Map<Id, User>([
            SELECT Id, Profile.Name, LastLoginDate, UserRole.Name
            FROM User
            WHERE Id IN :userIds
        ]);

        Map<String, Threat_Weight__c> weightMap = new Map<String, Threat_Weight__c>();
        for (Threat_Weight__c tw : [
            SELECT Event_Type__c, Base_Score__c, Multiplier__c
            FROM Threat_Weight__c
            WHERE Event_Type__c IN :eventTypes
        ]) {
            weightMap.put(tw.Event_Type__c, tw);
        }

        List<Threat_Score__c> scores = new List<Threat_Score__c>();
        for (Security_Event__c evt : events) {
            Decimal baseScore = weightMap.containsKey(evt.Event_Type__c)
                ? weightMap.get(evt.Event_Type__c).Base_Score__c
                : 5.0;

            scores.add(new Threat_Score__c(
                Security_Event__c = evt.Id,
                User__c = evt.User__c,
                Score__c = baseScore,
                Calculated_Date__c = System.now()
            ));
        }

        if (!scores.isEmpty()) {
            insert scores;
        }
        return scores;
    }
}
