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



### KVO

使用KVO的对象，类会变成NSKVONotifying_Class，是通过Runtime动态创建的子类，set方法的实现会变成Foundation框架的_NSSetXXXValueAndNotify方法，该方法内部流程如下：

willChangeValueForKey->父类set方法->didChangeValueForKey，其中didChangeValueForKey内会调用observeValueForKeyPath告诉监听者值的改变

 

NSKVONotifying_Class除了重写set方法，还回重写class(返回原类)、dealloc(收尾工作)、_isKVO方法



### KVC

Set流程：

1. setKey
2. _setKey
3. 判断 accessInstanceVariableDirectly，如果是 No 则抛出异常，为 YES 则依次查找`_key、_isKey、key、isKey`变量



get流程：

1. 方法查找getKey->key->isKey->_key
2. 判断 accessInstanceVariableDirectly，为 YES 则依次查找`_key、_isKey、key、isKey`



### Category

编译时会转成_category_t的结构体，分类中的内容会在程序运行过程中(read_image)通过Runtime(attachCategories)合并到类对象或元类对象中

以rw-methods为例，重新分配方法列表数组的内存，将新的方法列表移入（后编译的分类会放在前面被先调用），旧的方法列表移动到数组末尾

相关方法：

_objc_init -> map_images -> map_images_nolock -> _read_images -> remethodizeClass -> attachCatagory -> attachLists -> realloc、memmove、memcopy(移动多个元素时，copy会从小地址开始挪动，如果是在同一个内存中操作可能会出现元素互相覆盖，而move内部有判断，会保证数据完整的挪动到目标位置)

load：虽然分类的load方法会合并到类中，但是在程序加载时load images，就会先通过地址直接调用load方法，所有类和分类的load方法都会被调用，且只会调用一次。load的调用顺序是父类->子类->父类分类->子类分类 。不同类之间load加载顺序是按照编译顺序先后调用。如果我们主动调用load方法，才会走消息发送机制，像普通方法一样调用方法列表中的最前面一个

initialize：在类第一次接受到消息时调用，并且是通过消息发送机制调用的，只会调用方法列表最前面一个。先调用父类的，再调自身及子类的。如果子类没有实现Initialize，会调用父类的initialize，导致父类的Initialize会多次调用(a->b 调用b会初始化a,b，如果b没有实现，初始化调用的也是a，导致调用两次初始化a)

































### 面试题

- 一个NSObject对象占用多少内存

  系统分配了16字节，使用了8个字节

- 对象的isa指针指向哪

- OC的类信息存放在哪

- KVO的实现

- 手动触发kvo

  手动调用willChangeValueForKey和didChangeValueForKey

- 直接修改成员变量会触发kvo吗？

  不会。因为不会走set方法，除非自己手动触发

- KVC修改属性会触发KVO吗

  会触发，没有setter方法，KVC内部也会自己触发KVO

- KVC的原理

- Category的实现原理

- Category和Extension的区别

  extension编译时信息就包含在类中，category编译会生成_category_t 的结构体，包含对象方法、类方法、属性和协议信息等，运行时才通过runtime合并到类中

- Category有load方法吗？什么时候调用？能继承吗

  

- load、initialize的区别?  category中的调用顺序？有继承时的调用过程

- Category添加成员变量



