//
//  XLLDocumentController.h
//  XLLFile
//
//  Created by 肖乐 on 2018/4/19.
//  Copyright © 2018年 iOSCoder. All rights reserved.
//  适用于iOS11+

#import <UIKit/UIKit.h>

@interface XLLDocumentController : UIDocumentPickerViewController

/**
 设置主题颜色
 */
@property (nonatomic, strong) UIColor *themeColor;

/**
 present到文件控制器

 @param animation 是否开启动画
 */
- (void)presentDocumentVCAnimation:(BOOL)animation;

@end
