//
//  ApplicationController.m
//  xkcd Open Source
//
//  Created by Mike on 6/11/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import "ApplicationController.h"
#import "Assembler.h"
#import "DataManager.h"
#import "ReviewManager.h"
#import "RequestManager.h"
#import "ImageManager.h"
#import "ThemeManager.h"

#import <Fabric/Fabric.h>
#import <Crashlytics/Crashlytics.h>
#import <TwitterKit/TwitterKit.h>

static NSString * const kTokenPostURLString = @"http://xkcdos.app.sgnl24.com/register-push.php";

@interface ApplicationController ()

@property (nonatomic, strong) Assembler *assembler;

@end

@implementation ApplicationController

#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (void)handleAppLaunch {
    // Setup the assembler.
    [self assemble];

    // Setup third-party libs.
    [self setupThirdPartyLibraries];

    // Setup the application theme.
    [ThemeManager setupTheme];

    // Tell the review manager to handle the app launched.
    [self.assembler.reviewManager handleAppLaunched];

    // Register for app life cycle notifications.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

    // Kick off downloading the latest comics now.
    [self.assembler.dataManager syncComics];
}

- (void)assemble {
    self.assembler = [Assembler sharedInstance];
    self.assembler.dataManager = [DataManager new];
    self.assembler.requestManager = [RequestManager new];
    self.assembler.imageManager = [ImageManager new];
    self.assembler.reviewManager = [ReviewManager new];
}

- (void)handleAppWillEnterForeground {
    [self.assembler.dataManager syncComics];
}

#pragma mark - Third-party library setup

- (void)setupThirdPartyLibraries {
    [Fabric with:@[CrashlyticsKit, TwitterKit]];
}

#pragma mark - Loading dismissal

- (void)handleLoadingViewDismissed {
    // We want to hold off prompting the user for push permissions until dismissing the loading view
    // so they get a chance to see the cool loading GIF and aren't bombarded with all sorts of popups
    // during their firs tapp launch.
    [[UIApplication sharedApplication] registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:(UIUserNotificationTypeSound | UIUserNotificationTypeAlert | UIUserNotificationTypeBadge) categories:nil]];
}

#pragma mark - Push notifications

- (void)handlePushRegistrationWithTokenData:(NSData *)data {
    NSString *token = [self.assembler.dataManager tokenStringFromData:data];
    NSDictionary *params = @{@"token": token};

    [self.assembler.requestManager sendPOSTRequestToURL:kTokenPostURLString params:params handler:^(NSError * _Nullable error, id  _Nullable responseObject) {
        
    }];
}

@end
