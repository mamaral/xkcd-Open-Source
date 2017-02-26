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

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleComicFavorited) name:ComicFavoritedNotification object:nil];

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
        [self.view didFinishLoadingComics];
        
        if (error) {
            return;
        }

        self.comics = [self.dataManager allSavedComics];
        [self.view comicListDidChange:self.comics];
    }];
}

- (void)handleComicFavorited {
    // Tell our view the comic list changed.
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Favorites

- (void)toggleFilterFavorites {
    _isFilteringFavorites = !self.isFilteringFavorites;

    // Refresh our state and comic list, and tell our view we've updated.
    _isSearching = NO;

    self.comics = self.isFilteringFavorites ? [self.dataManager allFavorites] : [self.dataManager allSavedComics];
    [self.view comicListDidChange:self.comics];
}


#pragma mark - Searching

- (void)handleSearchBegan {
    _isSearching = YES;

    // Refresh our state and comics list, and tell our view we've updated.
    _isFilteringFavorites = NO;

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

@end
