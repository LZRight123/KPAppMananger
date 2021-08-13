//
//  KPAppTool.h
//  AutoDownload
//
//  Created by 梁泽 on 2021/5/21.
//

#import <Foundation/Foundation.h>
#pragma mark - 数据模型
@interface _LSLazyPropertyList : NSObject 
@property (readonly) NSDictionary *propertyList;
+ (id)lazyPropertyListWithLazyPropertyLists:(id)arg1;
+ (id)lazyPropertyListWithPropertyList:(id)arg1;
@end
//shortVersionString teamID -super: bundleIdentifier entitlements environmentVariables localizedShortName signerIdentity
@interface LSApplicationProxy : NSObject
@property (nonatomic, readonly) NSString *localizedName; //app 名字
@property (nonatomic, readonly) NSString *localizedShortName;// app 名字
@property (nonatomic, readonly) NSString *shortVersionString;//version
@property (nonatomic, readonly) NSString *bundleVersion; //build号 60404
@property (nonatomic, readonly) NSString *bundleType;// @"User"  @"System"
// super
@property (nonatomic, readonly) NSString *bundleIdentifier;
@property (setter=_setEntitlements:, nonatomic, copy) _LSLazyPropertyList *_entitlements; //看下这个可以写权限不
@property (setter=_setEntitlements:, nonatomic, copy) _LSLazyPropertyList *_environmentVariables; //看下这个可以写权限不
@property (nonatomic, readonly) NSString *teamID;
@property (nonatomic, readonly) NSString *signerIdentity;//Apple Development: Xiaolin Guo (SVAVPRD74S)
- (void)_setEntitlements:(id)_entitlements;
@end


#pragma mark - 工具类
typedef void(^KPNotifcationHanlderType)(NSString *);
@interface KPAppTool : NSObject
/// 设置bundleid后 打开 卸载的bundleId传nil 就取此bid
@property (strong, nonatomic) NSString *bundleId;


/// 进程间通信通知 所有的
@property (copy, nonatomic) void(^hanlderIPCNotify)(NSString *name);
@property (strong, nonatomic, readonly) NSMutableDictionary *notifiHandlers;


#define KPAppToolInstance [KPAppTool shareInstance]
+(instancetype) shareInstance;
/*
 从一个本地path 初始化ipa, 内部会copy一份tmp文件
 需要权限
 */
+ (void)installAppWithIpaPath:(NSString *)ipaPath block:(void(^)(NSArray<NSDictionary *> *progressList, BOOL isCompletion, NSError *error))block;
/*
 从一个本地url 初始化ipa
 需要权限
 暂时对外隐藏
 */
+ (void)installAppWithIpaPathURL:(NSURL *)ipaPath  block:(void(^)(NSArray<NSDictionary *> *progressList, BOOL isCompletion, NSError *error))block;
/*
 从远程URL下载 初始化
 appIdentfier 可以为nil
 需要权限
 */
+ (void)installAppWithRemoteURL:(NSString *)url downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgress completion:(void(^)(NSArray<NSDictionary *> *progressList, BOOL isCompletion, NSError *error))block;

/*
 根据bundleId 打开app
 */
+ (bool)openApplicationWithBundleID:(NSString *)bundleId;
/// 卸载app
+ (bool)uninstallApplication:(NSString *)bundleId;

/// 获取 LSApplicationProxy
+ (LSApplicationProxy *)applicationProxy:(NSString *)bundleId;


///MARK: - 通知 回调用 hanlderIPCNotify
- (void)registerIPCNotfication:(NSString *)notifyName;
- (void)registerIPCNotfication:(NSString *)notifyName callBack:(KPNotifcationHanlderType)callBack;
- (uint32_t)postIPCNoftication:(NSString *)notifyName;
/// 发起ping "kp.xm.ping" 接收app 监听 service掉用
- (void)pingTimeSecond:(int)second callBack:(dispatch_block_t)callBack;
/// 接收方 接收到ping 后续动作
- (void)recevicePingCallBack:(KPNotifcationHanlderType)callBack;

/// 设备UDID
+ (NSString *)UDID;
// ComputerName-关于本机-名称 DeviceColor-颜色 ModelNumber-型号号码 RegionCode RegionInfo
+ (NSDictionary *)deviceInfo;
+ (BOOL)isChina;
///MARK: - App下载相关
/// 清空下载文件夹
+ (void)clearDownloadFiles;
/// 下载的本地路径
+ (NSURL *)fileUrlWithRemoteUrl:(NSString *)URLString  suggestedFilename:(NSString *)suggestedFilename;
/// 断点下载的resumeData
+ (NSString *)resumeDataFilePathWithKey:(NSString *)key;
/// 清空下载resumeData文件夹
+ (void)clearResumeDataFiles;
+ (void)clearResumeDataWithKey:(NSString *)key;
@end

