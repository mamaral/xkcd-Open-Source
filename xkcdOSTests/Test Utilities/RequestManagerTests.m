//
//  RequestManagerTests.m
//  xkcd Open Source
//
//  Created by Mike on 5/23/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "RequestManager.h"
#import "StubManager.h"

@interface RequestManager (Testing)
- (NSError *)errorWithMessage:(NSString *)errorMessage;
@end

@interface RequestManagerTests : XCTestCase {
    RequestManager *_requestManager;
}

@end

@implementation RequestManagerTests

- (void)setUp {
    [super setUp];

    _requestManager = [RequestManager sharedInstance];

    [[StubManager sharedInstance] removeAllStubs];
}

- (void)tearDown {
    _requestManager = nil;

    [[StubManager sharedInstance] removeAllStubs];

    [super tearDown];
}

- (void)testSingleton {
    XCTAssertNotNil([RequestManager sharedInstance]);
    XCTAssertNotNil([RequestManager sharedInstance].session);
}

- (void)testDownloadLatestComic {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    NSDictionary *comic1 = [Comic comicDictForTestsWithID:1];
    NSDictionary *comic2 = [Comic comicDictForTestsWithID:2];

    [[StubManager sharedInstance] stubComics:@[comic1, comic2]];

    [_requestManager downloadLatestComicWithCompletionHandler:^(NSError *error, NSDictionary *latestComic) {
        XCTAssertNil(error);
        XCTAssertEqualObjects(latestComic, comic2);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDownloadLatestComicWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:502 object:nil delay:0.0];

    [_requestManager downloadLatestComicWithCompletionHandler:^(NSError *error, NSDictionary *latestComic) {
        XCTAssertNotNil(error);
        XCTAssertNil(latestComic);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDownloadComicsWithNumbers {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    // More comics than we download at once, to exercise the batching.
    NSMutableArray *comics = [NSMutableArray array];
    NSMutableArray *numbers = [NSMutableArray array];
    for (NSInteger num = 1; num <= 20; num++) {
        [comics addObject:[Comic comicDictForTestsWithID:num]];
        [numbers addObject:@(num)];
    }

    [[StubManager sharedInstance] stubComics:comics];

    [_requestManager downloadComicsWithNumbers:numbers completionHandler:^(NSError *error, NSArray *comicDicts) {
        XCTAssertNil(error);
        XCTAssertEqual(comicDicts.count, comics.count);

        for (NSDictionary *comic in comics) {
            XCTAssert([comicDicts containsObject:comic]);
        }

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0 handler:nil];
}

- (void)testDownloadComicsWithNoNumbers {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [_requestManager downloadComicsWithNumbers:@[] completionHandler:^(NSError *error, NSArray *comicDicts) {
        XCTAssertNil(error);
        XCTAssertNotNil(comicDicts);
        XCTAssertEqual(comicDicts.count, 0);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDownloadComicsWithPartialFailure {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    NSDictionary *comic1 = [Comic comicDictForTestsWithID:1];
    [[StubManager sharedInstance] stubComics:@[comic1]];

    // Comic 2 doesn't exist, so its request 404s, but we should still get comic 1.
    [_requestManager downloadComicsWithNumbers:@[@1, @2] completionHandler:^(NSError *error, NSArray *comicDicts) {
        XCTAssertNotNil(error);
        XCTAssertEqual(comicDicts.count, 1);
        XCTAssertEqualObjects(comicDicts.firstObject, comic1);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testErrorWithMessage {
    NSString *errorMessage = @"My error message.";
    XCTAssertNotNil([_requestManager errorWithMessage:errorMessage]);
    XCTAssert([[_requestManager errorWithMessage:errorMessage].domain isEqualToString:kRequestManagerErrorDomain]);
    XCTAssertEqual([_requestManager errorWithMessage:errorMessage].code, kRequestManagerErrorCode);
    XCTAssert([[_requestManager errorWithMessage:errorMessage].userInfo[kRequestManagerUserInfoKey] isEqualToString:errorMessage]);

    errorMessage = nil;
    XCTAssert([[_requestManager errorWithMessage:errorMessage].domain isEqualToString:kRequestManagerErrorDomain]);
    XCTAssertEqual([_requestManager errorWithMessage:errorMessage].code, kRequestManagerErrorCode);
    XCTAssert([[_requestManager errorWithMessage:errorMessage].userInfo[kRequestManagerUserInfoKey] isEqualToString:@""]);
}

@end
