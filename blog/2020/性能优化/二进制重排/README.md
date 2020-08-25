# 二进制重排

## 介绍

去年年底二进制重排的概念被宇宙厂带火了起来，出于学习的目的，综合网上已有资料并总结实现了下，以便对启动优化有更好的了解。

对比了网上的实现方式，抖音通过手动插桩获取的符号数据，包括C++静态初始化、+Load、Block等都需要针对性处理，就其复杂度来说感觉性价比不高；手淘的方案比较特殊，通过修改 .o 目标文件实现静态插桩，需要对目标代码较为熟悉，通用性不高；最后决定采用 clang 插桩的方式实现二进制重排。

先介绍一些基本的概念以便对实现有更好的了解。

### App启动和内存加载

Linux 系统下，进程申请内存并不是直接物理内存给我们运行，而是只标记当前进程拥有该段内存，当真正使用这段段内存时才会分配，此时的内存是虚拟内存。

> 在虚拟内存出现前，程序指令必须都在物理内存内，使得物理内存能存放的进程十分有限，并且由于是相邻存储，容易发生越界访问等情况。
>
> 虚拟内存是作为 **内存的管理和保护工具** 诞生的，为每个进程提供了一片连续完整的虚拟内存空间，使用时先通过界限寄存器判断访问是否越界，再通过基址寄存器转换为实际内存地址。降低了内存管理的复杂度，保护每个进程的内存地址空间不会被其它进程破坏，并且实现了 **共享缓存功能**，访问时先判断是否已缓存到主存中才通过 CPU 寻址（虚拟地址）访问主存或硬盘。

当我们需要访问一个内存地址时，如果虚拟内存地址对应的物理内存还未分配，CPU 会执行 `page fault`，将指令从磁盘加载到物理内存中并进行验签操作（App Store 发布情况下）。

在App 启动过程中，会调用各种函数，由于这些函数分布在各个 TEXT 段中且不连续，此时需要执行多次 `page fault` 创建分页，将代码读取到物理内存中，并且这些分页中的部分代码不会在启动阶段被调用。如下图所示，假设我们在启动阶段需要调用 `Func A、B、C`，则需执行3次 `page default`(包括首次读取)，并使用3个分页。

![二进制重排01](./images/二进制重排01.png)

### 如何优化？

优化的思路很简单，即把启动阶段需要用到的函数按顺序排放，减少 `page fault` 执行次数和分页数量，并使 `page fault` 在相邻页执行，如下图所示，相较于之前，减少了一次 `page fault` 和分页加载，当工程复杂度高时，优化的效果就很客观了。

![二进制重排02](./images/二进制重排02.png)



Xcode 的链接器提供了一个 `Order File` 配置，对应的文件中符号会按照顺序写入二进制文件中，我们可以将调用到的函数写到该文件，实现优化。

![二进制重排01](./images/二进制重排03.png)



## 实现详解

### Link Map了解链接顺序

Link Map 是 App 编译过程的中间产物，记载了二进制文件的布局，我们可以通过 Link Map 文件分析可执行文件的构成是怎样，里面的内容都是些什么，哪些库占用空间较高等等，需要手动在 Build Settings 将 Write Link Map File 设置为 Yes。  

默认生成的 Link Map 文件在 build 目录下，可以通过修改 Path To Link Map 指定存放地址。

![重排04](./images/二进制重排04.png)

以demo为例，文件中的内容如下，各部位含义见注释：

