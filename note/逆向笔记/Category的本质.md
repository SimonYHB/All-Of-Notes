- Category的本质

  ```objective-c
  struct category_t {
      const char *name;
      classref_t cls;
      struct method_list_t *instanceMethods;
      struct method_list_t *classMethods;
      struct protocol_list_t *protocols;
      struct property_list_t *instanceProperties;
      // Fields below this point are not always present on disk.
      struct property_list_t *_classProperties;
  
      method_list_t *methodsForMeta(bool isMeta) {
          if (isMeta) return classMethods;
          else return instanceMethods;
      }
  
      property_list_t *propertiesForMeta(bool isMeta, struct header_info *hi);
  };
  ```

  - 结构中没有用于存放成员变量

    - 通过关联对象实现

  - 方法的调用

    objc源码分类内容载入路径： _objc_init -> map_images_nolock -> _read_images -> remethodizeClass -> attachCategories -> attachLists

    - load

      实现：直接找到load地址调用函数

    - initialize

      实现：消息机制

  - 匿名分类不是分类，而是类拓展，用于设置私有属性和私有方法申明，没有实现

- 内存分配

  - 对象内存对齐：8
    - sizeof
  - 内存分配对齐： 16
    -  malloc_size

