//
//  SMLabel.m
//  SMLabel
//
//  Created by zsm on 13-12-17.
//  Copyright (c) 2013年 zsm. All rights reserved.
//

#import "SMLabel.h"
#import <CoreText/CoreText.h>
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>

#define SMLabel_IMAGE_NAME @"imageName"

void smLabelMenuControllerAction(id self, SEL _cmd, id param) {
    
    if ([self isKindOfClass:[SMLabel class]]) {
        SMLabel *thisSelf = self;
        if ([thisSelf.delegate respondsToSelector:@selector(menuItemsTouchUpIndexWithSMLabel:menuItemAction:sender:)]) {
            [thisSelf.delegate menuItemsTouchUpIndexWithSMLabel:self menuItemAction:_cmd sender:param];
        }
    }
//    NSLog(@"调用eat %@ %@ %@",self,NSStringFromSelector(_cmd),param);
}

@interface SMLabel ()

@property(nonatomic,assign)NSRange movieStringRange;//当前选中的字符索引
@property(nonatomic,strong)NSMutableArray *ranges;//所有链接文本的位置数组
@property(nonatomic,assign)NSInteger lastLineWidth;//最后一行文本的宽度
@property(nonatomic,strong)NSMutableAttributedString *attrString;//文本属性字符串
@property(nonatomic,strong)NSArray *row;//所有行的数组
@property(nonatomic,strong)UIColor *linkColor;   //超链接文本颜色
@property(nonatomic,strong)UIColor *passColor;   //鼠标经过链接文本颜色
@property(nonatomic,strong)NSArray *regexStrArray;  //正则表达式 数组
@property(nonatomic,strong)NSMutableArray *emoticonArray;  //正则表达式 数组

@property(nonatomic,strong)NSMutableArray<UIMenuItem *> *menuItems; // 长按选项菜单

@end

@implementation SMLabel

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        /// 初始化
        [self _customInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    /// 初始化
    [self _customInit];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        /// 初始化
        [self _customInit];
    }
    return self;
}

/// 初始化
- (void)_customInit {
    // 开启当前点击的手势
    self.userInteractionEnabled = YES;
    // 创建长按手势
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressAction:)];
    longPress.minimumPressDuration = 0.5;
    [self addGestureRecognizer:longPress];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuControllerWillHide) name:UIMenuControllerWillHideMenuNotification object:nil];
    // 初始化属性
}

- (void)longPressAction:(UILongPressGestureRecognizer *)longPress {
    if (longPress.state == UIGestureRecognizerStateBegan) {
        if ([self.delegate respondsToSelector:@selector(menuItemsWithSMLabel:)]) {
            self.menuItems = [self.delegate menuItemsWithSMLabel:self];
            [self becomeFirstResponder];
            // 控制好menu的显示与隐藏
            UIMenuController *menuVC = [UIMenuController sharedMenuController];
            if (menuVC.isMenuVisible) {
                [menuVC setMenuVisible:NO animated:YES];
            }
            menuVC.menuItems = self.menuItems;
            /// 显示menuController的时候的背景色 default = [UIColor lightGrayColor]
            if ([self.delegate respondsToSelector:@selector(menuControllerDidShowColorWithSMLabel:)]) {
                self.backgroundColor = [self.delegate menuControllerDidShowColorWithSMLabel:self];
            } else {
                self.backgroundColor = [UIColor lightGrayColor];
            }
            [menuVC setTargetRect:self.frame inView:self.superview];
            [menuVC setMenuVisible:YES animated:YES];
        } else {
            self.menuItems = nil;
        }
    }
}

- (BOOL)canBecomeFirstResponder
{
    // 明确该控件可以成为第一响应者
    return YES;
}

// 该控件可以执行哪些动作
- (BOOL)canPerformAction:(SEL)action withSender:(id)sender
{
    // 1.遍历列表中的内容进行对比
    for (UIMenuItem *item in self.menuItems) {
        if (item.action == action) {
            // 2.判断当前方法是否存在不存在进行方法创建
            if (![self respondsToSelector:action]) {
                return class_addMethod([self class], action, (IMP)smLabelMenuControllerAction, "v@:@");
            }
            return YES;
        }
    }
    return NO;
}

// 菜单视图将要消失
- (void)menuControllerWillHide
{
    /// 隐藏menuController的时候的背景色 default = [UIColor clearColor]
    if ([self.delegate respondsToSelector:@selector(menuControllerDidCloseColorWithSMLabel:)]) {
        self.backgroundColor = [self.delegate menuControllerDidCloseColorWithSMLabel:self];
    } else {
        self.backgroundColor = [UIColor clearColor];
    }
}

