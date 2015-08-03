//
//  AltView.h
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"

@interface AltView : UIView

@property (nonatomic, strong) Comic *comic;

@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, strong) UILabel *altLabel;
@property (nonatomic, strong) UILabel *dateLabel;

@property (nonatomic) BOOL isVisible;

- (void)layoutFacade;
- (void)show;
- (void)dismissWithCompletion:(dispatch_block_t)completion;

@end
