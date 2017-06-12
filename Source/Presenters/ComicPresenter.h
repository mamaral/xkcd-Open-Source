//
//  ComicPresenter.h
//  xkcd Open Source
//
//  Created by Mike on 6/11/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

@class RLMResults;
@class Comic;

@protocol ComicView <NSObject>

- (void)updateToNewComic:(Comic *)comic hasPrevious:(BOOL)hasPrevious hasNext:(BOOL)hasNext;
- (void)showWebComic:(Comic *)comic;

@end

@interface ComicPresenter : NSObject

- (instancetype)initWithComics:(RLMResults *)comics currentComic:(Comic *)currentComic;

- (void)attachToView:(id<ComicView>)view;
- (void)dettachFromView:(id<ComicView>)view;

- (void)showNextComic;
- (void)showPreviousComic;
- (void)showRandomComic;

@end
