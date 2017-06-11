//
//  RequestManager.h
//  xkcd Open Source
//
//  Created by Mike on 5/14/15.
//  Copyright (c) 2015 Mike Amaral. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface RequestManager : NSObject

typedef void (^_Nonnull RequestHandler)(NSError * _Nullable error, id _Nullable responseObject);

- (void)sendPOSTRequestToURL:(NSString *)urlString params:(nullable NSDictionary *)params handler:(RequestHandler)handler;
- (void)sendGETRequestToURL:(NSString *)urlString params:(nullable NSDictionary *)params handler:(RequestHandler)handler;

@end

NS_ASSUME_NONNULL_END
