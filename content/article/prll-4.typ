#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet IV",
  desc: [并行计算课程考试前的一些总结. Ch4],
  date: "2025-06-21",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

= Ch4-Pthread
Pthread -- Portable Operating System Interface (POSIX)

== Pthread Hello World!
```c
#include <pthread.h>
#include <stdlib.h>
#include <stdio.h>

/* Global variable -- accessible to all threads */
int thread_count;

void *Hello(void *rank) {}; /* Thread function */

int main(int argc, char *argv[]) {
  long thread;
  pthread_t* thread_handles;

  /* Get the number of threads from the command line */
  thread_count = strtol(argv[1], NULL, 10);

  thread_handles = malloc(thread_count*sizeof(pthread_t));

  /* Create threads.
   * The thread will call Hello() with a different value for rank. */
  for (thread = 0; thread < thread_count; thread++) {
    pthread_create(&thread_handles[thread], NULL, Hello, (void*)thread);
  }

  printf("Hello World from the main thread\n");

  /* Wait for the other threads to finish. */
  for (thread = 0; thread < thread_count; thread++) {
    pthread_join(thread_handles[thread], NULL);
  }

  free(thread_handles);

  return 0;
} /* main */

void* Hello(void* rank) {
  long my_rank = (long) rank;
  printf("Hello World from thread %ld of %d\n", my_rank, thread_count);
} /* Hello */
```

- Type `pthread_t`
  在这里，pthread_t可以认为是对线程的抽象。用于表示线程的唯一标识符。
  每个创建的线程都会被分配一个唯一的`pthread_t`ID，用来在程序中标识该线程。
  应该被视为不透明的数据类型，并通过标准的 Pthread API 来进行操作。
- `pthread_create`
  ```c
  int pthread_create(
    pthread_t *thread_p,          /* out：thread ID, should be allocated before calling */
    const pthread_attr_t *attr,   /* in: thread attributes, pass NULL for default */
    void *(*start_routine) (void),/* in: pointer to function to execute */
    void *arg                     /* in: pointer to function argument */
  );
  ```
  创建一个新的线程，让这个线程执行指定的函数，并返回该线程的 ID。
- Function started by `pthread_create`
  ```c
  void *thread_function(void *arg_p) {}
  ```
  `void*`可以被转换为任意类型。
  `arg_p`是函数参数的指针(数组),指向一个或多个参数.
  类似地，返回值也是这样的数组。
- `pthread_join`
  ```c
  int pthread_join(
    pthread_t thread, /* in: thread ID */
    void **value_ptr  /* out: pointer to function return value */
  );
  ```
  A single call to `pthread_join` will wait for the thread associated with the `pthread_t` object to complete.

== Busy Waiting
先Review一下最原始的同步机制--忙等待(Busy Waiting)
```c
// In a thread function
y = Compute_something(my_rank);
while (flag != my_rank) {}
x += y;
flag += 1;
...
```
这种方法效率较低,且等待时会一直占用CPU资源。

== Pthread中的锁
Review --> 锁(Mutex), 临界区(Critical Section)

Mutex (mutual exclusion) is a special type of variable that can be used to restrict access to a critical section to a single thread at a time.
简单来说，锁的作用就是保证一次同时只有一个线程能执行临界区(的代码)。

- `pthread_mutex_t`
  `pthread_mutex_t`是pthread中锁的类型(抽象)。
- `pthread_mutex_init`
  ```c
  int pthread_mutex_init(
    pthread_mutex_t *mutex_p,         /* out: pointer to mutex */
    const pthread_mutexattr_t *attr_p /* in: mutex attributes, pass NULL for default */
  );
  ```
  初始化一个锁。
- `pthread_mutex_lock`
  ```c
  int pthread_mutex_lock(
    pthread_mutex_t *mutex_p /* in: pointer to mutex */
  );
  ```
  获取锁。(上锁)
  如果此时锁被其他线程占用(被其他线程锁住了)，则当前线程会阻塞，直到锁被释放。
  获取锁后，当前线程会获得锁，并继续执行之后的代码(临界区代码)。
- `pthread_mutex_unlock`
  ```c
  int pthread_mutex_unlock(
    pthread_mutex_t *mutex_p /* in: pointer to mutex */
  );
  ```
  释放锁。(解锁)