#pragma mark - 绘制视图
- (void)drawRect:(CGRect)rect
{
    // 创建表情视图存储数组
    if (self.emoticonArray == nil) {
        self.emoticonArray = [[NSMutableArray alloc] init];
    } else {
        // 移除表情数组中的元素和视图
        for (UIView *emoticonView in self.emoticonArray) {
            [emoticonView removeFromSuperview];
        }
        [self.emoticonArray removeAllObjects];
    }
    
    //当前文本超链接文字的颜色默认为purpleColor
    self.linkColor = [UIColor purpleColor];
    //自定义当前超链接文本颜色
    if ([self.delegate respondsToSelector:@selector(linkColorWithSMLabel:)]) {
        self.linkColor = [self.delegate linkColorWithSMLabel:self];
    }
    
    //当前文本超链接文字手指经过的颜色默认为greenColor
    self.passColor = [UIColor greenColor];
    //自定义当前超链接文本颜色
    if ([self.delegate respondsToSelector:@selector(passColorWithSMLabel:)]) {
        self.passColor = [self.delegate passColorWithSMLabel:self];
    }
    if (self.text == nil) {
        return;
    }
    //生成属性字符串对象
    self.attrString = [[NSMutableAttributedString alloc]initWithString:self.text];
    //设置图片属性字符串
    [self replaceImageText];
    
    //------------------------设置字体属性--------------------------
    //    CTFontRef font = CTFontCreateWithName(CFSTR("Georgia"), 15, NULL);
    //设置当前字体
    [_attrString addAttribute:(id)kCTFontAttributeName value:self.font range:NSMakeRange(0, _attrString.length)];
    //设置当前文本的颜色
    [_attrString addAttribute:(id)kCTForegroundColorAttributeName value:self.textColor range:NSMakeRange(0, _attrString.length)];
    
    
    //----------------------设置链接文本的颜色-------------------
    //判断当前链接文本表达式是否实现
    if ([self.delegate respondsToSelector:@selector(contentsOfRegexStringWithSMLabel:)] && [self.delegate contentsOfRegexStringWithSMLabel:self] != nil)
    {
        //获取所有的链接文本
        NSArray *contents = [self contentsOfRegexStrArray];
        
        //获取所有文本的的索引集合
        NSArray *ranges = [self rangesOfContents:contents];
        //NSLog(@"ranges %@",ranges);
        for (NSValue *value in ranges) {
            NSRange range = [value rangeValue];
            //设置字体的颜色
            [_attrString addAttribute:(id)kCTForegroundColorAttributeName value:(id)self.linkColor range:range];
            
        }
        
        //设置选中经过字体颜色
        [_attrString addAttribute:(id)kCTForegroundColorAttributeName value:(id)self.passColor range:self.movieStringRange];
        
    }
    
    
    //------------------------设置段落属性-----------------------------
    //指定为对齐属性
    CTTextAlignment alignment = kCTJustifiedTextAlignment;
    CTParagraphStyleSetting alignmentStyle;
    alignmentStyle.spec=kCTParagraphStyleSpecifierFirstLineHeadIndent;//指定为对齐属性
    alignmentStyle.valueSize=sizeof(alignment);
    alignmentStyle.value=&alignment;
    
    
    //行距
    CTParagraphStyleSetting lineSpaceSetting;
    lineSpaceSetting.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
    lineSpaceSetting.value = &_linespace;
    lineSpaceSetting.valueSize = sizeof(_linespace);
    
    //设置行高
    if (_lineHeight < self.font.pointSize) {
        _lineHeight = self.font.pointSize;
    }
    CTParagraphStyleSetting MinLineHeight;
    MinLineHeight.spec = kCTParagraphStyleSpecifierMinimumLineHeight;
    MinLineHeight.value = &_lineHeight;
    MinLineHeight.valueSize = sizeof(_lineHeight);
    
    CTParagraphStyleSetting MaxLineHeight;
    MaxLineHeight.spec = kCTParagraphStyleSpecifierMaximumLineHeight;
    MaxLineHeight.value = &_lineHeight;
    MaxLineHeight.valueSize = sizeof(_lineHeight);
    
    //换行模式
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping;
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    //组合设置
    CTParagraphStyleSetting settings[] = {
        lineSpaceSetting,MinLineHeight,MaxLineHeight,alignmentStyle,lineBreakMode
    };
    
    //通过设置项产生段落样式对象
    CTParagraphStyleRef style = CTParagraphStyleCreate(settings, 5);
    
    // build attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:(__bridge id)style forKey:(id)kCTParagraphStyleAttributeName ];
    
    // set attributes to attributed string
    [_attrString addAttributes:attributes range:NSMakeRange(0, _attrString.length)];
    
    
    //生成CTFramesetterRef对象
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)_attrString);
    
    
    //然后创建一个CGPath对象，这个Path对象用于表示可绘制区域坐标值、长宽。
    CGRect bouds = CGRectInset(self.bounds, 0.0f, 0.0f);
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, bouds);
    
    //使用上面生成的setter和path生成一个CTFrameRef对象，这个对象包含了这两个对象的信息（字体信息、坐标信息）
    CTFrameRef frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, NULL);
    //获取当前(View)上下文以便于之后的绘画，这个是一个离屏。
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context , CGAffineTransformIdentity);
    //压栈，压入图形状态栈中.每个图形上下文维护一个图形状态栈，并不是所有的当前绘画环境的图形状态的元素都被保存。图形状态中不考虑当前路径，所以不保存
    //保存现在得上下文图形状态。不管后续对context上绘制什么都不会影响真正得屏幕。
    CGContextSaveGState(context);
    //x，y轴方向移动
    CGContextTranslateCTM(context , 0 ,self.frame.size.height );
    //缩放x，y轴方向缩放，－1.0为反向1.0倍,坐标系转换,沿x轴翻转180度
    CGContextScaleCTM(context, 1.0 ,-1.0);
    //可以使用CTFrameDraw方法绘制了。
