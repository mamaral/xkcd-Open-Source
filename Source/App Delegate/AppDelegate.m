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

static NSString * const kAppStoreURLString = @"itms-apps://itunes.apple.com/app/id995811425";

static NSString * const kReviewAlertActionEvent = @"Asked To Leave Review";
static NSString * const kLeaveAReviewButtonTitle = @"Leave A Review";
static NSString * const kDontAskAgainButtonTitle = @"No... Leave me alone!";

static NSString * const kReviewAlertTitle = @"Tell us what you think!";
static NSString * const kReviewAlertMessage = @"We worked hard to create the best xkcd comic reader out there, for free AND without adds! It would mean a lot if you'd take a minute and leave some honest feedback about the app. Pretty please?";

static NSTimeInterval const kReviewAlertDelay = 30.0;


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

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ComicListViewController new]];
    [self.window makeKeyAndVisible];

    [self askNicelyForAReviewIfNecessary];

    return YES;
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
    // If we've already asked for a review in the past, don't ask again.
    if ([[DataManager sharedInstance] hasAskedForReview]) {
        return;
    }

    // After a short delay, ask the nice people to leave a review.
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, kReviewAlertDelay * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        UIAlertAction *goToReview = [UIAlertAction actionWithTitle:kLeaveAReviewButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSURL *appStoreURL = [NSURL URLWithString:kAppStoreURLString];
            [[UIApplication sharedApplication] openURL:appStoreURL];

            [self.dataManager setHasAskedForReview:YES];
        }];

        UIAlertAction *dontAskAgain = [UIAlertAction actionWithTitle:kDontAskAgainButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            [self.dataManager setHasAskedForReview:YES];
        }];

        UIAlertController *reviewAlertController = [UIAlertController alertControllerWithTitle:kReviewAlertTitle message:kReviewAlertMessage preferredStyle:[XKCDDeviceManager isPad] ? UIAlertControllerStyleAlert : UIAlertControllerStyleActionSheet];
        [reviewAlertController addAction:goToReview];
        [reviewAlertController addAction:dontAskAgain];

        [self.window.rootViewController presentViewController:reviewAlertController animated:YES completion:nil];
    });
}

@end
