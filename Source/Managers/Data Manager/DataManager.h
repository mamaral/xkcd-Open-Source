//
//  DataManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <Realm/Realm.h>
#import "Comic.h"

static NSString * const NewComicsAvailableNotification = @"NewComicsAvailable";

@interface DataManager : NSObject

@property (nonatomic, strong) RLMRealm *realm;


#pragma mark - Singleton

+ (instancetype)sharedInstance;


#pragma mark - Saving / updating comics

- (void)saveComics:(NSArray *)comics;
- (void)markComicViewed:(Comic *)comic;
- (void)markComic:(Comic *)comic favorited:(BOOL)favorited;


#pragma mark - Latest comic info

- (NSInteger)latestComicDownloaded;
- (void)setLatestComicDownloaded:(NSInteger)latest;


#pragma mark - Getting comics

- (RLMResults *)allSavedComics;
- (RLMResults *)comicsMatchingSearchString:(NSString *)searchString;
- (RLMResults *)allFavorites;
- (void)downloadLatestComicsWithCompletionHandler:(void (^)(NSError *error, NSInteger numberOfNewComics))handler;


#pragma mark - Background fetching 

- (void)performBackgroundFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;


#pragma mark - Converting token data

- (NSString *)tokenStringFromData:(NSData *)data;


#pragma mark - Randomization

- (NSInteger)randomNumberBetweenMin:(NSUInteger)min andMax:(NSUInteger)max;
- (Comic *)randomComic;

@end
