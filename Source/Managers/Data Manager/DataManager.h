//
//  DataManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Realm/Realm.h>

@class Comic;

// TODO: Refactor this class.

static NSString * const ComicListUpdatedNotification = @"ComicListUpdated";
static NSString * const ComicSyncFailedNotification = @"ComicSyncFailed";
static NSString * const ComicFavoritedNotification = @"ComicFavorited";
static NSString * const ComicReadNotification = @"ComicRead";
static NSString * const kComicKey = @"comic";
static NSString * const kHasAskedForReviewKey = @"HasAskedForReview";
static NSString * const kExplainURLBase = @"http://www.explainxkcd.com";

@interface DataManager : NSObject

@property (nonatomic, strong) RLMRealm *realm;

@property (nonatomic, strong) NSArray *knownInteractiveComicNumbers;

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

#pragma mark - Syncinc comics

- (void)syncComics;

#pragma mark - Converting token data

- (NSString *)tokenStringFromData:(NSData *)data;

#pragma mark - Randomization

- (NSInteger)randomNumberBetweenMin:(NSUInteger)min andMax:(NSUInteger)max;
- (Comic *)randomComic;

#pragma mark - Date utils

- (NSString *)dateStringFromDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year;

@end
