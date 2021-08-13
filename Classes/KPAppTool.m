//
//  KPAppTool.m
//  AutoDownload
//
//  Created by 梁泽 on 2021/5/21.
//

#import "KPAppTool.h"
#import "LSApplicationWorkspace.h"
#import <notify.h>
#import <dlfcn.h>
#import "MobileGestalt.h"
#import "KPHTTPManager.h"
static void NotificationReceivedCallBack(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userinfo) {
    NSString *notifyName = (__bridge NSString *)name;
//    NSLog(@"[from ipcIOSReBookApp] notify name = %@", notifyName);
    if (KPAppTool.shareInstance.hanlderIPCNotify) {
        KPAppTool.shareInstance.hanlderIPCNotify(notifyName);
    }
    
    
    if (KPAppToolInstance.notifiHandlers[notifyName]) {
        ((KPNotifcationHanlderType)KPAppToolInstance.notifiHandlers[notifyName])(notifyName);
    }
}


@interface KPAppTool()
@property (strong, nonatomic, readwrite) NSMutableDictionary *notifiHandlers;
@property (strong, nonatomic) dispatch_source_t  timer;

/// ipc
@property (strong, nonatomic) dispatch_queue_t executionQueue;
@end

@implementation KPAppTool

+(instancetype) shareInstance
{
    static KPAppTool *_instance;
    static dispatch_once_t onceToken ;
    dispatch_once(&onceToken, ^{
//        [UIApplication sharedApplication].networkActivityIndicatorVisible = true;
        _instance = [[self alloc] init] ;
        _instance.bundleId = @"";
        _instance.notifiHandlers = @{}.mutableCopy;
        _instance.executionQueue = dispatch_queue_create("kp.xpc.run.queue", DISPATCH_QUEUE_CONCURRENT);
    }) ;
    
    return _instance ;
}


+ (void)installAppWithIpaPath:(NSString *)ipaPath  block:(void(^)(NSArray<NSDictionary *> *progressList, BOOL isCompletion, NSError *error))block {
    if (ipaPath.length <= 0) {
        if (block) {
            NSString *domain = @"com.KPAppInstall.ErrorDomain";
            NSString *desc = @"复制IPA文件失败  检查要安装的IPA路径是否正确!";
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            NSError *error = [NSError errorWithDomain:domain
                                                     code:-101
                                                 userInfo:userInfo];
            block(nil, false, error);
        }
        return;
    }
    
    NSString* temp = [NSTemporaryDirectory() stringByAppendingPathComponent:[@"Temp" stringByAppendingString:ipaPath.lastPathComponent]];
    if (![[NSFileManager defaultManager] copyItemAtPath:ipaPath toPath:temp error:nil]) {
        if (block) {
            NSString *domain = @"com.KPAppInstall.ErrorDomain";
            NSString *desc = @"复制IPA文件失败  检查要安装的IPA路径是否正确!";
            NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
            NSError *error = [NSError errorWithDomain:domain
                                                     code:-101
                                                 userInfo:userInfo];
            block(nil, false, error);
        }
    }
    
    if (temp.length <= 0) { return; }

    [self installAppWithIpaPathURL:[NSURL fileURLWithPath:temp]  block:block];
}

+ (void)installAppWithIpaPathURL:(NSURL *)ipaPath block:(void(^)(NSArray<NSDictionary *> *progressList, BOOL isCompletion, NSError *error))block {
    LSApplicationWorkspace *appWorkspace = [LSApplicationWorkspace defaultWorkspace];
  
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error = NULL;
        __block NSMutableArray *tempArr = @[].mutableCopy;
        [appWorkspace installApplication:ipaPath withOptions:nil error:&error usingBlock:^(NSDictionary *progress, void *unknow) {
#if DEBUG
//            NSLog(@"installApplication time:%d   progress: %@", CFAbsoluteTimeGetCurrent() , progress);
#endif
            [tempArr addObject:progress];
            if ([progress[@"PercentComplete"] intValue] >= 90) {
                if (block) {
                    block(tempArr, false, nil);
                }
                /// 系统返回的进度只有90% 先延迟5s 后期看情况调整
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSDictionary *dic = @{
                        @"PercentComplete": @100,
                        @"Status": @"Complete",
                    };
                    [tempArr addObject:dic];
                    if (block) {
                        block(tempArr, true, nil);
                    }
                    /// 删
                    [[NSFileManager defaultManager] removeItemAtPath:ipaPath error:nil];
                });
            } else {
                if (block) {
                    block(tempArr, false, nil);
                }
            }
        }];
        if (error) {
            block(nil, false, error);
        }
    });
   
}