一个使用锁的多线程求和的例子:
```c
void* Thread_sum(void* rank) {
  long my_rank = (long) rank;
  double factor;
  long long i = 0;
  long long my_n = n / thread_count;
  long long my_first_i = my_n * my_rank;
  long long my_last_i = my_first_i + my_n;

  double local_sum = 0.0; // my_sum

  if (my_first_i % 2 == 0) {
    factor = 1.0;
  } else {
    factor = -1.0;
  }

  for (i = my_first_i; i < my_last_i; i++, factor = -factor) {
    local_sum += factor / (2 * i + 1);
  }

  pthread_mutex_lock(&mutex);
  global_sum += local_sum;
  pthread_mutex_unlock(&mutex);

  return NULL;
}
```

== 生产者-消费者问题and信号量机制
Producer-Consumer Synchronization and Semaphores

在锁(互斥锁)的基础上，信号量机制可以控制线程进入临界区的_顺序_。

接下来将尝试介绍信号量机制

Semaphores[信号量]
- 基本定义: 信号量是一个整数变量，通常与一个等待队列结合使用,信号量的值在信号量初始化的时候被定义
- `wait()`或`P()`: 当调用P操作时，如果信号量的值大于0，则信号量的值减1，当前线程继续执行之后的代码。如果信号量的值等于0，则当前线程被加入等待队列，并被阻塞(直到信号量的值大于0)。
- `signal()`或`V()`: 将信号量的值加1，并唤醒等待队列中的第一个线程(如果有)。

典型的信号量:
- Binary Semaphore: 值为0或1.功能上与互斥锁类似
- Counting Semaphore: 值可为任意正数。

C语言中关于信号量的API
```c
#include <semaphore.h>

int sem_init(
  sem_t *semaphore_p,        /* out */
  int pshared,               /* in */
  unsigned int initial_val   /* in */
);
// pshared:
//   0 - 信号量在当前进程的多个线程之间共享

int sem_destroy(
  sem_t *semaphore_p /* in */
);

int sem_wait( // P操作
  sem_t *semaphore_p /* in */
);

int sem_post( // V操作
  sem_t *semaphore_p /* in */
);
```

一个例子：用信号量实现线程间消息的有序传递
```c
void Send_msg(void* rank) {
  long my_rank = (long) rank;
  long dest = (my_rank + 1) % thread_count;
  char* my_msg = malloc(MSG_MAX * sizeof(char));

  sprintf(my_msg, "Hello, from %ld to %ld", my_rank, dest);
  messages[dest] = my_msg;

  // Unlock the semaphore of the destination thread
  sem_post(&semaphores[dest]);

  // Wait for our semaphore to be unlocked
  sem_wait(&semaphores[my_rank]);

  printf("Thread %ld recv msg: %s\n", my_rank, messages[my_rank]);

  return NULL;
}

int main(int argc, char* argv[]) {
  long thread;
  messages = malloc(MSG_MAX * sizeof(char*));

  thread_count = 8;
  semaphores = malloc(thread_count * sizeof(sem_t));
  sem_init(semaphores, 0, 0);

  thread_handles = malloc(thread_count * sizeof(pthread_t));

  // Start threads
  for (thread = 0; thread < thread_count; thread++) {
    pthread_create(&thread_handles[thread], NULL, Send_msg, (void*) thread);
  }

  // Wait for threads to finish
  for (thread = 0; thread < thread_count; thread++) {
    pthread_join(thread_handles[thread], NULL);
  }

  free(thread_handles);
  free(semaphores);
  free(messages);
  return 0;
}
```
代码能保证消息发送的顺序是有序的。

== Barrier与条件变量
Barriers and Condition Variables

Barrier[栅栏]
- Synchronizing the threads to make sure that they all are at the same point in a program.
- No thread can cross the barrier until all the threads have reached it.

用信号量实现一个简单的Barrier
```c
// Shared variables
int counter;        // init to 0
sem_t barrier_sem;  // init to 0
set_t count_sem;    // init to 1

void* Thread_function(...) {
  ...

  // Barrier
  sem_wait(&count_sem);
  if (counter == thread_count - 1) {
    // All threads have reached the barrier
    counter = 0;
    sem_post(&count_sem);
    for (i = 0; i < thread_count - 1; i++) {
      sem_post(&barrier_sem);  // Awake all threads
     }
  } else {
    counter++;
    sem_post(&count_sem);
    sem_wait(&barrier_sem); // Wait for all threads to reach the barrier
  }

  ...
}
```

