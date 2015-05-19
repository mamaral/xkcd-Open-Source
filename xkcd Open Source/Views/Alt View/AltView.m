//
//  AltView.m
//  xkcDump
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "AltView.h"
#import "ThemeManager.h"
#import <UIView+Facade.h>

@implementation AltView

- (instancetype)initWithAltText:(NSString *)altText {
    self = [super init];

    self.altText = altText;

    [self setupAltView];

    return self;
}

- (void)setupAltView {
    self.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.7];

    self.containerView = [UIView new];
    self.containerView.backgroundColor = [ThemeManager xkcdLightBlue];
    [self addSubview:self.containerView];

    [ThemeManager addBorderToLayer:self.containerView.layer radius:kDefaultCornerRadius color:[UIColor whiteColor]];
    [ThemeManager addShadowToLayer:self.containerView.layer radius:15.0 opacity:0.8];

    self.altLabel = [UILabel new];
    self.altLabel.text = self.comic.alt;
    self.altLabel.font = [ThemeManager xkcdFontWithSize:20];
    self.altLabel.textColor = [UIColor whiteColor];
    self.altLabel.textAlignment = NSTextAlignmentCenter;
    self.altLabel.numberOfLines = 0;
    [self.containerView addSubview:self.altLabel];

    self.dateLabel = [UILabel new];
    self.dateLabel.font = [ThemeManager xkcdFontWithSize:20];
    self.dateLabel.textColor = [UIColor whiteColor];
    self.dateLabel.text = self.comic.formattedDateString;
    [self addSubview:self.dateLabel];
}

- (void)layoutFacade {
    CGFloat padding = CGRectGetWidth(self.superview.frame) * 0.1;

    [self fillSuperview];

    [self.dateLabel anchorTopCenterFillingWidthWithLeftAndRightPadding:10 topPadding:10 height:20];

    // Establish the height we want, then size the label to fit - giving us the resulting
    // height / width of the label.
    [self.containerView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:padding topAndBottomPadding:padding];
    [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:kAltViewPadding topAndBottomPadding:kAltViewPadding];
    [self.altLabel sizeToFit];

    [self.containerView anchorInCenterWithWidth:CGRectGetWidth(self.superview.frame) - (2 * padding) height:CGRectGetHeight(self.altLabel.frame) + (2 * kAltViewPadding)];
    [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:kAltViewPadding topAndBottomPadding:kAltViewPadding];
}

- (void)show {
    [self layoutFacade];
    self.isVisible = YES;

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)dismissWithCompletion:(dispatch_block_t)completion {
    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        completion();

        self.isVisible = NO;
    }];
}

@end
