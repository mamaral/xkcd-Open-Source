//
//  ThemeManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ThemeManager.h"

static NSString * const kXkcdFontName = @"xkcd-Regular";

@implementation ThemeManager

+ (void)setupTheme {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [[self class] xkcdFontWithSize:22]}];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];
}

+ (UIFont *)xkcdFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:kXkcdFontName size:size];
}

+ (UIColor *)xkcdLightBlue {
    return [UIColor colorWithRed:151/255.0 green:169/255.0 blue:199/255.0 alpha:1.0];
}

+ (UIImage *)loadingImage {
    return [UIImage imageNamed:@"loading"];
}

+ (void)addBorderToLayer:(CALayer *)layer radius:(CGFloat)radius color:(UIColor *)color {
    layer.cornerRadius = radius;
    layer.borderColor = color.CGColor;
    layer.borderWidth = 1.25;
}

+ (void)addShadowToLayer:(CALayer *)layer radius:(CGFloat)radius opacity:(CGFloat)opacity {
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeMake(0.0, 0.0);
    layer.shadowOpacity = 0.9;
    layer.shadowRadius = 15.0;
}

@end
