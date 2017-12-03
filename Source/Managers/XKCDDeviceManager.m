//
//  DeviceManager.m
//  AtticGem
//
//  Created by Michael Amaral on 12/5/14.
//  Copyright (c) 2014 AtticGem. All rights reserved.
//

#import "XKCDDeviceManager.h"
#import "AppDelegate.h"

#define IS_IPHONE (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
#define IS_IPAD (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define IS_RETINA ([[UIScreen mainScreen] scale] >= 2.0)

#define SCREEN_WIDTH ([[UIScreen mainScreen] bounds].size.width)
#define SCREEN_HEIGHT ([[UIScreen mainScreen] bounds].size.height)
#define SCREEN_MAX_LENGTH (MAX(SCREEN_WIDTH, SCREEN_HEIGHT))
#define SCREEN_MIN_LENGTH (MIN(SCREEN_WIDTH, SCREEN_HEIGHT))

#define IS_IPHONE_4_OR_LESS (IS_IPHONE && SCREEN_MAX_LENGTH < 568.0)
#define IS_IPHONE_5 (IS_IPHONE && SCREEN_MAX_LENGTH == 568.0)
#define IS_IPHONE_6 (IS_IPHONE && SCREEN_MAX_LENGTH == 667.0)
#define IS_IPHONE_6P (IS_IPHONE && SCREEN_MAX_LENGTH == 736.0)
#define IS_IPHONE_X  (IS_IPHONE && SCREEN_HEIGHT == 812.0)
#define IS_IPAD_2 (IS_IPAD && !IS_RETINA)

@implementation XKCDDeviceManager


#pragma mark - Device size

+ (CGFloat)screenWidth {
    return [UIScreen mainScreen].bounds.size.width;
}

+ (CGFloat)screenHeight {
    return [UIScreen mainScreen].bounds.size.height;
}


#pragma mark - Device info

+ (DeviceType)currentDeviceType {
    if (IS_IPAD_2) {
        return DeviceTypePad2;
    }
    else if (IS_IPAD) {
        return DeviceTypePad;
    }
    else if (IS_IPHONE_4_OR_LESS) {
        return DeviceType4;
    }
    
    else if (IS_IPHONE_5) {
        return DeviceType5;
    }
    
    else if (IS_IPHONE_6) {
        return DeviceType6;
    }
    
    else if (IS_IPHONE_6P) {
        return DeviceType6Plus;
    }

    else if (IS_IPHONE_X) {
        return DeviceTypeX;
    }
    
    else {
        return DeviceTypeUnknown;
    }
}

+ (BOOL)isPad {
    return ([self currentDeviceType] == DeviceTypePad || [self currentDeviceType] == DeviceTypePad2);
}

+ (BOOL)isPad2 {
    return ([self currentDeviceType] == DeviceTypePad2);
}

+ (BOOL)isLargeDevice {
    return ([XKCDDeviceManager currentDeviceType] == DeviceType6) || ([XKCDDeviceManager currentDeviceType] == DeviceType6Plus);
}

+ (BOOL)isSmallDevice {
    return ([XKCDDeviceManager currentDeviceType] == DeviceType4) || ([XKCDDeviceManager currentDeviceType] == DeviceType5);
}

+ (BOOL)isX
{
    return ([self currentDeviceType] == DeviceTypeX);
}

+ (BOOL)isUSDevice {
    NSString *countryCode = [[NSLocale currentLocale] objectForKey:NSLocaleCountryCode];
    return [countryCode isEqualToString:@"US"];
}


#pragma mark - App info

+ (NSDecimalNumber *)appVersionNumber {
    NSString *appVersionString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    return [NSDecimalNumber decimalNumberWithString:appVersionString];
}

+ (NSString *)appVersionFull:(BOOL)full {
    NSString *appVersion = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    NSString *buildNumber = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    return full ? [NSString stringWithFormat:@"Version %@ (%@)", appVersion, buildNumber] : [NSString stringWithFormat:@"v%@", appVersion];
}

@end
