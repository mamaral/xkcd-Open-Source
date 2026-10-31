//
//  DataManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "DataManager.h"
#import "RequestManager.h"

static NSInteger const kCurrentSchemaVersion = 6;
static NSString * const kLatestComicDownloadedKey = @"LatestComicDownloaded";
static NSString * const kBookmarkedComicKey = @"BookmarkedComic";
static NSString * const kAppLaunchedCountKey = @"AppLaunchedCount";

@interface DataManager ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic) BOOL isDownloadingComics;
@property (nonatomic, strong) NSMutableArray *pendingDownloadHandlers;

@end

@implementation DataManager


#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}


#pragma mark - Initialization

- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.defaults = [NSUserDefaults standardUserDefaults];
    self.pendingDownloadHandlers = [NSMutableArray array];

    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;

    self.knownInteractiveComicNumbers = @[@1193, @1331, @1446, @1525, @1608, @1663];

    [self initializeRealm];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppEnteringForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppEnteringForeground) name:UIApplicationDidFinishLaunchingNotification object:nil];

    return self;
}

- (void)initializeRealm {
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.schemaVersion = kCurrentSchemaVersion;

    config.migrationBlock = ^(RLMMigration *migration, uint64_t oldSchemaVersion) {
        if (oldSchemaVersion < kCurrentSchemaVersion) {
            [migration enumerateObjects:Comic.className block:^(RLMObject *oldObject, RLMObject *newObject) {

                // Ensure we flag known interactive comics as such.
                NSNumber *comicNumber = oldObject[@"num"];
                newObject[@"isInteractive"] = @([self.knownInteractiveComicNumbers containsObject:comicNumber]);

                // Generate the URL string for the comic.
                newObject[@"comicURLString"] = [Comic generateComicURLStringFromNumber:[comicNumber integerValue]];

                // Set the explain URL string.
                newObject[@"explainURLString"] = [NSString stringWithFormat:@"%@/%@", kExplainURLBase, comicNumber];

                // Older comics may have been saved with insecure image URLs, which ATS now blocks.
                newObject[@"imageURLString"] = [Comic secureURLStringFromURLString:oldObject[@"imageURLString"]];
            }];
        }
    };

    // Tell Realm to use this new configuration object for the default Realm.
    [RLMRealmConfiguration setDefaultConfiguration:config];

    self.realm = [RLMRealm defaultRealm];
}


#pragma mark - Saving comics

- (NSInteger)saveComics:(NSArray *)comics {
    NSParameterAssert(comics);

    // Skip comics we already have, otherwise we'd reset their viewed and favorite state.
    NSMutableArray *newComics = [NSMutableArray arrayWithCapacity:comics.count];
    for (Comic *comic in comics) {
        if (![Comic objectForPrimaryKey:comic.comicID]) {
            [newComics addObject:comic];
        }
    }

    if (newComics.count == 0) {
        return 0;
    }

    [self.realm transactionWithBlock:^{
        [self.realm addOrUpdateObjects:newComics];
    }];

    return newComics.count;
}

- (void)markComicViewed:(Comic *)comic {
    // The comic may have been deleted out from under us, e.g. by clearing the cache.
    if (!comic || comic.isInvalidated) {
        return;
    }

    [self.realm beginWriteTransaction];
    comic.viewed = YES;
    [self.realm commitWriteTransaction];

    // Broadcast this comic was read.
    [[NSNotificationCenter defaultCenter] postNotificationName:ComicReadNotification object:nil userInfo:@{kComicKey: comic}];
}

- (void)markComic:(Comic *)comic favorited:(BOOL)favorited {
    // The comic may have been deleted out from under us, e.g. by clearing the cache.
    if (!comic || comic.isInvalidated) {
        return;
    }

    [self.realm beginWriteTransaction];
    comic.favorite = favorited;
    [self.realm commitWriteTransaction];

    // Broadcast this comic was favorited.
    [[NSNotificationCenter defaultCenter] postNotificationName:ComicFavoritedNotification object:nil userInfo:@{kComicKey: comic}];
}

- (void)updateAspectRatio:(CGFloat)aspectRatio forComic:(Comic *)comic {
    // xkcd doesn't tell us image dimensions, so we record them once we've loaded the image.
    if (!comic || comic.isInvalidated || aspectRatio <= 0 || fabs(comic.aspectRatio - aspectRatio) < 0.01) {
        return;
    }

    if (comic.realm) {
        [self.realm transactionWithBlock:^{
            comic.aspectRatio = aspectRatio;
        }];
    } else {
        comic.aspectRatio = aspectRatio;
    }
}