+ (void)installAppWithRemoteURL:(NSString *)url downloadProgress:(void (^)(NSProgress *downloadProgress))downloadProgress completion:(void(^)(NSArray<NSDictionary *> *progressList, BOOL isCompletion, NSError *error))block {
    dispatch_async(KPAppToolInstance.executionQueue, ^{
        [[KPHTTPManager downloadManager] downloadFile:url progress:downloadProgress completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nonnull filePath, NSError * _Nonnull error) {
            if (error) {
                block(nil, false, error);
                return;
            }
            [KPAppTool installAppWithIpaPathURL:filePath block:block];
        }];
    });
   
}

+ (bool)openApplicationWithBundleID:(NSString *)bundleId {
    LSApplicationWorkspace *appWorkspace = [LSApplicationWorkspace defaultWorkspace];
    return [appWorkspace openApplicationWithBundleID:bundleId?: KPAppToolInstance.bundleId];
}

+ (bool)uninstallApplication:(NSString *)bundleId {
    LSApplicationWorkspace *appWorkspace = [LSApplicationWorkspace defaultWorkspace];
    return [appWorkspace uninstallApplication:bundleId?: KPAppToolInstance.bundleId withOptions:nil];
}


/// LSApplicationProxy
+ (LSApplicationProxy *)applicationProxy:(NSString *)bundleId {
    NSArray<LSApplicationProxy *> *aps = [[LSApplicationWorkspace defaultWorkspace] allInstalledApplications];
    for (LSApplicationProxy *proxy in aps) {
        if ([proxy.bundleIdentifier isEqualToString: bundleId?: KPAppToolInstance.bundleId]) {
            return proxy;
        }
    }
    return nil;
}

- (void)registerIPCNotfication:(NSString *)notifyName {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &NotificationReceivedCallBack, (__bridge CFStringRef)notifyName, NULL, CFNotificationSuspensionBehaviorCoalesce);
}

- (void)registerIPCNotfication:(NSString *)notifyName callBack:(KPNotifcationHanlderType)callBack {
    self.notifiHandlers[notifyName] = callBack;
    [self registerIPCNotfication:notifyName];
}

- (uint32_t)postIPCNoftication:(NSString *)notifyName {
    return notify_post(notifyName.UTF8String);
}

- (void)pingTimeSecond:(int)second callBack:(dispatch_block_t)callBack{
    if (self.timer) {
        dispatch_source_cancel(self.timer);
        self.timer = nil;
    }
    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_queue_create("kp.xm.installerQueue", NULL));
    dispatch_source_set_timer(_timer, DISPATCH_TIME_NOW, second * NSEC_PER_SEC, 1 * NSEC_PER_SEC);
    dispatch_source_set_event_handler(_timer, ^{
        [self postIPCNoftication:@"kp.xm.ping"];
        if (callBack) {
            callBack();
        }
    });
    dispatch_resume(_timer);
}

/// 接收方 接收到ping 后续动作
- (void)recevicePingCallBack:(KPNotifcationHanlderType)callBack {
    [self registerIPCNotfication:@"kp.xm.ping" callBack:callBack];
}

