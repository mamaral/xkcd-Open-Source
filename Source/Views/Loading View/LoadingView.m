//
//  LoadingView.m
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "LoadingView.h"
#import <UIView+Facade.h>
#import "ThemeManager.h"

@implementation LoadingView


#pragma mark - Singleton

+ (LoadingView *)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}

- (instancetype)init {
    self = [super init];

    [self setupSubviews];
    
    return self;
}


#pragma mark - Creating subviews

- (void)setupSubviews {
    self.alpha = 0.0;
    self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.5];

    self.loadingLabel = [UILabel new];
    self.loadingLabel.backgroundColor = [UIColor whiteColor];
    self.loadingLabel.clipsToBounds = YES;
    self.loadingLabel.font = [ThemeManager xkcdFontWithSize:22];
    self.loadingLabel.text = NSLocalizedString(@"loading.button.title", nil);
    self.loadingLabel.textAlignment = NSTextAlignmentCenter;
    self.loadingLabel.textColor = [UIColor blackColor];
    [self addSubview:self.loadingLabel];

    [ThemeManager addBorderToLayer:self.loadingLabel.layer radius:kDefaultCornerRadius color:[UIColor blackColor]];

    self.imageViewContainer = [UIView new];
    self.imageViewContainer.backgroundColor = [UIColor whiteColor];
    [self addSubview:self.imageViewContainer];

    [ThemeManager addBorderToLayer:self.imageViewContainer.layer radius:kDefaultCornerRadius color:[UIColor blackColor]];

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"time-animated" ofType: @"gif"];
    NSData *data = [NSData dataWithContentsOfFile:filePath];

    FLAnimatedImage *image = [FLAnimatedImage animatedImageWithGIFData:data];
    self.animatedImageView = [FLAnimatedImageView new];
    self.animatedImageView.animatedImage = image;
    self.animatedImageView.contentMode = UIViewContentModeScaleAspectFit;
    [_imageViewContainer addSubview:self.animatedImageView];

    self.doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.doneButton.titleLabel.font = [ThemeManager xkcdFontWithSize:22];
    self.doneButton.alpha = 0.0;
    self.doneButton.userInteractionEnabled = NO;
    [self.doneButton setBackgroundColor:[UIColor whiteColor]];
    [self.doneButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.doneButton setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:UIControlStateHighlighted];
    [self.doneButton setTitle:NSLocalizedString(@"common.button.continue", nil) forState:UIControlStateNormal];
    [self.doneButton addTarget:[self class] action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.doneButton];

    [ThemeManager addBorderToLayer:self.doneButton.layer radius:kDefaultCornerRadius color:[UIColor blackColor]];
}


#pragma mark - View layout

+ (void)handleLayoutChanged {
    // For some reason layout subviews isn't called when rotation happens on an iPad? Need
    // to look into this more. For now, let our super view tell us to update.
    [[self sharedInstance] layoutSubviews];
}

- (void)layoutSubviews {
    [self fillSuperview];

    CGFloat imageViewAspectRatio = 1.4;
    CGFloat maxWidth = CGRectGetWidth(self.frame) * 0.9;
    CGFloat maxHeight = CGRectGetHeight(self.frame) * 0.6;
    CGFloat containerWidth = maxWidth;
    CGFloat containerHeight = containerWidth / imageViewAspectRatio;

    if (containerHeight > maxHeight) {
        containerHeight = maxHeight;
        containerWidth = containerHeight * imageViewAspectRatio;
    }

    [self.imageViewContainer anchorInCenterWithWidth:containerWidth height:containerHeight];
    [self.animatedImageView anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:10 topAndBottomPadding:10];
    [self.loadingLabel alignAbove:self.imageViewContainer matchingCenterWithBottomPadding:5 width:containerWidth height:44];
    [self.doneButton alignUnder:self.imageViewContainer matchingCenterWithTopPadding:5 width:containerWidth height:44];
}


#pragma mark - Showing and hiding

+ (void)showInView:(UIView *)superview {
    [superview addSubview:[self sharedInstance]];

    [[self sharedInstance] fillSuperview];

    [self sharedInstance].isVisible = YES;

    [self sharedInstance].loadingLabel.text = NSLocalizedString(@"loading.button.title", nil);
    [self sharedInstance].doneButton.alpha = 0.0;

    [UIView animateWithDuration:0.4 animations:^{
        [self sharedInstance].alpha = 1.0;
    }];
}

+ (void)handleDoneLoading {
    [self sharedInstance].doneButton.userInteractionEnabled = YES;

    [UIView animateWithDuration:0.2 animations:^{
        [self sharedInstance].doneButton.alpha = 1.0;
    }];

    CATransition *animation = [CATransition animation];
    animation.duration = 0.4;
    animation.type = kCATransitionFade;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [[self sharedInstance].loadingLabel.layer addAnimation:animation forKey:@"changeTextTransition"];
    [self sharedInstance].loadingLabel.text = NSLocalizedString(@"loading.button.complete", nil);
}

+ (void)dismiss {
    [UIView animateWithDuration:0.2 animations:^{
        [self sharedInstance].alpha = 0.0;
    } completion:^(BOOL finished) {
        [[self sharedInstance] removeFromSuperview];

        [self sharedInstance].isVisible = NO;
    }];
}


#pragma mark - Visibility

+ (BOOL)isVisible {
    return [self sharedInstance].isVisible;
}

@end
