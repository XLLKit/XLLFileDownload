//
//  XLLFileDownload.m
//  XLLFile
//
//  Created by 肖乐 on 2018/4/19.
//  Copyright © 2018年 iOSCoder. All rights reserved.
//  文件断点下载

#import "XLLFileDownload.h"
#import <pthread.h>

//文件存放目录名称
#define LastPath(fileUrl) [NSString stringWithFormat:@"%@", fileUrl]
//文件存储仓库
#define XLLCacheDirectory [[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"XLL_Files"]
//文件目录全路径
#define FileloadDirectory(fileUrl) [XLLCacheDirectory stringByAppendingPathComponent:LastPath(fileUrl)]
//文件全路径
#define FileFullpath(fileUrl, fileName) [FileloadDirectory(fileUrl) stringByAppendingPathComponent:fileName]

//存储下载文件信息plist文件存储仓库
#define XLLPlistCacheDirectory [[NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject] stringByAppendingPathComponent:@"XLL_Plist_Files"]
//存储下载文件信息plist文件目录全路径
#define PlistFileloadDirectory(fileUrl) [XLLPlistCacheDirectory stringByAppendingPathComponent:LastPath(fileUrl)]
//存储下载文件信息plist文件全路径
#define TotalLengthFullpath(fileUrl) [PlistFileloadDirectory(fileUrl) stringByAppendingPathComponent:@"totalLength.plist"]

@implementation XLLDownloadTaskItem

@end

@interface XLLFileDownload () <NSURLSessionDelegate>
{
    pthread_mutex_t _pthread;
}

//任务字典
@property (nonatomic, strong) NSMutableDictionary <NSString *, XLLDownloadTaskItem *>*tasks;

@end

@implementation XLLFileDownload
static XLLFileDownload *instance_ = nil;

#pragma mark - lazy loading
- (NSMutableDictionary *)tasks
{
    if (_tasks == nil)
    {
        _tasks = [NSMutableDictionary dictionary];
    }
    return _tasks;
}

- (instancetype)init
{
    if (self = [super init])
    {
        //初始化线程互斥锁🔐
        pthread_mutex_init(&_pthread, NULL);
        self.maximumTaskCount = 10;
    }
    return self;
}

+ (instancetype)sharedDownloadInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance_ = [[[self class] alloc] init];
        //创建文件存储仓库
        [instance_ createCacheRepertory];
    });
    return instance_;
}

- (void)createCacheRepertory
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:XLLCacheDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:XLLCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
    if (![[NSFileManager defaultManager] fileExistsAtPath:XLLPlistCacheDirectory])
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:XLLPlistCacheDirectory withIntermediateDirectories:YES attributes:nil error:NULL];
    }
}

