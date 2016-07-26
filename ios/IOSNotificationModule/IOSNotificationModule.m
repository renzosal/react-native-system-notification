//
//  IOSNotificationModule.m
//  IOSNotificationModule
//
//  Created by Renzo Saldana on 7/20/16.
//  Copyright © 2016 Renzo Saldana. All rights reserved.
//

#import "IOSNotificationModule.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTEventDispatcher.h"
#import "RCTUtils.h"

#if __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_8_0

#define UIUserNotificationTypeAlert UIRemoteNotificationTypeAlert
#define UIUserNotificationTypeBadge UIRemoteNotificationTypeBadge
#define UIUserNotificationTypeSound UIRemoteNotificationTypeSound
#define UIUserNotificationTypeNone  UIRemoteNotificationTypeNone
#define UIUserNotificationType      UIRemoteNotificationType

#endif

NSString *const RCTLocalNotificationReceived = @"LocalNotificationReceived";
NSString *const RCTRemoteNotificationReceived = @"RemoteNotificationReceived";
NSString *const RCTRemoteNotificationsRegistered = @"RemoteNotificationsRegistered";

@implementation RCTConvert (UILocalNotification)

+ (UILocalNotification *)UILocalNotification:(id)json
{
    NSDictionary<NSString *, id> *details = [self NSDictionary:json];
    UILocalNotification *notification = [UILocalNotification new];
    notification.fireDate = [RCTConvert NSDate:details[@"fireDate"]] ?: [NSDate date];
    notification.alertBody = [RCTConvert NSString:details[@"alertBody"]];
    notification.alertAction = [RCTConvert NSString:details[@"alertAction"]];
    notification.soundName = [RCTConvert NSString:details[@"soundName"]] ?: UILocalNotificationDefaultSoundName;
    notification.userInfo = [RCTConvert NSDictionary:details[@"userInfo"]];
    notification.category = [RCTConvert NSString:details[@"category"]];
    if (details[@"applicationIconBadgeNumber"]) {
        notification.applicationIconBadgeNumber = [RCTConvert NSInteger:details[@"applicationIconBadgeNumber"]];
    }
    return notification;
}

@end

@implementation IOSNotificationModule

RCT_EXPORT_MODULE()

@synthesize bridge = _bridge;

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (instancetype)init
{
    // We're only overriding this to ensure the module gets created at startup
    // TODO (t11106126): Remove once we have more declarative control over module setup.
    return [super init];
}


- (void)setBridge:(RCTBridge *)bridge
{
    _bridge = bridge;
    
    // TODO: if we add an explicit "startObserving" method, we can take this out
    // of the application startup path
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleLocalNotificationReceived:)
                                                 name:RCTLocalNotificationReceived
                                               object:nil];
}


+ (void)didRegisterUserNotificationSettings:(__unused UIUserNotificationSettings *)notificationSettings
{
    if ([UIApplication instancesRespondToSelector:@selector(registerForRemoteNotifications)]) {
        [[UIApplication sharedApplication] registerForRemoteNotifications];
    }
}


+ (void)didReceiveLocalNotification:(UILocalNotification *)notification
{
    NSMutableDictionary *details = [NSMutableDictionary new];
    if (notification.alertBody) {
        details[@"alertBody"] = notification.alertBody;
    }
    if (notification.userInfo) {
        details[@"userInfo"] = RCTJSONClean(notification.userInfo);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTLocalNotificationReceived
                                                        object:self
                                                      userInfo:details];
}


- (void)handleLocalNotificationReceived:(NSNotification *)notification
{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_bridge.eventDispatcher sendDeviceEventWithName:@"localNotificationReceived"
                                                body:notification.userInfo];
#pragma clang diagnostic pop
}


RCT_EXPORT_METHOD(presentLocalNotification:(UILocalNotification *)notification)
{
    [RCTSharedApplication() presentLocalNotificationNow:notification];
}

RCT_EXPORT_METHOD(scheduleLocalNotification:(UILocalNotification *)notification)
{
    [RCTSharedApplication() scheduleLocalNotification:notification];
}

RCT_EXPORT_METHOD(cancelAllLocalNotifications)
{
    [RCTSharedApplication() cancelAllLocalNotifications];
}

RCT_EXPORT_METHOD(cancelLocalNotifications:(NSDictionary *)userInfo)
{
    for (UILocalNotification *notification in [UIApplication sharedApplication].scheduledLocalNotifications) {
        __block BOOL matchesAll = YES;
        NSDictionary *notificationInfo = notification.userInfo;
        [userInfo enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
            if (![notificationInfo[key] isEqual:obj]) {
                matchesAll = NO;
                *stop = YES;
            }
        }];
        if (matchesAll) {
            [[UIApplication sharedApplication] cancelLocalNotification:notification];
        }
    }
}

@end
