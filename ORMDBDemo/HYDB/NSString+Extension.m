//
//  NSString+Extension.m
//  Imora
//
//  Created by huyong on 20/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <CommonCrypto/CommonDigest.h>
#import "NSString+Extension.h"

@implementation NSString (hy_Characters)

- (NSString *)hy_pinyinOfName {
    NSMutableString *name = [[NSMutableString alloc] initWithString:self];

    CFRange range = CFRangeMake(0, 1);

    // 汉字转换为拼音,并去除音调
    if (!CFStringTransform((__bridge CFMutableStringRef)name, &range, kCFStringTransformMandarinLatin, NO) ||
        !CFStringTransform((__bridge CFMutableStringRef)name, &range, kCFStringTransformStripDiacritics, NO)) {
        return @"";
    }

    return name;
}

- (NSString *)hy_firstCharacterOfName {
    NSMutableString *first = [[NSMutableString alloc] initWithString:[self substringWithRange:NSMakeRange(0, 1)]];

    CFRange range = CFRangeMake(0, 1);

    // 汉字转换为拼音,并去除音调
    if (!CFStringTransform((__bridge CFMutableStringRef)first, &range, kCFStringTransformMandarinLatin, NO) ||
        !CFStringTransform((__bridge CFMutableStringRef)first, &range, kCFStringTransformStripDiacritics, NO)) {
        return @"";
    }

    NSString *result;
    result = [first substringWithRange:NSMakeRange(0, 1)];

    return result.uppercaseString;
}

- (BOOL)hy_containChinese {
    NSUInteger length = self.length;
    if (0 == length) {
        return NO;
    }
    for (int i = 0; i < length; i++) {
        const char *cstring = [[self substringWithRange:NSMakeRange(i, 1)] UTF8String];
        if (3 == strlen(cstring)) {
            return YES;
        }
    }
    return NO;
}

@end

@implementation NSString (hy_Kit)

- (NSString *)hy_MD5 {
    const char *cStr = [self UTF8String];
    unsigned char result[32];
    CC_MD5(cStr, (CC_LONG)strlen(cStr), result);

    return [NSString stringWithFormat:@"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", result[0],
                                      result[1], result[2], result[3], result[4], result[5], result[6], result[7],
                                      result[8], result[9], result[10], result[11], result[12], result[13], result[14],
                                      result[15]];
}

+ (NSString *)hy_UUID {
    CFUUIDRef uuid_ref = CFUUIDCreate(NULL);

    CFStringRef uuid_string_ref = CFUUIDCreateString(NULL, uuid_ref);

    CFRelease(uuid_ref);

    NSString *uuid = [NSString stringWithString:(__bridge NSString *)uuid_string_ref];

    CFRelease(uuid_string_ref);

    return uuid;
}
+ (BOOL)hy_isBlankString:(NSString *)string {
    if (string == nil) {
        return YES;
    }
    if (![string isKindOfClass:[NSString class]]) {
        return YES;
    }

    if (string == NULL) {
        return YES;
    }

    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }

    if ([[string hy_trim] length] == 0) {
        return YES;
    }

    return NO;
}

- (NSString *)hy_trim {
    NSString *result = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return result;
}

