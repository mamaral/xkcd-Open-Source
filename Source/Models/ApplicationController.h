//
//  ApplicationController.h
//  xkcd Open Source
//
//  Created by Mike on 6/11/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApplicationController : NSObject

+ (instancetype)sharedInstance;

- (void)handleAppLaunch;

- (void)handleLoadingViewDismissed;

- (void)handlePushRegistrationWithTokenData:(NSData *)data;

@end