//    CTFrameDraw(frame,context);
//    return;
    //获取当前行的集合
    self.row = (NSArray *)CTFrameGetLines(frame);
    if (self.row.count > 0) {
        CGRect lineBounds = CTLineGetImageBounds((CTLineRef)[self.row lastObject], context);
        _lastLineWidth = lineBounds.size.width;
        
        //---------------------------绘制图片---------------------------
        CFArrayRef lines = CTFrameGetLines(frame);
        CGPoint lineOrigins[CFArrayGetCount(lines)];
        CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), lineOrigins);
        //NSLog(@"line count = %ld",CFArrayGetCount(lines));
        for (int i = 0; i < CFArrayGetCount(lines); i++) {
            CTLineRef line = CFArrayGetValueAtIndex(lines, i);
            CGFloat lineAscent;
            CGFloat lineDescent;
            CGFloat lineLeading;
            CTLineGetTypographicBounds(line, &lineAscent, &lineDescent, &lineLeading);
            //NSLog(@"ascent = %f,descent = %f,leading = %f",lineAscent,lineDescent,lineLeading);
            CFArrayRef runs = CTLineGetGlyphRuns(line);
            //NSLog(@"run count = %ld",CFArrayGetCount(runs));
            for (int j = 0; j < CFArrayGetCount(runs); j++) {
                CGFloat runAscent;
                CGFloat runDescent;
                CGPoint lineOrigin = lineOrigins[i];
                CTRunRef run = CFArrayGetValueAtIndex(runs, j);
                NSDictionary* attributes = (NSDictionary*)CTRunGetAttributes(run);
                CGRect runRect;
                runRect.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0,0), &runAscent, &runDescent, NULL);
                //NSLog(@"width = %f",runRect.size.width);
                
                runRect=CGRectMake(lineOrigin.x + CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL), lineOrigin.y - runDescent, runRect.size.width, runAscent + runDescent);
                //NSLog(@"%@",attributes);
                NSString *imageName = [attributes objectForKey:SMLabel_IMAGE_NAME];
                //图片渲染逻辑
                if (imageName) {
                    UIImage *image = [UIImage imageNamed:imageName];
                    if (image) {
                        CGRect imageDrawRect;
#pragma mark 设置图片的大小
                        if (![imageName hasSuffix:@"gif"]) {
                            imageDrawRect.size = CGSizeMake(self.font.pointSize + 4 , self.font.pointSize + 4);
                            imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                            imageDrawRect.origin.y = lineOrigin.y - self.font.pointSize * 0.2 - 0.5;
                            CGContextDrawImage(context, imageDrawRect, image.CGImage);
                            //NSLog(@"gif:rect:%@,imageName:%@",NSStringFromCGRect(imageDrawRect),imageName);
                        } else {
#pragma mark gif
                            imageDrawRect.size = CGSizeMake(self.font.pointSize + 4, self.font.pointSize + 4);
                            imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                            imageDrawRect.origin.y = self.frame.size.height - lineOrigin.y + self.font.pointSize * 0.2 - 0.5 - self.font.pointSize * 1.20;
                            //NSLog(@"png:rect:%@,imageName:%@",NSStringFromCGRect(imageDrawRect),imageName);
                            NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:imageName withExtension:@""];//加载GIF图片
                            CGImageSourceRef gifSource = CGImageSourceCreateWithURL((CFURLRef)fileUrl, NULL);//将GIF图片转换成对应的图片源
                            size_t frameCout=CGImageSourceGetCount(gifSource);//获取其中图片源个数，即由多少帧图片组成
                            NSMutableArray* frames=[[NSMutableArray alloc] init];//定义数组存储拆分出来的图片
                            for (size_t i=0; i < frameCout; i++) {
                                CGImageRef imageRef=CGImageSourceCreateImageAtIndex(gifSource, i, NULL);//从GIF图片中取出源图片
                                UIImage* imageName=[UIImage imageWithCGImage:imageRef];//将图片源转换成UIimageView能使用的图片源
                                [frames addObject:imageName];//将图片加入数组中
                                CGImageRelease(imageRef);
                            }
                            
                            UIImageView* emoticonImageView=[[UIImageView alloc] initWithFrame:imageDrawRect];
                            emoticonImageView.animationImages=frames;//将图片数组加入UIImageView动画数组中
                            emoticonImageView.animationDuration=2;//每次动画时长
                            [emoticonImageView startAnimating];//开启动画，此处没有调用播放次数接口，UIImageView默认播放次数为无限次，故这里不做处理
                            [self addSubview:emoticonImageView];
                            [self.emoticonArray addObject:emoticonImageView];
                        }
                        
                        
                        //                    imageDrawRect.size = CGSizeMake(image.size.height, image.size.height);
                        //                    imageDrawRect.origin.x = runRect.origin.x + lineOrigin.x;
                        //                    imageDrawRect.origin.y = lineOrigin.y - 8;
                        //                    CGContextDrawImage(context, imageDrawRect, image.CGImage);
                        
                    }
                }
            }
            //CoreText的origin的Y值是在baseLine处，而不是下方的descent。
            CGPoint lineOrigin = lineOrigins[i];
            CGContextSetTextPosition(context, lineOrigin.x, lineOrigin.y);
            
            if (i == self.row.count - 1) {
                //NSLog(@"最后一行");
                // 最后一行，加上省略号
//                static NSString* const kEllipsesCharacter = @"\u2026 全文";
                static NSString* const kEllipsesCharacter = @"\u2026";
                CFRange lastLineRange = CTLineGetStringRange(line);
                // 一个emoji表情占用两个长度单位
                //NSLog(@"range.location = %ld,range.length = %ld,总长度 = %ld",lastLineRange.location,lastLineRange.length,_attrString.length);
                if (lastLineRange.location + lastLineRange.length < (CFIndex)_attrString.length){
                    // 这一行放不下所有的字符（下一行还有字符），则把此行后面的回车、空格符去掉后，再把最后一个字符替换成省略号
                    CTLineTruncationType truncationType = kCTLineTruncationEnd;
//                    NSUInteger truncationAttributePosition = lastLineRange.location + lastLineRange.length - 1;
                    
                    // 拿到最后一个字符的属性字典
                    // 给省略号字符设置字体大小、颜色等属性
                    NSMutableAttributedString *tokenString = [[NSMutableAttributedString alloc] initWithString:kEllipsesCharacter];
                    [tokenString addAttribute:(id)kCTForegroundColorAttributeName value:(id)self.textColor range:NSMakeRange(0, 1)];
//                    [tokenString addAttribute:(id)kCTForegroundColorAttributeName value:(id)self.linkColor range:NSMakeRange(2, 2)];
                    
                    // 用省略号单独创建一个CTLine，下面在截断重新生成CTLine的时候会用到
                    CTLineRef truncationToken = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)tokenString);
                    
                    // 把这一行的属性字符串复制一份，如果要把省略号放到中间或其他位置，只需指定复制的长度即可
                    long copyLength = lastLineRange.length;
                    
                    NSMutableAttributedString *truncationString = [[_attrString attributedSubstringFromRange:NSMakeRange(lastLineRange.location, copyLength)] mutableCopy];
                    
                    if (lastLineRange.length > 0)
                    {
                        // Remove any whitespace at the end of the line.
                        unichar lastCharacter = [[truncationString string] characterAtIndex:copyLength - 1];
                        
                        // 如果复制字符串的最后一个字符是换行、空格符，则删掉
                        if ([[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:lastCharacter])
                        {
                            [truncationString deleteCharactersInRange:NSMakeRange(copyLength - 1, 1)];
                        }
                    }
                    
                    // 拼接省略号到复制字符串的最后
                    [truncationString appendAttributedString:tokenString];
                    
                    // 把新的字符串创建成CTLine
                    CTLineRef truncationLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)truncationString);
                    
                    // 创建一个截断的CTLine，该方法不能少，具体作用还有待研究
                    CTLineRef truncatedLine = CTLineCreateTruncatedLine(truncationLine, self.frame.size.width, truncationType, truncationToken);
                    
                    if (!truncatedLine)
                    {
                        // If the line is not as wide as the truncationToken, truncatedLine is NULL
                        truncatedLine = CFRetain(truncationToken);
                    }
                    
                    CFRelease(truncationLine);
                    CFRelease(truncationToken);
                    
                    CTLineDraw(truncatedLine, context);
                    CFRelease(truncatedLine);
                } else{
                    // 这一行刚好是最后一行，且最后一行的字符可以完全绘制出来
                    CTLineDraw(line, context);
                }
            } else {
                CTLineDraw(line, context);
            }
        }
    }
    
    
    
    //－－－－－－－－－－－－－－－获取当前文本的高度－－－－－－－－－－－－－－－－－－
    //获取当前的行高
    //    float lineHeight = self.font.pointSize + self.linespace + 2;
    //    self.textHeight = CFArrayGetCount(lines) * lineHeight ;
    
    //释放对象
    CGPathRelease(path);
    CFRelease(framesetter);
    CFRelease(frame);
    
    
}
#pragma mark - 检索当前图片
//获取所有图片的字符串
- (NSArray *)imagesOfRegexStrArray
{
    //需要添加图片正则表达，默认为@"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>"
    NSString *regex = @"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>";
    if ([self.delegate respondsToSelector:@selector(imagesOfRegexStringWithSMLabel:)]) {
        regex = [self.delegate imagesOfRegexStringWithSMLabel:self];
    }
    
    //通过正则表达式查找出匹配的字符串
    NSArray *matchArray = [SMLabel matchLinkWithStr:self.text withMatchStr:regex];
    //NSLog(@"2----个数：%@",matchArray);
//    NSArray *matchArray = [self.text componentsMatchedByRegex:regex];
    //<image url = 'wxhl.png'>
    return matchArray;
}

