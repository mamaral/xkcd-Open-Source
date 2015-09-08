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
    XCTAssertNotNil([RequestManager sharedInstance].manager);
    XCTAssertNotNil([RequestManager sharedInstance].manager.requestSerializer);
    XCTAssert([[RequestManager sharedInstance].manager.requestSerializer.HTTPRequestHeaders[kContentTypeKey] isEqualToString:kDefaultContentType]);
}

- (void)testDownloadComicsSinceWithComics {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    NSDictionary *comic1 = [Comic comicDictForTestsWithID:1];
    NSDictionary *comic2 = [Comic comicDictForTestsWithID:2];

    NSArray *comics = @[comic1, comic2];

    [[StubManager sharedInstance] stubResponseWithStatusCode:202 object:comics delay:0.0];

    [_requestManager downloadComicsSince:0 completionHandler:^(NSError *error, NSArray *comicDicts) {
        XCTAssertNil(error);
        XCTAssertNotNil(comicDicts);
        XCTAssertEqual(comicDicts.count, comics.count);
        XCTAssert([comicDicts containsObject:comic1]);
        XCTAssert([comicDicts containsObject:comic2]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDownloadComicsSinceWithNoComics {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:200 object:@[] delay:0.0];

    [_requestManager downloadComicsSince:0 completionHandler:^(NSError *error, NSArray *comicDicts) {
        XCTAssertNil(error);
        XCTAssertNotNil(comicDicts);
        XCTAssertEqual(comicDicts.count, 0);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testDownloadComicsSinceWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:502 object:nil delay:0.0];

    [_requestManager downloadComicsSince:0 completionHandler:^(NSError *error, NSArray *comicDicts) {
        XCTAssertNotNil(error);
        XCTAssertNil(comicDicts);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testSendDeviceToken {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:200 object:nil delay:0.0];

    NSString *token = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    [_requestManager sendDeviceToken:token completionHandler:^(NSError *error) {
        XCTAssertNil(error);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testSendNilToken {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:502 object:nil delay:0.0];

    NSString *token = nil;
    [_requestManager sendDeviceToken:token completionHandler:^(NSError *error) {
        XCTAssertNotNil(error);
        XCTAssert([error.domain isEqualToString:kRequestManagerErrorDomain]);
        XCTAssertEqual(error.code, kRequestManagerErrorCode);
        XCTAssert([error.userInfo[kRequestManagerUserInfoKey] isEqualToString:kRequestManagerNilTokenErrorMessage]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:2.0 handler:nil];
}

- (void)testSendTokenWithError {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:502 object:nil delay:0.0];

    NSString *token = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";
    [_requestManager sendDeviceToken:token completionHandler:^(NSError *error) {
        XCTAssertNotNil(error);

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
