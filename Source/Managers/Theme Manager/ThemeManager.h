//
//  ThemeManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>

static NSString * const kXKCDFontName = @"xkcd-Regular";

static NSString * const kDefaultLoadingImageName = @"loading";

static CGFloat const kDefaultXKCDTitleFontSize = 22.0;

static CGFloat const kDefaultCornerRadius = 7.0;
static CGFloat const kDefaultBorderWidth = 1.25;

@interface ThemeManager : NSObject

+ (void)setupTheme;

+ (UIFont *)xkcdFontWithSize:(CGFloat)size;
+ (UIColor *)xkcdLightBlue;
+ (UIImage *)loadingImage;

+ (void)addBorderToLayer:(CALayer *)layer radius:(CGFloat)radius color:(UIColor *)color;
+ (void)addShadowToLayer:(CALayer *)layer radius:(CGFloat)radius opacity:(CGFloat)opacity;

@end
