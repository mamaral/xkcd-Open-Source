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

static CGFloat const kComicViewControllerPadding = 10.0;
static CGFloat const kComicViewControllerSmallPadding = 7.0;
static CGFloat const kBottomButtonSize = 50.0;
static CGFloat const kFavoritedButtonNonFavoriteAlpha = 0.3;

@interface ComicViewController ()

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

@end

@implementation ComicViewController

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.prevSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showPrev)];
    self.nextSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showNext)];

    self.containerView = [UIScrollView new];
    self.comicImageView = [UIImageView new];
    self.buttonContainerView = [UIView new];
    self.favoriteButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.randomComicButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.altTextButton = [UIButton new];
    self.bookmarkButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.altView = [AltView new];

    return self;
}


#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(handleShareButton)];

    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.scrollEnabled = YES;
    self.containerView.minimumZoomScale = 1.0;
    self.containerView.maximumZoomScale = 10.0;
    self.containerView.delegate = self;
    [self.view addSubview:self.containerView];

    self.comicImageView.contentMode = UIViewContentModeScaleAspectFit;
    self.comicImageView.userInteractionEnabled = YES;
    [self.containerView addSubview:self.comicImageView];

    self.buttonContainerView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
    [self.view addSubview:self.buttonContainerView];

    self.bookmarkButton.adjustsImageWhenHighlighted = NO;
    [self.bookmarkButton setImage:[ThemeManager bookmarkedOffImage] forState:UIControlStateNormal];
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
    [self.randomComicButton addTarget:self action:@selector(showRandomComic) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.randomComicButton];

    self.prevButton.adjustsImageWhenHighlighted = NO;
    [self.prevButton setImage:[ThemeManager prevComicImage] forState:UIControlStateNormal];
    [self.prevButton addTarget:self action:@selector(showPrev) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.prevButton];

    self.prevSwipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:self.prevSwipe];

    self.nextSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    [self.view addGestureRecognizer:self.nextSwipe];

    self.nextButton.adjustsImageWhenHighlighted = NO;
    [self.nextButton setImage:[ThemeManager nextComicImage] forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(showNext) forControlEvents:UIControlEventTouchDown];
    [self.buttonContainerView addSubview:self.nextButton];

    [self.altTextButton setTitle:@"Alt" forState:UIControlStateNormal];
    [self.altTextButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.altTextButton setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.7] forState:UIControlStateHighlighted];
    [self.altTextButton.titleLabel setFont:[ThemeManager xkcdFontWithSize:20.0]];
    [self.altTextButton addTarget:self action:@selector(toggleAltView) forControlEvents:UIControlEventTouchUpInside];
    [self.buttonContainerView addSubview:self.altTextButton];

    self.altView.alpha = 0.0;
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
    [self.comicImageView anchorTopCenterWithTopPadding:kComicViewControllerPadding width:self.view.width - (kComicViewControllerPadding * 2) height:self.view.height - (2 * kComicViewControllerPadding) - kBottomButtonSize];

    // Layout the button container and buttons
    CGFloat spacing = [XKCDDeviceManager isSmallDevice] ? kComicViewControllerSmallPadding : kComicViewControllerPadding;
    [self.buttonContainerView anchorBottomCenterFillingWidthWithLeftAndRightPadding:0.0 bottomPadding:0.0 height:kBottomButtonSize];
    [self.prevButton anchorCenterLeftWithLeftPadding:spacing width:kBottomButtonSize height:kBottomButtonSize];
    [self.nextButton anchorCenterRightWithRightPadding:spacing width:kBottomButtonSize height:kBottomButtonSize];
    [self.buttonContainerView groupHorizontally:@[self.bookmarkButton, self.favoriteButton, self.randomComicButton, self.altTextButton] centeredFillingHeightWithSpacing:spacing width:kBottomButtonSize];

    // Layout the alt view if its on screen
    if (self.altView.isVisible) {
        [self.altView layoutFacade];
    }
}


#pragma mark - Setters

