//
//  IOSNotificationModule.h
//  IOSNotificationModule
//
//  Created by Renzo Saldana on 7/20/16.
//  Copyright © 2016 Renzo Saldana. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "RCTBridgeModule.h"

@interface IOSNotificationModule : NSObject <RCTBridgeModule>

+ (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings;
+ (void)didReceiveLocalNotification:(UILocalNotification *)notification;

@end
