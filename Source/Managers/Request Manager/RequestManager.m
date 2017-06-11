//
//  RequestManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "RequestManager.h"

#import <AFNetworking.h>

NS_ASSUME_NONNULL_BEGIN;

static NSString * const kDefaultContentType = @"application/x-www-form-urlencoded";
static NSString * const kContentTypeKey = @"Content-Type";

@interface RequestManager ()

@property (nonatomic, strong) AFHTTPRequestOperationManager *manager;

@end


@implementation RequestManager

#pragma mark - Initialization

- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    AFHTTPRequestSerializer *serializer = [AFHTTPRequestSerializer serializer];
    [serializer setValue:kDefaultContentType forHTTPHeaderField:kContentTypeKey];

    self.manager = [AFHTTPRequestOperationManager manager];
    self.manager.requestSerializer = serializer;

    return self;
}

#pragma mark - Sending requests

- (void)sendPOSTRequestToURL:(NSString *)urlString params:(nullable NSDictionary *)params handler:(RequestHandler)handler {
    NSLog(@"Sending POST request to %@ with params: %@", urlString, params);

    [self.manager POST:urlString parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"POST success with response: %@", responseObject);
        handler(nil, responseObject);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"POST failed with error: %@", error);
        handler(error, nil);
    }];
}

- (void)sendGETRequestToURL:(NSString *)urlString params:(nullable NSDictionary *)params handler:(RequestHandler)handler {
    NSLog(@"Sending GET request to %@ with params: %@", urlString, params);

    [self.manager GET:urlString parameters:params success:^(AFHTTPRequestOperation * _Nonnull operation, id  _Nonnull responseObject) {
        NSLog(@"GET success with response: %@", responseObject);
        handler(nil, responseObject);
    } failure:^(AFHTTPRequestOperation * _Nullable operation, NSError * _Nonnull error) {
        NSLog(@"GET failed with error: %@", error);
        handler(error, nil);
    }];
}

@end

NS_ASSUME_NONNULL_END
