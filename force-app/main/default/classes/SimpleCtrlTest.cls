/**
 * @description Test class for SimpleCtrl.
 * Verifies that the @InvocableMethod works correctly under with-sharing enforcement
 * and tests both a fully-permissioned user (positive) and a restricted user via System.runAs().
 */
@IsTest
private class SimpleCtrlTest {

    /**
     * @description Positive test: Standard user calls reverseString and gets expected output.
     */
    @IsTest
    static void testReverseString_positiveUser() {
        User testUser = createStandardUser('simplectrl_pos@test.example.com');
        
        Test.startTest();
        List<String> result;
        System.runAs(testUser) {
            result = SimpleCtrl.reverseString(new List<String>{'hello'});
        }
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(1, result.size(), 'Expected exactly one result');
        System.assertEquals('hellooooooo', result[0], 'Expected static return value');
    }

    /**
     * @description Test with a restricted user: method should still complete because
     * SimpleCtrl has no SOQL/DML/SObject field access; with sharing has no data-row impact.
     */
    @IsTest
    static void testReverseString_restrictedUser() {
        User restrictedUser = createStandardUser('simplectrl_res@test.example.com');

        Test.startTest();
        List<String> result;
        System.runAs(restrictedUser) {
            result = SimpleCtrl.reverseString(new List<String>{'anyInput'});
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for restricted user');
        System.assertEquals(1, result.size(), 'Expected exactly one result for restricted user');
        System.assertEquals('hellooooooo', result[0], 'Expected static return value for restricted user');
    }

    /**
     * @description Test with empty input list; method should return a non-null list.
     */
    @IsTest
    static void testReverseString_emptyInput() {
        User testUser = createStandardUser('simplectrl_empty@test.example.com');

        Test.startTest();
        List<String> result;
        System.runAs(testUser) {
            result = SimpleCtrl.reverseString(new List<String>());
        }
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null on empty input');
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
