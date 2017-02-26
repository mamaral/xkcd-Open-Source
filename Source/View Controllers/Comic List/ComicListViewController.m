//
//  ComicListViewController.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ComicListViewController.h"
#import <UIView+Facade.h>
#import "DataManager.h"
#import "ThemeManager.h"
#import "LoadingView.h"
#import "Comic.h"
#import "ComicCell.h"
#import "ComicWebViewController.h"
#import "AltView.h"
#import "ComicListPresenter.h"

static NSString * const kComicListTitle = @"xkcd: Open Source";
static NSString * const kComicListFavoritesTitle = @"Favorites";
static NSString * const kNoSearchResultsMessage = @"No results found...";
static NSString * const kNoFavoritesMessage = @"You have no favorites yet!";

@interface ComicListViewController () <ComicListFlowLayoutDelegate, ComicViewControllerDelegate, UISearchBarDelegate, ComicCellDelegate, ComicListView>

@property (nonatomic, strong) RLMResults *comics;

@property (nonatomic, strong) UIBarButtonItem *searchButton;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UILabel *noResultsLabel;

@property (nonatomic, strong) AltView *altView;

@property (nonatomic, strong) ComicListPresenter *presenter;

@end

@implementation ComicListViewController

- (instancetype)init {
    ComicListFlowLayout *comicListLayout = [ComicListFlowLayout new];
    comicListLayout.delegate = self;
    self = [super initWithCollectionViewLayout:comicListLayout];

    if (!self) {
        return nil;
    }

    self.presenter = [[ComicListPresenter alloc] initWithView:self];;
    self.comics = [self.presenter getSavedComicList];
    
    return self;
}


#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = kComicListTitle;
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.backIndicatorImage = [ThemeManager backImage];
    self.navigationController.navigationBar.backIndicatorTransitionMaskImage = [ThemeManager backImage];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.collectionView.backgroundColor = [ThemeManager xkcdLightBlue];
    [self.collectionView registerClass:[ComicCell class] forCellWithReuseIdentifier:kComicCellReuseIdentifier];

    self.altView = [AltView new];
    self.altView.alpha = 0.0;

    self.searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(toggleSearch)];
    self.navigationItem.leftBarButtonItem = self.searchButton;

    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStylePlain target:self action:@selector(showMenu)];
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

    // Fetch comics whenever we get notified more are available.
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(loadComicsFromDB) name:NewComicsAvailableNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // If our presenter tells us an initial load is required, disable the navigation buttons
    // and tell it to handle the initial load.
    if ([self.presenter isInitialLoadRequired]) {
        self.navigationItem.leftBarButtonItem.enabled = NO;
        self.navigationItem.rightBarButtonItem.enabled = NO;
        
        [self.presenter handleInitialLoad];
    }
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    // Layout the loading view if it's visible.
    if ([LoadingView isVisible]) {
        [LoadingView handleLayoutChanged];
    }

    // Layout the no-results label if it's visible.
    if (!self.noResultsLabel.isHidden) {
        [self.noResultsLabel anchorTopCenterFillingWidthWithLeftAndRightPadding:15 topPadding:15 height:20];
    }
}


#pragma mark - Actions

- (void)showMenu {
    // Cancel searching if we were.
    if (self.presenter.isSearching) {
        [self cancelSearch];
    }

    NSString *favoritesTitle = [self.presenter isFilteringFavorites] ? @"Show All Comics" : @"Show Favorites";
    UIAlertAction *toggleFavs = [UIAlertAction actionWithTitle:favoritesTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self.presenter toggleFilterFavorites];
    }];

    UIAlertAction *viewRandom = [UIAlertAction actionWithTitle:@"View Random Comic" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showRandomComic];
    }];

    UIAlertAction *viewBookmark = [UIAlertAction actionWithTitle:@"View Bookmarked Comic" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self viewBookmark];
    }];

    UIAlertAction *clearCache = [UIAlertAction actionWithTitle:@"Clear Cache" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self showClearCacheConfirmation];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    RLMResults *favorites = [[DataManager sharedInstance] allFavorites];

    if (favorites.count > 0) {
        [alertController addAction:toggleFavs];
    }

    [alertController addAction:viewRandom];

    NSInteger bookmarkIndex = [[DataManager sharedInstance] bookmarkedComicNumber];

    if (bookmarkIndex > 0) {
        [alertController addAction:viewBookmark];
    }

    [alertController addAction:clearCache];
    [alertController addAction:cancel];

    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

- (void)viewBookmark {
    Comic *bookmarkedComic = [[DataManager sharedInstance] bookmarkedComic];
    [self showComic:bookmarkedComic atIndexPath:nil];
}

- (void)showClearCacheConfirmation {
    UIAlertAction *clearCache = [UIAlertAction actionWithTitle:@"Clear Cache" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
//        [self clearCache];
    }];

    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Are you sure?" message:@"This will set all comics as unread, reset all favorites, and clear your bookmark if you have one set." preferredStyle:UIAlertControllerStyleActionSheet];
    [alertController addAction:clearCache];
    [alertController addAction:cancel];

    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

//- (void)clearCache {
//    [[DataManager sharedInstance] clearCache];
//
//    [self loadComicsFromDB];
//
//    [self handleInitialLoadBegan];
//
//    [[DataManager sharedInstance] downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
//        if (error && [[DataManager sharedInstance] allSavedComics].count == 0) {
//
//        } else if (numberOfNewComics > 0) {
//            [self loadComicsFromDB];
//        }
//    }];
//}

- (void)showComic:(Comic *)comic atIndexPath:(NSIndexPath *)indexPath {
    ComicViewController *comicVC = [ComicViewController new];
    comicVC.delegate = self;
    //comicVC.allowComicNavigation = !self.searching && !self.filteringFavorites;
    comicVC.comic = comic;
    [self.navigationController pushViewController:comicVC animated:YES];
}

