//
//  SKKVCKVOVC.m
//  iOSBasicDemo
//
//  Created by shavekevin on 2019/9/24.
//  Copyright © 2019 小风. All rights reserved.
//

#import "SKKVCKVOVC.h"
#import "KVOModel.h"
#import <objc/runtime.h>
#import <mach/mach.h>
#import "SKKVOStudentModel.h"
#import "NSObject+SKKVO.h"
#import "SKKVCModel.h"
#import "SKKVCTestModel.h"


// KVO - Key-Value- Observing 键值监听  用于监听某个对象中属性的改变
// KVC - Key-Value- Coding 键值编码 主要用于不调用setter方法就更改或者访问对象的属性，这只是在动态地访问或更改对象的属性，而不是在编译期。
@interface SKKVCKVOVC ()
@property (nonatomic, strong) KVOModel *kvoModel;

@property (nonatomic, strong) SKKVOStudentModel *selfSysModel;

@property (nonatomic, strong) SKKVOStudentModel *testKVOModel;


@end

@implementation SKKVCKVOVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self kvomodelselfSysthis];

}

- (void)modelValueChange {
    
    KVOModel *model1 = [[KVOModel alloc]init];
    KVOModel *model2 = [[KVOModel alloc]init];
    NSLog(@"model1===%@", model1);
    model1.age = 2;
    model2.age = 2;
    // 这个时候打印model1的isa指向 我们可以看到:KVOModel
    // 这个时候打印model2的isa指向 我们可以看到:KVOModel
    NSKeyValueObservingOptions options = NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld;
    [model1 addObserver:self forKeyPath:@"age" options:options context:nil];
    // 这个时候打印model1的isa指向类对象,我们可以看到:NSKVONotifying_KVOModel
    // 这个时候打印model2的isa指向类对象,我们可以看到:KVOModel
    model1.age = 10;
    model2.age = 10;
    [model1 removeObserver:self forKeyPath:@"age"];
    // 我们可以看到在对model的age进行监听的时候，model1对象所指向的类对象发生了改变，而没有添加监听的model2没有发生改变。
    /*
     model2：只关注model2的时候我们可以看到在对model2调用setAge的时候，首先找到对应的类KVOModel然后从类中找到setAge 方法进行调用。
     NSKVONotifying_KVOModel 这个类是
     
     */
}

- (void)nameChangeedMethod {
    //在设置观察者的时候。只要被观察的属性发生改变就会响应改变的方法(不论前后是不是值发生改变都会执行observe的方法)
    self.kvoModel = [[KVOModel alloc]init];
    NSLog(@"添加观察者之前： %@  %@",self.kvoModel ,object_getClass(self.kvoModel));
    self.kvoModel.name = @"shave";
    [self.kvoModel addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    NSLog(@"添加观察者之后： %@  %@",self.kvoModel ,object_getClass(self.kvoModel));
    self.kvoModel.name = @"shave";
    // 可以直接调用 这个时候name是kvoModel实例中的一个属性。这个时候把key改为_name 就不可以。因为_name不是属性而是私有的变量。(设置完@property的时候不加特殊标识系统会帮我们生成setter和getter方法)
    [self.kvoModel setValue:@"kevin" forKey:@"name"];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.kvoModel.name = @"shave";
    });
}

