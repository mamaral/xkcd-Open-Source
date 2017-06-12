//
//  ComicPresenter.m
//  xkcd Open Source
//
//  Created by Mike on 6/11/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import "ComicPresenter.h"

#import "Assembler.h"
#import "DataManager.h"
#import "Comic.h"

@interface ComicPresenter ()

@property (nonatomic, strong) RLMResults *comics;
@property (nonatomic, strong) Comic *currentComic;

@property (nonatomic, weak) id<ComicView> view;

@end

@implementation ComicPresenter

- (instancetype)initWithComics:(RLMResults *)comics currentComic:(Comic *)currentComic {
    NSParameterAssert(comics);
    NSParameterAssert(currentComic);

    self = [super init];

    if (!self) {
        return nil;
    }

    self.comics = comics;
    self.currentComic = currentComic;

    return self;
}

- (void)attachToView:(id<ComicView>)view {
    NSParameterAssert(view);

    self.view = view;

    [self updateCurrentComic:self.currentComic];
}

- (void)dettachFromView:(id<ComicView>)view {
    NSParameterAssert(view);

    self.view = nil;
}

- (void)showNextComic {
    NSUInteger indexOfCurrentComic = [self.comics indexOfObject:self.currentComic];
    Comic *nextComic = [self.comics objectAtIndex:indexOfCurrentComic + 1];
    [self updateCurrentComic:nextComic];
}

- (void)showPreviousComic {
    NSUInteger indexOfNextComic = [self.comics indexOfObject:self.currentComic];
    Comic *previousComic = [self.comics objectAtIndex:indexOfNextComic - 1];
    [self updateCurrentComic:previousComic];
}

- (void)showRandomComic {
    // If we're showing a random comic, the next and previous will get all messed up unless we
    // change our comics to the entire list first.
    self.comics = [[Assembler sharedInstance].dataManager allSavedComics];
    Comic *randomComic = [[Assembler sharedInstance].dataManager randomComic];
    [self updateCurrentComic:randomComic];
}

- (void)updateCurrentComic:(Comic *)newComic {
    NSParameterAssert(newComic);

    // Mark this comic as viewed.
    DataManager *dataManager = [Assembler sharedInstance].dataManager;
    [dataManager markComicViewed:newComic];

    // If this is a web comic, show it the special way.
    BOOL isInteractive = newComic.isInteractive || [dataManager.knownInteractiveComicNumbers containsObject:@(newComic.num)];
    if (isInteractive) {
        [self.view showWebComic:newComic];
        return;
    }

    self.currentComic = newComic;
    BOOL hasPrevious = [self.comics indexOfObject:newComic] > 0;
    BOOL hasNext = [self.comics indexOfObject:newComic] < self.comics.count - 1;
    [self.view updateToNewComic:newComic hasPrevious:hasPrevious hasNext:hasNext];
}


@end
