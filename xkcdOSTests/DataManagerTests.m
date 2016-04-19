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
#import "StubManager.h"

@interface DataManagerTests : XCTestCase {
    DataManager *_dataManager;
}

@end

@implementation DataManagerTests

- (void)setUp {
    [super setUp];

    _dataManager = [DataManager sharedInstance];

    [_dataManager setLatestComicDownloaded:0];

    [_dataManager.realm beginWriteTransaction];
    [_dataManager.realm deleteAllObjects];
    [_dataManager.realm commitWriteTransaction];

    [[StubManager sharedInstance] removeAllStubs];
}

- (void)tearDown {
    [_dataManager setLatestComicDownloaded:0];

    [_dataManager.realm beginWriteTransaction];
    [_dataManager.realm deleteAllObjects];
    [_dataManager.realm commitWriteTransaction];

    _dataManager = nil;

    [[StubManager sharedInstance] removeAllStubs];

    [super tearDown];
}

- (void)testSingleton {
    XCTAssertNotNil([DataManager sharedInstance]);
    XCTAssertNotNil(_dataManager.realm);
}

- (void)testMarkComicViewed {
    Comic *comic = [Comic new];

    XCTAssertFalse(comic.viewed);

    [_dataManager markComicViewed:comic];

    XCTAssertTrue(comic.viewed);
}

- (void)testMarkComicFavorited {
    Comic *comic = [Comic new];

    XCTAssertFalse(comic.favorite);

    [_dataManager markComic:comic favorited:YES];

    XCTAssertTrue(comic.favorite);

    [_dataManager markComic:comic favorited:NO];

    XCTAssertFalse(comic.favorite);
}

- (void)testRandomComic {
    Comic *comic1 = [Comic comicFromDictionary:[Comic comicDictForTestsWithID:0]];
    Comic *comic2 = [Comic comicFromDictionary:[Comic comicDictForTestsWithID:1]];

    [_dataManager saveComics:@[comic1, comic2]];

    Comic *randomComic = [_dataManager randomComic];

    XCTAssertNotNil(randomComic);
}

- (void)testComicsMatchingSearch {
    Comic *comic1 = [Comic comicFromDictionary:[Comic comicDictForTestsWithID:0]];
    Comic *comic2 = [Comic comicFromDictionary:[Comic comicDictForTestsWithID:1]];

    [_dataManager saveComics:@[comic1, comic2]];

    RLMResults *searchResults = [_dataManager comicsMatchingSearchString:comic1.title];

    XCTAssertEqual(searchResults.count, 1);
    XCTAssertEqualObjects(searchResults.firstObject, comic1);

    searchResults = [_dataManager comicsMatchingSearchString:comic2.alt];

    XCTAssertEqual(searchResults.count, 1);
    XCTAssertEqualObjects(searchResults.firstObject, comic2);

    searchResults = [_dataManager comicsMatchingSearchString:@"thisshouldnotreturnresults"];

    XCTAssertEqual(searchResults.count, 0);
}

- (void)testAllFavorites {
    Comic *comic1 = [Comic comicFromDictionary:[Comic comicDictForTestsWithID:0]];
    Comic *comic2 = [Comic comicFromDictionary:[Comic comicDictForTestsWithID:1]];

    [_dataManager saveComics:@[comic1, comic2]];

    RLMResults *allFavorites = [_dataManager allFavorites];

    XCTAssertEqual(allFavorites.count, 0);

    [_dataManager markComic:comic1 favorited:YES];
    allFavorites = [_dataManager allFavorites];

    XCTAssertEqual(allFavorites.count, 1);

    [_dataManager markComic:comic2 favorited:YES];
    allFavorites = [_dataManager allFavorites];

    XCTAssertEqual(allFavorites.count, 2);

    [_dataManager markComic:comic1 favorited:NO];
    [_dataManager markComic:comic2 favorited:NO];
    allFavorites = [_dataManager allFavorites];

    XCTAssertEqual(allFavorites.count, 0);
}

