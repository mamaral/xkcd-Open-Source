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

@end

@interface ComicListPresenter : NSObject

@property (nonatomic, readonly) BOOL isFilteringFavorites;
@property (nonatomic, readonly) BOOL isSearching;

- (instancetype)initWithView:(id<ComicListView>)view;

- (RLMResults *)getSavedComicList;

- (BOOL)isInitialLoadRequired;

- (void)handleInitialLoad;

#pragma mark - Favorites
- (BOOL)isFilteringFavorites;
- (void)toggleFilterFavorites;

#pragma mark - Searching
- (void)handleSearchBegan;
- (void)searchForComicsWithText:(NSString *)searchText;
- (void)cancelSearch;

@end
