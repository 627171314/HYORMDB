//
//  HYDBManager.m
//  Imora
//
//  Created by huyong on 19/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import "HYDBManager.h"

@implementation HYDBManager

+ (BOOL)createTableWithModel:(Class)className {
    Class class = className;
    NSMutableString *createSql = [NSMutableString new];
    HYDBOperator *operator= [HYDBOperator shareManager];
    NSString *tableName = NSStringFromClass(class);
    [createSql appendFormat:@"create table if not exists %@ (", tableName];
    [createSql appendFormat:@"%@ VARCHAR primary key, ", kModelPrimary];

    NSArray *ignoredPropertyNames = [class mj_totalIgnoredPropertyNames];

    while (class && ![[NSString stringWithUTF8String:object_getClassName(class)] isEqualToString:@"NSObject"]) {
        unsigned int numberOfIvars = 0;
        //获取class 类成员变量列表
        objc_property_t *ivars = class_copyPropertyList(class, &numberOfIvars);
        //采用指针+1 来获取下一个变量
        for (const objc_property_t *p = ivars; p < ivars + numberOfIvars; p++) {
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(*p)];
            // 如果是忽略字段则不创建
            if (ignoredPropertyNames && [ignoredPropertyNames containsObject:propertyName]) continue;

            if (![propertyName isEqualToString:kModelPrimary]) {
                NSString *propertyType = [NSString stringWithUTF8String:property_getAttributes(*p)];

                if ([propertyType rangeOfString:@"NSString"].location != NSNotFound) {
                    [createSql appendFormat:@" %@ VARCHAR ,", propertyName];

                } else if ([propertyType rangeOfString:@"NSURL"].location != NSNotFound) {
                    [createSql appendFormat:@" %@ VARCHAR ,", propertyName];

                } else if ([propertyType rangeOfString:@"NSNumber"].location != NSNotFound) {
                    [createSql appendFormat:@" %@ VARCHAR ,", propertyName];

                } else if ([propertyType rangeOfString:@"NSDate"].location != NSNotFound) {
                    [createSql appendFormat:@" %@ VARCHAR ,", propertyName];
                } else {
                    NSLog(@"%@ 的 %@ 属性(类型:%@)已在建表时自动忽略 ", tableName, propertyName,
                               [propertyType
                                   substringWithRange:NSMakeRange(3, [propertyType rangeOfString:@","].location - 4)]);
                }
            }
        }

        free(ivars);
        class = class_getSuperclass(class);
    }

    NSRange range = NSMakeRange(createSql.length - 1, 1);
    [createSql deleteCharactersInRange:range];  // 删除最后一个逗号","

    [createSql appendFormat:@" )"];

    BOOL isSuccess = [operator createTable:createSql];
    if (!isSuccess) {
        NSLog(@"== %@ 表创建失败 ==", tableName);
    } else {
        NSLog(@"== %@ 表创建成功 ==", tableName);
    }

    return isSuccess;
}

+ (BOOL)updateTableWithModelByModifyTable:(Class)className {
    Class tempClass = className;
    NSMutableArray *oldColumns = [self loadTableColumns:tempClass];

    NSMutableArray *currentColumns = [NSMutableArray array];
    NSArray *ignoredPropertyNames = [tempClass mj_totalIgnoredPropertyNames];
    while (tempClass && ![[NSString stringWithUTF8String:object_getClassName(tempClass)] isEqualToString:@"NSObject"]) {
        unsigned int numberOfIvars = 0;
        //获取class 类成员变量列表
        objc_property_t *ivars = class_copyPropertyList(tempClass, &numberOfIvars);
        //采用指针+1 来获取下一个变量
        for (const objc_property_t *p = ivars; p < ivars + numberOfIvars; p++) {
            NSString *propertyName = [NSString stringWithUTF8String:property_getName(*p)];
            // 如果是忽略字段则不创建
            if (ignoredPropertyNames && [ignoredPropertyNames containsObject:propertyName]) continue;

            NSString *propertyType = [NSString stringWithUTF8String:property_getAttributes(*p)];

            if ([propertyType rangeOfString:@"NSString"].location != NSNotFound) {
                [currentColumns addObject:propertyName];

            } else if ([propertyType rangeOfString:@"NSURL"].location != NSNotFound) {
                [currentColumns addObject:propertyName];

            } else if ([propertyType rangeOfString:@"NSNumber"].location != NSNotFound) {
                [currentColumns addObject:propertyName];

            } else if ([propertyType rangeOfString:@"NSDate"].location != NSNotFound) {
                [currentColumns addObject:propertyName];
            } else {
                NSLog(
                    @"%@ 的 %@ 属性(类型:%@)已在升级表时自动忽略 ", NSStringFromClass(tempClass), propertyName,
                    [propertyType substringWithRange:NSMakeRange(3, [propertyType rangeOfString:@","].location - 4)]);
            }
        }

        free(ivars);
        tempClass = class_getSuperclass(tempClass);
    }

    BOOL shouldRemoveColumn = NO;
    // 判断是否需要删除废弃字段
    for (NSString *deleteColumn in oldColumns) {
        if (![currentColumns containsObject:deleteColumn]) {
            shouldRemoveColumn = YES;
            break;
        }
    }

    if (shouldRemoveColumn) {
        NSLog(@"%@ 表删除了字段需要通过新建表来升级", NSStringFromClass(className));
        return [self updateTableWithModel:className]; /* 由于SQLite不支持删除column操作,所以只能通过新建表来升级 */

    } else {
        // 创建添加新增字段sql
        NSMutableArray *addColumnArray = [NSMutableArray array];
        NSMutableArray *newColumns = [NSMutableArray array];
        for (NSString *columnName in currentColumns) {
            if (![oldColumns containsObject:columnName]) {
                NSString *addColumnSql = [NSString stringWithFormat:@"alter table %@  add column %@ VARCHAR ",
                                                                    NSStringFromClass(className), columnName];
                [addColumnArray addObject:addColumnSql];
                [newColumns addObject:columnName];
            }
        }

        // 判断是否需要新增字段
        if ([addColumnArray count]) {
            HYDBOperator *operator= [HYDBOperator shareManager];
            NSLog(@"%@ 表升级成功,新增字段:%@", className, [newColumns componentsJoinedByString:@","]);
            return [operator executeSqlsInTransaction:addColumnArray];
        } else {
            NSLog(@"%@ 表没有结构变化,不需要升级表结构。", NSStringFromClass(className));
        }
    }

    return YES;
}

