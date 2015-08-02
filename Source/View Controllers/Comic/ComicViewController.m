//
//  ComicViewController.m
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ComicViewController.h"
#import <UIView+Facade.h>
#import <UIImageView+WebCache.h>
#import <GTTracker.h>
#import "ThemeManager.h"
#import "DataManager.h"

static CGFloat const kComicViewControllerPadding = 10.0;
static CGFloat const kFavoritedButtonSize = 50.0;
static CGFloat const kFavoriteButtonPadding = 20.0;
static CGFloat const kFavoritedButtonNonFavoriteAlpha = 0.3;
static CGFloat const kAltButtonSize = 40.0;
static CGFloat const kAltButtonPadding = 25.0;

@interface ComicViewController () {
    BOOL _viewedAlt;
}

@end

@implementation ComicViewController

- (instancetype)init {
    self = [super init];

    [self createViewComponents];

    return self;
}


#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [[GTTracker sharedInstance] sendScreenEventWithTitle:@"Comic"];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self layoutFacade];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Viewed Alt" action:_viewedAlt ? @"Yes" : @"NO"];
}

- (void)createViewComponents {
    self.containerView = [UIScrollView new];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.scrollEnabled = YES;
    self.containerView.minimumZoomScale = 1.0;
    self.containerView.maximumZoomScale = 10.0;
    self.containerView.delegate = self;
    [self.view addSubview:self.containerView];

    self.comicImageView = [UIImageView new];
    self.comicImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.comicImageView.userInteractionEnabled = YES;
    [self.containerView addSubview:self.comicImageView];

    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.adjustsImageWhenHighlighted = NO;
    [self.favoriteButton setImage:[ThemeManager favoriteImage] forState:UIControlStateNormal];
    [self.favoriteButton addTarget:self action:@selector(toggleComicFavorited) forControlEvents:UIControlEventTouchDown];
    [self.favoriteButton setAlpha:self.comic.favorite ? 1.0 : kFavoritedButtonNonFavoriteAlpha];
    [self.view addSubview:self.favoriteButton];

    self.showAltButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.showAltButton.titleLabel.font = [ThemeManager xkcdFontWithSize:22];
    [self.showAltButton setBackgroundColor:[ThemeManager xkcdLightBlue]];
    [self.showAltButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.showAltButton setTitleColor:[[UIColor whiteColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    [self.showAltButton setTitle:@"..." forState:UIControlStateNormal];
    [self.showAltButton addTarget:self action:@selector(showAltView) forControlEvents:UIControlEventTouchDown];
    [self.showAltButton addTarget:self action:@selector(dismissAltView) forControlEvents:UIControlEventTouchUpInside];
    [self.showAltButton addTarget:self action:@selector(dismissAltView) forControlEvents:UIControlEventTouchUpOutside];
    [self.view addSubview:self.showAltButton];

    [ThemeManager addBorderToLayer:self.showAltButton.layer radius:kAltButtonSize / 2.0 color:[UIColor whiteColor]];
    [ThemeManager addShadowToLayer:self.showAltButton.layer radius:10.0 opacity:0.4];

    self.altView = [[AltView alloc] initWithComic:self.comic];
    self.altView.alpha = 0.0;
}

- (void)layoutFacade {
    [self.containerView fillSuperview];
    self.containerView.contentSize = self.containerView.frame.size;
    [self.favoriteButton anchorBottomLeftWithLeftPadding:kFavoriteButtonPadding bottomPadding:kFavoriteButtonPadding width:kFavoritedButtonSize height:kFavoritedButtonSize];
    [self.showAltButton anchorBottomRightWithRightPadding:kAltButtonPadding bottomPadding:kAltButtonPadding width:kAltButtonSize height:kAltButtonSize];
    [self.comicImageView anchorTopCenterWithTopPadding:kComicViewControllerPadding width:self.view.width - (kComicViewControllerPadding * 2) height:self.showAltButton.yMin - (2 * kComicViewControllerPadding)];

    if (self.altView.isVisible) {
        [self.altView layoutFacade];
    }
}


#pragma mark - Setters

- (void)setComic:(Comic *)comic {
    _comic = comic;

    self.title = comic.safeTitle;

    [self.comicImageView sd_setImageWithURL:[NSURL URLWithString:comic.imageURLString ?: @""] placeholderImage:[ThemeManager loadingImage]];
}


#pragma mark - Alt

- (void)showAltView {
    _viewedAlt = YES;

    [self.view addSubview:self.altView];
    [self.altView show];
}

- (void)dismissAltView {
    [self.altView dismissWithCompletion:^{
        [self.altView removeFromSuperview];
    }];
}


#pragma mark - Favorite

- (void)toggleComicFavorited {
    BOOL isNowFavorited = !self.comic.favorite;

    [[DataManager sharedInstance] markComic:self.comic favorited:isNowFavorited];

    [self.favoriteButton setAlpha:isNowFavorited ? 1.0 : kFavoritedButtonNonFavoriteAlpha];
}


#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.comicImageView;
}

@end
