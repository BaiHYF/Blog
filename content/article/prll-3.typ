#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet III",
  desc: [并行计算课程考试前的一些总结. Ch3],
  date: "2025-06-21",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

= Ch03-MPI
MPI的全称是Message Passing Interface，即消息传递接口.
是一种用于编写并行计算机程序的标准库，主要用于多进程间的通
信和数据交换

MPI适用于分布式内存的多处理器系统

== MPI Initialization and Finalization
```c
#include <mpi.h>

int main(int argc, char *argv[])
{
  int rank, size;
  MPI_Init(&argc, &argv);
  MPI_Comm_rank(MPI_COMM_WORLD, &rank); // Get My process rank
  MPI_Comm_size(MPI_COMM_WORLD, &size); // Get number of processes

  // Your main program here
  // ...

  MPI_Finalize();
  return 0;
} /* main */
```

- `MPI_Init()`
  ```c
  int MPI_Init(
    int *argc_p,    /* in/out */
    char ***argv_p  /* in/out */
  );
  ```
  Tells MPI to do all the necessary setup.
  Defines a communicator that consists of all the processes created when the program is started.
- `MPI_Finalize()`
  ```c
  int MPI_Finalize(void);
  ```
  Tells MPI we’re done, so clean up anything allocated for this program.

通信子Communicator:A collection of processes that can send messages to
each other 对进程的抽象

- `MPI_Comm_size`
  ```c
  int MPI_Comm_size(
    MPI_Comm comm, /* in */
    int *size_p    /* out */
  );
  ```
  get the number of processes in the communicator
- `MPI_Comm_rank`
  ```c
  int MPI_Comm_rank(
    MPI_Comm comm, /* in */
    int *rank_p    /* out */
  );
  ```
  get the rank of the calling process in the communicator

== MPI点到点通信

- `MPI_Send`
  ```c
  int MPI_Send(
    void *buf,         /* in */
    int count,         /* in */
    MPI_Datatype type, /* in */
    int dest,          /* in */
    int tag,           /* in */
    MPI_Comm comm      /* in */
  );
  ```
  `tag` is used to distinguish messages that are otherwise identical
- `MPI_Recv`
  ```c
  int MPI_Recv(
    void *buf,         /* out */
    int count,         /* in */
    MPI_Datatype type, /* in */
    int source,        /* in */
    int tag,           /* in */
    MPI_Comm comm,     /* in */
    MPI_Status *status /* out */
  );
  ```
  `status` is used to return information about the received message, includes
  - `MPI_SOURCE`: The rank of the process that sent the message
  - `MPI_TAG`: The tag of the message
  - `MPI_ERROR`: An error code
- `MPI_Get_count`
  ```c
  int MPI_Get_count(
    MPI_Status *status, /* in */
    MPI_Datatype type,  /* in */
    int *count_p        /* out */
  );
  ```
  get the number of elements in a message

`MPI_Recv`会阻塞调用线程，直到收到消息

一个例子：读取用户输入
```c
/*
 * Get_input
 * Get input from the user, and broadcast them to all processes
 *
 * Parameters:
 * my_rank - The rank of the calling process
 * comm_sz - The number of processes in the communicator
 * a_p - The value of a
 * b_p - The value of b
 * n_p - The value of n
 */
void Get_input(
  int my_rank,
  int comm_sz,
  double* a_p,
  double* b_p,
  int* n_p,
) {
  int dest;

  if (my_rank == 0) {
    printf("Enter number a, b, and n:\n");
    scanf("%lf %lf %d", a_p, b_p, n_p);
    for (dest = 1; dest < comm_sz; dest++) {
      MPI_Send(a_p, 1, MPI_DOUBLE, dest, 0, MPI_COMM_WORLD);
      MPI_Send(b_p, 1, MPI_DOUBLE, dest, 0, MPI_COMM_WORLD);
      MPI_Send(n_p, 1, MPI_INT, dest, 0, MPI_COMM_WORLD);
    }
  } else {
    MPI_Recv(a_p, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(b_p, 1, MPI_DOUBLE, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
    MPI_Recv(n_p, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, MPI_STATUS_IGNORE);
  }
} /* Get_input */
```

MPI_Send和MPI_Recv的不当使用可能导致死锁

- `MPI_SendRecv`
  +在一个调用中同时完成发送和接收操作
  +发送和接收操作是原子的，避免了死锁风


#figure(
  image("../../public/blog-resources/image-51.png"),
  caption: [Send/Recv与SendRecv],
)


== MPI集合通信
集合通信是MPI中的一种通信模式，它涉及一组进程（通常是通信域中的所有进程）之间的协同操作。
- 全局性：集合通信涉及通信域中的所有进程，而不是单独的两个进程。
- 同步性：所有参与的进程必须同时调用集合通信函数，否则会导致程序挂起或错误。
- 高效性：集合通信通常经过优化，能够利用底层硬件和网络的特性，提高通信效率。

