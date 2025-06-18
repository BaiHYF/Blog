#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet II",
  desc: [并行计算课程考试前的一些总结. Ch2],
  date: "2025-06-21",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

= Ch02-Parallel Hardware and Software

== Interconnection Network[ICN]

== Parallel Software
SPMD编程模式:single program multiple data

多个处理器同时执行相同的程序，但通过条件语句执行不同的代码。

```
if (I'm thread process i) {
  do this;
} else if (I'm thread process j) {
  do that;
} else {
  do something else;
}
...
```

不确定性：多线程并行程序执行时结果存在不确定性
+ Reason1 -- 多个线程对共享资源的访问顺序不确定，导致结果依赖于线程执行顺序(Race Condition)
+ Reason2 -- 多个线程同时读写共享数据时，如果没有同步机制（如锁、信号量），可能导致数据不一致


Shared Memory
- Dynamic threads:Master thread waits for work, forks new threads, and when threads are done, they terminate
- Static threads:Pool of threads are created and allocated work, but do not terminate until cleanup.

加速比:

$p$ -- 线程数/核心数

$T_("serial")$ -- 原串行程序运行时间

$T_("parallel")$ -- 并行化后程序运行时间

$T_("parallel") = T_("serial") / p$

加速比 $S = T_("serial") / T_("parallel")$
并行效率 $E = S / p$

Amdahl定律: Unless virtually all of a serial program is parallelized, the possible speedup is going to be very limited, regardless of the number of cores available.

可扩展性:
+ 强可扩展性Strongly Scalable
  - 在问题规模（即任务大小）固定的情况下，通过增加计算资源（如处理器数量）来缩短计算时间
  - Key: 问题规模不变，资源增加，计算时间减少。
  - 关注增加资源加速计算
+ 弱可扩展性Weakly Scalable
  - 在增加计算资源的同时，问题规模也按比例增加，目标是保持每个处理器的负载不变，计算时间基本稳定。
  - Key: 问题规模与资源同步增加，计算时间不变。
  - 关注在资源增加时能处理更大规模的问题，保持效率不变

== 并行程序设计

Foster设计方法:
+ Partitioning 将问题划分为更细小的子任务
+ Communication 设计线程之间的通信方式
+ Agglomeration 设计将之前划分得到的子任务合并
+ Mapping 将子任务映射到线程(处理器)
