//
//  ThemeManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>

static CGFloat const kDefaultCornerRadius = 7.0;

@interface ThemeManager : NSObject

+ (void)setupTheme;

+ (UIFont *)xkcdFontWithSize:(CGFloat)size;
+ (UIColor *)xkcdLightBlue;
+ (UIImage *)loadingImage;

+ (void)addBorderToLayer:(CALayer *)layer radius:(CGFloat)radius color:(UIColor *)color;
+ (void)addShadowToLayer:(CALayer *)layer radius:(CGFloat)radius opacity:(CGFloat)opacity;

@end
