//
//  AppDelegate.m
//  BackgroundDownloadDemo
//
//  Created by HK on 16/9/10.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import "AppDelegate.h"
#import "BLDownlowdHanlder.h"
@interface AppDelegate () 

typedef void(^CompletionHandlerType)(void);

@property (strong, nonatomic) NSMutableDictionary *completionHandlerDictionary;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    self.completionHandlerDictionary = @{}.mutableCopy;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskFinishhandle:) name:@"kNotifacationNameDownloadTaskFinished" object:nil];
   
    // ios8后，需要添加这个注册，才能得到授权
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(registerUserNotificationSettings:)]) {
        UIUserNotificationType type =  UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound;
        UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:type
                                                                                 categories:nil];
        [[UIApplication sharedApplication] registerUserNotificationSettings:settings];
    }
    
    UILocalNotification *localNotification = [launchOptions valueForKey:UIApplicationLaunchOptionsLocalNotificationKey];
    if (localNotification) {
        [self application:application didReceiveLocalNotification:localNotification];
    }
    return YES;
}
- (void)application:(UIApplication *)application
handleEventsForBackgroundURLSession:(NSString *)identifier
  completionHandler:(void (^)(void))completionHandler{
    // 你必须重新建立一个后台 seesion ，系统会自动与创建的session关联
    [[BLDownlowdHanlder shareHandler] initBackgroundSessionWithId:identifier];
    
    // 保存 completion handler 以在处理 session 事件后更新 UI
    [self.completionHandlerDictionary setObject:completionHandler forKey:identifier];
}


- (void)taskFinishhandle:(NSNotification *)notification{
    NSString *identifier = notification.object;
    CompletionHandlerType handler = [self.completionHandlerDictionary objectForKey:identifier];
    if (handler) {
        [self.completionHandlerDictionary removeObjectForKey: identifier];
        handler();
    }
}


#pragma mark - Local Notification
- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    [[UIApplication sharedApplication] cancelAllLocalNotifications];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"下载通知"
                                                    message:notification.alertBody
                                                   delegate:nil
                                          cancelButtonTitle:@"确定"
                                          otherButtonTitles:nil];
    [alert show];
    
    // 图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // 图标上的数字减1
    application.applicationIconBadgeNumber -= 1;
}


@end
