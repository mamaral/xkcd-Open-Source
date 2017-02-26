//
//  ThemeManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/15/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "ThemeManager.h"
#import "DataManager.h"

@implementation ThemeManager

+ (void)setupTheme {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [[self class] xkcdFontWithSize:kDefaultXKCDTitleFontSize]}];
    [[UINavigationBar appearance] setTintColor:[UIColor blackColor]];

    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName:[[self class] xkcdFontWithSize:kDefaultSearchBarFontSize]} forState:UIControlStateNormal];

    [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setTitleTextAttributes:@{NSForegroundColorAttributeName : [UIColor blackColor], NSFontAttributeName : [[self class] xkcdFontWithSize:kDefaultXKCDTitleFontSize]} forState:UIControlStateNormal];

    [[UITextField appearanceWhenContainedIn:[UISearchBar class], nil] setDefaultTextAttributes:@{NSFontAttributeName: [[self class] xkcdFontWithSize:kDefaultSearchBarFontSize]}];
}

+ (UIFont *)xkcdFontWithSize:(CGFloat)size {
    return [UIFont fontWithName:kXKCDFontName size:size];
}

+ (UIColor *)xkcdLightBlue {
    return [UIColor colorWithRed:151/255.0 green:169/255.0 blue:199/255.0 alpha:1.0];
}

+ (UIColor *)comicViewedColor {
    return [UIColor colorWithRed:130/255.0 green:130/255.0 blue:130/255.0 alpha:1.0];
}

+ (UIImage *)loadingImage {
    return [UIImage imageNamed:kDefaultLoadingImageName];
}

+ (UIImage *)randomImage {
    NSInteger randomNumber = [[DataManager sharedInstance] randomNumberBetweenMin:1 andMax:6];
    NSString *randomImageName = [NSString stringWithFormat:@"r%ld", (long)randomNumber];
    return [UIImage imageNamed:randomImageName] ?: [UIImage imageNamed:kDefaultRandomImageName];
}

+ (UIImage *)backImage {
    return [UIImage imageNamed:kDefaultBackImageName];
}

+ (UIImage *)favoriteImage {
    return [UIImage imageNamed:kFavoriteImageName];
}

+ (UIImage *)favoriteOffImage {
    return [UIImage imageNamed:kFavoriteOffImageName];
}

+ (UIImage *)prevComicImage {
    return [UIImage imageNamed:kPrevImageName];
}

+ (UIImage *)nextComicImage {
    return [UIImage imageNamed:kNextImageName];
}

+ (UIImage *)facebookImage {
    return [UIImage imageNamed:kFacebookImageName];
}

+ (UIImage *)twitterImage {
    return [UIImage imageNamed:kTwitterImageName];
}

+ (UIImage *)bookmarkedImage {
    return [UIImage imageNamed:kBookmarkImageName];
}

+ (UIImage *)bookmarkedOffImage {
    return [UIImage imageNamed:kBookmarkOffImageName];
}

+ (UIImage *)moreImage {
    return [UIImage imageNamed:kMoreImageName];
}


#pragma mark - CALayer schtuff

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


#pragma mark - Fancy-schmancy parallax

+ (void)addParallaxToView:(UIView *)view {
    UIInterpolatingMotionEffect *verticalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y" type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    verticalMotionEffect.minimumRelativeValue = @(-kDefaultParallaxValue);
    verticalMotionEffect.maximumRelativeValue = @(kDefaultParallaxValue);

    UIInterpolatingMotionEffect *horizontalMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x" type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    horizontalMotionEffect.minimumRelativeValue = @(-kDefaultParallaxValue);
    horizontalMotionEffect.maximumRelativeValue = @(kDefaultParallaxValue);

    UIMotionEffectGroup *group = [UIMotionEffectGroup new];
    group.motionEffects = @[horizontalMotionEffect, verticalMotionEffect];

    [view addMotionEffect:group];
}

@end
