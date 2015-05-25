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

static NSString * const kComicListTitle = @"xkcd: Open Source";
static NSString * const kNoSearchResultsMessage = @"No results found...";

@interface ComicListViewController () {
    RLMResults *_comics;

    LoadingView *_loadingView;

    BOOL _searching;
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

    self.title = kComicListTitle;
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
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;

    self.noResultsLabel = [UILabel new];
    self.noResultsLabel.hidden = YES;
    self.noResultsLabel.text = kNoSearchResultsMessage;
    self.noResultsLabel.font = [ThemeManager xkcdFontWithSize:18];
    self.noResultsLabel.textColor = [UIColor blackColor];
    self.noResultsLabel.textAlignment = NSTextAlignmentCenter;
    [self.collectionView addSubview:self.noResultsLabel];

    // Initially we want to grab what we have stored.
    [self loadComicsFromDB];

    // Fetch comics whenever we get notified more are available.
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadComicsFromDB) name:NewComicsAvailableNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // If we don't have any, it's the first launch - let's show the loading view
    // and wait for the data manager to tell us new comics are available.
    if (!_searching && _comics.count == 0 && ![LoadingView isVisible]) {
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

    if (!self.noResultsLabel.isHidden) {
        [self.noResultsLabel anchorTopCenterFillingWidthWithLeftAndRightPadding:15 topPadding:15 height:20];
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
    if (_searching) {
        self.searchBar.text = @"";

        self.navigationItem.titleView = nil;

        _searching = NO;
    }

    else {
        self.navigationItem.titleView = self.searchBar;

        [self.searchBar becomeFirstResponder];

        _searching = YES;
    }
}

- (void)handleSearchCancelled {
    _comics = [[DataManager sharedInstance] allSavedComics];

    self.noResultsLabel.hidden = YES;

    [self.collectionView setContentOffset:CGPointZero animated:YES];
    [self.collectionView reloadData];
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *searchString = searchBar.text;

    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Comic List Search" action:searchString];

    _comics = [[DataManager sharedInstance] comicsMatchingSearchString:searchString];

    if (_comics.count > 0) {
        self.noResultsLabel.hidden = YES;

        [searchBar resignFirstResponder];

        [self.collectionView setContentOffset:CGPointZero animated:YES];
    }

    else {
        // handle no results
        self.noResultsLabel.hidden = NO;
    }

    [self.collectionView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self toggleSearch];
    [self handleSearchCancelled];
}

@end