#pragma mark - Latest comic info

- (NSInteger)latestComicDownloaded {
    return [self.defaults integerForKey:kLatestComicDownloadedKey];
}

- (void)setLatestComicDownloaded:(NSInteger)latest {
    [self.defaults setInteger:latest forKey:kLatestComicDownloadedKey];
}


#pragma mark - Bookmarked Comic

- (Comic *)bookmarkedComic {
    NSInteger number = [self bookmarkedComicNumber];
    NSString *primaryKey = [NSString stringWithFormat:@"%ld", (long)number];
    return [Comic objectForPrimaryKey:primaryKey];
}

- (NSInteger)bookmarkedComicNumber {
    return [self.defaults integerForKey:kBookmarkedComicKey];
}

- (void)setBookmarkedComic:(NSInteger)bookmarkedComic {
    [self.defaults setInteger:bookmarkedComic forKey:kBookmarkedComicKey];
}


#pragma mark - App life cycle handling

- (void)handleAppEnteringForeground {
    // Download any comics we're missing. If this fails we'll try again the next time we come to the
    // foreground, and the comic list lets the user retry if the initial load fails.
    [self downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        if (numberOfNewComics > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NewComicsAvailableNotification object:nil];
        }
    }];
}


#pragma mark - Fetching comics

- (RLMResults *)allSavedComics {
    RLMResults *allComics = [Comic allObjects];
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithKeyPath:@"num" ascending:NO];
    return [allComics sortedResultsUsingDescriptors:@[sortDescriptor]];
}

- (RLMResults *)comicsMatchingSearchString:(NSString *)searchString {
    searchString = searchString ?: @"";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"comicID == %@ OR title CONTAINS[c] %@ OR alt CONTAINS[c] %@", searchString, searchString, searchString];
    RLMResults *matchingComics = [Comic objectsWithPredicate:predicate];
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithKeyPath:@"num" ascending:NO];
    return [matchingComics sortedResultsUsingDescriptors:@[sortDescriptor]];
}

- (RLMResults *)allFavorites {
    RLMResults *unsorted = [Comic objectsWithPredicate:[NSPredicate predicateWithFormat:@"favorite == YES"]];
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithKeyPath:@"num" ascending:NO];
    return [unsorted sortedResultsUsingDescriptors:@[sortDescriptor]];
}

- (RLMResults *)allUnread {
    RLMResults *unsorted = [Comic objectsWithPredicate:[NSPredicate predicateWithFormat:@"viewed == NO"]];
    RLMSortDescriptor *sortDescriptor = [RLMSortDescriptor sortDescriptorWithKeyPath:@"num" ascending:NO];
    return [unsorted sortedResultsUsingDescriptors:@[sortDescriptor]];
}

- (void)downloadLatestComicsWithCompletionHandler:(void (^)(NSError *error, NSInteger numberOfNewComics))handler {
    // If a download is already running, wait for it to finish rather than starting another.
    if (handler) {
        [self.pendingDownloadHandlers addObject:[handler copy]];
    }

    if (self.isDownloadingComics) {
        return;
    }

    self.isDownloadingComics = YES;

    RequestManager *requestManager = [RequestManager sharedInstance];

    [requestManager downloadLatestComicWithCompletionHandler:^(NSError *error, NSDictionary *latestComicDict) {
        if (error) {
            [self finishDownloadingComicsWithError:error numberOfNewComics:0];
            return;
        }

        // Rather than only fetching comics newer than the last one we downloaded, fetch every one we
        // don't have, so any gaps left by failed requests get filled in next time.
        Comic *latestComic = [Comic comicFromDictionary:latestComicDict];
        NSMutableArray *numbersToDownload = [[self missingComicNumbersUpTo:latestComic.num] mutableCopy];

        // We already have the latest comic from this request, no need to fetch it again.
        BOOL isLatestComicNew = [numbersToDownload containsObject:@(latestComic.num)];
        [numbersToDownload removeObject:@(latestComic.num)];

        [requestManager downloadComicsWithNumbers:numbersToDownload completionHandler:^(NSError *error, NSArray *comicDicts) {
            NSMutableArray *comics = [NSMutableArray arrayWithCapacity:comicDicts.count + 1];

            if (isLatestComicNew) {
                [comics addObject:latestComic];
            }

            for (NSDictionary *comicDict in comicDicts) {
                [comics addObject:[Comic comicFromDictionary:comicDict]];
            }

            NSInteger numberOfNewComics = [self saveComics:comics];

            if (latestComic.num > [self latestComicDownloaded]) {
                [self setLatestComicDownloaded:latestComic.num];
            }

            [self finishDownloadingComicsWithError:error numberOfNewComics:numberOfNewComics];
        }];
    }];
}

