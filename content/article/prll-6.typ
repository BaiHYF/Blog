
#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet V",
  desc: [并行计算课程考试前的一些总结. Ch5],
  date: "2025-06-22",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

= Ch5-OpenMP

open multiprocessing[OpenMP]

#figure(
  image("../../public/blog-resources/image-54.png"),
  caption: [OpenMP与Pthread对比],
)

OpenMP将系统抽象为一系列的能访问主存的CPU(核心)

例子:OpenMP Hellpp World程序
```c
#include <omp.h>

void Hello(void);

int main(int argc, char **argv) {
  int thread_count = strtol(argv[1], NULL, 10);

  # pragma omp parallel num_threads(thread_count)
  {
    Hello();
  }

  return 0;
}

void Hello(void) {
  int thread_id = omp_get_thread_num();
  int thread_count = omp_get_num_threads();

  printf("Hello from thread %d of %d\n", thread_id, thread_count);
}
```

一些OpenMP指令(Directives)
- `# pragma omp parallel`
  创建一个并行区域,并行执行的线程数量由系统决定
- `# pragma omp parallel num_threads(thread_count)`
  创建一个并行区域，并指定并行执行的线程数

== OpenMP中的临界区

- `# pragma omp critical`
  创建一个临界区,临界区中的代码同时只能有一个线程执行

例子:计算全局和
```c
void Calculate_global_sum(int* global_sum_p) {
  int my_rank = omp_get_thread_num();
  int thread_count = omp_get_num_threads();

  int local_sum = get_local_sum(...);

  # pragma omp critical {
    *global_sum_p += local_sum;
  }
}

int main(int argc, char **argv) {
  int* global_sum_p = malloc(sizeof(int));
  *global_sum_p = 0;

  # pragma omp parallel
  {
    Calculate_global_sum(global_sum_p);
  }

  printf("The global sum is %d\n", *global_sum_p);
  free(global_sum_p);
}
```
代码中对global_sum_p的修改是临界区中的代码，多个线程不能同时修改global_sum_p,保证了计算的正确性。

其他一些有关临界区的操作


- `#pragma omp critical(name)`
  创建一个临界区，并指定临界区的名称.
  两个不同名字的临界区可以被多个线程同时访问。
- `#pragma omp atomic`
  创建一个原子操作，保证变量的修改是原子的。
  原子操作的形式必须为`x op= y`或`x++, x--, ++x, --x`
- `pragma omp barrier`
  阻塞当前线程,线程等待所有线程执行完毕
- `lock`
  `omp_set_lock(lock_p)`与`omp_unset_lock(lock_p)`


== OpenMP中变量的作用域[Scope]

一般我们谈作用域时，我们指的是变量能被访问到的范围。

在OpenMP中，变量的作用域指在并行区域内，能访问到该变量的_线程_。

Shared Scope: A variable that can be accessed by all the threads in the team has shared scope.

Private Scope: A variable that can only be accessed by a single thread has private scope.

The default scope for variables declared before a parallel block is shared.

== 规约子句[Reduction]

A reduction is a computation that repeatedly applies the same reduction operator to a sequence of operands in order to get a single result.

- `#pragma omp parallel ... reduction(operator: variable)`
  - operator: +, -, \*, &, ||, ^, |, &&, min, max
  - variable: 需要reduction的变量

在reduction子句中，每个线程的私有变量副本的初始值由归约操作符的类型决定
- +,|| ==> 0
- \*, && ==> 1
- min ==> 该数据类型的最小可能值(如INT_MIN for int)
- max ==> 该数据类型的最大可能值(如INT_MAX for int)

我们可以使用Reduction子句来优化上面例子中的临界区代码。
```c
int main(int argc, char **argv) {
  int* global_sum_p = malloc(sizeof(int));
  *global_sum_p = 0;

  # pragma omp parallel reduction(+: *global_sum_p)
  {
    *global_sum_p += get_local_sum(...);
  }

  printf("The global sum is %d\n", *global_sum_p);
  free(global_sum_p);
}
```
- 上面的代码中，每个线程的_私有的_`*global_sum_p`会被初始化为0
- 在并行区域内，各个线程操作自己的副本
- 退出并行区域时，所有线程的副本通过加法合并，结果再与主线程的`*global_sum_p`原始值相加

== Parallel For
Forks a team of threads to execute the following structured block.
However, the structured block following the `parallel for` directive must be a `for` loop.
Furthermore, with the `parallel for` directive the system parallelizes the `for` loop by dividing the iterations of the loop among the threads.

例子：多线程估算$pi$
```c
int main() {
  double pi = 0.0;
  int N = 10000;

  # pragma omp parallel for reduction(+: pi) private(factor) {
    for (int i = 0; i < N; i++) {
      factor = (i % 2 == 0) ? 1.0 : -1.0;
      pi += factor / (2 * i + 1);
    }
  }

  pi *= 4.0;
  printf("pi is approximately %.16f\n", pi);
}
```
这里显示规定`factor`的作用域为private，每个`factor`都是线程私有的。

== OpenMP中的循环调度策略

- `schedule(type, chunk_size)`
  - type: static, dynamic/guided, auto, runtime
  - The iterations are also broken up into chunks of chunksize.


+ `static`静态调度
  the iterations can be assigned to the threads befo re the loop is executed
  ```
  假设有12次循环，以及三个线程
  ----------------------------
  schedule(static, 1) 得到
  Thread 1: 0,3,6,9
  Thread 2: 1,4,7,10
  Thread 3: 2,5,8,11
  ----------------------------
  schedule(static, 2) 得到
  Thread 1: 0,1,6,7
  Thread 2: 2,3,8,9
  Thread 3: 4,5,10,11
    ----------------------------
  schedule(static, 4) 得到
  Thread 1: 0,1,2,3
  Thread 2: 4,5,6,7
  Thread 3: 8,9,10,11
  ```
+ `dynamic/guided`动态调度
  the iterations are assigned to the threads while the loop is executing.
  Each thread executes a chunk, and when a thread finishes a chunk, it requests another one from the run-time system.
  This continues until all the iterations are completed.
  In a `guided` schedule, as chunks are completed, the size of the new chunks decreases.
  即每个线程执行完当前的一轮循环，才会获取下一轮的要被执行的循环。
+ `auto`自动调度
  the compiler and/or the run-time system determine the schedule
+ `runtime`运行时调度
  根据环境变量`OMP_SCHEDULE`来决定调度的方式(上面几种之一)

#figure(
  image("../../public/blog-resources/image-55.png"),
  caption: [几种调度方式对比],
)

== Conclusions

- OpenMP is a standard for programming shared memory systems.
- OpenMP uses both special functions and preprocessor directives called `pragmas`.
- OpenMP programs start multiple threads rather than multiple processes.
- Many OpenMP directives can be modified by _clauses_.
- A major problem in the development of shared memory programs is the possibility of _race conditions_.
- OpenMP provides several mechanisms for insuring mutual exclusion in critical sections.(Critical directives, Named critical directives, Atomic directives, Locks)
- By default most systems use a block-partitioning of the iterations in a parallelized for loop.
- OpenMP offers a variety of scheduling options.
- In OpenMP the _scope_ of a variable is the collection of threads to which the variable is accessible.
- A _reduction_ is a computation that repeatedly applies the same reduction operator to a sequence of operands in order to get a single result.
