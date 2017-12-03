//
//  RequestManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "RequestManager.h"
#import "DataManager.h"

static NSString * const kFetchURLString = @"http://xkcdos.app.sgnl24.com/fetch-comics.php";
static NSString * const kLatestComicFetchUrlString = @"http://xkcdos.app.sgnl24.com/latest-comic.php";
static NSString * const kTokenPostURLString = @"http://xkcdos.app.sgnl24.com/register-push.php";

@implementation RequestManager {
    DataManager *_dataManager;
}


#pragma mark - Singleton

+ (instancetype)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&pred, ^{
        _sharedObject = [[self alloc] init];
    });

    return _sharedObject;
}


#pragma mark - Initialization

- (instancetype)init {
    self = [super init];

    self.manager = [self generateHTTPRequestOperationManager];

    _dataManager = [DataManager sharedInstance];

    return self;
}

- (AFHTTPRequestOperationManager *)generateHTTPRequestOperationManager {
    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:kDefaultContentType forHTTPHeaderField:kContentTypeKey];

    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    manager.requestSerializer = serializer;

    return manager;
}


#pragma mark - Downloading comics

- (void)downloadComicsSince:(NSInteger)since completionHandler:(void (^)(NSError *error, NSArray *comicDicts))handler {
    NSDictionary *params = @{@"since": [NSString stringWithFormat:@"%ld", (long)since]};

    [self.manager GET:kFetchURLString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(nil, (NSArray *)responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(error, nil);
    }];
}

- (void)downloadLatestComicWithCompletionHandler:(void (^)(NSError *error, NSDictionary *latestComic))handler {
    [self.manager GET:kLatestComicFetchUrlString parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(nil, (NSDictionary *)responseObject);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(error, nil);
    }];
}


#pragma mark - Device tokens

- (void)sendDeviceToken:(NSString *)token completionHandler:(void (^)(NSError *error))handler {
    if (!token) {
        NSError *error = [self errorWithMessage:kRequestManagerNilTokenErrorMessage];
        handler(error);
        return;
    }

    NSDictionary *params = @{@"token": token};

    [self.manager POST:kTokenPostURLString parameters:params success:^(AFHTTPRequestOperation *operation, id responseObject) {
        handler(nil);
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        handler(error);
    }];
}


#pragma mark - Error handling

- (NSError *)errorWithMessage:(NSString *)errorMessage {
    return [NSError errorWithDomain:kRequestManagerErrorDomain code:kRequestManagerErrorCode userInfo:@{kRequestManagerUserInfoKey: errorMessage ?: @""}];
}

@end
