//
//  HYDBOperator.m
//  Imora
//
//  Created by huyong on 19/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <FMDB/FMDB.h>
#import "HYDBOperator.h"

@interface OraDBModelPropertiesCache ()

typedef NS_ENUM(NSInteger, HYPropertyType) {
    HYPropertyTypeString,
    HYPropertyTypeUrl,
    HYPropertyTypeDate,
    HYPropertyTypeNumber,
    HYPropertyTypeOther
};

+ (id)setObject:(id)object forKey:(id<NSCopying>)key forDictId:(const void *)dictId;
+ (id)objectForKey:(id<NSCopying>)key forDictId:(const void *)dictId;
+ (id)dictWithDictId:(const void *)dictId;
@end

@interface NSObject (OraDBModelJsonTransfer)
- (NSMutableArray *)GetAllvars;
- (NSMutableDictionary *)transToDict;
- (NSMutableDictionary *)transToDictWithIgnoreKeys:(NSArray *)ignorekeys;
- (void)loadDataFromDict:(NSDictionary *)dict;
@end

@interface HYDBOperator () {
    FMDatabaseQueue *_dbqueue;
}

@end

@implementation HYDBOperator

static HYDBOperator *operator= nil;

+ (void)setPath:(NSString *)path {
    if (operator!= nil) {
        operator= [[HYDBOperator alloc] initWithPath:path];
    }
}

+ (HYDBOperator *)shareManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      operator= [[HYDBOperator alloc] initWithPath:CONTACTPATH];
    });
    return operator;
}

+ (BOOL)DBFileExists {
    NSString *userHomeDir = [[NSUserDefaults standardUserDefaults] objectForKey:ORACURRENTUSERID];
    if ([NSString hy_isBlankString:userHomeDir]) {
        return NO;
    }
    NSFileManager *fileM = [NSFileManager defaultManager];
    if (![fileM fileExistsAtPath:[kDocumentsDirectory
                                     stringByAppendingFormat:@"/%@", [[NSUserDefaults standardUserDefaults]
                                                                         objectForKey:ORACURRENTUSERID]]]) {
        NSLog(@"当前登陆用户的专属目录不存在,所属的数据库也一定不存在。");
        return NO;
    }
    if (![fileM fileExistsAtPath:CONTACTPATH]) {
        NSLog(@"当前账号下数据库文件不存在。");
        return NO;
    }
    NSLog(@"当前账号下数据库文件已存在。");
    return YES;
}

// 创建数据库文件
- (BOOL)createDBFile {
    NSFileManager *fileM = [NSFileManager defaultManager];
    BOOL dbEsist = YES;
    if (![fileM fileExistsAtPath:[kDocumentsDirectory
                                     stringByAppendingFormat:@"/%@", [[NSUserDefaults standardUserDefaults]
                                                                         objectForKey:ORACURRENTUSERID]]]) {
        //第一次登陆的情况
        dbEsist =
            [fileM createDirectoryAtPath:[kDocumentsDirectory
                                             stringByAppendingFormat:@"/%@", [[NSUserDefaults standardUserDefaults]
                                                                                 objectForKey:ORACURRENTUSERID]]
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:nil];
    }
    return dbEsist;
}

//初始化数据库对象
- (instancetype)initWithPath:(NSString *)path {
    self = [super init];
    if (self) {
        [self createDBFile];
        _dbqueue = [[FMDatabaseQueue alloc] initWithPath:path];
    }

    return self;
}

- (void)dealloc {
    [self close];
}

//关闭数据库
- (void)close {
    if (_dbqueue) {
        [_dbqueue close];
        _dbqueue = nil;
    }
}

- (BOOL)createTable:(NSString *)sql {
    __block BOOL result = YES;
    [_dbqueue inDatabase:^(FMDatabase *db) {
      result = [db executeUpdate:sql];
    }];
    return result;
}

//执行批量sql命令
- (BOOL)executeSQLs:(NSString *)sql {
    __block BOOL result = YES;

    [_dbqueue inDatabase:^(FMDatabase *db) {
      result = [db executeStatements:sql];
    }];

    return result;
}