//替换图片文本
- (void)replaceImageText
{
    //为图片设置CTRunDelegate,delegate决定留给图片的空间大小
    CTRunDelegateCallbacks imageCallbacks;
    imageCallbacks.version = kCTRunDelegateVersion1;
    imageCallbacks.dealloc = RunDelegateDeallocCallback;
    imageCallbacks.getAscent = RunDelegateGetAscentCallback;
    imageCallbacks.getDescent = RunDelegateGetDescentCallback;
    imageCallbacks.getWidth = RunDelegateGetWidthCallback;
    
    //存放所有图片的索引位置
    NSMutableArray *ranges = [NSMutableArray array];
    for (NSString *imageUrl in [self imagesOfRegexStrArray]) {
        NSArray *imageUrls = [imageUrl componentsSeparatedByString:@"'"];
        if (imageUrls.count >= 2) {
            NSString *imgName = imageUrls[1];
            CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks, (__bridge void *)(@(self.font.pointSize)));
            NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@"  "];//空格用于给图片留位置
            [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, 1)];
            CFRelease(runDelegate);
            //设置空格的属性
            [imageAttributedString addAttribute:SMLabel_IMAGE_NAME value:imgName range:NSMakeRange(0, 1)];
            
            //获取上一次图片检索的位置
            NSValue *lastValue = [ranges lastObject];
            long location = [lastValue rangeValue].location + ([lastValue rangeValue].length == 0 ? 0 : 1);
            //获取当前字符串在文本中的位置
            NSRange range = [[self.attrString string] rangeOfString:imageUrl  options:NSCaseInsensitiveSearch range:NSMakeRange(location, self.attrString.length - location)];
            //NSLog(@"lenght:%d",self.attrString.length);
            //把图片的字符串替换为（空格的属性字符串）
            [self.attrString replaceCharactersInRange:range withAttributedString:imageAttributedString];
            //NSLog(@"lenght:%d",self.attrString.length);
            NSValue *value = [NSValue valueWithRange:range];
            //添加到数组中
            [ranges addObject:value];
        }
        
    }
}

