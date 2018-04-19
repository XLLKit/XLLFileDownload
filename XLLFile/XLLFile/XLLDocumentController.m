//
//  XLLDocumentController.m
//  XLLFile
//
//  Created by 肖乐 on 2018/4/19.
//  Copyright © 2018年 iOSCoder. All rights reserved.
//

#import "XLLDocumentController.h"

@interface XLLDocumentController () <UIDocumentPickerDelegate>

// 承载窗口
@property (nonatomic, strong) UIWindow *pickerWindow;

@end

@implementation XLLDocumentController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.delegate = self;
    self.view.tintColor = [UIColor purpleColor];
}

#pragma mark - UIDocumentPickerDelegate
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls
{
    // 官方文档说明，此沙盒外的文件url访问方法
    // 1.使用文件协调器NSFileCoordinator
    // 2.使用UIDocument子类（强烈建议）
    // 我两种方法都尝试了一下，
    if (!urls) return;
    
    /**
     // 一、使用文件协调器访问
     // 1.获取文件安全访问权限
     BOOL isSuccess = [fileUrl startAccessingSecurityScopedResource];
     if(isSuccess)
     {
     // 2.通过文件协调器读取文件地址
     NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] initWithFilePresenter:nil];
     [fileCoordinator coordinateReadingItemAtURL:fileUrl options:NSFileCoordinatorReadingWithoutChanges error:nil byAccessor:^(NSURL * _Nonnull newURL) {
     // 3.读取文件协调器提供的新地址里的数据
     if (self.chooseBlock)
     {
     self.chooseBlock(newURL);
     }
     }];
     }
     // 4.停止安全访问权限
     [fileUrl stopAccessingSecurityScopedResource];
     */
}

#pragma mark - setter
- (void)setThemeColor:(UIColor *)themeColor
{
    _themeColor = themeColor;
    self.view.tintColor = themeColor;
}

#pragma mark - public method
- (void)presentDocumentVCAnimation:(BOOL)animation
{
    // 还是使用官方推荐的方式吧
    self.pickerWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    self.pickerWindow.windowLevel = UIWindowLevelAlert;
    self.pickerWindow.rootViewController = self;
    [self.pickerWindow makeKeyAndVisible];
    if (animation)
    {
        CATransition *transition = [CATransition animation];
        [transition setDuration:0.3];
        transition.type = kCATransitionMoveIn;
        transition.subtype = kCATransitionFromTop;
        [[self.pickerWindow layer] addAnimation:transition forKey:nil];
    }
}

- (void)dismissPickerVC:(void(^)(void))completion
{
    [UIView animateWithDuration:.25 animations:^{
        
        self.pickerWindow.transform = CGAffineTransformTranslate(self.pickerWindow.transform, 0, CGRectGetMaxY(self.pickerWindow.frame));
    } completion:^(BOOL finished) {
        
        [self.pickerWindow resignKeyWindow];
        self.pickerWindow.hidden = YES;
        [[UIApplication sharedApplication].delegate.window makeKeyWindow];
        if (completion) completion();
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
