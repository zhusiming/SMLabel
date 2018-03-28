//
//  SMLabel.h
//  SMLabel
//
//  Created by zsm on 13-12-17.
//  Copyright (c) 2013年 zsm. All rights reserved.
//

/*
    注意事项：
            1.使用之前需要倒入 libicucore.dylib  And  CoreText.framework
            2.SMLabel使用了ARC管理内存
            3.如果你的项目是非ARC项目，你需要在文件添加-fobjc-arc的标示（非ARC标示-fno-objc-arc）
 */

#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

@class SMLabel;
@protocol SMLabelDelegate <NSObject>

@optional

/// 手指离开当前非超链接文本响应的协议方法
- (void)toucheEndNoLinkSMLabel:(SMLabel * _Nonnull)smLabel;

/// 手指离开当前超链接文本响应的协议方法
- (void)toucheEndSMLabel:(SMLabel * _Nonnull)smLabel withContext:(NSString * _Nonnull)context;
/// 手指接触当前超链接文本响应的协议方法
- (void)toucheBenginSMLabel:(SMLabel * _Nonnull)smLabel withContext:(NSString * _Nonnull)context;

/*
    - (NSString *)contentsOfRegexStringWithSMLabel:(SMLabel *)SMLabel
    {
         //需要添加链接字符串的正则表达式：@用户、http://、#话题#
         NSString *regex1 = @"@\\w+";
         NSString *regex2 = @"http(s)?://([A-Za-z0-9._-]+(/)?)*";
         NSString *regex3 = @"#\\w+#";
         NSString *regex = [NSString stringWithFormat:@"(%@)|(%@)|(%@)",regex1,regex2,regex3];
         return regex;
    }
 */
/// 检索文本的正则表达式的字符串
- (NSString * _Nonnull)contentsOfRegexStringWithSMLabel:(SMLabel * _Nonnull)smLabel;
/// 设置当前链接文本的颜色
- (UIColor * _Nonnull)linkColorWithSMLabel:(SMLabel * _Nonnull)smLabel;
/// 设置当前文本手指经过的颜色
- (UIColor * _Nonnull)passColorWithSMLabel:(SMLabel * _Nonnull)smLabel;

/*
    注意：
        默认表达式@"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>"
        可以通过代理方法修改正则表达式，不过本地图片地址的左右（＊＊＊一定要用单引号引起来）
 */
/// 检索文本中图片的正则表达式的字符串
- (NSString * _Nonnull)imagesOfRegexStringWithSMLabel:(SMLabel * _Nullable)smLabel;

/// 长按显示UIMenuController视图
- (NSMutableArray<UIMenuItem *> * _Nonnull)menuItemsWithSMLabel:(SMLabel * _Nonnull)smLabel;
/// 点击UIMenuItem的点击事件
- (void)menuItemsTouchUpIndexWithSMLabel:(SMLabel * _Nonnull)smLabel menuItemAction:(SEL _Nonnull)action sender:(id _Nonnull)sender;
/// 显示menuController的时候的背景色 default = [UIColor lightGrayColor]
- (UIColor * _Nonnull)menuControllerDidShowColorWithSMLabel:(SMLabel * _Nonnull)smLabel;
/// 隐藏menuController的时候的背景色 default = [UIColor clearColor]
- (UIColor * _Nonnull)menuControllerDidCloseColorWithSMLabel:(SMLabel * _Nonnull)smLabel;

@end



@interface SMLabel : UILabel
/// @property(nonatomic, assign)BOOL isOpen;   //是否显示展开按钮
@property(nonatomic, assign)id<SMLabelDelegate> _Nonnull delegate;   //代理对象
@property(nonatomic, assign)CGFloat linespace;    //行间距      0
@property(nonatomic, assign)CGFloat lineHeight;   //行高        default = 当前字体的大小  如何设置行高小于字体大小时，行高默认为字体大小

///  自适应内容的高度
- (void)sm_sizeToFit;

/// 计算文本内容的高度
+ (CGFloat)sm_getStringHeightWithString:(NSString * _Nonnull)text
                                  width:(CGFloat) width
                              linespace:(CGFloat) linespace
                             lineHeight:(CGFloat) lineHeight
                                   font:(UIFont * _Nonnull)font
                               delegate:(id<SMLabelDelegate> _Nullable)delegate;

@end
