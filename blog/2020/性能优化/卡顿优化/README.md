

> 应用卡顿是让人头疼的问题，不像闪退一样直观明了，可以直接通过异常信号或调用栈分析得到，常常让人无处下手。文章按 `认识卡顿 -> 优化卡顿 -> 监控卡顿` 顺序，希望让读者对卡顿有更深刻的认识。

## 认识卡顿
### 一些概念

- FPS：Frames Per Second，表示每秒渲染的帧数，通过用于衡量画面的流畅度，数值越高则表示画面越流畅。
- CPU：负责对象的创建和销毁、对象属性的调整、布局计算、文本的计算和排版、图片的格式转换和解码、图像的绘制（Core Graphics）。
- GPU: 负责纹理的渲染(将数据渲染到屏幕)。
- 垂直同步技术: 让CPU和GPU在收到vSync信号后再开始准备数据，防止撕裂感和跳帧，通俗来讲就是保证每秒输出的帧数不高于屏幕显示的帧数。  
- 双缓冲技术：iOS是双缓冲机制，前帧缓存和后帧缓存,cpu计算完GPU渲染后放入缓冲区中,当gpu下一帧已经渲染完放入缓冲区，且视频控制器已经读完前帧，GPU会等待vSync(垂直同步信号)信号发出后,瞬间切换前后帧缓存，并让cpu开始准备下一帧数据，安卓4.0后采用三重缓冲，多了一个后帧缓冲，可降低连续丢帧的可能性，但会占用更多的CPU和GPU  。

### 图像显示

图像的显示可以简单理解成先经过 CPU 的计算/排版/编解码等操作，然后交由 GPU 去完成渲染放入缓冲中，当视频控制器接受到 vSync 时会从缓冲中读取已经渲染完成的帧并显示到屏幕上。  

