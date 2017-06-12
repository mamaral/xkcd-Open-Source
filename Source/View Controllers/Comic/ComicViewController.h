

//
//  ComicViewController.h
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"

@class ComicPresenter;

@interface ComicViewController : UIViewController <UIScrollViewDelegate>

- (instancetype)initWithPresenter:(ComicPresenter *)presenter;

@property (nonatomic, strong) Comic *comic;

@property (nonatomic) BOOL previewMode;

@end
