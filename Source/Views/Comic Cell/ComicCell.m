//
//  ComicCell.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ComicCell.h"
#import <UIView+Facade.h>
#import <UIImageView+WebCache.h>
#import "ThemeManager.h"
#import "DataManager.h"
#import "Assembler.h"
#import "ImageManager.h"

static CGFloat const kComicCellNumberLabelWidth = 35.0;
static CGFloat const kFavoriteIconSize = 55.0;

@interface ComicCell ()

@property (nonatomic, weak) ImageManager *imageManager;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIView *maskView;
@property (nonatomic, strong) UIButton *comicNumberButton;
@property (nonatomic, strong) UIView *highlightedMask;
@property (nonatomic, strong) UIImageView *favoritedIcon;

@end

@implementation ComicCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self == nil) {
        return nil;
    }

    self.imageManager = [Assembler sharedInstance].imageManager;
    self.containerView = [UIView new];
    self.imageView = [UIImageView new];
    self.maskView = [UIView new];
    self.comicNumberButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.highlightedMask = [UIView new];
    self.favoritedIcon = [[UIImageView alloc] initWithImage:[ThemeManager favoriteImage]];
    self.isAccessibilityElement = YES;

    [self generateCell];

    return self;
}

- (void)generateCell {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    self.contentView.clipsToBounds = YES;

    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.clipsToBounds = YES;
    self.containerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.containerView];

    [ThemeManager addBorderToLayer:self.containerView.layer radius:kDefaultCornerRadius color:[UIColor blackColor]];

    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    [self.containerView addSubview:self.imageView];

    self.maskView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    [self.containerView addSubview:self.maskView];

    [self.comicNumberButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.comicNumberButton.titleLabel.font = [ThemeManager xkcdFontWithSize:11];
    self.comicNumberButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.comicNumberButton.clipsToBounds = YES;
    self.comicNumberButton.showsTouchWhenHighlighted = YES;
    [self.comicNumberButton addTarget:self action:@selector(handleComicNumberSelected) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:self.comicNumberButton];

    [ThemeManager addBorderToLayer:self.comicNumberButton.layer radius:kComicCellNumberLabelWidth / 2.0 color:[UIColor whiteColor]];

    self.highlightedMask.backgroundColor = [UIColor blackColor];
    self.highlightedMask.alpha = 0.0;
    [self.containerView addSubview:self.highlightedMask];

    [self.contentView addSubview:self.favoritedIcon];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self.containerView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:3 topAndBottomPadding:3];
    [self.imageView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:7 topAndBottomPadding:7];
    [self.maskView fillSuperview];
    [self.comicNumberButton anchorBottomRightWithRightPadding:4 bottomPadding:4 width:kComicCellNumberLabelWidth height:kComicCellNumberLabelWidth];
    [self.highlightedMask fillSuperview];
    [self.favoritedIcon anchorTopLeftWithLeftPadding:0 topPadding:0 width:kFavoriteIconSize height:kFavoriteIconSize];
}

- (void)setComic:(Comic *)comic {
    // First we need to grab the filename for the previous comic so we can cancel
    // the download handler for it. This will prevent this cell from loading an
    // outdated image if users scroll really fast and this cell is reused.
    NSString *previousFilename = [self.comic getFilename];
    [self.imageManager cancelDownloadHandlerForFilename:previousFilename];

    // Now we can set our local comic.
    _comic = comic;

    // Get the existing cached image from our image manager.
    UIImage *existingImage = [self.imageManager loadImageWithFilename:[comic getFilename] urlString:comic.imageURLString handler:^(UIImage *image) {
        // Update our image view with the newly loaded image.
        self.imageView.image = image;
    }];

    // If we have an existing image, update our image view with it, otherwise
    // use the loading image as a placeholder.
    self.imageView.image = existingImage ?: [ThemeManager loadingImage];

    self.maskView.alpha = comic.viewed ? 1.0 : 0.0;
    [self.comicNumberButton setTitle:[NSString stringWithFormat:@"%ld", (long)comic.num] forState:UIControlStateNormal];
    self.comicNumberButton.backgroundColor = comic.viewed ? [ThemeManager comicViewedColor] : [ThemeManager xkcdLightBlue];
    self.favoritedIcon.hidden = !comic.favorite;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    CGFloat newAlpha = highlighted ? 0.4 : 0.0;

    [UIView animateWithDuration:0.4 animations:^{
        self.highlightedMask.alpha = newAlpha;
    }];
}


#pragma mark - Comic number button handling

- (void)handleComicNumberSelected {
    [self.delegate comicCell:self didSelectComicAltWithComic:self.comic];
}


#pragma mark - Accessibility

- (NSString *)accessibilityLabel {
    return self.comic.safeTitle;
}

- (UIAccessibilityTraits)accessibilityTraits {
    return UIAccessibilityTraitStaticText;
}

@end
