//
//  KPHTTPManager.m
//  KPAppInstall
//
//  Created by 梁泽 on 2021/7/5.
//

#import "KPHTTPManager.h"
#import <CommonCrypto/CommonDigest.h>
#import "KPAppTool.h"
@interface KPHTTPManager()
//@property (strong, nonatomic)
@end
//MARK:- 类的实现
@implementation KPHTTPManager
+ (instancetype)sharedManager {
    static KPHTTPManager *sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        sharedManager = [[KPHTTPManager alloc] initWithSessionConfiguration:config];
        sharedManager.requestSerializer.timeoutInterval = 30;
    });
    
    return sharedManager;
}

+ (instancetype)downloadManager{
    static KPHTTPManager *downloadManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
//        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"com.kp.download"];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        //系统根据当前性能自动处理后台任务的优先级
//        config.discretionary = YES;
        downloadManager = [[KPHTTPManager alloc] initWithSessionConfiguration:config];
//        [downloadManager saveDownloadResumeData];
    });
    
    return downloadManager;
}


- (NSURLSessionDownloadTask *)downloadFile:(NSString *)URLString
                                  progress:(void (^)(NSProgress *downloadProgress))downloadProgressBlock
                         completionHandler:(void (^)(NSURLResponse * response, NSURL * filePath, NSError * error))completionHandler{
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    NSData *resumeData = [KPHTTPManager resumeDataWithKey:URLString];
    return [self downloadTaskWithRequest:urlRequest resumeData:resumeData progress:downloadProgressBlock  destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        NSURL *des = [KPAppTool fileUrlWithRemoteUrl:URLString suggestedFilename:response.suggestedFilename];
        return des;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        NSURL *localUrl = [KPAppTool fileUrlWithRemoteUrl:URLString suggestedFilename:response.suggestedFilename];
        BOOL result = NO;
        if ([localUrl isEqual:filePath]) {
            result = YES;
            [KPHTTPManager removeResumeDataWithKey:URLString];
        }
        if ( (result && completionHandler) || error) {
            completionHandler(response,filePath,error);
        }
    }];
}


- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request resumeData:(NSData *)resumeData  progress:(void (^)(NSProgress *progress))downloadProgressBlock destination:(NSURL * (^)(NSURL * targetPath, NSURLResponse * response))destination completionHandler:(void (^)(NSURLResponse * response, NSURL * filePath, NSError * error))completionHandler{
    NSURLSessionDownloadTask *downloadTask = nil;
    if (resumeData) {
        downloadTask = [super downloadTaskWithResumeData:resumeData progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    }else{
        downloadTask = [super downloadTaskWithRequest:request progress:downloadProgressBlock destination:destination completionHandler:completionHandler];
    }
    [downloadTask resume];
    return downloadTask;
}

- (void)cancelAllDownloads {
    for (NSURLSessionDownloadTask *task in self.downloadTasks) {
        [task cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
            NSString *key = task.currentRequest.URL.absoluteString;
            [KPHTTPManager saveResumeData:resumeData withKey:key];
            NSLog(@"");
        }];
    }
}
- (void)saveDownloadResumeData{
//    [self setTaskDidCompleteBlock:^(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSError * _Nullable error) {
//        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]){
////            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
////            NSString *key = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
////            [KPHTTPManager saveResumeData:resumeData withKey:key];
//            NSLog(@"");
//        }
//    }];
}

- (void)suspendAllDownloads {
    for (NSURLSessionDownloadTask *task in self.downloadTasks) {
        [task suspend];
    }
}

- (void)resumeAllDownloads {
    for (NSURLSessionDownloadTask *task in self.downloadTasks) {
        [task resume];
    }
}


// key就是URL
+ (NSData *)resumeDataWithKey:(id)key{
    NSString *path = [KPAppTool resumeDataFilePathWithKey:key];
    NSData *data = [NSData dataWithContentsOfFile:path];
    return data;
}

+ (void)saveResumeData:(NSData *)resumeData withKey:(NSString *)key {
    NSString *path = [KPAppTool resumeDataFilePathWithKey:key];
    NSError *error;
    [resumeData writeToFile:path options:NSDataWritingAtomic error:&error];
    NSMutableData *data = [[[NSData alloc] init] mutableCopy];
    [data appendData:resumeData];
}
// key就是URL
+ (void)removeResumeDataWithKey:(NSString *)key {
    NSString *filePath = [KPAppTool resumeDataFilePathWithKey:key];
    if (filePath) {
        [[NSFileManager defaultManager]removeItemAtPath:filePath error:nil];
    }
}

@end


//MARK:- 文件辅助相关
NSString *kp_directoryFor(NSString *directoryName) {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *path = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
    path = [[path stringByAppendingPathComponent:@"aaa.com.kp.installer"] stringByAppendingPathComponent:directoryName];
    if (![fileManager fileExistsAtPath:path]) {
        [fileManager createDirectoryAtPath:path withIntermediateDirectories:true attributes:nil error:nil];
    }
    return path;
}

NSString *kp_md5WithString(NSString *string)
{
    if (string.length == 0) {
        return nil;
    }
    
    const char *cStr = [string UTF8String];
    unsigned char digest[CC_MD5_DIGEST_LENGTH];
    CC_MD5(cStr, (unsigned int)strlen(cStr), digest); // This is the md5 call
    NSMutableString *output = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for(int i = 0; i < CC_MD5_DIGEST_LENGTH; i++){
        [output appendFormat:@"%02x", digest[i]];
    }
    return output;
}
//MARK:- 文件辅助相关



//MARK:- 重要
@implementation NSURLSessionTask (RemoveKVO)
//- (void)dealloc{
//    if ([self isKindOfClass:NSClassFromString(@"__NSCFBackgroundDownloadTask")]) {
//        @try {
//            if ([[KPHTTPManager downloadManager] respondsToSelector:NSSelectorFromString(@"removeDelegateForTask:")]) {
//                [[KPHTTPManager downloadManager] performSelector:NSSelectorFromString(@"removeDelegateForTask:") withObject:self];
//            }
//        } @catch (NSException *exception) {
//
//        } @finally {
//
//        }
//    }
//}
@end
