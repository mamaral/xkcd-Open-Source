//
//  AltView.h
//  xkcDump
//
//  Created by Mike on 5/16/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AltView : UIView

@property (nonatomic, strong) NSString *altText;
@property (nonatomic, strong) UILabel *altLabel;

@property (nonatomic) BOOL isVisible;

- (instancetype)initWithAltText:(NSString *)altText;
- (void)layoutFacade;
- (void)show;
- (void)dismissWithCompletion:(dispatch_block_t)completion;

@end
