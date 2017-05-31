# HYORMDB
  model到数据库的映射，大多数情况下，无需自己操作数据库。新增表只需新增model加入到tablefactory、删除表只需从tablefactory中移除、修改表只需要修改项目中的Model就可以。目的是尽量做到app的升级或因业务导致的model数据修改，而不用修改数据库相关的代码。

###Purpose

HYORMDB is a simple ORM framework,with HYORMDB you just need to deal with your model.

Author: [Hu Yong](https://github.com/627171314/).

_Remark: Please accept my apologize if any bad coding._

###Installations

####Manual

1. Download or clone HYORMDB, import into your project.
2. Use HYORMDB whereever you need it.

###Easy Example

To use HYORMDB.
+ (void)createTablesWillUpdate:(void (^)(BOOL willUpdate))willUpdate FinishCallback:(void (^)(BOOL success))block {
    NSArray *DBTableArray = @[
        [TestCarModel class],
        [TestAnimalModel class],
    ];
// ...
}

 ```objective-c
 
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
        [animal save];
        
        TestCarModel *car = [[TestCarModel alloc] init];
        car.name = @"hongqi";
        car.compnay = @"hongqi";
        car.model = @"hq1";
        car.picture = [NSURL URLWithString:@"http://www.faw-hongqi.com.cn/"];
        [car save];
        
    }];
    
    return YES;
}

#Access data from DB
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

 ```

###License
This code is distributed under the terms and conditions of the [BSD license](LICENSE). 
