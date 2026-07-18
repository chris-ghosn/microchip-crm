trigger LeadAssignmentTrigger on Lead (before insert, before update) {
    for (Lead l : Trigger.new) {
        // Look up assignment rule based on lead source and region
        Lead_Assignment_Rule__c rule = [
            SELECT Id, Assigned_Owner__c, Region__c 
            FROM Lead_Assignment_Rule__c 
            WHERE Region__c = :l.Region__c 
            AND Lead_Source__c = :l.LeadSource
            AND Is_Active__c = true
            LIMIT 1
        ];
        
        if (rule != null) {
            l.OwnerId = rule.Assigned_Owner__c;
        }
        
        // Check for duplicate leads by email
        List<Lead> existingLeads = [
            SELECT Id, Email, Status 
            FROM Lead 
            WHERE Email = :l.Email 
            AND Id != :l.Id
        ];
        
        if (!existingLeads.isEmpty()) {
            l.Duplicate_Lead__c = true;
            l.Duplicate_Lead_Id__c = existingLeads[0].Id;
        }
        
        // Log assignment for audit
        Lead_Assignment_Log__c log = new Lead_Assignment_Log__c(
            Lead__c = l.Id,
            Assigned_To__c = l.OwnerId,
            Assignment_Date__c = System.today(),
            Assignment_Rule__c = rule != null ? rule.Id : null
        );
        insert log;
    }
}