// 手动触发KVO
- (void)handleKVOMethod {
    if (self.kvoModel) {
        self.kvoModel = [[KVOModel alloc]init];
    }
    self.kvoModel.name = @"hahaha";
    [self.kvoModel addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
    [self.kvoModel willChangeValueForKey:@"name"];
    [self.kvoModel didChangeValueForKey:@"name"];
}

- (void)setObjectMethod {
    // 集合运算符之数组
    NSMutableArray *mutableArray = [[NSMutableArray alloc]init];
    [mutableArray addObject:@"0"];
    [mutableArray addObject:@"1"];
    [mutableArray addObject:@"2"];
    [mutableArray addObject:@"4"];
    // count 返回的是一个NSNumber对象
    NSLog(@"计算数组的count为：%@",[mutableArray valueForKeyPath:@"@count.self"]);
    // sum把集合中的元素改为double类型的，然后计算总和，最后返回一个值为总和的NSNumber类型的对象。类似的还有 @avg求平均值@max求最大值@min求最小值。
    // 其中@max和@min使用的是compare来确定最大值、最小值
    NSLog(@"计算数组中元素的sum为：%@",[mutableArray valueForKeyPath:@"@sum.self"]);
    // 集合运算符之集合
    NSSet *nsset = [NSSet setWithArray:mutableArray];
    NSLog(@"计算set的count为：%@",[nsset valueForKeyPath:@"@count.self"]);
    
    NSMutableArray *objArray = [[NSMutableArray alloc]init];
    
    // 集合运算符之对象
    KVOModel *model1 = [[KVOModel alloc]init];
    model1.age = 10;
    [objArray addObject:model1];
    
    KVOModel *model2 = [[KVOModel alloc]init];
    model2.age = 30;
    [objArray addObject:model2];
    
    KVOModel *model3 = [[KVOModel alloc]init];
    model3.age = 50;
    [objArray addObject:model3];
    
    KVOModel *model4 = [[KVOModel alloc]init];
    model4.age = 30;
    [objArray addObject:model4];
    
    //返回的是一个数组distinctUnionOfObjects 去重后根据age返回的是一个数组 数组中放的是属性的结果
    // 个人理解这个是遍历对象然后拿出对象的对应的属性进行排序
    NSLog(@"去重的排序: %@",[objArray valueForKeyPath:@"@distinctUnionOfObjects.age"]);
    NSLog(@"不去重的排序: %@",[objArray valueForKeyPath:@"@unionOfObjects.age"]);
    
}

- (void)sortObjectMethod {
    
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        
        NSMutableArray *mutableArray = [[NSMutableArray alloc]init];
        for (NSUInteger i = 0; i < 100000; i ++) {
            NSUInteger j = arc4random()%1000000;
            [mutableArray addObject:@(j)];
        }
        NSLog(@"使用集合运算符 调用之前cpu用了  %@  memory用了 %@ ",@([SKKVCKVOVC cpuUsage]),@([SKKVCKVOVC memoryUsage]));
        uint64_t startTime = mach_absolute_time();
        id sum = [mutableArray valueForKeyPath:@"@sum.self"];
        NSLog(@"计算数组中元素的sum为：%@",sum);
        [self timeOfMach:startTime];
        NSLog(@"使用集合运算符 调用之后cpu用了  %@  memory用了 %@ ",@([SKKVCKVOVC cpuUsage]),@([SKKVCKVOVC memoryUsage]));
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self sortTypeMethod:mutableArray];
        });
    });
}


- (void)sortTypeMethod:(NSArray *)array {
    NSLog(@"使用for循环 调用之前cpu用了  %@  memory用了 %@ ",@([SKKVCKVOVC cpuUsage]),@([SKKVCKVOVC memoryUsage]));
    uint64_t startTime = mach_absolute_time();
    NSUInteger sum = 0;
    for (NSUInteger i = 0; i < array.count; i ++) {
        NSUInteger j = [array[i] intValue];
        sum +=j;
    }

    NSLog(@"计算数组中元素的sum为：%@",@(sum));
    [self timeOfMach:startTime];
    NSLog(@"使用for循环 调用之后cpu用了  %@  memory用了 %@ ",@([SKKVCKVOVC cpuUsage]),@([SKKVCKVOVC memoryUsage]));
    
    
}

- (void)methodCostTimeTest:(SEL)selector {
    uint64_t startTime = mach_absolute_time();
    [self performSelector:selector];
    [self timeOfMach:startTime];
    
}

