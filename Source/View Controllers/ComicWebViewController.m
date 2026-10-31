//
//  ComicWebViewController.m
//  xkcd Open Source
//
//  Created by Mike on 4/19/16.
//  Copyright © 2016 Mike Amaral. All rights reserved.
//

#import "ComicWebViewController.h"
#import <UIView+Facade.h>
#import "Comic.h"
#import "ThemeManager.h"

@import WebKit;

@interface ComicWebViewController ()

@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;

@end

@implementation ComicWebViewController

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.webView = [WKWebView new];
    [self.webView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:NSKeyValueObservingOptionNew context:NULL];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.progressView.progressTintColor = [ThemeManager xkcdLightBlue];

    return self;
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.webView];
    [self.view addSubview:self.progressView];

    // Load once here, rather than every time we appear, so coming back to this screen doesn't
    // throw away the user's place on the page.
    NSURL *url = self.URLString ? [NSURL URLWithString:self.URLString] : nil;
    if (url) {
        [self.webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (void)dealloc {
    [self.webView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self.webView fillSuperview];
    [self.progressView anchorTopCenterFillingWidthWithLeftAndRightPadding:0.0 topPadding:self.navigationController.navigationBar.yMax height:7.0];
}


#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.webView) {
        // Navigating within the page starts a new load, so make sure the progress bar is visible again.
        if (self.webView.estimatedProgress < 1.0) {
            self.progressView.alpha = 1.0;
        }

        [self.progressView setProgress:self.webView.estimatedProgress animated:YES];

        if (self.webView.estimatedProgress >= 1.0) {
            [UIView animateWithDuration:0.3 delay:0.3 options:UIViewAnimationOptionCurveEaseOut animations:^{
                self.progressView.alpha = 0.0;
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0 animated:NO];
            }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
