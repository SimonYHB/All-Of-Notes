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
	CFMutableSetRef _source0;
	CFMutableSetRef _source1;
	CFMutableArrayRef _observers;
	CFMutableArrayRef _times;
}
```

### 结构

- Source0 点击事件的处理
- Source1 基于Port的线程间通信，系统事件的捕捉（识别到后封装给Source0处理）
- Timers 定时器
- Observers 监听Runloop的状态和UI刷新

### 线程与runloop

每个线程都有唯一的runloop，创建线程时不会开启，只有在第一次使用时才创建

所有线程的runloop保存在一个全局字典里，thread为key，runloop为value

















### Q

- 项目中用法

- 内部实现逻辑，如何响应用户操作

- runloop和线程的关系

- timer和runloop的关系

- runloop的状态

- runloop的mode

  

  