//
//  ZoomingImageView.h
//  xkcd Open Source
//
//  Created by Oleg on 3/20/17.
//  Copyright © 2017 eclight. All rights reserved.
//

#import <UIKit/UIKit.h>

@class Comic;

@interface ComicImageView : UIView

@property UIImage *image;
@property(nonatomic, strong) Comic* comic;
@end
