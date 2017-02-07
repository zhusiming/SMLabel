//
//  ViewController.m
//  SMLabel
//
//  Created by zsm on 13-12-17.
//  Copyright (c) 2013年 zsm. All rights reserved.
//

#import "ViewController.h"
#import "SMLabel.h"
#import "RegexKitLite.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.view.backgroundColor = [UIColor orangeColor];
    // 创建一个富文本视图
    SMLabel *label = [[SMLabel alloc] initWithFrame:CGRectMake(0, 100, 320, 200)];
    // 设置代理对象
    label.delegate = self;
    label.font = [UIFont systemFontOfSize:16];
    label.text = @"测试数据，这是一个富文本师徒@用户 据文混排的框架#话题#、#话题#、#话题# ，https://github.com/zhusiming 下面要现实一张图片<image url = '1.png'>图片在现实d现实d现实d现实d现实d现实d现实d现实dd现实d现实1123412－12测试数据，这是一个富文本师徒@用户 据文混排的框架#话题#、#话题#、#话题# ，https://github.com/zhusiming 下面要现实一张图片<image url = '1.png'>图片在现实d现实d现实d现实d现实d现实d现实d现实dd现实d现实1123412－121<image url = '2.gif'>1";
    label.backgroundColor = [UIColor grayColor];
    // 获取文本的高度
    float height = [SMLabel getAttributedStringHeightWithString:label.text WidthValue:320 delegate:self font:label.font];
    // 设置视图的大小
    label.frame = CGRectMake(0, 100, 320, height);
    // 视图大小自适应内容大小
//    [label sizeToFit];

    [self.view addSubview:label];
}

#pragma mark - SMLabelDelegate
//手指离开当前超链接文本响应的协议方法
- (void)toucheEndSMLabel:(SMLabel *)smLabel withContext:(NSString *)context
{
    NSLog(@"context:%@",context);
}
//手指接触当前超链接文本响应的协议方法
//- (void)toucheBenginSMLabel:(SMLabel *)smLabel withContext:(NSString *)context;


//检索文本的正则表达式的字符串
- (NSString *)contentsOfRegexStringWithSMLabel:(SMLabel *)smLabel
{
    //需要添加链接字符串的正则表达式：@用户、http://、#话题#
    NSString *regex1 = @"@\\w+";
    NSString *regex2 = @"http(s)?://([A-Za-z0-9._-]+(/)?)*";
    NSString *regex3 = @"#\\w+#";
    NSString *regex = [NSString stringWithFormat:@"(%@)|(%@)|(%@)",regex1,regex2,regex3];
    return regex;
}
//设置当前链接文本的颜色
- (UIColor *)linkColorWithSMLabel:(SMLabel *)smLabel
{
    return [UIColor yellowColor];
}
//设置当前文本手指经过的颜色
- (UIColor *)passColorWithSMLabel:(SMLabel *)smLabel
{
    return [UIColor greenColor];
}

/*
 注意：
 默认表达式@"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>"
 可以通过代理方法修改正则表达式，不过本地图片地址的左右（＊＊＊一定要用单引号引起来）
 */
//检索文本中图片的正则表达式的字符串
//- (NSString *)imagesOfRegexStringWithSMLabel:(SMLabel *)smLabel;

@end