```
// Link Map对应安装包地址
# Path: /Users/yehuangbin/Library/Developer/Xcode/DerivedData/IOSDevelopTools-bpjwhcswecoziihayzwjgxztowne/Build/Products/Debug-iphoneos/IOSDevelopTools.app/IOSDevelopTools

// 对应的架构
# Arch: arm64

// 编译后生成的.o文件列表，包括系统和用户自定的类，UIKit库等等。
# Object files:
[  0] linker synthesized
[  1] /Users/yehuangbin/Library/Developer/Xcode/DerivedData/IOSDevelopTools-bpjwhcswecoziihayzwjgxztowne/Build/Intermediates.noindex/IOSDevelopTools.build/Debug-iphoneos/IOSDevelopTools.build/Objects-normal/arm64/YECallMonitor.o
[  2] /Users/yehuangbin/Library/Developer/Xcode/DerivedData/IOSDevelopTools-bpjwhcswecoziihayzwjgxztowne/Build/Intermediates.noindex/IOSDevelopTools.build/Debug-iphoneos/IOSDevelopTools.build/Objects-normal/arm64/YECallRecordCell.o
...

// Section是各种数据类型所在的内存空间，Section主要分为两大类，__Text和__DATA。__Text指的是程序代码，__DATA指的是已经初始化的变量等。
# Sections:
# Address	Size    	Segment	Section
0x10000572C	0x0000B184	__TEXT	__text
0x1000108B0	0x000002C4	__TEXT	__stubs
0x100010B74	0x000002DC	__TEXT	__stub_helper
0x100010E50	0x00000088	__TEXT	__const
0x100010ED8	0x000006EC	__TEXT	__cstring
...

// 变量名、类名、方法名等符号表
# Symbols:
# Address	Size    	File  Name
0x10000572C	0x00000080	[  1] +[YECallMonitor shareInstance]
0x1000057AC	0x0000005C	[  1] ___30+[YECallMonitor shareInstance]_block_invoke
0x100005808	0x00000024	[  1] -[YECallMonitor start]
0x10000582C	0x00000024	[  1] -[YECallMonitor stop]

...


# Dead Stripped Symbols:
#        	Size    	File  Name
<<dead>> 	0x00000008	[  2] 8-byte-literal
<<dead>> 	0x00000006	[  2] literal string: depth
<<dead>> 	0x00000012	[  2] literal string: stringWithFormat:
<<dead>> 	0x00000007	[  2] literal string: string
<<dead>> 	0x00000034	[  2] literal string: stringByPaddingToLength:withString:startingAtIndex:
<<dead>> 	0x0000000E	[  2] literal string: appendString:
<<dead>> 	0x00000004	[  2] literal string: cls
<<dead>> 	0x0000000E	[  2] literal string: .cxx_destruct
...


```

可以看到此时 Symbols 的符号表并不是按照启动时执行的函数顺序加载的，而是按照库的编译顺序全部载入。



### SanitizerCoverage采集调用函数信息

