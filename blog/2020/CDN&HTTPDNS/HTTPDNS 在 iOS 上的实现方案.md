# HttpDNS 在 iOS 上的实现方案 

## 前言

最近在公司做网络相关的优化，重新整理了下之前对 HttpDNS 的认知并编写了本编文章，以自建 HttpDNS 方案为基准，讲解实际的移动端接入代码，由于每个人的实现方案都有所不同，这里只是抛转引玉，不一定适合所有项目。

## 介绍

当我们发起一个有域名的请求时，需要先经过 DNS 解析成 IP 地址再发起请求，所以 DNS 的域名解析的稳定性很关键，是网络请求的第一步。

### 域名解析流程

默认情况下，域名都是先经过运营商的 LocalDNS 查询，例如电信用户查询的就是电信的 LocalDNS，移动用户查询的是移动的 LocalDNS，通常两者之间解析的 IP 地址是不相同的。

LocalDNS 未命中再转发到权威 DNS 服务器上，以访问 www.163.com 为例，先找寻 DNS根服务器 获取 .com 域服务器的地址，再查询 .com 服务器得到 163.com 域服务器地址，最后通过 163.com 域服务器得到准确的 IP 地址，并缓存到 LocalDNS 服务器中。

整体流程如下图：

![图片来源于网络](./images/01.jpeg)

