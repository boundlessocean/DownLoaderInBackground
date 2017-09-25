//
//  BLDownlowdHanlder.h
//  BackgroundDownloadDemo
//
//  Created by boundlessocean on 2017/9/21.
//  Copyright © 2017年 hkhust. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BLDownlowdHanlder : NSObject
+ (instancetype)shareHandler;
// 开始下载
- (void)downloadWithUrl:(NSString *)URLString
            destination:(NSString * (^)(NSURL *targetPath, NSURLResponse *response))destination
               progress:(void (^)(CGFloat downloadProgress)) downloadProgressBlock
      completionHandler:(void (^)(NSURLResponse *response,NSURL *filePath,NSError *error))completionHandler;

- (void)pauseDownload;
- (void)continueDownload;
- (void)initBackgroundSessionWithId:(NSString *)identifier;
@end
