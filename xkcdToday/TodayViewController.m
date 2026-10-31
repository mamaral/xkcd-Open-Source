//
//  TodayViewController.m
//  xkcdToday
//
//  Created by Mike on 9/24/16.
//  Copyright © 2016 Mike Amaral. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import <UIImageView+WebCache.h>
#import <UIView+Facade.h>
#import "DataManager.h"
#import "ThemeManager.h"
#import "XKCDDeviceManager.h"

static CGFloat const kComicNumberLabelPadding = 7.0;
static CGFloat const kMaxContentHeight = 300.0;

@interface TodayViewController () <NCWidgetProviding>

@property (strong, nonatomic) Comic *comic;
@property (strong, nonatomic) UIImageView *comicImageView;
@property (strong, nonatomic) UILabel *comicNumberLabel;

@end

@implementation TodayViewController

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self.extensionContext respondsToSelector:@selector(setWidgetLargestAvailableDisplayMode:)]) {
        [self.extensionContext setWidgetLargestAvailableDisplayMode:NCWidgetDisplayModeExpanded];
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];

    self.comicImageView = [UIImageView new];
    self.comicImageView.backgroundColor = [UIColor whiteColor];
    self.comicImageView.contentMode = UIViewContentModeScaleAspectFill;
    [self.view addSubview:self.comicImageView];

    self.comicNumberLabel = [UILabel new];
    self.comicNumberLabel.textColor = [UIColor whiteColor];
    self.comicNumberLabel.font = [ThemeManager xkcdFontWithSize:11];
    self.comicNumberLabel.adjustsFontSizeToFitWidth = YES;
    self.comicNumberLabel.clipsToBounds = YES;
    self.comicNumberLabel.textAlignment = NSTextAlignmentCenter;
    [self.comicImageView addSubview:self.comicNumberLabel];
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self updateLayout];
}

- (void)updateLayout {
    [self.comicImageView fillSuperview];

    [self.comicNumberLabel sizeToFit];

    CGFloat labelSize = self.comicNumberLabel.width + kComicNumberLabelPadding;
    [self.comicNumberLabel anchorTopLeftWithLeftPadding:kComicNumberLabelPadding topPadding:kComicNumberLabelPadding width:labelSize height:labelSize];
    [ThemeManager addBorderToLayer:self.comicNumberLabel.layer radius:labelSize / 2.0 color:[UIColor whiteColor]];
}


#pragma mark - Widget delegate

- (void)widgetActiveDisplayModeDidChange:(NCWidgetDisplayMode)activeDisplayMode withMaximumSize:(CGSize)maxSize {
    self.preferredContentSize = activeDisplayMode == NCWidgetDisplayModeCompact ? maxSize : CGSizeMake(0, [self expandedComicHeight]);
}

- (CGFloat)expandedComicHeight {
    CGFloat aspectRatio = self.comic.aspectRatio > 0 ? self.comic.aspectRatio : kDefaultAspectRatio;
    CGFloat actualHeight = [XKCDDeviceManager screenWidth] / aspectRatio;
    return MIN(actualHeight, kMaxContentHeight);
}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Fetch the comics and show the most recent.
    [[DataManager sharedInstance] downloadLatestComicWithCompletionHandler:^(Comic *comic, BOOL wasNew) {
        if (comic) {
            self.comic = comic;
            completionHandler(wasNew ? NCUpdateResultNewData : NCUpdateResultNoData);
        } else {
            completionHandler(NCUpdateResultFailed);
        }
    }];
}


#pragma mark - Setters

- (void)setComic:(Comic *)comic {
    _comic = comic;

    self.comicNumberLabel.text = [NSString stringWithFormat:@"%ld", (long)comic.num];
    self.comicNumberLabel.backgroundColor = [ThemeManager xkcdLightBlue];

    [self.comicImageView sd_setImageWithURL:[NSURL URLWithString:comic.imageURLString ?: @""] placeholderImage:[ThemeManager loadingImage] completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
        if (!image || image.size.height <= 0 || comic != self.comic) {
            return;
        }

        // Now that we know the image's real dimensions, resize if we're expanded.
        [[DataManager sharedInstance] updateAspectRatio:image.size.width / image.size.height forComic:comic];

        if (self.extensionContext.widgetActiveDisplayMode == NCWidgetDisplayModeExpanded) {
            self.preferredContentSize = CGSizeMake(0, [self expandedComicHeight]);
        }
    }];

    [self updateLayout];
}

@end