///MARK: - App下载相关
+ (void)clearDownloadFiles {
    NSString *path = kp_directoryFor(@"DownloadFiles");
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

+ (NSURL *)fileUrlWithRemoteUrl:(NSString *)URLString  suggestedFilename:(NSString *)suggestedFilename{
    NSString *path = kp_directoryFor(@"DownloadFiles");
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", kp_md5WithString(URLString), suggestedFilename];
    return [[NSURL fileURLWithPath:path] URLByAppendingPathComponent:fileName];
}
/// 断点下载的resumeData
+ (NSString *)resumeDataFilePathWithKey:(NSString *)key {
    NSString *path = kp_directoryFor(@"ResumeDataFiles");
    NSString *fileName = [NSString stringWithFormat:@"%@", kp_md5WithString(key)];
    return [path stringByAppendingPathComponent:fileName];
}

+ (void)clearResumeDataFiles {
    NSString *path = kp_directoryFor(@"ResumeDataFiles");
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}

+ (void)clearResumeDataWithKey:(NSString *)key {
    NSString *path = [self resumeDataFilePathWithKey:key];
    [[NSFileManager defaultManager] removeItemAtPath:path error:NULL];
}


//MARK:- MobileGestalt
/// 设备UDID
+ (NSString *)UDID {
    return [self mgCopyAnserForKey:@"UniqueDeviceID"];
}

+ (BOOL)isChina {
    return [[self mgCopyAnserForKey:@"RegionCode"] isEqualToString:@"CH"];
}

+ (id)mgCopyAnserForKey:(NSString *)key {
    void *gestalt = dlopen("/usr/lib/libMobileGestalt.dylib", RTLD_GLOBAL | RTLD_LAZY);
    CFStringRef (*MGCopyAnswer)(CFStringRef, CFDictionaryRef) = (CFStringRef (*)(CFStringRef))(dlsym(gestalt, "MGCopyAnswer"));
    CFDictionaryRef dic = (__bridge CFDictionaryRef)@{};
    // 31e4aaa6dc7c2eee88eff852bae785c4f97260c1
    // 31E4AAA6DC7C2EEE88EFF852BAE785C4F97260C1
    CFStringRef r1 = MGCopyAnswer((__bridge CFStringRef)(key), dic);
    return (__bridge  NSString *)r1;
}

+ (NSDictionary *)deviceInfo {
    NSArray *list = @[
     @"DiskUsage",
     @"ModelNumber",
     @"SIMTrayStatus",
     @"SerialNumber",
     @"MLBSerialNumber",
     @"UniqueDeviceID",
     @"UniqueDeviceIDData",
     @"UniqueChipID",
     @"InverseDeviceID",
     @"DiagData",
     @"DieId",
     @"CPUArchitecture",
     @"PartitionType",
     @"UserAssignedDeviceName",
     @"BluetoothAddress",
     @"RequiredBatteryLevelForSoftwareUpdate",
     @"BatteryIsFullyCharged",
     @"BatteryIsCharging",
     @"BatteryCurrentCapacity",
     @"ExternalPowerSourceConnected",
     @"BasebandSerialNumber",
     @"BasebandCertId",
     @"BasebandChipId",
     @"BasebandFirmwareManifestData",
     @"BasebandFirmwareVersion",
     @"BasebandKeyHashInformation",
     @"CarrierBundleInfoArray",
     @"CarrierInstallCapability",
     @"InternationalMobileEquipmentIdentity",
     @"MobileSubscriberCountryCode",
     @"MobileSubscriberNetworkCode",
     @"ChipID",
     @"ComputerName",
     @"DeviceVariant",
     @"HWModelStr",
     @"BoardId",
     @"HardwarePlatform",
     @"DeviceName",
     @"DeviceColor",
     @"DeviceClassNumber",
     @"DeviceClass",
     @"BuildVersion",
     @"ProductName",
     @"ProductType",
     @"ProductVersion",
     @"FirmwareNonce",
     @"FirmwareVersion",
     @"FirmwarePreflightInfo",
     @"IntegratedCircuitCardIdentifier",
     @"AirplaneMode",
     @"AllowYouTube",
     @"AllowYouTubePlugin",
     @"MinimumSupportediTunesVersion",
     @"ProximitySensorCalibration",
     @"RegionCode",
     @"RegionInfo",
     @"RegulatoryIdentifiers",
     @"SBAllowSensitiveUI",
     @"SBCanForceDebuggingInfo",
     @"SDIOManufacturerTuple",
     @"SDIOProductInfo",
     @"ShouldHactivate",
     @"SigningFuse",
     @"SoftwareBehavior",
     @"SoftwareBundleVersion",
     @"SupportedDeviceFamilies",
     @"SupportedKeyboards",
     @"TotalSystemAvailable",
     @"AllDeviceCapabilities",
     @"AppleInternalInstallCapability",
     @"ExternalChargeCapability",
     @"ForwardCameraCapability",
     @"PanoramaCameraCapability",
     @"RearCameraCapability",
     @"HasAllFeaturesCapability",
     @"HasBaseband",
     @"HasInternalSettingsBundle",
     @"HasSpringBoard",
     @"InternalBuild",
     @"IsSimulator",
     @"IsThereEnoughBatteryLevelForSoftwareUpdate",
     @"IsUIBuild",
     @"RegionalBehaviorAll",
     @"RegionalBehaviorChinaBrick",
     @"RegionalBehaviorEUVolumeLimit",
     @"RegionalBehaviorGB18030",
     @"RegionalBehaviorGoogleMail",
     @"RegionalBehaviorNTSC",
     @"RegionalBehaviorNoPasscodeLocationTiles",
     @"RegionalBehaviorNoVOIP",
     @"RegionalBehaviorNoWiFi",
     @"RegionalBehaviorShutterClick",
     @"RegionalBehaviorVolumeLimit",
     @"ActiveWirelessTechnology",
     @"WifiAddress",
     @"WifiAddressData",
     @"WifiVendor",
     @"FaceTimeBitRate2G",
     @"FaceTimeBitRate3G",
     @"FaceTimeBitRateLTE",
     @"FaceTimeBitRateWiFi",
     @"FaceTimeDecodings",
     @"FaceTimeEncodings",
     @"FaceTimePreferredDecoding",
     @"FaceTimePreferredEncoding",
     @"DeviceSupportsFaceTime",
     @"DeviceSupportsTethering",
     @"DeviceSupportsSimplisticRoadMesh",
     @"DeviceSupportsNavigation",
     @"DeviceSupportsLineIn",
     @"DeviceSupports9Pin",
     @"DeviceSupports720p",
     @"DeviceSupports4G",
     @"DeviceSupports3DMaps",
     @"DeviceSupports3DImagery",
     @"DeviceSupports1080p",
    ];
    
    NSMutableDictionary *dic = @{}.mutableCopy;
    for (NSString *item in list) {
       NSString *result =  [KPAppTool mgCopyAnserForKey:item];
        dic[item] = result;
    }
    return dic;
}
@end


