- 加密解密

  - 对称加密

    - 算法
      - DES
      - 3DES
      - AES（主流）
    - 密钥配送处理
      - 事先共享密钥
      - 密钥分配中心
      - Diffie-Hellman密钥交换算法 （openSSH使用）
      - 公钥密码
    - 缺点
      - 不能很好的解决密钥配送问题
  
- 非对称加密（公私钥）
  
  - 概念
      - 公钥加密私钥解密，私钥加密公钥解密
    - 解决密钥配送问题（防窃听）
      - 由消息的接收者，生成一对公钥、私钥
      - 将公钥发送给消息的发送者
      - 发送者使用公钥加密
    - RSA 算法
    - 缺点
    - 加密解密速度慢
  
- 混合密码系统
  
  - 会话密钥
  
    - 随机生成的临时密钥，作为对称密钥加密信息，提高速度
  
  - 加密步骤
  
    1. 获取接受者的公钥
  
    2. 消息发送者生成会话密钥，加密信息
  
    3. 使用接受者公钥加密会话密钥
  
    4. 将1和2的结果一起发送给接受者
  
  - 加密步骤
  
    1. 消息接收者用自己的私钥解密出会话密钥
      2. 再用第1步解密出来的会话密钥，解密消息
  
  - 优点
  
    - 加密解密消息速度快
      - 解决了密钥配送问题
    - 问题
    - 无法保证数据不被篡改
      - 解决-> 数字签名

- 单向散列函数

  - 又被称为消息摘要函数，哈希函数
  
- 输出的散列值又被称为消息摘要，指纹
  - 特点

    - 根据下次生成对应的固定长度的散列值
  - 计算速度快
    - 每条消息散列值不同
    - 具备单向性，不可逆
  - 常见的函数
  
  - MD4、MD5
      - 产生128bit的散列值，已不安全
    - Mac终端默认可使用
    - SHA-1
      - 产生160bit的散列值，已不安全
    - SHA-2
      - SHA-256、SHA-384、SHA-512，长度分别为256/384/512
    - SHA-3
      - 全新标准，研发中心
  - 应用场景
  
    - 防止数据被篡改
  - 口令加密
  - 数字签名
  - 用私钥加密消息的散列值，生成密文
    - 数字签名步骤
  
    - 发送者用私钥加密数据
      - 接受者使用发送者公钥解密数据
    - 通过比对消息是否一致
      - 问题：相同数据发了两份
    - 数字签名的改进
  
      - 发送者计算消息散列值
    - 发送者通过私钥加密散列值生成签名
      - 接受者计算消息的散列值
    - 接受者通过公钥解密得到签名
      - 比对签名和新生成的散列值是否一致
    - 数字签名的问题
  
      - 无法验证公钥是属于真正的发送者（中间人攻击） 
    - 解决-> CA证书传递公钥

- 证书

  - 证书是什么
    - 全称叫公钥证书
    - 包含姓名、邮箱等个人信息，以及发送方的公钥
    - 并由认证机构CA用机构私钥进行签名
    - 通过认证机构来传递发送方的信息及公钥

- iOS签名机制 

  - 真机吊事

    - 作用

      - 保证用户手机上的App都是经过Apple官方认证的

    - 流程

      - 真机调试流程图

        ![image-20200502094347437](/Users/yehuangbin/Desktop/image-20200502094347437.png)

    - 组成

      - .cerSigningRequest文件 Mac公钥
      - .cer文件 利用Apple私钥，对Mac公钥生成数字签名
      - .mobileprovision 利用Apple私钥，对.cer证书+devices+AppID+entitlements生成数字签名

  - Appstore

    - 只通过苹果私钥验证

      ![image-20200506144639489](/Users/yehuangbin/Desktop/image-20200506144639489.png)

  - 企业发布

    - 与真机调试类似，但更简单点

- 重签名

  - 使用其他证书对应用进行重签名
  - 工具：codesign
  - 步骤
    - 准备embedded.mobileprovision文件
      - 通过xcode自动生成或从开发者证书网站生成
    - 从embedded.mobileprovision提取entitlements.plist权限文件
      - `security cms -D -i embedded.mobileprovision > temp.plist`
      - `/user/libexec/PlistBuddy -x -c 'Print :Entitlements' temp.plist > entitlements.plist`
    - 查看本机可用证书
      - `security find-identity -v -p codesigning`
    - 对.app内部的动态库、拓展等进行签名
      - `codesign -fs 证书ID xxx.dylib`
    - 对.app包进行签名
      - `codesign -fs 证书ID --entitlements entitlements.plist xxx.app`
  - 其他工具
    - iReSign
    - iOS App Signer
  
- 破解应用重签名

  - 原理 tweak插件编译后生成dylib，将dylib重签名后注入到Mach-O文件

    - 通过Theos开发的动态库插件，默认依赖于/Library/Frameworks/CydiaSubstrate
    - 如果要将插件打包到ipa中，也需要将CydiaSubstrate打包到ipa中，并且修改插件依赖 CydiaSubstrate 的加载地址。

  - 利用 insert_dylib  实现动态库注入

    - insert_dylib 动态库加载路径 Mach-O文件
    - 本质是往 Mach-O 文件的 Load Commands中添加一个LC_LOAD_DYLIB或LC_LOAD_WEAK_DYLIB
    - otool -L Mach-O 文件 可查看动态库依赖信息

  - 使用 install_name_tool 修改 Mach-O 文件中动态库的加载地址

    - install_name_tool -change 旧地址 新地址 Mach-O文件

  - 用自己的证书对 .app内部的动态库、AppExtension等进行重新签名

    - codesign -fs 证书ID xxx.dylib

  - 对最外层 app 包进行重签名

  - 常用环境变量

    - @executable_path 代表可执行文件所在的目录
    - @loader_path 代表动态库所在的目录

  - 注意
  
    - 安装包的可执行文件必须是经过脱壳的，重签名才会有效
    - .app内部的所有动态库、AppExtension、WatchApp都需要重新签名
  
    