- (BOOL)executeSqlsInTransaction:(NSArray *)sqls {
    if (nil == sqls || 0 == sqls.count) {
        NSLog(@"没有需要执行的sql。");
        return NO;
    }
    [_dbqueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
      for (NSString *sql in sqls) {
          [db executeUpdate:sql];
      }
    }];

    return YES;
}

//加载数据,每行回调一次
- (void)loadData:(NSString *)sql param:(NSArray *)array callback:(void (^)(NSDictionary *data))callback {
    [_dbqueue inDatabase:^(FMDatabase *db) {
      FMResultSet *result = [db executeQuery:sql withArgumentsInArray:array];
      while ([result next]) {
          NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
          for (NSString *col in result.columnNameToIndexMap.allKeys) {
              dict[col] = [result objectForColumnName:col];
          }

          if (callback) {
              callback(dict);
          }
      }
    }];
}

//加载数据，返回所有数据
- (NSArray *)loadData:(NSString *)sql param:(NSArray *)array {
    __block NSMutableArray *data = [[NSMutableArray alloc] init];

    [_dbqueue inDatabase:^(FMDatabase *db) {
      FMResultSet *result = [db executeQuery:sql withArgumentsInArray:array];
      while ([result next]) {
          NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
          for (NSString *col in result.columnNameToIndexMap.allKeys) {
              dict[col] = [result objectForColumnName:col];
          }

          [data addObject:dict];
      }
    }];

    return data;
}

//返回单个数据
- (id)loadSingleData:(NSString *)sql param:(NSArray *)array {
    __block id data = nil;

    [_dbqueue inDatabase:^(FMDatabase *db) {
      FMResultSet *result = [db executeQuery:sql withArgumentsInArray:array];
      while ([result next]) {
          data = [result objectForColumnIndex:0];
      }
    }];

    return data;
}

//加载数据到models
- (NSArray *)loadData:(Class)c sql:(NSString *)sql param:(NSArray *)array {
    NSArray *rows = [self loadData:sql param:array];
    NSMutableArray *list = [[NSMutableArray alloc] init];
    for (NSDictionary *dict in rows) {
        HYBaseModel *tmp = [[c alloc] init];
        [tmp loadDataFromDict:dict];
        [list addObject:tmp];
    }
    rows = nil;

    return list;
}

//保存数据
- (BOOL)saveData:(NSString *)sql {
    __block BOOL result = YES;

    [_dbqueue inDatabase:^(FMDatabase *db) {

      result = [db executeUpdate:sql];

    }];

    return result;
}

//保存数据
- (BOOL)saveData:(NSString *)sql param:(NSArray *)array {
    return [self saveData:sql
                fetchData:^NSArray *(int i) {
                  if (i == 0) return array;
                  return nil;
                }];
}

//批量保存数据
- (BOOL)saveData:(NSString *)sql fetchData:(NSArray * (^)(int))fetchData {
    __block BOOL result = YES;

    [_dbqueue inDatabase:^(FMDatabase *db) {
      int i = 0;
      NSArray *array = fetchData(i);
      i++;
      while (array) {
          result = [db executeUpdate:sql withArgumentsInArray:array];
          array = fetchData(i);
          i++;
      }

    }];

    return result;
}

