//
//  ViewController.m
//  asyncRequestRelyon
//
//  Created by 张健 on 16/8/11.
//  Copyright © 2016年 ZJTechnology. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    [self setupRunLoop];
//    [self setupGCDGroup];
//    [self setupGCDBarrier];
    [self setupOperation];
}


/**
 *  RunLoop
 *  logs:
    2016-08-11 16:00:01.213 asyncRequestRelyon[83096:4474043] B
    2016-08-11 16:00:01.458 asyncRequestRelyon[83096:4473854] A
 */
- (void)setupRunLoop{
    NSURLRequest *quest = [[NSURLRequest alloc] initWithURL:[[NSURL alloc] initWithString:@"www.baidu.com"]];
    NSURLSessionConfiguration*configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
    NSURLSessionTask *task = [session dataTaskWithRequest:quest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        // 由于此处是子线程，所以应该使用CFRunLoopGetMain()，而不是CFRunLoopGetCurrent()
        CFRunLoopStop(CFRunLoopGetMain());
        NSLog(@"B");
    } ];
    [task resume];
    CFRunLoopRun();
    NSLog(@"A");
}

/**
 *  GCD Group
 *  dispatch_group_notify就是需要等queue里面的子线程都执行完毕之后才会执行
 *  logs:
 2016-08-11 16:04:32.355 asyncRequestRelyon[83126:4477533] B
 2016-08-11 16:04:32.356 asyncRequestRelyon[83126:4477533] A
 */
- (void)setupGCDGroup{
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create(0, 0);
    dispatch_group_async(group, queue, ^{
        NSLog(@"B");
    });
    dispatch_group_notify(group, queue, ^{
        NSLog(@"A");
    });
}

/**
 *  GCD Barrier
 *  dispatch_barrier_async, 会让barrier之前的线程执行完成之后才会执行barrier后面的操作
 *  logs:
 (无barrier)
 2016-08-11 16:12:49.501 asyncRequestRelyon[83277:4484707] A
 2016-08-11 16:12:49.501 asyncRequestRelyon[83277:4484724] C
 2016-08-11 16:12:49.502 asyncRequestRelyon[83277:4484734] E
 2016-08-11 16:12:49.501 asyncRequestRelyon[83277:4484733] D
 2016-08-11 16:12:49.501 asyncRequestRelyon[83277:4484716] B
 (有barrier)
 2016-08-11 16:13:09.740 asyncRequestRelyon[83300:4485409] C
 2016-08-11 16:13:09.740 asyncRequestRelyon[83300:4485386] B
 2016-08-11 16:13:09.740 asyncRequestRelyon[83300:4485406] A
 2016-08-11 16:13:09.741 asyncRequestRelyon[83300:4485406] 00
 2016-08-11 16:13:09.742 asyncRequestRelyon[83300:4485406] D
 2016-08-11 16:13:09.742 asyncRequestRelyon[83300:4485386] E
 */
- (void)setupGCDBarrier{
    dispatch_queue_t queue = dispatch_queue_create(0, DISPATCH_QUEUE_CONCURRENT);
    dispatch_async(queue, ^{
        NSLog(@"A");
    });
    dispatch_async(queue, ^{
        NSLog(@"B");
    });
    dispatch_async(queue, ^{
        NSLog(@"C");
    });
    dispatch_barrier_async(queue, ^{
        NSLog(@"00");
    });
    dispatch_async(queue, ^{
        NSLog(@"D");
    });
    dispatch_async(queue, ^{
        NSLog(@"E");
    });
}


/**
 *  NSOperation
 *  使用对象方法:addDependency
 *  logs:
 (waitUntilFinished为NO)
 2016-08-11 16:18:17.415 asyncRequestRelyon[83328:4488509] 00
 2016-08-11 16:18:17.415 asyncRequestRelyon[83328:4488615] C
 2016-08-11 16:18:17.417 asyncRequestRelyon[83328:4488624] B
 2016-08-11 16:18:17.417 asyncRequestRelyon[83328:4488634] A
 (waitUntilFinished为YES)
 2016-08-11 16:19:49.685 asyncRequestRelyon[83353:4489793] C
 2016-08-11 16:19:49.686 asyncRequestRelyon[83353:4489793] B
 2016-08-11 16:19:49.686 asyncRequestRelyon[83353:4489793] A
 2016-08-11 16:19:49.686 asyncRequestRelyon[83353:4489616] 00
 */
- (void)setupOperation{
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    NSBlockOperation *op1 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"A");
    }];
    NSBlockOperation *op2 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"B");
    }];
    NSBlockOperation *op3 = [NSBlockOperation blockOperationWithBlock:^{
        NSLog(@"C");
    }];
    [op1 addDependency:op2];
    [op2 addDependency:op3];
    // waitUntilFinished是否阻塞当前线程
    [queue addOperations:@[op1,op2,op3] waitUntilFinished:YES];
    NSLog(@"00");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
