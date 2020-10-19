## Runtime



### isa深入

arm64架构为什么要&ISA_MASK?

arm64后，isa不再是Class指针，优化成了union共用体(有64位)，使用位域来存储更多信息（通过mask和位运算来获取里面的值），&ISA_MASK取得shiftcls是对象地址，由于shiftcls是在第4~37位，所以对象地址的最后3位都是0

```c
union isa_t {//定义一个联合体
    isa_t() { }
    isa_t(uintptr_t value) : bits(value) { }
    //cls和bits是互斥的，只能存在一个
    Class cls;
    uintptr_t bits;
#if defined(ISA_BITFIELD)
    struct {
        ISA_BITFIELD;  // defined in isa.h
    };
#endif
};

# if __arm64__ /*iOS的定义*/
#   define ISA_MASK        0x0000000ffffffff8ULL
#   define ISA_MAGIC_MASK  0x000003f000000001ULL
#   define ISA_MAGIC_VALUE 0x000001a000000001ULL
#   define ISA_BITFIELD                                                      
      uintptr_t nonpointer        : 1;/*是否对isa指针开启指针优化*/                                       
      uintptr_t has_assoc         : 1;/*是否有设置过关联对象(setAssociatedObject)*/                                       
      uintptr_t has_cxx_dtor      : 1;/*是否有c++的析构函数*/                                       
      uintptr_t shiftcls          : 33; /*MACH_VM_MAX_ADDRESS 0x1000000000 存储类信息*/ 
      uintptr_t magic             : 6;/*调试器判断对象是真对象还是未初始化的空间*/                                       
      uintptr_t weakly_referenced : 1;/*对象是否被弱引用指向郭*/                                       
      uintptr_t deallocating      : 1;/*对象是否正在释放内存*/                                       
      uintptr_t has_sidetable_rc  : 1;/*是否有外挂散列表（当19位放不下引用计数器时候，该值为1）*/                                       
      uintptr_t extra_rc          : 19/*用于存放引用计数，值为引用计数-1*/
#   define RC_ONE   (1ULL<<45)
#   define RC_HALF  (1ULL<<18)

# elif __x86_64__/*macOS的定义*/
#   define ISA_MASK        0x00007ffffffffff8ULL
#   define ISA_MAGIC_MASK  0x001f800000000001ULL
#   define ISA_MAGIC_VALUE 0x001d800000000001ULL
#   define ISA_BITFIELD                                                        
      uintptr_t nonpointer        : 1;                                         
      uintptr_t has_assoc         : 1;                                         
      uintptr_t has_cxx_dtor      : 1;                                         
      uintptr_t shiftcls          : 44; /*MACH_VM_MAX_ADDRESS 0x7fffffe00000*/ 
      uintptr_t magic             : 6;                                         
      uintptr_t weakly_referenced : 1;                                         
      uintptr_t deallocating      : 1;                                         
      uintptr_t has_sidetable_rc  : 1;                                         
      uintptr_t extra_rc          : 8
#   define RC_ONE   (1ULL<<56)
#   define RC_HALF  (1ULL<<7)
```





```
// 示例：总共只占一字节，存了tall、rich、handsome
union {
	char bits;
	// struct只是用于说明，实际用不到，都是操作bits
	sturct {
		char tall: 1  //第一位
		char rich:1  //第二位
		char handsome: 1 //第三位
	};
} _tallRichHandsome;
```



### class_ro_t与class_rw_t

刚开始类方法、属性和协议都是一位数组存在class_ro_t，bits也是指向class_ro_t，加载时会创建class_rw_t，并将class_ro_t的信息赋值到class_rw_t的对应二位数组中，并将bits指向class_rw_t

上述过程在objc-runtime_new.mm的relizeClass方法中，load_images时调用



### method_t

```
// 函数的底层结构
struct method_t {
	SEL name; //函数名，类似C语言字符串
	const char *type; //编码(返回值类型、参数类型)
	IMP imp; //指向函数的指针
}
```

```
type示例：
v16@0:8  // 一个无参数无返回值的函数，v代表void，@代表id，:代表SEL，16表示参数总共占多少字节
i24@0:8i16f20 // 返回值为Int，参数为Int何float类型的函数
```

### 方法缓存 cache

使用散列表来缓存调用过的方法（包括父类的），避免每次都需要去遍历查找方法（缓存在当前调用类的cache中）

```
struct cache_t {
	struct bucket_t *_buckets; //散列表
	mask_t _mask; //散列表长度-1
	mask_t _occupied //已经缓存的方法数量
}

struct bucket_t {
	cache_key_t _key; //SEL作为key
	IMP _imp; //函数的内存地址
}
```

散列表的查找方式：

通过key&mask再经过某种算法得到的值就是在buckets中的索引

算法是为了处理得到的索引值相同，苹果里是直接进行-1操作判断是否已被占用

cache扩容后，会将原先缓存的数据都清除



### objc_msgSend

执行流程：

- 消息发送

  给方法调用者发送消息，执行方法查找流程，查缓存（汇编实现）->查自身->查父类缓存和方法列表，方法列表如果排序了，查找用的是二分查找，否则顺序查找

- 动态方法解析

  通过实现`resolveInstanceMethod/resolveClassMethod`动态给调用者添加方法实现`class_addMethod`，动态添加后，当前调用者会在重新查找方法列表

  如果当前方法做过动态方法解析了，下次就不会再进来

  实际开发中不常用

- 消息转发

  进入消息转发阶段，会进入`__forwarding__`函数，通过实现`forwardingTargetForSelector`将当前消息转发给别的对象处理，如果返回nil则直接结束

  如果没有实现`forwardingTargetForSelector`，则会转发成方法签名，通过实现`methodSignatureForSelector和forwardingInvocation`来处理Invocation，如果实现methodSignatureForSelector并且返回空则会调用doesNotRecognizeSelector再抛出unrecognized selector

  实际开发中常用在中间人代理，例如使用NSProxy当作target和timer的中间人防止循环引用，实现Proxy的该方法，将定时器的方法调用转回给target处理；还有数组add一个网络数据，无法保证是什么类型，就可以在这里处理，当类型错误时就不会闪退了

    

  

## 面试题

- OC的消息机制

  调用方法都是转成objc_msgSend函数调用...

- runtime的实际应用

  - 利用关联对象给分类添加属性

  - 字典转模型 / 遍历变量做归结档

  - 动态替换原来方法实现<只是交换imp>（用于系统或静态库等不公开的代码）

    例如替换数组/对象存取值方法，防止数据类型错误导致崩溃

    ```
    method_exchangeImplementations(Method1, Method2)
    ```

  - 利用消息转发机制解决方法找不到的异常

- runtime不好的案例

  不是苹果推荐的做法，容易在版本迭代时产生问题，例如iOS13迭代，placeLabel失效，会导致崩溃等

- @dynamic和@synthesize

  @dynamic告诉编译器不用为属性生成get和set实现（@synthesize相反，现在系统默认是synthesize），需要在resolveInstanceMethod中去处理调用

- isKindOfClass和isMemberOfClass区别

  kindOf会遍历父类，menber是比较当前类

- super调用的本质

  ```
  // 是汇编实现的，传入两个参数，伪代码如下
  objc_msgSendSuper2 {
  	id receiver;
  	Class current_class //通过这个去找superclass
  }
  ```

- 栈平衡

- 代码转换

  - 中间代码 .ll

    clang -emit-llvm -S main.m

  - C++

    xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc ViewController.m -o xx.cpp

