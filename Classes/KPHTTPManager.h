//
//  KPHTTPManager.h
//  KPAppInstall
//
//  Created by 梁泽 on 2021/7/5.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>


NSString *kp_directoryFor(NSString *directoryName);
NSString *kp_md5WithString(NSString *string);
NS_ASSUME_NONNULL_BEGIN

@interface KPHTTPManager : AFHTTPSessionManager
+ (instancetype)downloadManager;
+ (instancetype)sharedManager;

- (NSURLSessionDownloadTask *)downloadFile:(NSString *)URLString
                                  progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         completionHandler:(void (^)(NSURLResponse * response, NSURL * filePath, NSError * error))completionHandler;

- (void)cancelAllDownloads;

- (void)suspendAllDownloads;
- (void)resumeAllDownloads;
@end

NS_ASSUME_NONNULL_END



@interface NSURLSessionTask (RemoveKVO)

@end