- (void)testSaveComics {
    NSDictionary *comicDict1 = [Comic comicDictForTestsWithID:0];
    NSDictionary *comicDict2 = [Comic comicDictForTestsWithID:1];
    NSDictionary *comicDict3 = [Comic comicDictForTestsWithID:2];

    Comic *comic1 = [Comic comicFromDictionary:comicDict1];
    Comic *comic2 = [Comic comicFromDictionary:comicDict2];
    Comic *comic3 = [Comic comicFromDictionary:comicDict3];

    [_dataManager saveComics:@[comic1, comic2, comic3]];

    Comic *fetchedComic1 = [Comic objectForPrimaryKey:[comicDict1[kNumKey] stringValue]];
    Comic *fetchedComic2 = [Comic objectForPrimaryKey:[comicDict2[kNumKey] stringValue]];
    Comic *fetchedComic3 = [Comic objectForPrimaryKey:[comicDict3[kNumKey] stringValue]];

    XCTAssertNotNil(fetchedComic1);
    XCTAssertEqual(fetchedComic1.num, [comicDict1[kNumKey] integerValue]);
    XCTAssert([fetchedComic1.title isEqualToString:comicDict1[kTitleKey]]);
    XCTAssert([fetchedComic1.alt isEqualToString:comicDict1[kAltKey]]);
    XCTAssert([fetchedComic1.safeTitle isEqualToString:comicDict1[kSafeTitleKey]]);
    XCTAssert([fetchedComic1.transcript isEqualToString:comicDict1[kTranscriptKey]]);
    XCTAssert([fetchedComic1.imageURLString isEqualToString:comicDict1[kImageURLStringKey]]);
    XCTAssert([fetchedComic1.day isEqualToString:comicDict1[kDayKey]]);
    XCTAssert([fetchedComic1.month isEqualToString:comicDict1[kMonthKey]]);
    XCTAssert([fetchedComic1.year isEqualToString:comicDict1[kYearKey]]);
    XCTAssertEqual(fetchedComic1.aspectRatio, [comicDict1[kAspectRatioKey] floatValue]);

    XCTAssertNotNil(fetchedComic2);
    XCTAssertEqual(fetchedComic2.num, [comicDict2[kNumKey] integerValue]);
    XCTAssert([fetchedComic2.title isEqualToString:comicDict2[kTitleKey]]);
    XCTAssert([fetchedComic2.alt isEqualToString:comicDict2[kAltKey]]);
    XCTAssert([fetchedComic2.safeTitle isEqualToString:comicDict2[kSafeTitleKey]]);
    XCTAssert([fetchedComic2.transcript isEqualToString:comicDict2[kTranscriptKey]]);
    XCTAssert([fetchedComic2.imageURLString isEqualToString:comicDict2[kImageURLStringKey]]);
    XCTAssert([fetchedComic2.day isEqualToString:comicDict2[kDayKey]]);
    XCTAssert([fetchedComic2.month isEqualToString:comicDict2[kMonthKey]]);
    XCTAssert([fetchedComic2.year isEqualToString:comicDict2[kYearKey]]);
    XCTAssertEqual(fetchedComic2.aspectRatio, [comicDict2[kAspectRatioKey] floatValue]);

    XCTAssertNotNil(fetchedComic3);
    XCTAssertEqual(fetchedComic3.num, [comicDict3[kNumKey] integerValue]);
    XCTAssert([fetchedComic3.title isEqualToString:comicDict3[kTitleKey]]);
    XCTAssert([fetchedComic3.alt isEqualToString:comicDict3[kAltKey]]);
    XCTAssert([fetchedComic3.safeTitle isEqualToString:comicDict3[kSafeTitleKey]]);
    XCTAssert([fetchedComic3.transcript isEqualToString:comicDict3[kTranscriptKey]]);
    XCTAssert([fetchedComic3.imageURLString isEqualToString:comicDict3[kImageURLStringKey]]);
    XCTAssert([fetchedComic3.day isEqualToString:comicDict3[kDayKey]]);
    XCTAssert([fetchedComic3.month isEqualToString:comicDict3[kMonthKey]]);
    XCTAssert([fetchedComic3.year isEqualToString:comicDict3[kYearKey]]);
    XCTAssertEqual(fetchedComic3.aspectRatio, [comicDict3[kAspectRatioKey] floatValue]);
}

