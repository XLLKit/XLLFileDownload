//
//  ViewController.m
//  XLLFile
//
//  Created by 肖乐 on 2018/4/19.
//  Copyright © 2018年 iOSCoder. All rights reserved.
//

#import "ViewController.h"
#import "XLLFileDownload.h"
#import "XLLDocumentController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor redColor];
}

- (IBAction)downloadBtnClick:(id)sender {
    
    XLLDocumentController *vc = [[XLLDocumentController alloc] initWithDocumentTypes:@[@"public.content", @"public.item", @"public.data", @"public.image"] inMode:UIDocumentPickerModeImport];
    [vc presentDocumentVCAnimation:YES];
//    [[XLLFileDownload sharedDownloadInstance] download:@"http://image.we-meeting.com/Fg3n4UitjXJichxOLGQ1LeRCsEdA.mp4" fileName:@"小视频" progress:^(CGFloat downloadProgress) {
//
//        NSLog(@"~~~%lf---", downloadProgress);
//
//    } state:^(XLLDownloadState downloadState) {
//
//        NSLog(@"~~~%zd---", downloadState);
//    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
