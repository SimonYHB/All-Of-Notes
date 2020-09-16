## OC对象

### 对象的内存

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



### isa





### 面试题