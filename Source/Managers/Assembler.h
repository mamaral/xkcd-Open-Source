//
//  Assembler.h
//  xkcd Open Source
//
//  Created by Mike on 3/14/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ImageManager;

@interface Assembler : NSObject

@property (nonatomic, strong) ImageManager *imageManager;

+ (instancetype)sharedInstance;

@end
