//
//  HYBaseModel.h
//  Imora
//
//  Created by huyong on 17/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MJExtension.h"
#import "NSString+Extension.h"

#define kModelPrimary @"pid"

@interface HYBaseModel : NSObject

@property(nonatomic, copy) NSString *pid;

/**
 *  将模型转成字典
 *  @return 字典
 */
- (NSMutableDictionary *)hy_TransToDictionary;
/**
 *  将模型转成字典
 keys  内容是，希望转为json的属性的名称组成的数组
 *  @return 字典
 */
- (NSMutableDictionary *)hy_TransToDictionaryWithKeys:(NSArray *)keys;
/**
 *  将模型转成字典
 ignoredKeys  内容是，希望不被转为json的属性的名称组成的数组
 *  @return 字典
 */
- (NSMutableDictionary *)hy_TransToDictionaryWithIgnoredKeys:(NSArray *)ignoredKeys;
/**
 *  将字典的键值对转成模型属性
 *  @param keyValues 字典(可以是NSDictionary、NSData、NSString)
 */
- (instancetype)hy_loadDataFromkeyValues:(id)keyValues;

/**
 *  将model储存到数据库
 *  @return 执行结果
 */
- (BOOL)hy_insertToDB;
/**
 *  将model更新到数据库
 *  keys   是根据哪些参数来更新 如果传nil 则会根据ID来更新
 *  @return 执行结果
 */
- (BOOL)hy_updateToDB;

- (BOOL)save;
- (BOOL)remove;

/**
 *  将model从本地数据库删除
 *  keys   是根据哪些参数来删除 如果传nil 则会根据所有参数来删除
 *  @return 执行结果
 */
- (BOOL)hy_removeFromDB;
/**
 *  查询数据库，将查询条件赋值给此model，所有的赋值的属性，都会作为查询条件
 *  @return 返回值是查询结果数组
 */

- (NSArray *)hy_getDBModel;

- (id)hy_getDBFirstModel;
/** !!!!!!!!!!!!
 *  所有忽略保存至数据库的属性都需要在该方法中指出，
 *  在该方法中返回的属性，在存DB和转字典时都会被忽略
 *  @return 不需要保存至数据库的方法
 */
+ (NSMutableArray *)mj_ignoredPropertyNames;
/**
 *  如果model的属性名称存在于json内对应的键不匹配时，此函数更换key值，具体实现参考.m文件实现
 */
+ (NSDictionary *)mj_replacedKeyFromPropertyName;
#pragma mark - 对象的属性中包含数组，数组的内容是多个对象
/**
 *  return @{
 @"statuses" : @"Status",
 @"ads" : @"Ad"
 };
 statuses 和 ads 是属性名称，Status和Ad 是类的名字
 */

+ (NSDictionary *)mj_objectClassInArray;

//按照keys删除数据 model中存值
+ (BOOL)hy_removeFromDBWithModel:(HYBaseModel *)model dependOnKeys:(NSArray *)keys;
//按照keys更新数据 model中存值
+ (BOOL)hy_updateToDBWithModel:(HYBaseModel *)model dependOnKeys:(NSArray *)key;

@end