使用场景:数据分发与收集、数据规约与聚合、进程同步、高效通信

_树形通信_

- `MPI_Reduce`
  ```c
  int MPI_Reduce(
    void *input_data_p,       /* in */
    void *output_data_p,      /* out*/
    int count,                /* in */
    MPI_Datatype datatype,    /* in */
    MPI_Op op,                /* in */
    int dest_process,         /* in */
    MPI_Comm comm             /* in */
  );
  ```
  将各进程的数据按指定操作合并到目标进程。
  支持操作：MPI_SUM, MPI_MAX, MPI_MIN等。
  ```c
  // 例子：计算所有进程的局部和
  int local_sum = ...;
  int global_sum;
  MPI_Reduce(&local_sum, &global_sum, 1, MPI_INT, MPI_SUM, 0, MPI_COMM_WORLD);
  ```
- 类似的有`MPI_Allreduce`。规约操作后结果广播到所有进程
- `MPI_Bcast`
  ```c
  int MPI_Bcast(
    void *data_p,           /* in/out */
    int count,              /* in */
    MPI_Datatype datatype,  /* in */
    int src_proc,           /* in */
    MPI_Comm comm           /* in */
  );
  ```
  Data belonging to a single process is sent to all of the processes in the communicator.
  将根进程的数据广播到通信域内所有进程.
- `MPI_Scatter`
  ```c
  int MPI_Scatter(
    void *send_data_p,           /* in */
    int send_count,              /* in */
    MPI_Datatype send_datatype,  /* in */
    void *recv_data_p,           /* out */
    int src_proc,              /* in */
    MPI_Datatype recv_datatype,  /* in */
  )
  ```
  将根进程（root process）的发送缓冲区中的数据块均匀分发到通信域中的所有进程（包括根进程自身）。每个进程接收到一个不同的数据块。
  (MPI_Bcast中，每个进程得到相同的数据副本)
- `MPI_Gather`
  ```c
  int MPI_Gather(
    void *send_data_p,           /* in */
    int send_count,              /* in */
    MPI_Datatype send_datatype,  /* in */
    void *recv_data_p,           /* out */
    int recv_count,              /* in */
    MPI_Datatype recv_datatype,  /* in */
  )
  ```
  `MPI_Gather`是`MPI_Scatter`的逆操作，它将通信域中所有进程的数据收集到根进程（root process）的接收缓冲区中。
- 类似的还有`MPI_Allgather`

MPI_Gather vs MPI_Reduce
- MPI_Gather: 简单收集数据，保持原始值
- MPI_Reduce: 收集数据并应用归约操作（如求和、求最大值等）

MPI_Gather vs MPI_Allgather
- MPI_Gather: 只将数据收集到根进程
- MPI_Allgather: 将数据收集到所有进程（相当于Gather+Bcast的组合）


#figure(
  image("../../public/blog-resources/image-50.png"),
  caption: [对比MPI_Bcast,MPI_Scatter,MPI_Gather和MPI_Reduce],
)

#figure(
  image("../../public/blog-resources/image-49.png"),
  caption: [对比点到点通信与集合通信],
)

== MPI派生数据类型
PI派生数据类型（Derived Datatypes）用于定义复杂的数据结构，以便在MPI进程之间高效地传输非连续或异构的数据

派生数据类型是MPI中描述非连续内存布局的机制，定义数据的类型和内存分布规则
- 发送端：按指定规则从内存中收集数据
- 接收端：按相同规则将数据分散到内存正确位置
- 本质：数据的内存布局"地图"，而非实际数据打包

派生数据类型的主要用途是简化通信操作，提高代码的可读性和性能。

- `MPI_Type_create_struct`
  ```c
  int MPI_Type_create_struct(
    int count,                        /* in */
    int array_of_blocklengths[],      /* in */
    MPI_Aint array_of_displacements[],/* in */
    MPI_Datatype array_of_types[],    /* in  */
    MPI_Datatype *new_type_p          /* out */
  )
  ```
- `MPI_Get_address`
  ```c
  int MPI_Get_address(
    void *location,                   /* in */
    MPI_Aint *address                 /* out */
  )
  ```
- `MPI_Type_commit`
  ```c
  int MPI_Type_commit(
    MPI_Datatype *type_p              /* in/out */
  )
  ```
- `MPI_Type_free`
  ```c
  int MPI_Type_free(
    MPI_Datatype *type_p            /* in/out */
  )
  ```

