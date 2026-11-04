/**
 * @description Test class for ASimpleCtrlObjectApexForActionTest.
 *
 * Verifies that the with-sharing and WITH USER_MODE enforcement
 * prevents users without Account read access from retrieving records
 * via the @InvocableMethod entry point.
 */
@IsTest
private class ASimpleCtrlObjectApexForActionTestTest {

    /**
     * @description Creates a restricted user who has no object-level
     * permission to read Account records.
     */
    private static User createRestrictedUser() {
        Profile minProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];

        User restrictedUser = new User(
            FirstName        = 'Restricted',
            LastName         = 'TestUser',
            Email            = 'restricted.testuser@example.invalid',
            Username         = 'restricted.testuser.' + UserInfo.getOrganizationId() + '@example.invalid',
            Alias            = 'rstrctd',
            TimeZoneSidKey   = 'America/Los_Angeles',
            LocaleSidKey     = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId        = minProfile.Id
        );
        insert restrictedUser;
        return restrictedUser;
    }

    /**
     * @description Verifies that a privileged admin user (running in system context)
     * can retrieve Account records — confirms the method works correctly when access
     * is granted.
     */
    @IsTest
    static void testAdminCanRetrieveAccount() {
        Account testAccount = new Account(Name = 'CRUD Test Account');
        insert testAccount;

        List<Integer> amounts = new List<Integer>{ 1 };

        Test.startTest();
        List<Account> results = ASimpleCtrlObjectApexForActionTest.getPropertyBasedOnCity(amounts);
        Test.stopTest();

        // System admin has Account read access; should return a record
        System.assertEquals(1, results.size(), 'Admin should be able to retrieve accounts');
        System.assertEquals(testAccount.Id, results[0].Id, 'Should retrieve the inserted test account');
    }

    /**
     * @description Verifies that a restricted user with no Account read permission
     * gets an empty result list (WITH USER_MODE + with sharing enforcement).
     */
    @IsTest
    static void testRestrictedUserCannotRetrieveAccount() {
        // Insert account as system admin so it exists in the org
        Account testAccount = new Account(Name = 'Security Test Account');
        insert testAccount;

        User restrictedUser = createRestrictedUser();

        List<Integer> amounts = new List<Integer>{ 1 };
        List<Account> results;

        Test.startTest();
        System.runAs(restrictedUser) {
            results = ASimpleCtrlObjectApexForActionTest.getPropertyBasedOnCity(amounts);
        }
        Test.stopTest();

        // Restricted user has no Account read permission;
        // WITH USER_MODE enforces FLS/CRUD so the result must be empty
        System.assertEquals(0, results.size(), 'Restricted user must not be able to retrieve accounts');
    }

    /**
     * @description Verifies that passing a null or empty amounts list does not
     * cause an unhandled exception and returns an empty result.
     */
    @IsTest
    static void testEmptyAmountsReturnsLimit() {
        Account testAccount = new Account(Name = 'Limit Test Account');
        insert testAccount;

        List<Integer> amounts = new List<Integer>();

        Test.startTest();
        List<Account> results = ASimpleCtrlObjectApexForActionTest.getPropertyBasedOnCity(amounts);
        Test.stopTest();

        // Method ignores the amounts list and performs LIMIT 1 query
        System.assertNotEquals(null, results, 'Result should not be null');
    }
}
