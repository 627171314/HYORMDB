//
//  HYDBManager.h
//  Imora
//
//  Created by huyong on 19/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYDBOperator.h"
#import "HYBaseModel.h"

@interface HYDBManager : NSObject

/**
 *  数据库升级可能用到的一系列方法
 *
 */
+ (BOOL)createTableWithModel:(Class)className;
+ (BOOL)updateTableWithModel:(Class)className;
+ (BOOL)updateTableWithModelByModifyTable:(Class)className;
+ (BOOL)dropTable:(Class)className;
+ (NSArray *)loadAllTableNames;
+ (NSMutableArray *)loadTableColumns:(Class)className;

/**
 *  将model储存到数据库
 *  @return 执行结果
 */
+ (BOOL)insertModelIntoTable:(HYBaseModel *)model;

/**
 *  将model从本地数据库删除
 *  keys   是根据哪些参数来删除 如果传nil 则会根据pid参数来删除
 *  @return 执行结果
 */

+ (BOOL)deleteContact:(HYBaseModel *)model dependOnKeys:(NSArray *)keys;

/**
 *  将model更新到数据库
 *  keys   是根据哪些参数来更新 如果传nil 则会根据pid来更新
 *  @return 执行结果
 */

+ (BOOL)updateContact:(HYBaseModel *)model dependOnKeys:(NSArray *)keys;

/**
 *  执行sql
 *
 *  @param sql sql
 *
 *  @return 成功与否
 */
+ (BOOL)executeSQLs:(NSString *)sql;
+ (NSArray *)executeSearchSQLs:(NSString *)sql;
/**
 *  查询
 *
 *  @param class       类对象
 *
 *  @return 查询结果
 */
+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition;

/**
 *  分页查询并排序
 *
 *  @param calss       类对象
 *  @param pageindex 分页
 *  @param orderBy   排序字段
 *  @param isAscen   升/降序
 *
 *  @return 查询结果
 */
+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition
                               andpage:(int)pageindex
                            andOrderby:(NSString *)orderBy
                               isAscen:(BOOL)isAscen;

/**
 *  模糊查询
 *
 *  @param class       类对象
 *  @param itemName  模糊字段
 *
 *  @return 查询结果
 */
+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition andLike:(NSString *)itemName;

/**
 *  模糊查询
 *
 *  @param cls       类对象
 *  @param itemName  模糊字段
 *
 *  @return 查询结果
 */
+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition orLike:(NSArray *)itemNames;

@end
