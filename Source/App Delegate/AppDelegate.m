//
//  AppDelegate.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "AppDelegate.h"
#import "DataManager.h"
#import "RequestManager.h"
#import "ComicListViewController.h"
#import "ThemeManager.h"
#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <TwitterKit/TwitterKit.h>
#import "XKCDDeviceManager.h"
#import "Assembler.h"
#import "ImageManager.h"
#import "ReviewManager.h"

@interface AppDelegate ()

@property (nonatomic, strong) Assembler *assembler;

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

    [self setupAssembler];

    [self setupThirdPartyLibraries];
    [self setupPushNotifications];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ComicListViewController new]];;
    [self.window makeKeyAndVisible];

    [self.assembler.reviewManager handleAppLaunched];

    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Whenever the app becomes active clear the badge.
    if (application.applicationIconBadgeNumber > 0) {
        application.applicationIconBadgeNumber = 0;
    }
}


#pragma mark - Assembler setup

- (void)setupAssembler {
    self.assembler = [Assembler sharedInstance];
    self.assembler.dataManager = [[DataManager alloc] initWithAssembler:self.assembler];
    self.assembler.requestManager = [[RequestManager alloc] initWithAssembler:self.assembler];
    self.assembler.imageManager = [ImageManager new];
    self.assembler.reviewManager = [ReviewManager new];
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
    NSString *token = [self.assembler.dataManager tokenStringFromData:deviceToken];
    
    [self.assembler.requestManager sendDeviceToken:token completionHandler:^(NSError *error) {
        if (error) {
            NSLog(@"Sending token to server failed with error: %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.assembler.dataManager performBackgroundFetchWithCompletionHandler:completionHandler];
}

@end