#pragma mark - CTRunDelegate delegate
void RunDelegateDeallocCallback(void *refCon) {
    
}
//设置空白区域的高度
CGFloat RunDelegateGetAscentCallback(void *refCon) {
    //NSString *imageName = (__bridge NSString *)refCon;
    return 0;//[UIImage imageNamed:imageName].size.height / 4;
}

CGFloat RunDelegateGetDescentCallback(void *refCon) {
    return 0;
}
//设置空白区域的宽度
CGFloat RunDelegateGetWidthCallback(void *refCon){
    //    NSString *imageName = (__bridge NSString *)refCon;
    //    return [UIImage imageNamed:imageName].size.width;
    NSNumber *fontSize = (__bridge NSNumber *)refCon;
    return [fontSize floatValue] * 1.0;
}
#pragma mark - 检索当前链接文本
//返回所有的链接字符串数组
- (NSArray *)contentsOfRegexStrArray
{
    //需要添加链接字符串正则表达：@用户、http://、#话题#
    NSString *regex = [self.delegate contentsOfRegexStringWithSMLabel:self];
    
    //通过正则表达式查找出匹配的字符串
    NSArray *matchArray = [SMLabel matchLinkWithStr:[self.attrString string] withMatchStr:regex];
//    NSLog(@"3----个数：%@",matchArray);
//    NSArray *matchArray = [[self.attrString string] componentsMatchedByRegex:regex];
    //@用户 ---> <a href='user://用户'>@用户</a>
    //http:// ---> <a href='http://wwww.iphonetrain.com'>http://wwww.iphonetrain.com</a>
    //#话题# -----> <a href='topic://话题'>#话题#</a>
    return matchArray;
}