> 更多关于 DNS 内容可查看 [DNS 原理入门 - 阮一峰的网络日志](http://www.ruanyifeng.com/blog/2016/06/dns.html)

### LocalNDS带来的问题

随着 App 不同地区和运营商的用户不断扩大，经常会出现无法访问或者访问慢的问题，经过定位发现了以下问题。

#### LocalDNS 故障

运营商服务器故障，无法向权威服务器发起递归查询，导致解析失败。

#### DNS 劫持

第三方劫持了 DNS 服务器，篡改了解析结果，使客户端访问错误 IP 地址，实现资料窃取或恶意访问。

#### DNS 解析通过缓存返回

LocalDNS 缓存了之前的解析结果，当再次收到解析请求时不再访问权威 DNS 服务器，从而保证用户访问流量在本网消化或插入广告。如果权威服务器的 IP 或端口发生改变时，LocalDNS 未更新会导致访问失败。

#### 小运营商的解析转发

小运营商为了节省资源考虑，不向权威 DNS 服务器发起解析，而直接将请求发送到其他运营商进行递归解析，造成跨网访问，使用户访问变慢。

### 什么是 HttpDNS

由于 LocalDNS 存在种种问题而且不可控，是否可以绕过它自己进行解析？答案是肯定，通过在自己服务器维护一套域名与 IP 的映射关系，不再经过 LocalDNS 的 53 端口进行 DNS 解析，而是直接向自己服务器的 80 端口发起 HTTP 请求来获取 IP，再通过 IP 直接进行网络请求，这种方式便是 HttpDNS。

发起业务请求的步骤：

1. 客户端直接访问 HttpDNS 接口，获取与该业务请求的域名匹配的最优 IP 地址反馈给客户端。
2. 客户端向获取到的 IP 后就向直接往此IP发送业务协议请求。以 Http 请求为例，通过在 header 中指定 host 字段，向 HttpDNS 返回的IP发送标准的Http请求即可。
3. 基于容错的考虑，保留 LocalDNS 请求方式作为备用方案。

![图片来源于网络](./images/02.jpg)



### HttpDNS 优点

- 由于不再向 LocalDNS 发起解析，从根本上**避免了DNS劫持**。
- 直接通过 IP 访问，省了了域名解析过程，**提升用户访问速度**。
- 可在自己服务器通过算法对 IP 请求成功率高低的进行排序，筛选出优质 IP，**增加了请求的成功率**。



## iOS 端的网络请求实现

HttpDNS 整体方案需要服务器和移动端互相配合，在移动端主要是对网络请求进行封装，替换域名请求，做到对用户无感知，做好缓存和容错处理，并对成功/失败请求记录日志上传到服务器；服务器则需要维护域名与 IP 映射关系表并提供下发接口，并通过客户端日志进行优化排序。

接下来我们探讨一些实现的步骤。

### 服务器下发 IP 配置

在 App 启动时或者合适的时间向服务器请求配置表，这里的请求可以用固定 IP 替代域名，免去域名解析的过程。这里要注意的点是，如果使用 IP 请求，**需要在 header 指定 host 字段**。

```objective-c
NSString *host = "a.test.com";
[request setValue:host forHTTPHeaderField:@"Host"];
```

具体下发的配置表格式根据实际需求而定即可，例如：

```json
{
    "service" : "深圳移动",
    "enable" : 1,
    "domainlist" : [
                {
                "domain": "a.test.com",
                "ips" :  [
                        "222.66.22.111",
                        "222.66.22.102"
                        ]
                },
                {
                "domain": "b.test.com",
                "ips" :  [
                        "202.29.13.214"
                        ]
                }
    
}

```

### 封装网络请求

这里使用的网络框架 `AFNetworking`，我们的封装是基于该框架进行的。

```objective-c

/**
 请求后返回的block
 */
typedef void(^YENetworkManagerResponseCallBack)(NSDictionary *response, NSDictionary *error);



@interface YENetworkManager : NSObject

+ (nonnull instancetype)shareInstance;

/**
 获取服务器的DNS数据
 */
- (void)requestRemoteDNSList;

/**
 *  网络请求
 *  @param url             请求地址
 *  @param paraDic         请求入参 {key: value}
 *  @param method          请求类型 GET|POST
 *  @param timeoutInterval 请求超时时间
 *  @param headersDic      请求头 {key: value}
 *  @param callBack        请求结果回调
 */
- (void)requestWithUrl:(NSString *)url
                  body:(NSDictionary *)paraDic
                method:(NSString *)method
               timeOut:(NSTimeInterval)timeoutInterval
               headers:(NSDictionary *)headersDic
              callBack:(YENetworkManagerResponseCallBack)callBack;

@end

```

对外暴露两个接口，分别用于拉取 DNS 配置和网络请求，网络请求部分区别在于需在正式发起请求前先用 IP 替代域名，先看下简单的实现。

拉取配置这里先直接从本地读取，实际项目的还是应该去请求后台接口获取数据。

```objective-c
- (void)requestRemoteDNSList  {
    // 具体的实现根据服务端要求
    NSError*error = nil;
    NSData *data = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"dns.json" ofType:nil]];
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
    NSArray *domainlist = dic[@"domainlist"];
    NSMutableArray *tempDNSEntityArray = [[NSMutableArray alloc] initWithCapacity:0];
    for (NSDictionary *domainDict in domainlist)
    {
        //创建实体并保存
        YEDNSEntity *cdnsEntity = [YEDNSEntity yy_modelWithDictionary:domainDict];
        [tempDNSEntityArray addObject:cdnsEntity];
    }
    self.dnsEntityListCache = tempDNSEntityArray;
    // TODO: 根据实际需求是否需要存入本地数据库
}
```

转换 ip 是，将域名作为键，在缓存中查来相应的地址，若命中则创建新的 request，并完成：

1. 以 ip 替换接口域名
2. 添加域名到头部 host 字段
3. 将原 request 的 Cookie 设置到新 request

```objective-c
// 判断是否支持
- (BOOL)supportHTTPDNS:(NSURLRequest*)request {

    //无DNS数据不处理
    if (self.dnsEntityListCache.count == 0) {
        return NO;
    }

    //本地请求不处理
    if ([request.URL.scheme rangeOfString:@"http"].location == NSNotFound)
    {
        return NO;
    }


    //IP不处理
    if ([self isIPAddressString:request.URL.host])
    {
        return NO;
    }
    return YES;
}

// HTTPDNS转换
- (NSURLRequest *)transfromHTTPDNSRequest:(NSURLRequest *)request {
    if ([self supportHTTPDNS:request]) {
        YEDNSEntity *entity = [self queryDNSEntityWithDomain:request.URL.host];
        if (entity == nil) {
            return request;
        }
        // 创建ip请求
        NSMutableURLRequest *newURLRequest = request.mutableCopy;
        NSString *ipAddress = nil;
        if (entity.ips && entity.ips.count > 0 && (ipAddress = entity.ips.firstObject))
        {
            //原始host替换为IP
            NSString *originalHost = request.URL.host;
            NSString *newUrlString = [newURLRequest.URL.absoluteString stringByReplacingFirstOccurrencesOfString:originalHost withString:ipAddress];
            newURLRequest.URL = [NSURL URLWithString:newUrlString];
            
            //添加host头部
            NSString *realHost = originalHost;
            [newURLRequest setValue:realHost forHTTPHeaderField:@"host"];
            
            //添加原始域名对应的Cookie
            NSString *cookie = [self getCookieHeaderForRequestURL:request.URL];
            if (cookie)
            {
                [newURLRequest setValue:cookie forHTTPHeaderField:@"Cookie"];
            }
        }
        return newURLRequest;
        
    }
    return request;
}
```

这样我们就拿到了新的 ip 的请求体，通过 AFNetworking 发出请求即可。

```objective-c
- (void)requestWithUrl:(NSString *)url
                  body:(NSDictionary *)paraDic
                method:(NSString *)method
               timeOut:(NSTimeInterval)timeoutInterval
               headers:(NSDictionary *)headersDic
              callBack:(YENetworkManagerResponseCallBack)callBack {
    // 参数异常处理
		// ....
    
    // 序列化工具
    AFHTTPRequestSerializer *requestSerializer = [AFJSONRequestSerializer serializer];
    // 设置超时时间
    requestSerializer.timeoutInterval = timeoutInterval < 0 ? 10 :timeoutInterval;
    // 设置请求头
    for (NSString *headerName in headersDic.allKeys)
    {
        NSString *headerValue = [headersDic objectForKey:headerName];
        [requestSerializer setValue:headerValue forHTTPHeaderField:headerName];
    }
    
    // 构建原始request
    NSURLRequest *originalRequest =  [requestSerializer requestWithMethod:method
                                                                 URLString:url
                                                                parameters:[paraDic count] == 0 ? nil : paraDic
                                                                     error:nil];

    // HTTPDNS处理
    NSURLRequest *ipRequest = [self transfromHTTPDNSRequest:originalRequest];
    
    // SessionManager
    [[YESessionTool shareInstance] getSessionManagerWithRequest:ipRequest callBack:^(YESessionManager * _Nonnull sessionManager) {
        [sessionManager dataTaskWithRequest:ipRequest uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
            //不处理
        } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            //不处理
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (callBack) {
                if (error) {
                        NSDictionary *errorDic = [NSDictionary dictionaryWithObject:error.description forKey:@"message"];
                        callBack(@{}, errorDic);
                    
                } else {
                    // 数据解析
                    NSDictionary *responseDict = [responseObject objectFromJSONData];
                    
                    if (responseDict != nil && [responseDict isKindOfClass:[NSDictionary class]]) {
                        callBack(responseDict, @{});
                    } else {
                        NSDictionary *errorDic = [NSDictionary dictionaryWithObject:@"数据解析错误" forKey:@"message"];
                        callBack(@{}, errorDic);
                    }
                }
            }
        }];
    }];
    
}
```

### 容错处理&埋点

使用 IP 请求出现问题时，我们需要降级处理，使用备用 ip 或者域名再次尝试请求，除此之外，再请求结束后最好上传成功或失败的日志，便于服务器分析 IP 的可用性，我们改造下上面的请求响应部分：

```objective-c
// SessionManager
    [[YESessionTool shareInstance] getSessionManagerWithRequest:ipRequest callBack:^(YESessionManager * _Nonnull sessionManager) {
        [sessionManager dataTaskWithRequest:ipRequest uploadProgress:^(NSProgress * _Nonnull uploadProgress) {
            //不处理
        } downloadProgress:^(NSProgress * _Nonnull downloadProgress) {
            //不处理
        } completionHandler:^(NSURLResponse * _Nonnull response, id  _Nullable responseObject, NSError * _Nullable error) {
            if (callBack) {
                if (error) {
                    
                    //TODO: 失败埋点上传
                    // 降级请求
                    if ([self canDegradeForRequest:ipRequest.URL error:error]) {
                        // 移除该IP
                        [self removeIpInCacheWithDomain:originalRequest.URL.host ip:ipRequest.URL.host];
                        // 重新发起
                        [self requestWithUrl:url body:paraDic method:method timeOut:timeoutInterval headers:headersDic callBack:callBack];
                    } else {
                        NSDictionary *errorDic = [NSDictionary dictionaryWithObject:error.description forKey:@"message"];
                        callBack(@{}, errorDic);
                    }
                    
                } else {
                    //TODO: 成功埋点上传
                    // 保存Cookie
                    if (![self isIPAddressString:originalRequest.URL.host] && ![originalRequest.URL.host isEqualToString:ipRequest.URL.host]) {
                        NSDictionary *responseHeaderDict = ((NSHTTPURLResponse *)response).allHeaderFields;
                        [self storageHeaderFields:responseHeaderDict forURL:ipRequest.URL];
                    }
                    // 数据解析
                    NSDictionary *responseDict = [responseObject objectFromJSONData];
                    
                    if (responseDict != nil && [responseDict isKindOfClass:[NSDictionary class]]) {
                        callBack(responseDict, @{});
                    } else {
                        NSDictionary *errorDic = [NSDictionary dictionaryWithObject:@"数据解析错误" forKey:@"message"];
                        callBack(@{}, errorDic);
                    }
                }
               

            }
        }];
    }];
```



### 解决安全证书校验问题

证书校验分为 IP 请求和域名请求，对于普通的域名请求，我们只需要设置 SessionManager 安全策略即可。

```objective-c
// 域名请求的证书校验设置
- (void)setDomainNetPolicy: (YESessionManager *)manager request:(NSURLRequest *)request {
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    securityPolicy.validatesDomainName = YES;
    securityPolicy.allowInvalidCertificates = YES;
    // 从本地获取cer证书，仅作参考
    NSString * cerPath = [[NSBundle mainBundle] pathForResource:CerFile ofType:@"cer"];
    NSData * cerData = [NSData dataWithContentsOfFile:cerPath];
    securityPolicy.pinnedCertificates = [NSSet setWithObject:cerData];
    manager.securityPolicy = securityPolicy;
    
}
```

IP 请求部分稍微复杂点，我们在收到服务器安全认证请求时，再用**真实域名**和本地证书去进行校验，AFNetworking 提供了 `setSessionDidReceiveAuthenticationChallengeBlock` 和 `setTaskDidReceiveAuthenticationChallengeBlock` 方法可以让我们设置认证请求时的回调。

```objective-c
// IP请求的证书校验设置
- (void)setIPNetPolicy: (YESessionManager *)manager request:(NSURLRequest *)request {
    // 判断是否存在域名
    NSString *realDomain = [request.allHTTPHeaderFields objectForKey:@"host"];
    if (realDomain == nil || realDomain.length == 0) {
        //无域名不验证
        return;
    }
    // 通过客户端验证服务器信任凭证
    [manager setSessionDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
        return [self handleReceiveAuthenticationChallenge:challenge credential:credential host:realDomain];
    }];
    [manager setTaskDidReceiveAuthenticationChallengeBlock:^NSURLSessionAuthChallengeDisposition(NSURLSession * _Nonnull session, NSURLSessionTask * _Nonnull task, NSURLAuthenticationChallenge * _Nonnull challenge, NSURLCredential *__autoreleasing  _Nullable * _Nullable credential) {
        return [self handleReceiveAuthenticationChallenge:challenge credential:credential host:realDomain];
    }];
}


// 处理认证请求发生的回调
- (NSURLSessionAuthChallengeDisposition)handleReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
                                                       credential:(NSURLCredential**)credential
                                                             host:(NSString*)host
{
    NSURLSessionAuthChallengeDisposition disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        //验证域名是否被信任
        if ([self evaluateServerTrust:challenge.protectionSpace.serverTrust forDomain:host])
        {
            *credential = [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
            if (*credential)
            {
                disposition = NSURLSessionAuthChallengeUseCredential;
            }
            else
            {
                disposition = NSURLSessionAuthChallengePerformDefaultHandling;
            }
        }
        else
        {
            disposition = NSURLSessionAuthChallengeCancelAuthenticationChallenge;
        }
    }
    else
    {
        disposition = NSURLSessionAuthChallengePerformDefaultHandling;
    }
    return disposition;
}

//验证域名
- (BOOL)evaluateServerTrust:(SecTrustRef)serverTrust forDomain:(NSString *)domain
{
    
    AFSecurityPolicy *securityPolicy = [AFSecurityPolicy policyWithPinningMode:AFSSLPinningModeCertificate];
    securityPolicy.validatesDomainName = YES;
    securityPolicy.allowInvalidCertificates = YES;
    // 从本地获取cer证书,仅作参考
    NSString * cerPath = [[NSBundle mainBundle] pathForResource:CerFile ofType:@"cer"];
    NSData * cerData = [NSData dataWithContentsOfFile:cerPath];
    securityPolicy.pinnedCertificates = [NSSet setWithObject:cerData];
    
    return [securityPolicy evaluateServerTrust:serverTrust forDomain:domain];
}
```



### 总流程图

![图片来源于网络](./images/03.jpg)



## 总结

本文简单介绍了 HttpDNS 和域名解析带来的问题，代码部分已放在 [IOSDevelopTools-Network](https://github.com/SimonYHB/iOS-Develop-Tools/tree/master/IOSDevelopTools/IOSDevelopTools/Network)，仅作参考，还需根据实际项目来接入功能。

目前实现跟网络请求耦合在一起，还不算是完美的解决方案，后续有时间再补充 **HTTPDNS模块的解耦** 和 **WKWebview及AVplayer的处理**，敬请期待吧 😂。



### About Me  

- [掘金](https://juejin.im/user/58229b8ea0bb9f0058cd2738/posts)

- [Github](https://github.com/SimonYHB)

  

### 参考链接

- [【鹅厂网事】全局精确流量调度新思路-HttpDNS服务详解](https://mp.weixin.qq.com/s?__biz=MzA3ODgyNzcwMw==&mid=201837080&idx=1&sn=b2a152b84df1c7dbd294ea66037cf262&scene=2&from=timeline&isappinstalled=0&utm_source=tuicool)
- [可能是最全的iOS端HttpDns集成方案 | 掘金技术征文 - 掘金](https://juejin.im/post/58feef7261ff4b0066776d73#heading-14)
- [App域名劫持之DNS高可用 - 开源版HttpDNS方案详解](https://mp.weixin.qq.com/s?__biz=MzAwMDU1MTE1OQ==&mid=209805123&idx=1&sn=ced8d67c3e2cc3ca38ef722949fa21f8&3rd=MzA3MDU4NTYzMw==&scene=6#rd&utm_source=tuicool&utm_medium=referral)
- [全面理解DNS及HTTPDNS - 掘金](https://juejin.im/post/5dc14f096fb9a04a6b204c6f)
- [解决「HTTPDNS + HTTPS」的证书校验问题 - https- - ItBoth](http://www.itboth.com/d/INbqqy/https)
- [CDN是什么？与DNS有什么关系？及其原理_运维_hetoto的博客-CSDN博客](https://blog.csdn.net/hetoto/article/details/90509328)
- [APP网络优化之DNS优化实践 - 掘金](https://juejin.im/post/5e0d580b5188253a5c7d12fc)

