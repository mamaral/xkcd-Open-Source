//
//  ComicListViewController.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ComicListViewController.h"
#import <GTTracker.h>
#import <UIView+Facade.h>
#import "DataManager.h"
#import "ThemeManager.h"
#import "LoadingView.h"
#import "Comic.h"
#import "ComicCell.h"
#import "ComicViewController.h"

static NSString * const kComicListTitle = @"xkcd: Open Source";
static NSString * const kNoSearchResultsMessage = @"No results found...";

@interface ComicListViewController ()

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
    self.navigationController.navigationBar.backIndicatorImage = [ThemeManager backImage];
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = [ThemeManager backImage];
    self.collectionView.backgroundColor = [ThemeManager xkcdLightBlue];
    [self.collectionView registerClass:[ComicCell class] forCellWithReuseIdentifier:kComicCellReuseIdentifier];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleSearch)];

    self.searchBar = [UISearchBar new];
    self.searchBar.delegate = self;
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;

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
    if (!self.searching && self.comics.count == 0 && ![LoadingView isVisible]) {
        [LoadingView showInView:self.view];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[GTTracker sharedInstance] sendScreenEventWithTitle:@"Comic List"];

    // Clear the app badge here, as we can be reasonably sure at this point anything new
    // will have been seen, and we won't run into annoying issues related to the app
    // life-cycle that we've experienced before.
    [UIApplication sharedApplication].applicationIconBadgeNumber = 0;
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
    self.comics = [[DataManager sharedInstance] allSavedComics];

    // If we have comics and the loading view is present, tell it to handle that we're done.
    if (self.comics.count > 0 && [LoadingView isVisible]) {
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
    return self.comics.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    ComicCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kComicCellReuseIdentifier forIndexPath:indexPath];
    cell.comic = self.comics[indexPath.item];
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = self.comics[indexPath.item];

    [self.navigationController pushViewController:[[ComicViewController alloc] initWithComic:comic] animated:YES];


    if (!comic.viewed) {
        [[DataManager sharedInstance] markComicViewed:comic];

        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}


#pragma mark - Layout delegate

- (CGFloat)collectionView:(UICollectionView *)collectionView relativeHeightForItemAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = self.comics[indexPath.item];
    CGFloat aspectRatio = comic.aspectRatio;
    return 1.0 / aspectRatio;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeDoubleColumnAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = self.comics[indexPath.item];
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
    if (!self.searching) {
        [self enableSearch];
    }

    else {
        [self cancelSearch];
    }
}

- (void)enableSearch {
    self.searching = YES;

    [self.searchBar becomeFirstResponder];

    self.navigationItem.titleView = self.searchBar;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelSearch)];
}

- (void)cancelSearch {
    self.searching = NO;
    self.searchBar.text = @"";
    self.comics = [[DataManager sharedInstance] allSavedComics];
    self.noResultsLabel.hidden = YES;

    self.navigationItem.rightBarButtonItem = nil;
    self.navigationItem.titleView = nil;

    [self.collectionView setContentOffset:CGPointZero animated:YES];
    [self.collectionView reloadData];
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSString *searchString = searchBar.text;

    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Comic List Search" action:searchString];

    self.comics = [[DataManager sharedInstance] comicsMatchingSearchString:searchString];

    if (self.comics.count > 0) {
        self.noResultsLabel.hidden = YES;

        [searchBar resignFirstResponder];

        [self.collectionView setContentOffset:CGPointZero animated:YES];
    }

    else {
        self.noResultsLabel.hidden = NO;
    }

    [self.collectionView reloadData];
}

@end
