//
//  NSObject+SKKVO.m
//  iOSBasicDemo
//
//  Created by shavekevin on 2019/10/28.
//  Copyright © 2019 小风. All rights reserved.
//
// 这是参照链接：https://tech.glowing.com/cn/implement-kvo/ 中的代码实现的
// 项目github地址:https://github.com/okcomp/ImplementKVO

#import "NSObject+SKKVO.h"
#import <objc/runtime.h>
#import <objc/message.h>



NSString *const kSKKVOClassPrefix = @"SKKVOClassPrefix_";
NSString *const kSKKVOAssociatedObservers = @"SKKVOAssociatedObservers";

// 观察者保存的信息

#pragma mark - SKObservationInfo
@interface SKObservationInfo : NSObject
// 观察者
@property (nonatomic, weak) NSObject *observer;
// 观察的key
@property (nonatomic, copy) NSString *key;
// block
@property (nonatomic, copy) SKObservingBlock block;

@end

@implementation SKObservationInfo

- (instancetype)initWithObserver:(NSObject *)observer Key:(NSString *)key block:(SKObservingBlock)block {
    self = [super init];
    if (self) {
        _observer = observer;
        _key = key;
        _block = block;
    }
    return self;
}

@end


#pragma mark - Debug Help Methods

// 获取类中方法列表
static NSArray *ClassMethodNames(Class c) {
    
    NSMutableArray *array = [NSMutableArray array];
    unsigned int methodCount = 0;
    Method *methodList = class_copyMethodList(c, &methodCount);
    unsigned int i;
    for(i = 0; i < methodCount; i++) {
        [array addObject: NSStringFromSelector(method_getName(methodList[i]))];
    }
    free(methodList);
    
    return array;
}

// debug打印描述
static void PrintDescription(NSString *name, id obj) {
    NSString *str = [NSString stringWithFormat:
                     @"%@: %@\n\tNSObject class %s\n\tRuntime class %s\n\timplements methods <%@>\n\n",
                     name,
                     obj,
                     class_getName([obj class]),
                     class_getName(object_getClass(obj)),
                     [ClassMethodNames(object_getClass(obj)) componentsJoinedByString:@", "]];
    printf("%s\n", [str UTF8String]);
}


#pragma mark - Helpers
// 工具 获取setter和getter方法
static NSString *getterForSetter(NSString *setter)
{
    if (setter.length <=0 || ![setter hasPrefix:@"set"] || ![setter hasSuffix:@":"]) {
        return nil;
    }
    
    // remove 'set' at the begining and ':' at the end
    NSRange range = NSMakeRange(3, setter.length - 4);
    NSString *key = [setter substringWithRange:range];
    
    // lower case the first letter
    NSString *firstLetter = [[key substringToIndex:1] lowercaseString];
    key = [key stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                       withString:firstLetter];
    
    return key;
}


static NSString * setterForGetter(NSString *getter)
{
    if (getter.length <= 0) {
        return nil;
    }
    
    // upper case the first letter
    NSString *firstLetter = [[getter substringToIndex:1] uppercaseString];
    NSString *remainingLetters = [getter substringFromIndex:1];
    
    // add 'set' at the begining and ':' at the end
    NSString *setter = [NSString stringWithFormat:@"set%@%@:", firstLetter, remainingLetters];
    
    return setter;
}


#pragma mark - Overridden Methods
static void kvo_setter(id self, SEL _cmd, id newValue)
{
    NSString *setterName = NSStringFromSelector(_cmd);
    NSString *getterName = getterForSetter(setterName);
    
    if (!getterName) {
        NSString *reason = [NSString stringWithFormat:@"Object %@ does not have setter %@", self, setterName];
        @throw [NSException exceptionWithName:NSInvalidArgumentException
                                       reason:reason
                                     userInfo:nil];
        return;
    }
    
    id oldValue = [self valueForKey:getterName];
    
    struct objc_super superclazz = {
        .receiver = self,
        .super_class = class_getSuperclass(object_getClass(self))
    };
    
    // cast our pointer so the compiler won't complain
    void (*objc_msgSendSuperCasted)(void *, SEL, id) = (void *)objc_msgSendSuper;
    
    // call super's setter, which is original class's setter method
    objc_msgSendSuperCasted(&superclazz, _cmd, newValue);
    
    // look up observers and call the blocks
    NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kSKKVOAssociatedObservers));
    for (SKObservationInfo *each in observers) {
        if ([each.key isEqualToString:getterName]) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                each.block(self, getterName, oldValue, newValue);
            });
        }
    }
}