- (void)testLatestComicDownloaded {
    NSInteger latest = 4;

    [_dataManager setLatestComicDownloaded:latest];
    XCTAssertEqual([_dataManager latestComicDownloaded], latest);

    latest = 11;

    [_dataManager setLatestComicDownloaded:latest];
    XCTAssertEqual([_dataManager latestComicDownloaded], latest);
}

- (void)testAllSavedComics {
    // Create some comic dicts, save them, and when we fetch them back ensure they're
    // in order from highest to lowest.
    NSDictionary *comicDict1 = [Comic comicDictForTestsWithID:2];
    NSDictionary *comicDict2 = [Comic comicDictForTestsWithID:3];
    NSDictionary *comicDict3 = [Comic comicDictForTestsWithID:1];

    Comic *comic1 = [Comic comicFromDictionary:comicDict1];
    Comic *comic2 = [Comic comicFromDictionary:comicDict2];
    Comic *comic3 = [Comic comicFromDictionary:comicDict3];

    NSArray *comics = @[comic1, comic2, comic3];

    [_dataManager.realm beginWriteTransaction];
    [_dataManager.realm addObjects:comics];
    [_dataManager.realm commitWriteTransaction];

    RLMResults *fetchedComics = [_dataManager allSavedComics];

    XCTAssertEqual(fetchedComics.count, comics.count);

    Comic *fetchedComic1 = [fetchedComics objectAtIndex:1];
    Comic *fetchedComic2 = [fetchedComics objectAtIndex:0];
    Comic *fetchedComic3 = [fetchedComics objectAtIndex:2];

    XCTAssertNotNil(fetchedComic1);
    XCTAssertEqual(fetchedComic1.num, [comicDict1[kNumKey] integerValue]);
    XCTAssert([fetchedComic1.title isEqualToString:comicDict1[kTitleKey]]);
    XCTAssert([fetchedComic1.alt isEqualToString:comicDict1[kAltKey]]);
    XCTAssert([fetchedComic1.safeTitle isEqualToString:comicDict1[kSafeTitleKey]]);
    XCTAssert([fetchedComic1.transcript isEqualToString:comicDict1[kTranscriptKey]]);
    XCTAssert([fetchedComic1.imageURLString isEqualToString:comicDict1[kImageURLStringKey]]);
    XCTAssert([fetchedComic1.day isEqualToString:comicDict1[kDayKey]]);
    XCTAssert([fetchedComic1.month isEqualToString:comicDict1[kMonthKey]]);
    XCTAssert([fetchedComic1.year isEqualToString:comicDict1[kYearKey]]);
    XCTAssertEqual(fetchedComic1.aspectRatio, [comicDict1[kAspectRatioKey] floatValue]);

    XCTAssertNotNil(fetchedComic2);
    XCTAssertEqual(fetchedComic2.num, [comicDict2[kNumKey] integerValue]);
    XCTAssert([fetchedComic2.title isEqualToString:comicDict2[kTitleKey]]);
    XCTAssert([fetchedComic2.alt isEqualToString:comicDict2[kAltKey]]);
    XCTAssert([fetchedComic2.safeTitle isEqualToString:comicDict2[kSafeTitleKey]]);
    XCTAssert([fetchedComic2.transcript isEqualToString:comicDict2[kTranscriptKey]]);
    XCTAssert([fetchedComic2.imageURLString isEqualToString:comicDict2[kImageURLStringKey]]);
    XCTAssert([fetchedComic2.day isEqualToString:comicDict2[kDayKey]]);
    XCTAssert([fetchedComic2.month isEqualToString:comicDict2[kMonthKey]]);
    XCTAssert([fetchedComic2.year isEqualToString:comicDict2[kYearKey]]);
    XCTAssertEqual(fetchedComic2.aspectRatio, [comicDict2[kAspectRatioKey] floatValue]);

    XCTAssertNotNil(fetchedComic3);
    XCTAssertEqual(fetchedComic3.num, [comicDict3[kNumKey] integerValue]);
    XCTAssert([fetchedComic3.title isEqualToString:comicDict3[kTitleKey]]);
    XCTAssert([fetchedComic3.alt isEqualToString:comicDict3[kAltKey]]);
    XCTAssert([fetchedComic3.safeTitle isEqualToString:comicDict3[kSafeTitleKey]]);
    XCTAssert([fetchedComic3.transcript isEqualToString:comicDict3[kTranscriptKey]]);
    XCTAssert([fetchedComic3.imageURLString isEqualToString:comicDict3[kImageURLStringKey]]);
    XCTAssert([fetchedComic3.day isEqualToString:comicDict3[kDayKey]]);
    XCTAssert([fetchedComic3.month isEqualToString:comicDict3[kMonthKey]]);
    XCTAssert([fetchedComic3.year isEqualToString:comicDict3[kYearKey]]);
    XCTAssertEqual(fetchedComic3.aspectRatio, [comicDict3[kAspectRatioKey] floatValue]);
}

