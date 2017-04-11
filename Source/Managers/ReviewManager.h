//
//  ReviewManager.h
//  xkcd Open Source
//
//  Created by Mike on 4/10/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The review manager is responsible
 */
@interface ReviewManager : NSObject

/**
 * Our initial strategy will be to prompt users to leave a review on every
 * sixth app session per version of the app. That seems fairly reasonable as
 * most people will view the app when new comics come out M/W/F, so that would
 * mean after you download a new version you'll be prompted to review on average
 * after two weeks of use. I'm hoping this isn't too much, I guess time will tell!
 */
- (void)handleAppLaunched;

@end

NS_ASSUME_NONNULL_END
