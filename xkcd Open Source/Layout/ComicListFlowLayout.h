//
//  ComicListFlowLayout.h
//  xkcd Open Source
//
//  Created by Mike on 5/17/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol ComicListFlowLayoutDelegate <NSObject>

- (CGFloat)collectionView:(UICollectionView *)collectionView relativeHeightForItemAtIndexPath:(NSIndexPath *)indexPath;
- (BOOL)collectionView:(UICollectionView *)collectionView shouldBeDoubleColumnAtIndexPath:(NSIndexPath *)indexPath;
- (NSUInteger)numberOfColumnsInCollectionView:(UICollectionView *)collectionView;

@end


@interface ComicListFlowLayout : UICollectionViewFlowLayout

@property (nonatomic, weak) id <ComicListFlowLayoutDelegate> delegate;

@end
