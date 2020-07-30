最近在处理内存相关的问题，将最近了学到的知识总结了下，从 iOS 的角度介绍内存相关知识概念，并列出优化建议和参考工具，希望能对读者有帮助。

## 操作系统内存相关概念

### 起源

1945 年，冯·诺伊曼体系结构被提出，奠定了计算机的基础，同时其局限性也限制了计算机的进一步发展，直至现代，计算机体系还是没能逃离其局限性，只是陆续对其组织结构进行优化而已。

冯·诺伊曼体系结将计算机分为运算器、控制器、存储器、输入设备和输出设备五大部分，由于存储器的读写效率远远低于运算器（CPU）工作效率，导致了 CPU 性能的浪费，而随着摩尔定律，CPU 发展越来越快，这种差距会越来越明显。

> 当价格不变时，集成电路上可容纳的元器件的数目，约每隔18-24个月便会增加一倍，性能也将提升一倍。

![](./images/01.png)

### 多级存储

对于冯·诺伊曼体系结构局限性，目前通用计算机一般会设置多级缓存，从 CPU 缓存到磁盘，读写速度逐级递减，类似金字塔结构，塔尖负责缓存高频使用的数据，对稳定性和读写效率有更高要求，而底部用于存储常规数据，需要容量足够大，以供上层结构调用，同时兼顾性价比。

![02](./images/02.jpg)

### 物理内存&虚拟内存

- 物理内存：在进程运行时，为操作系统及进程提供临时存储空间，需要借助物理存储器进行存储。目前最新的 iPhone 11 内存为 4GB。
- 虚拟内存：Virtual Memory，是计算机内存管理的技术之一，为每个进程提供一个连续并私有的地址空间，从而保护每个进程的地址空间不被其它进程损坏，降低了开发的复杂度，开发者只需要关注自身进程即可。iOS分别在 32 / 64 位操作系统下，给每个进程提供了 4 / 16 GB  的虚拟内存。



### CPU寻址

### 内存分页

目前大部分计算机的内存都采用了分页管理，iOS下每个进程空间先分段，每个段内再分页，所以物理地址由 `段号 + 段内页号 + 页内地址` 组成，目前 64 为系统每页为 16KB。

当访问虚拟内存时，其对应的物理内存页不存在，则会触发一次 `Page Fault`，将数据或指令从磁盘加载到物理内存中并建立映射关系。

### 内存交换机制（Swap In/Out ）

通常磁盘中都会有一个区域作为内存交换空间（Swap Space），内存管理单元（MMU）会将内存中暂时不用的内容写到交换空间中，该过程即为 Swap Out；当需要使用访问时，在从内存交换空间中读取，即 Swap In；这两种操作都是比较耗时的，频繁使用对性能影响较大，通常在物理内存不足以供程序使用时，操作系统会自动进行 Swap 操作。

iOS 不支持该机制，由于手机使用的都是闪存，频繁读写对齐影响较大，并且闪存的空间也较小，目前最高配置为 512 GB，跟电脑相比还是有不小差距，因此 iOS 采用的是内存压缩机制（Compressed memoryy）。

## iOS内存机制

### 内存空间

前面介绍过，内存是采用分段和分页管理的，在 iOS 系统下，内存从`高地址到低地址` 分为：

- 栈区（stack）：用于存储程序临时创建的局部变量和函数参数等，在作用域执行完毕后会被系统回收，其中分配的地址由高到低分布。
- 堆区（heap）：用于存储程序运行中动态分配的内存段（通过调用 alloc 等函数），例如创建的新对象，默认由 ARC 进行管理，MRC 模式下需要手动进行内存释放，其中分配的地址由低到高分布。
- 全局静态区：由编译器分配，主要是存放全局变量 和 静态变量，程序结束后由系统释放；主要分为：
  - BBS区：存放**未初始化**的全局变量 和 静态变量。
  - 数据区：存放**已初始化**的全局变量 和 静态变量。
