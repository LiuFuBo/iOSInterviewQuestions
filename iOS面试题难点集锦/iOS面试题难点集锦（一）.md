## iOS面试题难点集锦（一）---参考答案

说明：面试题来源于自己知识点的总结以及一些博客大佬例如:[玉令天下的博客](http://yulingtianxia.com)的博文学习记录。文章问题答案如有出入的地方，欢迎联系我加以校正。

# 索引


1. [什么是Runtime？Runtime方法是如何在缓存中寻找的?](#什么是runtime?runtime方法是如何在缓存中寻找的)

2. [在Runtime中，是如何在消息列表中查找方法的?](#在runtime中是如何在消息列表中查找方法的)

3. [Runtime在项目中的运用](#Runtime在项目中的运用)

4. [Class继承链关系](#Class继承链关系)

5. [以上代码打印结果是什么?](#以上代码打印结果是什么)

5. [RunLoop和屏幕点击事件传递链以及响应链关系](#RunLoop和屏幕点击事件传递链以及响应链关系)







### 什么是Runtime？Runtime方法是如何在缓存中寻找的?

OC语言是一门动态语言，会将程序的一些决定工作从编译期推迟到运行期。由于OC语言运行时的特性，所以其不仅需要依赖编译期，还需要依赖运行时环境，这就是Objective-C Runtime(运行时环境)系统存在的意义。Runtime基本是由一套C、C++、以及汇编编写的，可见苹果为了动态系统的高效而作出的努力。你可以在[这里下载](https://opensource.apple.com/source/objc4/)到苹果维护的开源代码。苹果和GNU各自维护一个开源的 runtime 版本，这两个版本之间都在努力的保持一致。

OC􏰈􏰉􏰈􏰉语言在编译期都会被编译为C语言的Runtime代码，二进制执行过程中执行的都是C语言代码。而OC的类本质上都是结构体，在编译时都会以结构体的形式被编译到二进制中。

根据Apple官方文档的描述，目前OC运行时分为两个版本，Modern和Legacy,我们现在用的 Objective-C 2.0 采用的是现行 (Modern) 版的 Runtime 系统，只能运行在 iOS 和 macOS 10.5 之后的 64 位程序中。而 maxOS 较老的32位程序仍采用 Objective-C 1 中的（早期）Legacy 版本的 Runtime 系统。这两个版本最大的区别在于Legacy在实例变量发生改变后，需要重新编译其子类。Modern在实例变量发生改变后，不需要重新编译其子类。

## Runtime的交互

我们在编写Objective-C代码的时候，无论是直接的还是间接的都会使用到Runtime,总的来说Runtime系统发生交互的方式主要有三种分别如下:

1.Objective-C源码直接使用上层Objective-C源码，然后底层会通过Runtime为其提供运行支持，上层不需要关心Runtime的运行。  
2.通过Foundation框架的NSObject类定义的方法来访问Runtime。NSObject在OC代码中绝大多数类都是继承自NSObject的，NSProxy类例外。Runtime在NSObject中定义了一些基础操作，NSObject的子类也具备这些特性。  
3.通过直接调用Runtime函数，不过我们一般情况下不需要直接调用Runtime函数，咱们直接和Objective-C代码打交道就好了。

## Runtime方法的调用

除了 `+(void)load` 以外，所有的OC方法调用在底层都会被转化为`objc_msgSend:`函数的调用，它是这样的结构:
```
id objc_msgSend ( id self, SEL op, ... );

```
下面咱们先逐一的对该函数参数做一个详尽的讲解。看过Runtime源码的可以直接跳过。

### id

`objc_msgSend`函数第一个参数类型为`id`,它实际是指向类实例的指针，具体结构如下:

```
typedef struct objc_object *id;

```
那么`objc_object`又是什么东西呢？参考Runtime部分源码:

```
struct objc_object {
private:
    isa_t isa;

public:

    // ISA() assumes this is NOT a tagged pointer object
    Class ISA();

    // getIsa() allows this to be a tagged pointer object
    Class getIsa();
    ... 此处省略其他方法声明
}

```
`objc_object`结构体包含了一个`isa`指针，类型为`isa_t`联合体。根据`isa`就可以顺藤摸瓜找到对象所属的类。因为`isa_t`使用`union`实现，所以可能表示多种形态，既可以当成指针，也可以作为存储标志位。它跟`tagged pointer`都涉及到引用计数管理。有关`isa_t`联合体更多的内容可以查看[Objective-C 引用计数原理](https://www.jianshu.com/p/12d6e64c07bb)。

注:`isa`指针不总是指向实例对象所属的类，不能依靠它来确定类型，而是应该用 class 方法来确定实例对象的类。因为KVO的实现机理就是将被观察对象的 `isa` 指针指向一个中间类而不是真实的类，这是一种叫做 isa-swizzling 的技术，详见[官方文档](https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/KeyValueObserving/Articles/KVOImplementation.html)

### SEL

`objc_msgSend`函数第二个参数类型为`SEL`，它是`selector`在Objc中的表示类型（Swift中是`Selector`类）。`selector`是方法选择器，
可以理解为区分方法的 ID，而这个 ID 的数据结构是`SEL`:
```
typedef struct objc_selector *SEL;

```
其实它也就是一个映射方法的C字符串，你可以用 Objc 编译器命令`@selector()`或者 Runtime 系统的 `sel_registerName` 函数来获得一个 `SEL` 类型的方法选择器。在OC中不同类中相同名字的方法所对应的方法选择器是相同的，即使方法名字相同而变量类型不同也会导致它们具有相同的方法选择器，于是OC方法命名中有时候会带上参数类型。

PS:`objc_msgSend`方法第三个参数`...`表示的是函数的一些参数，这里就不再做具体的讲解。

上面我们讲到`objc_msgSend`函数的各个参数的作用，同时了解到`isa`指针不能用来确定类型，必须用`class`方法来确定实例对象的类。那么`class`又究竟是个什么呢？咱们通过Runtime源码可以了解到它是一个结构体指针，具体结构如下:
```
typedef struct objc_class *Class;

```
而咱们的`objc_class`又是继承自`objc_object`结构体的，`objc_class`包含了很多成员，主要如下:

```
struct objc_class : objc_object {
    // Class ISA;
    Class superclass;
    cache_t cache;             // formerly cache pointer and vtable
    class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags
    class_rw_t *data() { 
        return bits.data();
    }
    ... 省略其他方法
}

```

`objc_class`它是继承自`objc_object`的，也就是说`Class`本身同时也是一个对象，为了处理类和对象的关系，runtime库创建了一种叫做元类(Meta Class)的东西，类对象所属类型就叫做元类，它用来表述类对象本身所具备的元数据。类方法就定义于此处，因为这些方法可以理解成类对象的实例方法。每个类仅有一个类对象，而每个类对象仅有一个与之相关的元类。当你发出一个类似 `[NSObject alloc] `的消息时，你事实上是把这个消息发给了一个类对象 (Class Object) ，这个类对象必须是一个元类的实例，而这个元类同时也是一个根元类 (root meta class) 的实例。所有的元类最终都指向根元类为其超类。所有的元类的方法列表都有能够响应消息的类方法。所以当 `[NSObject alloc]` 这条消息发给类对象的时候，objc_msgSend() 会去它的元类里面去查找能够响应消息的方法，如果找到了，然后对这个类对象执行方法调用。

<div align= center>
<img src = "http://brandonliu.pub/class-diagram.jpg"/>
</div>



上图中实线是`superclass`指针，虚线是`isa`指针。 有趣的是根元类的超类是 `NSObject`，而 `isa` 指向了自己，而 `NSObject` 的超类为 nil，也就是它没有超类。

可以看到运行时一个类还关联了它的超类指针，类名，成员变量，方法，缓存，还有附属的协议。

上面我们讲到OC方法调用实际转化为了 `objc_msgSend`函数调用，而通过方法选择器`SEL`字符串去寻找方法实现`IMP`则是先去当前对象的`cache`缓存中寻找的，也就是上面`objc_class`结构体对应的`cache_t`结构体内部实现。`cache_t`结构体的结构如下:
```
struct cache_t {
    struct bucket_t *_buckets;
    mask_t _mask;
    mask_t _occupied;
    ... 省略其他方法
}

```
`mask`存储了散列表的长度，`occupied`则存储了缓存方法的数量。

`buckets`则是存储了`IMP`和`SEL`映射的散列表(Hash表)。 通过Runtime源码查看`buckets`结构体如下:

```
struct bucket_t {
private:
    cache_key_t _key;
    IMP _imp;

public:
    inline cache_key_t key() const { return _key; }
    inline IMP imp() const { return (IMP)_imp; }
    inline void setKey(cache_key_t newKey) { _key = newKey; }
    inline void setImp(IMP newImp) { _imp = newImp; }

    void set(cache_key_t newKey, IMP newImp);
};

```

通过阅读Runtime源码，我们可以找到方法缓存的实现函数为`cache_fill_nolock(Class cls, SEL sel, IMP imp, id receiver)`具体实现如下：

```
static void cache_fill_nolock(Class cls, SEL sel, IMP imp, id receiver)
{  //线程安全操作
    cacheUpdateLock.assertLocked();
    //系统要求在类初始化完成之前，不能进行方法缓存，因此如果类还没有完成初始化就返回
    // Never cache before +initialize is done
    if (!cls->isInitialized()) return;

    // Make sure the entry wasn't added to the cache by some other thread 
    // before we grabbed the cacheUpdateLock.
    //因为有可能其他线程已经抢先把该方法缓存进来，因此这里还需要检查一次缓存，如果cache_t找到该方法，就返回
    if (cache_getImp(cls, sel)) return;
   //通过类对象获取到cache_t
    cache_t *cache = getCache(cls);

    // Use the cache as-is if it is less than 3/4 full
    //拿到散列表中已经缓存方法数并在此基础上+1,看假设存好这个方法后会不会占用空间超过3/4，超过的话就不在这里缓存，二十对散列表进行扩容处理，所以这里自身并没有+1而是看+1后是否超过容量的3/4
    mask_t newOccupied = cache->occupied() + 1;
    //拿到散列表的容量，看散列表可以存储多少个bucket_t结构体
    mask_t capacity = cache->capacity();
    if (cache->isConstantEmptyCache()) {
        // Cache is read-only. Replace it. 如果散列表还没有空间，则为起分配空间
        cache->reallocate(capacity, capacity ?: INIT_CACHE_SIZE);
    }
    else if (newOccupied <= capacity / 4 * 3) {
        // Cache is less than 3/4 full. Use it as-is.
        //如果缓存小于总容量的3/4，则继续使用他
    }
    else {
        // Cache is too full. Expand it.如果大于3/4则进行扩容
        cache->expand();
    }

    // Scan for the first unused slot(位置，狭槽) and insert there.
    // There is guaranteed to be an empty slot because the 
    // minimum size is 4 and we resized at 3/4 full.
    //调用cache->find函数(在find有一个条件是散列表某个索引的数据为空或者key等于当前要找的这个key，则返回这个索引对应对应的方法实现，这个l的作用是看这个key&mask对应的索引是否还有其他内容，没有的话就拿到这个索引方法存储数据，有的话，则判断是否为__x86_64__(x86架构的64拓展向后兼容16位或者32位x86架构)或者__i386__(i386即Intel 80386。其实i386通常被用来作为对Intel（英特尔）32位微处理器的统称)则向上取整，如果为__arm64__则向下取整，有空的话就返回空的bucket_t来存储这方法的key和imp,)
    bucket_t *bucket = cache->find(sel, receiver);
    //拿到了散列表中的一个空位置将散列表中的已经缓存方法数+1
    if (bucket->sel() == 0) cache->incrementOccupied();
    //将要缓存的方法的imp和Key放进去
    bucket->set<Atomic>(sel, imp);
}

```

从上面代码备注我们可以了解到在缓存过程，我们需要经历以下几个步骤:

1.线程上锁，确保线程安全的情况下对方法进行缓存操作。  
2.在系统初始化完成之前，不能进行方法缓存，若当前类还没有完成初始化操作就直接return返回。  
3.其他线程也是已经将当前方法缓存进来，因此需要检查一遍是否已经缓存过该方法，如果之前已经缓存过该方法，则直接返回。  
4.判断散列表容量是否能继续存储该方法，如果超过当前类存储方法散列表内存的3/4，就需要对散列表进行扩容，扩容大小为原来的散列表内存2倍，并且直接扔掉以前缓存的方法，仅缓存当前方法。具体原由后面再详细讲解。如果散列表能够存储下当前方法，则判断是否已经散列表分配空间，如果未分配空间则需要为散列表分配空间。  
5.通过调用`cache->find(sel,receiver)`函数获取适合的内存区域存储`imp`。  
6.判断获取的散列表`SEL`所对应位置是否已经存储有数据了，如果没有存储过数据，则存储数据量+1。  
7.将需要缓存方法存入散列表。  


### 散列表扩容

通过上面步骤流程咱们了解到当散列表存储容量达到3/4以后，再存入新的方法则需要对散列表进行扩容，通过上面方法缓存入口函数可知,系统是调用`cache->expand()`函数来实现扩容的，具体实现可参考Runtime源码

```
//当散列表的空间占用超过3/4的时候，散列表会调用expand()函数进行扩展
void cache_t::expand()
{   //线程安全操作，上锁
    cacheUpdateLock.assertLocked();
    //旧散列表占用的存储空间
    uint32_t oldCapacity = capacity();
    //将新散列表占用的内存空间扩展到老内存空间的2倍
    uint32_t newCapacity = oldCapacity ? oldCapacity*2 : INIT_CACHE_SIZE;

    if ((uint32_t)(mask_t)newCapacity != newCapacity) {
        // mask overflow - can't grow further处理溢出情况
        // fixme this wastes one bit of mask
        newCapacity = oldCapacity;
    }
    //释放旧的内存，开辟新的内存
    reallocate(oldCapacity, newCapacity);
}

```
通过`cache->expand()`函数我们了解到扩容过程实现步骤也有五步：

1.将当前线程上锁，确保线程安全  
2.获取旧的散列表占用空间  
3.将新的散列表占用空间设置为旧散列表的2倍  
4.判断新散列表内存是否存在溢出，如果溢出，则内存还是设置为原来的内存大小  
5.释放旧的散列表，创建新的散列表  

咱们继续查看散列表内存释放函数`cache_t::reallocate(mask_t oldCapacity, mask_t newCapacity)`实现代码如下:

```
void cache_t::reallocate(mask_t oldCapacity, mask_t newCapacity)
{
    bool freeOld = canBeFreed();//这里仅仅判断旧的缓存容量池是否为空，为空则不需要释放

    bucket_t *oldBuckets = buckets();
    bucket_t *newBuckets = allocateBuckets(newCapacity);

    // Cache's old contents are not propagated. 
    // This is thought to save cache memory at the cost of extra cache fills.
    // fixme re-measure this

    assert(newCapacity > 0);
    assert((uintptr_t)(mask_t)(newCapacity-1) == newCapacity-1);

    setBucketsAndMask(newBuckets, newCapacity - 1);
    
    if (freeOld) {
        cache_collect_free(oldBuckets, oldCapacity);
        cache_collect(false);
    }
}

```
从实现代码我们看到新的散列表数组被创建，实际可以存储大小为`newCapacity-1`,旧的散列表最后就会被释放，因为读写操作非常耗时，缓存的目的是节省时间，所以创建新缓存池没有将老的内存copy过来，而且这种操作也会清理掉长时间没有调用的方法。

处理完缓存散列表扩容问题以后，咱们需要关注一下，方法缓存入口函数`cache_fill_nolock(Class cls, SEL sel, IMP imp, id receiver)`内部`cache->find(SEL s, id receiver)`函数，该函数用于查询`SEL`所对应的`bucket`。具体实现函数如下:

```
bucket_t * cache_t::find(SEL s, id receiver)
{
    //当方法选择器为空，则断言打印错误
    assert(s != 0);
    //获取散列表
    bucket_t *b = buckets();
    //获取mask
    mask_t m = mask();
    //通过key找到key在散列表中存储的下标
    mask_t begin = cache_hash(s, m);
    //将下标赋值给i
    mask_t i = begin;
    //这里采用do{}while()并不是全部循环了，如果do{}内部第一次被执行时，如果key和i下标取出的key是对应的，或者key下标对应的方法为空，则直接返回，
    do {
        // 如果下标i中存储的bucket的key==0说明当前没有存储相应的key，将b[i]返回出去进行存储
        // 如果下标i中存储的bucket的key==s，说明当前空间内已经存储了相应key，将b[i]返回出去进行存储
        if (b[i].sel() == 0  ||  b[i].sel() == s) {
            return &b[i];
        }
        //如果都不满足，则调用cache_nex(i,m)去寻找合适的i下标来存储imp
    } while ((i = cache_next(i, m)) != begin);

    
    Class cls = (Class)((uintptr_t)this - offsetof(objc_class, cache));
    cache_t::bad_cache(receiver, (SEL)s, cls);
}

```

`cache->find(SEL s, id receiver)`函数，当存储 `IMP` 之前需要查询散列表数组中的 `bucket_t`,采用 do{}while()只是为了处理 key 值所 对应的`hash`产生碰撞的问题。总结函数实现步骤如下:  
1.获取散列表(Hash表)  
2.获取mask，它是一个uint32_t类型的常量  
3.通过hash函数`cache_hash(s,m)`获取散列表中SEL存储的下标  
4.判断当前下标是否有值，如果没有值则直接返回该位置缓存新加入方法，如果之前如果有值，缓存的方法选择器字符串是否是当前需要缓存的字符串，如果是，则直接返回，如果获取的当前散列表下标对应的位置已经有内容了，则遇到了Hash碰撞，需要采用`cache_next(i,m)`函数获取适合的位置返回存储内容，这里涉及到两个函数,一个是`cache_hash(s,m)`,一个是`cache_next(i,m)`函数。  

```
static inline mask_t cache_hash(SEL sel, mask_t mask) 
{
    return (mask_t)(uintptr_t)sel & mask;
}

```

在拿到key以后,`cache_hash(s,m)`采用SEL按位与mask得到一个小于等于mask的常量，任何一个数值&mask得到的数值最大就是mask。

```
static inline mask_t cache_next(mask_t i, mask_t mask) {
    return (i+1) & mask;
}

```
`cache_next(mask_t i, mask_t mask)`方法内部则判断硬件系统如果是__x86_64__或者__i386系列的产品则向上取整 `-1` ,如果是__arm64__则向下取整 `+1`




### 在Runtime中是如何在消息列表中查找方法的?

注:通过以上讲解，我们知道了OC方法在缓存中查找方法实现的过程，但是如果缓存列表中没有找到相关方法实现，则需要进入方法列表中寻找。那么具体是如何寻找的呢？我们通过打开objc-msg-x86_64.s文件找到一段代码如下：

```
/********************************************************************
 *
 * _objc_msgSend_uncached
 * _objc_msgSend_stret_uncached
 * _objc_msgLookup_uncached
 * _objc_msgLookup_stret_uncached
 *
 * The uncached method lookup.
 *
 ********************************************************************/

    STATIC_ENTRY __objc_msgSend_uncached
    UNWIND __objc_msgSend_uncached, FrameWithNoSaves
    
    // THIS IS NOT A CALLABLE C FUNCTION
    // Out-of-band r10 is the searched class

    // r10 is already the class to search
    MethodTableLookup NORMAL    // r11 = IMP
    jmp *%r11           // goto *imp

    END_ENTRY __objc_msgSend_uncached

    
    STATIC_ENTRY __objc_msgSend_stret_uncached
    UNWIND __objc_msgSend_stret_uncached, FrameWithNoSaves
    
    // THIS IS NOT A CALLABLE C FUNCTION
    // Out-of-band r10 is the searched class

    // r10 is already the class to search
    MethodTableLookup STRET     // r11 = IMP
    jmp *%r11           // goto *imp

    END_ENTRY __objc_msgSend_stret_uncached

    
    STATIC_ENTRY __objc_msgLookup_uncached
    UNWIND __objc_msgLookup_uncached, FrameWithNoSaves

```
从上面我们可以了解到，如果缓存中没有找到方法，则会执行一个宏 `MethodTableLookup STRET` 这个方法可以看到它后面的注释说明它将 `IMP` 函数指针存放到了r11寄存器中，之后再通过jmp%r11 找到`IMP`完成方法调用。`MethodTableLookup`宏函数实现如下:

```
.macro MethodTableLookup

    push    %rbp
    mov %rsp, %rbp
    
    sub $$0x80+8, %rsp      // +8 for alignment

    movdqa  %xmm0, -0x80(%rbp)
    push    %rax            // might be xmm parameter count
    movdqa  %xmm1, -0x70(%rbp)
    push    %a1
    movdqa  %xmm2, -0x60(%rbp)
    push    %a2
    movdqa  %xmm3, -0x50(%rbp)
    push    %a3
    movdqa  %xmm4, -0x40(%rbp)
    push    %a4
    movdqa  %xmm5, -0x30(%rbp)
    push    %a5
    movdqa  %xmm6, -0x20(%rbp)
    push    %a6
    movdqa  %xmm7, -0x10(%rbp)

    // _class_lookupMethodAndLoadCache3(receiver, selector, class)

.if $0 == NORMAL
    // receiver already in a1
    // selector already in a2
.else
    movq    %a2, %a1
    movq    %a3, %a2
.endif
    movq    %r10, %a3
    call    __class_lookupMethodAndLoadCache3

    // IMP is now in %rax
    movq    %rax, %r11

    movdqa  -0x80(%rbp), %xmm0
    pop %a6
    movdqa  -0x70(%rbp), %xmm1
    pop %a5
    movdqa  -0x60(%rbp), %xmm2
    pop %a4
    movdqa  -0x50(%rbp), %xmm3
    pop %a3
    movdqa  -0x40(%rbp), %xmm4
    pop %a2
    movdqa  -0x30(%rbp), %xmm5
    pop %a1
    movdqa  -0x20(%rbp), %xmm6
    pop %rax
    movdqa  -0x10(%rbp), %xmm7

.if $0 == NORMAL
    cmp %r11, %r11      // set eq for nonstret forwarding
.else
    test    %r11, %r11      // set ne for stret forwarding
.endif
    
    leave

.endmacro

```
我们可以观察到宏在内部调用了 `_class_lookupMethodAndLoadCache3()` 函数，而在该函数内部，它又调用了 `lookUpImpOrForward()`函数,在这个函数中，要么找到方法并执行，要么找不到方法，调用消息转发流程，下面咱们来详细讲讲这个函数实现原理。

```
IMP lookUpImpOrForward(Class cls, SEL sel, id inst, 
                       bool initialize, bool cache, bool resolver)
{
    IMP imp = nil;
    bool triedResolver = NO;

    runtimeLock.assertUnlocked();

    // Optimistic cache lookup
    if (cache) {
        imp = cache_getImp(cls, sel);
        if (imp) return imp;
    }

    runtimeLock.lock();
    checkIsKnownClass(cls);

    if (!cls->isRealized()) {
        cls = realizeClassMaybeSwiftAndLeaveLocked(cls, runtimeLock);
        // runtimeLock may have been dropped but is now locked again
    }

    if (initialize && !cls->isInitialized()) {
        cls = initializeAndLeaveLocked(cls, inst, runtimeLock);
    }

 retry:    
    runtimeLock.assertLocked();

    // Try this class's cache.

    imp = cache_getImp(cls, sel);
    if (imp) goto done;

    // Try this class's method lists.
    {
        Method meth = getMethodNoSuper_nolock(cls, sel);
        if (meth) {
            log_and_fill_cache(cls, meth->imp, sel, inst, cls);
            imp = meth->imp;
            goto done;
        }
    }

    // Try superclass caches and method lists.
    {
        unsigned attempts = unreasonableClassCount();
        for (Class curClass = cls->superclass;
             curClass != nil;
             curClass = curClass->superclass)
        {
            // Halt if there is a cycle in the superclass chain.
            if (--attempts == 0) {
                _objc_fatal("Memory corruption in class list.");
            }
            
            // Superclass cache.
            imp = cache_getImp(curClass, sel);
            if (imp) {
                if (imp != (IMP)_objc_msgForward_impcache) {
                    // Found the method in a superclass. Cache it in this class.
                    log_and_fill_cache(cls, imp, sel, inst, curClass);
                    goto done;
                }
                else {
                    // Found a forward:: entry in a superclass.
                    // Stop searching, but don't cache yet; call method 
                    // resolver for this class first.
                    break;
                }
            }
            
            // Superclass method list.
            Method meth = getMethodNoSuper_nolock(curClass, sel);
            if (meth) {
                log_and_fill_cache(cls, meth->imp, sel, inst, curClass);
                imp = meth->imp;
                goto done;
            }
        }
    }

    // No implementation found. Try method resolver once.

    if (resolver  &&  !triedResolver) {
        runtimeLock.unlock();
        resolveMethod(cls, sel, inst);
        runtimeLock.lock();
    }

    // No implementation found, and method resolver didn't help. 
    // Use forwarding.

    imp = (IMP)_objc_msgForward_impcache;
    cache_fill(cls, sel, imp, inst);

 done:
    runtimeLock.unlock();

    return imp;
}

```

上面代码比较长，咱们将主要实现功能罗列如下:

1.Runtime不加锁。  
2.如果存在缓存，则读取缓存内容，因为方法缓存列表内没有找到对应方法实现，所以这一步应该不可能缓存，不过当前函数顶部有一段系统注释 "cache==NO skips optimistic unlocked lookup (but uses cache elsewhere)"讲述了为何需要写上这段代码，因为其他地方会用到缓存。  
3.Runtime加上锁，并且检查Class是否合法。    
4.如果类未加载，则在此刻加载,这里通常是处理懒加载的。  
5.如果需要初始化，但是当前Class并没有初始化，此时需要进行初始化操作。  
6. 再次去缓存中再次查找一遍，如果没有找到则会通过SEL去方法列表查找，并且找到以后存入缓存中。  
7.如果当前类还是找不到方法实现，则会去父类缓存中查找，如果缓存中命中，但是当前类没有该方法，则会将命中的方法实现存入当前类的缓存中，如果父类的缓存中没有，就会去父类的方法列表中查找，如果找到同样存入子类也就是当前类的缓存中。  
8.最后，如果还是没有找到方法，则会执行消息转发流程。   
  
  
咱们接着来看上面去方法列表查找方法实现的入口代码如下：  
```
// Try this class's method lists.
    {
        Method meth = getMethodNoSuper_nolock(cls, sel);
        if (meth) {
            log_and_fill_cache(cls, meth->imp, sel, inst, cls);
            imp = meth->imp;
            goto done;
        }
    }
```
从以上代码我们可以了解到方法列表获取方法是通过'getMethodNoSuper_nolock(cls, sel);'函数来实现的。咱们接下来看一下内部实现代码：  
```
static method_t *
getMethodNoSuper_nolock(Class cls, SEL sel)
{
    runtimeLock.assertLocked();

    assert(cls->isRealized());
    // fixme nil cls? 
    // fixme nil sel?
 //遍历方法，判断方法是否是自己选择的那个
    for (auto mlists = cls->data()->methods.beginLists(), 
              end = cls->data()->methods.endLists(); 
         mlists != end;
         ++mlists)
    {
        method_t *m = search_method_list(*mlists, sel);
        if (m) return m;
    }

    return nil;
}
```
总结流程如下：  
1.先通过runtime上锁。  
2.如果没有没有初始化类，则直接断言崩溃。  
3.for循环取出方法method结构体，判断是否是sel对应的method。如果是,则直接范围。  
4.如果没有找到则直接返回nil。  

接下来我们看一下'search_method_list(*mlists, sel);'函数内部是如何通过sel找到method：  
```
static method_t *search_method_list(const method_list_t *mlist, SEL sel)
{
    int methodListIsFixedUp = mlist->isFixedUp();是否排序好的
    int methodListHasExpectedSize = mlist->entsize() == sizeof(method_t);//获取方法列表size
    
    if (__builtin_expect(methodListIsFixedUp && methodListHasExpectedSize, 1)) {
        return findMethodInSortedMethodList(sel, mlist);
    } else {
        // Linear search of unsorted method list
        for (auto& meth : *mlist) {
            if (meth.name == sel) return &meth;
        }
    }
```
  
  
  
总结流程如下：  
1.先通过isFixedUp()函数判断是否方法列表是已经编译阶段就排序好的。
2.获取方法列表的size大小
3.通过__builtin_expect指令，优化执行逻辑，CPU是流水线方式实现的，即取指->执行->输出结果，第一条指令在执行的过程中，第二条指令可能已经完成了取指。但是如果第一条执行的执行结果使得程序发生了跳转，取到的第二条指令相当于做了无用功。因为此时要执行跳转位置的指令。使用__builtin_expect指令，如LIKELY宏，是告诉CPU X的值更大概率是1。在执行下一次取指操作的时候，执行结果是1成立的情况下的指令。这样减少了CPU做无用功的次数，提高执行效率。这里是如果方法列表已经排序好的，并且方法列表size大小已经获取到，就会去已存在的方法列表中通过'findMethodInSortedMethodList(sel, mlist);'函数二分查找更加快速查找到对应method结构体。  
4.如果方法列表没排序好，并且方法列表size大小无法获取到，则直接遍历方法列表。判断sel是否等于name,找到对应的method结构体。  

通过上面我们知道已经排好序的方法列表会通过二分查找的形式进行method结构体寻找，我们进入'findMethodInSortedMethodList(sel, mlist);'函数内部看一下实现过程。  

```
static method_t *findMethodInSortedMethodList(SEL key, const method_list_t *list)
{
    assert(list);
    //拿到第一个method结构体
    const method_t * const first = &list->first;
    const method_t *base = first;
    const method_t *probe;//折半位置的method结构体
    uintptr_t keyValue = (uintptr_t)key;
    uint32_t count;
    
    for (count = list->count; count != 0; count >>= 1) {
        probe = base + (count >> 1);
        
        uintptr_t probeValue = (uintptr_t)probe->name;
        
        if (keyValue == probeValue) {
            // `probe` is a match.
            // Rewind looking for the *first* occurrence of this value.
            // This is required for correct category overrides.
            while (probe > first && keyValue == (uintptr_t)probe[-1].name) {
                probe--;
            }
            return (method_t *)probe;
        }
        
        if (keyValue > probeValue) {
            base = probe + 1;
            count--;
        }
    }
    
    return nil;
}
```  
  
总结流程如下：  
1.首先断言判断方法列表是否为空，如果为空，则直接崩溃。
2.通过递减的形式进行for循环，count>>=1，相当于每循环一次除2。
3.probe 先取一半的位置的mehtod的name判断是否为需要寻找的method结构体。
4.如果是需要找的结构体，还得考虑分类添加的跟本类同样方法时的情况。
5.如果分类也添加了跟本类同样的方法，那么分类的方法一定是排在本类方法前面的，而且这里是已经排序好的方法，那么相同的方法肯定会被排序到相邻位置。所以通过while循环判断数组上一个位置method的name是否也是跟keyValue相同，如果相同则是分类添加的方法，而且开发者可能同时添加了多个跟本类一样的方法在不同的分类，这里只需要遍历找到最前面那个匹配的method结构体，就是我们需要寻找的method，再直接返回即可。
6.当keyValue位置大于一半的时候，则直接把base = probe +1 ，通过后一半数据进行比较，最终找出匹配的method结构体。  

通过上面代码，我们了解到方法列表在编译器有可能优化以后，会对方法列表进行排序，那么方法列表是通过什么方式来进行排序的呢？咱们接着来探索。  


```
static void 
prepareMethodLists(Class cls, method_list_t **addedLists, int addedCount, 
                   bool baseMethods, bool methodsFromBundle)
{

    for (int i = 0; i < addedCount; i++) {
        method_list_t *mlist = addedLists[i];
        assert(mlist);

        // 如果没有排序
        if (!mlist->isFixedUp()) {
            fixupMethodList(mlist, methodsFromBundle, true/*sort*/);
        }
    }
}
```
接着咱们进入'fixupMethodList(mlist, methodsFromBundle, true/*sort*/);'函数内部查看实现过程：  

```
static void 
fixupMethodList(method_list_t *mlist, bool bundleCopy, bool sort)
{ 
    //为方便查看，仅保留关键代码  
    for (auto& meth : *mlist) {
        const char *name = sel_cname(meth.name);
        
        SEL sel = sel_registerNameNoLock(name, bundleCopy);
        meth.name = sel;
        
        if (ignoreSelector(sel)) {
            meth.imp = (IMP)&_objc_ignored_method;
        }
    }
     
     //根据地址排序
    if (sort) {
        method_t::SortBySELAddress sorter;
        std::stable_sort(mlist->begin(), mlist->end(), sorter);
    }
    
    //标记方法列表已经被统一排序
    mlist->setFixedUp();
}
```
经过这里，我们大概已经知道是通过方法名地址来排序的，我们进去看一下排序的实现：  
```
struct method_t {
    SEL name;
    const char *types;
    IMP imp;

    struct SortBySELAddress :
        public std::binary_function<const method_t&,
                                    const method_t&, bool>
    {
        bool operator() (const method_t& lhs,
                         const method_t& rhs)
        { return lhs.name < rhs.name; }
    };
};
```
通过这里我们看到，其实地址比较的方法是放在method结构体内部实现的。可以清晰的看到，他们是通过地址比较来进行的排序。  
  


### Runtime在项目中的运用

1.消息转发 当需要动态指定某一个对象来实现某一个方法  
2.方法交换。用户埋点的时候，写一个工具实现方法交换 添加 `VC` 分类，`load` 中把系统方法 替换。  
3.字典转模型 `YYModel`。  
4.`KVO` 实现。  
5.处理崩溃(NSDictionary, NSMutableDictionary, NSArray, NSMutableArray 的处理) 在开发过程中， 有时候会出现 set object for key 的时候 object 为 Nil 或者 Key 为 Nil， 又或 者初始化array, dic的时候由于数据个数与指定的长度不一致造成崩溃。此时利用runtime 对异常情况进行捕捉，提前 return 或者抛弃多余的长度。  
6.通过写这些对象的分类，在 `load` 中交换方法 处理按钮的重复点击方法交换。  



### Class继承链关系    

> 假如现在我们有一个继承链  A->B->C->NSObject, A * a = [[A alloc]init]; 那么这里实例对象 'a' 的父类是谁？ 类对象A的父类又是谁？     

为了验证上面的结果，我们建立了一个Model类继承自Father类，Father类继承自NSObject,我们打印看看他们的地址  
```
Model *a = [[Model alloc]init];  
NSLog(@"小a的父类:%@，地址:%p",[a superclass],[a superclass]);  
NSLog(@"Model的父类:%@，地址:%p",[Model superclass],[Model superclass]);  
```
打印结果如下:  

```
2020-11-20 10:31:41.655137+0800 AAATest[2007:90242] 小a的父类:Father，地址:0x101e27570  
2020-11-20 10:31:41.655308+0800 AAATest[2007:90242] Model的父类:Father，地址:0x101e27570  
```
通过结果我们可以知道看到a实例对象的父类和Model类对象的父类都是Father  

> 那么我们再次思考 a 的isa 指针是指向Model的，那么Model的isa指针指向的是Model的元类，那么Model的元类的父类又是谁呢？  

接下来我们为了充分的验证，我们分别打印Model的元类，Model的元类的父类，Father的元类，Father的元类的父类，NSObject的元类，NSObject元类的元类，NSObject的元类的父类
```
NSLog(@"Model的地址:%p",[Model class]);  
Class clazz = objc_getMetaClass(NSStringFromClass([Model class]).UTF8String);  
NSLog(@"Model的元类:%@，地址:%p",clazz,clazz);  
NSLog(@"Model的元类的父类:%p",objc_getMetaClass(NSStringFromClass([clazz superclass]).UTF8String));  
Class fatherClazz = objc_getMetaClass(NSStringFromClass([Father class]).UTF8String);  
NSLog(@"Father的地址:%p，Father的元类地址:%p",[Father class],fatherClazz);  
NSLog(@"Father的元类的父类的地址:%p",[fatherClazz superclass]);  
Class objctClass = objc_getMetaClass(NSStringFromClass([NSObject class]).UTF8String);  
NSLog(@"NSObject的元类地址:%p,NSobject的地址:%p",objctClass,[NSObject class]);  
NSLog(@"NSObject的元类的元类地址:%p",objc_getMetaClass(NSStringFromClass([objctClass class]).UTF8String));  
NSLog(@"NSObject的元类的父类地址:%p",[objctClass superclass]);  
NSLog(@"NSObject的父类地址:%p",[NSObject superclass]);  
```
打印结果如下:  
```
2020-11-20 11:19:18.887960+0800 AAATest[2691:147165] Model的地址:0x105eae658
2020-11-20 11:19:18.888548+0800 AAATest[2691:147165] Model的元类:Model，地址:0x105eae630
2020-11-20 11:19:18.888779+0800 AAATest[2691:147165] Model的元类的父类:0x105eae540
2020-11-20 11:19:18.889115+0800 AAATest[2691:147165] Father的地址:0x105eae568，Father的元类地址:0x105eae540
2020-11-20 11:19:18.889451+0800 AAATest[2691:147165] Father的元类的父类的地址:0x10678b1d8
2020-11-20 11:19:18.890022+0800 AAATest[2691:147165] NSObject的元类地址:0x10678b1d8,NSobject的地址:0x10678b200
2020-11-20 11:19:18.890173+0800 AAATest[2691:147165] NSObject的元类的元类地址:0x10678b1d8
2020-11-20 11:19:18.890776+0800 AAATest[2691:147165] NSObject的元类的父类地址:0x10678b200
2020-11-20 11:46:56.007279+0800 AAATest[4208:196636] NSObject的父类地址:0x0
```
通过打印结果，我们发现Model的元类是一个单独的内存地址，Model的元类的父类就是Father的元类，而因为Father是继承自NSObject的，Father的元类的父类就是NSObject的元类，而NSObject的元类的元类是指向NSObject元类的，也就是说NSObject的元类就是NSobject元类本身，而NSObject元类的父类就是NSObject本身， NSObject的父类是nil。  

具体的继承关系图如下：  

<div align= center>
<img src = "http://brandonliu.pub/class-diagram.jpg"/>
</div>


该图咱们在讲解class类结构的时候已经分析过。  



### 以上代码打印结果是什么    

有以下代码，它们执行以后打印结果是怎么样的？为什么？  

```
#import "ViewController.h"  

@interface NSObject (objc)  

+ (void)funTest;  

@end  
@implementation NSObject (objc)

-(void)funTest {
    NSLog(@"this is function test");
}

@end
@interface ViewController ()

@end

@implementation ViewController
- (void)viewDidLoad {
    [super viewDidLoad];
    [NSObject funTest];
    NSObject *objc = [NSObject new];
    [objc funTest];
}

@end
```
以上代码运行结果如下:
```
2020-12-07 17:26:26.718361+0800 AAATest[5920:304985] this is function test  
2020-12-07 17:26:26.718559+0800 AAATest[5920:304985] this is function test  
```
这里我们观察到NSObject的 ’funTest‘ 类方法并没有方法的实现，为何最终调用了实例方法呢？咱们来一步步分析。  

> NSObject的类方法是存储在NSObject的元类中的  
> NSObject的元类中并没有 ’funTest‘ 类方法  
> NSObject的元类中找不到类方法实现的时候，就需要去NSObject元类的父类中寻找  
> NSObject的元类的父类指向的是NSObject类对象  
> 而咱们 objc 这个NSObject的实例对象的实例方法也是在NSObject类对象中寻找的  
> 在咱们NSObject类对象中方法是存放在专门的hash散列表中，通过sel作为key，可以获取到对象的imp方法函数指针  
> 而这里咱们的类方法和实例方法的方法名是一样的，所以找到的imp就是实例方法的imp  

因此，上面的代码类方法和实例方法打印结果是一样的    

这里我们猜想一下，假设上面是一个继承自NSObject的Model类，添加同样的方法和实现，最后结果又是怎么样的呢？    

我们再次来整理一下整个查找过程如下:    
> Model中类方法是存储在Model的元类中的  
> Model的元类中并没有 ’funTest‘ 类方法的实现imp  
> Model的元类找不到的话就会去Model的元类的父类中寻找  
> Model的元类的父类指向的是NSObject的元类(根元类)  
> 而NSObject根元类中也没有 'funTest' 类方法  
> 这个时候就需要去NSObject根元类的父类中寻找  
> 而NSObject的根元类的父类又是指向的NSObject类对象本身  
> 而NSObject类对象中并没有 'funTest' 类方法的实现，所以程序会直接崩溃  

因此，如果是Model中同样代码，则会造成整个程序直接崩溃，都无法执行到实例方法的执行。  

### RunLoop和屏幕点击事件传递链以及响应链关系


在讲解RunLoop和屏幕点击事件传递链以及响应链关系之前，我们先来看一下下面这张图:

<div align= center>
<img src = "http://brandonliu.pub/runloop.png"/>
</div>

通过上图，我们可以总结屏幕点击触发流程如下：

> 1.手指点击屏幕，传感器获取到信号，在内部由 `IOKit.framework` 框架将点击电信号封装成IOHIDEvent事件  
> 2.`springboard` 桌面操作系统接收事件，并通过 `mach port` 端口转发（PIC进程间通信）将 `IOHIDEvent` 事件传递给主线程处理  
> 3.主线程 RunLoop 此时注册的`source1`(专门处理系统级事件)回调被触发，然后`source1`通过内部将信息转发给了`source0`处理(专门处理应用内事件)  
> 4.然后事件被传递到UIApplication  
> 5.通过UIApplication触发`sendEvent`事件转发消息，将消息扔给UIWindow  
> 6.UIWindow通过调用 `hitTest:withEvent` 和 `pointInside:withEvent` 层层传递将事件传递给能够响应的控件  
> 7.系统判断找到的控件是否能够响应该事件，如果能响应则走响应流程，如果不能响应则采用回溯方法，寻找能够响应该事件的控件  
> 8.如果在回溯过程中找到能响应该事件的控件则进行响应，如果事件回溯到`UIApplication`还是没能找到响应该事件的控件，则直接丢弃事件  


在寻找能够响应该事件的控件过程中有两个方法被频繁的调用了:

```
// 先判断点是否在View内部，然后遍历subViews
- (nullable UIView *)hitTest:(CGPoint)point withEvent:(nullable UIEvent *)event;  
//判断点是否在这个View内部
- (BOOL)pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event; 

```
具体搜寻过程就是系统通过遍历屏幕范围内的view(注：如果遇到view内部还有subview，则会采用倒序遍历方法，加快遍历的速度)。然后调用 `hitTest:withEvent:` 判断屏幕点击事件是否在该view内部，实现流程如下:

> 1.判断该层级是否能够响应事件，包括透明度是否大于0.01,是否用户交互事件为YES，是否隐藏了当前view  
> 2.判断该点是否在当前view范围内。具体是通过调用 `pointInside:withEvent:`来实现  
> 3.如果存在则遍历子view，直到找到被点击的view，如果该view能够响应事件则由该view执行响应过程，如果不能响应则调用 `nextResponder` 方法将事件传递给下一个响应者来响应  




