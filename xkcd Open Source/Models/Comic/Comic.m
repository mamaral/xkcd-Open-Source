//
//  Comic.m
//  xkcd Open Source
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
    self.day = dictionary[kDayKey] ?: @"";
    self.month = dictionary[kMonthKey] ?: @"";
    self.year = dictionary[kYearKey] ?: @"";
    self.aspectRatio = dictionary[kAspectRatioKey] ? [dictionary[kAspectRatioKey] floatValue] : 1.0;
    self.viewed = NO;

    NSString *month = self.month.length > 0 ? [[[NSDateFormatter new] monthSymbols] objectAtIndex:([self.month integerValue] - 1)] : @"";
    self.formattedDateString = (month.length > 0 && self.day.length > 0 && self.year.length > 0) ? [NSString stringWithFormat:@"%@ %@,  %@", month, self.day, self.year] : @"";

    return self;
}

+ (NSString *)primaryKey {
    return @"comicID";
}

@end