- 常量区：存放的是常量，如常量字符串，程序结束后由系统释放。
- 代码区：由于存放程序代码。

### 内存压缩机制

当物理内存不够用时，

### 内存类型

iOS 的内存分为 Clean Memory 和 Dirty Memory 两种类型，其中 Compressed Memory 也属于 Dirty 类型。

通常情况下，我们申请内存空间后得到的都是 Clean 类型，只要在写入数据后才会变成 Dirty，例如下面代码，只有在第一页和最后一页会产生 Dirty Memory：

```objective-c
int *array = malloc(20000 * sizeof(int)); 
array[0] = 32                           
array[19999] = 64                         
```

### VM Region

为了更好的管理内存，系统将一组连续的内存页定义为一个 VM Region，每个 VM Region 都包含了 Dirty 页数、Compressed 页数和已映射到虚拟内存页的列表等信息。

```objective-c
struct vm_region_submap_info_64 {
	vm_prot_t		protection;     /* present access protection */
	vm_prot_t		max_protection; /* max avail through vm_prot */
	vm_inherit_t		inheritance;/* behavior of map/obj on fork */
	memory_object_offset_t	offset;		/* offset into object/map */
  unsigned int            user_tag;	/* user tag on map entry */
  unsigned int            pages_resident;	/* only valid for objects */
  unsigned int            pages_shared_now_private; /* only for objects */
  unsigned int            pages_swapped_out; /* only for objects */
  unsigned int            pages_dirtied;   /* only for objects */
  unsigned int            ref_count;	 /* obj/map mappers, etc */
  unsigned short          shadow_depth; 	/* only for obj */
  unsigned char           external_pager;  /* only for obj */
  unsigned char           share_mode;	/* see enumeration */
	boolean_t		is_submap;	/* submap vs obj */
	vm_behavior_t		behavior;	/* access behavior hint */
	vm_offset_t		object_id;	/* obj/map name, not a handle */
	unsigned short		user_wired_count; 
};

```

### 内存管理机制（MRC & ARC）

iOS 的内存管理遵循 `谁创建，谁释放，谁引用，谁管理` 原则，方式分为 MRC 和 ARC，13年发布 ARC 后，逐渐取代了手动管理的 MRC。除了部分C/C++ 的内存分配和 Core Graphics 等对象，大部分的内存申请、释放等操作都用系统自行完成，开发者只需要避免产生循环引用即可。

### 内存警告

接受内存警告的三种方式：

- **UIApplicationDelegate**的`applicationDidReceiveMemoryWarning:`
- **UIViewController**的`didReceiveMemoryWarning`
- **NSNotificationCenter**的`UIApplicationDidReceiveMemoryWarningNotification`

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



## iOS对象内存管理代码解析

MRC下，ARC下

### alloc

### retain

### release

### autorelease



## iOS常见内存问题及优化

### FOOM