static Class kvo_class(id self, SEL _cmd)
{
    return class_getSuperclass(object_getClass(self));
}




@implementation NSObject (SKKVO)
- (void)sk_addObserver:(NSObject *)observer forKey:(NSString *)key withBlock:(SKObservingBlock)block {
    SEL setterSelector = NSSelectorFromString(setterForGetter(key));
    Method setterMethod = class_getInstanceMethod([self class], setterSelector);
    if (!setterMethod) {
          NSString *reason = [NSString stringWithFormat:@"Object %@ does not have a setter for key %@", self, key];
          @throw [NSException exceptionWithName:NSInvalidArgumentException
                                         reason:reason
                                       userInfo:nil];
          
          return;
      }
      
      Class clazz = object_getClass(self);
      NSString *clazzName = NSStringFromClass(clazz);
      
      // if not an KVO class yet
      if (![clazzName hasPrefix:kSKKVOClassPrefix]) {
          clazz = [self makeKvoClassWithOriginalClassName:clazzName];
          object_setClass(self, clazz);
      }
      
      // add our kvo setter if this class (not superclasses) doesn't implement the setter?
      if (![self hasSelector:setterSelector]) {
          const char *types = method_getTypeEncoding(setterMethod);
          class_addMethod(clazz, setterSelector, (IMP)kvo_setter, types);
      }
      
      SKObservationInfo *info = [[SKObservationInfo alloc] initWithObserver:observer Key:key block:block];
      NSMutableArray *observers = objc_getAssociatedObject(self, (__bridge const void *)(kSKKVOAssociatedObservers));
      if (!observers) {
          observers = [NSMutableArray array];
          objc_setAssociatedObject(self, (__bridge const void *)(kSKKVOAssociatedObservers), observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }
      [observers addObject:info];
}

// 移除观察者
- (void)sk_removeObserver:(NSObject *)observer forKey:(NSString *)key {
    
    NSMutableArray* observers = objc_getAssociatedObject(self, (__bridge const void *)(kSKKVOAssociatedObservers));
      SKObservationInfo *infoToRemove;
    // 拿到所以观察者数组 然后遍历观察者信息 如果key 一致就移除观察者(其实这里我觉得并不仅仅需要判断key 还要判断对象是否一致。。如果同时观察几个对象并且这些对象都对同样的属性或者变量进行观察 那么，如果一样可能会移除的可能并不是目标对象的key)
      for (SKObservationInfo* info in observers) {
          if (info.observer == observer && [info.key isEqual:key]) {
              infoToRemove = info;
              break;
          }
      }
      [observers removeObject:infoToRemove];
}

//  替换kvo的method
- (Class)makeKvoClassWithOriginalClassName:(NSString *)originalClazzName {
    NSString *kvoClazzName = [kSKKVOClassPrefix stringByAppendingString:originalClazzName];
    Class clazz = NSClassFromString(kvoClazzName);
    
    if (clazz) {
        return clazz;
    }
    
    // class doesn't exist yet, make it
    Class originalClazz = object_getClass(self);
    Class kvoClazz = objc_allocateClassPair(originalClazz, kvoClazzName.UTF8String, 0);
    
    // grab class method's signature so we can borrow it
    Method clazzMethod = class_getInstanceMethod(originalClazz, @selector(class));
    const char *types = method_getTypeEncoding(clazzMethod);
    class_addMethod(kvoClazz, @selector(class), (IMP)kvo_class, types);
    
    objc_registerClassPair(kvoClazz);
    
    return kvoClazz;
}

// 是否存在方法
- (BOOL)hasSelector:(SEL)selector {
    Class clazz = object_getClass(self);
    unsigned int methodCount = 0;
    Method* methodList = class_copyMethodList(clazz, &methodCount);
    for (unsigned int i = 0; i < methodCount; i++) {
        SEL thisSelector = method_getName(methodList[i]);
        if (thisSelector == selector) {
            free(methodList);
            return YES;
        }
    }
    free(methodList);
    return NO;
}

@end
