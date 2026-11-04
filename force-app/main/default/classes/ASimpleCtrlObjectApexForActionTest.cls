public with sharing class ASimpleCtrlObjectApexForActionTest{

    @InvocableMethod
    public static List<Account> getPropertyBasedOnCity(List<Integer> Amount){
        try {
            return [SELECT Id, Name FROM Account WITH USER_MODE LIMIT 1];
        } catch (System.QueryException e) {
            // WITH USER_MODE enforces CRUD/FLS: return empty list when
            // the running user lacks Account read access instead of propagating
            // the exception so that calling Flows can handle the empty result.
            return new List<Account>();
        }
    }
}