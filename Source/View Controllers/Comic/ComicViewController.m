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
#import "ThemeManager.h"
#import "DataManager.h"
#import <SDWebImagePrefetcher.h>
#import <TwitterKit/TwitterKit.h>
#import "AltView.h"
#import "XKCDDeviceManager.h"
#import "ComicWebViewController.h"
#import "Assembler.h"
#import "ImageManager.h"
#import "ComicPresenter.h"
#import "ComicWebViewController.h"

static CGFloat const kComicViewControllerPadding = 10.0;
static CGFloat const kComicViewControllerSmallPadding = 7.0;
static CGFloat const kBottomButtonSize = 50.0;
static CGFloat const kBottomButtonPadSize = 70.0;
static CGFloat const kFavoritedButtonNonFavoriteAlpha = 0.3;

static NSString * const kAltButtonText = @"Alt";

@interface ComicViewController () <ComicView, AltViewDelegate>

@property (nonatomic, strong) ComicPresenter *presenter;
@property (nonatomic, weak) ImageManager *imageManager;
@property (nonatomic, weak) DataManager *dataManager;

@property (nonatomic) BOOL viewedAlt;

@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, strong) UIImageView *comicImageView;
@property (nonatomic, strong) AltView *altView;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *randomComicButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *altTextButton;
@property (nonatomic, strong) UIButton *bookmarkButton;
@property (nonatomic, strong) UIView *buttonContainerView;
@property (nonatomic, strong) UISwipeGestureRecognizer *prevSwipe;
@property (nonatomic, strong) UISwipeGestureRecognizer *nextSwipe;
@property (nonatomic, strong) UIImage *comicImage;

@property (nonatomic) CGFloat buttonSize;

@end

@implementation ComicViewController

- (instancetype)initWithPresenter:(ComicPresenter *)presenter {
    NSParameterAssert(presenter);

    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.presenter = presenter;
    self.imageManager = [Assembler sharedInstance].imageManager;
    self.dataManager = [Assembler sharedInstance].dataManager;

    self.prevSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self.presenter action:@selector(showPreviousComic)];
    self.nextSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self.presenter action:@selector(showNextComic)];

    self.containerView = [UIScrollView new];

    self.comicImageView = [UIImageView new];
    self.comicImageView.accessibilityLabel = NSLocalizedString(@"comic.view.comic", nil);

    self.buttonContainerView = [UIView new];

    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.favoriteButton.accessibilityLabel = NSLocalizedString(@"comic.view.favorite", nil);

    self.randomComicButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.randomComicButton.accessibilityLabel = NSLocalizedString(@"comic.view.view random", nil);

    self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.prevButton.accessibilityLabel = NSLocalizedString(@"comic.view.prev", nil);

    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.accessibilityLabel = NSLocalizedString(@"comic.view.next", nil);

    self.altTextButton = [UIButton new];
    self.altTextButton.accessibilityLabel = NSLocalizedString(@"comic.view.alt", nil);

    self.bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.bookmarkButton.accessibilityLabel = NSLocalizedString(@"comic.view.bookmark", nil);

    self.altView = [AltView new];
    self.altView.delegate = self;

    self.buttonSize = [XKCDDeviceManager isPad] ? kBottomButtonPadSize : kBottomButtonSize;

    return self;
}


#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(handleShareButton)];

    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.scrollEnabled = YES;
    self.containerView.minimumZoomScale = 1.0;
    self.containerView.maximumZoomScale = 10.0;
    self.containerView.delegate = self;
    [self.view addSubview:self.containerView];

    self.comicImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.comicImageView.userInteractionEnabled = YES;
    self.comicImageView.isAccessibilityElement = YES;
    [self.containerView addSubview:self.comicImageView];

    self.buttonContainerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    [self.view addSubview:self.buttonContainerView];

    self.bookmarkButton.adjustsImageWhenHighlighted = NO;
    [self.bookmarkButton addTarget:self action:@selector(toggleBookmark) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.bookmarkButton];

    self.favoriteButton.adjustsImageWhenHighlighted = NO;
    [self.favoriteButton setImage:[ThemeManager favoriteImage] forState:UIControlStateNormal];
    [self.favoriteButton addTarget:self action:@selector(toggleComicFavorited) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.favoriteButton];

    self.randomComicButton.adjustsImageWhenHighlighted = NO;
    self.randomComicButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.randomComicButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    [self.randomComicButton setImage:[ThemeManager randomImage] forState:UIControlStateNormal];
    [self.randomComicButton addTarget:self.presenter action:@selector(showRandomComic) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.randomComicButton];

    self.prevButton.adjustsImageWhenHighlighted = NO;
    [self.prevButton setImage:[ThemeManager prevComicImage] forState:UIControlStateNormal];
    [self.prevButton addTarget:self.presenter action:@selector(showPreviousComic) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.prevButton];

    self.prevSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.prevSwipe];

    self.nextSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.nextSwipe];

    self.nextButton.adjustsImageWhenHighlighted = NO;
    [self.nextButton setImage:[ThemeManager nextComicImage] forState:UIControlStateNormal];
    [self.nextButton addTarget:self.presenter action:@selector(showNextComic) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.nextButton];

    [self.altTextButton setTitle:kAltButtonText forState:UIControlStateNormal];
    [self.altTextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.altTextButton setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
    [self.altTextButton.titleLabel setFont:[ThemeManager xkcdFontWithSize:20.0]];
    [self.altTextButton addTarget:self action:@selector(toggleAltView) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonContainerView addSubview:self.altTextButton];

    self.altView.alpha = 0.0;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.presenter attachToView:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.presenter dettachFromView:self];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self layoutFacade];
}

