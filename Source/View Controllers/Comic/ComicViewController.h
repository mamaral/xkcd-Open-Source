

//
//  ComicViewController.h
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <FBSDKShareKit/FBSDKShareKit.h>
#import "Comic.h"
#import "AltView.h"

@class ComicViewController;

@protocol ComicViewControllerDelegate <NSObject>

@required
- (Comic *)comicViewController:(ComicViewController *)comicViewController comicBeforeCurrentComic:(Comic *)currentComic;
- (Comic *)comicViewController:(ComicViewController *)comicViewController comicAfterCurrentComic:(Comic *)currentComic;

@end

@interface ComicViewController : UIViewController <UIScrollViewDelegate, FBSDKSharingDelegate>

@property (nonatomic) id<ComicViewControllerDelegate> delegate;

@property (nonatomic, strong) Comic *comic;

@property (nonatomic) BOOL allowComicNavigation;

@property (nonatomic, strong) UIScrollView *containerView;
@property (nonatomic, strong) UIImageView *comicImageView;
@property (nonatomic, strong) AltView *altView;
@property (nonatomic, strong) UIButton *favoriteButton;
@property (nonatomic, strong) UIButton *prevButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIButton *facebookShareButton;
@property (nonatomic, strong) UIButton *twitterShareButton;

@end