//获取所有链接文字的位置
- (NSArray *)rangesOfContents:(NSArray *)contents
{
    if (_ranges == nil) {
        _ranges = [[NSMutableArray alloc]init];
    }
    [_ranges removeAllObjects];
    
    for (NSString *content in contents) {
        NSValue *lastValue = [_ranges lastObject];
        long location = [lastValue rangeValue].location + [lastValue rangeValue].length;
        //获取当前字符串在文本中的位置
        NSRange range = [[self.attrString string] rangeOfString:content options:NSCaseInsensitiveSearch range:NSMakeRange(location, self.attrString.length - location)];
        NSValue *value = [NSValue valueWithRange:range];
        //添加到数组中
        [_ranges addObject:value];
    }
    
    return _ranges;
}


#pragma mark - touch Action

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.movieStringRange = NSMakeRange(0, 0);
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    //获取当前选中字符的范围
    NSRange range = [self touchInLabelText:point];
    if (range.length == 0) {
        // 点击的是非超链接文本
        //        [super touchesEnded:touches withEvent:event];
        
        //NSLog(@"点击的不是超链接文本");
        
        if ([self.delegate respondsToSelector:@selector(toucheEndNoLinkSMLabel:)]) {
            [self.delegate toucheEndNoLinkSMLabel:self];
        }
    } else {
        //判断当前代理方法是否实现
        if ([self.delegate respondsToSelector:@selector(toucheEndSMLabel:withContext:)]) {
            //获取当前点击字符串
            NSString *context = [[self.attrString string] substringWithRange:range];
            //调用点击开始代理方法
            [self.delegate toucheEndSMLabel:self withContext:context];
        }
    }
    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    self.movieStringRange = NSMakeRange(0, 0);
}
//手指接触视图
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    //获取当前选中字符的范围
    NSRange range = [self touchInLabelText:point];
    self.movieStringRange = range;
    if (range.length == 0) {
        //        [super touchesBegan:touches withEvent:event];
    }else
    {
        //判断当前代理方法是否实现
        if ([self.delegate respondsToSelector:@selector(toucheBenginSMLabel:withContext:)]) {
            //获取当前点击字符串
            NSString *context = [[self.attrString string] substringWithRange:range];
            //调用点击开始代理方法
            [self.delegate toucheBenginSMLabel:self withContext:context];
        }
    }
    
}

// 想实现滑动效果
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    UITouch *touch = [touches anyObject];
    CGPoint point = [touch locationInView:self];
    //获取当前选中字符的范围
    NSRange range = [self touchInLabelText:point];
    self.movieStringRange = range;
}



#pragma mark - 检索当前点击的是否是链接文本
//检查当前点击的是否是连接文本,如果是返回文本的位置
- (NSRange)touchInLabelText:(CGPoint)point
{
    //获取当前的行高
    float lineHeight = self.lineHeight + self.linespace;
    
    int indexLine = point.y / lineHeight;
    //NSLog(@"indexLine:%d",indexLine);
    
    //如果当前行数大于最大行数
    if (indexLine >= _row.count) {
        return NSMakeRange(0, 0);
    }
    //如果当前行是最后一行and点击位置的横坐标大于当前行文本最大的位置
    if (indexLine == _row.count - 1 && point.x > _lastLineWidth) {
        return NSMakeRange(0, 0);
    }
    
    //如果点击在当前行文字的上方空白位置
    //    if (point.y <= indexLine *lineHeight + (asc+des+lead) * (_lineHeight - 1.0f)) {
    //        return NSMakeRange(0, 0);
    //    }
    
    
    //获取当前行
    CTLineRef selectLine = CFArrayGetValueAtIndex((__bridge CFArrayRef)_row, indexLine);
    CFIndex selectCharIndex = CTLineGetStringIndexForPosition(selectLine, point);
    
    
    //获取当前行结束字符位置
    CFIndex endIndex = CTLineGetStringIndexForPosition(selectLine, CGPointMake(self.frame.size.width-1, 1));
    
    
    //获取整段文字中charIndex位置的字符相对line的原点的x值
    CGFloat beginset;
    do {
        //获取当前选中字符距离起点位置
        CTLineGetOffsetForStringIndex(selectLine,selectCharIndex,&beginset);
        //判断当前字符的开始位置是否小于点击位置
        if (point.x >= beginset) {
            //判断当前字符是否为最后一个字符
            if (selectCharIndex == endIndex) {
                break;
            }
            //判断当前字符的结束位置是否大于点击位置
            CGFloat endset;
            CTLineGetOffsetForStringIndex(selectLine,selectCharIndex + 1,&endset);
            if (point.x <= endset) {
                break;
            }else
            {
                selectCharIndex++;
            }
        }else
        {
            selectCharIndex--;
        }
        
    } while (YES);
    
    //判断当前点击的位置是否在链接文本位置
    for (NSValue *value in _ranges) {
        NSRange range = [value rangeValue];
        if (range.location <= selectCharIndex && selectCharIndex + 1 <= range.location + range.length) {
            return range;
        }
    }
    
    
    return NSMakeRange(0, 0);
}