//新增models
- (BOOL)insertData:(HYBaseModel *)data {
    __block BOOL result = YES;

    [_dbqueue inDatabase:^(FMDatabase *db) {

      NSArray *col = [data transToDict].allKeys;
      NSMutableArray *cols = [[NSMutableArray alloc] init];

      for (id obj in col) {
          [cols addObject:obj];
      }
      NSMutableString *sql = [[NSMutableString alloc] init];
      if (!cols.count) {
          result = NO;
      } else {
          [sql appendFormat:@"INSERT INTO %@ (%@", [self tableNameForModel:data], cols[0]];
          for (int i = 1; i < cols.count; i++) {
              [sql appendFormat:@",%@", cols[i]];
          }
          [sql appendString:@") VALUES(?"];
          for (int i = 1; i < cols.count; i++) {
              [sql appendString:@",?"];
          }

          [sql appendString:@")"];
          NSMutableArray *array = [[NSMutableArray alloc] init];
          for (int i = 0; i < cols.count; i++) {
              id value = [data valueForKey:cols[i]];
              if ([value isKindOfClass:[NSString class]]) {
                  [array addObject:[value hy_trim]];
              } else {
                  [array addObject:value];
              }
          }
          result = [db executeUpdate:sql withArgumentsInArray:array];
      }
    }];

    return result;
}
- (BOOL)insertDataWithUUID:(HYBaseModel *)data {
    __block BOOL result = YES;
    NSLog(@"========================%@", _dbqueue.path);

    [_dbqueue inDatabase:^(FMDatabase *db) {

      NSArray *col = [data transToDict].allKeys;
      NSMutableArray *cols = [[NSMutableArray alloc] init];

      for (id obj in col) {
          if ([data valueForKey:obj]) {
              [cols addObject:obj];
          } else {
          }
      }
      NSMutableString *sql = [[NSMutableString alloc] init];
      if (!cols.count) {
          result = NO;
      } else {
          [sql appendFormat:@"INSERT INTO %@ (%@", [self tableNameForModel:data], cols[0]];
          for (int i = 1; i < cols.count; i++) {
              [sql appendFormat:@",%@", cols[i]];
          }

          [sql appendString:@") VALUES(?"];
          for (int i = 1; i < cols.count; i++) {
              [sql appendString:@",?"];
          }

          [sql appendString:@")"];
          NSMutableArray *array = [[NSMutableArray alloc] init];
          for (int i = 0; i < cols.count; i++) {
              id value = [data valueForKey:cols[i]];
              if ([value isKindOfClass:[NSString class]]) {
                  [array addObject:[value hy_trim]];
              } else {
                  [array addObject:value];
              }
          }
          result = [db executeUpdate:sql withArgumentsInArray:array];
      }
    }];

    return result;
}

- (void)batchInsertData:(NSArray *)dataArray {
    if (nil == dataArray || 0 == dataArray.count) {
        NSLog(@"空数据无法批量插入数据库，请正确使用方法。");
        return;
    }
    [_dbqueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
      BOOL result = NO;
      for (HYBaseModel *data in dataArray) {
          NSArray *col = [data transToDict].allKeys;
          NSMutableArray *cols = [[NSMutableArray alloc] init];

          for (id obj in col) {
              if ([data valueForKey:obj]) {
                  [cols addObject:obj];
              } else {
              }
          }
          NSMutableString *sql = [[NSMutableString alloc] init];
          if (!cols.count) {
              result = NO;
          } else {
              [sql appendFormat:@"INSERT INTO %@ (%@", [self tableNameForModel:data], cols[0]];
              for (int i = 1; i < cols.count; i++) {
                  [sql appendFormat:@",%@", cols[i]];
              }

              [sql appendString:@") VALUES(?"];
              for (int i = 1; i < cols.count; i++) {
                  [sql appendString:@",?"];
              }

              [sql appendString:@")"];
              NSMutableArray *array = [[NSMutableArray alloc] init];
              for (int i = 0; i < cols.count; i++) {
                  id value = [data valueForKey:cols[i]];
                  if ([value isKindOfClass:[NSString class]]) {
                      [array addObject:[value hy_trim]];
                  } else {
                      [array addObject:value];
                  }
              }
              result = [db executeUpdate:sql withArgumentsInArray:array];
          }
      }
    }];
}