- (void)layoutFacade {
    // Layout the container
    [self.containerView fillSuperview];
    self.containerView.contentSize = self.containerView.frame.size;

    // Layout the comic image view
    [self.comicImageView anchorTopCenterWithTopPadding:kComicViewControllerPadding width:self.view.width - (kComicViewControllerPadding * 2) height:self.view.height - (2 * kComicViewControllerPadding) - self.buttonSize];

    // Layout the button container and buttons
    CGFloat spacing = [XKCDDeviceManager isSmallDevice] ? kComicViewControllerSmallPadding : kComicViewControllerPadding;
    [self.buttonContainerView anchorBottomCenterFillingWidthWithLeftAndRightPadding:0.0 bottomPadding:0.0 height:self.buttonSize];
    [self.prevButton anchorCenterLeftWithLeftPadding:spacing width:kBottomButtonSize height:self.buttonSize];
    [self.nextButton anchorCenterRightWithRightPadding:spacing width:kBottomButtonSize height:self.buttonSize];
    [self.buttonContainerView groupHorizontally:@[self.bookmarkButton, self.favoriteButton, self.randomComicButton, self.altTextButton] centeredFillingHeightWithSpacing:spacing width:self.buttonSize];

    // Layout the alt view if its on screen
    if (self.altView.isVisible) {
        [self.altView layoutFacade];
    }
}


#pragma mark - Setters

- (void)setComic:(Comic *)comic {
    // First we need to grab the filename for the previous comic so we can cancel
    // the download handler for it. This will prevent this view from loading an
    // outdated image if users switch comics fast and a download finishes for a
    // prior comic.
    NSString *previousFilename = [self.comic getFilename];
    [self.imageManager cancelDownloadHandlerForFilename:previousFilename];

    _comic = comic;

    if (!self.comic.viewed) {
        [self.dataManager markComicViewed:comic];
    }

    self.title = comic.safeTitle;
    self.containerView.zoomScale = 1.0;

    if (comic.transcript.length > 0) {
        self.comicImageView.accessibilityLabel = comic.transcript;
    }

    UIImage *cachedImage = [self.imageManager loadImageWithFilename:[comic getFilename] urlString:comic.imageURLString handler:^(UIImage *image) {
        self.comicImageView.image = image;
    }];
    self.comicImageView.image = cachedImage ?: [ThemeManager loadingImage];

    [self.favoriteButton setAlpha:self.comic.favorite ? 1.0 : kFavoritedButtonNonFavoriteAlpha];

    self.altView.comic = comic;

    [self updateBookmarkButtonImage];
}

- (void)setPreviewMode:(BOOL)previewMode {
	_previewMode = previewMode;
	self.buttonContainerView.hidden = previewMode;
}

#pragma mark - Alt

- (void)toggleAltView {
    if (!self.altView.isVisible) {
        self.viewedAlt = YES;
        self.containerView.zoomScale = 1.0;

        [self.altView showInView:self.view];
    } else {
        [self.altView dismiss];
    }
}


#pragma mark - Favorite

- (void)toggleComicFavorited {
    BOOL isNowFavorited = !self.comic.favorite;

    [self.dataManager markComic:self.comic favorited:isNowFavorited];

    [self.favoriteButton setAlpha:isNowFavorited ? 1.0 : kFavoritedButtonNonFavoriteAlpha];
}


#pragma mark - Bookmark

- (void)toggleBookmark {
    // If this is currently bookmarked, un-bookmark it, and vice-versa.
    BOOL isCurrentlyBookmarked = self.comic.num == [self.dataManager bookmarkedComicNumber];
    NSInteger bookmarkedComicNum = isCurrentlyBookmarked ? 0 : self.comic.num;

    [self.dataManager setBookmarkedComic:bookmarkedComicNum];

    // Update the image on the button.
    [self updateBookmarkButtonImage];
}

- (void)updateBookmarkButtonImage {
    BOOL isCurrentlyBookmarked = self.comic.num == [self.dataManager bookmarkedComicNumber];
    UIImage *newImage = isCurrentlyBookmarked ? [ThemeManager bookmarkedImage] : [ThemeManager bookmarkedOffImage];
    [self.bookmarkButton setImage:newImage forState:UIControlStateNormal];
}


#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.comicImageView;
}

#pragma mark - Sharing

- (void)handleShareButton {
    NSArray *activityItems = self.comicImage ? @[[NSURL URLWithString:self.comic.comicURLString ?: @""], self.comicImage] : @[[NSURL URLWithString:self.comic.comicURLString ?: @""]];
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:shareSheet animated:YES completion:nil];
}

#pragma mark - Comic view delegate

- (void)updateToNewComic:(Comic *)comic hasPrevious:(BOOL)hasPrevious hasNext:(BOOL)hasNext {
    self.comic = comic;

    self.prevButton.hidden = !hasPrevious;
    self.prevSwipe.enabled = hasPrevious;
    self.nextButton.hidden = !hasNext;
    self.nextSwipe.enabled = hasNext;

    [self.randomComicButton setImage:[ThemeManager randomImage] forState:UIControlStateNormal];
}

#pragma mark - Alt view delegate

- (void)altView:(AltView *)altView didSelectExplainForComic:(Comic *)comic {
    [altView dismiss];

    ComicWebViewController *comicWebVC = [ComicWebViewController new];
    comicWebVC.title = kExplainTitle;
    comicWebVC.URLString = comic.explainURLString;
    [self.navigationController pushViewController:comicWebVC animated:YES];
}

- (void)altView:(AltView *)altView didSelectViewOnWebForComic:(Comic *)comic {
    [altView dismiss];

    ComicWebViewController *comicWebVC = [ComicWebViewController new];
    comicWebVC.title = comic.title;
    comicWebVC.URLString = comic.comicURLString;
    [self.navigationController pushViewController:comicWebVC animated:YES];
}

@end
