global with sharing class FundController {

    public class PagedResult {

        @AuraEnabled
        public Integer pageSize { get;set; }

        @AuraEnabled
        public Integer page { get;set; }

        @AuraEnabled
        public Integer pages { get;set; }

        @AuraEnabled
        public Integer total { get;set; }

        @AuraEnabled
        public List<Fund__c> funds { get;set; }

    }

    public class Filter {

        @AuraEnabled
        public String searchKey { get;set; }

        @AuraEnabled
        public String assetClass { get;set; }

        @AuraEnabled
        public String sector { get;set; }

        @AuraEnabled
        public Decimal minYtdReturn { get;set; }

        @AuraEnabled
        public Decimal maxYtdReturn { get;set; }

        @AuraEnabled
        public Decimal min1YearReturn { get;set; }

        @AuraEnabled
        public Decimal max1YearReturn { get;set; }

        @AuraEnabled
        public Decimal min5YearReturn { get;set; }

        @AuraEnabled
        public Decimal max5YearReturn { get;set; }
    }

    @AuraEnabled(cacheable=true)
    public static PagedResult getFunds(String filters, Decimal pageSize, Decimal pageNumber) {
        System.debug(filters);
        Filter filter = (Filter) JSON.deserializeStrict(filters, FundController.Filter.class);
        System.debug(filter);
        Integer pSize = (Integer)pageSize;
        String key = '%' + filter.searchKey + '%';
        Integer offset = ((Integer)pageNumber - 1) * pSize;
        PagedResult r =  new PagedResult();
        r.pageSize = pSize;
        r.page = (Integer) pageNumber;
        System.debug(filter.minYtdReturn);
        String assetClass = filter.assetClass;
        String sector = filter.sector;
        Decimal minYtdReturn = filter.minYtdReturn;
        Decimal min1YearReturn = filter.min1YearReturn;
        Decimal min5YearReturn = filter.min5YearReturn;
        Decimal maxYtdReturn = filter.maxYtdReturn;
        Decimal max1YearReturn = filter.max1YearReturn;
        Decimal max5YearReturn = filter.max5YearReturn;

        String countSQL = 'SELECT count() FROM Fund__c where name LIKE :key ' +
            'AND YTD_Return__c >= :minYtdReturn AND YTD_Return__c <= :maxYtdReturn ' +
            'AND One_Year_Return__c >= :min1YearReturn AND One_Year_Return__c <= :max1YearReturn ' +
            'AND Five_Year_Return__c >= :min5YearReturn AND Five_Year_Return__c <= :max5YearReturn ';
        if (!String.isBlank(filter.assetClass)) {
            countSQL = countSQL + 'AND Asset_Class__c = :assetClass ';
        }
        if (!String.isBlank(filter.sector)) {
            countSQL = countSQL + 'AND Sector__c = :sector ';
        }
        r.total = Database.countQuery(countSQL);
        r.pages = (Math.ceil(r.total/r.pageSize)).intValue();
        if (r.pages==0) {
            r.pages = 1;
        }
        String sql = 'SELECT id, name, abbreviation__c, asset_class__c, sector__r.Name, rating__c, YTD_Return__c, One_Year_Return__c, Two_Year_Return__c, Five_Year_Return__c FROM Fund__c where name LIKE :key ' +
            'AND YTD_Return__c >= :minYtdReturn AND YTD_Return__c <= :maxYtdReturn ' +
            'AND One_Year_Return__c >= :min1YearReturn AND One_Year_Return__c <= :max1YearReturn ' +
            'AND Five_Year_Return__c >= :min5YearReturn AND Five_Year_Return__c <= :max5YearReturn ';
        if (!String.isBlank(filter.assetClass)) {
            sql = sql + 'AND Asset_Class__c = :assetClass ';
        }
        if (!String.isBlank(filter.sector)) {
            sql = sql + 'AND Sector__c = :sector ';
        }
        sql = sql + 'LIMIT :pSize OFFSET :offset';
        r.funds =  Database.query(sql);
        return r;
    }

    @AuraEnabled(cacheable=true)
    public static List<String> getAssetClasses() {
        Schema.DescribeFieldResult result = Fund__c.Asset_Class__c.getDescribe();
        List<Schema.PicklistEntry> entries = result.getPicklistValues();
        List<String> values = new list <String>();
        for (Schema.PicklistEntry entry: entries) {
            values.add(entry.getValue());
        }
        return values;
    }

    @AuraEnabled(cacheable=true)
    public static Sector__c[] getSectors() {
        return [SELECT Id, Name FROM Sector__c ORDER BY Name];
    }

}
