## 问题

- iOS 编译有几个过程？分别作了些什么？

## 编译原理

### 编译流程

编译器分为前端和后端

Xcode3之前前端编译器为 GCC，后面自研 Clang+LLVM 和 Swift+LLVM

1. 源代码（source code） 

2. 预处理器（preprocessor） 

   - 删除所有`#define`，并将所有宏定义展开，在源码中使用的宏定义会被替换为对应代码

   - 将被包含的文件插入到预编译指令`(#include)`所在位置（这个过程是递归的）

   - 删除所有注释：// 、/* */等

   - 添加行号和文件名标识，以便于编译时编译器产生调试用的行号信息及编译时能够显示警告和错误的所在行号

   - 保留所有的`#pragma`编译器指令，因为编译器须要使用它们。

3. 编译器（compiler）

   1. 词法分析 把源文件中的代码转化为特殊的标记流，源码被分割成一个一个的字符和单词，在行尾Loc中都标记出了源码所在的对应源文件和具体行数

   2. 语法分析 把词法分析生成的标记流，解析生成抽象语法树 AST

   3. 静态分析 AST
   4. 生成 LLVM IR 作为后端的输入
   5. LLVM 优化
      - 针对全局变量优化、循环优化、尾递归优化等。
      - 在 Xcode 的编译设置里也可以设置优化级别-01，-03，-0s，还可以写些自己的 Pass。
      - Pass 是 LLVM 优化工作的一个节点，一个节点做些事，一起加起来就构成了 LLVM 完整的优化和转化。
      - 如果开启了 bitcode苹果会做进一步的优化，有新的后端架构还是可以用这份优化过的 bitcode 去生成。

4. 汇编程序（assembler） 

5. 目标代码（object code） 

6. 链接器（Linker） 

7. 可执行文件（executables）





### OC 

### Swift

## 优化手段

### OC

### Swift





## 参考资料

- [iOS 编译原理与应用](https://juejin.im/post/6844903896230395918)

- [美团 iOS 工程 zsource 命令背后的那些事儿](https://tech.meituan.com/2019/08/08/the-things-behind-the-ios-project-zsource-command.html)

- 

- [iOS底层学习](https://juejin.im/post/6844904040841641998)

- [iOS 编译知识小结](https://juejin.im/post/6850418118590726151)

- [深入剖析 iOS 编译 Clang / LLVM](https://xiaozhuanlan.com/topic/4916328705)

- 

  

  





- [iOS 微信编译速度优化分享](https://mp.weixin.qq.com/s/-wgBhE11xEXDS7Hqgq3FjA)
- [优化 iOS 项目编译时间](https://juejin.im/post/6844903940778115086)

- [优化 Xcode 编译时间](https://juejin.im/post/6844903591405158408)
- [Optimizing-Swift-Build-Times](https://github.com/fastred/Optimizing-Swift-Build-Times)





- https://tech.youzan.com/you-zan-ji-yu-er-jin-zhi-de-bian-yi-ti-xiao-ce-lue/