//更新models
- (BOOL)updateData:(HYBaseModel *)data dependOnKeys:(NSArray *)keys {
    __block BOOL result = YES;
    [_dbqueue inDatabase:^(FMDatabase *db) {
      NSMutableDictionary *modelDic = [data transToDictWithIgnoreKeys:keys];
      NSMutableArray *cols = [[NSMutableArray alloc] initWithArray:modelDic.allKeys];
      NSMutableDictionary *parm = modelDic;
      NSArray *param = modelDic.allKeys;
      NSMutableString *sql = [[NSMutableString alloc] init];
      for (int i = 0; i < param.count; i++) {
          if (![parm objectForKey:param[i]]) {
              [cols removeObject:param[i]];
          }
      }

      [sql appendFormat:@"update %@ set", [self tableNameForModel:data]];

      for (int i = 0; i < cols.count; i++) {
          [sql appendFormat:@" %@ = ?,", cols[i]];
      }
      NSRange range = NSMakeRange(sql.length - 1, 1);
      [sql deleteCharactersInRange:range];
      if (keys.count == 1) {
          [sql appendFormat:@" where %@ = ?", keys[0]];

      } else if (keys.count > 1) {
          for (int i = 0; i < keys.count; i++) {
              if (i == 0) {
                  [sql appendFormat:@" where %@ = ?", keys[i]];

              } else if (i == keys.count - 1) {
                  [sql appendFormat:@" and %@ = ?", keys[i]];

              } else {
                  [sql appendFormat:@" and %@ = ?", keys[i]];
              }
          }
      }

      NSMutableArray *array = [[NSMutableArray alloc] init];
      for (int i = 0; i < cols.count; i++) {
          [array addObject:[data valueForKey:cols[i]]];
      }

      for (int i = 0; i < keys.count; i++) {
          if (![data valueForKey:keys[i]]) {
              result = NO;
              NSLog(@"操作表: %@ dependOn属性%@值为空,更新数据库失败。 ", [self tableNameForModel:data], keys[i]);
              return;
          }
          id value = [data valueForKey:keys[i]];
          if ([value isKindOfClass:[NSString class]]) {
              [array addObject:[value hy_trim]];
          } else {
              [array addObject:value];
          }
      }

      result = [db executeUpdate:sql withArgumentsInArray:array];

    }];

    return result;
}
//删除models
- (BOOL)deleteData:(HYBaseModel *)data dependOnKeys:(NSArray *)keys {
    __block BOOL result = YES;
    [_dbqueue inDatabase:^(FMDatabase *db) {

      NSMutableString *sql = [[NSMutableString alloc] init];
      [sql appendFormat:@"delete  from %@ ", [self tableNameForModel:data]];
      NSMutableArray *parm = [[NSMutableArray alloc] init];
      if (keys.count == 1) {
          [sql appendFormat:@" where %@ = ?", keys[0]];

      } else if (keys.count > 1) {
          for (int i = 0; i < keys.count; i++) {
              if (i == 0) {
                  [sql appendFormat:@" where %@ = ?", keys[i]];

              } else if (i == keys.count - 1) {
                  [sql appendFormat:@" and %@ = ?", keys[i]];

              } else {
                  [sql appendFormat:@" and %@ = ?", keys[i]];
              }
          }

      } else {
          parm = nil;
      }

      for (int i = 0; i < keys.count; i++) {
          if (![data valueForKey:keys[i]]) {
              result = NO;
//              NSLog(@"操作表: %@ dependOn属性%@值为空,删除数据失败。 ", [self tableNameForModel:data], keys[i]);
              return;
          }
          [parm addObject:[data valueForKey:keys[i]]];
      }

      result = [db executeUpdate:sql withArgumentsInArray:parm];

    }];

    return result;
}

- (NSString *)tableNameForModel:(HYBaseModel *)model {
    return NSStringFromClass([model class]);
}