- (void)testDownloadLatestComics {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    NSInteger latest = 2;
    NSDictionary *comic1 = [Comic comicDictForTestsWithID:1];
    NSDictionary *comic2 = [Comic comicDictForTestsWithID:latest];

    NSArray *comics = @[comic1, comic2];

    [[StubManager sharedInstance] stubResponseWithStatusCode:202 object:comics delay:0.0];

    [_dataManager downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        XCTAssertNil(error);
        XCTAssertEqual(numberOfNewComics, comics.count);
        XCTAssertEqual([_dataManager latestComicDownloaded], latest);

        XCTAssertGreaterThanOrEqual([_dataManager allSavedComics].count, comics.count);
        XCTAssertNotNil([Comic objectForPrimaryKey:@"1"]);

        NSString *latestID = [NSString stringWithFormat:@"%ld", (long)latest];
        XCTAssertNotNil([Comic objectForPrimaryKey:latestID]);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testPerformBackgroundFetchNewData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    NSInteger latest = 2;
    NSDictionary *comic1 = [Comic comicDictForTestsWithID:1];
    NSDictionary *comic2 = [Comic comicDictForTestsWithID:latest];

    NSArray *comics = @[comic1, comic2];

    [[StubManager sharedInstance] stubResponseWithStatusCode:202 object:comics delay:0.0];

    [_dataManager performBackgroundFetchWithCompletionHandler:^(UIBackgroundFetchResult result) {
        XCTAssertEqual(result, UIBackgroundFetchResultNewData);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testPerformBackgroundFetchNoNewData {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:200 object:@[] delay:0.0];

    [_dataManager performBackgroundFetchWithCompletionHandler:^(UIBackgroundFetchResult result) {
        XCTAssertEqual(result, UIBackgroundFetchResultNoData);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testPerformBackgroundFetchFailed {
    XCTestExpectation *expectation = [self expectationWithDescription:@"The completion handler should be called."];

    [[StubManager sharedInstance] stubResponseWithStatusCode:500 object:nil delay:0.0];

    [_dataManager performBackgroundFetchWithCompletionHandler:^(UIBackgroundFetchResult result) {
        XCTAssertEqual(result, UIBackgroundFetchResultFailed);

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}

- (void)testTokenStringFromData {
    NSString *tokenString = [_dataManager tokenStringFromData:[NSData data]];
    XCTAssertNotNil(tokenString);
}

- (void)testTokenStringFromNilData {
    NSString *tokenString = [_dataManager tokenStringFromData:nil];
    XCTAssert([tokenString isEqualToString:@""]);
}

- (void)testHasAskedForReview {
    XCTAssertFalse([_dataManager hasAskedForReview]);

    [_dataManager setHasAskedForReview:YES];

    XCTAssertTrue([_dataManager hasAskedForReview]);

    [_dataManager setHasAskedForReview:NO];

    XCTAssertFalse([_dataManager hasAskedForReview]);
}

@end