#pragma mark - 当前手指触摸文本
//复写当前选中的链接文本的索引
- (void)setMovieStringRange:(NSRange)movieStringRange
{
    if (_movieStringRange.location != movieStringRange.location || _movieStringRange.length != movieStringRange.length) {
        _movieStringRange = movieStringRange;
        [self setNeedsDisplay];
    }
}

// 自适应内容的高度
- (void)sm_sizeToFit
{
    // 获取当前内容文本的高度
    CGFloat height = [SMLabel sm_getStringHeightWithString:self.text
                                                     width:self.frame.size.width
                                                 linespace:self.linespace
                                                lineHeight:self.lineHeight
                                                      font:self.font
                                                  delegate:self.delegate];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
}


#pragma mark - 计算文本高度
#define kHeightDic @"kHeightDic"

/// 计算文本内容的高度
+ (CGFloat)sm_getStringHeightWithString:(NSString * _Nonnull)text
                                  width:(CGFloat) width
                              linespace:(CGFloat) linespace
                             lineHeight:(CGFloat) lineHeight
                                   font:(UIFont * _Nonnull)font
                               delegate:(id<SMLabelDelegate> _Nullable)delegate
{
    
    //生成属性字符串对象
    NSMutableAttributedString *attrString = [[NSMutableAttributedString alloc]initWithString:text];
    //设置图片属性字符串
    //为图片设置CTRunDelegate,delegate决定留给图片的空间大小
    CTRunDelegateCallbacks imageCallbacks;
    imageCallbacks.version = kCTRunDelegateVersion1;
    imageCallbacks.dealloc = RunDelegateDeallocCallback;
    imageCallbacks.getAscent = RunDelegateGetAscentCallback;
    imageCallbacks.getDescent = RunDelegateGetDescentCallback;
    imageCallbacks.getWidth = RunDelegateGetWidthCallback;
    
    //存放所有图片的索引位置
    NSMutableArray *ranges = [NSMutableArray array];
    NSString *regex = @"<image url = '[a-zA-Z0-9_\\.@%&\\S]*'>";
    if ([delegate respondsToSelector:@selector(imagesOfRegexStringWithSMLabel:)]) {
        regex = [delegate imagesOfRegexStringWithSMLabel:nil];
    }
    
    //通过正则表达式查找出匹配的字符串
    NSArray *matchArray = [SMLabel matchLinkWithStr:text withMatchStr:regex];
    //NSLog(@"1----个数：%@",matchArray);
//    NSArray *matchArray = [text componentsMatchedByRegex:regex];
    for (NSString *imageUrl in matchArray) {
        NSArray *imageUrls = [imageUrl componentsSeparatedByString:@"'"];
        if (imageUrls.count >= 2) {
            NSString *imgName = imageUrls[1];
            CTRunDelegateRef runDelegate = CTRunDelegateCreate(&imageCallbacks, (__bridge void *)(@(font.pointSize)));
            NSMutableAttributedString *imageAttributedString = [[NSMutableAttributedString alloc] initWithString:@"  "];//空格用于给图片留位置
            [imageAttributedString addAttribute:(NSString *)kCTRunDelegateAttributeName value:(__bridge id)runDelegate range:NSMakeRange(0, 1)];
            CFRelease(runDelegate);
            //设置空格的属性
            [imageAttributedString addAttribute:SMLabel_IMAGE_NAME value:imgName range:NSMakeRange(0, 1)];
            
            //获取上一次图片检索的位置
            NSValue *lastValue = [ranges lastObject];
            long location = [lastValue rangeValue].location + ([lastValue rangeValue].length == 0 ? 0 : 1);
            //获取当前字符串在文本中的位置
            NSRange range = [[attrString string] rangeOfString:imageUrl  options:NSCaseInsensitiveSearch range:NSMakeRange(location, attrString.length - location)];
            //NSLog(@"lenght:%d",self.attrString.length);
            //把图片的字符串替换为（空格的属性字符串）
            [attrString replaceCharactersInRange:range withAttributedString:imageAttributedString];
            //NSLog(@"lenght:%d",self.attrString.length);
            NSValue *value = [NSValue valueWithRange:range];
            //添加到数组中
            [ranges addObject:value];
        }
    }
    //------------------------设置字体属性--------------------------
    //    CTFontRef font = CTFontCreateWithName(CFSTR("Georgia"), 15, NULL);
    //设置当前字体
    [attrString addAttribute:(id)kCTFontAttributeName value:font range:NSMakeRange(0, attrString.length)];
    
    //------------------------设置段落属性-----------------------------
    //指定为对齐属性
    CTTextAlignment alignment = kCTJustifiedTextAlignment;
    CTParagraphStyleSetting alignmentStyle;
    alignmentStyle.spec=kCTParagraphStyleSpecifierFirstLineHeadIndent;//指定为对齐属性
    alignmentStyle.valueSize=sizeof(alignment);
    alignmentStyle.value=&alignment;
    
    
    //行距
    CTParagraphStyleSetting lineSpaceSetting;
    lineSpaceSetting.spec = kCTParagraphStyleSpecifierLineSpacingAdjustment;
    lineSpaceSetting.value = &linespace;
    lineSpaceSetting.valueSize = sizeof(linespace);
    
    //设置行高
    if (lineHeight < font.pointSize) {
        lineHeight = font.pointSize;
    }
    float minximumLineHeight = lineHeight;
    CTParagraphStyleSetting MinLineHeight;
    MinLineHeight.spec = kCTParagraphStyleSpecifierMinimumLineHeight;
    MinLineHeight.value = &minximumLineHeight;
    MinLineHeight.valueSize = sizeof(float);
    
    float maximumLineHeight = lineHeight;
    CTParagraphStyleSetting MaxLineHeight;
    MaxLineHeight.spec = kCTParagraphStyleSpecifierMaximumLineHeight;
    MaxLineHeight.value = &maximumLineHeight;
    MaxLineHeight.valueSize = sizeof(float);
    
    //换行模式
    CTParagraphStyleSetting lineBreakMode;
    CTLineBreakMode lineBreak = kCTLineBreakByCharWrapping;
    lineBreakMode.spec = kCTParagraphStyleSpecifierLineBreakMode;
    lineBreakMode.value = &lineBreak;
    lineBreakMode.valueSize = sizeof(CTLineBreakMode);
    
    //组合设置
    CTParagraphStyleSetting settings[] = {
        lineSpaceSetting,MinLineHeight,MaxLineHeight,alignmentStyle,lineBreakMode
    };
    
    //通过设置项产生段落样式对象
    CTParagraphStyleRef style = CTParagraphStyleCreate(settings, 5);
    
    // build attributes
    NSMutableDictionary *attributes = [NSMutableDictionary dictionaryWithObject:(__bridge id)style forKey:(id)kCTParagraphStyleAttributeName ];
    
    // set attributes to attributed string
    [attrString addAttributes:attributes range:NSMakeRange(0, attrString.length)];
    
    
    //生成CTFramesetterRef对象
    CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attrString);
    CGRect drawingRect = CGRectMake(0, 0, width, kSMLabel_MAXHEIGHT);  //这里的高要设置足够大
    
    //然后创建一个CGPath对象，这个Path对象用于表示可绘制区域坐标值、长宽。
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, drawingRect);
    
    
    CTFrameRef textFrame = CTFramesetterCreateFrame(framesetter,CFRangeMake(0,0), path, NULL);
    CGPathRelease(path);
    CFRelease(framesetter);
    
    NSArray *linesArray = (NSArray *) CTFrameGetLines(textFrame);
    return linesArray.count * lineHeight + (linesArray.count - 1) * (linespace);
    
    /*
     CGPoint origins[[linesArray count]];
     
     CTFrameGetLineOrigins(textFrame, CFRangeMake(0, 0), origins);
     
     int line_y = (int) origins[[linesArray count] -1].y;  //最后一行line的原点y坐标
     
     CGFloat ascent;
     CGFloat descent;
     CGFloat leading;
     
     CTLineRef line = (__bridge CTLineRef) [linesArray objectAtIndex:[linesArray count]-1];
     CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
     
     total_height = kSMLabel_MAXHEIGHT - line_y + (int) descent + 1;    //+1为了纠正descent转换成int小数点后舍去的值
     
     CFRelease(textFrame);
     
     return total_height;
     */
    
}

#pragma mark - 正则表达式
+ (NSMutableArray *)matchLinkWithStr:(NSString *)str withMatchStr:(NSString *)matchRegex;
{
    NSError *error = NULL;
    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:matchRegex
                                                                         options:NSRegularExpressionCaseInsensitive
                                                                           error:&error];
    NSArray *match = [reg matchesInString:str
                                  options:NSMatchingReportCompletion
                                    range:NSMakeRange(0, [str length])];
    
    NSMutableArray *mulArr = [NSMutableArray array];
    // 取得所有的NSRange对象
    if(match.count != 0)
    {
        for (NSTextCheckingResult *matc in match)
        {
            NSRange range = [matc range];
            [mulArr addObject:[str substringWithRange:range]];
        }
    }
    return mulArr;
}





@end
