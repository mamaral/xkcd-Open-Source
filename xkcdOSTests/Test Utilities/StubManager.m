//
//  StubManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/22/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "StubManager.h"
#import <OHHTTPStubs/HTTPStubs.h>
#import <OHHTTPStubs/HTTPStubsResponse+JSON.h>

@implementation StubManager

+ (instancetype)sharedInstance {
    static StubManager *sharedInstance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        sharedInstance = [[self alloc] init];
    });

    return sharedInstance;
}

- (void)stubResponseWithStatusCode:(int)statusCode object:(id)object delay:(NSTimeInterval)delay {
    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString hasPrefix:@"https://xkcd.com/"];
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        return [[HTTPStubsResponse responseWithJSONObject:object ?: @{} statusCode:statusCode headers:nil] responseTime:delay];
    }];
}

- (void)stubComics:(NSArray<NSDictionary *> *)comicDicts {
    NSMutableDictionary *comicsByPath = [NSMutableDictionary dictionary];
    NSDictionary *latest = nil;

    for (NSDictionary *comicDict in comicDicts) {
        NSInteger num = [comicDict[@"num"] integerValue];
        comicsByPath[[NSString stringWithFormat:@"/%ld/info.0.json", (long)num]] = comicDict;

        if (!latest || num > [latest[@"num"] integerValue]) {
            latest = comicDict;
        }
    }

    if (latest) {
        comicsByPath[@"/info.0.json"] = latest;
    }

    [HTTPStubs stubRequestsPassingTest:^BOOL(NSURLRequest *request) {
        return [request.URL.absoluteString hasPrefix:@"https://xkcd.com/"];
    } withStubResponse:^HTTPStubsResponse *(NSURLRequest *request) {
        NSDictionary *comicDict = comicsByPath[request.URL.path];
        return [HTTPStubsResponse responseWithJSONObject:comicDict ?: @{} statusCode:comicDict ? 200 : 404 headers:nil];
    }];
}

- (void)removeAllStubs {
    [HTTPStubs removeAllStubs];
}

@end
