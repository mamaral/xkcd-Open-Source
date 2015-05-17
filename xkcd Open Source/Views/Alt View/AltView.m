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
    self.backgroundColor = [ThemeManager xkcdLightBlue];

    [ThemeManager addBorderToLayer:self.layer radius:kDefaultCornerRadius color:[UIColor whiteColor]];
    [ThemeManager addShadowToLayer:self.layer];

    self.altLabel = [UILabel new];
    self.altLabel.text = self.altText;
    self.altLabel.font = [ThemeManager xkcdFontWithSize:20];
    self.altLabel.textColor = [UIColor whiteColor];
    self.altLabel.textAlignment = NSTextAlignmentCenter;
    self.altLabel.numberOfLines = 0;
    [self addSubview:self.altLabel];
}

- (void)layoutFacade {
    CGFloat padding = CGRectGetWidth(self.superview.frame) * 0.1;

    // Establish the height we want, then size the label to fit - giving us the resulting
    // height / width of the label.
    [self anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:padding topAndBottomPadding:padding];
    [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:10 topAndBottomPadding:10];
    [self.altLabel sizeToFit];

    [self anchorInCenterWithWidth:CGRectGetWidth(self.superview.frame) - (2 * padding) height:CGRectGetHeight(self.altLabel.frame) + 20];
    [self.altLabel anchorInCenterFillingWidthAndHeightWithLeftAndRightPadding:10 topAndBottomPadding:10];
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