Condition Variables[条件变量]
- A condition variable is a data object that allows a thread to suspend execution until a certain event or condition occurs.
- When the event or condition occurs another thread can signal the thread to “wake up.”
- A condition variable is always associated with a mutex.

条件变量允许一个或多个线程等待某个特定条件发生，并通过其他线程发出信号来唤醒这些线程。

下面用一段伪代码描述条件变量工作的逻辑
```
lock mutex;
if (condition) {
  signal thread(s);
} else {
  unlock the mutex and block;
  // When the thread is unblocked, mutex is relocked
}
unlock mutex;
```

- `pthread_cond_init`
  ```c
  int pthread_cond_init(
    pthread_cond_t *cond,              /* out: condition variable */
    const pthread_condattr_t *attr     /* in: attributes (NULL for default) */
  );
  ```
- `pthread_cond_wait`
  ```c
  int pthread_cond_wait(
    pthread_cond_t *cond,        /* in/out: condition variable */
    pthread_mutex_t *mutex       /* in/out: associated mutex */
  );
  ```
  将当前线程加入等待队列，并释放关联的互斥锁。
  当线程被唤醒时，会重新获取锁。
- `pthread_cond_signal`
  ```c
  int pthread_cond_signal(
    pthread_cond_t *cond         /* in: condition variable */
  );
  ```
  唤醒一个等待该条件变量的线程。
- `pthread_cond_broadcast`
  ```c
  int pthread_cond_broadcast(
    pthread_cond_t *cond         /* in: condition variable */
  );
  ```
  唤醒所有等待该条件变量的线程。
- `pthread_cond_destroy` 销毁条件变量。

通常的应用场景下，当前线程执行pthread_cond_wait时，
处于临界区访问共享资源，存在一个mutex与该临界区相关联，这是理解pthread_cond_wait带有mutex参数的关键.
- 当前线程执行pthread_cond_wait前，已经获得了和临界区相关联的mutex；
  执行pthread_cond_wait会阻塞，但是在进入阻塞状态前，必须释放已经获得的mutex，
  让其它线程能够进入临界区.
- 当前线程执行pthread_cond_wait后，阻塞等待的条件满足，条件满足时会被唤醒；
  被唤醒后，仍然处于临界区，因此被唤醒后必须再次获得和临界区相关联的mutex.

例子：在生产者-消费者问题中使用条件变量
```c
pthread_mutex_t lock;
pthread_cond_t cond_var;
int buffer = 0; // Shared resource

void* producer(void* arg) {
    while (1) {
        pthread_mutex_lock(&lock);
        if (buffer == 0) {
            buffer = 1;
            printf("Produced item\n");
            pthread_cond_signal(&cond_var); // Notify consumer
        }
        pthread_mutex_unlock(&lock);
    }
}

void* consumer(void* arg) {
    while (1) {
        pthread_mutex_lock(&lock);
        while (buffer == 0) {
            pthread_cond_wait(&cond_var, &lock); // Wait for signal
            /* `lock` is released when `pthread_cond_wait` called */
            /* Then reacquired when `pthread_cond_wait` returns(when awaked) */
        }
        printf("Consumed item\n");
        buffer = 0;
        pthread_mutex_unlock(&lock);
    }
}
```

== 读写锁
多个线程同时并行操作一个链表(如执行member、delete、insert操作)会出现什么问题？
- 插入(Insert)+删除(Delete)竞争
  线程A准备在节点X 后插入新节点Y，但线程B同时删除了X，导致Y插入到无效位置或链表断裂。
- 删除(Delete)+查询(Member)竞争
  线程A正在读取节点X 的数据，线程B同时删除X，导致线程A访问已释放的内存(悬垂指针)

+ 解决方案1->简单的用锁将所有对链表的操作都锁起来.
  ```
  lock mutex;
  operate list...
  unlock mutex;
  ```
  但这样效率较低，无法并行操作.
+ 解决方案2->使用读写锁
  读写锁允许多个线程同时读取数据，但只有一个线程可以写入数据。

```c
pthread_rwlock_t rwlock;

// 读取链表-->读锁
pthread_rwlock_rdlock(&rwlock);
Member(list, key);
pthread_rwlock_unlock(&rwlock);

// 插入链表-->写锁
pthread_rwlock_wrlock(&rwlock);
Insert(list, key, value);
pthread_rwlock_unlock(&rwlock);

// 删除链表-->写锁
pthread_rwlock_wrlock(&rwlock);
Delete(list, key);
pthread_rwlock_unlock(&rwlock);
```
