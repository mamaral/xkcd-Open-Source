//
//  ComicListPresenter.m
//  xkcd Open Source
//
//  Created by Mike on 2/18/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import "ComicListPresenter.h"

#import "Assembler.h"
#import "DataManager.h"
#import "Comic.h"

@interface ComicListPresenter ()

@property (nonatomic, weak) id<ComicListView> view;

@property (nonatomic, strong) DataManager *dataManager;

@property (nonatomic, strong) RLMResults *comics;

@end

@implementation ComicListPresenter

- (instancetype)initWithAssembler:(Assembler *)assembler {
    self = [super init];

    if (!self) {
        return nil;
    }

    self.dataManager = assembler.dataManager;
    self.comics = [self.dataManager allSavedComics];

    // Fetch comics whenever we get notified more are available.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadComicsFromDB) name:NewComicsAvailableNotification object:nil];

    // Handle whenever we're notified about comic favorite updates.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleComicFavorited) name:ComicFavoritedNotification object:nil];

    // Handle whenever we're notified about comic read updates.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleComicRead) name:ComicReadNotification object:nil];

    return self;
}

- (void)attachToView:(id<ComicListView>)view {
    NSParameterAssert(view);

    self.view = view;
    [self.view comicListDidChange:self.comics];
}

- (void)dettachFromView:(id<ComicListView>)view {
    self.view = nil;
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


#pragma mark - Selecting comics

- (void)comicSelected:(Comic *)comic inPreviewMode:(BOOL)previewMode {
    [self showComic:comic inPreviewMode:previewMode];
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

    self.comics = [self.dataManager comicsMatchingSearchString:searchText];
    [self.view comicListDidChange:self.comics];
}

- (void)cancelSearch {
    _isSearching = NO;

    self.comics = [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Bookmarking

- (BOOL)hasBookmark {
    return [self.dataManager bookmarkedComic] != nil;
}

- (void)showBookmarkedComic {
    [self showComic:[self.dataManager bookmarkedComic] inPreviewMode:NO];
}


#pragma mark - Random

- (void)showRandomComic {
    [self showComic:[self.dataManager randomComic] inPreviewMode:NO];
}

- (Comic *)randomComic {
    return [self.dataManager randomComic];
}


#pragma mark - Clearing cache

- (void)handleClearCache {
    // Clear our state
    _isSearching = NO;
    _isFilteringUnread = NO;
    _isFilteringFavorites = NO;

    // Tell the data manager to clear the cache.
    [self.dataManager clearCache];

    // Get our updated list and pass it to the view.
    self.comics = [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];

    // Act as if this is the initial load.
    [self handleInitialLoad];
}


#pragma mark - Convenience methods

- (void)showComic:(Comic *)comic inPreviewMode:(BOOL)previewMode {
    NSParameterAssert(comic);

    BOOL allowNavigation = !self.isSearching && !self.isFilteringFavorites;
    BOOL isInteractive = comic.isInteractive || [self.dataManager.knownInteractiveComicNumbers containsObject:@(comic.num)];
    [self.view showComic:comic allowingNavigation:allowNavigation isInteractive:isInteractive inPreviewMode:previewMode];
}

@end
