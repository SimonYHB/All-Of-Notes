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

上述过程在objc-runtime_new.mm的relizeClass中