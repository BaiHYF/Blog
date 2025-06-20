#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet V",
  desc: [并行计算课程考试前的一些总结. Ch4 part2],
  date: "2025-06-21",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

== 缓存一致性[Cache Coherence]
缓存一致性是指在多处理器系统中，当多个处理器核心拥
有自己的缓存时，如何确保它们共享数据的一致性.

缓存一致性问题的本质是由于每个核心的缓存是独立的
- 如果一个核心修改了某些数据，并将其写入其自己的缓存行，
  那么其他核心的缓存行可能仍然包含旧的数据。
- 如果这些其他核心继续基于这个旧数据执行操作，就会导致
  错误的结果。

当不同处理器缓存了同一内存位置的数据副本时，对这些
副本的更新必须传播到所有其他缓存，以保持数据一致性.

#figure(
  image("../../public/blog-resources/image-53.png"),
  caption: [
    缓存一致性例子

    假设有一个多核处理器的系统，其中有两个核心，A和B，
    它们共享一个内存块。这个内存块包含一个变量 x。
  ],
)

== 伪共享[False Sharing]
False-sharing是一种在多核处理器系统中出现的性能问题
- 多个线程访问看似不同的变量，但实际上这些变量位于同一个缓存行。
- 在多核处理器中，每个核心都有自己的缓存，但是，当一个线程
  更新了一个变量，它可能会导致整个缓存行被刷新到主内存，这
  会影响到访问该缓存行中其他变量的其他线程

例子
```cpp
public class FalseSharingExample {
  private final int[] array = new int[1024];

  public void thread1() {
    for (int i = 0; i < 1024; i++) {
      array[i] = i;
    }
  }

  public void thread2() {
    for (int i = 0; i < 1024; i++) {
      array[i] += 1;
    }
  }
}
```
在上面的代码中，两个线程thread1和thread2都在更新同一个数组的不同元素。
尽管它们看似在更新不同的变量，但由于数组元素位于同一个缓存行，
线程thread2的更新可能会导致线程thread1的缓存行被刷新到主内存，这会导致性能下降。

== 线程安全[Thread Safety]
线程安全（Thread Safety）指在多线程环境下，程序或数
据结构能够正确、一致地工作，而不会因并发访问导致数
据损坏、逻辑错误或不可预测的行为。

- 选用线程安全的函数
- 互斥锁：确保同一时间只有一个线程能访问共享资源
- 原子操作：确保操作不可分割
- 局部存储：让每个线程拥有独立的变量副本，避免共享数据
...

== Conclusions
- A thread in shared-memory programming is analogous to a process in distributed memory programming. However, a thread is often lighter-weight than a full-fledged process.
- In Pthreads programs, all the threads have access to _global variables_, while _local variables_ usually are private to the thread running the function.
- When indeterminacy results from multiple threads attempting to access a shared resource, the accesses can result in an error, and we have a _race condition_
- A _critical section_ is a block of code that updates a shared resource that can only be updated by one thread at a time. So the execution of code in a critical section should, effectively, be executed as serial code.
- _Busy-waiting_ can be used to avoid conflicting access to critical sections with a flag variable and a while loop with an empty body. But it can be very wasteful of CPU cycles. It can also be unreliable if compiler optimization is turned on.
- A _mutex_ can be used to avoid conflicting access to critical sections as well. Think of it as a _lock_ on a critical section, since mutexes arrange for mutually exclusive access to a critical section.
- A _semaphore_ is the third way to avoid conflicting access to critical sections. It is an unsigned int together with two operations: `sem_wait` and `sem_post`. Semaphores are more powerful than mutexes since they can be initialized to any nonnegative value.
- A _barrier_ is a point in a program at which the threads block until all of the threads have reached it.
- A _read-write lock_ is used when it’s safe for multiple threads to simultaneously read a data structure, but if a thread needs to write to the data structure, then only that thread can access the data structure during the modification.
- Some C functions cache data between calls by declaring variables to be static, causing errors when multiple threads call the function. This type of function is not thread-safe.
