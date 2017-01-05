//
//  iOSHelpersTests.m
//  iOSHelpersTests
//
//  Created by Jota Melo on 21/09/16.
//
//

#import <XCTest/XCTest.h>
#import "User.h"
#import "API.h"
#import "APICacheManager.h"
#import "Helper.h"

@interface iOSHelpersTests : XCTestCase

@property (strong, nonatomic) API *request;

@end

@implementation iOSHelpersTests

- (void)testBaseModel
{
    NSDictionary *testDictionary = @{@"id": @"123",
                                     @"user_name": @"fulana22k",
                                     @"email": @"fulana22k@hotmail.com",
                                     @"is_first_login": @YES,
                                     @"register_date": @"2015/08/21 15:45:45",
                                     @"favorite_pizza": @{@"pizza_id": @5,
                                                          @"name": @"Catuperoni",
                                                          @"number_of_ingredients": [NSNull null]},
                                     @"OrderedPizzas": @[@{@"pizza_id": @5,
                                                           @"name": @"Catuperoni",
                                                           @"number_of_ingredients": @3},
                                                         @{@"pizza_id": @10,
                                                           @"name": @"Calabresa",
                                                           @"number_of_ingredients": [NSNull null]}]};
    
    User *user = [User initWithDictionary:testDictionary];
    
    NSDictionary *testDictionary2 = @{@"id": @"123",
                                     @"user_name": @"fulana22k",
                                     @"email": @"fulana22k@hotmail.com",
                                     @"is_first_login": @YES,
                                     @"register_date": @"2015-08-21",
                                     @"favorite_pizza": @{@"pizza_id": @5,
                                                          @"name": @"Catuperoni",
                                                          @"number_of_ingredients": [NSNull null]},
                                     @"OrderedPizzas": @[@{@"pizza_id": @5,
                                                           @"name": @"Catuperoni",
                                                           @"number_of_ingredients": @3},
                                                         @{@"pizza_id": @10,
                                                           @"name": @"Calabresa",
                                                           @"number_of_ingredients": [NSNull null]}]};
    
    User *user2 = [User new];
    user2.modelDateFormat = @"yyyy-MM-dd";
    user2.originalDictionary = testDictionary2;
    
    XCTAssert([user.uid isEqual:@123]);
    XCTAssert([user.userName isEqualToString:@"fulana22k"]);
    XCTAssert([user.email isEqualToString:@"fulana22k@hotmail.com"]);
    XCTAssert(user.isFirstLogin);
    
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = user.modelDateFormat;
    XCTAssert([user.registerDate isEqual:[dateFormatter dateFromString:@"2015/08/21 15:45:45"]]);
    
    XCTAssert(user.favoritePizza.pizzaID == 5);
    XCTAssert([user.favoritePizza.name isEqualToString:@"Catuperoni"]);
    XCTAssert(user.favoritePizza.numberOfIngredients == nil);
    XCTAssert(user.orderedPizzas.count == 2);
    
    XCTAssert(user.orderedPizzas.firstObject.pizzaID == 5);
    XCTAssert([user.orderedPizzas.firstObject.name isEqualToString:@"Catuperoni"]);
    XCTAssert([user.orderedPizzas.firstObject.numberOfIngredients isEqual:@3]);
    
    XCTAssert(user.orderedPizzas.lastObject.pizzaID == 10);
    XCTAssert([user.orderedPizzas.lastObject.name isEqualToString:@"Calabresa"]);
    XCTAssert(user.orderedPizzas.lastObject.numberOfIngredients == nil);
    
    XCTAssert([user.dictionaryRepresentation isEqualToDictionary:testDictionary]);
    
    dateFormatter.dateFormat = user2.modelDateFormat;
    XCTAssert([user2.registerDate isEqual:[dateFormatter dateFromString:@"2015-08-21"]]);
    
    XCTAssert([user2.dictionaryRepresentation isEqualToDictionary:testDictionary2]);
}

- (void)testAPIHelpers
{
    NSDictionary *testDictionary = @{@"id": @"123",
                                     @"abc": @[@{@"a": @"b",
                                                 @"b": @"c",
                                                 @"c": @[@1, @2, @3, @{@"x": @"y"}]},
                                                ],
                                     @"ddd": @{@"b": @"j",
                                               @"c": @{@"b": @"p", @"c": [NSData new]}}};
    
    NSDictionary *flattenedTestDictionary = @{@"id": @"123",
                                              @"abc[0][a]": @"b",
                                              @"abc[0][b]": @"c",
                                              @"abc[0][c][0]": @1,
                                              @"abc[0][c][1]": @2,
                                              @"abc[0][c][2]": @3,
                                              @"abc[0][c][3][x]": @"y",
                                              @"ddd[b]": @"j",
                                              @"ddd[c][b]": @"p",
                                              @"ddd[c][c]": [NSData new]};
    
    NSDictionary *flattenedDictionary = [API flattenDictionary:testDictionary];
    
    XCTAssert([flattenedDictionary isEqualToDictionary:flattenedTestDictionary]);
    XCTAssert([API checkForDataObjectsInParameters:testDictionary.allValues]);
}

