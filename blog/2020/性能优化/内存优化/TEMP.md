1. 资料收集
2. 确定大纲
   - 内存相关概念介绍
   - iOS内存机制
   - 常见内存问题及优化
   - iOS常用内存分析工具
3. 按模块学习（列出问题点）
4. 按模块输出
5. 深入更多内容







## 为什么要减小内存

### ARC出现之前

## 一些概念

- clean page 

- dirty page

- Compressed page

- memory warnings

  不一定是因为自己的应用造成的

- 内存占用限制

## 检测工具

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

## 常见内存相关问题



### 图片的内存

- 

### OOM



## 优化建议

- Framework 使用单例，减少加载次数

## 总结

### 参考资料

- [WWDC2018 - iOS Memory Deep Dive ](https://developer.apple.com/videos/play/wwdc2018/416/)
- [OOM探究：XNU 内存状态管理](https://www.jianshu.com/p/4458700a8ba8) （待深入）
- 



- https://juejin.im/post/5e8ee75df265da47e7526b67#heading-14
- https://mp.weixin.qq.com/s/YpJa3LeTFz9UFOUcs5Bitg
- https://wetest.qq.com/lab/view/367.html?from=content_juejin
- http://blog.devtang.com/2016/07/30/ios-memory-management/
- https://juejin.im/post/5c0744f6e51d45598b76f481#heading-9
- https://juejin.im/post/5e3794a7f265da3e51531c9d#heading-79
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://www.meiwen.com.cn/subject/jixyeftx.html