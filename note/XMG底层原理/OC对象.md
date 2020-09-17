## OC对象

### 对象的内存

OC是由C/C++的结构体实现



转成C/C++代码：xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc 输入文件 -o 输出文件



NSObject -> struct NSObject_IMPL { Class isa } -> typedef struct objc_class *Class



class_getInstanceSize 返回的是对象所有成员变量所占用大小

malloc_size 返回的是分配的空间

一个NSObject对象占用了16个字节，但只使用了其中8个字节

allocWithZone中有处理，所有对象至少分配16字节



lldb指令：p、po、x/、memory write



sizeof、class_getInstanceSize查询的类型的内存，以最大成员变量占用大小为标准进行内存对齐；malloc_size是查询分配的内存，calloc分配内存也是内存对齐的，都是16的倍数(gnu的libmalloc中可以看到MALLOC_ALIGNMENT为2倍的size_t或long double，在arm64下都是16)



### 对象的类型

对象分为：实例对象、类对象和元类对象三种

- 实例对象
  - 存储的信息有isa指针和其他成员变量
- 类对象
  - 每个类在内存中有且只有一个class对象
  - 存储信息
    - isa
    - superclass指针
    - 属性信息 @property
    - 对象方法 instance method
    - 协议信息 protocol
    - 成员变量信息 ivar
  - 获取方式
    - [对象 class] 注意：class方法获取的永远是类对象
    - object_getClass(实例对象)
    - [类 class]
    - objc_getClass(类名)

- 元类对象
  - 每个类在内存中有且只有一个Meta-class对象
  - 获取方式：object_getClass(类对象)
  - 存储信息
    - isa
    - superclass指针
    - 类方法 class method
- 类对象和元类对象的内存结构都是Class类型，只是存储的东西不一样



```
// objc_class (OBJC2
// objc-runtime-new.h
struct objc_class: objc_object {
	Class isa;
	Class superclass;
	cache_t cache // 方法缓存
	class_data_bits_t bits //具体类信息
}

&FAST_DATA_MASK

struct class_rw_t {

}

struct class_ro_t {

}
```





### isa

instance的isa指向class，

class的isa指向meta-class，

Meta-class的isa指向基类的meta-class，基类的meta-class的isa指向自己，

class的superclass指向父class，基类的superclass为nil，

meta-class的superclass指向父meta-class，基类的meta-class的superclass指向基类class



从64bit开始 isa&ISA_MASK 才能得到对应类的地址值













### 面试题

- 一个NSObject对象占用多少内存

  系统分配了16字节，使用了8个字节

- 对象的isa指针指向哪

- OC的类信息存放在哪