+ (BOOL)updateTableWithModel:(Class)className {
    NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
    BOOL result = NO;
    // 第一步创建临时表
    NSString *runTimeClassName = [NSString stringWithFormat:@"Temp_%@", NSStringFromClass(className)];
    const char *temp = [runTimeClassName cStringUsingEncoding:NSASCIIStringEncoding];
    Class tempClass = objc_allocateClassPair(className, temp, 0);
    result = [self createTableWithModel:tempClass];
    if (!result) {
        return result;
    }

    // 第二步将旧表数据全部移入临时表
    HYDBOperator *operator= [HYDBOperator shareManager];
    NSTimeInterval queryStart = [NSDate timeIntervalSinceReferenceDate];
    NSArray *allData = [operator loadData:tempClass sql:[NSString stringWithFormat:@"select * from %@",NSStringFromClass(className)] param:nil];
    NSLog(@"查询所有数据用时:%f", [NSDate timeIntervalSinceReferenceDate] - queryStart);
    if (allData && [allData count]) {
        NSTimeInterval batchStart = [NSDate timeIntervalSinceReferenceDate];
         [operator batchInsertData:allData];
         NSLog(@"批量插入耗时:%f", [NSDate timeIntervalSinceReferenceDate] - batchStart);
         allData = nil;
    }

    // 第三步删除旧表
    result = [operator executeSQLs:[NSString stringWithFormat:@"drop table %@ ", NSStringFromClass(className)]];
    if (!result) {
        return result;
    }

    // 第四步将临时表重命名
    result = [operator executeSQLs:[NSString stringWithFormat:@"alter table %@ rename to %@ ",NSStringFromClass(tempClass),NSStringFromClass(className)]];
    if (!result) {
        return result;
    }

    NSLog(@"%@表升级耗时:%lf", NSStringFromClass(className), [NSDate timeIntervalSinceReferenceDate] - start);
    return result;
}

+ (BOOL)dropTable:(Class)className {
    HYDBOperator *operator= [HYDBOperator shareManager];
    BOOL result = [operator executeSQLs:[NSString stringWithFormat:@"drop table %@ ", NSStringFromClass(className)]];
    if (result) {
        NSLog(@"%@ 表在升级时成功删除", NSStringFromClass(className));
    } else {
        NSLog(@"%@ 表在升级时删除失败", NSStringFromClass(className));
    }
    return result;
}

+ (NSMutableArray *)loadTableColumns:(Class)className {
    NSString *tableName = NSStringFromClass(className);
    NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)", tableName];
    HYDBOperator *operator= [HYDBOperator shareManager];
    NSArray *columns = [operator loadData:sql param:nil];
    NSMutableArray *columnList = [NSMutableArray array];
    for (id dic in columns) {
        [columnList addObject:[dic objectForKey:@"name"]];
    }

    return columnList;
}

+ (NSArray *)loadAllTableNames {
    NSString *sql = @"select name from sqlite_master where type='table' order by name";
    HYDBOperator *operator= [HYDBOperator shareManager];
    NSArray *tableNames = [operator loadData:sql param:nil];
    return tableNames;
}

+ (BOOL)insertModelIntoTable:(HYBaseModel *)model {
    if (nil == model) {
        return NO;
    }
    if (![model valueForKey:kModelPrimary]) {
        model.pid = [NSString hy_UUID];
    }
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator insertData:model];
}

+ (BOOL)deleteContact:(HYBaseModel *)model dependOnKeys:(NSArray *)keys {
    if (nil == model) {
        return NO;
    }
    if (!keys || 0 == keys.count) {
        keys = [NSArray arrayWithObject:kModelPrimary];
    }

    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator deleteData:model dependOnKeys:keys];
}

+ (BOOL)updateContact:(HYBaseModel *)model dependOnKeys:(NSArray *)keys {
    if (nil == model) {
        return NO;
    }
    if (!keys || 0 == keys.count) {
        keys = [NSArray arrayWithObject:kModelPrimary];
    }
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator updateData:model dependOnKeys:keys];
}
+ (NSArray *)executeSearchSQLs:(NSString *)sql {
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator loadData:sql param:nil];
}

+ (BOOL)executeSQLs:(NSString *)sql {
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator executeSQLs:sql];
}

+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition {
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator searchModelsWithCondition:condition];
}

+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition
                               andpage:(int)pageindex
                            andOrderby:(NSString *)orderBy
                               isAscen:(BOOL)isAscen {
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator searchModelsWithCondition:condition andpage:pageindex andOrderby:orderBy isAscen:isAscen];
}

+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition andLike:(NSString *)itemName {
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator searchModelsWithCondition:condition andLike:itemName];
}

+ (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition orLike:(NSArray *)itemNames {
    HYDBOperator *operator= [HYDBOperator shareManager];
    return [operator searchModelsWithCondition:condition orLike:itemNames];
}
@end
