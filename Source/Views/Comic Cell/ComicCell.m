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

static CGFloat const kComicCellNumberLabelWidth = 35.0;

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

    self.numberLabel = [UILabel new];
    self.numberLabel.textAlignment = NSTextAlignmentCenter;
    self.numberLabel.textColor = [UIColor whiteColor];
    self.numberLabel.backgroundColor = [ThemeManager xkcdLightBlue];
    self.numberLabel.font = [ThemeManager xkcdFontWithSize:11];
    self.numberLabel.adjustsFontSizeToFitWidth = YES;
    self.numberLabel.clipsToBounds = YES;
    [self.containerView addSubview:self.numberLabel];

    [ThemeManager addBorderToLayer:self.numberLabel.layer radius:kComicCellNumberLabelWidth / 2.0 color:[UIColor whiteColor]];

    self.highlightedMask = [UIView new];
    self.highlightedMask.backgroundColor = [UIColor blackColor];
    self.highlightedMask.alpha = 0.0;
    [self.containerView addSubview:self.highlightedMask];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [self.containerView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:3 topAndBottomPadding:3];
    [self.imageView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:7 topAndBottomPadding:7];
    [self.maskView fillSuperview];
    [self.numberLabel anchorBottomRightWithRightPadding:4 bottomPadding:4 width:kComicCellNumberLabelWidth height:kComicCellNumberLabelWidth];
    [self.highlightedMask fillSuperview];
}

- (void)setComic:(Comic *)comic {
    _comic = comic;

    [self.imageView sd_setImageWithURL:[NSURL URLWithString:comic.imageURLString] placeholderImage:[ThemeManager loadingImage]];
    self.numberLabel.text = [NSString stringWithFormat:@"%ld", (long)comic.num];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    CGFloat newAlpha = highlighted ? 0.4 : 0.0;

    [UIView animateWithDuration:0.4 animations:^{
        self.highlightedMask.alpha = newAlpha;
    }];
}

@end
