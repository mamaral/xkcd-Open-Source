//
//  RequestManager.m
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import "RequestManager.h"

static NSString * const kLatestComicURLString = @"https://xkcd.com/info.0.json";
static NSString * const kComicURLFormat = @"https://xkcd.com/%ld/info.0.json";

// xkcd.com serves these over HTTP/2, so they share a single connection; each request is mostly
// waiting on latency, so a couple dozen in flight keeps the first-launch download reasonably quick.
static NSUInteger const kMaxConcurrentComicDownloads = 24;
static NSTimeInterval const kRequestTimeout = 20.0;

@interface RequestManager ()

- (void)GETJSONFromURL:(NSURL *)url completionHandler:(void (^)(NSError *error, id json))handler;
- (NSError *)errorWithMessage:(NSString *)errorMessage;

@end


// Tracks a batch of comic downloads, keeping a limited number of requests in flight so we
// don't hammer xkcd.com when we need to download the entire archive on first launch.
@interface ComicBatchDownload : NSObject

@property (nonatomic, weak) RequestManager *requestManager;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *pendingNumbers;
@property (nonatomic, strong) NSMutableArray *comicDicts;
@property (nonatomic, strong) NSError *firstError;
@property (nonatomic) NSUInteger requestsInFlight;
@property (nonatomic, copy) void (^completionHandler)(NSError *error, NSArray *comicDicts);

@end

@implementation ComicBatchDownload

- (void)startNextRequests {
    while (self.requestsInFlight < kMaxConcurrentComicDownloads && self.pendingNumbers.count > 0) {
        NSInteger number = [self.pendingNumbers.firstObject integerValue];
        [self.pendingNumbers removeObjectAtIndex:0];
        self.requestsInFlight++;

        NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:kComicURLFormat, (long)number]];

        // The request's completion block keeps this batch alive until everything has finished.
        [self.requestManager GETJSONFromURL:url completionHandler:^(NSError *error, id json) {
            self.requestsInFlight--;

            if ([json isKindOfClass:[NSDictionary class]]) {
                [self.comicDicts addObject:json];
            } else if (!self.firstError) {
                self.firstError = error ?: [self.requestManager errorWithMessage:kRequestManagerInvalidResponseErrorMessage];
            }

            [self startNextRequests];
        }];
    }

    if (self.requestsInFlight == 0 && self.pendingNumbers.count == 0 && self.completionHandler) {
        void (^handler)(NSError *, NSArray *) = self.completionHandler;
        self.completionHandler = nil;
        handler(self.firstError, [self.comicDicts copy]);
    }
}

@end


@implementation RequestManager


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

    if (!self) {
        return nil;
    }

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.timeoutIntervalForRequest = kRequestTimeout;

    // Deliver completions on the main queue, since callers touch Realm and the UI.
    self.session = [NSURLSession sessionWithConfiguration:configuration delegate:nil delegateQueue:[NSOperationQueue mainQueue]];

    return self;
}


#pragma mark - Downloading comics

- (void)downloadLatestComicWithCompletionHandler:(void (^)(NSError *error, NSDictionary *latestComic))handler {
    [self GETJSONFromURL:[NSURL URLWithString:kLatestComicURLString] completionHandler:^(NSError *error, id json) {
        if (![json isKindOfClass:[NSDictionary class]]) {
            handler(error ?: [self errorWithMessage:kRequestManagerInvalidResponseErrorMessage], nil);
            return;
        }

        handler(nil, json);
    }];
}

- (void)downloadComicsWithNumbers:(NSArray<NSNumber *> *)numbers completionHandler:(void (^)(NSError *error, NSArray *comicDicts))handler {
    NSParameterAssert(handler);

    ComicBatchDownload *batch = [ComicBatchDownload new];
    batch.requestManager = self;
    batch.pendingNumbers = [(numbers ?: @[]) mutableCopy];
    batch.comicDicts = [NSMutableArray arrayWithCapacity:numbers.count];
    batch.completionHandler = handler;
    [batch startNextRequests];
}


#pragma mark - Requests

- (void)GETJSONFromURL:(NSURL *)url completionHandler:(void (^)(NSError *error, id json))handler {
    NSURLSessionDataTask *task = [self.session dataTaskWithURL:url completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            handler(error, nil);
            return;
        }

        NSInteger statusCode = [response isKindOfClass:[NSHTTPURLResponse class]] ? ((NSHTTPURLResponse *)response).statusCode : 0;
        if (statusCode < 200 || statusCode >= 300 || !data) {
            handler([self errorWithMessage:kRequestManagerInvalidResponseErrorMessage], nil);
            return;
        }

        NSError *parseError = nil;
        id json = [NSJSONSerialization JSONObjectWithData:data options:0 error:&parseError];
        handler(json ? nil : parseError, json);
    }];

    [task resume];
}


#pragma mark - Error handling

- (NSError *)errorWithMessage:(NSString *)errorMessage {
    return [NSError errorWithDomain:kRequestManagerErrorDomain code:kRequestManagerErrorCode userInfo:@{kRequestManagerUserInfoKey: errorMessage ?: @""}];
}

@end
