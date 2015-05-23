//
//  StubManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/22/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface StubManager : NSObject

+ (instancetype)sharedInstance;

- (void)stubResponseWithStatusCode:(int)statusCode object:(id)object delay:(NSTimeInterval)delay;
- (void)removeAllStubs;

@end
