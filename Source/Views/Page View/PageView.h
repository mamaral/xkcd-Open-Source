//
//  PageView.h
//  xkcd Open Source
//
//  Created by Oleg on 3/20/17.
//  Copyright © 2017 eclight. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol PageViewDelegate <NSObject>

- (UIView *)pageBeforePage: (UIView *)page;
- (UIView *)pageAfterPage: (UIView *)page;
- (void)recyclePage: (UIView *)page;
- (void)pageDidBecomeCurrent: (UIView *)page;

@end


@interface PageView : UIView

@property(nonatomic, weak) id<PageViewDelegate> delegate;
@property(nonatomic, strong) UIView *currentPage;
@property(nonatomic, assign) CGFloat pageSpacing;

- (void)scrollForward;
- (void)scrollBack;

@end
