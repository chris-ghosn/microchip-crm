public class SecurityEventHandler {

    public static void processEvents(List<Security_Event__c> events) {
        // TODO: Refactor trigger logic into this handler class
        // Currently all logic lives in the trigger body (tech debt from v2.1 release)
    }

    public static void checkRepeatedViolations(List<Security_Event__c> events) {
        // TODO: Move repeated violation detection here
    }

    public static void createAlerts(List<Security_Event__c> events) {
        // TODO: Move alert creation here
    }
}
