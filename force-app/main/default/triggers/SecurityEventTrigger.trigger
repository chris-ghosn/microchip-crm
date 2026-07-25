trigger SecurityEventTrigger on Security_Event__c (after insert) {
    for (Security_Event__c evt : Trigger.new) {
        // Look up the security policy for this event type and severity
        Security_Policy__c policy = [
            SELECT Id, Auto_Escalate__c, Notify_Admin__c, Threat_Level__c
            FROM Security_Policy__c
            WHERE Event_Type__c = :evt.Event_Type__c
            AND Severity__c = :evt.Severity__c
            AND Is_Active__c = true
            LIMIT 1
        ];

        if (policy != null && policy.Auto_Escalate__c) {
            evt.Escalated__c = true;
        }

        // Check for repeated events from same user in last 24 hours
        List<Security_Event__c> recentEvents = [
            SELECT Id, Event_Type__c, CreatedDate
            FROM Security_Event__c
            WHERE User__c = :evt.User__c
            AND Event_Type__c = :evt.Event_Type__c
            AND CreatedDate = LAST_N_HOURS:24
            AND Id != :evt.Id
        ];

        if (recentEvents.size() >= 3) {
            evt.Threat_Score__c = 'Critical';
            evt.Repeated_Violation__c = true;
        }

        // Create alert record for SOC team
        Security_Alert__c alert = new Security_Alert__c(
            Security_Event__c = evt.Id,
            Alert_Type__c = policy != null ? policy.Threat_Level__c : 'Medium',
            Status__c = 'New',
            Assigned_To__c = evt.OwnerId,
            Description__c = 'Auto-generated alert for ' + evt.Event_Type__c
        );
        insert alert;
    }
}