// 根据条件查询数据库
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"select * from %@", [self tableNameForModel:condition]];

    if (nil == condition) {
        return nil;
    }
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    NSDictionary *model = [condition transToDict];
    NSMutableArray *parm = [[NSMutableArray alloc] init];
    NSMutableArray *arrayy = [[NSMutableArray alloc] initWithArray:model.allKeys];
    NSArray *arr = [NSArray arrayWithArray:arrayy];
    for (NSString *obj in arr) {
        if ([model objectForKey:obj]) {
            id Value = [model objectForKey:obj];
            [param setObject:Value forKey:obj];
            [parm addObject:Value];
        } else {
            [arrayy removeObject:obj];
        }
    }

    if (param.count) {
        for (int i = 0; i < param.count; i++) {
            if (i == 0) {
                [sql appendFormat:@" where %@ = ?", arrayy[i]];

            } else {
                [sql appendFormat:@" and %@ = ?", arrayy[i]];
            }
        }
    } else {
        parm = nil;
    }
    return [self loadData:[condition class] sql:sql param:parm];
}
// 提供分页查询功能
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition
                               andpage:(int)pageindex
                            andOrderby:(NSString *)orderBy
                               isAscen:(BOOL)isAscen {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"select * from %@", [self tableNameForModel:condition]];

    if (nil == condition) {
        return nil;
    }
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    NSDictionary *model = [condition transToDict];
    NSMutableArray *parm = [[NSMutableArray alloc] init];
    NSMutableArray *arrayy = [[NSMutableArray alloc] initWithArray:model.allKeys];
    NSArray *arr = [NSArray arrayWithArray:arrayy];
    for (NSString *obj in arr) {
        if ([model objectForKey:obj]) {
            id Value = [model objectForKey:obj];
            [param setObject:Value forKey:obj];
            [parm addObject:Value];

        } else {
            [arrayy removeObject:obj];
        }
    }

    if (param.count) {
        for (int i = 0; i < param.count; i++) {
            if (i == 0) {
                [sql appendFormat:@" where %@ = ?", arrayy[i]];
            } else {
                [sql appendFormat:@" and %@ = ?", arrayy[i]];
            }
        }
    } else {
        parm = nil;
    }

    //[sql appendFormat:@" order by id desc limit %d offset %d", LIMITNUMBER,
    // pageindex * LIMITNUMBER];
    // NSString *sqll = [NSString stringWithFormat:@"select * from ( %@) order by
    // id", sql];
    NSString *sort = isAscen ? @"asc" : @"desc";

    [sql appendFormat:@" order by %@ %@ limit %d offset %d", orderBy, sort, LIMITNUMBER, pageindex * LIMITNUMBER];
    NSString *sqll = [NSString stringWithFormat:@"select * from ( %@) order by %@ %@", sql, orderBy, sort];

    return [self loadData:[condition class] sql:sqll param:parm];
}

// 提供条件+模糊匹配查询功能
- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition andLike:(NSString *)itemName {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"select * from %@  ", [self tableNameForModel:condition]];

    if (nil == condition) {
        return nil;
    }
    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    NSDictionary *model = [condition transToDict];
    NSMutableArray *parm = [[NSMutableArray alloc] init];
    NSMutableArray *arrayy = [[NSMutableArray alloc] initWithArray:model.allKeys];
    [arrayy removeObject:itemName];
    NSArray *arr = [NSArray arrayWithArray:arrayy];

    for (NSString *obj in arr) {
        if ([model objectForKey:obj]) {
            id Value = [model objectForKey:obj];
            [param setObject:Value forKey:obj];
            [parm addObject:Value];
        } else {
            [arrayy removeObject:obj];
        }
    }
    if (param.count > 0) {
        for (int i = 0; i < param.count; i++) {
            if (i == 0) {
                [sql appendFormat:@"where %@ = ?", arrayy[i]];

            } else {
                [sql appendFormat:@" and %@ = ?", arrayy[i]];
            }
        }
        [sql appendFormat:@" and %@  like '%%%@%%'", itemName, [condition valueForKey:itemName]];
    } else {
        parm = nil;
        [sql appendFormat:@" where %@  like '%%%@%%'", itemName, [condition valueForKey:itemName]];
    }
    return [self loadData:[condition class] sql:sql param:parm];
}

- (NSArray *)searchModelsWithCondition:(HYBaseModel *)condition orLike:(NSArray *)itemNames {
    NSMutableString *sql = [[NSMutableString alloc] init];
    [sql appendFormat:@"select * from %@  ", [self tableNameForModel:condition]];

    if (nil == condition || itemNames == nil || itemNames.count == 0) {
        return nil;
    }

    NSMutableDictionary *param = [[NSMutableDictionary alloc] init];
    NSDictionary *model = [condition transToDict];
    NSMutableArray *parm = [[NSMutableArray alloc] init];
    NSMutableArray *arrayy = [[NSMutableArray alloc] initWithArray:model.allKeys];
    NSArray *arr = [NSArray arrayWithArray:arrayy];
    for (NSString *obj in arr) {
        if ([model objectForKey:obj]) {
            id Value = [model objectForKey:obj];
            [param setObject:Value forKey:obj];
            [parm addObject:Value];
        } else {
            [arrayy removeObject:obj];
        }
    }

    for (int i = 0; i < itemNames.count; i++) {
        if (i == 0) {
            [sql appendFormat:@" where %@  like '%%%@%%'", itemNames[i], [condition valueForKey:itemNames[i]]];

        } else {
            [sql appendFormat:@" or %@  like '%%%@%%'", itemNames[i], [condition valueForKey:itemNames[i]]];
        }
    }
    return [self loadData:[condition class] sql:sql param:parm];
}
@end

