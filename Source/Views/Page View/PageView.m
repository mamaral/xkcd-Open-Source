//
//  PageView.m
//  xkcd Open Source
//
//  Created by Oleg on 3/20/17.
//  Copyright © 2017 eclight. All rights reserved.
//

#import "PageView.h"

@interface PageView () <UIScrollViewDelegate>

@property(nonatomic, strong) UIScrollView *pagingScrollView;
@property(nonatomic, strong) UIView *prevPage;
@property(nonatomic, strong) UIView *nextPage;
@property(nonatomic) BOOL ignoreScroll;
@property(nonatomic) BOOL scrollAnimationRunning;

// Current page index (0, 1, 2)
@property(nonatomic) int currentPageIndex;

// Used to track current page index during scrolling (before scrollViewDidEndDecelerating)
@property(nonatomic) int currentPageIndexForScrolling;

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

- (void)scrollForward
{
    if (self.scrollAnimationRunning) return;
    self.scrollAnimationRunning = YES;
    CGFloat newOffset = self.pagingScrollView.contentOffset.x + self.pagingScrollView.bounds.size.width;
    [self.pagingScrollView setContentOffset:CGPointMake(newOffset, 0.0) animated:TRUE];
}
- (void)scrollBack
{
    if (self.scrollAnimationRunning) return;
    self.scrollAnimationRunning = YES;
    CGFloat newOffset = self.pagingScrollView.contentOffset.x - self.pagingScrollView.bounds.size.width;
    [self.pagingScrollView setContentOffset:CGPointMake(newOffset, 0.0) animated:TRUE];
}

- (void)setup
{
    self.scrollAnimationRunning = NO;
    self.clipsToBounds = YES;
    self.pagingScrollView = [UIScrollView new];
    self.pagingScrollView.showsVerticalScrollIndicator = NO;
    self.pagingScrollView.showsHorizontalScrollIndicator = NO;
    self.pagingScrollView.pagingEnabled = YES;
    self.pagingScrollView.backgroundColor = [UIColor whiteColor];
    self.pagingScrollView.delegate = self;
    [self addSubview:self.pagingScrollView];
}

- (void)setCurrentPage:(UIView *)currentPage
{
    for (UIView *page in self.pagingScrollView.subviews) {
        [page removeFromSuperview];
        [self.delegate recyclePage:page];
    }
    
    _currentPage = currentPage;
    if (_currentPage) {
        self.prevPage = [self.delegate pageBeforePage:_currentPage];
        self.nextPage = [self.delegate pageAfterPage:_currentPage];
        
        [self.pagingScrollView addSubview: _currentPage];
        if (self.prevPage) {
            [self.pagingScrollView addSubview:self.prevPage];
        }
        
        if (self.nextPage) {
            [self.pagingScrollView addSubview:self.nextPage];
        }
    } else {
        self.prevPage = nil;
        self.nextPage = nil;
    }
    
    [self layoutPages];
    [self.delegate pageDidBecomeCurrent:_currentPage];
}

- (void)setCurrentPageIndex:(int)currentPageIndex
{
    _currentPageIndex = currentPageIndex;
    _currentPageIndexForScrolling = currentPageIndex;
}

- (CGFloat)pageWidth
{
    return CGRectGetWidth(self.bounds) + self.pageSpacing;
}

- (CGRect)frameForPage:(NSInteger)pageIndex
{
    CGRect pageRect = CGRectMake(pageIndex * self.pageWidth, 0, self.pageWidth, CGRectGetHeight(self.bounds));
    return CGRectInset(pageRect, self.pageSpacing * 0.5, 0);
}

- (void)layoutPages
{
    int pageIndex = 0;
    if (self.prevPage) {
        self.prevPage.frame = [self frameForPage:pageIndex];
        ++pageIndex;
    }
    
    if (self.currentPage) {
        self.currentPage.frame = [self frameForPage:pageIndex];
        self.currentPageIndex = pageIndex;
        ++pageIndex;
    }
    
    if (self.nextPage) {
        self.nextPage.frame = [self frameForPage:pageIndex];
        ++pageIndex;
    }
    
    self.pagingScrollView.contentSize = CGSizeMake(pageIndex * self.pageWidth, CGRectGetHeight(self.bounds));
    self.pagingScrollView.contentOffset = CGPointMake(self.currentPageIndex * self.pageWidth, 0);
}

- (void)layoutSubviews
{
    self.ignoreScroll = YES;
    CGRect scrollViewFrame = CGRectInset(self.bounds, -self.pageSpacing * 0.5, 0);
    self.pagingScrollView.frame = scrollViewFrame;
    [self layoutPages];
    self.ignoreScroll = NO;
}

// MARK: - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    self.scrollAnimationRunning = YES;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.ignoreScroll) return;

    CGFloat offset = self.pagingScrollView.contentOffset.x;
    int newPageIndex = MAX(0, round(offset / self.pageWidth));
    
    if (newPageIndex != self.currentPageIndexForScrolling) {
        UIView *newCurrentPage;
        switch(newPageIndex) {
            case 0:
                newCurrentPage = (self.prevPage != nil) ? self.prevPage : self.currentPage;
                break;
            
            case 1:
                newCurrentPage = (self.prevPage != nil) ? self.currentPage : self.nextPage;
                break;
                
            case 2:
                newCurrentPage = self.nextPage;
                break;
                
            default:
                [NSException raise:@"NSInternalInconsistencyException" format:@"Unexpected page index"];
        }
        
        [self.delegate pageDidBecomeCurrent:newCurrentPage];
        self.currentPageIndexForScrolling = newPageIndex;
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    int newPageIndex = scrollView.contentOffset.x / self.pageWidth;
    if (newPageIndex < self.currentPageIndex)
    {
        
        if (self.nextPage) {
            [self.nextPage removeFromSuperview];
            [self.delegate recyclePage:self.nextPage];
        }
        self.nextPage = self.currentPage;
        _currentPage = self.prevPage;
        self.prevPage = [self.delegate pageBeforePage: self.currentPage];
        if (self.prevPage) {
            [self.pagingScrollView addSubview:self.prevPage];
        }
        
        [self layoutPages];
        
    }
    else if (newPageIndex > self.currentPageIndex)
    {
        
        if (self.prevPage) {
            [self.prevPage removeFromSuperview];
            [self.delegate recyclePage:self.prevPage];
        }
        self.prevPage = self.currentPage;
        _currentPage = self.nextPage;
        self.nextPage = [self.delegate pageAfterPage: self.currentPage];
        if (self.nextPage) {
            [self.pagingScrollView addSubview:self.nextPage];
        }
        [self layoutPages];
    }
    
    self.scrollAnimationRunning = NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self scrollViewDidEndScrollingAnimation: scrollView];
}

@end
