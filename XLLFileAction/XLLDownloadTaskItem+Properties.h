//
//  XLLDownloadTaskItem+Properties.h
//  XLLFile
//
//  Created by 肖乐 on 2018/4/20.
//  Copyright © 2018年 iOSCoder. All rights reserved.
//

#import "XLLFileDownload.h"

@interface XLLDownloadTaskItem ()

/**
 下载任务
 */
@property (nonatomic, strong) NSURLSessionDataTask *task;

/**
 流
 */
@property (nonatomic, strong) NSOutputStream *stream;

@end
