//
//  XLLFileDownload.h
//  XLLFile
//
//  Created by 肖乐 on 2018/4/19.
//  Copyright © 2018年 iOSCoder. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, XLLDownloadState) {
    
    XLLDownloadStateDownloading, //下载中
    XLLDownloadStateSuspended,   //暂停中
    XLLDownloadStateCompleted,   //下载完成
    XLLDownloadStateFailed,      //下载失败
    XLLDownloadStateUnStart      //暂未下载
};

@interface XLLDownloadTaskItem : NSObject

/**
 下载状态回执
 */
@property (nonatomic, copy) void(^stateBlock)(XLLDownloadState state);

/**
 下载任务
 */
@property (nonatomic, strong) NSURLSessionDataTask *task;

/**
 流
 */
@property (nonatomic, strong) NSOutputStream *stream;

/**
 下载链接
 */
@property (nonatomic, copy) NSString *fileUrl;

/**
 文件名称
 */
@property (nonatomic, copy) NSString *fileName;

/**
 文件总大小，单位字节
 */
@property (nonatomic, assign) NSInteger totalLength;

/**
 下载进度回执
 */
@property (nonatomic, copy) void(^progressBlock)(CGFloat downloadProgress);

@end

@interface XLLFileDownload : NSObject

/**
 同时支持的最多任务数量,缺省为10
 */
@property (nonatomic, assign) NSInteger maximumTaskCount;

/**
 初始化下载实例

 @return 下载实例
 */
+ (instancetype)sharedDownloadInstance;

/**
 下载文件方法

 @param fileUrl 文件下载链接
 @param fileName 文件名
 @param progress 文件下载进度回执
 @param state 文件下载状态回执
 */
- (void)download:(NSString *)fileUrl
        fileName:(NSString *)fileName
        progress:(void(^)(CGFloat downloadProgress))progress
           state:(void(^)(XLLDownloadState downloadState))state;

/**
 获取文件下载状态

 @param fileUrl 文件下载链接
 @param fileName 文件名称
 @return 下载状态
 */
- (XLLDownloadState)downloadState:(NSString *)fileUrl
                         fileName:(NSString *)fileName;

/**
 停止所有下载任务
 */
- (void)stopAllDownloadTask;

@end

@interface NSString (fileUrl)

/**
 判断是否包含中文

 @param fileUrl 需要验证的字符串
 @return 判断结果
 */
+ (BOOL)isContainChiese:(NSString *)fileUrl;

@end
