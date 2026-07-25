public class ComplianceAuditController {

    public static List<Compliance_Report__c> runAudit(String auditType, Date startDate, Date endDate) {
        List<Security_Event__c> events = [
            SELECT Id, Event_Type__c, User__c, Severity__c, CreatedDate,
                   Threat_Score__c, Escalated__c, Repeated_Violation__c
            FROM Security_Event__c
            WHERE CreatedDate >= :startDate
            AND CreatedDate <= :endDate
            AND Event_Type__c = :auditType
            ORDER BY CreatedDate DESC
        ];

        Map<Id, Integer> violationsByUser = new Map<Id, Integer>();
        for (Security_Event__c evt : events) {
            Integer count = violationsByUser.containsKey(evt.User__c)
                ? violationsByUser.get(evt.User__c) + 1
                : 1;
            violationsByUser.put(evt.User__c, count);
        }

        List<Compliance_Report__c> reports = new List<Compliance_Report__c>();
        for (Id userId : violationsByUser.keySet()) {
            reports.add(new Compliance_Report__c(
                User__c = userId,
                Audit_Type__c = auditType,
                Violation_Count__c = violationsByUser.get(userId),
                Period_Start__c = startDate,
                Period_End__c = endDate,
                Generated_Date__c = System.now()
            ));
        }

        if (!reports.isEmpty()) {
            insert reports;
        }
        return reports;
    }
}