- (NSString *)hy_trimOnlyWhitespace {
    NSString *result = [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    return result;
}

- (BOOL)hy_isIncludeChinese {
    for (int i = 0; i < self.length; i++) {
        unichar ch = [self characterAtIndex:i];
        if (0x4e00 < ch && ch < 0x9fff) {
            return true;
        }
    }
    return false;
}

- (NSArray *)hy_splitUsingWhitespace {
    NSString *str = [self hy_trimOnlyWhitespace];
    NSArray *array = [str componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    array = [array filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF != ''"]];
    return array;
}

- (BOOL)hy_isVaildPhoneNumber {
    NSString *phoneRegex = @"^1(3[0-9]|4[0-9]|5[0-9]|7[0-9]|8[0-9])\\d{8}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", phoneRegex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)hy_isVaildQQ {
    NSString *qqRegex = @"^[1-9]\\d{4,9}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", qqRegex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)hy_isVaildURL {
    NSString *lowercaseString = self.lowercaseString;
    NSString *urlRegex = @"^(((ht|f)tp(s?))\\://"
                         @")?(www.|[a-zA-Z].)[a-zA-Z0-9\\-\\.]+\\.(cn|com|edu|gov|mil|net|org|biz|info|name|museum|us|ca|"
                         @"uk)(\\:[0-9]+)*(/($|[a-zA-Z0-9\\.\\,\\;\\?\\'\\\\\\+&amp;%\\$#\\=~_\\-]+))*$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegex];
    return [predicate evaluateWithObject:lowercaseString];
}

- (BOOL)hy_isVaildFax {
//    NSString *urlRegex = @"^((\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|"
//                         @"\\d{1})|(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1}))$";
    NSString *urlRegex = @"^[0-9*#+,;]{7,32}$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)hy_isVaildPhone {
//    NSString *urlRegex = @"^((\\d{7,8})|(\\d{11,12})|(\\d{4}|\\d{3})-(\\d{7,8})|(\\d{4}|\\d{3})-(\\d{7,8})-(\\d{4}|\\d{"
//                         @"3}|\\d{2}|\\d{1})|(\\d{7,8})-(\\d{4}|\\d{3}|\\d{2}|\\d{1}))$";
    NSString *urlRegex = @"^[0-9*#+,;]{7,32}$";

    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegex];
    return [predicate evaluateWithObject:self];
}

- (BOOL)hy_isVaildEmail {
    NSString *lowercaseString = self.lowercaseString;
    NSString *urlRegex = @"^[a-zA-Z0-9_-]+@[a-zA-Z0-9_-]+(\\.[a-zA-Z0-9_-]+)+$";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", urlRegex];
    return [predicate evaluateWithObject:lowercaseString];
}

- (NSString *)hy_removeDigit {
    if ([NSString hy_isBlankString:self]) {
        return self;
    }
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:@"[0-9]" options:0 error:NULL];
    return [regular stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@""];
}

- (NSString *)hy_removeExtendName {
    NSString *fileName = self;  //文件名
    NSRange range = [self rangeOfString:@"." options:NSBackwardsSearch];
    if (range.length > 0) {
        fileName = [self substringToIndex:(NSMaxRange(range) - 1)];
    };
    return fileName;
}

- (NSString *)hy_removeWord {
    if ([NSString hy_isBlankString:self]) {
        return self;
    }
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:@"[a-zA-Z]" options:0 error:NULL];
    return [regular stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@""];
}

@end

@implementation NSString (hy_Size)

- (CGSize)hy_sizeWithFont:(UIFont *)font {
    if ([self length] == 0) {
        return CGSizeZero;
    }

    return [self sizeWithAttributes:@{NSFontAttributeName : font}];
}

- (CGSize)hy_sizeWithLimitSize:(CGSize)size font:(UIFont *)font {
    if ([self length] == 0) {
        return CGSizeZero;
    }

    CGRect rect = [self boundingRectWithSize:size
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{
                                      NSFontAttributeName : font
                                  }
                                     context:nil];
    return rect.size;
}

- (CGFloat)hy_heightWithWidth:(CGFloat)width font:(UIFont *)font {
    return [self hy_sizeWithLimitSize:CGSizeMake(width, MAXFLOAT) font:font].height;
}

@end

@implementation NSString (hy_AutoUTF8Data)

- (NSData *)hy_UTF8Data {
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}

@end
@implementation NSString (hy_chineseToPinyin)
- (NSString *)pinyin {
    NSMutableString *pinyin = [self mutableCopy];
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformMandarinLatin, NO);
    CFStringTransform((__bridge CFMutableStringRef)pinyin, NULL, kCFStringTransformStripCombiningMarks, NO);
    return [pinyin uppercaseString].lowercaseString;
}
- (NSArray<NSString *> *)pinyinArray {
    NSMutableArray *results = [NSMutableArray arrayWithCapacity:self.length];
    for (NSInteger index = 0; index < self.length; index++) {
        NSString *subString = [self substringWithRange:NSMakeRange(index, 1)];
        NSString *pinyin = [subString pinyin];
        if ([NSString hy_isBlankString:pinyin]) {
            [results addObject:subString];
        } else {
            [results addObject:pinyin];
        }
    }
    return results;
}
- (NSArray<NSString *> *)pinyinArraySegmentation;{
    NSMutableArray*resluts = [NSMutableArray new];
    [self enumerateSubstringsInRange:NSMakeRange(0, self.length) options:NSStringEnumerationByWords usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
        if([self IsChinese:substring]){
            for (NSInteger index = 0; index < substring.length; index++) {
                NSString *itemString = [substring substringWithRange:NSMakeRange(index, 1)];
                NSString *pinyin = [itemString pinyin];
                if ([NSString hy_isBlankString:pinyin]) {
                    [resluts addObject:itemString];
                } else {
                    [resluts addObject:pinyin];
                }
            }
        }else{
            [resluts addObject:substring.lowercaseString];
        }
    }];
    return resluts;
}
-(BOOL)IsChinese:(NSString *)str {
    for(int i=0; i< [str length];i++){
        int a = [str characterAtIndex:i];
        if( a > 0x4e00 && a < 0x9fff)
        {
            return YES;
        }
    }
    return NO;
    
}
@end
