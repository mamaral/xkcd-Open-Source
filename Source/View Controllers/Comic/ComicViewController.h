

//
//  ComicViewController.h
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"
#import "AltView.h"

@interface ComicViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) Comic *comic;
@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, strong) UIImageView *comicImageView;

@property (nonatomic, strong) UIButton *showAltButton;
@property (nonatomic, strong) AltView *altView;

@property (nonatomic, strong) UIButton *favoriteButton;

@end
