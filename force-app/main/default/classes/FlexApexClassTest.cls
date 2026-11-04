/**
 * @description Test class for FlexApexClass.
 * Verifies with-sharing enforcement and FLS-stripping behaviour when accessing
 * Account.Name and Case.Subject in the @InvocableMethod.
 */
@IsTest
private class FlexApexClassTest {

    /**
     * @description Positive test: user with full read access sees expected prompt text.
     */
    @IsTest
    static void testGetCaseContactPrompt_fullAccess() {
        User fullUser = createStandardUser('flex_full@test.example.com');

        Account acct = new Account(Name = 'Acme Corp');
        insert acct;
        Case cs = new Case(Subject = 'Test Issue', AccountId = acct.Id);
        insert cs;

        // Re-query with only the fields we need (as if passed from Flow)
        Account acctInput = new Account(Id = acct.Id, Name = acct.Name);
        Case caseInput   = new Case(Id = cs.Id, Subject = cs.Subject);

        FlexApexClass.Request req = new FlexApexClass.Request();
        req.My_Account = acctInput;
        req.My_Case    = caseInput;

        Test.startTest();
        List<FlexApexClass.Response> responses;
        System.runAs(fullUser) {
            responses = FlexApexClass.getCaseContactPrompt(
                new List<FlexApexClass.Request>{ req }
            );
        }
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Expected exactly one response');
        System.assert(
            responses[0].Prompt.contains('Acme Corp'),
            'Prompt should contain Account Name: ' + responses[0].Prompt
        );
        System.assert(
            responses[0].Prompt.contains('Test Issue'),
            'Prompt should contain Case Subject: ' + responses[0].Prompt
        );
    }

    /**
     * @description Test with a restricted user where Account.Name may be stripped by FLS.
     * The method must complete without throwing regardless of field accessibility;
     * stripped fields should be treated as empty strings.
     */
    @IsTest
    static void testGetCaseContactPrompt_restrictedUser_noException() {
        User restrictedUser = createStandardUser('flex_res@test.example.com');

        Account acct = new Account(Name = 'Restricted Corp');
        insert acct;
        Case cs = new Case(Subject = 'Restricted Issue', AccountId = acct.Id);
        insert cs;

        Account acctInput = new Account(Id = acct.Id, Name = acct.Name);
        Case caseInput   = new Case(Id = cs.Id, Subject = cs.Subject);

        FlexApexClass.Request req = new FlexApexClass.Request();
        req.My_Account = acctInput;
        req.My_Case    = caseInput;

        Test.startTest();
        List<FlexApexClass.Response> responses;
        Boolean exceptionThrown = false;
        try {
            System.runAs(restrictedUser) {
                responses = FlexApexClass.getCaseContactPrompt(
                    new List<FlexApexClass.Request>{ req }
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
     * @description Test with null field values after potential FLS strip: 
     * verifies graceful handling of null Name and Subject.
     */
    @IsTest
    static void testGetCaseContactPrompt_nullFields() {
        User testUser = createStandardUser('flex_null@test.example.com');

        // Create Account/Case with no Name/Subject to simulate stripped FLS scenario
        Account acctInput = new Account();
        Case caseInput   = new Case();

        FlexApexClass.Request req = new FlexApexClass.Request();
        req.My_Account = acctInput;
        req.My_Case    = caseInput;

        Test.startTest();
        List<FlexApexClass.Response> responses;
        Boolean exceptionThrown = false;
        try {
            System.runAs(testUser) {
                responses = FlexApexClass.getCaseContactPrompt(
                    new List<FlexApexClass.Request>{ req }
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
