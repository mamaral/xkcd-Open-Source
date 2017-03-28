//
//  PageView.h
//  ScrollViewObjC
//
//  Created by Oleg on 3/20/17.
//  Copyright © 2017 eclight. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PageView;

@protocol PageViewDataSource <NSObject>

- (UIView *)createPage;
- (void)setupPage:(UIView *)page forIndex:(NSUInteger)index;
- (NSInteger)numberOfPages;

@end

@protocol PageViewDelegate <NSObject>

- (void)pageView: (PageView *)pageView shownPageWithIndex: (NSUInteger)index;

@end

@interface PageView : UIView

@property(nonatomic, weak) id<PageViewDataSource> dataSource;
@property(nonatomic, weak) id<PageViewDelegate> delegate;
@property(nonatomic, assign) CGFloat pageSpacing;
@property(nonatomic, assign) NSInteger pageIndex;

@end