// 手动设定实例变量的KVO
- (void)kvomodelselfSysthis {
    _selfSysModel = [[SKKVOStudentModel alloc]init];
    // stdAge 检测的是实例变量
    [_selfSysModel addObserver:self forKeyPath:@"stdAge" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    // stdName 监测的是属性变量
    [_selfSysModel addObserver:self forKeyPath:@"stdName" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
    _selfSysModel.stdName = @"Tom";
    // 使用点语法和setvalue都可以触发kvo 因为setvalue 调用的属性的setter方法
    [_selfSysModel setValue:@"12" forKey:@"stdAge"];
    
}
// 自己实现kvo 不用系统的
- (void)sysKVOModel {
    _testKVOModel = [[SKKVOStudentModel alloc]init];
    NSLog(@"添加观察者之前： %@  %@",_testKVOModel ,object_getClass(_testKVOModel));
    [_testKVOModel sk_addObserver:self forKey:@"stdName" withBlock:^(id  _Nonnull observedObject, NSString * _Nonnull observeKey, id  _Nonnull oldValue, id  _Nonnull newValue) {
        NSLog(@"observedObject===%@  observeKey===%@ oldValue===%@  newValue===%@",observedObject,observeKey,oldValue,newValue);
    }];
    _testKVOModel.stdName = @"kevin";
    NSLog(@"添加观察者之后： %@  %@",_testKVOModel ,object_getClass(_testKVOModel));

}

// 注意 只要添加观察者都会调用这个方法(注意：只要观察者的类中实现了willChangeValueForKey或didChangeValueForKey方法 这个观察方法就不会响应)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    NSLog(@"监听到===%@===的%@===改变了%@===", object, keyPath,change);
    NSLog(@"上下文====%@",context);
    if ([keyPath isEqualToString:@"age"]) {
        
    } else if ([keyPath isEqualToString:@"name"]) {
        
    }
}

- (void)kvcUsageMethod {
    
    // KVC 使用  KVC 赋值的时候可以使用 setvalueforkey  也可以是使用 setValueForKeypath.keypath 可以使用点语法(具体下面会做分析)
    SKKVCModel *kvcModel = [[SKKVCModel alloc]init];
    [kvcModel setValue:@"kevin" forKey:@"name"];
    [kvcModel setValue:@26 forKey:@"age"];
    [kvcModel setValue:@"9529" forKey:@"id"];
    SKKVCTestModel *testModel = [[SKKVCTestModel alloc]init];
    [kvcModel setValue:testModel forKey:@"model"];
    [kvcModel setValue:@"shave" forKeyPath:@"model.name"];
    NSLog(@"kvcModel name  is %@  kvcmodel.model.name is %@",[kvcModel valueForKey:@"name"],[kvcModel valueForKeyPath:@"model.name"]);
}


#pragma mark - additions method-

- (void)timeOfMach:(uint64_t)startTime {
    mach_timebase_info_data_t timebase;
    mach_timebase_info(&timebase);
    uint64_t end = mach_absolute_time();
    uint64_t cost = (end - startTime) * timebase.numer / timebase.denom;
    NSLog(@"方法耗时: %f ms",(CGFloat)cost / NSEC_PER_SEC * 1000.0);
}

+ (float)cpuUsage {
    return  cpu_usage();
}

float cpu_usage() {
    kern_return_t kr;
    task_info_data_t tinfo;
    mach_msg_type_number_t task_info_count;

    task_info_count = TASK_INFO_MAX;
    kr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)tinfo, &task_info_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }

    task_basic_info_t      basic_info;
    thread_array_t         thread_list;
    mach_msg_type_number_t thread_count;

    thread_info_data_t     thinfo;
    mach_msg_type_number_t thread_info_count;

    thread_basic_info_t basic_info_th;
    uint32_t stat_thread = 0; // Mach threads

    basic_info = (task_basic_info_t)tinfo;

    // get threads in the task
    kr = task_threads(mach_task_self(), &thread_list, &thread_count);
    if (kr != KERN_SUCCESS) {
        return -1;
    }
    if (thread_count > 0)
        stat_thread += thread_count;

    long tot_sec = 0;
    long tot_usec = 0;
    float tot_cpu = 0;
    int j;

    for (j = 0; j < thread_count; j++)
    {
        thread_info_count = THREAD_INFO_MAX;
        kr = thread_info(thread_list[j], THREAD_BASIC_INFO,
                         (thread_info_t)thinfo, &thread_info_count);
        if (kr != KERN_SUCCESS) {
            return -1;
        }

        basic_info_th = (thread_basic_info_t)thinfo;

        if (!(basic_info_th->flags & TH_FLAGS_IDLE)) {
            tot_sec = tot_sec + basic_info_th->user_time.seconds + basic_info_th->system_time.seconds;
            tot_usec = tot_usec + basic_info_th->user_time.microseconds + basic_info_th->system_time.microseconds;
            tot_cpu = tot_cpu + basic_info_th->cpu_usage / (float)TH_USAGE_SCALE * 100.0;
        }

    } // for each thread

    kr = vm_deallocate(mach_task_self(), (vm_offset_t)thread_list, thread_count * sizeof(thread_t));
    assert(kr == KERN_SUCCESS);

    return tot_cpu;
}

