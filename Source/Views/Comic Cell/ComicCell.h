//
//  ComicCell.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Comic.h"

static NSString * const kComicCellReuseIdentifier = @"ComicCell";

@interface ComicCell : UICollectionViewCell

@property (nonatomic, strong) Comic *comic;

@end
