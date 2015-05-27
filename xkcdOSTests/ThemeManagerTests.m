//
//  ThemeManagerTests.m
//  xkcd Open Source
//
//  Created by Mike on 5/22/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "ThemeManager.h"

@interface ThemeManagerTests : XCTestCase

@end

@implementation ThemeManagerTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testSetupTheme {
    [ThemeManager setupTheme];

    NSDictionary *navigationBarAppearanceAttributes = [UINavigationBar appearance].titleTextAttributes;

    XCTAssertEqualObjects(navigationBarAppearanceAttributes[NSForegroundColorAttributeName], [UIColor blackColor]);
    XCTAssertEqualObjects(navigationBarAppearanceAttributes[NSFontAttributeName], [UIFont fontWithName:kXKCDFontName size:kDefaultXKCDTitleFontSize]);
}

- (void)testXKCDFont {
    CGFloat fontSize = 25.0;

    XCTAssertEqualObjects([ThemeManager xkcdFontWithSize:fontSize], [UIFont fontWithName:kXKCDFontName size:fontSize]);
}

- (void)testXKCDLightBlue {
    XCTAssertEqualObjects([ThemeManager xkcdLightBlue], [UIColor colorWithRed:151/255.0 green:169/255.0 blue:199/255.0 alpha:1.0]);
}

- (void)testLoadingImage {
    XCTAssertEqualObjects(UIImagePNGRepresentation([ThemeManager loadingImage]), UIImagePNGRepresentation([UIImage imageNamed:kDefaultLoadingImageName]));
}

- (void)testBackImage {
    XCTAssertEqualObjects(UIImagePNGRepresentation([ThemeManager backImage]), UIImagePNGRepresentation([UIImage imageNamed:kDefaultBackImageName]));
}

- (void)testAddBorderToLayer {
    UIView *testView = [UIView new];
    CGFloat radius = 10;
    UIColor *color = [UIColor redColor];

    [ThemeManager addBorderToLayer:testView.layer radius:radius color:color];

    XCTAssertEqual(testView.layer.cornerRadius, radius);
    XCTAssertEqual(testView.layer.borderColor, color.CGColor);
    XCTAssertEqual(testView.layer.borderWidth, kDefaultBorderWidth);
}

- (void)testAddShadowToLayer {
    UIView *testView = [UIView new];
    CGFloat radius = 15;
    CGFloat opacity = 0.4;

    [ThemeManager addShadowToLayer:testView.layer radius:radius opacity:opacity];

    XCTAssertEqual(testView.layer.shadowRadius, radius);
    XCTAssertEqualWithAccuracy(testView.layer.shadowOpacity, opacity, 0.01);
    XCTAssertEqual(testView.layer.shadowColor, [UIColor blackColor].CGColor);
    XCTAssert(CGSizeEqualToSize(testView.layer.shadowOffset, CGSizeZero));
}

@end
