//
//  Assembler.h
//  xkcd Open Source
//
//  Created by Mike on 3/14/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DataManager;
@class ImageManager;
@class RequestManager;

@interface Assembler : NSObject

@property (nonatomic, strong) DataManager *dataManager;
@property (nonatomic, strong) ImageManager *imageManager;
@property (nonatomic, strong) RequestManager *requestManager;

+ (instancetype)sharedInstance;

@end
