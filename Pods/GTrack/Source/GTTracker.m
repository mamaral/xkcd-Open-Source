//
//  GTTracker.m
//  GTrack
//
//  Created by Michael Amaral on 1/23/15.
//  Copyright (c) 2015 Gemr, Inc. All rights reserved.
//

#import "GTTracker.h"

static NSString * kAnalyticsStartSessionKey = @"start";
static NSString * kAnalyticsEndSessionKey = @"end";

@implementation GTTracker

+ (instancetype)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    
    return _sharedObject;
}


#pragma mark - Object life cycle

- (instancetype)init {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.automaticSessionManagementEnabled = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startAnalyticsSession) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endAnalyticsSession) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(endAnalyticsSession) name:UIApplicationWillTerminateNotification object:nil];
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - Initialization

- (void)initializeAnalyticsWithTrackingID:(NSString *)trackingID logLevel:(GAILogLevel)logLevel {
    NSLog(@"[GTrack] GTTracker initialized.");
    
    [[[GAI sharedInstance] logger] setLogLevel:logLevel];
    [[GAI sharedInstance] trackerWithTrackingId:trackingID];
}


#pragma mark - Session management

- (void)startAnalyticsSession {
    if (!self.automaticSessionManagementEnabled) {
        return;
    }
    
    if (self.loggingEnabled) {
        NSLog(@"[GTrack] Starting analytics session.");
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAISessionControl value:kAnalyticsStartSessionKey];
    
    _isSessionActive = YES;
}

- (void)endAnalyticsSession {
    if (!self.automaticSessionManagementEnabled) {
        return;
    }
    
    if (self.loggingEnabled) {
        NSLog(@"[GTrack] Ending analytics session.");
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAISessionControl value:kAnalyticsEndSessionKey];
    
    _isSessionActive = NO;
}


#pragma mark - Screen events

- (void)sendScreenEventWithTitle:(NSString *)title {
    if (self.loggingEnabled) {
        NSLog(@"[GTrack] Dispatched screen event: %@", title);
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:title];
    [tracker send:[[GAIDictionaryBuilder createScreenView] build]];
}


#pragma mark - App events

- (void)sendAnalyticsEventWithCategory:(NSString *)category {
    [self sendAnalyticsEventWithCategory:category action:nil label:nil value:nil];
}

- (void)sendAnalyticsEventWithCategory:(NSString *)category action:(NSString *)action {
    [self sendAnalyticsEventWithCategory:category action:action label:nil value:nil];
}

- (void)sendAnalyticsEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label {
    [self sendAnalyticsEventWithCategory:category action:action label:label value:nil];
}

- (void)sendAnalyticsEventWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label value:(NSNumber *)value {
    if (self.loggingEnabled) {
        NSLog(@"[GTrack] Dispatched event with category: %@, action: %@, label: %@, value: %@", category, action, label, value);
    }
    
    id<GAITracker> tracker = [[GAI sharedInstance] defaultTracker];
    [tracker set:kGAIScreenName value:nil];
    [tracker send:[[GAIDictionaryBuilder createEventWithCategory:category action:action label:label value:value] build]];
}

@end


#pragma mark - Timed events

@implementation GTTimedEvent

+ (instancetype)eventStartingNowWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label {
    return [[[self class] alloc] initWithCategory:category action:action label:label];
}

- (instancetype)initWithCategory:(NSString *)category action:(NSString *)action label:(NSString *)label {
    self = [super init];
    
    if (!self) {
        return nil;
    }
    
    self.category = category;
    self.action = action;
    self.label = label;
    self.eventInterval = [GTInterval intervalWithNowAsStartDate];
    
    return self;
}

- (void)endAndSendWithIntervalUnit:(IntervalUnit)intervalUnit {
    [self.eventInterval end];
    
    NSNumber *intervalValue;
    
    switch (intervalUnit) {
        case IntervalUnitSeconds:
            intervalValue = [self.eventInterval intervalAsSeconds];
            break;
        case IntervalUnitMinutes:
            intervalValue = [self.eventInterval intervalAsMinutes];
            break;
        case IntervalUnitHours:
            intervalValue = [self.eventInterval intervalAsHours];
            break;
    }
    
    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:self.category action:self.action label:self.label value:intervalValue];
}

- (NSString *)debugDescription {
    return @{@"category": self.category ?: @"nil", @"action": self.action ?: @"nil", @"label": self.label ?: @"nil", @"interval": self.eventInterval ?: @"nil"}.description;
}

@end


#pragma mark - Interval tracking

@implementation GTInterval

+ (instancetype)intervalWithNowAsStartDate {
    GTInterval *interval = [GTInterval new];
    interval.startDate = [NSDate date];
    interval.timeInterval = kAnalyticsDefaultTimeInterval;
    return interval;
}

- (void)end {
    self.endDate = [NSDate date];
}

- (void)setEndDate:(NSDate *)endDate {
    _endDate = endDate;
    self.timeInterval = [self.endDate timeIntervalSinceDate:self.startDate];
}

- (NSNumber *)intervalAsSeconds {
    NSString *seconds = [NSString stringWithFormat:@"%.1f", self.timeInterval];
    return @([seconds doubleValue]);
}

- (NSNumber *)intervalAsMinutes {
    NSTimeInterval minutes = self.timeInterval / kAnalyticsSecondsPerMinute;
    NSString *minutesString = [NSString stringWithFormat:@"%.1f", minutes];
    return @([minutesString doubleValue]);
}

- (NSNumber *)intervalAsHours {
    NSTimeInterval hours = self.timeInterval / kAnalyticsSecondsPerHour;
    NSString *hoursString = [NSString stringWithFormat:@"%.1f", hours];
    return @([hoursString doubleValue]);
}

- (NSString *)debugDescription {
    return @{@"startDate": self.startDate ?: @"nil", @"endDate": self.endDate ?: @"nil", @"interval": @(self.timeInterval)}.description;
}

@end
