public class AccountTerritoryAssignment {
    
    public static void assignTerritories(List<Account> accounts) {
        Map<String, Territory__c> territoryMap = getTerritoryMap();
        
        List<Account> toUpdate = new List<Account>();
        for (Account acc : accounts) {
            String key = acc.BillingCountry + '-' + acc.Industry;
            if (territoryMap.containsKey(key)) {
                acc.Territory__c = territoryMap.get(key).Id;
                acc.Territory_Owner__c = territoryMap.get(key).Owner__c;
                toUpdate.add(acc);
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    
    private static Map<String, Territory__c> getTerritoryMap() {
        Map<String, Territory__c> tMap = new Map<String, Territory__c>();
        List<Territory__c> territories = [
            SELECT Id, Region__c, Country__c, Industry__c, Owner__c
            FROM Territory__c
            WHERE Is_Active__c = true
        ];
        
        for (Territory__c t : territories) {
            String key = t.Country__c + '-' + t.Industry__c;
            tMap.put(key, t);
        }
        
        return tMap;
    }
}
