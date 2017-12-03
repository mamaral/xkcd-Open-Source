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
static NSString * const ComicFavoritedNotification = @"ComicFavorited";
static NSString * const ComicReadNotification = @"ComicRead";
static NSString * const kComicKey = @"comic";
static NSString * const kReviewPromptDate = @"ReviewPromptDate";
static NSString * const kExplainURLBase = @"http://www.explainxkcd.com";

@interface DataManager : NSObject

@property (nonatomic, strong) RLMRealm *realm;

@property (nonatomic, strong) NSArray *knownInteractiveComicNumbers;


#pragma mark - Singleton

+ (instancetype)sharedInstance;


#pragma mark - Saving / updating comics

- (void)saveComics:(NSArray *)comics;
- (void)markComicViewed:(Comic *)comic;
- (void)markComic:(Comic *)comic favorited:(BOOL)favorited;


#pragma mark - Latest comic info

- (NSInteger)latestComicDownloaded;
- (void)setLatestComicDownloaded:(NSInteger)latest;


#pragma mark - Bookmarked Comic

- (Comic *)bookmarkedComic;
- (NSInteger)bookmarkedComicNumber;
- (void)setBookmarkedComic:(NSInteger)bookmarkedComic;


#pragma mark - Getting comics

- (RLMResults *)allSavedComics;
- (RLMResults *)comicsMatchingSearchString:(NSString *)searchString;
- (RLMResults *)allFavorites;
- (RLMResults *)allUnread;
- (void)downloadLatestComicsWithCompletionHandler:(void (^)(NSError *error, NSInteger numberOfNewComics))handler;
- (void)downloadLatestComicWithCompletionHandler:(void (^)(Comic *comic, BOOL wasNew))handler;


#pragma mark - Background fetching 

- (void)performBackgroundFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;


#pragma mark - Converting token data

- (NSString *)tokenStringFromData:(NSData *)data;


#pragma mark - Randomization

- (NSInteger)randomNumberBetweenMin:(NSUInteger)min andMax:(NSUInteger)max;
- (Comic *)randomComic;


#pragma mark - Reviews

- (NSInteger)appLaunchCount;
- (void)incrementAppLaunchCount;
- (NSDate *)previousReviewPromptDate;
- (void)updateReviewPromptDate;


#pragma mark - Clearing Cache

- (void)clearCache;


#pragma mark - Date utils

- (NSString *)dateStringFromDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;

@end
