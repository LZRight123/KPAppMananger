//
//  KPLocalWebServerManager.h
//  KPAppInstall
//
//  Created by 梁泽 on 2021/6/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KPLocalConnectManager : NSObject
#define KPLocalConnect [KPLocalConnectManager shareInstance]
+(instancetype) shareInstance;
/// 服务端
- (void)registerLisenerAtPort:(int)port callBack:(NSDictionary *(^)(NSInteger actionType ,NSDictionary *context))hanler;

/// 用户端
- (void)getAtPort:(int)port actionType:(NSInteger)actionType completion:(void(^)(NSDictionary *response, NSError *error, NSURLSessionDataTask *task))completion;
- (void)getAtPort:(int)port parameters:(NSDictionary *)parameters completion:(void(^)(NSDictionary *response, NSError *error, NSURLSessionDataTask *task))completion;
@end

NS_ASSUME_NONNULL_END

/* using
 [KPLocalConnect registerLisenerAtPort:5555 callBack:^NSDictionary * _Nonnull(NSInteger actionType ,NSDictionary *context) {
     switch actionType{
     }
 }];
 
 /// 客户端
 [KPLocalConnect getAtPort:5555 actionType:1 completion:^(NSDictionary * _Nonnull response, NSError * _Nonnull error, NSURLSessionDataTask * _Nonnull task) {
     NSLog(@"response: %@", response);;
 }];
 
 [KPLocalConnect getAtPort:5555 parameters:@{@"actionType": @1} completion:^(NSDictionary * _Nonnull response, NSError * _Nonnull error, NSURLSessionDataTask * _Nonnull task) {
     NSLog(@"response: %@", response);;
 }];
 */
