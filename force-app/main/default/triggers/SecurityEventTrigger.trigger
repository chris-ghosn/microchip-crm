trigger SecurityEventTrigger on Security_Event__c (after insert) {
    // Collect event types, severities, and user IDs for bulk queries
    Set<String> eventTypes = new Set<String>();
    Set<String> severities = new Set<String>();
    Set<Id> userIds = new Set<Id>();

    for (Security_Event__c evt : Trigger.new) {
        eventTypes.add(evt.Event_Type__c);
        severities.add(evt.Severity__c);
        userIds.add(evt.User__c);
    }

    // Single query for all matching security policies
    Map<String, Security_Policy__c> policyMap = new Map<String, Security_Policy__c>();
    for (Security_Policy__c policy : [
        SELECT Id, Auto_Escalate__c, Notify_Admin__c, Threat_Level__c,
               Event_Type__c, Severity__c
        FROM Security_Policy__c
        WHERE Event_Type__c IN :eventTypes
        AND Severity__c IN :severities
        AND Is_Active__c = true
    ]) {
        policyMap.put(policy.Event_Type__c + ':' + policy.Severity__c, policy);
    }

    // Single query for recent events by all users in batch
    Map<String, Integer> recentEventCounts = new Map<String, Integer>();
    for (AggregateResult ar : [
        SELECT User__c, Event_Type__c, COUNT(Id) cnt
        FROM Security_Event__c
        WHERE User__c IN :userIds
        AND Event_Type__c IN :eventTypes
        AND CreatedDate = LAST_N_HOURS:24
        AND Id NOT IN :Trigger.newMap.keySet()
        GROUP BY User__c, Event_Type__c
    ]) {
        String key = (String)ar.get('User__c') + ':' + (String)ar.get('Event_Type__c');
        recentEventCounts.put(key, (Integer)ar.get('cnt'));
    }

    // Process records and collect alerts for bulk insert
    List<Security_Event__c> eventsToUpdate = new List<Security_Event__c>();
    List<Security_Alert__c> alerts = new List<Security_Alert__c>();

    for (Security_Event__c evt : Trigger.new) {
        String policyKey = evt.Event_Type__c + ':' + evt.Severity__c;
        Security_Policy__c policy = policyMap.get(policyKey);

        Security_Event__c evtUpdate = new Security_Event__c(Id = evt.Id);
        Boolean needsUpdate = false;

        if (policy != null && policy.Auto_Escalate__c) {
            evtUpdate.Escalated__c = true;
            needsUpdate = true;
        }

        // Check repeated violations from pre-queried aggregate
        String countKey = evt.User__c + ':' + evt.Event_Type__c;
        Integer recentCount = recentEventCounts.containsKey(countKey)
            ? recentEventCounts.get(countKey) : 0;

        if (recentCount >= 3) {
            evtUpdate.Threat_Score__c = 'Critical';
            evtUpdate.Repeated_Violation__c = true;
            needsUpdate = true;
        }

        if (needsUpdate) {
            eventsToUpdate.add(evtUpdate);
        }

        // Collect alert for bulk insert
        alerts.add(new Security_Alert__c(
            Security_Event__c = evt.Id,
            Alert_Type__c = policy != null ? policy.Threat_Level__c : 'Medium',
            Status__c = 'New',
            Assigned_To__c = evt.OwnerId,
            Description__c = 'Auto-generated alert for ' + evt.Event_Type__c
        ));
    }

    // Bulk DML outside the loop
    if (!eventsToUpdate.isEmpty()) {
        update eventsToUpdate;
    }
    if (!alerts.isEmpty()) {
        insert alerts;
    }
}
