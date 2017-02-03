

//
//  ComicViewController.h
//  xkcd Open Source
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"

@class ComicViewController;

@protocol ComicViewControllerDelegate <NSObject>

@required
- (Comic *)comicViewController:(ComicViewController *)comicViewController comicBeforeCurrentComic:(Comic *)currentComic;
- (Comic *)comicViewController:(ComicViewController *)comicViewController comicAfterCurrentComic:(Comic *)currentComic;
- (Comic *)comicViewController:(ComicViewController *)comicViewController randomComic:(Comic *) currentComic;

@end

@interface ComicViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic) id<ComicViewControllerDelegate> delegate;

@property (nonatomic, strong) Comic *comic;

@property (nonatomic) BOOL allowComicNavigation;

@property (nonatomic) BOOL previewMode;

@end
