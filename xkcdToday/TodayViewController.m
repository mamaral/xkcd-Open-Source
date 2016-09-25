//
//  TodayViewController.m
//  xkcdToday
//
//  Created by Mike on 9/24/16.
//  Copyright © 2016 Mike Amaral. All rights reserved.
//

#import "TodayViewController.h"
#import <NotificationCenter/NotificationCenter.h>
#import "DataManager.h"
#import <UIImageView+WebCache.h>
#import "ThemeManager.h"

@interface TodayViewController () <NCWidgetProviding>

@property (strong, nonatomic) IBOutlet UIImageView *comicImageView;

@end

@implementation TodayViewController

- (void)viewDidLoad {
    [super viewDidLoad];


}

- (void)widgetPerformUpdateWithCompletionHandler:(void (^)(NCUpdateResult))completionHandler {
    // Perform any setup necessary in order to update the view.
    [[DataManager sharedInstance] downloadLatestComicsWithCompletionHandler:^(NSError *error, NSInteger numberOfNewComics) {
        if (error) {
            completionHandler(NCUpdateResultFailed);
        } else if (numberOfNewComics == 0) {
            completionHandler(NCUpdateResultNoData);
        } else {
            Comic *latestComic = [[DataManager sharedInstance] allSavedComics][2];
            [self.comicImageView sd_setImageWithURL:[NSURL URLWithString:latestComic.imageURLString ?: @""] placeholderImage:[ThemeManager loadingImage]];

            completionHandler(NCUpdateResultNewData);
        }
    }];
}

@end
