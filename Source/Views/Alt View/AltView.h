//
//  AltView.h
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"

@class AltView;

@protocol AltViewDelegate <NSObject>

- (void)altView:(AltView *)altView didSelectExplainForComic:(Comic *)comic;

@end

@interface AltView : UIView

@property (nonatomic, weak) id<AltViewDelegate> delegate;

@property (nonatomic, strong) Comic *comic;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *altLabel;
@property (nonatomic, strong) UILabel *dateLabel;
@property (nonatomic, strong) UIButton *explainButton;

@property (nonatomic) BOOL isVisible;

- (void)layoutFacade;
- (void)showInView:(UIView *)superview;
- (void)dismiss;

@end
