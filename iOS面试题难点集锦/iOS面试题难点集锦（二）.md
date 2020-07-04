## iOS面试题难点集锦（二）---参考答案

引言：通过上篇文章[iOS面试题难点集锦（一）](https://github.com/LiuFuBo/iOSInterviewQuestions/blob/master/iOS面试题难点集锦/iOS面试题难点集锦（一）.md)，我们讲解了一些关于Runtime的知识，由于篇幅过长问题，其他一些内容咱们会放到后续一些章节来讲解。

# 索引

1. [main函数之前程序做了些什么？](#main函数之前程序做了些什么)  
2. [NSArray 和 NSMutableArray使用Copy和MutableCopy有何不同?](#nsarray-和-nsmutablearray使用copy和mutablecopy有何不同)  
3. [initialize 和 init 以及 load 调用时机?](#initialize-和-init-以及-load-调用时机)  
4. [GCD 全称是啥?什么时候使用 GCD?](gcd-全称是啥-什么时候使用-gcd)  
5. [NSURLSession 和 NSURLConnection 区别?](#nsurlsession-和-nsurlconnection-区别?)  
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

NSURLConnection 下载文件时，先将整个文件下载到内存，然后再写入沙盒，如果文件比较 大，就会出现内存暴涨的情况。而使用 NSURLSessionUploadTask 下载文件，会默认下载到沙 盒中的 tem 文件夹中，不会出现内存暴涨的情况，但在下载完成后会将 tem 中的临时文件 删除，需要在初始化任务方法时，在 completionHandler 回调中增加保存文件的代码。  

4.配置信息

NSURLSession 的构造方法(sessionWithConfiguration:delegate:delegateQueue)中有一个 NSURLSessionConfiguration 类的参数可以设置配置信息，其决定了 cookie，安全和高速缓存 策略，最大主机连接数，资源管理，网络超时等配置。NSURLConnection 不能进行这个配置， 相比于 NSURLConnection 依赖于一个全局的配置对象，缺乏灵活性而言，NSURLSession 有 很大的改进了。  


### 引用计数设计原理

引用计数设计不仅我们的系统是否支持`Tagged Pointer`有关系，而且还跟系统`isa`指针是否优化过有关系，具体的实现原理可参考这篇文章[Objective-C 引用计数原理](https://www.jianshu.com/p/12d6e64c07bb)。


### Hash表扩容问题



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

开放地址法: 

这种方法的意思是当关键字 Key 的哈希地址 p=H(key)出现冲突是，以 p 为基础， 产生另一个哈希地址 `p1`,如果 `p1` 仍然冲突，产生另外一个哈希地址 P2,直到找出不冲突的哈 希地址 Pi,将相应元素存入其中。  

线性探测再散列

当发生冲突的时候，顺序的查看下一个单元

二次(平方)探测再散列

当发生冲突的时候，在表的左右进行跳跃式探测 (+1^2 如果有冲突就-1^2 如果发生冲 突,+2^2 进行验证)

伪随机探测再散列

建立一个伪随机数发生器，并给一个随机数作为起点，再hash法 这种方式是同时构造多个哈希函数，当产生冲突时，计算另一个哈希函数的值。 这种方法不易产生聚集，但增加了计算时间。  

链地址法

将所有哈希地址相同的都链接在同一个链表中 ，因而查找、插入和删除主要在同义词链中 进行。链地址法适用于经常进行插入和删除的情况。HashMap 就是用此方法解决冲突的。 此种方法必须要求采用链表来实行 hash表。

建立一个公共溢出区 

将哈希表分为基本表和溢出表两部分，凡是和基本表发生冲突的元素，一律填入溢出表。


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