一个例子
```c
// Get_input function with a derived datatype

void Build_mpi_type(
  double* a_p,  /* in */
  double* b_p,  /* in */
  int*    n_p,  /* in */
  MPI_Datatype* input_mpi_t_p /* out */
) {
  int array_of_blocklengths[3] = {1, 1, 1};
  MPI_Datatype array_of_types[3] = {MPI_DOUBLE, MPI_DOUBLE, MPI_INT};
  MPI_Aint a_addr, b_addr, n_addr;
  MPI_Aint array_of_displacements[3] = {0};

  MPI_Get_address(a_p, &a_addr);
  MPI_Get_address(b_p, &b_addr);
  MPI_Get_address(n_p, &n_addr);

  array_of_displacements[1] = b_addr - a_addr;
  array_of_displacements[2] = n_addr - a_addr;

  MPI_Type_create_struct(3, array_of_blocklengths,
    array_of_displacements, array_of_types, input_mpi_t_p);

  MPI_Type_commit(input_mpi_t_p);
} /* Build_mpi_type */

void Get_input(int my_rank, int comm_sz, int *a_p, int *b_p, int *n_p) {
  MPI_Datatype input_mpi_t;
  Build_mpi_type(a_p, b_p, n_p, &input_mpi_t);

  if (my_rank == 0) {
    printf("Enter n, a, and b\n");
    scanf("%d %d %d", n_p, a_p, b_p);
  }
  MPI_Bcast(n_p, 1, input_mpi_t, 0, MPI_COMM_WORLD);

  MPI_Type_free(&input_mpi_t);
} /* Get_input */
```

== MPI性能评估

- `MPI_Wtime`
  World Time
- `MPI_Barrier`
  阻塞当前进程，等待所有进程都到达
  Ensures that no process will return from calling it until every process in the communicator has started calling it.

```
Q: Wall Clock Time与CPU Time有何区别？
A:
  Wall Clock Time是程序运行的实际时间，包括所有计算、等待和I/O 时间。
  CPU Time是程序运行所使用的CPU时间，不包括等待和I/O时间。
```

== 奇偶转置排序[Odd-even transposition sort]
奇偶转置排序是一种基于比较交换的并行排序算法，结合了冒泡排序的思想和并行计算的优势。

设计目标：在并行计算环境（如MPI）中高效排序分布式数据

时间复杂度：
- 串行实现：O(n²)（类似冒泡排序）
- 并行实现（n个处理器）：O(n)

基本概念
- 数据分布：假设有n个元素，均匀分布在p个处理器上（每个处理器约n/p个元素）
- 比较方向：
  + 偶阶段（Even Phase）：比较相邻的(2i, 2i+1)元素对
  + 奇阶段（Odd Phase）：比较相邻的(2i+1, 2i+2)元素对

执行流程示例
```
初始序列: [5, 3, 8, 1, 2]

第1轮（偶阶段）:
  (5,3)→比较交换→[3,5,8,1,2]
  (8,1)→比较交换→[3,5,1,8,2]
  (2无配对)→保持→[3,5,1,8,2]

第2轮（奇阶段）:
  (5,1)→比较交换→[3,1,5,8,2]
  (8,2)→比较交换→[3,1,5,2,8]

第3轮（偶阶段）:
  (3,1)→比较交换→[1,3,5,2,8]
  (5,2)→比较交换→[1,3,2,5,8]

第4轮（奇阶段）:
  (3,2)→比较交换→[1,2,3,5,8]
  (5,8)→保持→[1,2,3,5,8] → 排序完成
```

算法终止条件
- 无交换发生：某一轮所有比较均未发生数据交换时终止
- 最大轮数：最多需要n轮（n为元素总数）

那么，如何使用MPI将这个算法并行化呢？

+ 数据分配
  - 每个进程持有部分数据（如local_data数组）
  - 进程rank与邻居进程通信：
    - 偶阶段：rank与rank+1通信（rank为偶数）
    - 奇阶段：rank与rank+1通信（rank为奇数）

进程通信的行为可以简单的描述为:
- 合并两个有序数组
- 保存合并后数组的前一半(或后一半)到进程本地

伪代码描述
```
首先将被分配到本进程的子数组排好序 my_part
for (phase = 0; phase < comm_sz; phase++) {
  neighbour = compute_partner(phase, rank, comm_sz);
  if (当前进程可以找到neighbour) {
    Send my_part to neighbour
    Receive neighbour_part from neighbour
    if (my_rank < neighbour_rank) {
      Merge sort my_part and neighbour_part
      将合并后数组的前一半保存到 my_part
    } else {
      Merge sort my_part and neighbour_part
      将合并后数组的后一半保存到 my_part
  }
}
```


#figure(
  image("../../public/blog-resources/image-52.png"),
  caption: [一个并行化奇偶转置排序算法的例子。],
)
