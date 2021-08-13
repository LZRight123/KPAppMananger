//
//  KPConst.h
//  KPAppInstall
//
//  Created by 梁泽 on 2021/7/6.
//

#import <Foundation/Foundation.h>


// 弱引用
#define KPWeakSelf __weak typeof(self) weakSelf = self;

/// 安装器service端口
FOUNDATION_EXPORT const int k_KPAppManangerServicePort;


/// xxservice端口
FOUNDATION_EXPORT const int k_xxServicePort;

/// 要获取其它app信息的事件类型
typedef NS_ENUM(NSUInteger, KPEventType) {
    KPEventType_0x01 = 1,
    KPEventType_0x02 = 2,
    KPEventType_0x03 = 3,
    KPEventType_0x04 = 4,
    KPEventType_0x05 = 5,
    KPEventType_0x06 = 6,
    KPEventType_0x07 = 7,
    KPEventType_0x08 = 8,
    KPEventType_0x09 = 9,
    KPEventType_0x10 = 10,
    KPEventType_0x0A = 11,
    KPEventType_0x0B = 12,
    KPEventType_0x0C = 13,
    KPEventType_0x0D = 14,
    KPEventType_0x0E = 15,
    KPEventType_0x0F = 16,
};

