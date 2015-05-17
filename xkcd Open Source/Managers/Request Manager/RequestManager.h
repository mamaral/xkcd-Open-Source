//
//  RequestManager.h
//  xkcDump
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking.h>
#import "Comic.h"

@interface RequestManager : NSObject

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;


#pragma mark - Singleton

+ (instancetype)sharedInstance;


#pragma mark - Downloading comics

- (void)downloadComicsStartingAtIndex:(NSInteger)startingIndex completionHandler:(void (^)(NSError *error, NSArray *comicDicts))handler;


#pragma mark - Device tokens

- (void)sendDeviceToken:(NSString *)token completionHandler:(void (^)(NSError *error))handler;

@end