- 指 App 在前台因消耗内存过大导致被系统杀死，针对这类问题，我们需要记录发生 FOOM 时的调用栈、内存占用等信息，从而具体分析解决内存占用大的问题。
- 流程是监控 App 生命周期内的内存增减，在收到内存警告时，记录内存信息，获取当前所有对象信息和内存占用值，并在合适的时机上传到服务器。目前比较出名的 OOM 监控框架有 Facebook 的 **[OOMD](https://github.com/facebookincubator/oomd)** 和腾讯的**[ OOMDetector](https://github.com/Tencent/OOMDetector)**。
- OOMD 和 OOMDetoctor 区别在于内存监控方便，OOMD 是通过

### 内存泄漏

- ARC 模式下，开发者不再需要手动释放内存，所有内存泄漏基本都是由于对象循环引用引起的。可通过申明 `weak` 或 `unowned` 来避免循环使用。
- 区别在于
- 另外不是所有引用关系都需要使用弱引用申明，毕竟弱引用对性能还是有影响。GCD 中的

### WKWebView 白屏问题

UIWebView 会因为内存使用过大而崩溃，WKWebView 苹果进行了优化，不会 Crash 但会导致白屏，不显示内容。

解决方法是监听到 URL 为 nil  或者接收到 WKNavigationDelegate 的 `webViewWebContentProcessDidTerminate` 时，reload 页面。

### 野指针

目前最为常见的野指针是 `objc_msgSend` 和 `unrecognized selector sent to`，只要能记录崩溃时的调用栈，一般都较容易解决。

开发阶段可以通过开启编译里的 `Zombie Objects` 复现问题，原理是 Hook 系统的 dealloc 方法，执行 __dealloc_zombie 将对象进行僵尸化，如果当前对象再次收到消息，则终止程序并打印出调用信息。

### 图片内存

- 图片读取

  imageNamed 会被缓存到内存中，适用于频繁使用的小图片；imageWithContentOfFile 适用于大图片，持有者生命周期结束后既被释放。

- 不同格式差别很大
  - 如何选择合适的格式？绘制时使用 UIGraphicsImageRenderer （iOS10之后）替代 UIGraphicsBeginImageContextWithOptions（固定是4字节像素格式SRGB）
- 缩小图像
  - 将大图片加载到小空间时， UIImage （UIImage.contentsOfFile）需要先解压整个图像再渲染，会产生内存峰值
  - ImageIO框架（CGImageSourceCreateWithURL）可以直接指定加载到内存的图像尺寸和信息，用 ImageIO框架 替代 UIImage 可避免图像峰值
- 后台优化
  - 切入后台时，图像默认还在内存中  
  - 退到后台或view消失时从内存中移除图片，进入前台或view出现时再加载图片 （通过通知) 

### 其它问题

- namo_free Crash

  苹果对于小于 256B 的空间分配使用的是 nano zone，由于内部的问题在  iOS10.0 ~ 10.1 会崩溃，解决方法是创建自己的 zone 替代 nano zone，iOS10.2 之后已修复，对该问题有兴趣的可参考 [聊聊苹果的Bug - iOS 10 nano_free Crash](https://cloud.tencent.com/developer/article/1031006)。

### 其它优化

- 构建缓存时使用 NSCache 替代 NSMutableDictionary

  NSCache 是线程安全的，当内存不足时会自动释放内存（取数据时需要先判空），并且可以通过 `countLimit` 和 `totalCostLimit` 属性设置上限，另外当收到内存警告时会自动清空数据，这些都是 NSDictionary 不具备的。



## iOS内存分析工具

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

- MLeaksFinder

## 总结

### 系列文章

### 参考资料

- [iOS内存二三事](https://juejin.im/post/5e8ee75df265da47e7526b67#heading-15)

- [iOS Memory 内存详解](https://mp.weixin.qq.com/s/YpJa3LeTFz9UFOUcs5Bitg)

- [什么是内存（一）：存储器层次结构](https://www.cnblogs.com/yaoxiaowen/p/7805661.html)



- [探索iOS内存分配](https://juejin.im/post/5a5e13c45188257327399e19)



- [WWDC2018 - iOS Memory Deep Dive ](https://developer.apple.com/videos/play/wwdc2018/416/)
- [OOM探究：XNU 内存状态管理](https://www.jianshu.com/p/4458700a8ba8) （待深入）
- 



- https://juejin.im/post/5e8ee75df265da47e7526b67#heading-14
- https://wetest.qq.com/lab/view/367.html?from=content_juejin
- http://blog.devtang.com/2016/07/30/ios-memory-management/
- https://juejin.im/post/5c0744f6e51d45598b76f481#heading-9
- https://juejin.im/post/5e3794a7f265da3e51531c9d#heading-79
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://www.meiwen.com.cn/subject/jixyeftx.html

