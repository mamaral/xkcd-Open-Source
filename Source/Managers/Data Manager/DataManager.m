//
//  DataManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "DataManager.h"
#import "RequestManager.h"

static NSInteger const kCurrentSchemaVersion = 5;
static NSString * const kLatestComicDownloadedKey = @"LatestComicDownloaded";
static NSString * const kBookmarkedComicKey = @"BookmarkedComic";
static NSString * const kAppLaunchedCountKey = @"AppLaunchedCount";

@interface DataManager ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

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

    self.defaults = [NSUserDefaults standardUserDefaults];

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

                // Set the default bookmark value.
                newObject[@"isBookmark"] = @(NO);

                // Set the explain URL string.
                newObject[@"explainURLString"] = [NSString stringWithFormat:@"%@/%@", kExplainURLBase, comicNumber];
            }];
        }
    };

    // Tell Realm to use this new configuration object for the default Realm.
    [RLMRealmConfiguration setDefaultConfiguration:config];

    self.realm = [RLMRealm defaultRealm];
}


#pragma mark - Saving comics

- (void)saveComics:(NSArray *)comics {
    NSParameterAssert(comics);

    [self.realm beginWriteTransaction];
    [self.realm addOrUpdateObjects:comics];
    [self.realm commitWriteTransaction];
}

- (void)markComicViewed:(Comic *)comic {
    NSParameterAssert(comic);

    [self.realm beginWriteTransaction];
    comic.viewed = YES;
    [self.realm commitWriteTransaction];

    // Broadcast this comic was read.
    [[NSNotificationCenter defaultCenter] postNotificationName:ComicReadNotification object:nil userInfo:@{kComicKey: comic}];
}

- (void)markComic:(Comic *)comic favorited:(BOOL)favorited {
    NSParameterAssert(comic);

    [self.realm beginWriteTransaction];
    comic.favorite = favorited;
    [self.realm commitWriteTransaction];

    // Broadcast this comic was favorited.
    [[NSNotificationCenter defaultCenter] postNotificationName:ComicFavoritedNotification object:nil userInfo:@{kComicKey: comic}];
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
    // Download the latest comics.
    [self downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {

        // If there was an error and we have none saved, there was an issue loading the first batch of
        // comics and we should probably retry after a short delay Otherwise if we have new comics, notify the app that there are more available.
        if (error && [self allSavedComics].count == 0) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                [self handleAppEnteringForeground];
            });
        } else if (numberOfNewComics > 0) {
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
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"comicID == %@ OR title CONTAINS[c] %@ OR alt CONTAINS %@", searchString, searchString, searchString];
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
    // Calculate the starting index.
    NSInteger since = [self latestComicDownloaded];

    // Pass that to our request manager to fetch it.
    [[RequestManager sharedInstance] downloadComicsSince:since completionHandler:^(NSError *error, NSArray *comicDicts) {
        // Error handling
        if (error) {
            handler(error, 0);
            return;
        }

        // Convert the dictionaries to our comic models, also keeping track of the newest
        // latest comic.
        NSMutableArray *comics = [NSMutableArray arrayWithCapacity:comicDicts.count];
        NSInteger latestDownloaded = since;

        for (NSDictionary *comicDict in comicDicts) {
            Comic *comic = [Comic comicFromDictionary:comicDict];
            [comics addObject:comic];

            if (comic.num > latestDownloaded) {
                latestDownloaded = comic.num;
            }
        }

        // Save them in our realm.
        if (comics.count > 0) {
            [self saveComics:comics];
        }

        // Update our latest comic.
        [self setLatestComicDownloaded:latestDownloaded];

        handler(nil, comics.count);
    }];
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
        BOOL newData = numberOfNewComics > 0;

        if (error) {
            completionHandler(UIBackgroundFetchResultFailed);
        } else if (newData) {
            completionHandler(UIBackgroundFetchResultNewData);

            [[NSNotificationCenter defaultCenter] postNotificationName:NewComicsAvailableNotification object:nil];
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    }];
}


#pragma mark - Converting token data

- (NSString *)tokenStringFromData:(NSData *)data {
    if (!data) {
        return @"";
    }

    NSString *token = [NSString stringWithFormat:@"%@", data];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    return token;
}


#pragma mark - Randomization

- (NSInteger)randomNumberBetweenMin:(NSUInteger)min andMax:(NSUInteger)max {
    return (min + arc4random_uniform((u_int32_t)max - (u_int32_t)min + 1));
}

- (Comic *)randomComic {
    RLMResults *allComics = [self allSavedComics];
    NSInteger randomIndex = [self randomNumberBetweenMin:0 andMax:allComics.count - 1];
    return allComics[randomIndex];
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
