
#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet I",
  desc: [并行计算课程考试前的一些总结. Ch1 Ch2],
  date: "2025-06-20",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

= Ch01-Introduction

Task parallelism[任务并行]
- Partitionvarious tasks carried out solving the problem among the cores 任务并行是指将不同的任务或执行线程分配到多个核心上。

Data parallelism[数据并行]
- Partition the data used in solving gthe problem among the cores.数据并行是指在多个核心上对不同部分的数据执行相同的操作。
- Eachcore carries out similaroperations on it's part of the data.

Parallel Computing vs. Concurrent Computing [并行vs并发]
+ In parallel computing, execution occurs at the same physical instant
  - parallel computing is impossible on a (one-core) single processor
  - 在多个处理器或核心上同时执行多个计算任务。需要多核或多处理器系统。
+ concurrent computing consists of process lifetimes overlapping, but execution need not happen at the same instant
  - concurrent processes can be executed on one core by interleaving the execution steps of each process via timesharing slices
  - 多个计算任务同时处于进行中，但不一定同时执行。
  - 通过时间片轮转在单核处理器上交错执行。

= Ch02-Parallel Hardware and Software

== Parallel Hardware
这一环节主要是复习计组和操作系统的内容。以及其他一些有关并行的基本概念。

- Main Memory 主存
- CPU
  - Register
  - Program Counter
  - Bus
- Core 核
  + A core is usually the basic computation unit of the CPU
  + A CPU may have one or more cores to perform tasks at a given time.
- Processor 处理器: A processor is a generic term used to describe any sort of CPU, regardless of cores.
- Process 进程 ： An instance of a computer program that is being executed.
- Time Slice Concurrency 时间片轮转
- Thread 线程
  + Threads are contained within processes.
  + They allow programmers to divide their programs into (more or less) independent tasks.
  + The hope is that when one thread blocks because it is waiting on a resource, another will have work to do and can run.
- Thread forking and Thread Joining : 线程的产生和终止
- Cache 缓存
- Spatial locality 空间局部性 : accessing a nearby location.
- Temporal locality 时间局部性 : accessing in the near future.
- Cache 写策略
  + Write-through 写直达 : caches handle the write issues by updating the data in main memory at the time it is written to cache.
  + Write-back 写回 : mark data in the cache as dirty. When the cache line is replaced by a new cache line from memory, the dirty line is written to memory.
- Cache Mapping 缓存映射
  + Full associative: a new line can be placed at any location in the cache.
  + Direct mapped: each cache line has a unique location in the cache to which it will be assigned.
  + n-way Set associative: each cache line can be placed in one of n different locations in the cache.
- Virtual Memory 虚拟内存: Virtual memory functions as a cache for secondary storage. 即可以理解为主存的Cache
- Pages 页: blocks of data and instructions.
- Page Table 页表
- TLB Translation Lookaside Buffer 快表：可以理解为页表的Cache
- Instruction Level Parallelism (ILP)
  - Attempts to improve processor performance by having multiple processor components or functional units simultaneously executing instructions.
  - 即CPU同时执行多个指令，如流水线技术。

```
Q: Can a single process run in multiple cores?
A: Yes, a single process can run multiple threads on different cores.

Q: Can a single thread run in multiple cores?
A: No. There is no such thing as a single thread running on multiple cores simultaneously.
But the instructions from one thread can be executed in parallel
(e.g. Instruction pipelining and out-of-order execution).
```

== 重点-并行体系结构分类-弗林分类法
+ SISD: 单指令流单数据流
  - 传统的串行冯诺依曼机
  - 支持数据集并行
+ SIMD: 单指令流多数据流
  - 向量计算机，阵列计算机
+ MISD: 多指令流单数据流
  - 略
+ MIMD: 多指令流多数据流
  - 目前最广泛使用
  - 每个处理器都有自己的指令流，也可以和其他处理器共享指令流，对自己的数据进行处理
  - 超算、计算机集群、分布式系统、多处理器计算机和多核计算机都划分为这种类型。
+ SIMT: 单指令流多线程
  - 将SIMD与多线程结合在一起,广泛应用于GPU上的计算单元中
  - 向量中元素相互之间可以自由通信
  - 每个线程的寄存器都是私有的,SIMT线程之间只能通过共享内存和同步机制进行通信

#figure(
  image("../../public/blog-resources/image-47.png"),
  caption: "Flin's classification of parallel systems",
)

#figure(
  image("../../public/blog-resources/image-48.png"),
  caption: "GPU architecture",
)

```
Q: SIMD与SIMT有什么区别?
A:
  SIMD中所有处理单元同步执行同一指令，操作不同数据元素，适合规则数据并行处理。
  SIMT中多个线程同时执行同一指令，但每个线程可独立处理不同数据，适合不规则数据并行处理。
  两者都旨在提高并行计算效率，SIMT可视为SIMD的扩展，支持更复杂控制流和分支操作
```

== 内存系统

=== 共享式内存系统
集中共享式内存,又称一致存储访问系统(UMA)
+ 有一个存储器被所有处理器均匀共享(以及共享缓存)
+ 所有处理器访问共享的存储器的延迟相同
+ 每个处理器可以拥有私有内存或高速缓存

分布式共享内存系统，又称非一致存储访问系统(NUMA)
+ 每个处理器都拥有自己的存储器，也可以访问其他节点的存储器
+ 每个结点访问本地内存和访问其它结点的远程内存的延迟是不同的
+ 所有的处理器都能访问一个单一的地址空间
+ 能使用LOAD和STORE指令访问远程内存
+ 访问远程内存比访问本地内存延迟要高
+ 每个处理器可以使用高速缓存

目前几乎所有的多核心多处理器系统都使用了分布式存储器

=== 分布式内存系统
在这种计算机体系结构中，每台计算机使用消息机制（如以太网）
连接起来。每台计算机都有自己的处理器，每个处理器都有自己的私有内存，
私有内存只提供自己的处理器进行访问。其他的计算机不能直接访问，每个计算机都有自己独立的物理地址
空间。

大规模并行处理器系统(MPP)
+ MPP系统是由成百上千台计算机组成的大规模并行计算机系统
+ 般开发困难，价格高，市场有限
+ MPP中一般每个节点可以认为是一个没有硬盘的计算机
+ MPP节点一般只驻留操作系统内核，由一条I/O总线连接到同一个硬盘上面
+ 一般使用制造商专有的定制高速通信网络

工作站机群系统(COW, Cluster Of Workstations)
+ COW系统是由大量的家用计算机或者工作站通过商用网络连接在一起而构成的多计算机系统。
+ COW中每个节点都可以认为是一台独立的计算机，它们有自己的硬盘、CPU、存储器等，在商用网络的协作下组成一个工作站机群系统。
- 如大公司的数据中心

#quote([根据2018年6月全球超级计算机排行榜Top500名单中，有437台超算
  采用的是COW架构，另外63台采用的是MPP架构。])

```
Q: MPP和COW有何区别？
A:
  1. MPP中节点高度集成，专为并行计算设计，通常没有独立操作系统，依赖全局调度和管理系统。
  2. COW中节点完全独立，各自运行操作系统和应用程序，节点间通过消息传递（如MPI）通信。
  3. MPP使用专用高速互联网络（如InfiniBand），延迟低、带宽高，适合大规模并行计算。
  4. COW使用标准网络（如以太网），延迟较高、带宽较低，适合松散耦合任务。
```