// 有的是除以1024，有的是除以1000。
+ (float)memoryUsage {
    vm_size_t memory = memory_usage();
    return memory / 1000.0 /1000.0;
}


vm_size_t memory_usage(void) {
    struct task_basic_info info;
    mach_msg_type_number_t size = sizeof(info);
    kern_return_t kerr = task_info(mach_task_self(), TASK_BASIC_INFO, (task_info_t)&info, &size);
    return (kerr == KERN_SUCCESS) ? info.resident_size : 0; // size in bytes
}

- (void)dealloc {
    // 没有add的不要移除 或者加上try catch  如果没有addobserve 就去移除 那么会crash
    @try {
        [self.kvoModel removeObserver:self forKeyPath:@"age"];
        [self.kvoModel removeObserver:self forKeyPath:@"name"];
        
        [self.selfSysModel removeObserver:self forKeyPath:@"stdAge"];
        [self.selfSysModel removeObserver:self forKeyPath:@"stdName"];
        
        [_testKVOModel sk_removeObserver:self forKey:@"stdName"];

        
    } @catch (NSException *exception) {
        NSLog(@"异常原因： %@",exception);
    } @finally {
        //
    }
}

@end
// 面试题解答：1.addObserver:forKeyPath:options:context:各个参数的作用分别是什么，observer中需要实现哪个方法才能获得KVO回调？
/*
 答：
 ```
 - (void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(nullable void *)context;
 ```
 方法中的参数为： observer 观察者 keyPath 进行kvo的观察属性 options 观察的选项 一般为新值NSKeyValueObservingOptionNew 和 旧值 NSKeyValueObservingOptionOld  context是上下文。
 
   在observer 实现下面的方法可以获取KVO回调
 ```
 - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{}
 ```
 中 各参数的作用是： keyPath 进行kvo设置的观察属性 object是被观察者对象本身  change 是一个字典里面包括 观察的类型 kind  new 新值 old 旧值
  context是上下文。这个值就是监听时候传的值
 */
// 面试题解答：2.如何手动触发一个value的KVO?
/*
 答：手动触发是为了和自动触做区分。
    自动触发的场景:在kvo注册之后，对要观察的属性进行赋值。那么就触发了。
    自动触发的原理：key  value 观察者方法依赖于willChangeValueForKey和didChangeValueForKey两个方法。在一个属性被观察者发生改变之前。willChangeValueForKey会先调用，这个时候回记录旧值，当发生改变后， didChangeValueForKey也会被调用，之后observeValueForKeyPath 会被调用。从change 里面的参数 old new 就可以看出。 所以，要实现手动调用 我们只需要触发willChangeValueForKey和didChangeValueForKey就可以了。
 具体实现参考方法:
 ```
 // 手动触发KVO
 - (void)handleKVOMethod {
     if (self.kvoModel) {
         self.kvoModel = [[KVOModel alloc]init];
     }
     self.kvoModel.name = @"hahaha";
     [self.kvoModel addObserver:self forKeyPath:@"name" options:NSKeyValueObservingOptionNew context:nil];
     [self.kvoModel willChangeValueForKey:@"name"];
     [self.kvoModel didChangeValueForKey:@"name"];
 }
 ```
总结：kvo触发原理，在我们调用setter方法的时候，系统会在调用setter方法之前调用willChangeValueForKey 以及didChangeValueForKey 然会调用observeValueForKeyPath
  具体可参考：apple 关于kvo 的说明:https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOCompliance.html#//apple_ref/doc/uid/20002178-SW3

 */