//开始下载
- (void)download:(NSString *)fileUrl fileName:(NSString *)fileName progress:(void (^)(CGFloat))progress state:(void (^)(XLLDownloadState))state
{
    //如果已经下载完成直接回调
    if ([self downloadState:fileUrl fileName:fileName] == XLLDownloadStateCompleted)
    {
        if (state) {
            state(XLLDownloadStateCompleted);
        }
        return;
    }
    if ([self.tasks valueForKey:fileUrl])
    {
        XLLDownloadTaskItem *taskItem = [self getTaskItem:fileUrl];
        taskItem.progressBlock = progress;
        taskItem.stateBlock = state;
        if (taskItem.task == NSURLSessionTaskStateRunning)
        {
            //暂停任务
            [self pauseTask:taskItem];
        } else {
            //开启任务
            [self startTask:taskItem];
        }
        return;
    }
    if (self.tasks.count > self.maximumTaskCount) {
        if (state) {
            //任务达到上限
            state(XLLDownloadStateFailed);
        }
        return;
    }
    //没有任务，生成一个新的任务
    NSString *validUrl = [self getValidUrl:fileUrl];
    //创建文件目录
    if ([[NSFileManager defaultManager] fileExistsAtPath:FileloadDirectory(validUrl)])
    {
        [[NSFileManager defaultManager] removeItemAtPath:FileloadDirectory(validUrl) error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:FileloadDirectory(validUrl) withIntermediateDirectories:YES attributes:nil error:NULL];
    //创建plist文件目录
    if ([[NSFileManager defaultManager] fileExistsAtPath:PlistFileloadDirectory(validUrl)])
    {
        [[NSFileManager defaultManager] removeItemAtPath:PlistFileloadDirectory(validUrl) error:nil];
    }
    [[NSFileManager defaultManager] createDirectoryAtPath:PlistFileloadDirectory(validUrl) withIntermediateDirectories:YES attributes:nil error:NULL];
    // 加锁
    pthread_mutex_lock(&_pthread);
    NSDictionary *tempDic = @{
                              @"fileUrl":fileUrl,
                              @"fileName":fileName,
                              @"progressBlock":progress,
                              @"stateBlock":state
                              };
    [self performSelector:@selector(startDownloadFile:) onThread:[[self class] downloadTaskThread] withObject:tempDic waitUntilDone:NO modes:[[NSSet setWithObject:NSRunLoopCommonModes] allObjects]];
    // 解锁
    pthread_mutex_unlock(&_pthread);
}

- (void)startDownloadFile:(NSDictionary *)tempDic
{
    NSString *fileUrl = tempDic[@"fileUrl"];
    NSString *fileName = tempDic[@"fileName"];
    void(^progressBlock)(CGFloat) = tempDic[@"progressBlock"];
    void(^stateBlock)(XLLDownloadState) = tempDic[@"stateBlock"];
    NSString *validUrl = [self getValidUrl:fileUrl];
    //请求session
    NSURLSession *session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    //创建流
    NSOutputStream *stream = [NSOutputStream outputStreamToFileAtPath:FileFullpath(validUrl,fileName) append:YES];
    //创建请求
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:fileUrl]];
    //设置请求头
    NSString *range = [NSString stringWithFormat:@"bytes=%zd-", [self fileDownloadLength:validUrl fileName:fileName]];
    [request setValue:range forHTTPHeaderField:@"Range"];
    //创建一个task任务
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    NSUInteger taskIdentifier = arc4random() % ((arc4random() % 10000 + arc4random() % 10000));
    [task setValue:@(taskIdentifier) forKeyPath:@"taskIdentifier"];
    
    XLLDownloadTaskItem *taskItem = [[XLLDownloadTaskItem alloc] init];
    taskItem.fileUrl = fileUrl;
    taskItem.fileName = fileName;
    taskItem.progressBlock = progressBlock;
    taskItem.stateBlock = stateBlock;
    taskItem.stream = stream;
    taskItem.task = task;
    [self.tasks setValue:taskItem forKey:fileUrl];
    //开启这个任务
    [self startTask:taskItem];
}


//获取当前文件下载状态
- (XLLDownloadState)downloadState:(NSString *)fileUrl fileName:(NSString *)fileName
{
    NSString *validUrl = [self getValidUrl:fileUrl];
    //获取文件总大小
    NSInteger totalSize = [self fileTotalLength:validUrl fileName:fileName];
    //获取文件已下载大小
    NSInteger downloadSize = [self fileDownloadLength:validUrl fileName:fileName];
    if (totalSize && downloadSize == totalSize)
    {
        return XLLDownloadStateCompleted;
    }
    //看下是否有这个任务
    XLLDownloadTaskItem *taskItem = [self getTaskItem:fileUrl];
    if (taskItem.task)
    {
        if (taskItem.task.state == NSURLSessionTaskStateRunning)
        {
            return XLLDownloadStateDownloading;
        }
        return XLLDownloadStateSuspended;
    }
    return XLLDownloadStateUnStart;
}

//停止所有下载任务
- (void)stopAllDownloadTask
{
    for (XLLDownloadTaskItem *taskItem in self.tasks) {
        NSURLSessionDataTask *task = taskItem.task;
        if (task.state == NSURLSessionTaskStateRunning)
        {
            [task suspend];
        }
    }
}

//获取文件总大小
- (NSInteger)fileTotalLength:(NSString *)validUrl fileName:(NSString *)fileName
{
    return [[NSDictionary dictionaryWithContentsOfFile:TotalLengthFullpath(validUrl)][fileName] integerValue];
}

#pragma mark - private method
//得到合法的url
- (NSString *)getValidUrl:(NSString *)fileUrl
{
    NSString *validStr = [fileUrl stringByReplacingOccurrencesOfString:@":" withString:@""];
    validStr = [validStr stringByReplacingOccurrencesOfString:@"/" withString:@""];
    if ([NSString isContainChiese:validStr])
    {
        if ([UIDevice currentDevice].systemVersion.floatValue >= 9.0)
        {
            NSString *charactersToEscape = @"?!@#$^&%*+,;='\"`<>()[]{}/\\| ";
            NSCharacterSet *allowedCharacters = [[NSCharacterSet characterSetWithCharactersInString:charactersToEscape] invertedSet];
            validStr = [validStr stringByAddingPercentEncodingWithAllowedCharacters:allowedCharacters];
        } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            validStr = [validStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
#pragma clang diagnostic pop
        }
    }
    return validStr;
}

