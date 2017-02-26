//
//  ComicListPresenter.h
//  xkcd Open Source
//
//  Created by Mike on 2/18/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Realm/Realm.h>

@class Comic;

@protocol ComicListView <NSObject>

@required
- (void)didStartLoadingComics;
- (void)didFinishLoadingComics;
- (void)comicListDidChange:(RLMResults *)comicList;
- (void)didEncounterLoadingError;

@end

@interface ComicListPresenter : NSObject

@property (nonatomic, readonly) BOOL isFilteringFavorites;
@property (nonatomic, readonly) BOOL isSearching;
@property (nonatomic, readonly) BOOL isFilteringUnread;

- (instancetype)initWithView:(id<ComicListView>)view;

#pragma mark - Loading
- (RLMResults *)getSavedComicList;
- (BOOL)isInitialLoadRequired;
- (void)handleInitialLoad;
- (void)handleShowAllComics;

#pragma mark - Unread
- (void)toggleUnread;

#pragma mark - Favorites
- (BOOL)hasFavorites;
- (BOOL)isFilteringFavorites;
- (void)toggleFilterFavorites;

#pragma mark - Searching
- (void)handleSearchBegan;
- (void)searchForComicsWithText:(NSString *)searchText;
- (void)cancelSearch;

#pragma mark - Bookmarking
- (BOOL)hasBookmark;
- (Comic *)bookmarkedComic;

#pragma mark - Random
- (Comic *)randomComic;

#pragma mark - Interactive comics
- (BOOL)shouldShowComicAsInteractive:(Comic *)comic;

#pragma mark - Clearing cache
- (void)handleClearCache;

@end
