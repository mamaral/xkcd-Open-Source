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

- (void)testComicWithDictionary {
    NSDictionary *emptyDict = @{};
    Comic *comicFromEmptyDict = [Comic comicFromDictionary:emptyDict];

    XCTAssertNotNil(comicFromEmptyDict);
    XCTAssert(comicFromEmptyDict.num == -1);
}

@end
