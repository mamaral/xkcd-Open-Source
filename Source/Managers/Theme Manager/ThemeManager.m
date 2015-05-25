//
//  ThemeManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ThemeManager.h"

@implementation ThemeManager

+ (void)setupTheme {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor],NSFontAttributeName : [[self class] xkcdFontWithSize:kDefaultXKCDTitleFontSize]}];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [[self class] xkcdFontWithSize:kDefaultSearchBarFontSize]} forState:UIControlStateNormal];

    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [[self class] xkcdFontWithSize:kDefaultSearchBarFontSize]}];
}

+ (UIFont *)xkcdFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:kXKCDFontName size:size];
}

+ (UIColor *)xkcdLightBlue {
    return [UIColor colorWithRed:151/255.0 green:169/255.0 blue:199/255.0 alpha:1.0];
}

+ (UIImage *)loadingImage {
    return [UIImage imageNamed:kDefaultLoadingImageName];
}

+ (void)addBorderToLayer:(CALayer *)layer radius:(CGFloat)radius color:(UIColor *)color {
    layer.cornerRadius = radius;
    layer.borderColor = color.CGColor;
    layer.borderWidth = kDefaultBorderWidth;
}

+ (void)addShadowToLayer:(CALayer *)layer radius:(CGFloat)radius opacity:(CGFloat)opacity {
    layer.shadowColor = [UIColor blackColor].CGColor;
    layer.shadowOffset = CGSizeZero;
    layer.shadowOpacity = opacity;
    layer.shadowRadius = radius;
}

@end
