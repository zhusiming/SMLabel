//
//  ViewController.m
//  SMLabel
//
//  Created by zsm on 13-12-17.
//  Copyright (c) 2013年 zsm. All rights reserved.
//

#import "ViewController.h"
#import "SMLabel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor orangeColor];
    // 创建一个富文本视图
    SMLabel *label = [[SMLabel alloc] initWithFrame:CGRectMake(0, 100, 320, 200)];
    label.lineHeight = 20;
    label.linespace = 10;
    label.linkUnderline = true;
    // 设置代理对象
    label.delegate = self;
    label.font = [UIFont systemFontOfSize:14];
    label.text = @"测试数据，这是一个富文本一个富文本本本一个富文本一个富文本@用户 据文#话题#、1111111#话题# ，片<image url = '1.png'>图片在现实d现实d😂d现实d<image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'>d现实d现实d现实1@用户 据文混排的框架#话题#、#话题#、#话题# ，https://github.com/zhusiming 下面要现实一张图片<image url = '1.png'>图片在现实d现实d现实d现实d现实d现实d现实d现实dd现实d现实1123412－121😂😄<image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'><image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'><image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'><image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'><image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'><image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'><image url = 'B8715B823E6BE80BB1516E6AF60C49E3.png'>😄😂1";
    label.backgroundColor = [UIColor grayColor];
    // 获取文本的高度
//    float height = [SMLabel sm_getStringHeightWithString:label.text width:320 linespace:10 lineHeight:20 font:label.font delegate:self];
    // 设置视图的大小
    label.frame = CGRectMake(0, 100, 320, 80);
    // 视图大小自适应内容大小
    [label sm_sizeToFit];

    [self.view addSubview:label];
}

#pragma mark - SMLabelDelegate
/// 手指离开当前非超链接文本响应的协议方法
- (void)sm_label:(SMLabel * _Nonnull)label didTouche:(UITouch * _Nonnull)touche {
    NSLog(@"点击了label非超链接文本视图位置");
}

/// 手指离开当前超链接文本响应的协议方法
- (void)sm_label:(SMLabel * _Nonnull)label didToucheHyperlinkText:(NSString * _Nonnull)text {
    NSLog(@"context:%@",text);
}

/// 手指接触当前超链接文本响应的协议方法
//- (void)sm_label:(SMLabel * _Nonnull)label willToucheHyperlinkText:(NSString * _Nonnull)text;

/// 检索文本的正则表达式的字符串
- (NSString * _Nonnull)sm_regexStringHyperlinkOfLabel:(SMLabel * _Nonnull)label {
    //需要添加链接字符串的正则表达式：@用户、http://、#话题#
    NSString *regex1 = @"@\\w+";
    NSString *regex2 = @"http(s)?://([A-Za-z0-9._-]+(/)?)*";
    NSString *regex3 = @"#\\w+#";
    NSString *regex = [NSString stringWithFormat:@"(%@)|(%@)|(%@)",regex1,regex2,regex3];
    return regex;
}

/*
 注意：
 默认表达式@"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>"
 可以通过代理方法修改正则表达式，不过本地图片地址的左右（＊＊＊一定要用单引号引起来）
 */
/// 检索文本中图片的正则表达式的字符串
//- (NSString * _Nonnull)sm_regexStringImageOfLabel:(SMLabel * _Nullable)label;

/// 设置当前链接文本的颜色
- (UIColor * _Nonnull)sm_linkColorOfLabel:(SMLabel * _Nonnull)label {
    return [UIColor yellowColor];
}

/// 设置当前文本手指经过的颜色
- (UIColor * _Nonnull)sm_passColorOfLabel:(SMLabel * _Nonnull)label {
    return [UIColor greenColor];
}

#pragma mark - 1.1.0 添加长按显示UIMenuController功能
/// 长按显示UIMenuController视图
- (NSMutableArray<UIMenuItem *> * _Nonnull)sm_menuItemsOfLabel:(SMLabel * _Nonnull)label {
    NSMutableArray *menuItems = [[NSMutableArray alloc] init];
    
    UIMenuItem *copyItem = [[UIMenuItem alloc] initWithTitle:@"复制" action:NSSelectorFromString(@"copyText:")];
    [menuItems addObject:copyItem];
    UIMenuItem *testItem = [[UIMenuItem alloc] initWithTitle:@"测试" action:NSSelectorFromString(@"test:")];
    [menuItems addObject:testItem];
    return menuItems;
}

/// 点击UIMenuItem的点击事件
- (void)sm_label:(SMLabel * _Nonnull)label menuItemsAction:(SEL _Nonnull)action sender:(id _Nonnull)sender {
    if (action == NSSelectorFromString(@"copyText:")) {
        NSLog(@"复制%@",sender);
    } else if (action == NSSelectorFromString(@"test:")) {
        NSLog(@"测试%@",sender);
    }
}

/// 显示menuController的时候的背景色 default = [UIColor lightGrayColor]
- (UIColor * _Nonnull)sm_menuControllerDidShowColorOfLabel:(SMLabel * _Nonnull)label {
    return [UIColor redColor];
}

/// 隐藏menuController的时候的背景色 default = [UIColor clearColor]
- (UIColor * _Nonnull)sm_menuControllerWillHiddenColorOfLabel:(SMLabel * _Nonnull)label {
    return [UIColor clearColor];
}

@end