- (void)showRandomComic {
    [self cancelAllNavBarActions];

    [self showComic:[[DataManager sharedInstance] randomComic] atIndexPath:nil];
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
    cell.delegate = self;
    return cell;
}


#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    Comic *comic = self.comics[indexPath.item];

    if (comic.isInteractive || [[DataManager sharedInstance].knownInteractiveComicNumbers containsObject:@(comic.num)]) {
        ComicWebViewController *comicWebVC = [ComicWebViewController new];
        comicWebVC.comic = comic;
        [self.navigationController pushViewController:comicWebVC animated:YES];
    } else {
        [self showComic:comic atIndexPath:indexPath];
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
    } else {
        return isLandscape ? 4 : 2;
    }
}


#pragma mark - Comic view controller delegate

- (Comic *)comicViewController:(ComicViewController *)comicViewController comicBeforeCurrentComic:(Comic *)currentComic {
    NSInteger indexOfCurrentComic = [self.comics indexOfObject:currentComic];

    return (indexOfCurrentComic != NSNotFound && indexOfCurrentComic > 0) ? self.comics[indexOfCurrentComic - 1] : nil;
}

- (Comic *)comicViewController:(ComicViewController *)comicViewController comicAfterCurrentComic:(Comic *)currentComic {
    NSInteger indexOfCurrentComic = [self.comics indexOfObject:currentComic];

    return (indexOfCurrentComic != NSNotFound && indexOfCurrentComic + 1 <= self.comics.count - 1) ? self.comics[indexOfCurrentComic + 1] : nil;
}

- (Comic *)comicViewController:(ComicViewController *)comicViewController randomComic:(Comic *)currentComic {
    return [[DataManager sharedInstance] randomComic];
}


#pragma mark - Searching and Filtering

- (void)toggleSearch {
    if (!self.presenter.isSearching) {
        [self.presenter handleSearchBegan];

        [self.searchBar becomeFirstResponder];

        UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 40.0)];

        UIBarButtonItem *spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancelSearch)];

        [toolbar setItems:@[spacer, cancel]];
        self.searchBar.inputAccessoryView = toolbar;

        self.navigationItem.titleView = self.searchBar;
    } else {
        [self cancelSearch];
    }
}

- (void)cancelSearch {
    // Clear the search text, dismiss the keyboard, clear the title view, and
    // tell the presenter to cancel.
    self.searchBar.text = nil;
    [self.searchBar resignFirstResponder];

    self.navigationItem.titleView = nil;

    [self.presenter cancelSearch];
}

- (void)toggleFilterFavorites {
//    if (!self.filteringFavorites) {
//        self.filteringFavorites = YES;
//        self.searching = NO;
//
//        [self filterFavorites];
//    } else {
//        [self cancelAllNavBarActions];
//    }
}

- (void)searchForComicsWithSearchString:(NSString *)searchString {
    self.comics = [[DataManager sharedInstance] comicsMatchingSearchString:searchString];

    self.noResultsLabel.text = kNoSearchResultsMessage;

    [self handleSearchOrFilterCompleteWithScroll:YES];
}

- (void)filterFavorites {
    self.comics = [[DataManager sharedInstance] allFavorites];

    self.noResultsLabel.text = kNoFavoritesMessage;

    [self handleSearchOrFilterCompleteWithScroll:NO];
}

- (void)handleSearchOrFilterCompleteWithScroll:(BOOL)scroll {
    if (self.comics.count > 0) {
        self.noResultsLabel.hidden = YES;

        if (scroll) {
            [self.collectionView setContentOffset:CGPointZero animated:YES];
        }
    } else {
        self.noResultsLabel.hidden = NO;
    }

    [self.collectionView reloadData];
}


#pragma mark - Comic cell delegate

- (void)comicCell:(ComicCell *)cell didSelectComicAltWithComic:(Comic *)comic {
    if (!self.altView.isVisible) {
        self.altView.comic = comic;
        [self.altView showInView:self.view];
    } else {
        self.altView.comic = nil;
        [self.altView dismiss];
    }
}


#pragma mark - Nav bar state

- (void)cancelAllNavBarActions {
    self.searchBar.text = @"";
    self.comics = [[DataManager sharedInstance] allSavedComics];
    self.noResultsLabel.hidden = YES;

    self.navigationItem.leftBarButtonItem = self.searchButton;
    self.navigationItem.titleView = nil;

    [self.collectionView setContentOffset:CGPointZero animated:YES];
    [self.collectionView reloadData];
}


#pragma mark - UISearchBar delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];

    // Scroll to the top now that results will be changing.
    [self.collectionView setContentOffset:CGPointZero animated:YES];

    // Tell our presenter to search.
    [self.presenter searchForComicsWithText:searchBar.text];
}


#pragma mark - Comic view protocol

- (void)didStartLoadingComics {
    [LoadingView showInView:self.view];
}

- (void)didFinishLoadingComics {
    [LoadingView handleDoneLoading];

    self.navigationItem.leftBarButtonItem.enabled = NO;
    self.navigationItem.rightBarButtonItem.enabled = NO;
}

- (void)comicListDidChange:(RLMResults *)comicList {
    // Update our data source and reload the collection view.
    self.comics = comicList;
    [self.collectionView reloadData];

    // If we're filtering favorites, update our title
    if (self.presenter.isFilteringFavorites) {
        self.title = kComicListFavoritesTitle;
    } else if (self.presenter.isSearching) {
        self.noResultsLabel.hidden = self.comics.count > 0;
    } else {
        self.title = kComicListTitle;
    }
}

@end
