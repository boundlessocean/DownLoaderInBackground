//
//  ViewController.m
//  BackgroundDownloadDemo
//
//  Created by HK on 16/9/10.
//  Copyright © 2016年 hkhust. All rights reserved.
//

#import "ViewController.h"
#import "BLDownlowdHanlder.h"
#import "AppDelegate.h"
@interface ViewController ()

@property (strong, nonatomic) IBOutlet UIProgressView *downloadProgress;
@property (weak, nonatomic) IBOutlet UILabel *progressLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateDownloadProgress:) name:kDownloadProgressNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)updateDownloadProgress:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    CGFloat fProgress = [userInfo[@"progress"] floatValue];
    self.progressLabel.text = [NSString stringWithFormat:@"%.2f%%",fProgress * 100];
    self.downloadProgress.progress = fProgress;
    if (fProgress >= 1) {
        dispatch_async(dispatch_get_main_queue(), ^{
            UILocalNotification *localNotification = [[UILocalNotification alloc] init];
            localNotification.fireDate = [[NSDate date] dateByAddingTimeInterval:5];
            localNotification.alertAction = nil;
            localNotification.soundName = UILocalNotificationDefaultSoundName;
            localNotification.alertBody = @"下载完成了！";
            localNotification.applicationIconBadgeNumber = 1;
            localNotification.repeatInterval = 0;
            [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
        });
    }
}

#pragma mark Method
- (IBAction)download:(id)sender {
    NSString *urlString = @"http://sw.bos.baidu.com/sw-search-sp/software/797b4439e2551/QQ_mac_5.0.2.dmg";
    [[BLDownlowdHanlder shareHandler] downloadWithUrl:urlString
                                          destination:^NSString *(NSURL *targetPath,
                                                               NSURLResponse *response)
    {
      NSString *fileURLString = [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory , NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:[NSString stringWithFormat:@"file%@.dmg",[NSUUID UUID]]];
      return fileURLString;
        
    }
                                             progress:^(CGFloat downloadProgress)
    {
        self.progressLabel.text = [NSString stringWithFormat:@"%.2f%%",downloadProgress * 100];
        self.downloadProgress.progress = downloadProgress;
    }
                                    completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error)
    {
        NSLog(@"%@,%@,%@",response,filePath,error);
    }];
}

- (IBAction)pauseDownlaod:(id)sender {
    [[BLDownlowdHanlder shareHandler] pauseDownload];
}

- (IBAction)continueDownlaod:(id)sender {
    [[BLDownlowdHanlder shareHandler] continueDownload];
}


@end
