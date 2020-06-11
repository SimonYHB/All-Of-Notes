1. 资料收集

2. 确定大纲

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

- 图片的内存
  - 不同格式差别很大
    - 如何选择合适的格式？ 使用 UIGraphicsImageRenderer （iOS10之后）替代 UIGraphicsBeginImageContextWithOptions（固定是4字节像素格式SRGB）
  - 缩小图像
    - 将大图片加载到小空间时， UIImage （UIImage.contentsOfFile）需要先解压整个图像再渲染，会产生内存峰值
    -  ImageIO框架（CGImageSourceCreateWithURL）可以直接指定加载到内存的图像尺寸和信息，用 ImageIO框架 替代 UIImage 可避免图像峰值
  - 后台优化
    - 切入后台时，图像默认还在内存中  
    - 退到后台或view消失时从内存中移除图片，进入前台或view出现时再加载图片 （通过通知) 

## 优化建议

- Framework 使用单例，减少加载次数

## 总结

### 参考资料

- [WWDC2018 - iOS Memory Deep Dive 24：29](https://developer.apple.com/videos/play/wwdc2018/416/)
- https://www.jianshu.com/p/4458700a8ba8
- 





- https://www.jianshu.com/p/4458700a8ba8
- https://wetest.qq.com/lab/view/367.html?from=content_juejin
- http://blog.devtang.com/2016/07/30/ios-memory-management/
- https://juejin.im/post/5c0744f6e51d45598b76f481#heading-9
- https://juejin.im/post/5e8ee75df265da47e7526b67#heading-14
- https://juejin.im/post/5e3794a7f265da3e51531c9d#heading-79
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://juejin.im/post/5a5e13c45188257327399e19#heading-8
- https://www.meiwen.com.cn/subject/jixyeftx.html