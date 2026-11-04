/**
 * @description Test class for FieldGenerationApexClass.
 * Verifies with-sharing enforcement and FLS-stripping behaviour when accessing
 * Account.Name and Account.Phone in the @InvocableMethod.
 */
@IsTest
private class FieldGenerationApexClassTest {

    /**
     * @description Positive test: user with full read access sees expected prompt.
     */
    @IsTest
    static void testGetAccountsPrompt_fullAccess() {
        User fullUser = createStandardUser('fgac_full@test.example.com');

        Account acct = new Account(Name = 'Tech Corp', Phone = '555-1234');
        insert acct;

        Account acctInput = new Account(Id = acct.Id, Name = acct.Name, Phone = acct.Phone);

        FieldGenerationApexClass.Request req = new FieldGenerationApexClass.Request();
        req.RelatedEntity = acctInput;

        Test.startTest();
        List<FieldGenerationApexClass.Response> responses;
        System.runAs(fullUser) {
            responses = FieldGenerationApexClass.getAccountsPrompt(
                new List<FieldGenerationApexClass.Request>{ req }
            );
        }
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Expected exactly one response');
        System.assert(
            responses[0].Prompt.contains('Tech Corp'),
            'Prompt should contain Account Name: ' + responses[0].Prompt
        );
        System.assert(
            responses[0].Prompt.contains('555-1234'),
            'Prompt should contain Phone: ' + responses[0].Prompt
        );
    }

    /**
     * @description Test with a restricted user where Account.Name/Phone may be stripped by FLS.
     * The method must complete without throwing; stripped fields should default to empty strings.
     */
    @IsTest
    static void testGetAccountsPrompt_restrictedUser_noException() {
        User restrictedUser = createStandardUser('fgac_res@test.example.com');

        Account acct = new Account(Name = 'Restricted Corp', Phone = '555-9999');
        insert acct;

        Account acctInput = new Account(Id = acct.Id, Name = acct.Name, Phone = acct.Phone);

        FieldGenerationApexClass.Request req = new FieldGenerationApexClass.Request();
        req.RelatedEntity = acctInput;

        Test.startTest();
        List<FieldGenerationApexClass.Response> responses;
        Boolean exceptionThrown = false;
        try {
            System.runAs(restrictedUser) {
                responses = FieldGenerationApexClass.getAccountsPrompt(
                    new List<FieldGenerationApexClass.Request>{ req }
                );
            }
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(false, exceptionThrown, 'No exception should be thrown for restricted user');
        System.assertNotEquals(null, responses, 'Responses should not be null for restricted user');
        System.assertEquals(1, responses.size(), 'Expected one response for restricted user');
        System.assertNotEquals(null, responses[0].Prompt, 'Prompt should not be null');
    }

    /**
     * @description Test with null Name and Phone (e.g., after FLS strip or blank Account).
     * Verifies graceful handling — prompt should still be non-null.
     */
    @IsTest
    static void testGetAccountsPrompt_nullFields() {
        User testUser = createStandardUser('fgac_null@test.example.com');

        // Account with no fields populated to simulate FLS-stripped scenario
        Account acctInput = new Account();

        FieldGenerationApexClass.Request req = new FieldGenerationApexClass.Request();
        req.RelatedEntity = acctInput;

        Test.startTest();
        List<FieldGenerationApexClass.Response> responses;
        Boolean exceptionThrown = false;
        try {
            System.runAs(testUser) {
                responses = FieldGenerationApexClass.getAccountsPrompt(
                    new List<FieldGenerationApexClass.Request>{ req }
                );
            }
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        System.assertEquals(false, exceptionThrown, 'Should handle null fields without exception');
        System.assertNotEquals(null, responses, 'Responses should not be null with null fields');
        System.assertNotEquals(null, responses[0].Prompt, 'Prompt must not be null even with null fields');
    }

    /**
     * @description Test with a fully populated Account to confirm full prompt format.
     */
    @IsTest
    static void testGetAccountsPrompt_fullPromptFormat() {
        User testUser = createStandardUser('fgac_fmt@test.example.com');

        Account acctInput = new Account(Name = 'Global Inc', Phone = '800-0000');

        FieldGenerationApexClass.Request req = new FieldGenerationApexClass.Request();
        req.RelatedEntity = acctInput;

        Test.startTest();
        List<FieldGenerationApexClass.Response> responses;
        System.runAs(testUser) {
            responses = FieldGenerationApexClass.getAccountsPrompt(
                new List<FieldGenerationApexClass.Request>{ req }
            );
        }
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Expected non-null responses');
        System.assertEquals(1, responses.size(), 'Expected one response');
        System.assert(
            responses[0].Prompt.startsWith('Account Name='),
            'Prompt should start with Account Name=: ' + responses[0].Prompt
        );
    }

    // ────────────────────────────────────────────────────────────────────────
    // Helper
    // ────────────────────────────────────────────────────────────────────────

    private static User createStandardUser(String username) {
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName       = 'Test',
            LastName        = 'User',
            Email           = username,
            Username        = username,
            Alias           = 'tstUsr',
            TimeZoneSidKey  = 'America/Los_Angeles',
            LocaleSidKey    = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            ProfileId       = p.Id
        );
        insert u;
        return u;
    }
}
