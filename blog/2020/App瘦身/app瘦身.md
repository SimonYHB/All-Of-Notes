

## 背景

为什么要进行包大小优化？

虽然苹果官方一直在提高最大的可执行文件大小，在 iOS 13 还取消了强制的 OTA 限制，但是超过 200 MB 会默认请求用户下载许可（可在 设置 - iTunes Store与App Store - App下载 中配置），并且iOS 13 以下的超过 200 MB 无法使用 OTA，影响了整体更新率。

如果 App 还要适配 iOS 8 之前的版本，苹果还规定了主二进制 __TEXT 段的大小不能超过 60MB，否则上传构建时会被打回。

为了更好的用户体验，减少用户等待时间，包瘦身仍然是 App 优化中重要的一环。

![01.png](./images/01.png)



## App Thinning

严格来说App Thinning不会让安装包变小，但用户安装应用时，苹果会根据用户的机型自动选择合适的资源和对应CPU架构的二进制执行文件（也就是说用户本地可执行文件不会同时存在armv7和arm64），安装后空间占用更小

## 资源瘦身

### 无用图片资源

通过资源关键字进行全局匹配，筛选出未使用的资源。有些资源使用是通过拼接或者后台下发名称，需额外进行检查，防止误删。

### 图片等资源压缩

建议使用无损压缩，例如 ImageOptim、compress命令等，否则需要设计接入进行检查。



### 重复文件



### 图片资源放入image.xcassets





## 代码瘦身

### LinkMap 结合 Mach-O 找无用代码

- 查找无用 selector
  - 结合LinkMap文件的__TEXT.__text，通过正则表达式**([+|-][.+\s(.+)])**，我们可以提取当前可执行文件里所有objc类方法和实例方法（SelectorsAll）。再使用otool命令**otool -v -s __DATA __objc_selrefs**逆向__DATA.__objc_selrefs段，提取可执行文件里引用到的方法名（UsedSelectorsAll），我们可以大致分析出SelectorsAll里哪些方法是没有被引用的（SelectorsAll-UsedSelectorsAll）。注意，系统API的Protocol可能被列入无用方法名单里，如UITableViewDelegate的方法，我们只需要对这些Protocol里的方法加入白名单过滤即可。
- 查找无用 oc类
  - 通过搜索"**[ClassName alloc/new**"、"**ClassName \***"、"**[ClassName class]**"等关键字在代码里是否出现
  - 通过otool命令逆向__DATA.__objc_classlist段和__DATA.__objc_classrefs段来获取当前所有oc类和被引用的oc类，两个集合相减就是无用oc类

### 精简代码

simian 扫描重复代码

### 通过 AppCode 找出无用代码

### 运行时检查类是否真正被使用过



## 编译选项优化

- Strip Link Product设成YES，WeChatWatch 可执行文件减少0.3M
- Make Strings Read-Only设为YES，也许是因为微信工程从低版本Xcode升级过来，这个编译选项之前一直为NO，设为YES后可执行文件减少了3M
- 去掉异常支持，Enable C++ Exceptions和Enable Objective-C Exceptions设为NO，并且Other C Flags添加-fno-exceptions，可执行文件减少了27M，其中__gcc_except_tab段减少了17.3M，__text减少了9.7M，效果特别明显。可以对某些文件单独支持异常，编译选项加上-fexceptions即可。但有个问题，假如ABC三个文件，AC文件支持了异常，B不支持，如果C抛了异常，在模拟器下A还是能捕获异常不至于Crash，但真机下捕获不了（有知道原因可以在下面留言：）。去掉异常后，Appstore后续几个版本Crash率没有明显上升。个人认为关键路径支持异常处理就好，像启动时NSCoder读取setting配置文件得要支持捕获异常，等等

## 其他

### 静态库瘦身 只保留需要用的指令集

### App Extension 用动态库替代静态库

减少了二进制文件的体积，但增加了整个包的大小，还会增加启动时间，需多方面考虑。

### 慎重引入第三方库

### H5本地资源优化（只保留主页面）



## 总结

在项目瘦身过程中，上面列举的方式不一定都使用。例如当项目具有动态化，许多类和方法都不会在代码中直接产生引用，而可能是通过接口方式下发数据来使用，如果没有配置表会容易产生误删。



### 参考资料

[10 | 包大小：如何从资源和代码层面实现全方位瘦身？-极客时间](https://time.geekbang.org/column/article/88573?utm_source=web&utm_medium=pinpaizhuanqu&utm_campaign=baidu&utm_term=pinpaizhuanqu&utm_content=0427)

[iOS-APP包的瘦身之旅（从116M到现在的36M的减肥之路）_移动开发_ZFJ_张福杰-CSDN博客](https://blog.csdn.net/u014220518/article/details/79725478)

[iOS 瘦身之道](https://juejin.im/post/5cdd27d4f265da036902bda5)

[iOS安装包瘦身指南](http://www.zoomfeng.com/blog/ipa-size-thin.html)

[Humble Assets Catalog](http://lingyuncxb.com/2019/04/14/HumbleAssetCatalog/)

https://github.com/skyming/iOS-Performance-Optimization



- [iOS微信安装包瘦身](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=207986417&idx=1&sn=77ea7d8e4f8ab7b59111e78c86ccfe66&scene=24&srcid=0921TTAXHGHWKqckEHTvGzoA#rd)

