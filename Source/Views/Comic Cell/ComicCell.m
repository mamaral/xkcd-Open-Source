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

static CGFloat const kComicCellNumberLabelWidth = 35.0;
static CGFloat const kFavoriteIconSize = 55.0;

@implementation ComicCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    [self generateCell];

    return self;
}

- (void)generateCell {
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;
    self.contentView.clipsToBounds = YES;

    self.containerView = [UIView new];
    self.containerView.backgroundColor = [UIColor whiteColor];
    self.containerView.clipsToBounds = YES;
    self.containerView.layer.masksToBounds = YES;
    [self.contentView addSubview:self.containerView];

    [ThemeManager addBorderToLayer:self.containerView.layer radius:kDefaultCornerRadius color:[UIColor blackColor]];
    
    self.imageView = [UIImageView new];
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.imageView.clipsToBounds = YES;
    [self.containerView addSubview:self.imageView];

    self.maskView = [UIView new];
    self.maskView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.4];
    [self.containerView addSubview:self.maskView];

    self.numberLabel = [UILabel new];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    self.numberLabel.textColor = [UIColor whiteColor];
    self.numberLabel.font = [ThemeManager xkcdFontWithSize:11];
    self.numberLabel.adjustsFontSizeToFitWidth = YES;
    self.numberLabel.clipsToBounds = YES;
    [self.containerView addSubview:self.numberLabel];

    [ThemeManager addBorderToLayer:self.numberLabel.layer radius:kComicCellNumberLabelWidth / 2.0 color:[UIColor whiteColor]];

    self.highlightedMask = [UIView new];
    self.highlightedMask.backgroundColor = [UIColor blackColor];
    self.highlightedMask.alpha = 0.0;
    [self.containerView addSubview:self.highlightedMask];

    self.favoritedIcon = [[UIImageView alloc] initWithImage:[ThemeManager favoriteImage]];
    [self.contentView addSubview:self.favoritedIcon];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self.containerView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:3 topAndBottomPadding:3];
    [self.imageView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:7 topAndBottomPadding:7];
    [self.maskView fillSuperview];
    [self.numberLabel anchorBottomRightWithRightPadding:4 bottomPadding:4 width:kComicCellNumberLabelWidth height:kComicCellNumberLabelWidth];
    [self.highlightedMask fillSuperview];
    [self.favoritedIcon anchorTopLeftWithLeftPadding:2 topPadding:2 width:kFavoriteIconSize height:kFavoriteIconSize];
}

- (void)setComic:(Comic *)comic {
    _comic = comic;

    [self.imageView sd_setImageWithURL:[NSURL URLWithString:comic.imageURLString] placeholderImage:[ThemeManager loadingImage]];

    self.maskView.alpha = comic.viewed ? 1.0 : 0.0;
    self.numberLabel.backgroundColor = comic.viewed ? [ThemeManager comicViewedColor] : [ThemeManager xkcdLightBlue];
    self.numberLabel.text = [NSString stringWithFormat:@"%ld", (long)comic.num];
    self.favoritedIcon.hidden = !comic.favorite;
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    CGFloat newAlpha = highlighted ? 0.4 : 0.0;

    [UIView animateWithDuration:0.4 animations:^{
        self.highlightedMask.alpha = newAlpha;
    }];
}

@end
