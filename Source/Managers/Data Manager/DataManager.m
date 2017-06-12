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

static NSString * const kFetchURLString = @"http://xkcdos.app.sgnl24.com/fetch-comics.php";

@interface DataManager ()

@property (nonatomic, strong) NSUserDefaults *defaults;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@end

@implementation DataManager

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.defaults = [NSUserDefaults standardUserDefaults];

    self.dateFormatter = [NSDateFormatter new];
    self.dateFormatter.dateStyle = NSDateFormatterMediumStyle;

    self.knownInteractiveComicNumbers = @[@1193, @1331, @1446, @1525, @1608, @1663];

    [self initializeRealm];

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

- (void)syncComics {
    // Calculate the starting index.
    NSInteger since = [self latestComicDownloaded];
    NSDictionary *params = @{@"since": [NSString stringWithFormat:@"%ld", (long)since]};

    [[Assembler sharedInstance].requestManager sendGETRequestToURL:kFetchURLString params:params handler:^(NSError * _Nullable error, id  _Nullable responseObject) {
        if (error) {
            [[NSNotificationCenter defaultCenter] postNotificationName:ComicSyncFailedNotification object:nil];
            return;
        }

        // Convert the dictionaries to our comic models, also keeping track of the newest
        // latest comic.
        NSArray *comicDicts = (NSArray *)responseObject;
        NSMutableArray *comics = [NSMutableArray arrayWithCapacity:comicDicts.count];
        NSInteger latestDownloaded = since;

        for (NSDictionary *comicDict in comicDicts) {
            Comic *comic = [Comic comicFromDictionary:comicDict];
            [comics addObject:comic];

            if (comic.num > latestDownloaded) {
                latestDownloaded = comic.num;
            }
        }

        // Update our latest comic.
        [self setLatestComicDownloaded:latestDownloaded];

        // If we have new comics, save them in our realm and broadcast to the rest of the app
        // that the comic list was updated.
        if (comics.count > 0) {
            [self saveComics:comics];

            RLMResults *allComics = [self allSavedComics];
            [[NSNotificationCenter defaultCenter] postNotificationName:ComicListUpdatedNotification object:allComics];
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

    // Ensure we only show interactive comics, we'll need some more work to handle if not.
    // For now, just try another random comic.
    Comic *randomComic = allComics[randomIndex];
    BOOL isInteractive = randomComic.isInteractive || [self.knownInteractiveComicNumbers containsObject:@(randomComic.num)];
    if (!isInteractive) {
        return [self randomComic];
    }

    return randomComic;
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
