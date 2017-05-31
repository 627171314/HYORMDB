//
//  HYTableFactory.m
//  Imora
//
//  Created by huyong on 20/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import "HYTableFactory.h"
#import "NSString+Extension.h"
#import "AppDelegate.h"
#import "HYDBManager.h"

#import "TestCarModel.h"
#import "TestAnimalModel.h"


NSString *const kDBUpdateFinishedNotification = @"kDBUpdateNotification";

@implementation HYTableFactory

+ (void)createTablesWillUpdate:(void (^)(BOOL willUpdate))willUpdate FinishCallback:(void (^)(BOOL success))block {
    NSArray *DBTableArray = @[
        [TestCarModel class],
        [TestAnimalModel class],
    ];
    NSString *dbVersion = [self getCurrentUserDBVersion]; /* 获取当前用户上次创建数据库时的App版本 */
    if ([NSString hy_isBlankString:dbVersion]) {
        if (willUpdate) {
            willUpdate(NO);
        }
        NSLog(@"初次安装");

        [self createTablesForApp:DBTableArray];
        [self setCurrentUserDBVersion]; /* 记录下用户当前数据库对应的App版本 */
        if (block) {
            block(YES);
        }

    } else {
        NSString *appVersion = [[NSBundle mainBundle]
            objectForInfoDictionaryKey:@"CFBundleVersion"]; /* build版本号,格式: 0.0.20160420.0 */
        BOOL toDo = [self shouldUpdateWithAppVersion:appVersion andDBVersion:dbVersion];
        if (toDo) {
            NSLog(@"程序版本与数据库版本不匹配,需要升级");
            if (willUpdate) {
                willUpdate(YES);
            }
            isUpdateDB = YES;

            // 跳转至数据库升级Controller
            UIViewController *dbUpdateController = [[UIViewController alloc] init];
            UINavigationController *nav =
                [[UINavigationController alloc] initWithRootViewController:dbUpdateController];
            AppDelegate *delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            delegate.window.rootViewController = nav;

            dispatch_async(dispatch_get_global_queue(0, 0), ^{
              NSTimeInterval start = [NSDate timeIntervalSinceReferenceDate];
              BOOL success = [self updateTablesForApp:dbVersion newVersion:appVersion dbTables:DBTableArray];

              if (success) {
                  [self setCurrentUserDBVersion];
                  NSLog(@"数据库升级完成。");
              } else {
                  NSLog(@"数据库升级失败。");
              }
              isUpdateDB = NO;
              NSLog(@"数据库升级总耗时:%f", [NSDate timeIntervalSinceReferenceDate] - start);
              dispatch_async(dispatch_get_main_queue(), ^{
                //                    [[NSNotificationCenter defaultCenter]
                //                    postNotificationName:kDBUpdateFinishedNotification object:nil];

                if (block) {
                    block(YES);
                }
              });
            });

        } else {
            NSLog(@"数据库已是最新版本无需升级。");

            if (willUpdate) {
                willUpdate(NO);
            }
            if (block) {
                block(YES);
            }
        }
    }
}

+ (BOOL)updateTablesForApp:(NSString *)oldVersion newVersion:(NSString *)newVersion dbTables:(NSArray *)allTables {
    NSArray *oldDbTables =
        [HYDBManager loadAllTableNames]; /* 读取数据库中的全部就表名 @[{@"name":xxxModel},{@"name":xxxmodel}...] */
    NSMutableArray *arName = [NSMutableArray array];
    for (id kt in oldDbTables) {
        [arName addObject:kt[@"name"]];
    }

    oldDbTables = [NSArray arrayWithArray:arName];
    // 添加新增表
    NSMutableArray *newTable = [NSMutableArray array];
    for (Class retainModel in allTables) {
        if (![oldDbTables containsObject:NSStringFromClass(retainModel)]) {
            [HYDBManager createTableWithModel:retainModel]; /* 创建新增表 */
            [newTable addObject:retainModel];
        }
    }
    // 删除的废弃表
    for (NSString *oldTable in oldDbTables) {
        if (![allTables containsObject:NSClassFromString(oldTable)]) {
            [HYDBManager dropTable:NSClassFromString(oldTable)];
        }
    }
    // 为保留的旧表做升级
    for (Class needUpdateModel in allTables) {
        if (![newTable containsObject:needUpdateModel]) {
            [HYDBManager updateTableWithModelByModifyTable:needUpdateModel];
        }
    }
    
    oldDbTables = nil;
    allTables = nil;

    /* 采用所有旧表全部通过临时表进行数据迁移的升级方式
    for (Class dbmodel in dbTables) {
        [HYDBManager updateTableWithModel:dbmodel];
    }*/
    return YES;
}

+ (void)createTablesForApp:(NSArray *)dbTables {
    for (Class dbmodel in dbTables) {
        [HYDBManager createTableWithModel:dbmodel];
    }
}

+ (NSString *)getCurrentUserDBVersion {
    NSString *key = @"dbversion_";
    NSString *version = [[NSUserDefaults standardUserDefaults] stringForKey:key];

    return version;
}

+ (void)setCurrentUserDBVersion {
    NSString *appVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    NSUserDefaults *usd = [NSUserDefaults standardUserDefaults];
    NSString *key = @"dbversion_";
    [usd setObject:appVersion forKey:key];
    [usd synchronize];
}

+ (void)reSetCurrentUserDBVersion {
    NSUserDefaults *usd = [NSUserDefaults standardUserDefaults];
    NSString *key = @"dbversion_";
    [usd removeObjectForKey:key];
    [usd synchronize];
}

#define versionSeparator @"."
+ (BOOL)shouldUpdateWithAppVersion:(NSString *)appVersion andDBVersion:(NSString *)dbVersion {
    BOOL shouldUpdate = NO;
    NSArray *appVs = [appVersion componentsSeparatedByString:versionSeparator];
    NSArray *dbVs = [dbVersion componentsSeparatedByString:versionSeparator];

    // 从主版本号到次版本号依次比较
    for (int i = 0; i < [appVs count]; i++) {
        NSInteger app = [appVs[i] integerValue];
        NSInteger db = [dbVs[i] integerValue];
        if (app > db) {
            shouldUpdate = YES;
            break;
        }
    }

    return shouldUpdate;
}

@end
