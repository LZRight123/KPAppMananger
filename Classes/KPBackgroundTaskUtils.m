//
//  KPBackgroundTaskUtils.m
//  weworkhelperDylib
//
//

#import "KPBackgroundTaskUtils.h"
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>

@interface KPBackgroundTaskUtils ()
@property (nonatomic, assign) UIBackgroundTaskIdentifier backgrounTask;
@property (nonatomic,strong) NSTimer *timer;
@end
@implementation KPBackgroundTaskUtils{
    AVAudioPlayer *player;
}
static KPBackgroundTaskUtils * backgroundTask = nil;
+(instancetype)sharedInstance {
    static dispatch_once_t onceTokenplayer;
    dispatch_once(&onceTokenplayer, ^{
        backgroundTask = [KPBackgroundTaskUtils new];
    });
    return backgroundTask;
}
-(void)playNoVoliceBackgroundTask{
    NSBundle *b = [NSBundle bundleWithPath: [NSString stringWithFormat:@"%@/KPAppMananger.bundle", NSBundle.mainBundle.bundlePath]];
    NSURL *urlSound = [[NSURL alloc]initWithString:[b pathForResource:@"noVoice" ofType:@"mp3"]];
    [self playNoVoliceBackgroundTaskResourceUrl:urlSound];
}

-(void)playNoVoliceBackgroundTaskResourceUrl:(NSURL *)fileUrl{
    //设置后台模式和锁屏模式下依然能够播放
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:nil];
    [[AVAudioSession sharedInstance] setActive: YES error: nil];
    
    //初始化音频播放器
    NSError *playerError;
    AVAudioPlayer *playerSound = [[AVAudioPlayer alloc] initWithContentsOfURL:fileUrl error:&playerError];
    playerSound.numberOfLoops = -1;//无限播放
    player = playerSound;
    [player play];
}

-(void)applicationDidEnterBackgroundTask:(UIApplication *)launchOptions{
    [self backgroundMode];
}
-(void)backgroundMode{
    //创建一个背景任务去和系统请求后台运行的时间
    self.backgrounTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self.backgrounTask];
        self.backgrounTask = UIBackgroundTaskInvalid;
    }];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:10.0 target:self selector:@selector(applyToSystemForMoreTime) userInfo:nil repeats:YES];
    [self.timer fire];
}

- (void)applyToSystemForMoreTime {
    if ([UIApplication sharedApplication].backgroundTimeRemaining < 30.0) {//如果剩余时间小于30秒
        [[UIApplication sharedApplication] endBackgroundTask:self.self.backgrounTask];
        self.backgrounTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
            [[UIApplication sharedApplication] endBackgroundTask:self.self.backgrounTask];
            self.self.backgrounTask = UIBackgroundTaskInvalid;
        }];
    }
}
@end
