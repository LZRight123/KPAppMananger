//
//  KPLocalWebServerManager.m
//  KPAppInstall
//
//  Created by 梁泽 on 2021/6/24.
//

#import "KPLocalConnectManager.h"
#import <GCDWebServer/GCDWebServer.h>
#import <GCDWebServer/GCDWebServerDataResponse.h>
#import <AFNetworking/AFHTTPSessionManager.h>
@interface KPLocalConnectManager()
@property (strong, nonatomic) GCDWebServer* webServer;
@property (strong, nonatomic) AFHTTPSessionManager *afnManager;
@end

@implementation KPLocalConnectManager
+(instancetype) shareInstance
{
    static KPLocalConnectManager *_instance;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    }) ;
    return _instance ;
}

- (void)registerLisenerAtPort:(int)port callBack:(NSDictionary *(^)(NSInteger actionType ,NSDictionary *context))hanler{
    if (!_webServer) {
        _webServer = [[GCDWebServer alloc] init];
    }
    
    static dispatch_once_t onceToken;   // typedef long dispatch_once_t;
    dispatch_once(&onceToken, ^{
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            @try {
                
                [self.webServer addDefaultHandlerForMethod:@"GET"
                                          requestClass:[GCDWebServerRequest class]
                                          processBlock:^GCDWebServerResponse *(GCDWebServerRequest* request) {
                    NSDictionary *dic = request.query;
                    NSDictionary *responseDic = hanler([dic[@"actionType"] integerValue], dic);
                    return [GCDWebServerDataResponse responseWithJSONObject:responseDic];
                }];
                
                NSMutableDictionary* options = [NSMutableDictionary dictionary];
                [options setObject:[NSNumber numberWithInteger:port] forKey:GCDWebServerOption_Port];
                [options setValue:@NO forKey:GCDWebServerOption_AutomaticallySuspendInBackground];
                [options setValue:@YES forKey:GCDWebServerOption_BindToLocalhost];
                NSError *error;
                bool success = [self.webServer startWithOptions:options error:&error];
                NSLog(@"Visit %@ in your web browser  success: %d error: %@" , _webServer.serverURL, success, error);
            } @catch (NSException *e) {
                
            }
        });
    });
}


/// 用户端
- (void)getAtPort:(int)port actionType:(NSInteger)actionType completion:(void(^)(NSDictionary *response, NSError *error, NSURLSessionDataTask *task))completion {
    [self getAtPort:port parameters:@{@"actionType": @(actionType)} completion:completion];
}

- (void)getAtPort:(int)port parameters:(NSDictionary *)parameters completion:(void(^)(NSDictionary *response, NSError *error, NSURLSessionDataTask *task))completion {
    if (!_afnManager) {
        _afnManager = [[AFHTTPSessionManager manager] initWithBaseURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://localhost:%d", port]]];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            [_afnManager GET:@"kp" parameters:parameters headers:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (completion) {
                        completion(responseObject, nil, task);
                    }
                });
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    if (completion) {
                        completion(nil, error, task);
                    }
                });
            }];
        } @catch (NSException *e) {
            
        }
    });
    
   
}


@end
