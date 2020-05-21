

## 背景

为什么要进行包大小优化？

虽然苹果官方一直在提高最大的可执行文件大小，在 iOS 13 还取消了强制的 OTA 限制，但是超过 200 MB 会默认请求用户下载许可（可在 设置 - iTunes Store与App Store - App下载 中配置），并且iOS 13 以下的超过 200 MB 无法使用 OTA，影响了整体更新率。

如果 App 还要适配 iOS 8 之前的版本，苹果还规定了主二进制 __TEXT 段的大小不能超过 60MB，否则上传构建时会被打回。

为了更好的用户体验，减少用户等待时间，包瘦身仍然是 App 优化中重要的一环。

![01.png](./images/01.png)





## 资源瘦身

### 移除无用图片资源

通过资源关键字进行全局匹配，筛选出未使用的资源。有些资源使用是通过拼接或者后台下发名称，需对筛选出的资源进行筛选，防止误删。

- [LSUnusedResources](https://github.com/tinymind/LSUnusedResources)

### 压缩图片等资源文件

- 建议使用无损压缩，例如 [ImageOptim](https://imageoptim.com/mac)、[pngquant命令](https://pngquant.org)，如果涉及有损压缩最好要求设计介入进行资源检查。

- 还可以使用 [Webp](https://developers.google.com/speed/webp/) 格式的图片，Webp 是由 Google 推出的图片格式，相同分辨率的图片体积只有 jpeg 格式的 1/3，可以使用 [Precompiled Utilities](https://developers.google.com/speed/webp/docs/precompiled) 进行格式压缩转换，目前 SDWebImage、Kingfisher 都用支持该格式解析的拓展。

- Xcode 本身也提供压缩图片的编译选项

  - Compress PNG Files

    打包的时候基于 pngcrush 工具自动对图片进行无损压缩，如果我们已自行对图片进行压缩，该选项最好关闭。

  - Remove Text Medadata From PNG Files

    移除 PNG 资源的文本字符，比如图像名称、作者、版权、创作时间、注释等信息。

  ![01.png](./images/05.png)





### 删除重复文件

通过校验所有资源的 MD5，筛选出项目中的重复资源。

 大小对比 > 部分 MD5 签名对比 > 完整 MD5 签名对比 > 逐字节对比

- [fdupes](https://github.com/adrianlopezroche/fdupes) 

### 图片资源放入.xcassets

- 尽量将图片资源放入 Images.xcassets 中，包括 pod 库的图片。 Images.xcassets 中的图片加载后会有缓存，加快调用，在最终打包时会自动进行压缩（Compress PNG Files），并且根据最终运行设备进行 2x 和 3x 分发。

- 对于内部 Pod 库中的资源文件，我们可以在 Pod 库里面的 Resources 目录下新建 Asset Catalog 文件，命名为 Images.xcassets，移入所有图片文件，接着手动修改该 SDK 的 `podspec` 文件指定使用该 Images.xcassets。

  ```
  s.resource_bundles = {
      'xxsdk' => ['PAX/Assets/*.xcassets']
  }
  ```

  > Pod 资源文件的引用方式分为 resource_bundles 和 resources，这里我们使用的是 resource_bundles。
  >
  > - resource_bundles
  > - resources
  >
  > 

  



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
- Valid Architectures 不支持32位以及 iOS8 ，可去掉 armv7 ，减小生成的 ipa 包。



## App Thinning

WWDC2015 发布会上首次介绍了 App Thinning，并在 iOS9 开始应用。严格来说App Thinning不会让安装包变小，但用户安装应用时，苹果会根据用户的机型自动选择合适的资源和对应CPU架构的二进制执行文件（也就是说用户本地可执行文件不会同时存在 armv7 和 arm64），减少下载流量和安装占用空间。

在上传 App 时，配置 App Thinning 即可开启。分为三个部分： Slicing、Bitcode、On-Demand Resources。

![02.png](./images/04.png)

### Slicing

在向 iTunes connect 上传 App 后，会做 App 进行分割，创建不同的变体来适配不同的设备，不同变体之间的差异主要体现在系统指令集和资源文件上。

在项目的 xcassets 目录添加图片，2x 和 3x 图会分别放入到不同的变体中，用户从 App Store 下载时只下载特定的变体，而不会下载全部的指令集和资源文件。

![02.png](./images/02.jpg)

### Bitcode 

Bitcode 是编译好的程序中间码，使用 Bitcode 上传到 iTunes Connect 的 app 将会在 Apple 服务器中进行链接和编译。该步骤主要是方便 Apple 推出新的架构或LLVM优化时无需重新上传 App。

通过设置项目的 `Build Settings -> Enable Bitcode` 为 YES 开启Bitcode，使用时需要保证 App 中所有的静态库和动态库都支持，否则会编译失败。

由于 App 的编译是在 Apple 服务器中进行的，所以本地无法获取 dSYM 文件进行崩溃分析，需在上传时勾选 `Include app symbols for your application* to receive symbolicated crash logs from Apple`，再从  `Xcode -> Window -> Organizer` 或者 Apple Store Connect 中下载对应的 dYSM文件。

### On-Demand Resources

可将部分资源单独下载，而不随着 App 一同下载，减少初始 App 的大小。例如相机的滤镜和游戏关卡。

![03.png](./images/03.jpg)

## 其他

### 静态库瘦身 只保留需要用的指令集

### App Extension 用动态库替代静态库

减少了二进制文件的体积，但增加了整个包的大小，还会增加启动时间，需多方面考虑。

### 慎重引入第三方库

### H5本地资源优化（只保留主页面）



## 总结

在项目瘦身过程中，上面列举的方式不一定都适用。例如当项目具有动态化，许多类和方法都不会在代码中直接产生引用，而可能是通过接口方式下发数据来使用，如果没有配置表会容易产生误删。我们应该怀着敬畏之心，宁可多花点时间，避免误操作，毕竟瘦身虽可贵，安全价更高 😂。



### 参考资料

[10 | 包大小：如何从资源和代码层面实现全方位瘦身？-极客时间](https://time.geekbang.org/column/article/88573?utm_source=web&utm_medium=pinpaizhuanqu&utm_campaign=baidu&utm_term=pinpaizhuanqu&utm_content=0427)

[iOS-APP包的瘦身之旅（从116M到现在的36M的减肥之路）_移动开发_ZFJ_张福杰-CSDN博客](https://blog.csdn.net/u014220518/article/details/79725478)

[iOS 瘦身之道](https://juejin.im/post/5cdd27d4f265da036902bda5)

[iOS安装包瘦身指南](http://www.zoomfeng.com/blog/ipa-size-thin.html)

[Humble Assets Catalog](http://lingyuncxb.com/2019/04/14/HumbleAssetCatalog/)

https://github.com/skyming/iOS-Performance-Optimization



- [iOS微信安装包瘦身](https://mp.weixin.qq.com/s?__biz=MzAwNDY1ODY2OQ==&mid=207986417&idx=1&sn=77ea7d8e4f8ab7b59111e78c86ccfe66&scene=24&srcid=0921TTAXHGHWKqckEHTvGzoA#rd)

