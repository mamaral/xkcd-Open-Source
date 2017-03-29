//
//  ZoomingImageView.m
//  xkcd Open Source
//
//  Created by Oleg on 3/20/17.
//  Copyright © 2017 eclight. All rights reserved.
//

#import <UIImageView+WebCache.h>
#import "ComicImageView.h"
#import "ThemeManager.h"

@interface ComicImageView () <UIScrollViewDelegate>

@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIImageView *imageView;

- (void)setup;
- (void)setupZoomScale;
- (void)centerImage;

@end

@implementation ComicImageView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self setup];
    }
    return self;
}

- (UIImage *)image
{
    return self.imageView.image;
}

- (void)setImage:(UIImage *)image
{
    self.imageView.image = image;
    self.imageView.frame = CGRectMake(0, 0, image.size.width, image.size.height);
    self.scrollView.contentSize = self.imageView.frame.size;
    [self setNeedsLayout];
}

- (void) setup
{
    self.scrollView = [UIScrollView new];
    self.imageView = [UIImageView new];
    self.imageView.frame = CGRectZero;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView.delegate = self;
    self.scrollView.minimumZoomScale = 1.0;
    self.scrollView.maximumZoomScale = 10.0;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.showsHorizontalScrollIndicator = NO;
    [self.scrollView addSubview:self.imageView];
    [self addSubview:self.scrollView];
}

- (void) setupZoomScale
{
    CGSize imageSize = self.imageView.bounds.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    
    CGFloat widthScale = scrollViewSize.width / imageSize.width;
    CGFloat heightScale = scrollViewSize.height / imageSize.height;
    
    self.scrollView.minimumZoomScale = MIN(widthScale, heightScale);
    self.scrollView.zoomScale = self.scrollView.minimumZoomScale;
}

- (void)centerImage
{
    CGSize imageViewSize = self.imageView.frame.size;
    CGSize scrollViewSize = self.scrollView.bounds.size;
    CGFloat verticalPadding = (scrollViewSize.height > imageViewSize.height) ? 0.5 * (scrollViewSize.height - imageViewSize.height) : 0.0;
    CGFloat horizontalPadding = (scrollViewSize.width > imageViewSize.width) ? 0.5 * (scrollViewSize.width - imageViewSize.width) : 0.0;
    
    self.scrollView.contentInset = UIEdgeInsetsMake(verticalPadding, horizontalPadding, verticalPadding, horizontalPadding);
}

- (void)layoutSubviews
{
    self.scrollView.frame = self.bounds;
    
    if (self.imageView.image) {
        [self setupZoomScale];
        [self centerImage];
    }
}

// MARK: - UIScrollViewDelegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
    return self.imageView;
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
    [self centerImage];
}

@end
