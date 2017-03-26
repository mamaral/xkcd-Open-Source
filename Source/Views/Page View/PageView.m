//
//  PageView.m
//  ScrollViewObjC
//
//  Created by Oleg on 3/20/17.
//  Copyright © 2017 eclight. All rights reserved.
//

#import "PageView.h"

@interface PageView () <UIScrollViewDelegate>

@property(nonatomic, strong) UIScrollView *pagingScrollView;
@property(nonatomic, strong) NSMutableDictionary<NSNumber *, UIView *> *loadedPages;
@property(nonatomic, strong) NSMutableArray<UIView *> *unloadedPages;
@property(nonatomic, assign) BOOL ignoreScroll;

- (void)setup;
- (void)reloadData;
- (void)loadPageForIndex:(NSInteger)index;
- (void)unloadPageForKey:(NSNumber*)key;

@end

@implementation PageView

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setDataSource:(id<PageViewDataSource>)dataSource
{
    _dataSource = dataSource;
    [self reloadData];
}

- (void)setPageIndex:(NSInteger)pageIndex
{
    if (!self.dataSource) return;
    
    _pageIndex = pageIndex;
    
    NSMutableArray<NSNumber *> *pagesToUnload = [NSMutableArray new];
    for (NSNumber *key in self.loadedPages) {
        NSInteger index = key.integerValue;
        if (labs(index - pageIndex) > 1) {
            [pagesToUnload addObject:key];
        }
    }
    
    for (NSNumber *key in pagesToUnload) {
        [self unloadPageForKey:key];
    }
    
    if (![self.loadedPages objectForKey:[NSNumber numberWithInteger:pageIndex]]) {
        [self loadPageForIndex:pageIndex];
    }
    
    if (pageIndex > 0) {
        [self loadPageForIndex:pageIndex - 1];
    }
    
    if (pageIndex < _dataSource.numberOfPages - 1) {
        [self loadPageForIndex:pageIndex + 1];
    }
    
    [self.delegate pageView:self shownPageWithIndex:self.pageIndex];
}

- (void)setup
{
    self.pagingScrollView = [UIScrollView new];
    self.pagingScrollView.showsVerticalScrollIndicator = NO;
    self.pagingScrollView.showsHorizontalScrollIndicator = NO;
    self.pagingScrollView.pagingEnabled = YES;
    self.pagingScrollView.backgroundColor = [UIColor whiteColor];
    self.pagingScrollView.delegate = self;
    self.pagingScrollView.backgroundColor = [UIColor blueColor];
    self.loadedPages = [NSMutableDictionary new];
    self.unloadedPages = [NSMutableArray new];
    [self addSubview:self.pagingScrollView];
}

- (void)reloadData
{
    for (UIView *view in self.pagingScrollView.subviews) {
        [view removeFromSuperview];
    }
    [self.loadedPages removeAllObjects];
    [self.unloadedPages removeAllObjects];
    self.pageIndex = 0;
    [self setNeedsLayout];
}

- (void)loadPageForIndex:(NSInteger)index
{
    NSNumber *key = [NSNumber numberWithInteger:index];
    if ([self.loadedPages objectForKey:key]) {
        return;
    }
    
    UIView *page = [self.unloadedPages lastObject];
    if (page) {
        [self.unloadedPages removeLastObject];
    }
    else {
        page = [self.dataSource createPage];
    }
    
   // UIView *page = [self.dataSource createPage];
    
    [self.dataSource setupPage:page forIndex:index];
    CGSize pageRect = self.pagingScrollView.bounds.size;
    page.frame = CGRectMake(pageRect.width * index, 0, pageRect.width, pageRect.height);
    [self.loadedPages setObject:page forKey:key];
    [self.pagingScrollView addSubview:page];
}

- (void)unloadPageForKey:(NSNumber*)key
{
    UIView *page = [self.loadedPages objectForKey:key];
    [page removeFromSuperview];
    [self.loadedPages removeObjectForKey:key];
}

- (void)layoutSubviews
{
    self.ignoreScroll = YES;
    CGRect pageRect = self.bounds;
    self.pagingScrollView.frame = pageRect;
    self.pagingScrollView.contentSize = CGSizeMake(CGRectGetWidth(pageRect) * self.dataSource.numberOfPages, CGRectGetHeight(pageRect));
    self.pagingScrollView.contentOffset = CGPointMake(CGRectGetWidth(pageRect) * self.pageIndex, 0);
    
    for (NSNumber *key in self.loadedPages) {
        UIView *page = [self.loadedPages objectForKey:key];
        NSInteger index = key.integerValue;
        page.frame = CGRectMake(index * CGRectGetWidth(pageRect), 0, CGRectGetWidth(pageRect), CGRectGetHeight(pageRect));
    }
    
    self.ignoreScroll = NO;
}

// MARK: - UIScrollViewDelegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.ignoreScroll) {
        return;
    }
    
    CGFloat offset = self.pagingScrollView.contentOffset.x;
    CGFloat pageWidth = self.pagingScrollView.bounds.size.width;
    
    if (fabs(offset - self.pageIndex * pageWidth) > 0.5 * pageWidth) {
        NSInteger newIndex = MAX(0, floor(offset / pageWidth));
        
        if (self.pageIndex != newIndex) {
            self.pageIndex = newIndex;
        }
    }
}

@end
