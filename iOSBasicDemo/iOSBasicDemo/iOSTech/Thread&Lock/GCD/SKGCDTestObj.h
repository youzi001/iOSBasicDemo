//
//  SKGCDTestObj.h
//  iOSBasicDemo
//
//  Created by shavekevin on 2019/10/18.
//  Copyright © 2019 小风. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 面试题： 1.GCD的队列（dispatch_queue_t）分哪两种类型？
// 面试题： 2.dispatch_barrier_async的作用是什么？
// 面试题： 3.苹果为什么要废弃dispatch_get_current_queue？
// 面试题： 4.如何用GCD同步若干个异步调用？（如根据若干个url异步加载多张图片，然后在都下载完成后合成一张整图）。
// 面试题： 5.以下代码运行结果如何？
// 面试题： 6.dispatch_once 原理是什么？

@interface SKGCDTestObj : NSObject
// 串行队列
- (void)createSerialQueue;
//并行队列
- (void)createConcurrentQueue;
// barrier
- (void)createDispatchBarrierAsync;
// dispatchNotify
- (void)createDispatchNotify;
// 死锁
- (void)createDeadLock;
// 通过队列标识实现可重入
- (void)queueSetSpecificFunc;
// 递归锁实现可重入
- (void)reentrantMethod;
// 同步主线程
- (void)syncMainThread;

@end

NS_ASSUME_NONNULL_END
