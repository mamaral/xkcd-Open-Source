//
//  Comic.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "RLMObject.h"

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
@property NSString *day;
@property NSString *month;
@property NSString *year;
@property NSString *formattedDateString;
@property CGFloat aspectRatio;
@property BOOL viewed;


#pragma mark - Initialization

+ (instancetype)comicFromDictionary:(NSDictionary *)dictionary;

@end
