//
//  Comic.m
//  xkcDump
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "Comic.h"

@implementation Comic


#pragma mark - Initialization

+ (instancetype)comicFromDictionary:(NSDictionary *)dictionary {
    return [[[self class] alloc] initComicWithDictionary:dictionary];;
}

- (instancetype)initComicWithDictionary:(NSDictionary *)dictionary {
    self = [super init];

    self.num = [dictionary[kNumKey] integerValue] ?: -1;
    self.comicID = [dictionary[kNumKey] stringValue] ?: @"-1";
    self.title = dictionary[kTitleKey] ?: @"";
    self.safeTitle = dictionary[kSafeTitleKey] ?: @"";
    self.alt = dictionary[kAltKey] ?: @"";
    self.transcript = dictionary[kTranscriptKey] ?: @"";
    self.imageURLString = dictionary[kImageURLStringKey] ?: @"http://xkcd.com/";
    self.date = [self generateDateFromDay:dictionary[kDayKey] month:dictionary[kMonthKey] year:dictionary[kYearKey]];
    self.aspectRatio = dictionary[kAspectRatioKey] ? [dictionary[kAspectRatioKey] floatValue] : 1.0;
    self.viewed = NO;

    return self;
}

+ (NSString *)primaryKey {
    return @"comicID";
}


#pragma mark - Generating dates

- (NSDate *)generateDateFromDay:(NSString *)day month:(NSString *)month year:(NSString *)year {
    NSDateComponents *components = [NSDateComponents new];

    [components setDay:[day integerValue]];
    [components setMonth:[month integerValue]];
    [components setYear:[year integerValue]];

    return [[NSCalendar currentCalendar] dateFromComponents:components];
}

@end
