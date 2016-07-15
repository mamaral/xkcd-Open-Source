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

@import WebKit;

@interface ComicWebViewController ()

@property (nonatomic, strong) WKWebView *webView;

@end

@implementation ComicWebViewController

- (instancetype)init {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.webView = [WKWebView new];

    return self;
}

#pragma mark - View life cycle

- (void)viewDidLoad {
    [super viewDidLoad];

    self.title = self.comic.title;

    [self.view addSubview:self.webView];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:[NSURL URLWithString:self.comic.comicURLString]];
    [self.webView loadRequest:request];
}


#pragma mark - Layout

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];

    [self.webView fillSuperview];
}

@end