//文件已下载大小
- (NSInteger)fileDownloadLength:(NSString *)validUrl fileName:(NSString *)fileName
{
    NSInteger downloadLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:FileFullpath(validUrl, fileName) error:nil][NSFileSize] integerValue];
    return downloadLength;
}

//获取任务元素
- (XLLDownloadTaskItem *)getTaskItem:(NSString *)fileUrl
{
    XLLDownloadTaskItem *taskItem = (XLLDownloadTaskItem *)[self.tasks valueForKey:fileUrl];
    return taskItem;
}

//开启任务
- (void)startTask:(XLLDownloadTaskItem *)taskItem
{
    [taskItem.task resume];
    if (taskItem.stateBlock)
    {
        taskItem.stateBlock(XLLDownloadStateDownloading);
    }
}

//暂停任务
- (void)pauseTask:(XLLDownloadTaskItem *)taskItem
{
    [taskItem.task suspend];
    if (taskItem.stateBlock)
    {
        taskItem.stateBlock(XLLDownloadStateSuspended);
    }
}

//开启下载常驻线程
+ (NSThread *)downloadTaskThread
{
    static NSThread *_downloadTaskThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _downloadTaskThread = [[NSThread alloc] initWithTarget:self selector:@selector(downloadTaskThreadEntryPoint:) object:nil];
        [_downloadTaskThread start];
    });
    return _downloadTaskThread;
}

//为下载线程添加runloop保活
+ (void)downloadTaskThreadEntryPoint:(id)__unused object
{
    @autoreleasepool {
        [[NSThread currentThread] setName:@"XLLFileDownload"];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

#pragma mark - NSURLSessionDataDelegate
//接收响应
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler
{
    NSString *fileUrl = dataTask.currentRequest.URL.absoluteString;
    XLLDownloadTaskItem *taskItem = [self getTaskItem:fileUrl];
    // 打开流
    [taskItem.stream open];
    
    NSString *validUrl = [self getValidUrl:fileUrl];
    // 获得服务器这次请求 返回数据的总长度
    NSInteger totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + [self fileDownloadLength:validUrl fileName:taskItem.fileName];
    taskItem.totalLength = totalLength;
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:TotalLengthFullpath(validUrl)];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
    }
    if (taskItem.fileName) {
        dict[taskItem.fileName] = @(totalLength);
    }
    [dict writeToFile:TotalLengthFullpath(validUrl) atomically:YES];
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}

//接收到服务器返回的数据
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
    NSString *fileUrl = dataTask.currentRequest.URL.absoluteString;
    XLLDownloadTaskItem *taskItem = [self getTaskItem:fileUrl];
    // 写入数据
    [taskItem.stream write:data.bytes maxLength:data.length];
    
    NSString *validUrl = [self getValidUrl:fileUrl];
    NSInteger downloadSize = [self fileDownloadLength:validUrl fileName:taskItem.fileName];
    NSInteger totalSize = taskItem.totalLength;
    CGFloat progress = 1.0 * downloadSize / totalSize;
    if (taskItem.progressBlock)
    {
        taskItem.progressBlock(progress);
    }
}

//请求完毕（成功|失败）
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    NSString *fileUrl = task.currentRequest.URL.absoluteString;
    XLLDownloadTaskItem *taskItem = [self getTaskItem:fileUrl];
    if (!taskItem) return;
    //关闭流
    [taskItem.stream close];
    taskItem.stream = nil;
    //根据fileUrl清除任务
    [self.tasks removeObjectForKey:fileUrl];
    if ([self downloadState:fileUrl fileName:taskItem.fileName] == XLLDownloadStateCompleted)
    {
        if (taskItem.stateBlock)
        {
            taskItem.stateBlock(XLLDownloadStateCompleted);
        }
    } else {
        if (taskItem.stateBlock)
        {
            taskItem.stateBlock(XLLDownloadStateFailed);
        }
    }
}

@end

@implementation NSString (fileUrl)

+ (BOOL)isContainChiese:(NSString *)fileUrl
{
    for(int i = 0; i< [fileUrl length];i++)
    {
        int a = [fileUrl characterAtIndex:i];
        if( a > 0x4e00 && a < 0x9fff)
        {
            return YES;
        }
    }
    return NO;
}

@end
