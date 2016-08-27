//
//  AppDelegate.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DataManager.h"
#import "RequestManager.h"

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong) RequestManager *requestManager;
@property (nonatomic, strong) DataManager *dataManager;

+ (instancetype)sharedAppDelegate;

@end