@implementation NSObject (OraDBModelJsonTransfer)

- (NSMutableArray *)GetAllvars {
    NSMutableArray *list = [[NSMutableArray alloc] init];

    //获取当前的类
    Class c = [self class];
    NSArray *ignoredPropertyNames = [[self class] mj_totalIgnoredPropertyNames];

    while (c && ![[NSString stringWithUTF8String:object_getClassName(c)] isEqualToString:@"NSObject"]) {
        unsigned int numberOfIvars = 0;
        //获取cls 类成员变量列表
        objc_property_t *ivars = class_copyPropertyList(c, &numberOfIvars);
        //采用指针+1 来获取下一个变量
        for (const objc_property_t *p = ivars; p < ivars + numberOfIvars; p++) {
            NSString *key = [NSString stringWithUTF8String:property_getName(*p)];

            if (!ignoredPropertyNames || ![ignoredPropertyNames containsObject:key]) {
                [list addObject:key];
            }
        }

        free(ivars);
        c = class_getSuperclass(c);
    }

    return list;
}

- (NSMutableDictionary *)transToDictWithIgnoreKeys:(NSArray *)ignorekeys {
    NSArray *props = [self GetAllvars];

    NSArray *ignoredPropertyNames = [[self class] mj_totalIgnoredPropertyNames];

    NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
    for (NSString *pro in props) {
        // 如果是忽略字段则不创建
        if (ignoredPropertyNames && [ignoredPropertyNames containsObject:pro]) {
            continue;
        }
        if (ignorekeys && [ignorekeys containsObject:pro]) {
            continue;
        }

        if ([self valueForKey:pro] != nil) {
            [dict setValue:[self valueForKey:pro] forKey:pro];
        }
    }

    return dict;
}

//转换对象为字典
- (NSMutableDictionary *)transToDict {
    return [self transToDictWithIgnoreKeys:nil];
}

//加载数据
- (void)loadDataFromDict:(NSDictionary *)dict {
    //获取当前的类
    NSArray *ignoredPropertyNames = [[self class] mj_totalIgnoredPropertyNames];

    NSDictionary *allProperties = [OraDBModelPropertiesCache allProperties:[self class]];

    for (NSString *propertyName in allProperties) {
        //        NSTimeInterval querydbStart = [NSDate timeIntervalSinceReferenceDate];

        HYPropertyType propertyType = [[allProperties objectForKey:propertyName] integerValue];
        if (HYPropertyTypeOther == propertyType) {
            continue;
        }
        // 如果是忽略字段则不创建
        if (ignoredPropertyNames && [ignoredPropertyNames containsObject:propertyName]) continue;

        NSString *value;
        if (dict[[propertyName lowercaseString]] || dict[propertyName]) {
            if ([dict[[propertyName lowercaseString]] isKindOfClass:[NSNull class]] ||
                [dict[propertyName] isKindOfClass:[NSNull class]]) {
                //                    value = nil;
                continue;
            } else {
                if (dict[[propertyName lowercaseString]]) {
                    value = dict[[propertyName lowercaseString]];
                } else {
                    value = dict[propertyName];
                }
            }
        }

        //        NSLog(@"--执行 %@耗时:%f", NSStringFromClass([self class]),
        //              [NSDate timeIntervalSinceReferenceDate] - querydbStart);
        //        querydbStart = [NSDate timeIntervalSinceReferenceDate];
        switch (propertyType) {
            case HYPropertyTypeString:
                [self setValue:value forKey:propertyName];
                break;
            case HYPropertyTypeUrl:
                [self setValue:[NSURL URLWithString:value] forKey:propertyName];
                break;
            case HYPropertyTypeNumber: {
                if ([value rangeOfString:@"."].location != NSNotFound) {
                    NSNumberFormatter *nformat = [[NSNumberFormatter alloc] init];
                    [nformat setNumberStyle:NSNumberFormatterDecimalStyle];
                    NSNumber *number = [nformat numberFromString:value];
                    [self setValue:number forKey:propertyName];
                } else {
                    NSNumber *number = [[NSNumberFormatter alloc] numberFromString:value];
                    [self setValue:number forKey:propertyName];
                }
                break;
            }
            case HYPropertyTypeDate: {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:value.doubleValue];
                [self setValue:date forKey:propertyName];
                break;
            }
            default:
                break;
        }
        //        if ([propertyType isEqualToString:@"NSString"]) {
        //            [self setValue:value forKey:propertyName];
        //
        //        } else if ([propertyType isEqualToString:@"NSURL"]) {
        //            [self setValue:[NSURL URLWithString:value] forKey:propertyName];
        //
        //        } else if ([propertyType isEqualToString:@"NSNumber"]) {
        //            NSNumber *number = [[NSNumberFormatter alloc] numberFromString:value];
        //            [self setValue:number forKey:propertyName];
        //
        //        } else if ([propertyType isEqualToString:@"NSDate"]) {
        //            NSDate *date = [NSDate dateWithTimeIntervalSince1970:value.doubleValue];
        //            [self setValue:date forKey:propertyName];
        //        }
        //        NSLog(@"--执行ok %@耗时:%f", NSStringFromClass([self class]),
        //              [NSDate timeIntervalSinceReferenceDate] - querydbStart);
    }
}

