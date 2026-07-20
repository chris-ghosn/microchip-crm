trigger LeadAssignmentTrigger on Lead (before insert, before update) {

    // Collect all region/source combos and emails up front — no SOQL in the loop
    Set<String> regions = new Set<String>();
    Set<String> sources = new Set<String>();
    Set<String> emails  = new Set<String>();

    for (Lead l : Trigger.new) {
        if (l.Region__c    != null) regions.add(l.Region__c);
        if (l.LeadSource   != null) sources.add(l.LeadSource);
        if (l.Email        != null) emails.add(l.Email);
    }

    // Single query for all matching assignment rules
    Map<String, Lead_Assignment_Rule__c> ruleMap = new Map<String, Lead_Assignment_Rule__c>();
    for (Lead_Assignment_Rule__c rule : [
        SELECT Id, Assigned_Owner__c, Region__c, Lead_Source__c
        FROM   Lead_Assignment_Rule__c
        WHERE  Region__c      IN :regions
        AND    Lead_Source__c IN :sources
        AND    Is_Active__c   = true
    ]) {
        String key = rule.Region__c + '|' + rule.Lead_Source__c;
        if (!ruleMap.containsKey(key)) {
            ruleMap.put(key, rule);
        }
    }

    // Single query for all potential duplicate leads
    Map<String, Id> duplicateEmailMap = new Map<String, Id>();
    for (Lead existing : [
        SELECT Id, Email
        FROM   Lead
        WHERE  Email IN :emails
        AND    Id    NOT IN :Trigger.newMap.keySet()
    ]) {
        if (!duplicateEmailMap.containsKey(existing.Email)) {
            duplicateEmailMap.put(existing.Email, existing.Id);
        }
    }

    // Process each lead — zero SOQL inside this loop
    List<Lead_Assignment_Log__c> logs = new List<Lead_Assignment_Log__c>();

    for (Lead l : Trigger.new) {
        String ruleKey = l.Region__c + '|' + l.LeadSource;
        Lead_Assignment_Rule__c rule = ruleMap.get(ruleKey);

        if (rule != null) {
            l.OwnerId = rule.Assigned_Owner__c;
        }

        if (l.Email != null && duplicateEmailMap.containsKey(l.Email)) {
            l.Duplicate_Lead__c    = true;
            l.Duplicate_Lead_Id__c = duplicateEmailMap.get(l.Email);
        }

        // Log is queued for bulk insert — Id is null on before insert, set after
        logs.add(new Lead_Assignment_Log__c(
            Assigned_To__c    = l.OwnerId,
            Assignment_Date__c = System.today(),
            Assignment_Rule__c = rule != null ? rule.Id : null
        ));
    }

    // Single DML outside the loop
    if (!logs.isEmpty()) {
        insert logs;
    }
}