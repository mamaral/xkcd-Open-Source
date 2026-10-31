//
//  Comic.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "Comic.h"
#import "DataManager.h"

// The JSON can contain nulls, or numbers where we expect strings, so coerce anything unexpected.
static NSString *StringFromJSONValue(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    if ([value isKindOfClass:[NSNumber class]]) {
        return [value stringValue];
    }

    return @"";
}

@implementation Comic


#pragma mark - Initialization

+ (instancetype)comicFromDictionary:(NSDictionary *)dictionary {
    return [[[self class] alloc] initComicWithDictionary:dictionary];
}

- (instancetype)initComicWithDictionary:(NSDictionary *)dictionary {
    self = [super init];

    id num = dictionary[kNumKey];
    id aspectRatio = dictionary[kAspectRatioKey];
    id isInteractive = dictionary[kIsInteractiveKey];

    self.num = [num respondsToSelector:@selector(integerValue)] ? [num integerValue] : kDefaultComicNum;
    self.comicID = [NSString stringWithFormat:@"%ld", (long)self.num];
    self.title = StringFromJSONValue(dictionary[kTitleKey]);
    self.safeTitle = StringFromJSONValue(dictionary[kSafeTitleKey]);
    self.alt = StringFromJSONValue(dictionary[kAltKey]);
    self.transcript = StringFromJSONValue(dictionary[kTranscriptKey]);
    self.imageURLString = [[self class] secureURLStringFromURLString:StringFromJSONValue(dictionary[kImageURLStringKey])];
    self.day = StringFromJSONValue(dictionary[kDayKey]);
    self.month = StringFromJSONValue(dictionary[kMonthKey]);
    self.year = StringFromJSONValue(dictionary[kYearKey]);
    self.aspectRatio = ([aspectRatio respondsToSelector:@selector(floatValue)] && [aspectRatio floatValue] > 0) ? [aspectRatio floatValue] : kDefaultAspectRatio;
    self.viewed = NO;
    self.favorite = NO;

    // xkcd's JSON includes "extra_parts" for comics with interactive content.
    self.isInteractive = ([isInteractive respondsToSelector:@selector(boolValue)] && [isInteractive boolValue]) || [dictionary[kExtraPartsKey] isKindOfClass:[NSDictionary class]];
    self.explainURLString = [NSString stringWithFormat:@"%@/%@", kExplainURLBase, @(self.num)];

    NSInteger day = [self.day integerValue];
    NSInteger month = [self.month integerValue];
    NSInteger year = [self.year integerValue];

    self.formattedDateString = year > 0 ? ([[DataManager sharedInstance] dateStringFromDay:day month:month year:year] ?: @"") : @"";

    self.comicURLString = [[self class] generateComicURLStringFromNumber:self.num];

    return self;
}

+ (NSString *)primaryKey {
    return @"comicID";
}

+ (NSArray *)ignoredProperties {
    // Bookmarks are stored in user defaults, see the custom getter below.
    return @[@"isBookmark"];
}


#pragma mark - Comic URL Generation

+ (NSString *)generateComicURLStringFromNumber:(NSInteger)number {
    return number > 0 ? [NSString stringWithFormat:@"%@/%ld", kShareURLBase, (long)number] : kShareURLBase;
}

+ (NSString *)secureURLStringFromURLString:(NSString *)urlString {
    if ([urlString hasPrefix:@"http://"]) {
        return [@"https://" stringByAppendingString:[urlString substringFromIndex:@"http://".length]];
    }

    return urlString;
}


#pragma mark - Custom Getters

- (BOOL)isBookmark {
    return [[DataManager sharedInstance] bookmarkedComicNumber] == self.num;
}


#pragma mark - Test utilities

+ (NSDictionary *)comicDictForTestsWithID:(NSInteger)comicID {
    NSInteger rand = arc4random_uniform(5000);
    return @{
             kNumKey: @(comicID),
             kTitleKey: [NSString stringWithFormat:@"Title%ld", (long)rand],
             kSafeTitleKey: [NSString stringWithFormat:@"Safe Title%ld", (long)rand],
             kAltKey: [NSString stringWithFormat:@"Alt%ld", (long)rand],
             kTranscriptKey: [NSString stringWithFormat:@"Transcript%ld", (long)rand],
             kImageURLStringKey: [NSString stringWithFormat:@"www.xkcd.com/comics/%ld", (long)rand],
             kDayKey: [NSString stringWithFormat:@"%ld", (long)(arc4random_uniform(30) + 1)],
             kMonthKey: [NSString stringWithFormat:@"%ld", (long)(arc4random_uniform(11) + 1)],
             kYearKey: [NSString stringWithFormat:@"%ld", (long)(arc4random_uniform(1983) + 1)],
             kAspectRatioKey: @(rand + 1)
             };
}

@end
