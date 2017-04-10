//
//  DataManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "DataManager.h"
#import "RequestManager.h"
#import "Assembler.h"
#import "Comic.h"
#import "ImageManager.h"

static NSInteger const kCurrentSchemaVersion = 7;
static NSString * const kLatestComicDownloadedKey = @"LatestComicDownloaded";
static NSString * const kBookmarkedComicKey = @"BookmarkedComic";

@interface DataManager ()

@property (nonatomic, strong) Assembler *assembler;

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation DataManager

#pragma mark - Initialization

- (instancetype)initWithAssembler:(Assembler *)assembler {
    NSParameterAssert(assembler);

    self = [super init];

    if (!self) {
        return nil;
    }

    self.assembler = assembler;

    self.defaults = [NSUserDefaults standardUserDefaults];

    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;

    self.knownInteractiveComicNumbers = @[@1193, @1331, @1446, @1525, @1608, @1663];

    [self initializeRealm];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleAppEnteringForeground) name:UIApplicationWillEnterForegroundNotification object:nil];

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
    [self.realm addOrUpdateObjectsFromArray:comics];
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
    return [[Comic allObjects] sortedResultsUsingKeyPath:@"num" ascending:NO];
}

- (RLMResults *)comicsMatchingSearchString:(NSString *)searchString {
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"comicID == %@ OR title CONTAINS[c] %@ OR alt CONTAINS %@", searchString, searchString, searchString];
    return [[Comic objectsWithPredicate:searchPredicate] sortedResultsUsingKeyPath:@"num" ascending:NO];
}

- (RLMResults *)allFavorites {
    NSPredicate *favoritedPredicate = [NSPredicate predicateWithFormat:@"favorite == YES"];
    return [[Comic objectsWithPredicate:favoritedPredicate] sortedResultsUsingKeyPath:@"num" ascending:NO];
}

- (RLMResults *)allUnread {
    NSPredicate *unreadPredicate = [NSPredicate predicateWithFormat:@"viewed == NO"];
    return [[Comic objectsWithPredicate:unreadPredicate] sortedResultsUsingKeyPath:@"num" ascending:NO];
}

- (void)downloadLatestComicsWithCompletionHandler:(void (^)(NSError *error, NSInteger numberOfNewComics))handler {
    // Calculate the starting index.
    NSInteger since = [self latestComicDownloaded];

    // Pass that to our request manager to fetch it.
    [self.assembler.requestManager downloadComicsSince:since completionHandler:^(NSError *error, NSArray *comicDicts) {
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

    if (allComics.count == 0) {
        return nil;
    }

    NSInteger randomIndex = [self randomNumberBetweenMin:0 andMax:allComics.count - 1];
    return allComics[randomIndex];
}


#pragma mark - Reviews

- (BOOL)hasAskedForReview {
    return [self.defaults boolForKey:kHasAskedForReviewKey];
}

- (void)setHasAskedForReview:(BOOL)hasAsked {
    [self.defaults setBool:hasAsked forKey:kHasAskedForReviewKey];
}


#pragma mark - Clearing Cache

- (void)clearCache {
    // Reset bookmarked comic
    [self setBookmarkedComic:0];

    // Reset the latest comic download index
    [self setLatestComicDownloaded:0];

    // Reset the viewed and favorite state of all comics.
    RLMResults *allComics = [Comic allObjects];
    [self.realm beginWriteTransaction];
    [allComics setValue:@NO forKey:@"viewed"];
    [allComics setValue:@NO forKey:@"favorite"];
    [self.realm commitWriteTransaction];

    // Remove all images from disk and the cache on a background thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.assembler.imageManager deleteAllImagesFromDisk];
        [self.assembler.imageManager deleteAllImagesFromCache];
    });
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
