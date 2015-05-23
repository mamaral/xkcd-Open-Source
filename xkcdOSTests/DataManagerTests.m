//
//  DataManagerTests.m
//  xkcd Open Source
//
//  Created by Mike on 5/22/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "DataManager.h"

static NSString *kRealmPathForTesting = @"test.realm";

@interface DataManagerTests : XCTestCase {
    DataManager *_dataManager;
    RLMRealm *_testRealm;
}

@end

@implementation DataManagerTests

- (void)setUp {
    [super setUp];

    [self deleteAllRealmFiles];

    _testRealm = [RLMRealm realmWithPath:[self testRealmPath] readOnly:NO error:nil];

    _dataManager = [DataManager sharedInstance];
    _dataManager.realm = _testRealm;
}

- (void)tearDown {
    [self deleteAllRealmFiles];

    _testRealm = nil;
    _dataManager = nil;

    [super tearDown];
}

- (void)deleteAllRealmFiles {
    NSString *testRealmPath = [self testRealmPath];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    [fileManager removeItemAtPath:testRealmPath error:nil];

    NSString *lockPath = [testRealmPath stringByAppendingString:@".lock"];
    [fileManager removeItemAtPath:lockPath error:nil];
}

- (NSString *)testRealmPath {
    NSString *basePath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    return [basePath stringByAppendingPathComponent:kRealmPathForTesting];
}

- (void)testSingleton {
    XCTAssertNotNil([DataManager sharedInstance]);
    XCTAssertNotNil(_dataManager.realm);
}

- (void)testSaveComics {
    NSDictionary *comicDict = @{
                                kNumKey: @123,
                                kTitleKey: @"Title",
                                kSafeTitleKey: @"Safe title",
                                kAltKey: @"Alt",
                                kTranscriptKey: @"Trans",
                                kImageURLStringKey: @"www.imageURL.com",
                                kDayKey: @"1",
                                kMonthKey: @"12",
                                kYearKey: @"1881",
                                kAspectRatioKey: @(1.0)
                                };

//    Comic *comic = [Comic comicFromDictionary:comicDict];
//
//    [_dataManager saveComics:@[comic]];
//
//    RLMResults *comics = [Comic allObjects];
//    XCTAssertNotEqual([comics indexOfObject:comic], NSNotFound);
}

@end
