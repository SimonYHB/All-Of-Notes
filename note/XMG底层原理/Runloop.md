## Runloop

```
NSRunloop是对CFRunLoop的包装

struct __CFRunLoop {
	pthread_t _thread;
	CFMutableSetRef _commonModes;
	CFMutableSetREF _commonModeItems;
	CFRunLoopModeRef _currentMode;
	CFMutableSetREF modes;
}

struct _CFRunLoopMode {
	CFStringRef _name
	CFMutableSetRef _source0; //事件的处理
	CFMutableSetRef _source1; //处理基于Port的线程间通信，系统事件的捕捉（识别到后封装给Source0处理）
	CFMutableArrayRef _observers; // 监听Runloop的状态和UI刷新
	CFMutableArrayRef _times; // 定时器
}
```



### 线程与runloop

每个线程都有唯一的runloop，创建线程时不会开启，只有在第一次使用时才创建

所有线程的runloop保存在一个全局字典里，thread为key，runloop为value

### GCD与runloop

GCD是不依赖于runloop的，只有在切换回主线程时才会通过runloop去处理

### 休眠

runloop的休眠等待是通过mach_msg()切换到内核态实现的，是真正的休眠，在有消息时才会占用CPUI，与线程阻塞不同

### 应用-线程保活

往线程的runloop里面添加Source/Timer/Observer，不要使用run开启，run是专门用于开启一个永不释放的线程，需要自己实现，通过while循环+标记实现

释放持有者时要停止runloop并手动释放











### Q

- 项目中应用

  - 控制线程生命周期（线程保活）
  - 监控卡顿
  - 性能优化
  - 解决NSTimer滑动时失效问题（mode的原因，NSTimer默认是加到defaultMode，滑动时runloop会切换到TrackingMode，需要将NSTimer加入到两种模式下）

- 内部实现逻辑

- 如何响应用户操作

  通过source1捕抓用户时间，包装放入到事件队列中，交由source0处理

- runloop和线程的关系

- timer和runloop的关系

- runloop的状态

- runloop的mode

  常见 NSDefaultRunLoopMode和UITrackingRunLoopMode。

  NSRunLoopCommonMode是一种标记，表示能运行在runloop的_commonModes中的所有mode

  