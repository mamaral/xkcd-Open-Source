//
//  DeviceManager.h
//  AtticGem
//
//  Created by Michael Amaral on 12/5/14.
//  Copyright (c) 2014 AtticGem. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef enum {
    DeviceTypePad = 0,
    DeviceTypePad2,
    DeviceType4,
    DeviceType5,
    DeviceType6,
    DeviceType6Plus,
    DeviceTypeX,
    DeviceTypeUnknown
} DeviceType;

@interface XKCDDeviceManager : NSObject


#pragma mark - Device size

+ (CGFloat)screenWidth;
+ (CGFloat)screenHeight;


#pragma mark - Device info

+ (DeviceType)currentDeviceType;
+ (BOOL)isPad;
+ (BOOL)isPad2;
+ (BOOL)isLargeDevice;
+ (BOOL)isSmallDevice;
+ (BOOL)isX;
+ (BOOL)isUSDevice;


#pragma mark - App info

+ (NSDecimalNumber *)appVersionNumber;
+ (NSString *)appVersionFull:(BOOL)full;

@end