// 面试题解答：3. 若一个类有实例变量 NSString *_foo ，调用setValue:forKey:时，可以以foo还是 _foo 作为key？
/*
 答:都可以。前提条件是在实例变量在对应类中调用。如果是在其他类中实例化变量所在的类就不行。因为这个变量是类的私有属性。只有公开属性才可以使用。
 */

// 面试题解答：4.KVC的keyPath中的集合运算符如何使用？
/*
 答:在集合对象或者普通对象的集合属性。 才能使用。。具体可以看setObjectMethod中的例子。。通过对比发现使用集合运算符没有直接计算的效率高（通过集合运算符调用时候消耗的cpu和内存相较于使用for循环的时候相差比较大。这是在数量级在10w左右的时候，如果再增加数量级，差别会更大）
 */
// 面试题解答：5.KVC和KVO的keyPath一定是属性么？
/*
    KVC支持实例变量
    如果把一个对象的属性设定成属性，这个属性是个自动支持KVO的，如果这个对象是一个实例变量，那么这个KVO是需要我们自己来实现的。这个可以参考SKKVOStudentModel中关于实例变量的observer的实现
    其中在`+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)key `方法中 对所要观察的实例变量监测的时候做排除处理，同时在实现setter和getter的时候调用方法willChangeValueForKey 和didChangeValueForKey
 */
// 面试题解答：6.如何关闭默认的KVO的默认实现，并进入自定义的KVO实现？
/*
 答：  (1).关闭默认KVO的实现需要将类实现方法`automaticallyNotifiesObserversForKey:` 然后返回NO。
       (2). 自定义kvo的实现有逻辑如下:
           1.检查对象有没有对应的setter方法没有就抛出异常。
           2.检查对象isa指向的类是不是一个kvo类，如果不是，新建一个继承自原来类的子类，并把isa指向这个新建的子类。
           3.检查对象的KVO类重写过setter方法没,如果没有 添加重写setter方法
           4.添加观察者
           可参考类 NSObject+SKKVO 对KVO的实现
 
 
 参考链接：如何自己动手实现KVO  https://tech.glowing.com/cn/implement-kvo/
         KVO使用及实现原理 https://www.ctolib.com/topics-137765.html
 
 */
// 面试题解答：7.apple用什么方式实现对一个对象的KVO？
/*
 答：我们可以看apple文档对KVO的描述:
 ```
 Automatic key-value observing is implemented using a technique called isa-swizzling... When an observer is registered for an attribute of an object the isa pointer of the observed object is modified, pointing to an intermediate class rather than at the true class ...
 ```
在官方文档中，只是对kvo的实现做了简单的介绍，并未深入介绍。只是告诉我们使用了runtime技术。我们借助runtime来探究一下runtime的实现

 当观察一个对象时，一个新的类会被动态创建。这个类继承自该对象的原本的类，并重写了被观察属性的setter方法。重写的setter方法会负责在调用原setter方法之前和之后通知观察对象。值的更改。最后通过isa混写（isa-swizzling）把这个对象的isa指针指向这个新创建的子类。这样对象就神奇的变成了我们新创建的子类。
 这个使用的是黑魔法  使用isa混写isa-swizzling来实现kvo。
 
 下面是详细介绍：
 简直观察依赖于NSObject的两个方法`willChangeValueForKey`和`didChangeValueForKey`。在一个被观察者发生改变之前调用willChangeValueForKey记录旧值，当发生改变之后调用didChangeValueForKey记录新值。我们可以手动实现这些调用。一般我们希望在控制回调的时机才会这么做。改变通知会自动调用。
 ps:如果主动调用willChangeValueForKey和didChangeValueForKey而又不屏蔽类中对该属性KVO的观察的时候，这个时候会调用两次`-observeValueForKeyPath:ofObject:change:context:`。第一次是setter 方法内部调用 的 另外一种是willChangeValueForKey和didChangeValueForKey共同其作用的。
 
 “手动触发”的使用场景是什么？一般我们只在希望能控制“回调的调用时机”时才会这么做。

 而“回调的调用时机”就是在你调用 didChangeValueForKey: 方法时。
 
 参考链接：apple 对KVO实现的描述 https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html
 */
