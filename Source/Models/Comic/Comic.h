//
//  Comic.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "Realm/Realm.h"

#import <UIKit/UIKit.h>

static NSString * const kNumKey = @"num";
static NSString * const kTitleKey = @"title";
static NSString * const kSafeTitleKey = @"safe_title";
static NSString * const kAltKey = @"alt";
static NSString * const kTranscriptKey = @"transcript";
static NSString * const kImageURLStringKey = @"img";
static NSString * const kDayKey = @"day";
static NSString * const kMonthKey = @"month";
static NSString * const kYearKey = @"year";
static NSString * const kAspectRatioKey = @"img_aspect_ratio";
static NSString * const kIsInteractiveKey = @"isInteractive";

static NSString * const kShareURLBase = @"http://xkcd.com";

static NSInteger kDefaultComicNum = 0;
static CGFloat const kDefaultAspectRatio = 1.0;

@interface Comic : RLMObject

@property NSInteger num;
@property NSString *comicID;
@property NSString *title;
@property NSString *safeTitle;
@property NSString *alt;
@property NSString *transcript;
@property NSString *imageURLString;
@property NSString *comicURLString;
@property NSString *day;
@property NSString *month;
@property NSString *year;
@property NSString *formattedDateString;
@property NSString *explainURLString;
@property CGFloat aspectRatio;
@property BOOL viewed;
@property BOOL favorite;
@property BOOL isInteractive;

@property (nonatomic) BOOL isBookmark;


#pragma mark - Initialization

+ (instancetype)comicFromDictionary:(NSDictionary *)dictionary;


#pragma mark - Comic URL Generation

+ (NSString *)generateComicURLStringFromNumber:(NSInteger)number;


#pragma mark - Test utilities

+ (NSDictionary *)comicDictForTestsWithID:(NSInteger)comicID;

@end
