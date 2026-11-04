/**
 * @description Test class for GetFoodDetailsInvocable.
 * Verifies the @InvocableMethod behaviour under with-sharing enforcement.
 * GetFoodDetailsInvocable accesses no SObject fields, so sharing enforcement
 * has no data-row or FLS impact; tests confirm the static URL logic is intact.
 */
@IsTest
private class GetFoodDetailsInvocableTest {

    /**
     * @description Positive test: standard user requests food details for "pizza".
     */
    @IsTest
    static void testGetFoodDetails_pizza_positiveUser() {
        User testUser = createStandardUser('gfdi_pizza@test.example.com');
        
        GetFoodDetailsInvocable.FoodDetailRequest req = new GetFoodDetailsInvocable.FoodDetailRequest();
        req.foodName = 'pizza';

        Test.startTest();
        List<GetFoodDetailsInvocable.FoodDetailResponse> responses;
        System.runAs(testUser) {
            responses = GetFoodDetailsInvocable.getFoodDetails(
                new List<GetFoodDetailsInvocable.FoodDetailRequest>{ req }
            );
        }
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null');
        System.assertEquals(1, responses.size(), 'Expected one response');
        System.assertNotEquals(null, responses[0].foodDetails, 'Food details should not be null');
        System.assertEquals(1, responses[0].foodDetails.size(), 'Expected one food detail');
        System.assertEquals('Delicious Pizza', responses[0].foodDetails[0].linkTitle, 'Pizza title mismatch');
    }

    /**
     * @description Test with a restricted profile user: method should still return static data.
     */
    @IsTest
    static void testGetFoodDetails_restrictedUser() {
        User restrictedUser = createStandardUser('gfdi_res@test.example.com');

        GetFoodDetailsInvocable.FoodDetailRequest req = new GetFoodDetailsInvocable.FoodDetailRequest();
        req.foodName = 'burger';

        Test.startTest();
        List<GetFoodDetailsInvocable.FoodDetailResponse> responses;
        System.runAs(restrictedUser) {
            responses = GetFoodDetailsInvocable.getFoodDetails(
                new List<GetFoodDetailsInvocable.FoodDetailRequest>{ req }
            );
        }
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null for restricted user');
        System.assertEquals(1, responses.size(), 'Expected one response for restricted user');
        System.assertEquals('Classic Burger', responses[0].foodDetails[0].linkTitle, 'Burger title mismatch');
    }

    /**
     * @description Test with an unknown food name returns the default "Unknown Food" detail.
     */
    @IsTest
    static void testGetFoodDetails_unknownFood() {
        User testUser = createStandardUser('gfdi_unk@test.example.com');

        GetFoodDetailsInvocable.FoodDetailRequest req = new GetFoodDetailsInvocable.FoodDetailRequest();
        req.foodName = 'unicorn steak';

        Test.startTest();
        List<GetFoodDetailsInvocable.FoodDetailResponse> responses;
        System.runAs(testUser) {
            responses = GetFoodDetailsInvocable.getFoodDetails(
                new List<GetFoodDetailsInvocable.FoodDetailRequest>{ req }
            );
        }
        Test.stopTest();

        System.assertNotEquals(null, responses, 'Responses should not be null for unknown food');
        System.assertEquals(1, responses.size(), 'Expected one response');
        System.assertEquals('Unknown Food', responses[0].foodDetails[0].linkTitle, 'Default title mismatch');
    }

    /**
     * @description Test several known food names to ensure coverage of food-specific branches.
     */
    @IsTest
    static void testGetFoodDetails_variousFoods() {
        User testUser = createStandardUser('gfdi_var@test.example.com');

        Map<String, String> foodTitleMap = new Map<String, String>{
            'pasta'        => 'Tasty Pasta',
            'tiramisu'     => 'Classic Tiramisu',
            'tacos'        => 'Authentic Mexican Tacos',
            'quesadilla'   => 'Cheesy Quesadilla',
            'nachos'       => 'Loaded Nachos',
            'croissant'    => 'Fresh Croissant',
            'ratatouille'  => 'Traditional Ratatouille',
            'creme brulee' => 'French Crème Brûlée',
            'sushi'        => 'Japanese Sushi',
            'ramen'        => 'Delicious Ramen',
            'tempura'      => 'Crispy Tempura',
            'dumplings'    => 'Chinese Dumplings',
            'peking duck'  => 'Peking Duck',
            'spring rolls' => 'Fresh Spring Rolls',
            'hot dog'      => 'Grilled Hot Dog',
            'apple pie'    => 'Homemade Apple Pie'
        };

        Test.startTest();
        System.runAs(testUser) {
            for (String foodName : foodTitleMap.keySet()) {
                GetFoodDetailsInvocable.FoodDetailRequest req = new GetFoodDetailsInvocable.FoodDetailRequest();
                req.foodName = foodName;
                List<GetFoodDetailsInvocable.FoodDetailResponse> responses =
                    GetFoodDetailsInvocable.getFoodDetails(
                        new List<GetFoodDetailsInvocable.FoodDetailRequest>{ req }
                    );
                System.assertEquals(
                    foodTitleMap.get(foodName),
                    responses[0].foodDetails[0].linkTitle,
                    'Title mismatch for food: ' + foodName
                );
            }
        }
        Test.stopTest();
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
