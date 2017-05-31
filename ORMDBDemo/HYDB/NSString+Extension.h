//
//  NSString+Extension.h
//  Imora
//
//  Created by huyong on 20/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface NSString (hy_Characters)

#pragma mark - Category(hy_Characters)

//汉字转换为拼音
- (NSString *)hy_pinyinOfName;

//汉字转换为拼音后，返回大写的首字母
- (NSString *)hy_firstCharacterOfName;

// 是否包含中文字符
- (BOOL)hy_containChinese;

-(BOOL)IsChinese:(NSString *)str;

@end

@interface NSString (hy_Kit)

#pragma mark - Category(hy_Kit)
/*
 忽略大小写
 */
/**
 *  @brief  转换成MD5字符串
 *
 *  @return MD5字符串
 */
- (NSString *)hy_MD5;

/**
 *  @brief  生成UUID
 *
 *  @return UUID字符串
 */
+ (NSString *)hy_UUID;

/**
 *  @brief  去除两端空格和回车
 *
 *  @return 去除后的字符串
 */
- (NSString *)hy_trim;

/**
 *  @brief  仅去除两端空格
 *
 *  @return 去除后的字符串
 */
- (NSString *)hy_trimOnlyWhitespace;

/**
 *  @brief  是否包含中文
 *
 *  @return YES/NO
 */
- (BOOL)hy_isIncludeChinese;

/**
 *  @brief  是否为空字符串
 *
 *  @return YES/NO
 */
+ (BOOL)hy_isBlankString:(NSString *)string;

/**
 *  @brief  空格分割字符串
 *
 *  @return 字符串数据
 */
- (NSArray *)hy_splitUsingWhitespace;

/**
 *  @brief  是否是合法的手机号码
 *
 *  @return 如果是合法的手机号码则返回YES；否则返回NO
 */
- (BOOL)hy_isVaildPhoneNumber;

/**
 *  @brief  判断是否是合法的QQ号码
 *
 *  @return 如果是合法的QQ号码，则返回YES；否则返回NO
 */
- (BOOL)hy_isVaildQQ;

/**
 *  @brief  判断是否是合法URL
 *
 *  @return 如果是合法的URL，则返回YES；否则返回NO
 */
- (BOOL)hy_isVaildURL;

/**
 *  @brief  判断是否是合法传真
 *
 *  @return 如果是合法的传真，则返回YES；否则返回NO
 */
- (BOOL)hy_isVaildFax;

/**
 *  @brief  判断是否是合法电话
 *
 *  @return 如果是合法的电话，则返回YES；否则返回NO
 */
- (BOOL)hy_isVaildPhone;

/**
 *  @brief  判断是否是合法电话
 *
 *  @return 如果是合法的电话，则返回YES；否则返回NO
 */
- (BOOL)hy_isVaildEmail;

/**
 *  @brief  去除字符串中的数字
 *
 *  @return 去除数字的字符串
 */
- (NSString *)hy_removeDigit;

/**
 *  @brief  去除文件扩展名
 *
 *  @return  去除文件扩展名的字符串
 */
- (NSString *)hy_removeExtendName;

/**
 *  @brief  去除带数字的单词中的英文字符
 *
 *  @return 数字
 */
- (NSString *)hy_removeWord;
@end

@interface NSString (hy_Size)

#pragma mark - Category(hy_Size)

/**
 *  @brief  获取要显示该文本的所需要的size
 *
 *  @param font 字体
 *
 *  @return 要显示文本所需size
 */
- (CGSize)hy_sizeWithFont:(UIFont *)font;

/**
 *  @brief 获取要显示该文本的所需要的size
 *
 *  @param size 限定大小，即返回的size不会超过这个所限定的大小
 *  @param font 字体
 *
 *  @return 要显示文本所需size
 */
- (CGSize)hy_sizeWithLimitSize:(CGSize)size font:(UIFont *)font;

/**
 *  @brief  获取要显示文本的所需的高度
 *
 *  @param width 限定的宽度
 *  @param font  字体
 *
 *  @return 文本所需高度
 */
- (CGFloat)hy_heightWithWidth:(CGFloat)width font:(UIFont *)font;

@end

#pragma mark - Category(hy_AutoUTF8Data)
@interface NSString (hy_AutoUTF8Data)
/**
 *  获取string的utf8编码的nsdata
 *
 *  @return data
 */
- (NSData *)hy_UTF8Data;
@end

@interface NSString (hy_chineseToPinyin)
- (NSString *)pinyin;
- (NSArray<NSString *> *)pinyinArray;
- (NSArray<NSString *> *)pinyinArraySegmentation;
@end
