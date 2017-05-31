//
//  HYBaseModel.m
//  Imora
//
//  Created by huyong on 17/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import "HYBaseModel.h"
#import "HYDBManager.h"

@implementation HYBaseModel
MJCodingImplementation - (NSMutableDictionary *)hy_TransToDictionary { return [self mj_keyValues]; }

- (NSMutableDictionary *)hy_TransToDictionaryWithKeys:(NSArray *)keys {
    return [self mj_keyValuesWithKeys:keys];
}

- (NSMutableDictionary *)hy_TransToDictionaryWithIgnoredKeys:(NSArray *)ignoredKeys {
    return [self mj_keyValuesWithIgnoredKeys:ignoredKeys];
}

- (instancetype)hy_loadDataFromkeyValues:(id)keyValues {
    return [self mj_setKeyValues:keyValues];
}

+ (NSMutableArray *)mj_ignoredPropertyNames {
    return nil;
}

- (BOOL)hy_insertToDB {
    return [HYDBManager insertModelIntoTable:self];
}

- (BOOL)hy_updateToDB {
    return [HYDBManager updateContact:self dependOnKeys:nil];
}

- (BOOL)hy_removeFromDB {
    return [HYDBManager deleteContact:self dependOnKeys:nil];
}

- (BOOL)save
{
    if ([NSString hy_isBlankString:self.pid]) {
        return [self hy_insertToDB];
    } else {
        return [self hy_updateToDB];
    }
}
- (BOOL)remove
{
    return [self hy_removeFromDB];
}

- (NSArray *)hy_getDBModel {
    return [HYDBManager searchModelsWithCondition:self];
}

- (id)hy_getDBFirstModel {
    NSArray *array = [self hy_getDBModel];
    if (array && array.count > 0) {
        return [array firstObject];
    } else {
        return nil;
    }
}

+ (BOOL)hy_insertToDBWithModel:(HYBaseModel *)model {
    if (![model valueForKey:kModelPrimary]) {
        model.pid = [NSString hy_UUID];
    }
    return [HYDBManager insertModelIntoTable:model];
}

+ (BOOL)hy_updateToDBWithModel:(HYBaseModel *)model dependOnKeys:(NSArray *)keys {
    if (!keys || 0 == keys.count) {
        return [HYDBManager updateContact:model dependOnKeys:@[ kModelPrimary ]];
    }
    return [HYDBManager updateContact:model dependOnKeys:keys];
}

+ (BOOL)hy_removeFromDBWithModel:(HYBaseModel *)model dependOnKeys:(NSArray *)keys {
    if (!keys || 0 == keys.count) {
        return [HYDBManager deleteContact:model dependOnKeys:@[ kModelPrimary ]];
    }
    return [HYDBManager deleteContact:model dependOnKeys:keys];
}

+ (NSDictionary *)mj_replacedKeyFromPropertyName {
    /*
     return @{kModelPrimary : kModelPrimary,
     @"desc" : @"desciption",
     @"oldName" : @"name.oldName",
     @"nowName" : @"name.newName",
     @"nameChangedTime" : @"name.info[1].nameChangedTime",
     @"bag" : @"other.bag"
     };
     key值是json内的key值
     value值是model的属性名称，如果属性本身是类对象，@"name.oldName"就是指类对象的属性
     */
    return nil;
}

+ (NSDictionary *)mj_objectClassInArray {
    return nil;
}
@end
