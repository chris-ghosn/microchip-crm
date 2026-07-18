public class OpportunityForecastService {
    
    public static Map<String, Decimal> getRegionalForecast(String fiscalQuarter) {
        Map<String, Decimal> forecast = new Map<String, Decimal>();
        
        List<AggregateResult> results = [
            SELECT Owner.Region__c region, SUM(Amount) totalAmount
            FROM Opportunity
            WHERE FiscalQuarter = :fiscalQuarter
            AND StageName NOT IN ('Closed Lost', 'Closed Won')
            GROUP BY Owner.Region__c
        ];
        
        for (AggregateResult ar : results) {
            String region = (String) ar.get('region');
            Decimal amount = (Decimal) ar.get('totalAmount');
            forecast.put(region, amount);
        }
        
        return forecast;
    }
    
    public static void updateForecastSnapshot() {
        String currentQuarter = getCurrentFiscalQuarter();
        Map<String, Decimal> forecast = getRegionalForecast(currentQuarter);
        
        List<Forecast_Snapshot__c> snapshots = new List<Forecast_Snapshot__c>();
        for (String region : forecast.keySet()) {
            snapshots.add(new Forecast_Snapshot__c(
                Region__c = region,
                Quarter__c = currentQuarter,
                Amount__c = forecast.get(region),
                Snapshot_Date__c = Date.today()
            ));
        }
        
        insert snapshots;
    }
    
    private static String getCurrentFiscalQuarter() {
        Integer month = Date.today().month();
        Integer year = Date.today().year();
        String quarter = 'Q' + String.valueOf(((month - 1) / 3) + 1);
        return year + '-' + quarter;
    }
}