- (void)setComic:(Comic *)comic {
    _comic = comic;

    if (!self.comic.viewed) {
        [[DataManager sharedInstance] markComicViewed:comic];
    }

    self.title = comic.safeTitle;
    self.containerView.zoomScale = 1.0;

    [self.comicImageView sd_setImageWithURL:[NSURL URLWithString:comic.imageURLString ?: @""] placeholderImage:[ThemeManager loadingImage] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (image) {
            self.comicImage = image;
        }
    }];

    [self.favoriteButton setAlpha:self.comic.favorite ? 1.0 : kFavoritedButtonNonFavoriteAlpha];

    self.prevButton.hidden = !self.allowComicNavigation || [self.delegate comicViewController:self comicBeforeCurrentComic:comic] == nil;
    self.nextButton.hidden = !self.allowComicNavigation || [self.delegate comicViewController:self comicAfterCurrentComic:comic] == nil;
    
    self.prevSwipe.enabled = self.allowComicNavigation && [self.delegate comicViewController:self comicBeforeCurrentComic:comic] != nil;
    self.nextSwipe.enabled = self.allowComicNavigation && [self.delegate comicViewController:self comicAfterCurrentComic:comic] != nil;

    [self prefetchImagesForComicsBeforeAndAfter];

    self.altView.comic = comic;

    [self updateBookmarkButtonImage];
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

    [[DataManager sharedInstance] markComic:self.comic favorited:isNowFavorited];

    [self.favoriteButton setAlpha:isNowFavorited ? 1.0 : kFavoritedButtonNonFavoriteAlpha];
}


#pragma mark - Bookmark

- (void)toggleBookmark {
    // If this is currently bookmarked, un-bookmark it, and vice-versa.
    BOOL isCurrentlyBookmarked = self.comic.num == [[DataManager sharedInstance] bookmarkedComic];
    NSInteger bookmarkedComicNum = isCurrentlyBookmarked ? 0 : self.comic.num;

    [[DataManager sharedInstance] setBookmarkedComic:bookmarkedComicNum];

    // Update the image on the button.
    [self updateBookmarkButtonImage];
}

- (void)updateBookmarkButtonImage {
    BOOL isCurrentlyBookmarked = self.comic.num == [[DataManager sharedInstance] bookmarkedComic];
    UIImage *newImage = isCurrentlyBookmarked ? [ThemeManager bookmarkedImage] : [ThemeManager bookmarkedOffImage];
    [self.bookmarkButton setImage:newImage forState:UIControlStateNormal];
}


#pragma mark - Scroll view delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.comicImageView;
}

#pragma mark - Navigation between comics

- (void)showPrev {
    self.comic = [self.delegate comicViewController:self comicBeforeCurrentComic:self.comic];
}

- (void)showNext {  
    self.comic = [self.delegate comicViewController:self comicAfterCurrentComic:self.comic];
}

- (void)showRandomComic {
    self.comic = [self.delegate comicViewController:self randomComic:self.comic];
    [self.randomComicButton setImage:[ThemeManager randomImage] forState:UIControlStateNormal];
}
- (void)prefetchImagesForComicsBeforeAndAfter {
    Comic *prevComic = [self.delegate comicViewController:self comicBeforeCurrentComic:self.comic];
    Comic *nextComic = [self.delegate comicViewController:self comicAfterCurrentComic:self.comic];

    if (prevComic.imageURLString) {
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[[NSURL URLWithString:prevComic.imageURLString]]];
    }

    if (nextComic.imageURLString) {
        [[SDWebImagePrefetcher sharedImagePrefetcher] prefetchURLs:@[[NSURL URLWithString:nextComic.imageURLString]]];
    }
}


#pragma mark - Sharing

- (void)handleShareButton {
    NSArray *activityItems = self.comicImage ? @[[NSURL URLWithString:self.comic.comicURLString ?: @""], self.comicImage] : @[[NSURL URLWithString:self.comic.comicURLString ?: @""]];
    UIActivityViewController *shareSheet = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    shareSheet.popoverPresentationController.barButtonItem = self.navigationItem.rightBarButtonItem;
    [self presentViewController:shareSheet animated:YES completion:nil];
}

@end
