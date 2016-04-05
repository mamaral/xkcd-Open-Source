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
#import <SDWebImagePrefetcher.h>
#import <TwitterKit/TwitterKit.h>

static CGFloat const kComicViewControllerPadding = 10.0;
static CGFloat const kBottomButtonSpacing = 15.0;
static CGFloat const kBottomButtonPadding = 10.0;
static CGFloat const kBottomButtonSize = 50.0;
static CGFloat const kFavoritedButtonNonFavoriteAlpha = 0.3;

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"..." style:UIBarButtonItemStylePlain target:self action:@selector(toggleAltView)];
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
    [self.view addSubview:self.favoriteButton];
    
    self.randomComicButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.randomComicButton.adjustsImageWhenHighlighted = NO;
    self.randomComicButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentFill;
    self.randomComicButton.contentVerticalAlignment = UIControlContentVerticalAlignmentFill;
    [self.randomComicButton setImage:[ThemeManager randomImage] forState:UIControlStateNormal];
    [self.randomComicButton addTarget:self action:@selector(showRandomComic) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.randomComicButton];

    self.prevButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.prevButton.adjustsImageWhenHighlighted = NO;
    [self.prevButton setImage:[ThemeManager prevComicImage] forState:UIControlStateNormal];
    [self.prevButton addTarget:self action:@selector(showPrev) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.prevButton];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.nextButton.adjustsImageWhenHighlighted = NO;
    [self.nextButton setImage:[ThemeManager nextComicImage] forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(showNext) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:self.nextButton];

    self.facebookShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.facebookShareButton setImage:[ThemeManager facebookImage] forState:UIControlStateNormal];
    [self.facebookShareButton addTarget:self action:@selector(handleFacebookShare) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.facebookShareButton];

    self.twitterShareButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.twitterShareButton setImage:[ThemeManager twitterImage] forState:UIControlStateNormal];
    [self.twitterShareButton addTarget:self action:@selector(handleTwitterShare) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.twitterShareButton];

    self.altView = [AltView new];
    self.altView.alpha = 0.0;
}

- (void)layoutFacade {
    [self.containerView fillSuperview];
    self.containerView.contentSize = self.containerView.frame.size;
    
    [self.prevButton anchorBottomLeftWithLeftPadding:kBottomButtonPadding bottomPadding:kBottomButtonPadding width:kBottomButtonSize height:kBottomButtonSize];
    [self.favoriteButton alignToTheRightOf:self.facebookShareButton matchingCenterWithLeftPadding:kBottomButtonSpacing width:kBottomButtonSize height:kBottomButtonSize];
    [self.randomComicButton alignToTheRightOf:self.favoriteButton matchingCenterWithLeftPadding:kBottomButtonSpacing width:kBottomButtonSize height:kBottomButtonSize];
    [self.facebookShareButton alignToTheRightOf:self.prevButton matchingCenterWithLeftPadding:kBottomButtonSpacing width:kBottomButtonSize height:kBottomButtonSize];
    [self.twitterShareButton alignToTheRightOf:self.randomComicButton matchingCenterWithLeftPadding:kBottomButtonSpacing width:kBottomButtonSize height:kBottomButtonSize];
    [self.nextButton anchorBottomRightWithRightPadding:kBottomButtonPadding bottomPadding:kBottomButtonPadding width:kBottomButtonSize height:kBottomButtonSize];

    [self.comicImageView anchorTopCenterWithTopPadding:kComicViewControllerPadding width:self.view.width - (kComicViewControllerPadding * 2) height:self.favoriteButton.yMin - (2 * kComicViewControllerPadding)];

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

    [self.comicImageView sd_setImageWithURL:[NSURL URLWithString:comic.imageURLString ?: @""] placeholderImage:[ThemeManager loadingImage]];
    [self.favoriteButton setAlpha:self.comic.favorite ? 1.0 : kFavoritedButtonNonFavoriteAlpha];

    self.prevButton.hidden = !self.allowComicNavigation || [self.delegate comicViewController:self comicBeforeCurrentComic:comic] == nil;
    self.nextButton.hidden = !self.allowComicNavigation || [self.delegate comicViewController:self comicAfterCurrentComic:comic] == nil;

    [self prefetchImagesForComicsBeforeAndAfter];

    self.altView.comic = comic;
}


#pragma mark - Alt

- (void)toggleAltView {
    if (!self.altView.isVisible) {
        _viewedAlt = YES;

        [self.altView showInView:self.view];
    }

    else {
        [self.altView dismiss];
    }
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

#pragma mark - Navigation between comics

- (void)showPrev {
    self.comic = [self.delegate comicViewController:self comicBeforeCurrentComic:self.comic];
}

- (void)showNext {  
    self.comic = [self.delegate comicViewController:self comicAfterCurrentComic:self.comic];
}

- (void)showRandomComic {
    self.comic = [self.delegate comicViewController:self randomComic:self.comic];
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


#pragma mark - Facebook Sharing

- (void)handleFacebookShare {
    FBSDKShareLinkContent *shareLinkContent = [FBSDKShareLinkContent new];
    shareLinkContent.contentTitle = self.comic.safeTitle;
    shareLinkContent.contentURL = [self.comic generateShareURL];

    [FBSDKShareDialog showFromViewController:self withContent:shareLinkContent delegate:self];
}

- (void)sharerDidCancel:(id<FBSDKSharing>)sharer {
    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Social Share" action:@"Facebook" label:@"Cancel"];
}

- (void)sharer:(id<FBSDKSharing>)sharer didFailWithError:(NSError *)error {
    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Social Share" action:@"Facebook" label:[NSString stringWithFormat:@"Error: %@", error.localizedDescription]];
}

- (void)sharer:(id<FBSDKSharing>)sharer didCompleteWithResults:(NSDictionary *)results {
    [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Social Share" action:@"Facebook" label:@"Success"];
}


#pragma mark - Twitter sharing

- (void)handleTwitterShare {
    [[Twitter sharedInstance] logInWithCompletion:^(TWTRSession *session, NSError *error) {
        if (error) {
            [[[UIAlertView alloc] initWithTitle:@"Uh oh..." message:[NSString stringWithFormat:@"Twitter said something went wrong. Don't blame me..."] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
            return;
        }

        TWTRComposer *composer = [TWTRComposer new];
        [composer setText:self.comic.safeTitle];
        [composer setImage:self.comicImageView.image];
        [composer setURL:[self.comic generateShareURL]];
        [composer showFromViewController:self completion:^(TWTRComposerResult result) {
            [[GTTracker sharedInstance] sendAnalyticsEventWithCategory:@"Social Share" action:@"Twitter" label:(result == TWTRComposerResultCancelled) ? @"Cancel" : @"Success"];
        }];
    }];
}

@end