@end

static const char OraDBModelPropertiesCacheKey = '\0';
@implementation OraDBModelPropertiesCache
+ (NSDictionary *)allProperties:(Class)className {
    NSString *stringName = NSStringFromClass(className);
    NSMutableDictionary *cachedProperties =
        [OraDBModelPropertiesCache objectForKey:stringName forDictId:&OraDBModelPropertiesCacheKey];

    if (nil == cachedProperties) {
        cachedProperties = [NSMutableDictionary dictionary];
        while (className &&
               ![[NSString stringWithUTF8String:object_getClassName(className)] isEqualToString:@"NSObject"]) {
            unsigned int numberOfIvars = 0;
            //获取cls 类成员变量列表
            objc_property_t *ivars = class_copyPropertyList(className, &numberOfIvars);
            //采用指针+1 来获取下一个变量
            for (const objc_property_t *p = ivars; p < ivars + numberOfIvars; p++) {
                NSString *propertyName = [NSString stringWithUTF8String:property_getName(*p)];
                NSString *propertyType = [NSString stringWithUTF8String:property_getAttributes(*p)];
                //
                if ([propertyType rangeOfString:@"NSString"].location != NSNotFound) {
                    [cachedProperties setObject:@(HYPropertyTypeString) forKey:propertyName];

                } else if ([propertyType rangeOfString:@"NSURL"].location != NSNotFound) {
                    [cachedProperties setObject:@(HYPropertyTypeUrl) forKey:propertyName];

                } else if ([propertyType rangeOfString:@"NSNumber"].location != NSNotFound) {
                    [cachedProperties setObject:@(HYPropertyTypeNumber) forKey:propertyName];

                } else if ([propertyType rangeOfString:@"NSDate"].location != NSNotFound) {
                    [cachedProperties setObject:@(HYPropertyTypeDate) forKey:propertyName];
                } else {
                    [cachedProperties setObject:@(HYPropertyTypeOther) forKey:propertyName];
                }
            }

            free(ivars);
            className = class_getSuperclass(className);
        }
        [OraDBModelPropertiesCache setObject:cachedProperties
                                      forKey:stringName
                                   forDictId:&OraDBModelPropertiesCacheKey];
    }

    return cachedProperties;
}

+ (id)setObject:(id)object forKey:(id<NSCopying>)key forDictId:(const void *)dictId {
    // 获得字典
    NSMutableDictionary *dict = [self dictWithDictId:dictId];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, dictId, dict, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // 存储数据
    dict[key] = object;

    return dict;
}

+ (id)objectForKey:(id<NSCopying>)key forDictId:(const void *)dictId {
    return [self dictWithDictId:dictId][key];
}

+ (id)dictWithDictId:(const void *)dictId {
    return objc_getAssociatedObject(self, dictId);
}
@end