- (void)finishDownloadingComicsWithError:(NSError *)error numberOfNewComics:(NSInteger)numberOfNewComics {
    NSArray *handlers = [self.pendingDownloadHandlers copy];
    [self.pendingDownloadHandlers removeAllObjects];
    self.isDownloadingComics = NO;

    for (void (^handler)(NSError *, NSInteger) in handlers) {
        handler(error, numberOfNewComics);
    }
}

- (NSArray<NSNumber *> *)missingComicNumbersUpTo:(NSInteger)latest {
    NSMutableIndexSet *missingNumbers = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(1, MAX(latest, 0))];
    [missingNumbers removeIndex:kMissingComicNumber];

    for (Comic *comic in [Comic allObjects]) {
        if (comic.num > 0) {
            [missingNumbers removeIndex:comic.num];
        }
    }

    // Newest first.
    NSMutableArray *numbers = [NSMutableArray arrayWithCapacity:missingNumbers.count];
    [missingNumbers enumerateIndexesWithOptions:NSEnumerationReverse usingBlock:^(NSUInteger number, BOOL *stop) {
        [numbers addObject:@(number)];
    }];

    return numbers;
}

- (void)downloadLatestComicWithCompletionHandler:(void (^)(Comic *comic, BOOL wasNew))handler {
    [[RequestManager sharedInstance] downloadLatestComicWithCompletionHandler:^(NSError *error, NSDictionary *latestComic) {
        if (error || !latestComic) {
            handler(nil, NO);
            return;
        }

        Comic *latest = [Comic comicFromDictionary:latestComic];

        BOOL wasNew = [self latestComicDownloaded] < latest.num;
        [self setLatestComicDownloaded:latest.num];

        handler(latest, wasNew);
    }];
}


#pragma mark - Background fetching

- (void)performBackgroundFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Download all of the latest comics.
    [self downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        // Some comics may have downloaded even if others failed, so check for new data first.
        if (numberOfNewComics > 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:NewComicsAvailableNotification object:nil];

            completionHandler(UIBackgroundFetchResultNewData);
        } else if (error) {
            completionHandler(UIBackgroundFetchResultFailed);
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
}


#pragma mark - Randomization

- (NSInteger)randomNumberBetweenMin:(NSUInteger)min andMax:(NSUInteger)max {
    return (min + arc4random_uniform((u_int32_t)max - (u_int32_t)min + 1));
}

- (Comic *)randomComic {
    RLMResults *allComics = [self allSavedComics];

    if (allComics.count == 0) {
        return nil;
    }

    return allComics[arc4random_uniform((u_int32_t)allComics.count)];
}


#pragma mark - Reviews

- (NSInteger)appLaunchCount {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kAppLaunchedCountKey];
}

- (void)incrementAppLaunchCount {
    NSInteger newAppLaunchCount = [self appLaunchCount] + 1;
    [[NSUserDefaults standardUserDefaults] setInteger:newAppLaunchCount forKey:kAppLaunchedCountKey];
}

- (NSDate *)previousReviewPromptDate {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kReviewPromptDate];
}

- (void)updateReviewPromptDate {
    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:kReviewPromptDate];
}


#pragma mark - Clearing Cache

- (void)clearCache {
    [self setBookmarkedComic:0];
    [self setLatestComicDownloaded:0];
    [self.realm transactionWithBlock:^{
        [self.realm deleteAllObjects];
    }];
}


#pragma mark - Date utils

- (NSString *)dateStringFromDay:(NSInteger)day month:(NSInteger)month year:(NSInteger)year {
    NSDateComponents *dateComponents = [NSDateComponents new];
    dateComponents.day = day;
    dateComponents.month = month;
    dateComponents.year = year;
    dateComponents.calendar = [NSCalendar autoupdatingCurrentCalendar];
    return [self.dateFormatter stringFromDate:dateComponents.date];
}

@end
