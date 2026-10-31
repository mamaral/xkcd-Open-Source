//
//  ComicTests.m
//  xkcd Open Source
//
//  Created by Mike on 5/20/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "Comic.h"

@interface ComicTests : XCTestCase

@end

@implementation ComicTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testComicWithEmptyDictionary {
    NSDictionary *emptyDict = @{};
    Comic *comicFromEmptyDict = [Comic comicFromDictionary:emptyDict];

    XCTAssertNotNil(comicFromEmptyDict);
    XCTAssertEqual(comicFromEmptyDict.num, 0);
    XCTAssert([comicFromEmptyDict.comicID isEqualToString:@"0"]);
    XCTAssert([comicFromEmptyDict.title isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.safeTitle isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.alt isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.transcript isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.imageURLString isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.day isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.month isEqualToString:@""]);
    XCTAssert([comicFromEmptyDict.year isEqualToString:@""]);
    XCTAssertEqual(comicFromEmptyDict.aspectRatio, kDefaultAspectRatio);
    XCTAssertFalse(comicFromEmptyDict.viewed);
    XCTAssert([comicFromEmptyDict.formattedDateString isEqualToString:@""]);
}

- (void)testComicWithNilDictionary {
    NSDictionary *nilDict = nil;
    Comic *comicFromNilDict = [Comic comicFromDictionary:nilDict];

    XCTAssertNotNil(comicFromNilDict);
    XCTAssertEqual(comicFromNilDict.num, 0);
    XCTAssert([comicFromNilDict.comicID isEqualToString:@"0"]);
    XCTAssert([comicFromNilDict.title isEqualToString:@""]);
    XCTAssert([comicFromNilDict.safeTitle isEqualToString:@""]);
    XCTAssert([comicFromNilDict.alt isEqualToString:@""]);
    XCTAssert([comicFromNilDict.transcript isEqualToString:@""]);
    XCTAssert([comicFromNilDict.imageURLString isEqualToString:@""]);
    XCTAssert([comicFromNilDict.day isEqualToString:@""]);
    XCTAssert([comicFromNilDict.month isEqualToString:@""]);
    XCTAssert([comicFromNilDict.year isEqualToString:@""]);
    XCTAssertEqual(comicFromNilDict.aspectRatio, kDefaultAspectRatio);
    XCTAssertFalse(comicFromNilDict.viewed);
    XCTAssert([comicFromNilDict.formattedDateString isEqualToString:@""]);
}

- (void)testComicWithValidDictionary {
    NSNumber *comicID = @456;
    NSInteger num = [comicID integerValue];
    NSString *title = @"This is a comic title.";
    NSString *safeTitle = @"This is a safe comic title.";
    NSString *alt = @"Here's some alt text.";
    NSString *transcript = @"This is the transcript.";
    NSString *imageURLString = @"https://imgs.xkcd.com/comics/456.png";
    NSString *day = @"10";
    NSString *month = @"11";
    NSString *year = @"1988";
    CGFloat aspectRatio = 1.5;

    NSDictionary *comicDict = @{
                                kNumKey: comicID,
                                kTitleKey: title,
                                kSafeTitleKey: safeTitle,
                                kAltKey: alt,
                                kTranscriptKey: transcript,
                                kImageURLStringKey: imageURLString,
                                kDayKey: day,
                                kMonthKey: month,
                                kYearKey: year,
                                kAspectRatioKey: @(aspectRatio)
                                };

    Comic *comic = [Comic comicFromDictionary:comicDict];

    XCTAssertNotNil(comic);
    XCTAssertEqual(comic.num, num);
    XCTAssert([comic.comicID isEqualToString:[comicID stringValue]]);
    XCTAssert([comic.title isEqualToString:title]);
    XCTAssert([comic.safeTitle isEqualToString:safeTitle]);
    XCTAssert([comic.alt isEqualToString:alt]);
    XCTAssert([comic.transcript isEqualToString:transcript]);
    XCTAssert([comic.imageURLString isEqualToString:imageURLString]);
    XCTAssert([comic.day isEqualToString:day]);
    XCTAssert([comic.month isEqualToString:month]);
    XCTAssert([comic.year isEqualToString:year]);
    XCTAssertEqual(comic.aspectRatio, aspectRatio);
    XCTAssertFalse(comic.viewed);

    // Dates are formatted for the user's locale, so build the expected string the same way.
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = 10;
    dateComponents.month = 11;
    dateComponents.year = 1988;
    dateComponents.calendar = [NSCalendar autoupdatingCurrentCalendar];
    NSString *expectedDate = [NSDateFormatter localizedStringFromDate:dateComponents.date dateStyle:NSDateFormatterMediumStyle timeStyle:NSDateFormatterNoStyle];
    XCTAssertEqualObjects(comic.formattedDateString, expectedDate);
}

- (void)testGenerateURLString {
    Comic *comic = [Comic new];

    NSURL *shareURL = [NSURL URLWithString:[Comic generateComicURLStringFromNumber:comic.num]];
    XCTAssertNotNil(shareURL);
    XCTAssert([shareURL.absoluteString isEqualToString:kShareURLBase]);

    comic.num = 666;

    shareURL = [NSURL URLWithString:[Comic generateComicURLStringFromNumber:comic.num]];
    XCTAssertNotNil(shareURL);
    XCTAssert([shareURL.absoluteString isEqualToString:@"https://xkcd.com/666"]);
}

- (void)testInsecureImageURLIsUpgraded {
    Comic *comic = [Comic comicFromDictionary:@{kNumKey: @1, kImageURLStringKey: @"http://imgs.xkcd.com/comics/barrel_cropped_(1).jpg"}];
    XCTAssertEqualObjects(comic.imageURLString, @"https://imgs.xkcd.com/comics/barrel_cropped_(1).jpg");

    XCTAssertEqualObjects([Comic secureURLStringFromURLString:@"https://xkcd.com"], @"https://xkcd.com");
    XCTAssertEqualObjects([Comic secureURLStringFromURLString:@""], @"");
}

- (void)testComicWithNullValues {
    NSDictionary *comicDict = @{
                                kNumKey: [NSNull null],
                                kTitleKey: [NSNull null],
                                kTranscriptKey: [NSNull null],
                                kAspectRatioKey: [NSNull null],
                                kIsInteractiveKey: [NSNull null]
                                };

    Comic *comic = [Comic comicFromDictionary:comicDict];

    XCTAssertEqual(comic.num, 0);
    XCTAssertEqualObjects(comic.title, @"");
    XCTAssertEqualObjects(comic.transcript, @"");
    XCTAssertEqual(comic.aspectRatio, kDefaultAspectRatio);
    XCTAssertFalse(comic.isInteractive);
}

- (void)testComicWithExtraPartsIsInteractive {
    Comic *comic = [Comic comicFromDictionary:@{kNumKey: @1663, kExtraPartsKey: @{@"headerextra": @""}}];
    XCTAssertTrue(comic.isInteractive);

    comic = [Comic comicFromDictionary:@{kNumKey: @1}];
    XCTAssertFalse(comic.isInteractive);
}

@end
