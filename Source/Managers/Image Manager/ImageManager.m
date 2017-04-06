//
//  ImageManager.m
//
//  Created by Mike on 3/14/17.
//  Copyright © 2017 Mike Amaral. All rights reserved.
//

#import "ImageManager.h"

@interface ImageManager ()

/**
 * The path to this application's documents directory, used for storing downloaded
 * images on disk.
 */
@property (nonatomic, strong) NSString *documentsDirectoryPath;

/**
 * A reference to the default NSFileManager instance, used for storing and
 * retrieving image data from disk.
 */
@property (nonatomic, strong) NSFileManager *fileManager;

/**
 * The cache we will use to store images in memory while the application
 * is running.
 */
@property (nonatomic, strong) NSCache *imageCache;

/**
 * Our download queue we will use to schedule image download block operations.
 */
@property (nonatomic, strong) NSOperationQueue *downloadQueue;

@end

@implementation ImageManager

- (instancetype)init {
    self = [super init];

    if (!self) {
        return nil;
    }

    // Create a new queue we'll use for the download operations.
    self.downloadQueue = [NSOperationQueue new];
    self.downloadQueue.maxConcurrentOperationCount = NSOperationQueueDefaultMaxConcurrentOperationCount;

    // Get our documents directory path.
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    self.documentsDirectoryPath = paths.firstObject;

    // Create our file manager.
    self.fileManager = [NSFileManager defaultManager];

    // Create our image cache
    self.imageCache = [NSCache new];

    return self;
}

- (nullable UIImage *)loadImageWithFilename:(NSString *)filename
                                  urlString:(NSString *)urlString
                                    handler:(void (^)(UIImage * nullable))handler {
    // #1 - Load from cache synchronously.
    UIImage *cachedImage = [self.imageCache objectForKey:filename];
    if (cachedImage) {
        return cachedImage;
    }

    // #2 - Load from disk asynchronously.
    NSString *path = [self.documentsDirectoryPath stringByAppendingPathComponent:filename];
    if ([self.fileManager fileExistsAtPath:path]) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{

            // If an image was loaded from disk, call our handler on the main thread
            // providing that image.
            UIImage *imageOnDisk = [self loadImageFromDiskWithFilename:filename];
            if (imageOnDisk) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    handler(imageOnDisk);
                });
            }
        });
    }

    // #3 - Download from remote URL asynchronously.
    else {
        [self downloadAndStoreImageFromURLString:urlString filename:filename handler:handler];
    }

    // If we got this far, the image was not found in the cache and we will hopefully
    // be calling the handler at some FUTURE.TIME with the image.
    return nil;
}

- (void)cancelDownloadHandlerForFilename:(nullable NSString *)filename {
    if (filename.length == 0) {
        return;
    }

    for (NSBlockOperation *operation in self.downloadQueue.operations) {
        if ([operation.name isEqualToString:filename]) {
            [operation cancel];
            return;
        }
    }
}


#pragma mark - Loading images from disk

/**
 * Loads and returns the image previously saved to the documents directory.
 *
 * @param filename The filename the image was saved with.
 *
 * @return The image previously saved to the documents directory, if it exists, otherwise returns nil.
 */
- (nullable UIImage *)loadImageFromDiskWithFilename:(NSString *)filename {
    NSString *path = [self.documentsDirectoryPath stringByAppendingPathComponent:filename];

    if ([self.fileManager fileExistsAtPath:path]) {
        NSData *dataFromDisk = [self.fileManager contentsAtPath:path];
        UIImage *imageFromDisk = [UIImage imageWithData:dataFromDisk];

        if (imageFromDisk) {
            [self updateCacheWithFilename:filename image:imageFromDisk];
            return imageFromDisk;
        }
    }

    return nil;
}


#pragma mark - Download and storing images

/**
 * Downloads image data from a remote URL and upon success stores the image in our cache and on disk.
 *
 * @param urlString The remote URL string where the image can be downloaded from.
 * @param filname The name of the image to be used as the key in the cache, the name of the
 * file on disk, and as the key for the download operation.
 * @param handler A block that takes a single UIImage argument that will be called only when the image
 * is successfully downloaded.
 */
- (void)downloadAndStoreImageFromURLString:(NSString *)urlString filename:(NSString *)filename handler:(void (^)(UIImage *))handler {
    __block NSBlockOperation *downloadOperation = [NSBlockOperation blockOperationWithBlock:^{
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *dataFromServer = [NSData dataWithContentsOfURL:url];

        if (dataFromServer) {
            UIImage *imageFromServer = [UIImage imageWithData:dataFromServer];

            if (imageFromServer) {
                // Dispatch the handler on the main thread only if our operation wasn't cancelled.
                if (![downloadOperation isCancelled]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        handler(imageFromServer);
                    });
                }

                // Now let's update the cache with the newly downloaded image.
                [self updateCacheWithFilename:filename image:imageFromServer];
            }

            // Save the raw image data to disk.
            NSString *path = [self.documentsDirectoryPath stringByAppendingPathComponent:filename];
            [dataFromServer writeToFile:path atomically:YES];
        }
    }];

    // Set the download operation's name as the filename - this will be used if we want to cancel the
    // download operation in the future.
    downloadOperation.name = filename;

    [self.downloadQueue addOperation:downloadOperation];
}


#pragma mark - Image caching

/**
 * Updates our image cache by adding the provided filename as the key and the image object
 * as the value for that key.
 *
 * @param filename The name of the image file that will be used as the key for the image.
 * @param image The image to be cached.
 */
- (void)updateCacheWithFilename:(NSString *)filename image:(UIImage *)image {
    NSParameterAssert(filename);
    NSParameterAssert(image);

    // Insert the new key/value pair in the cache.
    [self.imageCache setObject:image forKey:filename];
}

@end
