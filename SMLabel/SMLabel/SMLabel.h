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

// 设置行间距比例，行间距 ＝ 行间距比例＊字体大小 default ＝ 0.4
#define kSMLINEHEIGHT_SCALE (.4)

// 计算文本的最大行高，默认为：1000,如果视图内容可能超过这个高度可自行调节
#define kSMLabel_MAXHEIGHT (1000)

@class SMLabel;
@protocol SMLabelDelegate <NSObject>

@optional

//手指离开当前非超链接文本响应的协议方法
- (void)toucheEndNoLinkSMLabel:(SMLabel *)smLabel;

//手指离开当前超链接文本响应的协议方法
- (void)toucheEndSMLabel:(SMLabel *)smLabel withContext:(NSString *)context;
//手指接触当前超链接文本响应的协议方法
- (void)toucheBenginSMLabel:(SMLabel *)smLabel withContext:(NSString *)context;

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
//检索文本的正则表达式的字符串
- (NSString *)contentsOfRegexStringWithSMLabel:(SMLabel *)smLabel;
//设置当前链接文本的颜色
- (UIColor *)linkColorWithSMLabel:(SMLabel *)smLabel;
//设置当前文本手指经过的颜色
- (UIColor *)passColorWithSMLabel:(SMLabel *)smLabel;

/*
    注意：
        默认表达式@"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>"
        可以通过代理方法修改正则表达式，不过本地图片地址的左右（＊＊＊一定要用单引号引起来）
 */
//检索文本中图片的正则表达式的字符串
- (NSString *)imagesOfRegexStringWithSMLabel:(SMLabel *)smLabel;
@end



@interface SMLabel : UILabel

@property(nonatomic, assign)id<SMLabelDelegate> delegate;   //代理对象
@property(nonatomic, assign, readonly)CGFloat linespace;    //行间距      default = 当前字体的大小 ＊ kSMLINEHEIGHT_SCALE
@property(nonatomic, assign, readonly)CGFloat lineHeight;   //行高        default = 当前字体的大小

// 自适应内容的高度
- (void)sizeToFit;

//计算文本内容的高度
+ (float)getAttributedStringHeightWithString:(NSString *)text
                                  WidthValue:(float)width
                                    delegate:(id<SMLabelDelegate>)delegate
                                        font:(UIFont*)font;
@end
