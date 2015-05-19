//
//  ComicListFlowLayout.m
//  xkcd Open Source
//
//  Created by Mike on 5/17/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ComicListFlowLayout.h"

static NSUInteger const kHeightModulo = 50;
static CGFloat const kMinimumCellHeightPhone = 60;
static CGFloat const kMinimumCellHeightPad = 100;

@implementation ComicListFlowLayout {
    NSMutableArray *_columns;
    NSMutableArray *_itemsAttributes;
}

- (void)prepareLayout {
    NSUInteger numberOfColumns = [self numberOfColumns];
    _columns = [NSMutableArray arrayWithCapacity:numberOfColumns];
    for (NSInteger i = 0; i < numberOfColumns; i++) {
        [_columns addObject:@(0)];
    }

    NSUInteger itemsCount = [self.collectionView numberOfItemsInSection:0];
    _itemsAttributes = [NSMutableArray arrayWithCapacity:itemsCount];

    for (NSUInteger i = 0; i < itemsCount; i++){
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:i inSection:0];
        NSUInteger columnIndex = [self indexForShortestColumn];
        CGFloat xOffset = columnIndex * [self columnWidth];
        CGFloat yOffset = [[_columns objectAtIndex:columnIndex] floatValue];
        CGFloat columnWidth = [self columnWidth];
        CGFloat relativeItemHeight = [self.delegate collectionView:self.collectionView relativeHeightForItemAtIndexPath:indexPath];
        CGFloat minimumCellHeight = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? kMinimumCellHeightPad : kMinimumCellHeightPhone;
        NSUInteger itemWidth = 0;
        NSUInteger itemHeight = 0;

        BOOL canBeDoubleWide = [self canBeDoubleColumnAtIndex:columnIndex];
        BOOL shouldBeDoubleWide = [self.delegate collectionView:self.collectionView shouldBeDoubleColumnAtIndexPath:indexPath];

        if (canBeDoubleWide && shouldBeDoubleWide) {
            itemWidth = columnWidth * 2;
            itemHeight = MAX(relativeItemHeight * itemWidth, minimumCellHeight);

            _columns[columnIndex] = @(yOffset + itemHeight);
            _columns[columnIndex + 1] = @(yOffset + itemHeight);
        }

        else {
            itemWidth = columnWidth;
            itemHeight = MAX((relativeItemHeight * itemWidth) - (itemHeight % kHeightModulo), minimumCellHeight);

            _columns[columnIndex] = @(yOffset + itemHeight);
        }

        UICollectionViewLayoutAttributes *attributes = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];
        attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight);
        [_itemsAttributes addObject:attributes];
    }
}

- (NSArray *)layoutAttributesForElementsInRect:(CGRect)rect{
    NSPredicate *filterPredicate = [NSPredicate predicateWithBlock:^BOOL(UICollectionViewLayoutAttributes *evaluatedObject, NSDictionary *bindings) {
        return CGRectIntersectsRect(rect, evaluatedObject.frame);
    }];

    return [_itemsAttributes filteredArrayUsingPredicate:filterPredicate];
}

- (UICollectionViewLayoutAttributes *)layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath{
    return [_itemsAttributes objectAtIndex:indexPath.row];
}

- (CGSize)collectionViewContentSize {
    CGSize contentSize = self.collectionView.bounds.size;

    NSUInteger indexForLongestColumn = [self longestColumnIndex];
    float columnHeight = [_columns[indexForLongestColumn] floatValue];
    contentSize.height = columnHeight;
    
    return contentSize;
}

- (NSUInteger)indexForShortestColumn {
    CGFloat shortestHeight = MAXFLOAT;
    NSUInteger indexForShortest = 0;

    for (NSUInteger i = 0; i < _columns.count; i++) {
        CGFloat height = [_columns[i] floatValue];

        if (height < shortestHeight) {
            shortestHeight = height;
            indexForShortest = i;
        }
    }

    return indexForShortest;
}

- (NSUInteger)longestColumnIndex {
    CGFloat longestHeight = 0;
    NSUInteger indexForLongest = 0;

    for (NSUInteger i = 0; i < _columns.count; i++) {
        CGFloat height = [_columns[i] floatValue];

        if (height > longestHeight) {
            longestHeight = height;
            indexForLongest = i;
        }
    }

    return indexForLongest;
}

- (BOOL)canBeDoubleColumnAtIndex:(NSUInteger)columnIndex{
    BOOL retVal = NO;

    if (columnIndex < self.numberOfColumns - 1) {
        float firstColumnHeight = [_columns[columnIndex] floatValue];
        float secondColumnHeight = [_columns[columnIndex + 1] floatValue];

        retVal = firstColumnHeight == secondColumnHeight;
    }

    return retVal;
}

- (NSUInteger)numberOfColumns {
    return [self.delegate numberOfColumnsInCollectionView:self.collectionView];
}

- (CGFloat)columnWidth {
    return roundf(self.collectionView.bounds.size.width / self.numberOfColumns);
}

@end
