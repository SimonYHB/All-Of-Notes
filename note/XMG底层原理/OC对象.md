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

分类中的属性只会生成get/set方法声明，且在分类中不能直接添加成员变量，可以在get/set方法里通过关联对象来实现为分类添加成员变量。



### 关联对象

```
objc_setAssociatedObject(id object, const void * key, id value, objc_AssociationPolicy policy)
objc_getAssociatedObject
objc_removeAssociatedObject
key用字符串或(@selector(xx)和_cmd)最方便
```

关联对象并不是存储在关联对象本身内存中，而是存储在全局统一的AssociationsManager中，要移除某个关联对象时，value传入nil就可以，内部会整队移除。另外关联对象对会引用value，对object没有引用关系，只是用了其地址值作为key

AssociationsManager的结构层级：

- **AssociationsManager**
  - **AssociationsHashMap**
    - key是disguised_ptr_t指针，是外部传入的object对象的地址
    - value是**ObjectAssociationMap**
      - key是void *指针，是外部传入的key值
      - value是**ObjcAssociation**，存放的是policy和value



### Block

block本质也是oc对象，也有isa指针，封装了函数调用及函数调用环境 

````
Block转成C++代码

struct __xxx_block_imp_0 {
	... //变量捕获
	struct __block_impl impl; //封装block执行代码
	struct __xxx_block_desc_0* Desc;
	 __xxx_block_imp_0() // C++构造函数
}

struct ___block_impl {
	void *isa;
	int Flags;
	int Reserved;
	void *FuncPtr
}


struct __xxx_block_desc_0 {
	size_t reserved;
	size_t Block_size
	void (*copy)() // 堆block引用对象才会有，栈复制到堆上时调用
	void (*dispose)() // 堆block引用对象才会有，block被废弃时调用
}
````

block变量捕获机制：

| 变量           | 是否捕获 | 访问方式               |
| -------------- | -------- | ---------------------- |
| 局部变量auto   | 是       | 值传递(对象是指针指向) |
| 局部变量static | 是       | 指针传递               |
| 全局变量       | 否       | 直接访问               |



当block内部访问了对象类型的局部变量时：

- 栈block不会产生强引用
- 堆block会引用对象(strong或weak,取决于修饰符)，堆block里的copy函数调用_Block_object_assign函数做引用处理
- dispose的_Block_object_dispose会对对象release操作



block内修改变量：

- auto是值拷贝了一份block里，不能直接修改外部的auto变量，只能修改static和全局变量
- 用`__block` 修饰auto变量才能在block里修改，编译器会将其包装成对象传入block，访问时实际是访问 `变量->forwarding->变量`，其中forwarding是指向封装对象本身
- forwarding是为了解决block从栈拷贝到堆，在栈时forwarding是指向栈上的自己，拷贝到堆后，栈和堆都有该对象，此时forwarding指向的是堆上的自己

 

__block修饰:

- 基本数据类型
  - 堆block需要对__block包装的对象进行内存管理(copy/dispose)
  - copy的_Block_object_assign会对包装对象强引用，并且如果变量是在栈上，还会将变量移到堆上
  - dispose的_Block_object_dispose会对对象release操作

- 对象类型

  - block内部强引用block封装的对象，封装的对象内部有实际对象指针，引用关系取决于修饰符
  - MRC下，封装对象对实际对象的引用都是弱引用

  

循环引用：

- __weak 对象销毁会自动置为nil (ARC最常用)

- __unsafe_unretained 对象销毁不会自动置为nil，还是指向原对象地址，产生野指针 (MRC不支持weak，只能用这个或者\__block，MRC下才不用强引用对象)

- __block 将对象在block内置为nil,并且要调用block (基本不用，花里胡哨...)

  





 block类型：

- NSGlobalBlock 没有访问auto变量
- NSStackBlock 访问了auto变量（放在栈上出了作用域会被销毁）
- NSMallocBlock NSStackBlock调用了copy（所以block作为属性值，是用copy修饰）



ARC 模式下，以下场景Block会自动做copy操作放到堆上

- 作为函数返回值
- 将block赋值给__strong，被强指针指向
- block作为Cocoa API中方法名含有usingBlock的参数
- GCD的API参数



























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

- Block的原理和本质

  封装了函数调用以及调用环境的OC对象

- __block的作用和注意点

  __block会将对象包装成对象，解决在block内部无法修改局部变量问题，block对其进行内存管理等

- block属性为什么要用copy修饰

  copy后才会将block拷贝到堆上，方便进行内存管理

- block修改NSMutableArray，需不需要添加_block

  不需要，array是指针指向，在block内部修改，外部也会跟着修改

