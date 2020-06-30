1. 资料收集
2. 确定大纲
   - 内存机制介绍
   - iOS内存机制
   - 常见内存问题及优化
   - iOS内存分析检测
3. 按模块学习（列出问题点）
4. 按模块输出
5. 深入更多内容







## 为什么要减小内存

### ARC出现之前

## 一些概念

- clean page 

- dirty page

- Compressed page

- memory warnings

  不一定是因为自己的应用造成的

- 内存占用限制

## 检测工具

- 如何分析内存占用
  - 内存测量器 (memory)
  - Instruments 
    - Allocations
    - Leaks
    - VM Tracker 追踪脏内存和压缩内存
    - Virture memory trace 了解系统虚拟内存
    - 导出 Memgraph
      - vmmap
      - Leaks
      - Heap
      - malloc_history

## 常见内存相关问题

### 

### 图片的内存

- 不同格式差别很大
  - 如何选择合适的格式？ 使用 UIGraphicsImageRenderer （iOS10之后）替代 UIGraphicsBeginImageContextWithOptions（固定是4字节像素格式SRGB）
- 缩小图像
  - 将大图片加载到小空间时， UIImage （UIImage.contentsOfFile）需要先解压整个图像再渲染，会产生内存峰值
  -  ImageIO框架（CGImageSourceCreateWithURL）可以直接指定加载到内存的图像尺寸和信息，用 ImageIO框架 替代 UIImage 可避免图像峰值
- 后台优化
  - 切入后台时，图像默认还在内存中  
  - 退到后台或view消失时从内存中移除图片，进入前台或view出现时再加载图片 （通过通知) 

### OOM

全称是 Out Of Memory，是一种系统管理内存的机制，当内存不够时，会自动将低优先级的进行kill，腾出内存供其他高优先级进程使用。xnu 本身代码是开源的，可在苹果官方[下载](https://opensource.apple.com/tarballs/xnu/)，其中内存状态管理相关代码主要在 `/bsd/kern/kern_memorystatus.h/c` 文件中。

```c
#define JETSAM_PRIORITY_REVISION                  2

#define JETSAM_PRIORITY_IDLE_HEAD                -2
/* The value -1 is an alias to JETSAM_PRIORITY_DEFAULT */
#define JETSAM_PRIORITY_IDLE                      0
#define JETSAM_PRIORITY_IDLE_DEFERRED             1 /* Keeping this around till all xnu_quick_tests can be moved away from it.*/
#define JETSAM_PRIORITY_AGING_BAND1               JETSAM_PRIORITY_IDLE_DEFERRED
#define JETSAM_PRIORITY_BACKGROUND_OPPORTUNISTIC  2
#define JETSAM_PRIORITY_AGING_BAND2               JETSAM_PRIORITY_BACKGROUND_OPPORTUNISTIC
#define JETSAM_PRIORITY_BACKGROUND                3
#define JETSAM_PRIORITY_ELEVATED_INACTIVE         JETSAM_PRIORITY_BACKGROUND
#define JETSAM_PRIORITY_MAIL                      4
#define JETSAM_PRIORITY_PHONE                     5
#define JETSAM_PRIORITY_UI_SUPPORT                8
#define JETSAM_PRIORITY_FOREGROUND_SUPPORT        9
#define JETSAM_PRIORITY_FOREGROUND               10
#define JETSAM_PRIORITY_AUDIO_AND_ACCESSORY      12
#define JETSAM_PRIORITY_CONDUCTOR                13
#define JETSAM_PRIORITY_DRIVER_APPLE             15
#define JETSAM_PRIORITY_HOME                     16
#define JETSAM_PRIORITY_EXECUTIVE                17
#define JETSAM_PRIORITY_IMPORTANT                18
#define JETSAM_PRIORITY_CRITICAL                 19

#define JETSAM_PRIORITY_MAX                      21

/* TODO - tune. This should probably be lower priority */
#define JETSAM_PRIORITY_DEFAULT                  18
#define JETSAM_PRIORITY_TELEPHONY                19


...
  
typedef struct memstat_bucket {
	TAILQ_HEAD(, proc) list;
	int count;
	int relaunch_high_count;
} memstat_bucket_t;
```

系统定义了多个优先级，每个优先级对应一个 `memstat_bucket_t` 结构体，存放这个优先级下所有进程。其中后台进程和前台进程的优先级分别为 3 和 10，当系统内存紧张时，前台进程之前的优先级全被 kill 后（包括后台进程），仍然不满足高优先级进程的内存需求，才会主动 kill 前台进程。

## 优化建议

- Framework 使用单例，减少加载次数

## 总结

### 参考资料

- [WWDC2018 - iOS Memory Deep Dive ](https://developer.apple.com/videos/play/wwdc2018/416/)
- [OOM探究：XNU 内存状态管理](https://www.jianshu.com/p/4458700a8ba8) （待深入）
- 



- https://juejin.im/post/5e8ee75df265da47e7526b67#heading-14
- https://mp.weixin.qq.com/s/YpJa3LeTFz9UFOUcs5Bitg
- https://wetest.qq.com/lab/view/367.html?from=content_juejin
- http://blog.devtang.com/2016/07/30/ios-memory-management/
- https://juejin.im/post/5c0744f6e51d45598b76f481#heading-9
- https://juejin.im/post/5e3794a7f265da3e51531c9d#heading-79
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://www.meiwen.com.cn/subject/jixyeftx.html