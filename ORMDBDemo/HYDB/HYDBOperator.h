//
//  HYDBOperator.h
//  Imora
//
//  Created by huyong on 19/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HYBaseModel.h"

#define LIMITNUMBER 15

#define ORACURRENTUSERID @"currentUserId"

#define kDocumentsDirectory \
([NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0])

// 数据库路径
#define CONTACTPATH                                                                     \
                [ kDocumentsDirectory\
                stringByAppendingFormat:@"/%@/HyData.db",                                      \
                [[NSUserDefaults standardUserDefaults] objectForKey:ORACURRENTUSERID]]

@interface OraDBModelPropertiesCache : NSObject
+ (NSDictionary *)allProperties:(Class)className;
@end
@interface HYDBOperator : NSObject

+ (HYDBOperator *)shareManager;
+ (void)setPath:(NSString *)path;
+ (BOOL)DBFileExists;
/**
 *  初始化数据库对象
 *
 *  @param path 数据库路径
 *
 *  @return 数据库操作员 DBOperator
 */
- (instancetype)initWithPath:(NSString *)path;

- (BOOL)createTable:(NSString *)sql;

/**
 *  关闭数据库
 */
- (void)close;

//执行批量sql命令
- (BOOL)executeSQLs:(NSString *)sql;
- (BOOL)executeSqlsInTransaction:(NSArray *)sqls;

//加载数据,每行回调一次
- (void)loadData:(NSString *)sql param:(NSArray *)array callback:(void (^)(NSDictionary *data))callback;
//加载数据，返回所有数据
- (NSArray *)loadData:(NSString *)sql param:(NSArray *)array;
//返回单个数据
- (id)loadSingleData:(NSString *)sql param:(NSArray *)array;
//加载数据到model
- (NSArray *)loadData:(Class)c sql:(NSString *)sql param:(NSArray *)array;


//保存数据
- (BOOL)saveData:(NSString *)sql;
//保存数据
- (BOOL)saveData:(NSString *)sql param:(NSArray *)array;
//批量保存数据
- (BOOL)saveData:(NSString *)sql fetchData:(NSArray * (^)(int))fetchData;


//新增models
- (BOOL)insertData:(HYBaseModel *)data;
//更新models
- (BOOL)updateData:(HYBaseModel *)data dependOnKeys:(NSArray *)keys;
//删除models
- (BOOL)deleteData:(HYBaseModel *)data dependOnKeys:(NSArray *)keys;
- (void)batchInsertData:(NSArray *)dataArray;


// 获取当前Model的类名
- (NSString *)tableNameForModel:(HYBaseModel *)model;


// 根据条件查询数据库
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition;
// 提供分页查询功能
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition
                               andpage:(int)pageindex
                            andOrderby:(NSString *)orderBy
                               isAscen:(BOOL)isAscen;
// 提供条件+模糊匹配查询功能
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition andLike:(NSString *)itemName;

// 提供条件+模糊匹配查询功能
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition orLike:(NSArray *)itemNames;
@end
