//
//  ViewController.m
//  NSURLSession
//
//  Created by wangjianwei on 15/10/24.
//  Copyright © 2015年 JW. All rights reserved.
//

#import "ViewController.h"
#define JWLog(xx, ...)  NSLog(@"%s(%d): " xx, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__)
@interface ViewController ()<NSURLSessionDownloadDelegate>

@property (nonatomic,strong) NSURLSession   *session;
@property (weak, nonatomic) IBOutlet UIProgressView *progresss;

@property (nonatomic,strong) NSURLSessionDownloadTask *downloadTask;

@property (nonatomic,strong) NSData *recievedData;

@end
/**
 * 存在的问题： 
 * 1. 暂停时候存在内存峰值：
 *---因为保存了暂停时候已经接受到的数据
 *---因为在下载结束时候还要一次性将所有在tmp中的数据导入内存，然后转存到别的地方。
 *---所以下载大文件对NSURLSessionDownloadTask 来讲是不合适的。
 * 2. 存在循环引用问题
 *---session 对delegate 进行了retain ，而不是weak
 *---解决办法： 不是在下载结束的时候对self.session进行nil，而是对其进行invalidateAndCancel 或者是finishAndCancel 操作，取消session中管理的任务，然后系统将会自动对session进行回收
 */
@implementation ViewController

-(void)dealloc{
    NSLog(@"888");
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.progresss.progress = 0;
}

-(void)downSession{
    NSString *urlStr = [NSString stringWithFormat:@"http://127.0.0.1/01-知识点回顾.mp4"];
    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    NSLog(@"%@",urlStr);
    
    NSURL *url = [NSURL URLWithString:urlStr];
    [[[NSURLSession sharedSession]downloadTaskWithURL:url completionHandler:^(NSURL * _Nullable location, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if ( error != nil) {
            NSLog(@"error:%@",error);
        }
        NSLog(@"%@",[NSThread currentThread]);
        NSLog(@"%@",[NSSearchPathForDirectoriesInDomains(NSCachesDirectory,NSUserDomainMask , YES)lastObject]);
        
        NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)lastObject];
        NSString *path = [cacheDir stringByAppendingPathComponent:@"3124.mp4"];
        NSData *data = [NSData dataWithContentsOfURL:location];
        [data writeToFile:path atomically:YES];
    }]resume];
}
-(void)getSession{
    NSString *urlStr = [NSString stringWithFormat:@"http://127.0.0.1/demo.json"];
    
    urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
    
    NSURL *url = [NSURL URLWithString:urlStr];
    [[[NSURLSession sharedSession]dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (data.length == 0 || error != nil) {
            NSLog(@"网络故障，请稍后重试");
        }
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
        NSLog(@"%@",dic);
        
    }] resume];
}

#pragma mark -- Download by Delegate
-(NSURLSession *)session{
    if (_session == nil) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:nil];
    }
    return  _session;
}
- (IBAction)suspend:(id)sender {
    [self.downloadTask cancelByProducingResumeData:^(NSData * _Nullable resumeData) {
        self.recievedData = resumeData;
    }];
    self.downloadTask = nil;
}
- (IBAction)resume:(id)sender {
    
    if (self.recievedData != nil ) {
        self.downloadTask = [self.session downloadTaskWithResumeData:self.recievedData];
        [self.downloadTask resume];
        self.recievedData = nil;
    }
}

-(IBAction)start{
    if (self.recievedData == nil && self.downloadTask == nil) {
        NSString *urlStr = [NSString stringWithFormat:@"http://127.0.0.1/01-知识点回顾.mp4"];
        
        urlStr = [urlStr stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
        NSLog(@"%@",urlStr);
        
        NSURL *url = [NSURL URLWithString:urlStr];
        self.downloadTask = [self.session downloadTaskWithURL:url];
        [self.downloadTask resume];
        
    }else [self resume:nil];
}
#pragma mark - NSURLSessionDownloadDelegate
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location{
    JWLog(@"完成下载");
    self.session = nil;
    self.downloadTask = nil;
    self.recievedData = nil;
    NSString *cacheDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject];
    JWLog(@"%@",cacheDir);
    NSString *filePath =  [cacheDir stringByAppendingPathComponent:@"afda.mp4"];
    @autoreleasepool {
        [[NSData dataWithContentsOfURL:location]writeToFile:filePath atomically:YES];
    }
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite{
    float progress = (float)totalBytesWritten/totalBytesExpectedToWrite;
    JWLog(@"%f",progress);
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progresss.progress = progress;
    });
}
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes{
    JWLog();
}
@end
