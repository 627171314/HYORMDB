//
//  TestAnimalModel.h
//  ORMDBDemo
//
//  Created by huyong on 2017/5/31.
//  Copyright © 2017年 Hu Yong. All rights reserved.
//

#import "HYBaseModel.h"

@interface TestAnimalModel : HYBaseModel
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSNumber *legs;
@property (nonatomic, strong) NSNumber *speed;
@property (nonatomic, strong) NSURL *wikiurl;
@end
