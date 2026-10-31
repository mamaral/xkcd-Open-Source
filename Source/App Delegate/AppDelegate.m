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

@import StoreKit;
@import UserNotifications;

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

    // When hosting unit tests, don't set up the UI or start downloading comics, as that would
    // interfere with the tests' own stubbed requests.
    if ([NSProcessInfo processInfo].environment[@"XCTestConfigurationFilePath"]) {
        self.window.rootViewController = [UIViewController new];
        [self.window makeKeyAndVisible];
        return YES;
    }

    if (application.applicationIconBadgeNumber > 0) {
        application.applicationIconBadgeNumber = 0;
    }

    self.dataManager = [DataManager sharedInstance];
    self.requestManager = [RequestManager sharedInstance];

    [ThemeManager setupTheme];
    [self setupBackgroundFetch];

    self.window.rootViewController = [[UINavigationController alloc] initWithRootViewController:[ComicListViewController new]];
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


#pragma mark - Background fetch

- (void)setupBackgroundFetch {
    [[UIApplication sharedApplication] setMinimumBackgroundFetchInterval:UIApplicationBackgroundFetchIntervalMinimum];

    // We let people know about new comics with local notifications, posted after a background fetch.
    [[UNUserNotificationCenter currentNotificationCenter] requestAuthorizationWithOptions:(UNAuthorizationOptionAlert | UNAuthorizationOptionBadge) completionHandler:^(BOOL granted, NSError *error) {
        if (error) {
            NSLog(@"Requesting notification authorization failed with error: %@", error);
        }
    }];
}

- (void)application:(UIApplication *)application performFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    [self.dataManager performBackgroundFetchWithCompletionHandler:^(UIBackgroundFetchResult result) {
        if (result == UIBackgroundFetchResultNewData && application.applicationState != UIApplicationStateActive) {
            [self notifyAboutNewComic:[[self.dataManager allSavedComics] firstObject]];
        }

        completionHandler(result);
    }];
}

- (void)notifyAboutNewComic:(Comic *)comic {
    if (!comic) {
        return;
    }

    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.body = [NSString stringWithFormat:NSLocalizedString(@"notification.new comic", nil), comic.title];
    content.badge = @1;

    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:comic.comicID content:content trigger:nil];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request withCompletionHandler:nil];
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
