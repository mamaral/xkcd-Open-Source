//
//  ComicCell.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"

@class ComicCell;

@protocol ComicCellDelegate <NSObject>

@required
- (void)comicCell:(ComicCell *)cell didSelectComicAltWithComic:(Comic *)comic;

@end

static NSString * const kComicCellReuseIdentifier = @"ComicCell";

@interface ComicCell : UICollectionViewCell

@property (nonatomic, weak) id<ComicCellDelegate> delegate;

@property (nonatomic, strong) Comic *comic;

@end
