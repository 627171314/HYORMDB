//
//  TestCarModel.h
//  ORMDBDemo
//
//  Created by huyong on 2017/5/31.
//  Copyright © 2017年 Hu Yong. All rights reserved.
//

#import "HYBaseModel.h"

@interface TestCarModel : HYBaseModel
@property (nonatomic, strong) NSString *model;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSURL *picture;
@property (nonatomic, strong) NSString *compnay;
@end
