//
//  ReviewManager.m
//  xkcd Open Source
//
//  Created by Mike on 4/10/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import "ReviewManager.h"

#import <StoreKit/StoreKit.h>

NS_ASSUME_NONNULL_BEGIN

static NSString * const kAppVersionKey = @"CFBundleShortVersionString";

static NSUInteger const kAppLaunchReviewThreshold = 6;

static NSTimeInterval const kReviewAlertDelay = 15.0;

@interface ReviewManager ()

@property (nonatomic, strong) NSString *currentAppVersion;
@property (nonatomic, strong) NSUserDefaults *defaults;

@end

@implementation ReviewManager

- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.defaults = [NSUserDefaults standardUserDefaults];
    self.currentAppVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:kAppVersionKey];

    return self;
}

- (void)handleAppLaunched {
    // If we've already prompted for this version, bail early.
    if ([self hasAlreadyPromptedForReviewForCurrentVersion]) {
        return;
    }

    // First we need to get the current number of launches for this version
    NSUInteger launchCount = [self updateLaunchCountForCurrentVersion];

    // If we're at our threshold, prompt the user for a review after a delay.
    if (launchCount == kAppLaunchReviewThreshold) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kReviewAlertDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [SKStoreReviewController requestReview];
        });
    }
}

/**
 * Whether or not we have already prompted this user to leave a review
 * for the current version of the app.
 */
- (BOOL)hasAlreadyPromptedForReviewForCurrentVersion {
    return [self previousLaunchCount] >= kAppLaunchReviewThreshold;
}

/**
 * Returns the number of prior launches for the current app version.
 */
- (NSUInteger)previousLaunchCount {
    return [self.defaults integerForKey:self.currentAppVersion];
}

/**
 * Increments and returns the updated launch count for the current version.
 */
- (NSUInteger)updateLaunchCountForCurrentVersion {
    NSUInteger newLaunchCount = [self previousLaunchCount] + 1;
    [self.defaults setInteger:newLaunchCount forKey:self.currentAppVersion];
    return newLaunchCount;
}

@end

NS_ASSUME_NONNULL_END
