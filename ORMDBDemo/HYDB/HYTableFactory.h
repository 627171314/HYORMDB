//
//  HYTableFactory.h
//  Imora
//
//  Created by huyong on 20/11/15.
//  Copyright © 2015年 Oradt. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString *const kDBUpdateFinishedNotification;

static BOOL isUpdateDB = NO;

@interface HYTableFactory : NSObject

+ (void)createTablesWillUpdate:(void(^)(BOOL willUpdate))willUpdate FinishCallback:(void (^)(BOOL success))block;
+ (void)reSetCurrentUserDBVersion;
@end
