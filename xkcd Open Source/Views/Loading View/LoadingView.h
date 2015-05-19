//
//  LoadingView.h
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FLAnimatedImage.h"

@interface LoadingView : UIView

@property (nonatomic) BOOL isVisible;
@property (nonatomic, strong) UILabel *loadingLabel;
@property (nonatomic, strong) UIView *imageViewContainer;
@property (nonatomic, strong) FLAnimatedImageView *animatedImageView;
@property (nonatomic, strong) UIButton *doneButton;

+ (void)showInView:(UIView *)superview;
+ (void)handleLayoutChanged;
+ (void)handleDoneLoading;
+ (void)dismiss;
+ (BOOL)isVisible;

@end
