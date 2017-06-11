//
//  ApplicationController.h
//  xkcd Open Source
//
//  Created by Mike on 6/11/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ApplicationController : NSObject

- (void)handleAppLaunch;

- (void)handlePushRegistrationWithTokenData:(NSData *)data;

@end
