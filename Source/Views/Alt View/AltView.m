//
//  AltView.m
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "AltView.h"
#import "ThemeManager.h"
#import <UIView+Facade.h>

static CGFloat const kAltViewPadding = 10.0;

@implementation AltView

- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

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
    [ThemeManager addParallaxToView:self.containerView];

    self.dateLabel = [UILabel new];
    self.dateLabel.font = [ThemeManager xkcdFontWithSize:18];
    self.dateLabel.textColor = [UIColor whiteColor];
    self.dateLabel.numberOfLines = 0;
    [self addSubview:self.dateLabel];

    self.altLabel = [UILabel new];
    self.altLabel.font = [ThemeManager xkcdFontWithSize:18];
    self.altLabel.textColor = [UIColor whiteColor];
    self.altLabel.textAlignment = NSTextAlignmentCenter;
    self.altLabel.numberOfLines = 0;
    [self.containerView addSubview:self.altLabel];

    self.explainButton = [UIButton new];
    self.explainButton.accessibilityLabel = NSLocalizedString(@"comic.explain.accessibility", nil);
    self.explainButton.titleLabel.font = [ThemeManager xkcdFontWithSize:15];
    self.explainButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.explainButton.clipsToBounds = YES;
    self.explainButton.showsTouchWhenHighlighted = YES;
    self.explainButton.backgroundColor = [ThemeManager xkcdLightBlue];
    [self.explainButton setTitle:NSLocalizedString(@"comic.explain.title", nil) forState:UIControlStateNormal];
    [self.explainButton addTarget:self action:@selector(handleExplain) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.explainButton];

    [ThemeManager addBorderToLayer:self.explainButton.layer radius:3.0 color:[UIColor whiteColor]];
}


#pragma mark - Layout

- (void)layoutFacade {
    CGFloat padding = CGRectGetWidth(self.superview.frame) * 0.1;

    [self fillSuperview];

    [self.dateLabel anchorTopCenterFillingWidthWithLeftAndRightPadding:10 topPadding:10 height:0.0];
    [self.dateLabel sizeToFit];
    [self.dateLabel anchorTopCenterFillingWidthWithLeftAndRightPadding:10 topPadding:10 height:self.dateLabel.height];

    // Establish the height we want, then size the label to fit - giving us the resulting
    // height / width of the label.
    [self.containerView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:padding topAndBottomPadding:padding];
    [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:kAltViewPadding topAndBottomPadding:kAltViewPadding];
    [self.altLabel sizeToFit];
    [self.containerView anchorInCenterWithWidth:CGRectGetWidth(self.superview.frame) - (2 * padding) height:CGRectGetHeight(self.altLabel.frame) + (2 * kAltViewPadding)];
    [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:kAltViewPadding topAndBottomPadding:kAltViewPadding];

    CGFloat maxContainerSize = CGRectGetHeight(self.superview.frame) - (2 * kAltViewPadding) - CGRectGetMaxY(self.dateLabel.frame);

    if (CGRectGetHeight(self.containerView.frame) > maxContainerSize) {
        [self.containerView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:2 * kAltViewPadding topAndBottomPadding:6 * kAltViewPadding];
        [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:kAltViewPadding topAndBottomPadding:kAltViewPadding];

        self.altLabel.adjustsFontSizeToFitWidth = YES;
    }

    [self.explainButton anchorTopRightWithRightPadding:10.0 topPadding:10.0 width:100.0 height:40.0];
}


#pragma mark - Setters

- (void)setComic:(Comic *)comic {
    _comic = comic;

    self.dateLabel.text = [NSString stringWithFormat:@"#%@\n%@", @(self.comic.num), self.comic.formattedDateString];
    self.altLabel.text = self.comic.alt;
}


#pragma mark - Showing and hiding

- (void)showInView:(UIView *)superview {
    [superview addSubview:self];

    [self layoutFacade];
    self.isVisible = YES;

    [UIView animateWithDuration:0.3 animations:^{
        self.alpha = 1.0;
    }];
}

- (void)dismiss {
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
        self.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self removeFromSuperview];

        self.isVisible = NO;
    }];
}


#pragma mark - Touch handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self dismiss];
}


#pragma mark - Explain

- (void)handleExplain {
    [self.delegate altView:self didSelectExplainForComic:self.comic];
}

@end
