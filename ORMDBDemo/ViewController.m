//
//  ViewController.m
//  ORMDBDemo
//
//  Created by huyong on 2017/5/31.
//  Copyright © 2017年 Hu Yong. All rights reserved.
//

#import "ViewController.h"
#import "TestCarModel.h"
#import "TestAnimalModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    TestCarModel *car = [[TestCarModel alloc] init];
    car.name = @"hongqi";
    NSArray *cars = [car hy_getDBModel];
    NSLog(@"数据库中共有 %ld 个名为 %@ 的car",[cars count],car.name);
    
    
    car = [car hy_getDBFirstModel];
    NSLog(@"\ncar:name = %@, \nmodel = %@, \npicture = %@, \ncompnay=%@\n",car.name,car.model,car.picture,car.compnay);
    
    TestAnimalModel *animal = [[TestAnimalModel alloc] init];
    animal.name = @"狮子";
    NSArray *animals = [animal hy_getDBModel];
    NSLog(@"数据库中共有 %ld 个名为 %@ 的animal",[animals count],animal.name);
    
    animal = [animal hy_getDBFirstModel];
    NSLog(@"\nanimal:name = %@, \nlegs = %d, \nspeed = %@, \nspeed=%@\n",animal.name,[animal.legs intValue],animal.speed,animal.wikiurl);
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
