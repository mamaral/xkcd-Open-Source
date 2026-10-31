//
//  RequestManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Comic.h"

static NSString * const kRequestManagerErrorDomain = @"Request Manager";
static NSString * const kRequestManagerUserInfoKey = @"error";
static NSString * const kRequestManagerInvalidResponseErrorMessage = @"The server returned an unexpected response.";

static NSInteger const kRequestManagerErrorCode = -1;

// xkcd skipped comic #404, so there's never anything to fetch for it.
static NSInteger const kMissingComicNumber = 404;

@interface RequestManager : NSObject

@property (nonatomic, strong) NSURLSession *session;


#pragma mark - Singleton

+ (instancetype)sharedInstance;


#pragma mark - Downloading comics

- (void)downloadLatestComicWithCompletionHandler:(void (^)(NSError *error, NSDictionary *latestComic))handler;

// Downloads the given comics, a few at a time. The handler is called once every request has
// finished, with whichever comics succeeded and the first error encountered, if any.
- (void)downloadComicsWithNumbers:(NSArray<NSNumber *> *)numbers completionHandler:(void (^)(NSError *error, NSArray *comicDicts))handler;

@end
