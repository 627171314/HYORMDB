//
//  AppDelegate.m
//  ORMDBDemo
//
//  Created by huyong on 2017/5/31.
//  Copyright © 2017年 Hu Yong. All rights reserved.
//

#import "AppDelegate.h"
#import "HYTableFactory.h"
#import "TestAnimalModel.h"
#import "TestCarModel.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [HYTableFactory createTablesWillUpdate:^(BOOL willUpdate) {
        if (willUpdate) {
            NSLog(@"数据库将进行升级");
        } else {
            NSLog(@"数据库无需进行升级操作");
        }
    } FinishCallback:^(BOOL success) {
        NSLog(@"数据库已建立");
        
        TestAnimalModel *animal = [[TestAnimalModel alloc] init];
        animal.name = @"狮子";
        animal.legs = @(4);
        animal.speed = @(50);
        animal.wikiurl = [NSURL URLWithString:@"https://zh.wikipedia.org/wiki/%E7%8B%AE"];
//        [animal hy_insertToDB];
        [animal save];
        
        TestCarModel *car = [[TestCarModel alloc] init];
        car.name = @"hongqi";
        car.compnay = @"hongqi";
        car.model = @"hq1";
        car.picture = [NSURL URLWithString:@"http://www.faw-hongqi.com.cn/"];
//        [car hy_insertToDB];
        [car save];
        
    }];
    
    return YES;
}


- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
