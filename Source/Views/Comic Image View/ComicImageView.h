//
//  ComicImageView.h
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

- (void)loadImageWithURL: (NSURL *)url
    completionHandler: (void(^)(UIImage *image, NSError *error))completion;

- (void)cancelLoading;

@end
