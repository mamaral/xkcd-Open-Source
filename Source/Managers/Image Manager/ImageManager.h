//
//  ImageManager.h
//  xkcd Open Source
//
//  Created by Mike on 3/14/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * The ImageManager class is responsible for keeping a local cache of images
 * used in the app, loading and saving images to disk, and downloading remote
 * images and updating the cache and disk with the recently downloaded images.
 * It also provides a mechanism to cancel previous download handler operations,
 * aimed at high performance when used in conjunction with UITableView and
 * UIScrollView cell reuse.
 */
@interface ImageManager : NSObject

@property (nonatomic) NSUInteger cacheLimit;

/**
 * Returns an image with a given filename if it's present in our image cache.
 * If the image isn't in the cache but has been previously saved to disk, the
 * image is asynchronously loaded from disk and the handler block is called
 * with that image. If the image is not in our cache or on disk, it is then
 * downloaded from the provided remote url, saved in both the cache and on
 * disk, and the provided handler block is called with the image.
 *
 * @param filename The name of the file that will be used as the key in the image
 * cache and the path for the image to be loaded on or saved to disk.
 *
 * @param urlString The string representation of the remote url for this image
 * that will be used to download the image if it is not present in the cache
 * or on disk.
 *
 * @param handler A block that will be called only when an image is
 * not found in our cache and is either loaded from disk or successfully
 * downloaded from the provided url.
 *
 * @return The image loaded from our cache if present; nil otherwise.
 */
- (nullable UIImage *)loadImageWithFilename:(NSString *)filename
                                  urlString:(NSString *)urlString
                                    handler:(void (^)(UIImage * nullable))handler;

/**
 * Cancels the download handler for a given filename, preventing a previous
 * download operation from calling the download handler for that file.
 *
 * @param filename The name of the file downloaded.
 */
- (void)cancelDownloadHandlerForFilename:(nullable NSString *)filename;

@end

NS_ASSUME_NONNULL_END
