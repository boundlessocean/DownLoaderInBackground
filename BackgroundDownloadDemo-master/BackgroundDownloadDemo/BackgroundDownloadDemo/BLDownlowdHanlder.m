//
//  BLDownlowdHanlder.m
//  BackgroundDownloadDemo
//
//  Created by boundlessocean on 2017/9/21.
//  Copyright © 2017年 hkhust. All rights reserved.
//

#import "BLDownlowdHanlder.h"
#import "NSURLSession+CorrectedResumeData.h"
#define IS_IOS10ORLATER ([[[UIDevice currentDevice] systemVersion] floatValue] >= 10)

@interface BLDownlowdHanlder()<NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (strong, nonatomic) NSURLSession *backgroundSession;
@property (strong, nonatomic) NSData *resumeData;

/** 下载进度回调 */
@property(nonatomic,copy) void (^progressBlock)(CGFloat downloadProgress);
/** 下载完成回调 */
@property(nonatomic,copy) void (^completehander)(NSURLResponse *respone, NSURL *fileURL, NSError *error);
/** 获取最终路径 */
@property(nonatomic,copy) NSString *(^destination)(NSURL *targetPath, NSURLResponse *response);



@end

@implementation BLDownlowdHanlder

+ (instancetype)shareHandler{
    static BLDownlowdHanlder * handler;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        handler = [[BLDownlowdHanlder alloc] init];
    });
    return handler;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        self.backgroundSession = [self backgroundURLSessionWithID:@"xxxxxxxx"];
    }
    return self;
}

- (void)initBackgroundSessionWithId:(NSString *)identifier{
    
    self.backgroundSession = [self backgroundURLSessionWithID:identifier];
}


#pragma mark - - public
// 开始下载
- (void)downloadWithUrl:(NSString *)URLString
            destination:(NSString * (^)(NSURL *targetPath, NSURLResponse *response))destination
               progress:(void (^)(CGFloat downloadProgress)) downloadProgressBlock
      completionHandler:(void (^)(NSURLResponse *response,NSURL *filePath,NSError *error))completionHandler
{
    _progressBlock = downloadProgressBlock;
    _completehander = completionHandler;
    _destination = destination;
    
    NSURL *downloadURL = [NSURL URLWithString:URLString];
    NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
    self.downloadTask = [self.backgroundSession downloadTaskWithRequest:request];
    
    switch (self.downloadTask.state) {
        case NSURLSessionTaskStateRunning:
            [self showAlert];
            break;
        case NSURLSessionTaskStateSuspended:
        case NSURLSessionTaskStateCanceling:
        case NSURLSessionTaskStateCompleted:
            [self.downloadTask resume];
            break;
        default:
            break;
    }
}

// 暂停下载
- (void)pauseDownload {
    __weak __typeof(self) wSelf = self;
    [self.downloadTask cancelByProducingResumeData:^(NSData * resumeData) {
        __strong __typeof(wSelf) sSelf = wSelf;
        sSelf.resumeData = resumeData;
    }];
}

// 继续下载
- (void)continueDownload {
    if (self.resumeData) {
        if (IS_IOS10ORLATER) {
            self.downloadTask = [self.backgroundSession downloadTaskWithCorrectResumeData:self.resumeData];
        } else {
            self.downloadTask = [self.backgroundSession downloadTaskWithResumeData:self.resumeData];
        }
        [self.downloadTask resume];
        self.resumeData = nil;
    }
}

#pragma mark - private
    
- (void)showAlert{
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil
                                                    message:@"正在下载任务..."
                                                   delegate:nil
                                          cancelButtonTitle:@"取消"
                                          otherButtonTitles: nil];
    [alert show];
}

#pragma mark - backgroundURLSession

- (NSURLSession *)backgroundURLSessionWithID:(NSString *)identifier {
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:identifier];

        session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                delegate:self
                                           delegateQueue:nil];
    });
    
    return session;
}


#pragma mark - - NSURLSessionDownloadDelegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location {
    
    NSString *locationString = [location path];
    NSError *error;
    NSString *finalURL = _destination(location,downloadTask.response);
    [[NSFileManager defaultManager] moveItemAtPath:locationString
                                            toPath:finalURL
                                             error:&error];
    !_completehander ? : _completehander(downloadTask.response, [NSURL URLWithString:finalURL], nil);\
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kNotifacationNameDownloadTaskFinished" object:session.configuration.identifier];
}



- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    
    CGFloat progress = (CGFloat)totalBytesWritten / totalBytesExpectedToWrite;
    !_progressBlock ? : _progressBlock(progress);
}

/*
 * 该方法下载成功和失败都会回调，只是失败的是error是有值的，
 * 在下载失败时，error的userinfo属性可以通过NSURLSessionDownloadTaskResumeData
 * 这个key来取到resumeData(和上面的resumeData是一样的)，再通过resumeData恢复下载
 */
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error {
    if (error) {
        
        // check if resume data are available
        if ([error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData]) {
            NSData *resumeData = [error.userInfo objectForKey:NSURLSessionDownloadTaskResumeData];
            //通过之前保存的resumeData，获取断点的NSURLSessionTask，调用resume恢复下载
            self.resumeData = resumeData;
            // 判断是否是因为进程被杀掉，如果是继续下载
            if ([error.userInfo.allKeys containsObject:NSURLErrorBackgroundTaskCancelledReasonKey]) {
                [self continueDownload];
            } else if ([error.userInfo[@"NSLocalizedDescription"] isEqualToString:@"cancelled"]){
            } else {
                !_completehander ? : _completehander(task.response, nil, error);
            }
        }
    } else {
        
    }
}


@end
