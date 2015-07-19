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

static CGFloat const kAltButtonSize = 60.0;

@interface ComicViewController () {
    BOOL _viewedAlt;
}

@end

@implementation ComicViewController

- (instancetype)initWithComic:(Comic *)comic {
    self = [super init];

    self.comic = comic;

    return self;
}


#pragma mark - View life cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    self.edgesForExtendedLayout = UIRectEdgeNone;

    [self createViewComponents];
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
    self.title = self.comic.safeTitle;
    self.view.backgroundColor = [UIColor whiteColor];
    
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
    [self.comicImageView sd_setImageWithURL:[NSURL URLWithString:self.comic.imageURLString ?: @""] placeholderImage:[ThemeManager loadingImage]];
    [self.containerView addSubview:self.comicImageView];

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
    [self.comicImageView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:10 topAndBottomPadding:10];
    [self.showAltButton anchorBottomRightWithRightPadding:30 bottomPadding:30 width:kAltButtonSize height:kAltButtonSize];

    if (self.altView.isVisible) {
        [self.altView layoutFacade];
    }
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


#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.comicImageView;
}

@end
