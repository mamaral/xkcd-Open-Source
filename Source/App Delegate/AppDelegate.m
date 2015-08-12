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
#import <GTTracker.h>
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>

static NSString * const kAnalyticsTrackingID = @"UA-63011163-1";

@interface AppDelegate ()

@end

@implementation AppDelegate


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

    return YES;
}


#pragma mark - Third-party library setup

- (void)setupThirdPartyLibraries {
    [ThemeManager setupTheme];
    [Fabric with:@[CrashlyticsKit]];
    [[GTTracker sharedInstance] initializeAnalyticsWithTrackingID:kAnalyticsTrackingID logLevel:kGAILogLevelError];
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
            
            [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Token Request Failed" action:error.localizedDescription];
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.dataManager performBackgroundFetchWithCompletionHandler:completionHandler];
}

@end
