//
//  ComicListViewController.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ComicListViewController.h"
#import <Realm.h>
#import <GTTracker.h>
#import <UIView+Facade.h>
#import "DataManager.h"
#import "ThemeManager.h"
#import "Comic.h"
#import "ComicCell.h"
#import "LoadingView.h"
#import "ComicViewController.h"

@interface ComicListViewController () {
    RLMResults *_comics;

    LoadingView *_loadingView;

    BOOL _isSearching;
}

@end

@implementation ComicListViewController

- (instancetype)init {
    ComicListFlowLayout *comicListLayout = [ComicListFlowLayout new];
    comicListLayout.delegate = self;
    return [super initWithCollectionViewLayout:comicListLayout];
}


#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = @"xkcd: Open Source";
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.backIndicatorImage = [UIImage imageNamed:@"back"];
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = [UIImage imageNamed:@"back"];
    self.collectionView.backgroundColor = [ThemeManager xkcdLightBlue];
    [self.collectionView registerClass:[ComicCell class] forCellWithReuseIdentifier:kComicCellReuseIdentifier];

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleSearch)];

    self.searchBar = [UISearchBar new];
    self.searchBar.delegate = self;
    self.searchBar.showsCancelButton = YES;

    // Fetch comics whenever we get notified more are available.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadComicsFromDB) name:NewComicsAvailableNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Initially we want to grab what we have stored.
    [self loadComicsFromDB];

    // If we don't have any, it's the first launch - let's show the loading view
    // and wait for the data manager to tell us new comics are available.
    if (_comics.count == 0 && ![LoadingView isVisible]) {
        [LoadingView showInView:self.view];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[GTTracker sharedInstance] sendScreenEventWithTitle:@"Comic List"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    if ([LoadingView isVisible]) {
        [LoadingView handleLayoutChanged];
    }
}


#pragma mark - Loading data

- (void)loadComicsFromDB {
    // Grab the comics we have saved.
    _comics = [[DataManager sharedInstance] allSavedComics];

    // If we have comics and the loading view is present, tell it to handle that we're done.
    if (_comics.count > 0 && [LoadingView isVisible]) {
        [LoadingView handleDoneLoading];
    }

    // Reload the collection view.
    [self.collectionView reloadData];
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _comics.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ComicCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kComicCellReuseIdentifier forIndexPath:indexPath];
    cell.comic = _comics[indexPath.item];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = _comics[indexPath.item];

    [self.navigationController pushViewController:[[ComicViewController alloc] initWithComic:comic] animated:YES];
}


#pragma mark - Layout delegate

- (CGFloat)collectionView:(UICollectionView *)collectionView relativeHeightForItemAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = _comics[indexPath.item];
    CGFloat aspectRatio = comic.aspectRatio;
    return 1.0 / aspectRatio;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeDoubleColumnAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = _comics[indexPath.item];
    CGFloat aspectRatio = comic.aspectRatio;
    return aspectRatio > 1.0;
}

- (NSUInteger)numberOfColumnsInCollectionView:(UICollectionView *)collectionView {
    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    BOOL isLandscape = UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation);
    
    if (isPad) {
        return isLandscape ? 6 : 4;
    }

    else {
        return isLandscape ? 4 : 2;
    }
}


#pragma mark - Searching

- (void)toggleSearch {
    if (_isSearching) {
        self.searchBar.text = @"";

        self.navigationItem.titleView = nil;

        _isSearching = NO;

        [self handleDoneSearching];
    }

    else {
        self.navigationItem.titleView = self.searchBar;
        [self.searchBar becomeFirstResponder];

        _isSearching = YES;
    }
}

- (void)handleDoneSearching {
    _comics = [[DataManager sharedInstance] allSavedComics];

    [self.collectionView reloadData];
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *searchText = searchBar.text;


}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self toggleSearch];
}

@end
