//
//  KPBackgroundTaskUtils.h
//  weworkhelperDylib
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
NS_ASSUME_NONNULL_BEGIN

@interface KPBackgroundTaskUtils : NSObject<UIApplicationDelegate>
+(instancetype)sharedInstance;
/// 默认播放静音.mp3
-(void)playNoVoliceBackgroundTask;
-(void)playNoVoliceBackgroundTaskResourceUrl:(NSURL *)fileUrl;
-(void)applicationDidEnterBackgroundTask:(UIApplication *)launchOptions;
@end

NS_ASSUME_NONNULL_END