// 附加：KVO 缺点
/*
  答：KVO 我们经常使用在观察某个属性或者实例变量是否发生改变，虽然好用，但是我们用的时候你有没有发现它有哪些缺点呢？
     1.只能通过重写`-observeValueForKeyPath:ofObject:change:context:`方法来获取通知。想要用自己私有的selector不行。想要传一个block也不行。
     2.还要处理父类的情况(如果父类和子类都监听同一个对象的同一个属性，但是有时候父类虽然监听了 但是不一定需要处理。虽然可以用context这个参数个来处理但是写起来感觉很别扭)
     3.kvo如果不及时remove掉会造成crash
     4.如果要监测的对象是tableview的contentsize 那么在监测的方法中需要一大堆判断才行
 
 关于KVO的吐槽可以参考链接：http://khanlou.com/2013/12/kvo-considered-harmful/
 */
//  附加：KVC的实现原理是什么？
/*
 答：KVC的全称是key  value coding 定义在NSKeyValueCoding.h中，kvc提供了一种间接访问其属性方法或成员变量的机制。可以用过字符串来访问对应的属性方法或成员变量。KVC的实现主要依赖其搜索规则.
 搜索规则：KVC在通过key或者keypath的时候。可以查找属性方法，成员变量等。查找的时候可以兼容多种命名。
 官方文档是这样描述的：在KVC的实现中，依赖setter和getter的方法实现。所以方法命名应该符合苹果要求的规范，否者就会导致KVC失败。
 在了解搜索规则的时候有一个关键的属性我们需要了解`@property (class, readonly) BOOL accessInstanceVariablesDirectly;` 这个属性的意思是是否允许读取实例变量的值。如果是yes则在kvc的查找过程中，从内存中读取属性实例变量的值.（在没有找到存取器的时候才调用该方法）
 基础getter搜索模式：
 这是valueforkey:默认实现，给定一个key当做输入参数，开始下面的步骤，在这个接收valueForKey:方法调用的类内部进行操作。
 1.查找是否实现getter方法，依次匹配`-get<key>`和`-<key>`和 `is<key>`，如果找到，直接返回。
 需要注意的是:
 如果返回的是对象指针类型，则返回结果。
 如果返回的是NSNumber转化所支持的标量类型之一，则返回一个NSNumber否则将返回一个NSValue。
 2.当没有找到getter方法。调用`accessInstanceVariablesDirectly`询问，如果返回yes。则从 _<key>  _is<key> <key> is<key> 中找到对应的值。
 如果返回NO结束查找并调用valueForUndefinedKey:报异常。
 3.如果没有找到getter方法和属性值，就报valueForUndefinedKey: 异常。
 基础setter搜索模式：
 这是setValue:forKey的默认实现，给定输入参数value和key。试图在接受调用对象的内部，设置属性名为key的value，通过下面的步骤
 1.查找set<key>:或者_set<key>命名的setter。按照这个顺序，如果找到的话。调用这个方法并将值传进去(根据调用的对象进行类型转换)
 2.如果设置setter 但是`accessInstanceVariablesDirectly`返回为yes，那么查找的命名规则为 _<key>  _is<key> <key> is<key>的实例变量。根据这个顺序将发现则将value赋值给实例变量。
 3.如果没有发现setter或实例变量，则调用setValueForUndefinedKey:方法。并抛出一个异常。
 由此可以看出：kvc的性能访问属性并没有直接访问的快(因为他要有按照搜索规则进行搜索) 本质上是操作方法列表以及在内存中去查找实例变量。这个操作对readonley以及protected成员变量，都可以正常访问。如果不想外界访问的话可以将accessInstanceVariablesDirectly设置为NO。
 
 在iOS 13之前 我们是可以使用私有变量去访问属性的。例如更改textfield的一些颜色属性。
 
 缺点：因为传入的setvalueforkey以及setvalueforkeypath valueforkey 以及 valuefotkeypath是一个字符串。所以编译器不在编译的时候不会报错。但是在运行的时候，如果设置或者获取的属性不存在。那么就会报undefinedkey 会crash。
 //
 */
// 面试题解答：8.KVC能否触发KVO？说明理由。
/*
   答：会。原因是：KVC调用的就是setter方法，当然会触发KVO. 具体可参考KVC的实现原理以及kvo的实现原理。
 */
