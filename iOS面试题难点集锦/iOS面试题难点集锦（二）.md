## iOS面试题难点集锦（二）---参考答案

引言：通过上篇文章[iOS面试题难点集锦（一）](https://github.com/LiuFuBo/iOSInterviewQuestions/blob/master/iOS面试题难点集锦/iOS面试题难点集锦（一）.md)，我们讲解了一些关于Runtime的知识，由于篇幅过长问题，其他一些内容咱们会放到后续一些章节来讲解。

# 索引

1. [main函数之前程序做了些什么？](#main函数之前程序做了些什么)  
2. [NSArray 和 NSMutableArray使用Copy和MutableCopy有何不同?](#nsarray-和-nsmutablearray使用copy和mutablecopy有何不同)  
3. [initialize 和 init 以及 load 调用时机?](#initialize-和-init-以及-load-调用时机)  
4. [GCD 全称是啥?什么时候使用 GCD?](gcd-全称是啥-什么时候使用-gcd)  
5. [NSURLSession 和 NSURLConnection 区别?](#nsurlsession-和-nsurlconnection-区别)  
6. [引用计数设计原理](#引用计数设计原理)  
7. [Hash表扩容问题](#hash表扩容问题)  
8. [深入了解+load方法的执行顺序](#深入了解+load方法的执行顺序)  
9. [load 和 initialize 方法的区别](#load-和-initialize-方法的区别)  
10. [RunLoop 的 CFRunLoopModeRef 结构体有啥内容? ](#runLoop-的-cfrunloopmoderef-结构体有啥内容)  
11. [Category为现有的类提供拓展性，为何它可以提供拓展性?](#category为现有的类提供拓展性-为何它可以提供拓展性)  
12. [NSObject对象苹果增加了一些内容，为何不会覆盖咱们自定义的属性?](#NSObject对象苹果增加了一些内容-为何不会覆盖咱们自定义的属性)  
13. [load方法里如果有大量对象的创建的操作是，是否需要自动释放池?](#load方法里如果有大量对象的创建的操作-是否需要自动释放池)  
14. [AppDelegate 各个常用代理方法都是何时调用的?](#AppDelegate-各个常用代理方法都是何时调用的)  
15. [UIViewController 生命周期方法调用顺序?](#UIViewController-生命周期方法调用顺序)   
16. [浅谈iOS中weak的底层实现原理](#浅谈iOS中weak的底层实现原理)
17. [多线程死锁原因？](#多线程死锁原因)
18. [单核处理器和多核处理器的区别?](#单核处理器和多核处理器的区别)
19. [KVO实现原理?如何自己实现KVO？](#KVO实现原理-如何自己实现KVO)
20. [通知实现原理？如何自定义通知？](#通知实现原理-如何自定义通知)
21. [一个只读的属性 为什么不能实现KVO](#一个只读的属性-为什么不能实现KVO)
22. [UIWebView和WKWebView的区别?](#UIWebView和WKWebView的区别?)
23. [一张图片渲染到屏幕上经过了什么过程?](#一张图片渲染到屏幕上经过了什么过程)
24. [离屏渲染是什么?什么场景会触发离屏渲染?都有什么具体的优化?](#离屏渲染是什么-什么场景会触发离屏渲染-都有什么具体的优化)
25. [LRU算法原理？以及如何优化？](#LRU算法原理以及如何优化)
26. [NSMutableArray是线程安全的么？如何创建线程安全的NSMutableArray?](#NSMutableArray是线程安全的么-如何创建线程安全的NSMutableArray)
27. [UITableView性能优化汇总](#UITableView性能优化汇总)
28. [有两个视图A/B,A有一部分内容覆盖在B上面，如果点击A让B视图响应？](#有两个视图A/B-A有一部分内容覆盖在B上面-如果点击A让B视图响应)
29. [折半查找为何不能用于存储结构是链式的有序查找表?](#折半查找为何不能用于存储结构是链式的有序查找表)
30. [同步、异步与串行、并行的关系?](#同步-异步与串行-并行的关系)
31. [类目为何不能添加属性？](#类目为何不能添加属性)
32. [字典，一般是用字符串来当做Key的，可以用对象来做key么？要怎么做?](#字典一般是用字符串来当做Key的-可以用对象来做key么-要怎么做)
33. [苹果公司为什么要设计元类？](#苹果公司为什么要设计元类)
34. [结构体和联合区的区别？](#结构体和联合区的区别)



### main函数之前程序做了些什么？

我们很少关注应用在启动前，系统会为我们做哪些事情，首先系统会先读取App 的可执行文件(Mach-O 文件)，从里面获得 `dyld`（动态链接库） 的路径，然后加载 `dyld`（动态链接库）并进行以下流程加载：

1、设置运行环境  
2、加载共享缓存  
3、实例化主程序  
4、加载插入的动态库  
5、链接主程序  
6、链接插入的动态库  
7、执行弱符号绑定  
8、执行初始化方法  
9、查找入口点并返回  


#### 1.设置运行环境

这一步主要是设置运行参数、环境变量等。代码在开始的时候，将入参 `mainExecutableMH` 赋值给了 `sMainExecutableMachHeader`，这是一个 `macho_header` 结构体，表示的是当前主程 序的 `Mach-O` 头部信息，加载器依据 `Mach-O` 头部信息就可以解析整个 `Mach-O` 文件信息。 接着调用 `setContext()`设置上下文信息，包括一些回调函数、参数、标志信息等。

#### 2.加载共享缓存

这一步先调用 `checkSharedRegionDisable()` 检查共享缓存是否禁用。推断 iOS 必须开启共享缓 存才能正常工作仅加载到当前进程，调用 `mapCachePrivate()`。共享缓存已加载，不做任何处理。当前进程首次加载共享缓存，调用 `mapCacheSystemWide()`。


#### 3.实例化主程序

这一步将主程序的 Mach-O 加载进内存，并实例化一个 `ImageLoader`。


#### 4.加载插入的动态库


这一步是加载环境变量 `DYLD_INSERT_LIBRARIES` 中配置的动态库，先判断环境变量 `DYLD_INSERT_LIBRARIES` 中是否存在要加载的动态库，如果存在则调用 `loadInsertedDylib()` 依次加载,会先在共享缓存中搜寻,打开文件并读取数据到内存后，最后调用 `checkandAddImage()` 验证镜像并将其加入到全局镜像列表中。


#### 5.链接主程序

这一步调用 `link()` 函数将实例化后的主程序进行动态修正，让二进制变为可正常执行的状态。递归调用刷新层级。


#### 6.链接插入的动态库

这一步与链接主程序一样，将前面调用 `addImage()` 函数保存在 `sAllImages` 中的动态库列表循 环取出并调用 `link()` 进行链接，需要注意的是，`sAllImages` 中保存的第一项是主程序的镜像， 所以要从 `i+1` 的位置开始，取到的才是动态库的 `ImageLoader`。

#### 7.执行弱符号绑定

`weakBind()`首先通过 `getCoalescedImages()`合并所有动态库的弱符号到一个列表里，然后调用 `initializeCoalIterator()`对需要绑定的弱符号进行排序，接着调用 `incrementCoalIterator()`读取 `dyld_info_command` 结构的 `weak_bind_off` 和 `weak_bind_size` 字段，确定弱符号的数据偏移 与大小，最终进行弱符号绑定。


#### 8.执行初始化方法

这一步由 `initializeMainExecutable()` 完成。`dyld` 会优先初始化动态库，然后初始化主程序。该函数首先执行 `runInitializers()` ， 内部再依次调用 `processInitializers()` 、 `recursiveInitialization()` runtime在这个时间被初始化，runtime初始化后不会闲着，在`_objc_init` 中注册了几个通知，从 `dyld` 这里接手了几个活，其中包括负责初始化相应依赖库里的类结构，调用依赖库里所有的 `laod` 方法。这里注册的 `init` 回调函数就是 `load_images()`，回调里 面调用了 call_load_methods()来执行所有的+ load 方法。但由于 lazy bind 机制，依赖库多数 都是在使用时才进行 `bind`，所以这些依赖库的类结构初始化都是发生在程序里第一次使用 到该依赖库时才进行的。


#### 9.查找入口点并返回

这一步调用主程序镜像的 `getThreadPC()`，从加载命令读取 `LC_MAIN` 入口，如果没有 `LC_MAIN` 就调用 `getMain()`读取 `LC_UNIXTHREAD`，找到后就跳到入口点指定的地址并返回。 至此，整个 `dyld` 的加载过程就分析完成了。\




### NSArray 和 NSMutableArray使用Copy和MutableCopy有何不同?

#### 1.深拷贝和浅拷贝区别

NSArray Copy出来的是浅拷贝，MutableCopy出来的是深拷贝。  
NSMutableArray 使用Copy 和 MutableCopy 都是深拷贝。  


#### 2.拷贝出来的对象是可变数组还是非可变数组

NSArray         `Copy`拷贝出来的是一个不可变数组，   `MutableCopy`拷贝出来的是一个可变数组。  
NSMutableArray  `Copy`拷贝出来的是一个不可变数组，   `MutableCopy`拷贝出来的是一个可变数组。  


### initialize 和 init 以及 load 调用时机?

`Initialize` 是在这个类第一次被调用的时候调用,比如`[[class alloc]init]`,之后不管创建多少次这个类，都不会再调用这个方法，它被用来初始化静态变量，`init`是只要调用这个类就会触发 `init` 方法，`load` 方法是在 `main` 函数之前调用。  


### GCD 全称是啥 什么时候使用 GCD?

GCD 全称 `Grand Central Dispatch` 优秀的中央调度器  

GCD 优势:  
1.GCD 是苹果为多核的并行运算提出的解决方案。    
2.GCD 会自动利用更多的 CPU 内核。    
3.GCD 可以自动管理线程生命周期。 

GCD 使用场景:  
GCD 定时器、切换线程、耗时操作、多个异步操作完成后再更新UI。  

1、dispatch_barrier_sync 需要等待自己的任务(barrier)结束之后，才会继续添加并执行写 在 barrier 后面的任务(4、5、6)，然后执行后面的任务。    
2、dispatch_barrier_async 将自己的任务(barrier)插入到 queue 之后，不会等待自己的任务 结束，它会继续把后面的任务(4、5、6)插入到 queue，然后执行任务。  

### NSURLSession 和 NSURLConnection 区别?  

1.使用现状 

NSURLSession 是 NSURLConnection 的替代者。  

2.普通任务和上传  

NSURLSession 针对下载/上传等复杂的网络操作提供了专门的解决方案，针对普通、上传和 下载分别对应三种不同的网络请求任务:NSURLSessionDataTask, NSURLSessionUploadTask 和 NSURLSessionDownloadTask.。创建的 task 都是挂起状态，需要 resume 才能执行。当服务器 返回的数据较小时，NSURLSession 与 NSURLConnection 执行普通任务的操作步骤没有区别。 执行上传任务时，NSURLSession 与 NSURLConnection 一样同样需要设置 POST 请求的请求体 进行上传。

3.下载任务  

NSURLConnection 下载文件时，先将整个文件下载到内存，然后再写入沙盒，如果文件比较 大，就会出现内存暴涨的情况。而使用 NSURLSessionDownloadTask 下载文件，会默认下载到沙 盒中的 tem 文件夹中，不会出现内存暴涨的情况，但在下载完成后会将 tem 中的临时文件 删除，需要在初始化任务方法时，在 completionHandler 回调中增加保存文件的代码。  

4.配置信息

NSURLSession 的构造方法(sessionWithConfiguration:delegate:delegateQueue)中有一个 NSURLSessionConfiguration 类的参数可以设置配置信息，其决定了 cookie，安全和高速缓存 策略，最大主机连接数，资源管理，网络超时等配置。NSURLConnection 不能进行这个配置， 相比于 NSURLConnection 依赖于一个全局的配置对象，缺乏灵活性而言，NSURLSession 有 很大的改进了。  


### 引用计数设计原理

引用计数设计不仅我们的系统是否支持`Tagged Pointer`有关系，而且还跟系统`isa`指针是否优化过有关系，具体的实现原理可参考这篇文章[Objective-C 引用计数原理](https://www.jianshu.com/p/12d6e64c07bb)。


### hash表扩容问题



哈希表是一个散列表，里面存储的是键值对(key-value)映射。它是一种根据关键码 key 来寻找值 value 的数据映射结构。  


`装载因子`，也叫负载因子(load factor)，它表示散列表的装满程度。当当前表的实际装载因 子达到默认的负载因子值(负载极限)时，就会触发哈希表的扩容。  


一般情况下，默认的负载因子值不能太大，因为其虽然减少了空间开销，但是增加了查询的 时间成本;也不能太小，因为这样还会增加 `rehash` 的次数，性能较低。


`Hashcode` 
哈希码是一种算法，尽量为不同的对象生成不同的哈希码。(但不代表不同对象的哈希码一 定不同。)它可以作为相同对象判断的依据。同一对象如果没有经过修改，前后不同时刻生 成的哈希码应该是一致的。

不过我们知道，判断是否相同已经有了 `equals()` 方法，那为什么还需要 `Hashcode()`方法呢? 这是因为 `equals()`方法的效率远不如 `Hashcode()`方法。

同样的问题，既然 `Hashcode()`性能那么高，那为什么还需要 `equals()`方法呢? 这是因为 `equals()`方法是完全可靠的，而仅仅基于哈希码比较是不完全可靠的。 如果两个对象相同，`Hashcode()` 一定相同。

但是 `Hashcode()` 相同的两个对象不一定相同。 而如果两个对象相同，`equals()`方法得到的一定为 `true`。所以说 `Java` 中的 `HashMap` 既提供对 `equals()`的重写，也提供对 `Hashcode()`的重写。 于是，对于这种有着大量且快速的对象对比需求的 `hash` 容器，我们将两种方法结合起来用。 先使用 `Hashcode()`方法，如果两个对象产生的哈希码不相同，那么这两个对象一定不同，不 再进行后续比较; 而如果两个对象产生的哈希码相同，那么这两个对象有可能相同，于是再使用 equals()方法 进行比较。  


哈希冲突  
哈希冲突是指，不同的 key 经由哈希函数，映射到了相同的位置上，造成的冲突。哈希冲突是不可避免的，但是如果冲突较严重就会影响哈希表的性能。


我们一般采用四种方式来解决哈希冲突:开放定址法、链地址法、再哈希法、建立公共溢出区。

这里列举几种解决哈希冲突的几种办法(举例推演)。

开放定址法: 

这种方法的意思是当关键字 Key 的哈希地址 p=H(key)出现冲突是，以 p 为基础， 产生另一个哈希地址 `p1`,如果 `p1` 仍然冲突，产生另外一个哈希地址 P2,直到找出不冲突的哈 希地址 Pi,将相应元素存入其中。  

线性探测再散列

当发生冲突的时候，顺序的查看下一个单元

二次(平方)探测再散列

当发生冲突的时候，在表的左右进行跳跃式探测 (+1^2 如果有冲突就-1^2 如果发生冲 突,+2^2 进行验证)

伪随机探测再散列

建立一个伪随机数发生器，并给一个随机数作为起点，再hash法 这种方式是同时构造多个哈希函数，当产生冲突时，计算另一个哈希函数的值。 这种方法不易产生聚集，但增加了计算时间。    

双哈希函数探测法    

Hi = （Hash(key) + i·ReHash(key)）mod m (i=1,2,...,m-1)    
其中，Hash(key),ReHash(key)是两个哈希函数，m为哈希函表的长度。    
双哈希函数探测法先用第一个函数Hash(key)对关键字计算哈希地址，一旦产生地址冲突，再用第二个函数ReHash(key)  确定移动步长因子，最后，通过步长因子序列由探测函数寻找空的哈希地址。    
例如:    
 Hash(key) = a 产生地址冲突，就计算ReHash(key) = b,则探测的地址序列为 H1 = （a+b）mod m, H2 = (a+2b) mod m,..., Hm-1 = (a + (m-1)b) mod m。  


链地址法  

将所有哈希地址相同的都链接在同一个链表中 ，因而查找、插入和删除主要在同义词链中 进行。链地址法适用于经常进行插入和删除的情况。HashMap 就是用此方法解决冲突的。 此种方法必须要求采用链表来实现hash表。具体实现方法为将所有关键字为同义词的记录存储在一个单链表中以后，采用一维数组存放头指针。链地址法每个单元不是存储对应元素，而是存储响应单链表的表头指针，单链表中的每个节点动态分配产生。  

建立一个公共溢出区   

设哈希函数产生的哈希地址集为[0,...,m-1],则分配两个表：  
一个是基本表ElemType base_tb[m],其每个单元只能存放一个元素。另一个是溢出表ElemType over_tb[k],只要关键字对应的哈希地址在基本表上产生冲突，则所有这样的元素一律存入该表中。查找时，对给定值kx通过哈希函数计算出哈希地址I,先与基本表的base_tb[i]单元比较，若相等，查找成功；否则，再到溢出表中进行查找。


采取分摊转移的方式
即当插入一个新元素 x 触发了扩容时，先转移第一个不为空的桶 到新的哈希表，然后将该元素插入。而下一次再次插入时，继续转移旧哈希表中第一个不为 空的桶，再插入元素。直至旧哈希表为空为止。这样一来，理想情况下，插入的时间复杂度 是 O(1)。在 Redis 的实现中，新插入的键值对会放在箱子中链表的头部，而不是在尾部继续插入。

这种方案是基于两点考虑:

一是由于找到链表尾部的时间复杂度为 O(n)，且需要额外的内存地址来保存链表的尾部位置， 而头插法的时间复杂度为 O(1)。
二是处于 Redis 的实际应用场景来考虑。对于一个数据库系统来说，最新插入的数据往往更 可能频繁地被获取，所以这样也能节省查找的耗时。


### 深入了解+load方法的执行顺序


1、`+load` 方法是在 `dyld` 阶段的执行初始化方法步骤中执行的，其调用为 `load_images->call_load_methods`。    
2、一个类在代码中不主动调用+load 方法的情况下，其类、子类实现的`+load` 方法都会分别执行一次。  
3、父类的 `+load` 方法执行在前，子类的 `+load` 方法在后。  
4、在同一镜像中，所有类的+load 方法执行在前，所有分类的 `+load` 方法执行在后。  
5、同一镜像中，没有关系的两个类的执行顺序与编译顺序有关(Compile Sources 中的顺序)。  
6、同一镜像中所有的分类的+load方法的执行顺序与编译顺序有关(Compile Sources中的顺 序)，与是谁的分类，同一个类有几个分类无关。  
7、同一镜像中主工程的 `+load` 方法执行在前，静态库的 `+load` 方法执行在后。有多个静态库时， 静态库之间的执行顺序与编译顺序有关(Link Binary With Libraries 中的顺序)。  
8、不同镜像中，动态库的 `+load` 方法执行在前，主工程的 `+load` 执行在后，多个动态库的 `+load` 方法的执行顺序编译顺序有关(Link Binary With Libraries 中的顺序)。  

### load 和 initialize 方法的区别


`load` 方法采用的是 `IMP` 指针地址直接调用，`initialize` 采用的是消息转发机制。  

`load` 是只要类所在文件被引用就会被调用，而 `initialize` 是在类或者其子类的第一个方法被调用前调用。所以如果类没有被引用进项目，就不会有`load`调用;但即使类文件被引用进来， 但是没有使用，那么 `initialize` 也不会被调用。  

关于load方法特点  

1、只要程序启动就会将所有类的代码加载到内存中(在 `main` 函数执行之前), 放到代码区 (无论该类有没有被使用到都会被调用)。  
2、`+load` 方法会在当前类被加载到内存的时候调用, 有且仅会调用一次。    
3、当父类和子类都实现+load 方法时, 会先调用父类的 `+load` 方法, 再调用子类的 `+load`方法。  
4、先加载原始类，再加载分类的 `+load` 方法。  
5、当子类未实现 `+load` 方法时，不会调用多一次父类的 `+load` 方法(因为 `load` 采用 `IM`P 指针直接调用的)。  
6、多个类都实现 `+load` 方法，`+load` 方法的调用顺序，与 Compile Sources 中出现的顺序一致。 

关于initialize特点   

1、当类第一次被使用的时候就会调用(创建类对象的时候)。  
2、`initialize` 方法在整个程序的运行过程中只会被调用一次, 无论你使用多少次这个类都只会调用一次。  
3、`initialize` 用于对某一个类进行一次性的初始化。  
4、先调用父类的 `initialize` 再调用子类的 `initialize`。  
5、当子类未实现 `initialize` 方法时，会把父类的实现继承过来调用一遍，再次之前父类的 `initialize` 方法会被优先调用一次。  
6、当有多个 `Category` 都实现了 `initialize` 方法，会覆盖类中的方法，只执行一个(会执行 Compile Sources 列表中最后一个 `Category` 的 `initialize` 方法)。 


### RunLoop 的 CFRunLoopModeRef 结构体有啥内容? 


主要包含了两个Source 既`source0` 和 `source1`

```
CFMutableSetRef _sources0; CFMutableSetRef _sources1;
一个观察者 observers
CFMutableArrayRef _observers; 一个 timers
CFMutableArrayRef _timers; 一个 portSet
__CFPortSet _portSet;
```
其实 `NSRunLoop` 的本质是一个消息机制的处理模式，`runloop` 的运行，其实就是不停的通过 `observer` 监听各种事件，包含各种 `source` 事件，`timer`，`port` 等等，如果有这些事件，那就 处理，没有事件，就会进入休眠，不停的重复上述过程。`RunLoop` 是一种观察者模式 `AutoreleasePool` 与 `RunLoop` 并没有直接的关系，之所以将两个话题放到一起讨论最主要的原 因是因为在 iOS 应用启动后会注册两个 `Observer` 管理和维护 `AutoreleasePool` 第一个 `Observer` 会监听 `RunLoop` 的进入，它会回调 `objc_autoreleasePoolPush()`向当前的 `AutoreleasePoolPage` 增加一个哨兵对象标志创建自动释放池。这个` Observer `的 `order` 是 `-2147483647` 优先级最高， 确保发生在所有回调操作之前。  

第二个 `Observer` 会监听 `RunLoop` 的进入休眠和即将退出 `RunLoop` 两种状态，在即将进入休 眠时会调用 `objc_autoreleasePoolPop()` 和 `objc_autoreleasePoolPush()` 根据情况从最新加入的 对象一直往前清理直到遇到哨兵对象。而在即将退出 `RunLoop` 时会调用 `objc_autoreleasePoolPop()` 释放自动自动释放池内对象。这个 `Observer` 的 `order` 是 `2147483647`， 优先级最低，确保发生在所有回调操作之后。  


### Category为现有的类提供拓展性 为何它可以提供拓展性?


在App启动加载镜像文件时，会在`_read_images` 函数中调用 `remethodizeClass` 函数，然后再调用 `attachCategories` 函数，完成向类中添加 `Category` 的工作。原理就是向 `class_rw_t` 中的 `method_array_t`,`property_array_t`,`protocol_array_t` 数组中分别添加 `method_list_t`,`property_list_t`,`protocol_list_t` 指针。`xxx_array_t` 可以存储对应的 `xxx_list_t` 的指针数组。

在调用 `attachCategories` 函数之前，会先调用 `unttachedCategoriesForClass` 函数获取类中还未添加的类别列表。这个列表类型为 `locstamped_category_list_t`,它封装了 `category_t` 以及对应的 `header_info`。`header_info` 存储了实体在镜像中的加载和初始化状态，以及一些偏移量， 在加载 `Mach-O` 文件相关函数中经常用到。

```
struct locstamped_category_t { category_t *cat;
struct header_info *hi; };
struct locstamped_category_list_t { uint32_t count;
#if __LP64__
uint32_t reserved;
#endif
locstamped_category_t list[0];
};
```
所以更具体来说 `attachCategories` 做的就是将 `locstamped_category_list_t.list` 列表中每个 `Locstamped_category_t.cat` 中那方法、协议和属性分别添加到类的 `class_rw_t` 对应列表中。 `header_info` 中的信息决定了是否是元类，从而选择应该是添加实例方法还是类方法、实例 属性还是类属性等。
其实编译器会根据情况在 `objc_msgSend`,`objc_msgSend_stret`,`objc_msgSendSuper`,或 `objc_msgSendSuper_stret` 四个方法中选择一个来调用。如果消息是传递给超类，那么会调用 名字带有 `super` 的函数，如果是在 `i386` 平台处理返回类型为浮点数的消息事，需要用到 `objc_msgSend_fpret` 函数处理 `fpret` 就是`fp"+"ret` 分别代表`floating-point`和`return`。


### NSObject对象苹果增加了一些内容 为何不会覆盖咱们自定义的属性?


`objc_class` 包含了 `class_data_bits_t`，`class_data_bits_t` 存储了 `class_rw_t` 的指针，而 `class_rw_t` 结构体又包含 `class_ro_t` 的指针。

```
struct class_ro_t { 
uint32_t flags;
uint32_t instanceStart;
uint32_t instanceSize; #ifdef __LP64__
uint32_t reserved; #endif
const uint8_t * ivarLayout;
const char * name; 
method_list_t * baseMethodList; 
protocol_list_t * baseProtocols; 
const ivar_list_t * ivars;
const uint8_t * weakIvarLayout; 
property_list_t *baseProperties;
method_list_t *baseMethods() const { 
	return baseMethodList;
    } 
};
```

假如苹果在新版本的 SDK 中向 NSObject 类增加了一些内容，NSObject 的占据的内存区域 会扩大，开发者以前编译出的二进制中的子类就会与新的 NSObject 内存有重叠部分。于是在编译期会给 `instanceStart` 和 `instanceSize` 赋值，确定好编译时每个类的所占内存区域起 始偏移量和大小，这样只需将子类与基类的这两个变量作对比即可知道子类是否与基类有重叠，如果有，也可知道子类需要挪多少偏移量。  



### load方法里如果有大量对象的创建的操作 是否需要自动释放池?


`load`方法外部有一个 `runtime`。但是 他会调完 所有的`+load` 才会结束。。所以对于局部的峰值来说并不能优化。


### AppDelegate 各个常用代理方法都是何时调用的?


1. didFinishLaunchingWithOptions  
当应用程序正常启动时(不包括已在后台转到前台的情况)，调用此回调。launchOptions 是 启动参数，假如用户通过点击 push 通知启动的应用，(这是非正常启动的情况，包括本地通 知和远程通知)，这个参数里会存储一些 push 通知的信息。  

2.applicationWillResignActive   
当应用程序即将从活动状态移动到非活动状态时发送。对于某些类型的临时中断(例如来电 或 SMS 消息)，或者当用户退出应用程序并开始转换到后台状态时，可能会出现这种情况。 使用此方法暂停正在进行的任务，禁用计时器，并使图形呈现回调无效。游戏应该使用这种 方法暂停游戏。调用时机可能有以下几种:锁屏、单击 HOME 键、下拉状态栏、双击 HOME 弹出底部状态栏等情况

3.applicationDidBecomeActive
当应用程序全新启动，或者在后台转到前台，完全激活时，都会调用这个方法。它会重新启 动应用程序处于非活动状态时暂停(或尚未启动)的任何任务,如果应用程序是以前运行在后 台，这时可以选择刷新用户界面。

4.applicationDidEnterBackground
使用此方法释放共享资源、保存用户数据、使计时器失效，并存储足够的应用程序状态信息， 以便在以后终止应用程序时将其恢复到当前状态。如果你的应用程序支持后台执行，这个方 法会被调用，而不是 applicationWillTerminate:当用户退出时。

5.applicationWillEnterForeground 
被调用作为从后台到活动状态转换的一部分;在这里，您可以撤消在进入后台时所做的许多 更改。如果应用不在后台状态，而是直接启动，则不会回调此方法。  

6.applicationWillTerminate  
当应用退出，并且进程即将结束时会调到这个方法，一般很少主动调到，更多是内存不足时 是被迫调到的，我们应该在这个方法里做一些数据存储操作。  

7.application:openURL:  
从其他应用回到当前应用回调。  


### UIViewController 生命周期方法调用顺序?


1.init方法
这里包含了非 storyBoard 创建 UIViewController 调用 initWithNibName:bundle: 如果用 storyBoard 进行视图管理会调用 initWithCoder。  

2.loadView  
当执行到 loadView 方法时，如果视图控制器是通过 nib 创建，那么视图控制器已经从 nib 文 件中被解档并创建好了，接下来任务就是对 view 进行初始化。  

3.viewDidload  
当 loadView 将 view 载入内存中，会进一步调用 viewDidLoad 方法来进行进一步设置。此时， 视图层次已经放到内存中，通常，我们对于各种初始化数据的载入，初始设定、修改约束、 移除视图等很多操作都可以这个方法中实现。  

4.viewWillAppear  
系统在载入所有的数据后，将会在屏幕上显示视图，这时会先调用这个方法，通常我们会在 这个方法对即将显示的视图做进一步的设置。比如，设置设备不同方向时该如何显示;设置 状态栏方向、设置视图显示样式等。  

5.viewWillLayoutSubviews  
view 即将布局其 Subviews。 比如 view 的 bounds 改变了(例如:状态栏从不显示到显示,视图 方向变化)，要调整 Subviews 的位置，在调整之前要做的工作可以放在该方法中实现。  

6.viewDidAppear  
在 view 被添加到视图层级中以及多视图，上下级视图切换时调用这个方法，在这里可以对 正在显示的视图做进一步的设置。  

7.viewWillDisappear 
在视图切换时，当前视图在即将被移除、或被覆盖是，会调用该方法，此时还没有调用 removeFromSuperview。  

8.viewDidDisappear  
view 已经消失或被覆盖，此时已经调用 removeFromSuperView。  

9.dealloc
视图被销毁，此次需要对你在 init 和 viewDidLoad 中创建的对象进行释放。  

10.didReceiveMemoryWarning  
在内存足够的情况下，app的视图通常会一直保存在内存中，但是如果内存不够，一些没有 正在显示的 viewController 就会收到内存不足的警告，然后就会释放自己拥有的视图，以达到释放内存的目的。但是系统只会释放内存，并不会释放对象的所有权，所以通常我们需要 在这里将不需要显示在内存中保留的对象释放它的所有权，将其指针置 nil。  


### 浅谈iOS中weak的底层实现原理 

使用场景：在iOS开发中经常会用到"weak"关键词，具体的使用场景就是用于一些对象互相引用的时候，为了避免造成循环引用。weak 关键字的为弱引用，所以引用对象的引用计数不会+1，并且在引用对象被释放的时候，会自动将引用对象设置为nil。  

原理概括：苹果为了管理所有对象的计数器和weak指针，苹果创建了一个全局的哈希表，我们暂且叫它SideTables，里面装的是的名为SideTable的结构体。用对象的地址作为key，可以取出sideTable结构体，这个结构体用来管理引用计数和weak指针。

下面是SideTables结构体:

```
struct weak_table_t {
    weak_entry_t *weak_entries; // 保存了所有指向指定对象的weak指针数组
    size_t    num_entries;              // weak对象的存储空间
    uintptr_t mask;                      //参与判断引用计数辅助量
    uintptr_t max_hash_displacement;    //hash key 最大偏移值
};

```


 例如:__weak NSObject *objc = [[NSObject alloc] init]; 根据上面weak表的结构可以看出，这里通过objc这个对象的地址作为key，然后再全局weak哈希表中获取到objc该对象下面维护的所有弱引用的对象的指针数组。也就是weak_entry_t。  

 那么为何value这里是一个数组呢？因为objc对象可能引用了多个weak关键字的属性  


#### 具体步骤是怎么实现的呢？主要可以分为三步  

> 1. 创建一个weak对象时，runtime会调用一个objc_initWeak函数，初始化一个新的weak指针指向该对象的地址  
![image](http://brandonliu.pub/weak_init.png)

> 2.在objc_initWeak函数中会继续调用objc_storeWeak函数，在这个过程是用来更新weak指针的指向，同时创建对应的弱引用表

![image](http://brandonliu.pub/weak_store.png)

> 3.释放时，调用clearDeallocating函数。clearDeallocating函数首先根据对象地址获取所有weak指针地址的数组，然后遍历这个数组把其中的数据设为nil，最后把这个entry从weak表中删除，最后清理对象的记录。


拓展：weak和__unsafe_unretained以及unowned 与 assign区别是什么?  

>1.unsafe_unretained: 不会对对象进行retain,当对象销毁时,会依然指向之前的内存空间(野指针)。   

>2.weak: 不会对对象进行retain,当对象销毁时,会自动指向nil。    

>3.assign: 实质与__unsafe_unretained等同。    

>4.unsafe_unretained也可以修饰代表简单数据类型的property，weak也不能修饰用来代表简单数据类型的property。  

>5.unsafe_unretained 与 weak 比较，使用 weak是有代价的，因为通过上面的原理可知，weak需要检查对象是否已经消亡，而为了知道是否已经消亡，自然也需要一些信息去跟踪对象的使用情况。也正因此，unsafe_unretained 比weak快,所以当明确知道对象的生命期时，选择unsafe_unretained 会有一些性能提升，这种性能提升是很微小的。但当很清楚的情况下，unsafe_unretained 也是安全的，自然能快一点是一点。而当情况不确定的时候，应该优先选用weak。  

>6.unowned使用在Swift中，也会分 weak 和 unowned。unowned 的含义跟 unsafe_unretained 差不多。假如很明确的知道对象的生命期，也可以选择unowned。  


#### 多线程死锁原因?  


属于临界资源的硬件有打印机、磁带机等,软件有消息缓冲队列、变量、数组、缓冲区等。诸进程间应采取互斥方式，实现对这种资源的共享。    


当我们在使用两个不同的线程访问同一个临界资源时就会出现如下情况：    
![image](http://brandonliu.pub/icon_blog_jingzhengziyuan.png)    


线程A优先被创建出来并优先去获得对临界资源的操作权限，线程A里有一个循环代码会循环对该临界资源进行操作，因此就会操作系统内核在进程里的线程之间调度时会出现这样一种情况：线程A在对该临界资源操作时，线程B呼唤操作系统取的CPU控制权时，会有一个线程调用之间的现场保护，会对线程里的代码执行到了哪一步或者循环次数的记录保存到寄存器里，下次获取CPU控制权时会读取该记录，此时如果线程A没有结束的情况下会一直占用着该临界资源，导致线程B无法对该临界资源做写操作，从而进入无限的阻塞等待，从而导致了死锁的情况！  

如何避免死锁  

在有些情况下死锁是可以避免的。三种用于避免死锁的技术：  

> 1.加锁顺序（线程按照一定的顺序加锁）  
> 2.加锁时限（线程尝试获取锁的时候加上一定的时限，超过时限则放弃对该锁的请求，并释放自己占有的锁）  
> 2.死锁检测  

加锁顺序  

当多个线程需要相同的一些锁，但是按照不同的顺序加锁，死锁就很容易发生。  

如果能确保所有的线程都是按照相同的顺序获得锁，那么死锁就不会发生。看下面这个例子：  

```
Thread 1:
  lock A 
  lock B

Thread 2:
   wait for A
   lock C (when A locked)

Thread 3:
   wait for A
   wait for B
   wait for C

```

如果一个线程（比如线程3）需要一些锁，那么它必须按照确定的顺序获取锁。它只有获得了从顺序上排在前面的锁之后，才能获取后面的锁。

例如，线程2和线程3只有在获取了锁A之后才能尝试获取锁C(译者注：获取锁A是获取锁C的必要条件)。因为线程1已经拥有了锁A，所以线程2和3需要一直等到锁A被释放。然后在它们尝试对B或C加锁之前，必须成功地对A加了锁。

按照顺序加锁是一种有效的死锁预防机制。但是，这种方式需要你事先知道所有可能会用到的锁(译者注：并对这些锁做适当的排序)，但总有些时候是无法预知的。


加锁时限  

另外一个可以避免死锁的方法是在尝试获取锁的时候加一个超时时间，这也就意味着在尝试获取锁的过程中若超过了这个时限该线程则放弃对该锁请求。若一个线程没有在给定的时限内成功获得所有需要的锁，则会进行回退并释放所有已经获得的锁，然后等待一段随机的时间再重试。这段随机的等待时间让其它线程有机会尝试获取相同的这些锁，并且让该应用在没有获得锁的时候可以继续运行(译者注：加锁超时后可以先继续运行干点其它事情，再回头来重复之前加锁的逻辑)。  

以下是一个例子，展示了两个线程以不同的顺序尝试获取相同的两个锁，在发生超时后回退并重试的场景：  

```
Thread 1 locks A
Thread 2 locks B

Thread 1 attempts to lock B but is blocked
Thread 2 attempts to lock A but is blocked

Thread 1's lock attempt on B times out
Thread 1 backs up and releases A as well
Thread 1 waits randomly (e.g. 257 millis) before retrying.

Thread 2's lock attempt on A times out
Thread 2 backs up and releases B as well
Thread 2 waits randomly (e.g. 43 millis) before retrying.

```

在上面的例子中，线程2比线程1早200毫秒进行重试加锁，因此它可以先成功地获取到两个锁。这时，线程1尝试获取锁A并且处于等待状态。当线程2结束时，线程1也可以顺利的获得这两个锁（除非线程2或者其它线程在线程1成功获得两个锁之前又获得其中的一些锁。  

需要注意的是，由于存在锁的超时，所以我们不能认为这种场景就一定是出现了死锁。也可能是因为获得了锁的线程（导致其它线程超时）需要很长的时间去完成它的任务。  

此外，如果有非常多的线程同一时间去竞争同一批资源，就算有超时和回退机制，还是可能会导致这些线程重复地尝试但却始终得不到锁。如果只有两个线程，并且重试的超时时间设定为0到500毫秒之间，这种现象可能不会发生，但是如果是10个或20个线程情况就不同了。因为这些线程等待相等的重试时间的概率就高的多（或者非常接近以至于会出现问题）。  
(译者注：超时和重试机制是为了避免在同一时间出现的竞争，但是当线程很多时，其中两个或多个线程的超时时间一样或者接近的可能性就会很大，因此就算出现竞争而导致超时后，由于超时时间一样，它们又会同时开始重试，导致新一轮的竞争，带来了新的问题。)  

这种机制存在一个问题，在Java中不能对synchronized同步块设置超时时间。你需要创建一个自定义锁，或使用Java5中java.util.concurrent包下的工具。写一个自定义锁类不复杂，但超出了本文的内容。后续的Java并发系列会涵盖自定义锁的内容。  

死锁检测  

死锁检测是一个更好的死锁预防机制，它主要是针对那些不可能实现按序加锁并且锁超时也不可行的场景。  

每当一个线程获得了锁，会在线程和锁相关的数据结构中（map、graph等等）将其记下。除此之外，每当有线程请求锁，也需要记录在这个数据结构中。  

当一个线程请求锁失败时，这个线程可以遍历锁的关系图看看是否有死锁发生。例如，线程A请求锁7，但是锁7这个时候被线程B持有，这时线程A就可以检查一下线程B是否已经请求了线程A当前所持有的锁。如果线程B确实有这样的请求，那么就是发生了死锁（线程A拥有锁1，请求锁7；线程B拥有锁7，请求锁1）。  

当然，死锁一般要比两个线程互相持有对方的锁这种情况要复杂的多。线程A等待线程B，线程B等待线程C，线程C等待线程D，线程D又在等待线程A。线程A为了检测死锁，它需要递进地检测所有被B请求的锁。从线程B所请求的锁开始，线程A找到了线程C，然后又找到了线程D，发现线程D请求的锁被线程A自己持有着。这是它就知道发生了死锁。  


那么当检测出死锁时，这些线程该做些什么呢？  

一个可行的做法是释放所有锁，回退，并且等待一段随机的时间后重试。这个和简单的加锁超时类似，不一样的是只有死锁已经发生了才回退，而不会是因为加锁的请求超时了。虽然有回退和等待，但是如果有大量的线程竞争同一批锁，它们还是会重复地死锁（编者注：原因同超时类似，不能从根本上减轻竞争）。  

一个更好的方案是给这些线程设置优先级，让一个（或几个）线程回退，剩下的线程就像没发生死锁一样继续保持着它们需要的锁。如果赋予这些线程的优先级是固定不变的，同一批线程总是会拥有更高的优先级。为避免这个问题，可以在死锁发生的时候设置随机的优先级。  



#### 单核处理器和多核处理器的区别?

单核cpu并不是一个长久以来存在的概念，在近年来多核心处理器逐步普及之后，单核心的处理器为了与双核和四核对应而提出。多核是指一个CPU有多个核心处理器，处理器之间通过CPU内部总线进行通讯,而多CPU是指简单的多个CPU工作在同一个系统上，多个CPU之间的通讯是通过主板上的总线进行的。


#### KVO实现原理 如何自己实现KVO?

实现原理

KVO是通过isa-swizzling技术实现的(这句话是整个KVO实现的重点)。在运行时根据原类创建一个中间类，这个中间类是原类的子类，并动态修改当前对象的isa指向中间类。并且将class方法重写，返回原类的Class。所以苹果建议在开发中不应该依赖isa指针，而是通过class实例方法来获取对象类型。[具体实现，请参考demo](https://github.com/LiuFuBo/iOSInterviewQuestions/blob/master/demo)


自定义KVO

创建一个分类新增一个方法addObserver，在方法中创建子类注册并指向子类，再为子类添加set方法既可。

主要使用函数如下:  

 >1.创建一个子类    

```
 objc_allocateClassPair(Class _Nullable superclass, const char * _Nonnull name,
 size_t extraBytes)
 superclass:设置新类的父类
 name:新类名称
 extraBytes:额外字节数设置为0

```

>2.注册该类  

```
objc_registerClassPair(Class _Nonnull cls)
 cls:当前要注册的类，注册后才可以使用

```

>3.设置当前对象指向其他类

```
 object_setClass(id _Nullable obj, Class _Nonnull cls)
 obj:要设置的对象
 cls:指向的类
```

>4.动态添加一个方法

```
 class_addMethod(Class _Nullable cls, SEL _Nonnull name, IMP _Nonnull imp,
 const char * _Nullable types)
 cls:设置添加方法对应的类
 name:选择子（选择器）名称，描述了方法的格式，并不会指向方法
 imp:函数名称（函数指针），和选择子一一对应，指向方法实现的地址

```

>5.通过分类添加新的观察者添加方法

```
-(void)addObserver:(NSObject *)observer forKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context{
    
    //创建、注册子类
    NSString *oldClassName = NSStringFromClass([self  class]);
    NSString *newClassName = [NSString stringWithFormat:@"SKVONotifying_%@",oldClassName];
    
    Class clazz = objc_getClass(newClassName.UTF8String);
    if (!clazz) {
        clazz = objc_allocateClassPair([self class], newClassName.UTF8String, 0);
        objc_registerClassPair(clazz);
    }
    
    //set方法名
    if (keyPath.length <= 0)return;
    NSString *fChar = [[keyPath substringToIndex:1] uppercaseString];//第一个char
    NSString *rChar = [keyPath substringFromIndex:1];//第二到最后char
    NSString *setterChar = [NSString stringWithFormat:@"set%@%@:",fChar,rChar];
    SEL setSEL = NSSelectorFromString(setterChar);
    
    //添加set方法
    Method getMethod = class_getInstanceMethod([self class], setSEL);
    const char *types = method_getTypeEncoding(getMethod);
    class_addMethod(clazz, setSEL, (IMP)setterMethod, types);

    //改变isa指针，指向新建的子类
    object_setClass(self, clazz);
    

    //保存getter方法名，获取旧值的时候使用
    objc_setAssociatedObject(self, "getterKey", keyPath, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    //保存setter方法名,设置新值的时候使用
    objc_setAssociatedObject(self, "setterKey", setName, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    //通知值变化
    objc_setAssociatedObject(self, "observerKey", observer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    //传进来的内容需要回传
    objc_setAssociatedObject(self, "contextKey", (__bridge id _Nullable)(context), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
```

>6.设置属性值的新调用方法

```
void setterMethod(id self, SEL _cmd, id newValue){

    NSString *setterChar = objc_getAssociatedObject(self, "setterKey");
    NSString *getterChar = objc_getAssociatedObject(self, "getterKey");

     //保存子类类型
    Class clazz = [self class];
    
    //isa 指向原类
    object_setClass(self, class_getSuperclass(clazz));
    
    //调用原类get方法，获取oldValue
    id oldValue = objc_msgSend(self, NSSelectorFromString(getterChar));
    
    //调用原类set方法
    objc_msgSend(self, NSSelectorFromString(setterChar),newValue);
    
    NSMutableDictionary *change = [[NSMutableDictionary alloc]init];
    if (newValue) {
        change[NSKeyValueChangeNewKey] = newValue;
    }
    if (oldValue) {
        change[NSKeyValueChangeOldKey] = oldValue;
    }

    //原类观察者
    NSObject *observer = objc_getAssociatedObject(self, "observerKey");
    
    //原类存储的上下文
    id context = objc_getAssociatedObject(self, "contextKey");

    //调用observer的回调方法
    objc_msgSend(observer, @selector(observeValueForKeyPath:ofObject:change:context:),getterChar,observer,change,context);
    
    //操作完成后指回动态创建的新类
    object_setClass(self, clazz);
}

```

#### 通知实现原理 如何自定义通知  


实现原理  

自定义通知可以先创建一个Notification对象，将注册消息的observer、通知名name、通知触发的方法选择器等写入Notification,然后再创建一个NotificationCenter类单例，并且在单例内部创建一个数组，用来存储所有的Notification,每当需要注册通知时，就将需要注册的信息绑定到Notification对象上，放到单例全局数组中，在发送通知消息的时候，根据通知名遍历单例数组匹配对应的Notification,再通过IMP直接调用注册通知的对象的响应方法即可。[具体实现，请参考demo](https://github.com/LiuFuBo/iOSInterviewQuestions/blob/master/demo)      




> 创建Notification类，用于保存observer、通知名name，通知触发方法名、block回调等信息  

* 声明文件部分

```
@interface Notification : NSObject
@property (nonatomic, strong, readwrite) NSDictionary *userInfo;
@property (nonatomic, assign) id object;
@property (nonatomic, assign) id observer;
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) void(^callBack)(void);
@property (nonatomic, assign) SEL aSelector;

- (NSString *)name;
- (id)object;
- (NSDictionary *)userInfo;

+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject;
+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject userInfo:(NSDictionary *)aUserInfo;
- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo;


@end

```

* 实现文件部分  

```
@implementation Notification

+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject {
    return [Notification notificationWithName:aname object:anObject userInfo:nil];
}

+ (instancetype)notificationWithName:(NSString *)aname object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    
    Notification *nofi = [[Notification alloc]init];
    nofi.name = aname;
    nofi.object = anObject;
    nofi.userInfo = aUserInfo;
    return nofi;
}

- (instancetype)initWithName:(NSString *)name object:(id)object userInfo:(NSDictionary *)userInfo {
    return [Notification notificationWithName:name object:object userInfo:userInfo];
}

@end

```
  



> 创建NOtificationCenter类进行通知的管理,包括注册信息的数组保存，发送消息对象查找，以及IMP调用  


* 声明文件添加注册和发送通知两类方法  

```
@interface NotificationCenter : NSObject

+ (instancetype)defaultCenter;
- (void)addObserver:(id)observer callBack:(void(^)(void))callBack name:(NSString *)aName object:(id)anObject;
- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject;

- (void)postNotification:(Notification *)notification;
- (void)postNotificationName:(NSString *)aName object:(id)anObject;
- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo;

@end

```

* 实现文件单例的初始化、数组的创建  

```
@implementation NotificationCenter{
    NSMutableArray *_nofiArray;
}

+ (instancetype)defaultCenter {
    static NotificationCenter *_infoCenter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _infoCenter = [[NotificationCenter alloc]init];
    });
    return _infoCenter;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        _nofiArray = [[NSMutableArray alloc]init];
    }
    return self;
}

```

* 对通知消息进行注册，该步骤主要是将注册信息绑定到Notification对象，并存储到全局数组

```
- (void)addObserver:(id)observer selector:(SEL)aSelector callBack:(void (^)(void))callBack name:(NSString *)aName object:(id)anObject {
    
    Notification *nofi = [[Notification alloc]init];
    nofi.callBack = callBack;
    nofi.name = aName;
    nofi.aSelector = aSelector;
    nofi.observer = observer;
    [_nofiArray addObject:nofi];
}

- (void)addObserver:(id)observer callBack:(void (^)(void))callBack name:(NSString *)aName object:(id)anObject {
    [self addObserver:observer selector:nil callBack:callBack name:aName object:anObject];
}

- (void)addObserver:(id)observer selector:(SEL)aSelector name:(NSString *)aName object:(id)anObject {
    [self addObserver:observer selector:aSelector callBack:nil name:aName object:anObject];
}

```

* 发送通知消息，采用遍历数组，通过通知名命中对应能响应该通知的对象，并调用其对象对应的消息响应方法或者block回调  

```
- (void)postNotificationName:(NSString *)aName object:(id)anObject {
    
    for (Notification *nofi in _nofiArray) {
           if ([nofi.name isEqualToString:aName]) {
               
               nofi.object = anObject ? : anObject;
               
               if (nofi.callBack) {
                   nofi.callBack();
               }
               if (nofi.aSelector) {
                   if ([nofi.observer respondsToSelector:nofi.aSelector]) {
                       IMP imp = [nofi.observer methodForSelector:nofi.aSelector];
                       void(*func)(id, SEL,Notification *) = (void *)imp;
                       func(nofi.observer,nofi.aSelector,nofi);
                   }
               }
           }
    }
}

- (void)postNotification:(Notification *)notification {
    for (Notification *nofi in _nofiArray) {
        if ([nofi.name isEqualToString:notification.name]) {
            nofi.callBack = notification.callBack;
            nofi.object = notification.object;
            nofi.aSelector = notification.aSelector;
            nofi.observer = notification.observer;
            nofi.userInfo = notification.userInfo;
            break;
        }
    }
    [self postNotificationName:notification.name object:nil];
}

- (void)postNotificationName:(NSString *)aName object:(id)anObject userInfo:(NSDictionary *)aUserInfo {
    
    for (Notification *nofi in _nofiArray) {
        
        if ([nofi.name isEqualToString:aName]) {
            nofi.object = anObject;
            nofi.userInfo = aUserInfo;
            break;
        }
    }
    [self postNotificationName:aName object:nil];
}

@end

```

#### 一个只读的属性 为什么不能实现KVO?

>因为readonly对象没有setter方法，isa指向的派生类NSKVONotifying_XXX，也是readonly的，所以没有setter方法


#### UIWebView和WKWebView的区别?

WKWebView的优劣势   

>1.内存占用是UIWebView的20%-30%;   
>2.页面加载速度有提升，有的文章说它的加载速度比UIWebView提升了一倍左右。   
>3.更为细致地拆分了 UIWebViewDelegate 中的方法   
>4.自带进度条。不需要像UIWebView一样自己做假进度条（通过NJKWebViewProgress和双层代理技术实现），技术复杂度和代码量，根贴近实际加载进度优化好的多。   
>5.允许JavaScript的Nitro库加载并使用（UIWebView中限制）   
>6.可以和js直接互调函数，不像UIWebView需要第三方库WebViewJavascriptBridge来协助处理和js的交互。   
>7.不支持页面缓存,需要自己注入cookie,而UIWebView是自动注入cookie。   
>8.无法发送POST参数问题。


#### 一张图片渲染到屏幕上经过了什么过程

对应应用来说，图片是最占用手机内存的资源，将一张图片从磁盘中加载出来，并最终显示到屏幕上，中间其实经过了一系列复杂的处理过程。

具体工作流程:

>1、假设我们使用 +imageWithContentsOfFile: 方法从磁盘中加载一张图片，这个时候的图片并没有解压缩；  
>2、然后将生成的 UIImage 赋值给 UIImageView ；  
>3、接着一个隐式的 CATransaction（Transactions是CoreAnimation的用于将多个layer tree操作批量化为渲染树的原子更新的机制。 对layer tree的每个修改都需要事务作为其一部分） 捕获到了 UIImageView 图层树的变化；  
>4、在主线程的下一个 runloop 到来时，Core Animation 提交了这个隐式的 transaction ，这个过程可能会对图片进行 copy 操作，而受图片是否字节对齐等因素的影响，这个 copy 操作可能会涉及以下部分或全部步骤：  
>分配内存缓冲区用于管理文件 IO(输入/输出) 和解压缩操作；  
>将文件数据从磁盘读到内存中；  
>将压缩的图片数据解码成未压缩的位图形式，这是一个非常耗时的 CPU 操作；  
>最后 Core Animation 中CALayer使用未压缩的位图数据渲染 UIImageView 的图层。  


渲染流程:    

>GPU获取获取图片的坐标  
>将坐标交给顶点着色器(顶点计算)  
>将图片光栅化(获取图片对应屏幕上的像素点)  
>片元着色器计算(计算每个像素点的最终显示的颜色值)  
>从帧缓存区中渲染到屏幕上  
>我们提到了图片的解压缩是一个非常耗时的 CPU操作，并且它默认是在主线程中执行的。那么当需要加载的图片比较多时，就会对我们应用的响应性造成严重的影响，尤其是在快速滑动的列表上，这个问题会表现得更加突出。  

为什么要解压缩图片?

 既然图片的解压缩需要消耗大量的 CPU 时间，那么我们为什么还要对图片进行解压缩呢？是否可以不经过解压缩，而直接将图片显示到屏幕上呢？答案是否定的。要想弄明白这个问题，我们首先需要知道什么是位图
其实，位图就是一个像素数组，数组中的每个像素就代表着图片中的一个点。我们在应用中经常用到的 JPEG 和 PNG 图片就是位图

例如:  

```
UIImage *image = [UIImage imageNamed:@"file.png"];
CFDataRef rawData = CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
```

打印rawData,这里就是图片的原始数据.
事实上，不管是 JPEG 还是 PNG 图片，都是一种压缩的位图图形格式。只不过 PNG 图片是无损压缩，并且支持 alpha 通道，而 JPEG 图片则是有损压缩，可以指定 0-100% 的压缩比。值得一提的是，在苹果的 SDK 中专门提供了两个函数用来生成 PNG 和 JPEG 图片： 

```
// return image as PNG. May return nil if image has no CGImageRef or invalid bitmap format
UIKIT_EXTERN NSData * __nullable UIImagePNGRepresentation(UIImage * __nonnull image);
 
// return image as JPEG. May return nil if image has no CGImageRef or invalid bitmap format. compression is 0(most)..1(least)       
UIKIT_EXTERN NSData * __nullable UIImageJPEGRepresentation(UIImage * __nonnull image, CGFloat compressionQuality);

```

因此，在将磁盘中的图片渲染到屏幕之前，必须先要得到图片的原始像素数据，才能执行后续的绘制操作，这就是为什么需要对图片解压缩的原因。


解压缩原理

既然图片的解压缩不可避免，而我们也不想让它在主线程执行，影响我们应用的响应性，那么是否有比较好的解决方案呢？  
我们前面已经提到了，当未解压缩的图片将要渲染到屏幕时，系统会在主线程对图片进行解压缩，而如果图片已经解压缩了，系统就不会再对图片进行解压缩。因此，也就有了业内的解决方案，在子线程提前对图片进行强制解压缩。
而强制解压缩的原理就是对图片进行重新绘制，得到一张新的解压缩后的位图。其中，用到的最核心的函数是 CGBitmapContextCreate：    


```
CG_EXTERN CGContextRef __nullable CGBitmapContextCreate(void * __nullable data,
 size_t width, size_t height, size_t bitsPerComponent, size_t bytesPerRow,
 CGColorSpaceRef cg_nullable space, uint32_t bitmapInfo)
 CG_AVAILABLE_STARTING(__MAC_10_0, __IPHONE_2_0);

```

>data ：如果不为 NULL ，那么它应该指向一块大小至少为 bytesPerRow * height 字节的内存；如果 为 NULL ，那么系统就会为我们自动分配和释放所需的内存，所以一般指定 NULL 即可；  
>width 和height ：位图的宽度和高度，分别赋值为图片的像素宽度和像素高度即可；  
>bitsPerComponent ：像素的每个颜色分量使用的 bit 数，在 RGB 颜色空间下指定 8 即可；  
>bytesPerRow ：位图的每一行使用的字节数，大小至少为 width * bytes per pixel 字节。当我们指定 0/NULL 时，系统不仅会为我们自动计算，而且还会进行 cache line alignment 的优化;    
>space ：就是我们前面提到的颜色空间，一般使用 RGB 即可；  
>bitmapInfo ：位图的布局信息.kCGImageAlphaPremultipliedFirst;    


总结  

>1、图片文件只有在确认要显示时,CPU才会对齐进行解压缩.因为解压是非常消耗性能的事情.解压过的图片就不会重复解压,会缓存起来。  
>2、图片渲染到屏幕的过程:读取文件->计算Frame->图片解码->解码后纹理图片位图数据通过数据总线交给GPU->GPU获取图片Frame->顶点变换计算->光栅化->根据纹理坐标获取每个像素点的颜色值(如果出现透明值需要将每个像素点的颜色透明度值)->渲染到帧缓存区->渲染到屏幕。  


#### 离屏渲染是什么 什么场景会触发离屏渲染 都有什么具体的优化

首先，什么是离屏渲染?

离屏渲染就是在当前屏幕缓冲区以外，新开辟一个缓冲区进行操作。

离屏渲染出发的场景有以下： 

>1.圆角 （maskToBounds并用才会触发）    
>2.图层蒙版  
>3.阴影  
>4.光栅化  


为什么要避免离屏渲染？

CPU、GPU 在绘制渲染视图时做了大量的工作。离屏渲染发生在 GPU 层面上，会创建新的渲染缓冲区，会触发 OpenGL的多通道渲染管线，图形上下文的切换会造成额外的开销，增加 GPU 工作量。如果 CPU  GPU 累计耗时 16.67 毫秒还没有完成，就会造成卡顿掉帧。  

圆角属性、蒙层遮罩 都会触发离屏渲染。指定了以上属性，标记了它在新的图形上下文中，在未愈合之前，不可以用于显示的时候就出发了离屏渲染。

在OpenGL中，GPU有2种渲染方式

>On-Screen Rendering：当前屏幕渲染，在当前用于显示的屏幕缓冲区进行渲染操作    
>Off-Screen Rendering：离屏渲染，在当前屏幕缓冲区以外新开辟一个缓冲区进行渲染操作    

离屏渲染消耗性能的原因

>需要创建新的缓冲区
>离屏渲染的整个过程，需要多次切换上下文环境，先是从当前屏幕（On-Screen）切换到离屏（Off-Screen）；等到离屏渲染结束以后，将离屏缓冲区的渲染结果显示到屏幕上，又需要将上下文环境从离屏切换到当前屏幕。


哪些操作会触发离屏渲染？

>光栅化，layer.shouldRasterize = YES  
>遮罩，layer.mask  
>圆角，同时设置 layer.masksToBounds = YES、layer.cornerRadius大于0  
>考虑通过 CoreGraphics 绘制裁剪圆角，或者叫美工提供圆角图片阴影，layer.shadowXXX，如果设置了 layer.shadowPath 就不会产生离屏渲染  


什么是光栅化?

光栅化是将一个图元转变为一个二维图像的过程。二维图像上每个点都包含了颜色、深度和纹理数据。将该点和相关信息叫做一个片元,光栅化的目的，是找出一个几何单元（比如三角形）所覆盖的像素。你模型的那些顶点在经过各种矩阵变换后也仅仅是顶点。而由顶点构成的三角形要在屏幕上显示出来，除了需要三个顶点的信息以外，还需要确定构成这个三角形的所有像素的信息。光栅化会根据三角形顶点的位置，来确定需要多少个像素点才能构成这个三角形，以及每个像素点都应该得到哪些信息.  



#### LRU算法原理以及如何优化?

LRU设计原理

LRU（Least recently used，最近最少使用）算法根据数据的历史访问记录来进行淘汰数据，其核心思想是“如果数据最近被访问过，那么将来被访问的几率也更高”。

最常见的实现是使用一个链表保存缓存数据，详细算法实现如下：

![image](http://brandonliu.pub/icon_blog_lru.png)  


>1.新数据插入到链表头部；  
>2.每当缓存命中（即缓存数据被访问），则将数据移到链表头部；  
>3.当链表满的时候，将链表尾部的数据丢弃。  

 命中率  

>当存在热点数据时，LRU的效率很好，但偶发性的、周期性的批量操作会导致LRU命中率急剧下降，缓存污染情况比较严重。
 复杂度  
>实现简单。
 代价
>命中时需要遍历链表，找到命中的数据块索引，然后需要将数据移到头部。


LRU-K原理  

LRU-K中的K代表最近使用的次数，因此LRU可以认为是LRU-1。LRU-K的主要目的是为了解决LRU算法“缓存污染”的问题，其核心思想是将“最近使用过1次”的判断标准扩展为“最近使用过K次”。

相比LRU，LRU-K需要多维护一个队列，用于记录所有缓存数据被访问的历史。只有当数据的访问次数达到K次的时候，才将数据放入缓存。当需要淘汰数据时，LRU-K会淘汰第K次访问时间距当前时间最大的数据。详细实现如下：

![image](http://brandonliu.pub/icon_blog_lruK.png)


>1.数据第一次被访问，加入到访问历史列表；  
>2.如果数据在访问历史列表里后没有达到K次访问，则按照一定规则（FIFO，LRU）淘汰；  
>3.当访问历史队列中的数据访问次数达到K次后，将数据索引从历史队列删除，将数据移到缓存队列中，并缓存此数据，缓存队列重新按照时间排序；  
>4.缓存数据队列中被再次访问后，重新排序；  
>5.需要淘汰数据时，淘汰缓存队列中排在末尾的数据，即：淘汰“倒数第K次访问离现在最久”的数据。  
LRU-K具有LRU的优点，同时能够避免LRU的缺点，实际应用中LRU-2是综合各种因素后最优的选择，LRU-3或者更大的K值命中率会高，但适应性差，需要大量的数据访问才能将历史访问记录清除掉。    


 命中率  
 >LRU-K降低了“缓存污染”带来的问题，命中率比LRU要高。    


 复杂度  
>LRU-K队列是一个优先级队列，算法复杂度和代价比较高。  


 代价  
>由于LRU-K还需要记录那些被访问过、但还没有放入缓存的对象，因此内存消耗会比LRU要多；当数据量很大的时候，内存消耗会比较可观。LRU-K需要基于时间进行排序（可以需要淘汰时再排序，也可以即时排序），CPU消耗比LRU要高。  


关于 `NSDictionary + 双向链表 `  实现LRU缓存淘汰算法方案  


度过YYCache的同学应该知道YYCache内部对于内存缓存部分就是采用 `NSDictionary + 双向链表` 来实现的，具体的实现思路如下:  


设计思路:  


使用 `NSDictionary` 存储 `key`，这样可以做到 Save 和 Get key的时间都是 O(1)，而 NSDictionary 的 Value 指向双向链表实现的 `LRU` 的 `Node` 节点，利用空间hash_map的空间换来快速如图所示的访问；  

![image](http://brandonliu.pub/icon_lru_cache.png)


LRU 存储是基于双向链表实现的。其中 `head` 代表双向链表的表头，`tail` 代表尾部。首先预先设置 LRU 的容量，如果存储满了，可以通过 O(1) 的时间淘汰掉双向链表的尾部，每次新增和访问数据，都可以通过 O(1)的效率把新的节点增加到对头，或者把已经存在的节点移动到队头。

关于存取实现细节如下:

>1.存储数据，首先在NSDictionary找到Key对应的节点，如果节点存在，更新节点的值，并把这个节点移动队头。如果不存在，需要构造新的节点，并且尝试把节点塞到队头，如果LRU空间不足，则通过 tail 淘汰掉队尾的节点，同时在 HashMap 中移除 Key。  

>2.获取数据,通过 NSDictionary 找到 LRU 链表节点，因为根据LRU 原理，这个节点是最新访问的，所以要把节点插入到队头，然后返回缓存的值。

demo样例:

```

struct DlinkdNode {
	int  key;
	int val;
	DlinkdNode* pre;
	DlinkdNode* next;
 
};

class LRUCache {
private:
	unordered_map<int, DlinkdNode*>cache;
	int capacity;
	int size;
	DlinkdNode*head;
	DlinkdNode*tail;
 
    //链表中添加节点
	void addNode(DlinkdNode* node)
	{
		node->pre = head;
		node->next = head->next;
		head->next->pre = node;
		head->next = node;
	}
    //链表中删除节点
	void remove(DlinkdNode*node)
	{
		node->pre->next = node->next;
		node->next->pre = node->pre;
		//delete node;此处不能删除，节点的删除交给hash_map进行，否则后序hash_map无法访问此节点
	}
   //链表中将节点调制头结点，数据变为最热的数据
	void moveTohead(DlinkdNode*node)
	{
		this->remove(node);
		this->addNode(node);
	}
 
	//删除链表尾节点
	DlinkdNode* popTail()
	{
		DlinkdNode*res = tail->pre;
		this->remove(res);
		return res;
	}
 
 
public:
	LRUCache(int capacity) {
		size = 0;
		this->capacity = capacity;
 
		head = new DlinkdNode();
		head->pre = nullptr;
 
		tail = new DlinkdNode();
		tail->next = nullptr;
 
		head->next = tail;
		tail->pre = head;
	}
 
	int get(int key) {
		unordered_map<int, DlinkdNode*>::iterator it = cache.find(key);
		if (it == cache.end())
			return -1;
		else {
			moveTohead(it->second);
			return it->second->val;
		}
	}
 
 
	void put(int key, int value) {
		unordered_map<int, DlinkdNode*>::iterator it = cache.find(key);
		if (it == cache.end()) {
			DlinkdNode*Node = new DlinkdNode();
			Node->key = key;
			Node->val = value;
			this->cache.insert({ key,Node });
			addNode(Node);
 
			++size;
			if (size > capacity)//超出容量将尾部最冷数据删除
			{
				DlinkdNode* TailNode = popTail();
				cache.erase(TailNode->key);
				--size;
			}
		}
		else {
			it->second->val = value;//更新缓存key对应的val,并移动到链表头，最热
			moveTohead(it->second);
	}
 
}
};

```


#### NSMutableArray是线程安全的么 如何创建线程安全的NSMutableArray

>首先,NSMutableArray是线程不安全的，当有多个线程同时对数组进行操作的时候可能导致崩溃或数据错误

>对数组的读写都加锁，虽然数组是线程安全了，但失去了多线程的优势

> 然后又想可以只对写操作加锁然后定义一个全局变量来表示现在有没有写操作，如果有写操作就等写完了在读，那么问题来了如果一个线程先读取数据紧接着一个线程对数组写的操作，读的时候还没有加锁同样会导致崩溃或数据错误，这个方案pass掉.

>第三种方案说之前先介绍一下dispatch_barrier_async，dispatch_barrier_async 追加到 并行队列 queue 中后，会等待并行队列 queue 中的任务都结束后，再执行 dispatch_barrier_async 的任务，等 dispatch_barrier_async 的任务结束后，才恢复任务执行， 用dispatch_async和dispatch_barrier_async结合保证NSMutableArray的线程安全，用dispatch_async读和dispatch_barrier_async写（add,remove,replace），当有任务在读的时候写操作会等到所有的读操作都结束了才会写，同样当有写任务时，读任务会等写操作完了才会读，既保证了线程安全又发挥了多线程的优势，但还是有个不足，当我们重写读的方法时dispatch_async是另开辟线程去执行的而且是立马返回的，所以我们不能拿到执行结果，需要去另写一个方法来返回读的结果，但是我们又不想改变调用者的习惯于是又想到了一下方案

>用dispatch_sync和dispatch_barrier_async以及一个并行队列queue结合保证NSMutableArray的线程安全，dispatch_sync是在当前线程上执行不会另开辟新的线程，当线程返回的时候就可以拿到读取的结果，我认为这个方案是最完美的选择，既保证的线程安全有发挥了多线程的优势还不用另写方法返回结果.  



#### UITableView性能优化汇总

一、Cell重用

优化数据源方法:

```
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

```

在可⻅的⻚⾯会重复绘制⻚⾯，每次刷新显示都会去创建新的Cell，非常耗费性能。

解决方案:  创建⼀个静态变量reuseID(代理方法返回Cell会调用很多次，防⽌重复创建，static保证只会被创建⼀次，提⾼性能)，然后，从缓存池中取相应 identifier的Cell并更新数据，如果没有，才开始alloc新的Cell，并用identifier标识 Cell。每个Cell都会注册⼀个identifier(重用标识符)放⼊入缓存池，当需要调⽤的时候就直接从缓存池里找对应的id，当不需要时就放入缓存池等待调⽤。(移出屏幕的Cell才会放⼊入缓存池中，并不会被release)

优化方案如下:

```
static NSString *reuseID = “reuseCellID”;
// 缓存池中取已经创建的cell
UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseID];

```

缓存池内部原理:

当Cell要alloc时，UITableView会在堆中开辟一段内存以供Cell缓存之用。Cell的重 用通过identifier标识不同类型的Cell，由此可以推断出，缓存池外层可能是⼀个可变字典，通过key来取出内部的Cell，而缓存池为存储不同高度、不同类型(包含图片、 Label等)的Cell，可以推断出缓存池的字典内部可能是一个可变数组，用来存放不同类型的Cell，缓存池中只会保存已经被移出屏幕的不同类型的Cell。


缓存池获取可重用Cell的两个方法区别

```
-(nullable __kindof UITableViewCell *)dequeueReusableCellWithIdentifier: (NSString *)identifier;
这个⽅法会查询可重用Cell，如果注册了原型Cell，能够查询到，否则，返回nil;⽽且需要判断if(cell == nil)，才会创建Cell，不推荐
-(__kindof UITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier forIndexPath:(NSIndexPath *)indexPath NS_AVAILABLE_IOS(6_0);
使⽤这个⽅法之前，必须通过xib(storyboard)或是Class(纯代码)注册可重用 Cell，而且这个方法⼀定会返回一个Cell
//注册Cell
- (void)registerNib:(nullable UINib *)nib forCellReuseIdentifier:(NSString
*)identifier NS_AVAILABLE_IOS(5_0);
- (void)registerClass:(nullable Class)cellClass forCellReuseIdentifier:(NSString *)identifier NS_AVAILABLE_IOS(6_0);

```

二、在同一个UITableView中尽量少定义Cell类型，并且需要善用hidden隐藏或者显示subviews    


尽量少的定义Cell类型    

分析Cell结构，尽可能的将 相同内容的抽取到⼀种样式Cell中，前面已经提到了Cell的重⽤机制，这样就能保证UITbaleView要显示多少内容，真正创建出的Cell可能   只比屏幕显示的Cell多⼀点。虽然Cell的’体积’可能会大点，但是因为Cell的数量不会很多，完全可以接受的。    

好处:
>减少代码量，减少Nib⽂件的数量，统⼀一个Nib文件定义Cell，容易修改、维护。  
>基于Cell的重⽤，真正运⾏时铺满屏幕所需的Cell数量⼤致是固定的，设为N个。所以如果如果只有一种Cell，那就是只有N个Cell的实例;但是如果有M种Cell，那么运行时最多可能会是“M x N = MN”个Cell的实例例，虽然可能并不会占⽤用太多内存，但是能少点不是更好吗。  


善用hidden隐藏或显示subviews

只定义⼀种Cell，那该如何显示不同类型的内容呢?答案就是，把所有不同类型的view都定义好，放在cell⾥⾯，通过hidden显示、隐藏，来显示不同类型的内容。毕竟，在⽤户快速滑动中，只是单纯的显示、隐藏subview比实时创建要快得多。  


三、提前计算并缓存Cell的⾼高度

在iOS中，不设UITableViewCell的预估行高的情况下，会优先调用 ”tableView:heightForRowAtIndexPath:”⽅法，获取每个Cell的即将显示的高度， 从而确定UITableView的布局，实际就是要获取contentSize(UITableView继承⾃UIScrollView,只有获取滚动区域，才能实现滚动),然后才调用”tableView:cellForRowAtIndexPath”,获取每个Cell，进⾏赋值。如果项⽬中模块有 10000个Cell需要显示，可想⽽知.  


解决方案如下:

可以将计算Cell的⾼高度放⼊入数据模型，但这与MVC设计模式可能稍微有点冲突，这个时候我就想到MVVM这种设计模式，这个时候才能稍微有点MVVM这种设计模式的优点，可 以讲计算Cell⾼高度放入ViewModel(视图模型)中，让Model(数据模型)只负责处理数据。  


四、异步绘制(自定义Cell绘制)

遇到⽐较复杂的界面的时候，如复杂点的图文混排采用异步绘制Cell


五、滑动时，按需加载

开发的过程中自定义Cell的种类千奇百怪，但Cell本来就是⽤来显示数据的，不说100%带有图片，也差不多，这个时候就要考虑，下滑的过程中可能会有点卡顿，尤其网络不好的时候，异步加载图片是个程序员都会想到，但是如果给每个循环对象都加上异步加载，开启的线程太多，⼀样会卡顿，我记得好像线程条数⼀般3-5条，最多也就6条吧。

解决方案:

cell每次被渲染时，判断当前tableView是否处于滚动状态，是的话，不加载图片,cell 滚动结束的时候，获取当前界面内可见的所有cell.
```
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
    }
    
    DemoModel *model = self.datas[indexPath.row];
    cell.textLabel.text = model.text;
   
    //不在直接让cell.imageView loadYYWebImage
    if (model.iconImage) {
        cell.imageView.image = model.iconImage;
    }else{
       cell.imageView.image = [UIImage imageNamed:@"placeholder"];
        /**
         runloop - 滚动时候 - trackingMode，
         - 默认情况 - defaultRunLoopMode
         ==> 滚动的时候，进入`trackingMode`，defaultMode下的任务会暂停
         停止滚动的时候 - 进入`defaultMode` - 继续执行`trackingMode`下的任务 - 例如这里的loadImage
         */
        [self performSelector:@selector(p_loadImgeWithIndexPath:)
                   withObject:indexPath
                   afterDelay:0.0
                      inModes:@[NSDefaultRunLoopMode]];
      }
}

//下载图片，并渲染到cell上显示
- (void)p_loadImgeWithIndexPath:(NSIndexPath *)indexPath{
    
    DemoModel *model = self.datas[indexPath.row];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
    
    [ImageDownload loadImageWithModel:model success:^{
        //主线程刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            cell.imageView.image = model.iconImage;
        });
    }];
}

```

六、避免⼤量的图片缩放、颜⾊渐变等，尽量显示“大⼩刚好合适的图片资源

七、避免同步的从网络、文件获取数据，Cell内实现的内容来自web，使用异步加载，缓存请求结果


八、减少渲染复杂度

解决方案如下:

>减少subviews的个数和层级,子控件的层级越深，渲染到屏幕上所需要的计算量就越大;如多用drawRect绘制元素，替代⽤view显示.  

>少⽤用subviews的半透明图层,不透明的View，设置opaque为YES，这样在绘制该View时，就不需要考虑被View覆盖的其他内容(尽量设置Cell的view为opaque，避免GPU对Cell下⾯的内容 也进行绘制)

>避免CALayer特效(shadowPath) 给Cell中View加阴影会引起性能问题，如下面代码会导致滚动时有明显的卡顿:


#### 有两个视图A/B A有一部分内容覆盖在B上面 如果点击A让B视图响应  


对于这个问题，仅仅需要按照以下方法  

```
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        // 转换坐标系
        CGPoint newPoint = [self.subButton convertPoint:point fromView:self];
        // 判断触摸点是否在button上
        if (CGRectContainsPoint(self.A, newPoint)) {
            view = self.B;
        }
    }
    return view;
}

```

从上面可以看到，仅仅只需要在里面加一个判断，当点击的点在A视图里面，则将响应对象返回为B，即可实现该功能。  


#### 折半查找为何不能用于存储结构是链式的有序查找表    

> 这是由链表的特性决定的，链表是典型的顺序存取结构，数据在链表中的位置只能通过从头到尾的顺序检索得到，即使是有序的，要操作其中的某个数据也必须从头开始。这和数组有本质的区别。数组中的元素是通过下标来确定的，只要知道了下标，就可以直接存储真个元素，比如a[0]是可以直接存取的，链表没有这个，所以折半查找只能在数组上进行。    



#### 同步 异步与串行 并行的关系  

> 这块知识在我的简书博客[这篇文章](https://www.jianshu.com/p/29f1cee0aef7)中已经阐述的很清楚了，有不明白的同学欢迎前往自取。  


#### 类目为何不能添加属性

> 首先咱们的类目并不会生成setter和getter方法，其次类目没有成员变量列表。     


#### 字典一般是用字符串来当做Key的 可以用对象来做key么 要怎么做

 字典是可以用对象来做key的，不过需要满足几个条件    
> 1.NSDictionary的key实际是使用了copy方法，所以key必须要遵守NSCopying协议  
> 2.实现 ‘copyWithZone:’ 方法  
> 3.必须要保证 'copyWithZone: ' 返回对象为同一个地址对象，如果不能保证，则必须重写hashCode和isEqual方法，用来保证让存进去的对象key的地址不发生变化。  


#### 苹果公司为什么要设计元类    

> 这个问题是个开放性的问题。不同阶段的解读也会不一样。因为这个知识点大家都会去学，主要是希望能够通过面试者的回答，加上追问方式来看他是不是会带着思考去学习。比如元类和类的结构体非常类似，他有没有想过为什么不合在一起用一个结构体？（结构体设计能力）元类和类创建的时机是不是一样的，为什么？（用过 runtime 接口开发没）元类的 flag 字段里记录了什么？（是否有深入探究的意识）。    

* 个人认为元类和类的数据结构是同一个，只是运行时使用的字段不一样。实例方法调用是通过objc_msgSend来调用，它的第一个入参就是实例对象，其流程是查找实例对象的isa指针，找到类对象，然后找到method_t的IMP，bl直接跳转调用。  
* 类方法的调用和实例方法调用一致，它的第一个入参对象是类对象，类对象的isa指向的是元类。  
* 所以，没有元类的话，类方法是没有办法调用的。objc_msgSend的调用流程是一定要isa指针的。  
* 如果实例方法和类方法都放在类对象上，那类对象的isa指针只能指向自己了，那一旦类方法和实例方法重名，就没法搞了！   


#### 结构体和联合区的区别  

* 联合体 (union)  
> 各成员变量共用同一块内存空间，并且同事只有一个成员变量可以得到这块内存的使用权，当联合体对不同成员变量赋值，就会对其他成员重写，原来成员的值就不存在了。一个联合体变量的总长度等于最长的成员长度。  

* 结构体 (struct) 
> 各成员变量拥有各自的内存，互不干涉，遵守内存对齐原则，一个结构体的总长度等于所有成员的长度之和。 