- (void)testAPIRequest
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"APIRequest"];
    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"APIRequestCached"];
    
    NSDictionary *testDictionary = @{@"id": @"123",
                                     @"abc": @[@{@"a": @"b",
                                                 @"b": @"c",
                                                 @"c": @[@1, @2, @3, @{@"x": @"y"}]},
                                               ],
                                     @"ddd": @{@"b": @"j",
                                               @"c": @{@"b": @"p"}}};
    
    [APICacheManager.sharedManager clearCache];
    
    __weak typeof(self) weakSelf = self;
    self.request = [API make:APIMethodPOST requestWithPath:@"randomness/123echo123" baseURL:[NSURL URLWithString:@"http://jota.pm"] parameters:testDictionary extraHeaders:nil suppressErrorAlert:NO uploadBlock:nil downloadBlock:nil cacheOption:APICacheOptionNetworkOnly completion:^(id  _Nullable response, NSError * _Nullable error, BOOL cache) {
        
        XCTAssert(!cache);
        XCTAssert(!error);
        XCTAssert([response isEqual:testDictionary]);
        
        [expectation fulfill];
        
        weakSelf.request.cacheOption = APICacheOptionCacheOnly;
        weakSelf.request.completionBlock = ^(id response, NSError *error, BOOL cache) {
            
            XCTAssert(cache);
            XCTAssert(!error);
            XCTAssert([response isEqual:testDictionary]);
            
            [cacheExpectation fulfill];
            weakSelf.request = nil;
        };
        
        // cache save is async, so wait a bit to make sure it had time to save
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [weakSelf.request makeRequest];
        });
    }];
    [self.request makeRequest];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)testCache
{
    APICacheManager *cacheManager = APICacheManager.sharedManager;
    
    // checking it doesn't crash
    [cacheManager cacheFileNameWithPath:@"randomness/123echo123" method:APIMethodGET parameters:nil];
    [cacheManager cacheFileNameWithPath:@"randomness/123echo123" method:APIMethodPOST parameters:@{@"a": @{@"b": @"c"}}];
    [cacheManager cacheFileNameWithPath:@"randomness/123echo123" method:APIMethodPOST parameters:@{@"a": @{@"b": [NSData new]}}];
    
    // checking consistent results
    NSData *imageData = UIImagePNGRepresentation([UIImage imageNamed:@"testImage.jpg"]);
    NSString *cacheFileName1 = [cacheManager cacheFileNameWithPath:@"randomness/123echo123" method:APIMethodPUT parameters:@{@"a": @{@"b": imageData}}];
    NSString *cacheFileName2 = [cacheManager cacheFileNameWithPath:@"randomness/123echo123" method:APIMethodPUT parameters:@{@"a": @{@"b": imageData}}];
    XCTAssertEqualObjects(cacheFileName1, cacheFileName2);
    
    // saving this image to cache should go over the default 1MB in memory cache limit
    [cacheManager writeData:@{@"a": @{@"b": imageData}} toCacheFile:cacheFileName2];
    
    XCTestExpectation *cacheExpectation = [self expectationWithDescription:@"Cache"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSDictionary *inMemoryCache = [cacheManager valueForKey:@"memoryCache"];
        XCTAssertNil(inMemoryCache[cacheFileName2]);
        
        [cacheManager callBlock:^(id  _Nullable response, NSError * _Nullable error, BOOL cache) {
            XCTAssert(cache);
            XCTAssertEqualObjects(@{@"a": @{@"b": imageData}}, response);
            
            [cacheExpectation fulfill];
        } ifCacheExistsForFileName:cacheFileName2];
    });
    
    [self waitForExpectationsWithTimeout:5.f handler:^(NSError * _Nullable error) {
        
    }];
}

- (void)testHelpers
{
    NSArray<NSDictionary *> *pizzas = @[@{@"id": @5,
                                          @"name": @"Catuperoni",
                                          @"number_of_ingredients": @3},
                                        @{@"id": @10,
                                          @"name": @"Calabresa",
                                          @"number_of_ingredients": [NSNull null]}];
    
    NSMutableArray<Pizza *> *pizzasTestArray = @[].mutableCopy;
    for (NSDictionary *modelDictionary in pizzas) {
        Pizza *model = [Pizza initWithDictionary:modelDictionary];
        [pizzasTestArray addObject:model];
    }
    
    NSArray<Pizza *> *pizzasArray = [Helper transformDictionaryArray:pizzas intoArrayOfModels:[Pizza class]];
    
    XCTAssert([pizzasArray isEqualToArray:pizzasTestArray]);
    XCTAssert([Helper userDefaults]);
    
    [Helper setDefaultsObject:@"12345" forKey:@"abcdef"];
    
    XCTAssert([[Helper defaultsObjectForKey:@"abcdef"] isEqualToString:@"12345"]);
    
    [Helper removeDefaultsObjectForKey:@"abcdef"];
    
    XCTAssertNil([Helper defaultsObjectForKey:@"abcdef"]);
}

@end
