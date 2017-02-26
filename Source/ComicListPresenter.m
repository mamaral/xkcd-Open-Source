//
//  ComicListPresenter.m
//  xkcd Open Source
//
//  Created by Mike on 2/18/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import "ComicListPresenter.h"

#import "DataManager.h"

@interface ComicListPresenter ()

@property (nonatomic, weak) id<ComicListView> view;

@property (nonatomic, strong) DataManager *dataManager;

@property (nonatomic, strong) RLMResults *comics;

@end

@implementation ComicListPresenter

- (instancetype)initWithView:(id<ComicListView>)view {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.view = view;
    self.dataManager = [DataManager sharedInstance];
    self.comics = [self.dataManager allSavedComics];

    // Fetch comics whenever we get notified more are available.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadComicsFromDB) name:NewComicsAvailableNotification object:nil];

    // Handle whenever we're notified about comic favorite updates.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleComicFavorited) name:ComicFavoritedNotification object:nil];

    // Handle whenever we're notified about comic read updates.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleComicRead) name:ComicReadNotification object:nil];

    return self;
}


#pragma mark - Loading comics

- (RLMResults *)getSavedComicList {
    return [self.dataManager allSavedComics];
}

- (BOOL)isInitialLoadRequired {
    return self.comics.count == 0;
}

- (void)handleInitialLoad {
    [self.view didStartLoadingComics];

    [self.dataManager downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        RLMResults *savedComicsAfterLoad = [self.dataManager allSavedComics];

        // If an error occurred and we have no saved comics, tell the view an error occurred.
        if (error && savedComicsAfterLoad.count == 0) {
            [self.view didEncounterLoadingError];
            return;
        }

        [self.view didFinishLoadingComics];

        self.comics = savedComicsAfterLoad;
        [self.view comicListDidChange:self.comics];
    }];
}

- (void)handleComicFavorited {
    // Tell our view the comic list changed.
    [self.view comicListDidChange:self.comics];
}

- (void)handleComicRead {
    // Tell our view the comic list changed if we're filtering read.
    if (self.isFilteringUnread) {
        self.comics = [self.dataManager allUnread];
    }

    [self.view comicListDidChange:self.comics];
}

- (void)loadComicsFromDB {
    // If we're not searching and not filtering, update our list and tell the view we've updated.
    if (!self.isSearching && !self.isFilteringFavorites) {
        self.comics = [self.dataManager allSavedComics];
        [self.view comicListDidChange:self.comics];
    }
}

- (void)handleShowAllComics {
    // Refresh our state and comic list and tell our view we've updated;
    _isFilteringUnread = NO;
    _isFilteringFavorites = NO;
    _isSearching = NO;

    self.comics = [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Unread

- (void)toggleUnread {
    _isFilteringUnread = !self.isFilteringUnread;

    // Refresh our state and comic list, and tell our view we've updated.
    _isSearching = NO;
    _isFilteringFavorites = NO;

    self.comics = self.isFilteringUnread ? [self.dataManager allUnread] : [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Favorites

- (BOOL)hasFavorites {
    return [self.dataManager allFavorites].count > 0;
}

- (void)toggleFilterFavorites {
    _isFilteringFavorites = !self.isFilteringFavorites;

    // Refresh our state and comic list, and tell our view we've updated.
    _isSearching = NO;
    _isFilteringUnread = NO;

    self.comics = self.isFilteringFavorites ? [self.dataManager allFavorites] : [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Searching

- (void)handleSearchBegan {
    _isSearching = YES;

    // Refresh our state and comics list, and tell our view we've updated.
    _isFilteringFavorites = NO;
    _isFilteringUnread = NO;

    self.comics = [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}

- (void)searchForComicsWithText:(NSString *)searchText {
    _isSearching = YES;

    self.comics = [[DataManager sharedInstance] comicsMatchingSearchString:searchText];
    [self.view comicListDidChange:self.comics];
}

- (void)cancelSearch {
    _isSearching = NO;

    self.comics = [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Bookmarking

- (BOOL)hasBookmark {
    return [self bookmarkedComic] != nil;
}

- (Comic *)bookmarkedComic {
    return [self.dataManager bookmarkedComic];
}


#pragma mark - Random

- (Comic *)randomComic {
    return [self.dataManager randomComic];
}


#pragma mark - Interactive comics

- (BOOL)shouldShowComicAsInteractive:(Comic *)comic {
    return comic.isInteractive || [self.dataManager.knownInteractiveComicNumbers containsObject:@(comic.num)];
}

#pragma mark - Clearing cache

- (void)handleClearCache {
    [[DataManager sharedInstance] clearCache];

    self.comics = [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];

    [self handleInitialLoad];
}

@end
