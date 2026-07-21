trigger LeadAssignmentTrigger on Lead (before insert, before update) {
    // Collect all regions and lead sources for bulk query
    Set<String> regions = new Set<String>();
    Set<String> leadSources = new Set<String>();
    Set<String> emails = new Set<String>();

    for (Lead l : Trigger.new) {
        regions.add(l.Region__c);
        leadSources.add(l.LeadSource);
        emails.add(l.Email);
    }

    // Single query for all assignment rules
    Map<String, Lead_Assignment_Rule__c> ruleMap = new Map<String, Lead_Assignment_Rule__c>();
    for (Lead_Assignment_Rule__c rule : [
        SELECT Id, Assigned_Owner__c, Region__c, Lead_Source__c
        FROM Lead_Assignment_Rule__c
        WHERE Region__c IN :regions
        AND Lead_Source__c IN :leadSources
        AND Is_Active__c = true
    ]) {
        ruleMap.put(rule.Region__c + ':' + rule.Lead_Source__c, rule);
    }

    // Single query for all duplicate checks
    Map<String, Lead> existingLeadMap = new Map<String, Lead>();
    for (Lead existing : [
        SELECT Id, Email, Status
        FROM Lead
        WHERE Email IN :emails
    ]) {
        existingLeadMap.put(existing.Email, existing);
    }

    // Process records and collect audit logs
    List<Lead_Assignment_Log__c> logs = new List<Lead_Assignment_Log__c>();

    for (Lead l : Trigger.new) {
        // Assign owner from rule map
        String key = l.Region__c + ':' + l.LeadSource;
        if (ruleMap.containsKey(key)) {
            l.OwnerId = ruleMap.get(key).Assigned_Owner__c;
        }

        // Check duplicates from pre-queried map
        if (existingLeadMap.containsKey(l.Email) &&
            existingLeadMap.get(l.Email).Id != l.Id) {
            l.Duplicate_Lead__c = true;
            l.Duplicate_Lead_Id__c = existingLeadMap.get(l.Email).Id;
        }

        // Collect audit log (insert after loop)
        logs.add(new Lead_Assignment_Log__c(
            Lead__c = l.Id,
            Assigned_To__c = l.OwnerId,
            Assignment_Date__c = System.today(),
            Assignment_Rule__c = ruleMap.containsKey(key) ? ruleMap.get(key).Id : null
        ));
    }

    // Single bulk DML outside the loop
    if (!logs.isEmpty()) {
        insert logs;
    }
}