![成像](https://user-gold-cdn.xitu.io/2019/10/24/16dfcc4181755044?w=1162&h=516&f=png&s=156490)



### 卡顿原因

正常情况下，iOS 手机默认显示刷新频率是 60hz，所以 GPU 渲染只要达到 60fps 就不会产生卡顿。

以 60fps 为例，vSync 会每 16.67ms 渲染一次，如在16.67ms内没有准备好下一帧数据就会使画面停留在上一帧，这就造成了卡顿。例如图中第3帧渲染完成之前一直显示的是第2帧的内容。 

![卡顿原理](https://user-gold-cdn.xitu.io/2019/10/24/16dfcd55340d35d2?w=2800&h=788&f=png&s=142667)

这样我们就清楚了，只要能使 CPU 的计算和 GPU 的渲染能在规定时间内完成，就可以完美解决卡顿。所以我们的目标：**尽量减小CPU和GPU的资源消耗，使其有足够的资源完成计算和渲染工作。**



##    优化卡顿

### CPU

-   尽量用轻量级的对象，比如用不到事件处理的地方使用CALayer取代UIView
-   尽量提前计算好布局（例如cell行高）
-   不要频繁地调用和调整UIView的相关属性，比如frame、bounds、transform等属性，尽量减少不必要的调用和修改(UIView的显示属性实际都是CALayer的映射，而CALayer本身是没有这些属性的，都是初次调用属性时通过resolveInstanceMethod添加并创建Dictionry保存的，耗费资源)
-   Autolayout会比直接设置frame消耗更多的CPU资源，当视图数量增长时会呈指数级增长
-   图片的size最好刚好跟UIImageView的size保持一致，减少图片显示时的处理计算
-   控制一下线程的最大并发数量
-   尽量把耗时的操作放到子线程
-   文本处理（尺寸计算、绘制、CoreText和YYText）
    1.  计算文本宽高boundingRectWithSize:options:context: 和文本绘制drawWithRect:options:context:放在子线程操作
    2.  使用CoreText自定义文本空间，在对象创建过程中可以缓存宽高等信息，避免像UILabel/UITextView需要多次计算(调整和绘制都要计算一次)，且CoreText直接使用了CoreGraphics占用内存小，效率高。（YYText）
-   图片处理（解码、绘制）
图片都需要先解码成bitmap才能渲染到UI上，iOS创建UIImage，不会立刻进行解码，只有等到显示前才会在**主线程**进行解码，固可以使用Core Graphics中的CGBitmapContextCreate相关操作提前在子线程中进行强制解压缩获得位图
(YYImage/SDWebImage/kingfisher的对比)

```
SDWebImage的使用:
 CGImageRef imageRef = image.CGImage;
        // device color space
        CGColorSpaceRef colorspaceRef = SDCGColorSpaceGetDeviceRGB();
        BOOL hasAlpha = SDCGImageRefContainsAlpha(imageRef);
        // iOS display alpha info (BRGA8888/BGRX8888)
        CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host;
        bitmapInfo |= hasAlpha ? kCGImageAlphaPremultipliedFirst : kCGImageAlphaNoneSkipFirst;
        
        size_t width = CGImageGetWidth(imageRef);
        size_t height = CGImageGetHeight(imageRef);
        
        // kCGImageAlphaNone is not supported in CGBitmapContextCreate.
        // Since the original image here has no alpha info, use kCGImageAlphaNoneSkipLast
        // to create bitmap graphics contexts without alpha info.
        CGContextRef context = CGBitmapContextCreate(NULL,
                                                     width,
                                                     height,
                                                     kBitsPerComponent,
                                                     0,
                                                     colorspaceRef,
                                                     bitmapInfo);
        if (context == NULL) {
            return image;
        }
        
        // Draw the image into the context and retrieve the new bitmap image without alpha
        CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
        CGImageRef imageRefWithoutAlpha = CGBitmapContextCreateImage(context);
        UIImage *imageWithoutAlpha = [[UIImage alloc] initWithCGImage:imageRefWithoutAlpha scale:image.scale orientation:image.imageOrientation];
        CGContextRelease(context);
        CGImageRelease(imageRefWithoutAlpha);
        
        return imageWithoutAlpha;
```

###    GPU
- 尽量避免短时间内大量图片的显示，尽可能将多张图片合成一张进行显示

- GPU能处理的最大纹理尺寸是4096x4096，一旦超过这个尺寸，就会占用CPU资源进行处理，所以纹理尽量不要超过这个尺寸

- GPU会将多个视图混合在一起再去显示，混合的过程会消耗CPU资源，尽量减少视图数量和层次

- 减少透明的视图（alpha<1），不透明的就设置opaque为YES，GPU就不会去进行alpha的通道合成

- 尽量避免出现离屏渲染

  

### 离屏渲染

这里特别说下离屏渲染，对 GPU 的资源消耗极大。
在OpenGL中，GPU有2种渲染方式，分别是**屏幕渲染（On-Screen Rendering）**和**离屏渲染（Off-Screen Rendering）**，区别在于渲染操作是在当前用于显示的屏幕缓冲区进行还是新开辟一个缓冲区进行渲染，渲染完成后再在当前显示的屏幕展示。

离屏渲染消耗性能的原因，在于需要创建新的缓冲区，并且在渲染的整个过程中，需要多次切换上下文环境，先是从当前屏幕（On-Screen）切换到离屏（Off-Screen）；等到离屏渲染结束以后，将离屏缓冲区的渲染结果显示到屏幕上，又需要将上下文环境从离屏切换到当前屏幕，造成了资源的及大小消耗。

一些会触发离屏渲染的操作：

-  光栅化，layer.shouldRasterize = YES

-  遮罩，layer.mask

-  圆角，同时设置layer.masksToBounds = YES、layer.cornerRadius大于0
   考虑通过CoreGraphics绘制裁剪圆角，或者叫美工提供圆角图片

-  阴影，layer.shadowXXX
   如果设置了layer.shadowPath就不会产生离屏渲染






##    卡顿监控
###    Xcode 自带 Instruments
在开发阶段，可以直接使用 Instrument 来检测性能问题, Time Profiler 查看与 CPU 相关的耗时操作，Core Animation 查看与 GPU 相关的渲染操作。

###    FPS（CADisplayLink）
正常情况下，App的FPS只要保持在50~60之间，用户就不会感到界面卡顿。通过向主线程添加CADisplayLink我们可以接收到每次屏幕刷新的回调，从而统计出每秒屏幕刷新次数。这种方案最常见，例如 [YYFPSLabel](https://github.com/ibireme/YYText/blob/master/Demo/YYTextDemo/YYFPSLabel.m)，且只用了CADisplayLink，实现成本较低，但由于只能在CPU空闲时才去回调，无法精确采集到卡顿时调用栈信息，可以在开发阶段作为辅助手段使用。
```

//
//  YYFPSLabel.m
//  YYKitExample
//
//  Created by ibireme on 15/9/3.
//  Copyright (c) 2015 ibireme. All rights reserved.
//

#import "YYFPSLabel.h"
//#import <YYKit/YYKit.h>
#import "YYText.h"
#import "YYWeakProxy.h"

#define kSize CGSizeMake(55, 20)

@implementation YYFPSLabel {
    CADisplayLink *_link;
    NSUInteger _count;
    NSTimeInterval _lastTime;
    UIFont *_font;
    UIFont *_subFont;
    
    NSTimeInterval _llll;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (frame.size.width == 0 && frame.size.height == 0) {
        frame.size = kSize;
    }
    self = [super initWithFrame:frame];
    
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
    self.textAlignment = NSTextAlignmentCenter;
    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor colorWithWhite:0.000 alpha:0.700];
    
    _font = [UIFont fontWithName:@"Menlo" size:14];
    if (_font) {
        _subFont = [UIFont fontWithName:@"Menlo" size:4];
    } else {
        _font = [UIFont fontWithName:@"Courier" size:14];
        _subFont = [UIFont fontWithName:@"Courier" size:4];
    }
    // 创建CADisplayLink并添加到主线程的RunLoop中
    _link = [CADisplayLink displayLinkWithTarget:[YYWeakProxy proxyWithTarget:self] selector:@selector(tick:)];
    [_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    return self;
}

- (void)dealloc {
    [_link invalidate];
}

- (CGSize)sizeThatFits:(CGSize)size {
    return kSize;
}

//刷新回调时去计算fps
- (void)tick:(CADisplayLink *)link {
    if (_lastTime == 0) {
        _lastTime = link.timestamp;
        return;
    }
    
    _count++;
    NSTimeInterval delta = link.timestamp - _lastTime;
    if (delta < 1) return;
    _lastTime = link.timestamp;
    float fps = _count / delta;
    _count = 0;
    
    CGFloat progress = fps / 60.0;
    UIColor *color = [UIColor colorWithHue:0.27 * (progress - 0.2) saturation:1 brightness:0.9 alpha:1];
    
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%d FPS",(int)round(fps)]];
    [text yy_setColor:color range:NSMakeRange(0, text.length - 3)];
    [text yy_setColor:[UIColor whiteColor] range:NSMakeRange(text.length - 3, 3)];
    text.yy_font = _font;
    [text yy_setFont:_subFont range:NSMakeRange(text.length - 4, 1)];
    
    self.attributedText = text;
}

@end
```

###    RunLoop 监听
关于RunLoop，推荐参考[深入理解RunLoop](https://blog.ibireme.com/2015/05/18/runloop/)，这里只列出其简化版的状态。

![经典图片](https://user-gold-cdn.xitu.io/2019/10/24/16dfce7adc76f184?w=1294&h=996&f=png&s=225409)
```
// 1.进入loop
__CFRunLoopRun(runloop, currentMode, seconds, returnAfterSourceHandled)

// 2.RunLoop 即将触发 Timer 回调。
__CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeTimers);
// 3.RunLoop 即将触发 Source0 (非port) 回调。
__CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeSources);
// 4.RunLoop 触发 Source0 (非port) 回调。
sourceHandledThisLoop = __CFRunLoopDoSources0(runloop, currentMode, stopAfterHandle)
// 5.执行被加入的block等Source1事件
__CFRunLoopDoBlocks(runloop, currentMode);

// 6.RunLoop 的线程即将进入休眠(sleep)。
__CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopBeforeWaiting);

// 7.调用 mach_msg 等待接受 mach_port 的消息。线程将进入休眠, 直到被下面某一个事件唤醒。
__CFRunLoopServiceMachPort(waitSet, &msg, sizeof(msg_buffer), &livePort)


// 进入休眠


// 8.RunLoop 的线程刚刚被唤醒了。
__CFRunLoopDoObservers(runloop, currentMode, kCFRunLoopAfterWaiting

// 9.1.如果一个 Timer 到时间了，触发这个Timer的回调
__CFRunLoopDoTimers(runloop, currentMode, mach_absolute_time())

// 9.2.如果有dispatch到main_queue的block，执行bloc
 __CFRUNLOOP_IS_SERVICING_THE_MAIN_DISPATCH_QUEUE__(msg);
 
 // 9.3.如果一个 Source1 (基于port) 发出事件了，处理这个事件
__CFRunLoopDoSource1(runloop, currentMode, source1, msg);

// 10.RunLoop 即将退出
__CFRunLoopDoObservers(rl, currentMode, kCFRunLoopExit);

```
source0 处理的是 app 内部事件，包括 UI 事件，每次处理的开始和结束的耗时决定了当前页面刷新是否正常，即 kCFRunLoopBeforeSources 和 kCFRunLoopAfterWaiting 之间。因此创建一个子线程去监听主线程状态变化，通过dispatch_semaphore 在主线程进入上面两个状态时发送信号量，子线程设置超时时间循环等待信号量，若超过时间后还未接收到主线程发出的信号量则可判断为卡顿，此时可以保存当前调用栈信息作为后续分析依据，线上卡顿监控多采用这种方式，代码实现如下。

```
#pragma mark - 注册RunLoop观察者

//在主线程注册RunLoop观察者
- (void)registerMainRunLoopObserver
{
    //监听每个步凑的回调
    CFRunLoopObserverContext context = {0, (__bridge void*)self, NULL, NULL};
    self.runLoopObserver = CFRunLoopObserverCreate(kCFAllocatorDefault,
                                                   kCFRunLoopAllActivities,
                                                   YES,
                                                   0,
                                                   &runLoopObserverCallBack,
                                                   &context);
    CFRunLoopAddObserver(CFRunLoopGetMain(), self.runLoopObserver, kCFRunLoopCommonModes);
}

//观察者方法
static void runLoopObserverCallBack(CFRunLoopObserverRef observer, CFRunLoopActivity activity, void *info)
{
    self.runLoopActivity = activity;
    //触发信号，说明开始执行下一个步骤。
    if (self.semaphore != nil)
    {
        dispatch_semaphore_signal(self.semaphore);
    }
}

#pragma mark - RunLoop状态监测

//创建一个子线程去监听主线程RunLoop状态
- (void)createRunLoopStatusMonitor
{
    //创建信号
    self.semaphore = dispatch_semaphore_create(0);
    if (self.semaphore == nil)
    {
        return;
    }
    
    //创建一个子线程，监测Runloop状态时长
    dispatch_async(dispatch_get_global_queue(0, 0), ^
    {
        while (YES)
        {
            //如果观察者已经移除，则停止进行状态监测
            if (self.runLoopObserver == nil)
            {
                self.runLoopActivity = 0;
                self.semaphore = nil;
                return;
            }
            
            //信号量等待。状态不等于0，说明状态等待超时
        //方案一->设置单次超时时间为500毫秒
            long status = dispatch_semaphore_wait(self.semaphore, dispatch_time(DISPATCH_TIME_NOW, 500 * NSEC_PER_MSEC));
            if (status != 0)
            {
                if (self.runLoopActivity == kCFRunLoopBeforeSources || self.runLoopActivity == kCFRunLoopAfterWaiting)
                {
                    ...
                    //发生超过500毫秒的卡顿，此时去记录调用栈信息
                }
            }
        /*
       //方案二->连续5次卡顿50ms上报
        long status = dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, 50*NSEC_PER_MSEC));
        if (status != 0)
        {
            if (!observer)
            {
                timeoutCount = 0;
                semaphore = 0;
                activity = 0;
                return;
            }
            
            if (activity==kCFRunLoopBeforeSources || activity==kCFRunLoopAfterWaiting)
            {
                if (++timeoutCount < 5)
                    continue;
                //保存调用栈信息
            }
        }
        timeoutCount = 0;
        */
        }
    });
}

```
###    子线程Ping
根据卡顿发生时，主线程无响应的原理，创建一个子线程循环去Ping主线程，Ping之前先设卡顿置标志为True，再派发到主线程执行设置标志为False，最后子线程在设定的阀值时间内休眠结束后判断标志来判断主线程有无响应。该方法的监控准确性和性能损耗与ping频率成正比。  
代码部分来源于 [ANREye](https://github.com/zixun/ANREye)

```
private class AppPingThread: Thread {
    
    
    private let semaphore = DispatchSemaphore(value: 0)
    //判断主线程是否卡顿的标识
    private var isMainThreadBlock = false
    
    private var threshold: Double = 0.4
    
    fileprivate var handler: (() -> Void)?
    
    func start(threshold:Double, handler: @escaping AppPingThreadCallBack) {
        self.handler = handler
        self.threshold = threshold
        self.start()
    }
    
    override func main() {
        
        while self.isCancelled == false {
            self.isMainThreadBlock = true
            //主线程去重置标识
            DispatchQueue.main.async {
                self.isMainThreadBlock = false
                self.semaphore.signal()
            }
            
            Thread.sleep(forTimeInterval: self.threshold)
            //若标识未重置成功则说明再设置的阀值时间内主线程未响应，此时去做响应处理
            if self.isMainThreadBlock  {
                //采集卡顿调用栈信息
                self.handler?()
            }
            
            _ = self.semaphore.wait(timeout: DispatchTime.distantFuture)
        }
    }
    

}
```

## 参考文章

- [iOS 保持界面流畅的技巧](https://blog.ibireme.com/2015/11/12/smooth_user_interfaces_for_ios/)
- [屏幕成像原理](https://www.jianshu.com/p/3b32b1c99e7e)
- [iOS 性能优化总结 ](http://www.sohu.com/a/228462327_208051) 
- [质量监控-卡顿检测](https://juejin.im/post/6844903686620053512)

