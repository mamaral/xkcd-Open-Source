//
//  AppDelegate.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "AppDelegate.h"
#import "ComicListViewController.h"
#import "ThemeManager.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <TwitterKit/TwitterKit.h>
#import "XKCDDeviceManager.h"

@import StoreKit;

static NSString * const kAppStoreURLString = @"itms-apps://itunes.apple.com/app/id995811425";

static NSUInteger const kMinAppLaunchCountForReview = 3;
static NSTimeInterval const kReviewAlertDelay = 30.0;
static NSTimeInterval const kFourMonthsInSeconds = 10368000;

@interface AppDelegate ()

@end

@implementation AppDelegate

+ (instancetype)sharedAppDelegate {
    return (AppDelegate *)[[UIApplication sharedApplication] delegate];
}


#pragma mark - App life cycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];

    if (application.applicationIconBadgeNumber > 0) {
        application.applicationIconBadgeNumber = 0;
    }

    self.dataManager = [DataManager sharedInstance];
    self.requestManager = [RequestManager sharedInstance];

    [self setupThirdPartyLibraries];
    [self setupPushNotifications];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ComicListViewController new]];;
    [self.window makeKeyAndVisible];

    [self.dataManager incrementAppLaunchCount];

    // Only ask for reviews if the've launched the app at least a few times.
    if ([self.dataManager appLaunchCount] >= kMinAppLaunchCountForReview) {
        [self askNicelyForAReviewIfNecessary];
    }

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Whenever the app becomes active clear the badge.
    if (application.applicationIconBadgeNumber > 0) {
        application.applicationIconBadgeNumber = 0;
    }
}


#pragma mark - Third-party library setup

- (void)setupThirdPartyLibraries {
    [ThemeManager setupTheme];
    [Fabric with:@[CrashlyticsKit, TwitterKit]];
}


#pragma mark - Push notifications

- (void)setupPushNotifications {
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
}

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [application registerForRemoteNotifications];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *token = [[DataManager sharedInstance] tokenStringFromData:deviceToken];
    
    [self.requestManager sendDeviceToken:token completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Sending token to server failed with error: %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.dataManager performBackgroundFetchWithCompletionHandler:completionHandler];
}


#pragma mark - Annoying review stuff

- (void)askNicelyForAReviewIfNecessary {
    // If we've already asked for a review in the past 4 months, bail.
    NSDate *previousReviewDate = [[DataManager sharedInstance] previousReviewPromptDate];
    if (previousReviewDate && [[NSDate date] timeIntervalSinceDate:previousReviewDate] < kFourMonthsInSeconds) {
        return;
    }

    // After a short delay, prompt users for a rating and update our date so we don't ask again for another 4 months.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kReviewAlertDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        if (@available(iOS 11.0, *)) {
            [SKStoreReviewController requestReview];
            [[DataManager sharedInstance] updateReviewPromptDate];
        }
    });
}

@end
