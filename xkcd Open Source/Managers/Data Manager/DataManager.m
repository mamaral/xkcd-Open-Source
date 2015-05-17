//
//  DataManager.m
//  xkcDump
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "DataManager.h"
#import "RequestManager.h"

static NSInteger const kCurrentSchemaVersion = 1;
static NSString * const kLatestComicDownloadedKey = @"LatestComicDownloaded";

@implementation DataManager {
    NSUserDefaults *_defaults;
}


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

    _defaults = [NSUserDefaults standardUserDefaults];

    [self initializeRealm];

    return self;
}

- (void)initializeRealm {
    // Currently no need for migrations, so we can leave the migrations block empty.
    [RLMRealm setSchemaVersion:kCurrentSchemaVersion forRealmAtPath:[RLMRealm defaultRealmPath] withMigrationBlock:^(RLMMigration *migration, NSUInteger oldSchemaVersion) {}];

    self.realm = [RLMRealm defaultRealm];
}


#pragma mark - Saving comics

- (void)saveComics:(NSArray *)comics {
    [self.realm beginWriteTransaction];

    for (Comic *comic in comics) {
        [Comic createOrUpdateInDefaultRealmWithValue:comic];
    }

    [self.realm commitWriteTransaction];
}

- (void)markComicViewed:(Comic *)comic {
    [self.realm transactionWithBlock:^{
        comic.viewed = YES;
    }];
}


#pragma mark - Latest comic info

- (NSInteger)latestComicDownloaded {
    return [_defaults integerForKey:kLatestComicDownloadedKey];
}

- (void)setLatestComicDownloaded:(NSInteger)latest {
    [_defaults setInteger:latest forKey:kLatestComicDownloadedKey];
}


#pragma mark - Fetching comics

- (RLMResults *)allSavedComics {
    return [[Comic allObjects] sortedResultsUsingProperty:@"num" ascending:NO];
}

- (void)downloadLatestComicsWithCompletionHandler:(void (^)(NSError *error, NSInteger numberOfNewComics))handler {
    // Calculate the starting index.
    NSInteger startingIndex = [self latestComicDownloaded] + 1;

    // Pass that to our request manager to fetch it.
    [[RequestManager sharedInstance] downloadComicsStartingAtIndex:startingIndex completionHandler:^(NSError *error, NSArray *comicDicts) {
        // Error handling
        if (error) {
            handler(error, nil);
            return;
        }

        // Convert the dictionaries to our comic models, also keeping track of the newest
        // latest comic.
        NSMutableArray *comics = [NSMutableArray arrayWithCapacity:comicDicts.count];
        NSInteger latestDownloaded = [self latestComicDownloaded];

        for (NSDictionary *comicDict in comicDicts) {
            Comic *comic = [Comic comicFromDictionary:comicDict];
            [comics addObject:comic];

            if (comic.num > latestDownloaded) {
                latestDownloaded = comic.num;
            }
        }

        // Save them in our realm.
        [self saveComics:comics];

        // Update our latest comic.
        [self setLatestComicDownloaded:latestDownloaded];

        handler(nil, comics.count);
    }];
}


#pragma mark - Background fetching

- (void)performBackgroundFetchWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    // Download all of the latest comics.
    [self downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        if (error) {
            completionHandler(UIBackgroundFetchResultFailed);
        }

        else {
            completionHandler(numberOfNewComics > 1 ? UIBackgroundFetchResultNewData : UIBackgroundFetchResultNoData);
        }
    }];
}


#pragma mark - Converting token data

- (NSString *)tokenStringFromData:(NSData *)data {
    NSString *token = [NSString stringWithFormat:@"%@", data];
    token = [token stringByReplacingOccurrencesOfString:@"<" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@">" withString:@""];
    token = [token stringByReplacingOccurrencesOfString:@" " withString:@""];
    return token;
}

@end