我们通过 SanitizerCoverage 采集调用函数信息， SanitizerCoverage 内置在LLVM中，可以在函数、基本块和边界这些级别上插入对用户定义函数的回调，属于**静态插桩**，代码会在编译过程中插入到每个函数中，详细介绍可以在 [Clang 11 documentation](http://clang.llvm.org/docs/index.html) 找到。

在 build settings 里的 “Other C Flags” 中添加 `-fsanitize-coverage=func,trace-pc-guard`。如果含有 Swift 代码的话，还需要在 “Other Swift Flags” 中加入 `-sanitize-coverage=func` 和 `-sanitize=undefined`。需注意，所有链接到 App 中的二进制都需要开启 SanitizerCoverage，这样才能完全覆盖到所有调用。

开启后，**函数的调用** 都会执行 `void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {}` 回调，效果类似我们对 `objc_msgSend` 进行 Hook插桩，但该回调不止局限于 OC 函数，还包括 Swift、block、C等。

我们在该回调中插入自己的统计代码，收集函数名，启动完成后再将数据导出。借鉴[玉令天下](http://yulingtianxia.com/)的实现代码，稍微修改了下，如需自取 [AppCallCollecter](https://github.com/SimonYHB/iOS-Develop-Tools/tree/master/IOSDevelopTools/AppCallCollecter)，完整代码如下：

```c

static OSQueueHead qHead = OS_ATOMIC_QUEUE_INIT;
static BOOL stopCollecting = NO;

typedef struct {
    void *pointer;
    void *next;
} PointerNode;

// start和stop地址之间的区别保存工程所有符号的个数
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                         uint32_t *stop) {
    static uint32_t N;  // Counter for the guards.
    if (start == stop || *start) return;  // Initialize only once.
    printf("INIT: %p %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++)
        *x = ++N;  // Guards should start from 1.
    
    printf("totasl count %i\n", N);
}


// 每个函数调用时都会先跳转执行该函数
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {
    // +load方法先于guard_init调用，此时guard为0
//    if(!*guard) { return }

    if (stopCollecting) {
        return;
    }

    // __builtin_return_address 获取当前调用栈信息，取第一帧地址
    void *PC = __builtin_return_address(0);
    PointerNode *node = malloc(sizeof(PointerNode));
    *node = (PointerNode){PC, NULL};
    // 使用原子队列要存储帧地址
    OSAtomicEnqueue(&qHead, node, offsetof(PointerNode, next));

    
}

extern NSArray <NSString *> *getAllFunctions(NSString *currentFuncName) {
    NSMutableSet<NSString *> *unqSet = [NSMutableSet setWithObject:currentFuncName];
    NSMutableArray <NSString *> *functions = [NSMutableArray array];
    while (YES) {
        PointerNode *front = OSAtomicDequeue(&qHead, offsetof(PointerNode, next));
        if(front == NULL) {
            break;
        }
        Dl_info info = {0};
        // dladdr获取地址符号信息
        dladdr(front->pointer, &info);
        NSString *name = @(info.dli_sname);
        // 去除重复调用
        if([unqSet containsObject:name]) {
            continue;
        }
        BOOL isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
        // order文件格式要求C函数和block前需要添加_
        NSString *symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
        [unqSet addObject:name];
        [functions addObject:symbolName];
    }

    return [[functions reverseObjectEnumerator] allObjects];;

}

#pragma mark - public

extern NSArray <NSString *> *getAppCalls(void) {
    
    stopCollecting = YES;
    __sync_synchronize();
    NSString* curFuncationName = [NSString stringWithUTF8String:__FUNCTION__];
    return getAllFunctions(curFuncationName);
}




extern void appOrderFile(void(^completion)(NSString* orderFilePath)) {
    
    stopCollecting = YES;
    __sync_synchronize();
   NSString* curFuncationName = [NSString stringWithUTF8String:__FUNCTION__];
    // 异步存储到文件中
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *functions = getAllFunctions(curFuncationName);
        NSString *orderFileContent = [functions.reverseObjectEnumerator.allObjects componentsJoinedByString:@"\n"];
        NSLog(@"[orderFile]: %@",orderFileContent);
        NSString *filePath = [NSTemporaryDirectory() stringByAppendingPathComponent:@"orderFile.order"];
        [orderFileContent writeToFile:filePath
                           atomically:YES
                             encoding:NSUTF8StringEncoding
                                error:nil];
        if(completion){
            completion(filePath);
        }
    });
}
```

### 关键代码解析

这里详细介绍下每个函数的作用。

```objective-c
void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                         uint32_t *stop) {
  
    static uint32_t N;  // Counter for the guards.
    if (start == stop || *start) return;  // Initialize only once.
    printf("INIT: %p %p\n", start, stop);
    for (uint32_t *x = start; x < stop; x++)
        *x = ++N;  // Guards should start from 1.
    
    printf("totasl count %i\n", N);
}


```

dyld 每链接一个开启 `SanitizerCoverage` 配置的 dylib 都会执行一次  `__sanitizer_cov_trace_pc_guard_init `，`start` 和 `stop` 之间的区间保存了该 dylib 的符号个数，我们通过设置静态全局变量 N 可统计所有 dylib 的符号。

如果不需要以上内容可以仅执行空函数 `void __sanitizer_cov_trace_pc_guard_init(uint32_t *start,
                                         uint32_t *stop){}`，不会影响后面的调用。

```objective-c

// 每个函数调用时都会先跳转执行该函数
void __sanitizer_cov_trace_pc_guard(uint32_t *guard) {

    // +load方法先于guard_init调用，此时guard为0
//    if(!*guard) { return }

    if (stopCollecting) {
        return;
    }

    // __builtin_return_address 获取当前调用栈的下一条指令地址
    void *PC = __builtin_return_address(0);
    PointerNode *node = malloc(sizeof(PointerNode));
    *node = (PointerNode){PC, NULL};
    // 使用原子队列要存储帧地址
    OSAtomicEnqueue(&qHead, node, offsetof(PointerNode, next));
}
```

![image-20200410174421317](./images/二进制重排10.png)

我们通过汇编可发现，每个函数调用前都被插入了`__sanitizer_cov_trace_pc_guard`，所以我们在该函数中，利用 `__builtin_return_address` 获取运行栈的情况，保存第一条指令地址，即函数地址。

注意，由于存在多线程调用的问题，此时需要用锁来保证符号存储，这里我们使用原子队列，执行效率高且队列存储数据，不需要再额外加锁处理和创建数组。

```objective-c
extern NSArray <NSString *> *getAllFunctions(NSString *currentFuncName) {
    NSMutableSet<NSString *> *unqSet = [NSMutableSet setWithObject:currentFuncName];
    NSMutableArray <NSString *> *functions = [NSMutableArray array];
    while (YES) {
        PointerNode *front = OSAtomicDequeue(&qHead, offsetof(PointerNode, next));
        if(front == NULL) {
            break;
        }
        Dl_info info = {0};
        // dladdr获取地址符号信息
        dladdr(front->pointer, &info);
        NSString *name = @(info.dli_sname);
        // 去除重复调用
        if([unqSet containsObject:name]) {
            continue;
        }
        BOOL isObjc = [name hasPrefix:@"+["] || [name hasPrefix:@"-["];
        // order文件格式要求C函数和block前需要添加_
        NSString *symbolName = isObjc ? name : [@"_" stringByAppendingString:name];
        [unqSet addObject:name];
        [functions addObject:symbolName];
    }

    return [[functions reverseObjectEnumerator] allObjects];;

}
```

```objective-c
/*
 * Structure filled in by dladdr().
 */
typedef struct dl_info {
        const char      *dli_fname;     /* Pathname of shared object */
        void            *dli_fbase;     /* Base address of shared object */
        const char      *dli_sname;     /* Name of nearest symbol */
        void            *dli_saddr;     /* Address of nearest symbol */
} Dl_info;

extern int dladdr(const void *, Dl_info *);
```

将收集的函数地址从原子队列中取出，通过 `dladdr`  获取地址的对应符号信息，最后将数组排序逆转即可得到按顺序排序的调用函数数组。



### 结果对比

在项目启动后调用 `appOrderFile` 方法，将调用列表写到沙盒中，通过在 Devices 下载 xcappdata 文件即可获取该列表。

![image-20200410174421317](./images/二进制重排06.png)

![image-20200410174421317](./images/二进制重排07.png)

里面的内容即是启动过程被调用的函数顺序。

```c
_getThreadMethodStack
_after_objc_msgSend
_before_objc_msgSend
-[YECallMonitor ignoreClassArr]
-[YECallMonitor setFilterClassNames:]
_get_protection
_perform_rebinding_with_section
_rebind_symbols_for_image
__rebind_symbols_for_image
_prepend_rebindings
_rebind_symbols
___startMonitor_block_invoke
_startMonitor
-[YECallMonitor start]
_setMinConsumeTime
-[YECallMonitor setMinTime:]
___30+[YECallMonitor shareInstance]_block_invoke
+[YECallMonitor shareInstance]
-[AppDelegate application:didFinishLaunchingWithOptions:]
-[AppDelegate setWindow:]
-[AppDelegate window]
_main
```

最后在 `Order File` 配置下文件地址，重新编译打包。

从重排后的 Link Map Symbols 部分可以看到此时的载入顺序跟我们的 order file 文件是一致的。

```
...
# Symbols:
# Address	Size    	File  Name
0x100007CCC	0x000000AC	[  4] _getThreadMethodStack
0x100007D78	0x00000234	[  4] _after_objc_msgSend
0x100007FAC	0x0000016C	[  4] _before_objc_msgSend
0x100008118	0x000001AC	[  1] -[YECallMonitor ignoreClassArr]
0x1000082C4	0x00000298	[  1] -[YECallMonitor setFilterClassNames:]
0x10000855C	0x000000A0	[  5] _get_protection
0x1000085FC	0x000003D0	[  5] _perform_rebinding_with_section
0x1000089CC	0x00000320	[  5] _rebind_symbols_for_image
0x100008CEC	0x00000058	[  5] __rebind_symbols_for_image
0x100008D44	0x00000104	[  5] _prepend_rebindings
0x100008E48	0x000000F8	[  5] _rebind_symbols
0x100008F40	0x000000E0	[  4] ___startMonitor_block_invoke
0x100009020	0x00000074	[  4] _startMonitor
0x100009094	0x00000044	[  1] -[YECallMonitor start]
0x1000090D8	0x00000044	[  4] _setMinConsumeTime
0x10000911C	0x00000054	[  1] -[YECallMonitor setMinTime:]
0x100009170	0x00000074	[  1] ___30+[YECallMonitor shareInstance]_block_invoke
0x1000091E4	0x0000009C	[  1] +[YECallMonitor shareInstance]
0x100009280	0x00000208	[ 11] -[AppDelegate application:didFinishLaunchingWithOptions:]
0x100009488	0x00000070	[ 11] -[AppDelegate setWindow:]
0x1000094F8	0x00000058	[ 11] -[AppDelegate window]
0x100009550	0x000000D4	[  9] _main
...
```

通过 system trace 工具对比下优化前后的启动速度，由于 Demo 工程内容少，无法看出明显区别，这里用公司项目作为对比：

![image-20200410183559224](./images/二进制重排08.png)

![image-20200410183559224](./images/二进制重排09.png)

可以看到执行 `page fault` 少了将近 1/3，速度提升了 1/4，说明对启动优化上还是有一定效果，尤其是在大项目中。

## 总结



由于在 iOS 上，一页有16KB（Mac 为4KB），可以存放大量代码，所以在启动阶段执行 `page fault` 的次数并不会很多，二进制重排相比于其他优化手段，提升效果不明显，应优先从其他方面去进行启动优化（关于这部分的文章近期就会发布），最后再考虑是否做重排优化，但从技术学习的层面还是值得研究的 😁。



### 参考

- [Improving App Performance with Order Files](https://medium.com/@michael.eisel/improving-app-performance-with-order-files-c7fff549907f)
- [App 二进制文件重排已经被玩坏了](http://yulingtianxia.com/blog/2019/09/01/App-Order-Files/)
- [简谈二进制重排](http://www.cocoachina.com/articles/52793)
- [基于LinkMap分析iOSAPP各模块体积](https://blog.csdn.net/zgzczzw/article/details/79855660)
- [手淘架构组最新实践 | iOS基于静态库插桩的⼆进制重排启动优化](https://mp.weixin.qq.com/s/YDO0ALPQWujuLvuRWdX7dQ)
- [抖音研发实践：基于二进制文件重排的解决方案 APP启动速度提升超15%](https://mp.weixin.qq.com/s?__biz=MzI1MzYzMjE0MQ==&mid=2247485101&idx=1&sn=abbbb6da1aba37a04047fc210363bcc9&scene=21#wechat_redirect)



### About Me  🐝

今年计划完成10个优秀第三方源码解读，会陆续提交到 [iOS-Framework-Analysis](https://github.com/SimonYHB/iOS-Framework-Analysis) ，欢迎 star 项目陪伴笔者一起提高进步，若有什么不足之处，敬请告知 🏆。