//
//  ComicListViewController.m
//  xkcDump
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
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    // Initially we want to grab what we have stored, in case connectivity sucks.
    _comics = [[DataManager sharedInstance] allSavedComics];
    [self.collectionView reloadData];

    if (_comics.count == 0 && ![LoadingView isVisible]) {
        [LoadingView showInView:self.view];
    }

    [self fetchNewComics];
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

- (void)fetchNewComics {
    // Download the latest comics...
    [[DataManager sharedInstance] downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        // Error handling...
        if (error) {
            if (_comics.count == 0) {
                NSLog(@"Error downloading latest comics and we have no comics stored. Retrying fetch again in 3 seconds...");

                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                    [self fetchNewComics];
                });
            }

            return;
        }

        _comics = [[DataManager sharedInstance] allSavedComics];

        if (_comics.count > 0 && [LoadingView isVisible]) {
            [LoadingView handleDoneLoading];
        }

        if (numberOfNewComics > 0) {
            NSMutableArray *indexPathsToInsert = [NSMutableArray arrayWithCapacity:numberOfNewComics];

            for (NSInteger i = 0; i < numberOfNewComics; i++) {
                [indexPathsToInsert addObject:[NSIndexPath indexPathForItem:i inSection:0]];
            }

            [self.collectionView insertItemsAtIndexPaths:indexPathsToInsert];
        }
    }];
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

@end
