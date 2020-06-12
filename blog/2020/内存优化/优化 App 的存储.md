- 优化 App 的存储

  - 影响

    - 电量
    - 设备空间

  - 图片资源

    - HEIC 图片格式
      - iOS 11以上支持
      - 同画质比 JPEG 节省50%
      - 支持保存辅助图片（深度图、视差图等）
    - Asset Catalog 管理资源
      - 随需应变 on demand resource
      - app分割
      - 优化磁盘空间占用
      - 提升加载性能，app启动时效果明显
      - 支持GPU和无损/有损压缩，硬件解码

  - 文件系统元数据

    - 修改 文件
      - 240字节文件至少产生一次读取 三次写 fsync
      - 三次写操作是由文件系统元数据导致
        - 更新文件系统节点  4k
        - 更新对象映射 4k
        - 文件本身写入 4k
        - 总共写入12k
      - 创建/删除/修改都是有代价的，至少要产生8k的数据
    - 缓存和存储
      - 操作系统缓存 逻辑I/O
      - 磁盘缓存  物理I/O
      - 永久存储
    - fsync()
      - 将缓存数据存储到磁盘上
      - 数据不一定立刻写入到永久存储
      - 不保证写入顺序
      - 开销大
      - 系统会周期执行
    - F_FULLFSYNC
      - 强制缓存刷入磁盘
      - 所有的磁盘缓存都写入大永久存储
      - 开销大，系统会周期执行
    - F_BARRIERFSYNC
      - 能保证 I/O 顺序
      - 比 F_FULLSYNC 开销小

  - 序列化的数据文件（plists、XML、JSON）

    - 修改都必须替换整个文件，拓展性差，容易误用，不要当做数据库使用
    - NSUserDefaults默认是Plist

  - Core Data

    - 已高度封装，可减少 Model 层的代码

    ![image-20200609101821258](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609101821258.png)

    ![image-20200609101852707](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609101852707.png)

  - 数据库连接

    ![i1ri](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609101939645.png)

  - Delete 模式日志

    - 使用 WAL 模式日志替代减少写入

      ![image-20200609102109581](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609102109581.png)

  - 通过事务组合多个命令减少页面写入

    ![image-20200609102314233](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609102314233.png)

  - 文件大小和私密性

    ![image-20200609102350880](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609102350880.png)

    - 不要使用VACUUM
      - 很慢且 I/O密集型操作
      - 所有有效数据都被写入至少两次（一次日志一次文件）
      - 用增量式自动清除和快速删除替代
    - PRAGMA schema.auto_vacumn = Increment

    

    ![image-20200609102733398](/Users/yehuangbin/Library/Application Support/typora-user-images/image-20200609102733398.png)



- File Activity Instrument 文件追踪器 查看都打开和操作什么文件
- Metrics 获取性能数据的新工具
  - XCTest配套
  - MetricKit 收集一天24hr的聚合数据
  - Xcode Metrics Organizer 查看
  - 电池
  - 性能
    - 卡顿
    - 磁盘
    - 启动
    - 内存

- WWDOC
  - Check out Making Apps with Core Data from #developerapp，https://developer.apple.com/wwdc19/230
  - Check out Improving Battery Life and Performance from #developerapp，https://developer.apple.com/wwdc19/417
  - Check out Optimizing Storage in Your App from #developerapp，https://developer.apple.com/wwdc19/419







优化APP存储1对1



Kewei Li (Apple) 对所有人说:  下午 2:37 

https://github.com/topics/heic

Kewei Li (Apple) 对所有人说:  下午 2:38 

https://github.com/timonus/UIImageHEIC

Kewei Li (Apple) 对所有人说:  下午 2:43 

https://developer.apple.com/documentation/xcode/improving_your_app_s_performance?language=objc

Kewei Li (Apple) 对所有人说:  下午 2:43 

https://help.apple.com/xcode/mac/current/#/devb642b28ac

Kewei Li (Apple) 对所有人说:  下午 2:47 

https://developer.apple.com/documentation/metrickit?language=objc



Kewei Li (Apple) 对所有人说:  下午 2:53 

kewei_li@apple.com