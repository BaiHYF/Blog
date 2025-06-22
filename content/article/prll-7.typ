
#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Parallel Computing CheetSheet VII",
  desc: [并行计算课程考试前的一些总结. Ch7],
  date: "2025-06-23",
  tags: (
    blog-tags.exam,
  ),
  show-outline: true,
)

= Ch7-CUDA

== CUDA intro

CUDA (Compute Unified Device Architecture)

例子:Hello World From GPU
```c
#include <stdio.h>

// `__global__` is a CUDA keyword that marks a function as a CUDA kernel.
// tells the compiler that this function will be called from CPU
// and executed on GPU
__global__ void helloWorldGPU(void) {
  printf("Hello from GPU!\n");
} // kernel function

int main(void) {
  // Hello from CPU
  printf("Hello from CPU!\n");

  // Launch the kernel function and
  // execute 10 GPU threads
  helloWorldGPU<<<1, 10>>>();

  // Destroy and clean up
  cudeDeviceReset();

  return 0;
}
```
关于CUDA C编程
- just write a piece of serial code to be called by only one thread
- The GPU takes this kernel and makes it parallel by launching thousands of threads, all performing that same computation.
- CUDA abstracts away the hardware details and does not require applications to be mapped to traditional graphics APIs.

== CUDA Programming Model

Programming models present an abstraction of computer architectures.

编程模型是开发者视角的抽象，描述了如何利用CUDA编写并行程序，并且定义了逻辑抽象（如网格、块），开发者无需直接处理硬件细节。

The program, written for a programming model,dictates how components of the program share information and coordinate their activities.

术语:
+ `host` ==> CPU and its memory
+ `device` ==> GPU and its memory
+ `Kernel` ==> the code(functions) that runs on the GPU device
+ `Thread`[线程] ==> ：最小执行单元，每个线程独立运行核函数代码
+ `Block`[线程块] ==> ：一组线程，块内线程可同步并共享内存
  `blockIdx` => block index within a grid;
  `blockDim`=> block size;
  `threadIdx`=> thread index within a block;
+ `Grid`[线程网格]==> ：所有线程块的集合，网格内的块独立执行（不同步）

#figure(image("../../public/blog-resources/image-57.png"), caption: [CUDA Memory Model])

#figure(image("../../public/blog-resources/image-56.png"), caption: [Thread, Block and Grid])

#figure(image("../../public/blog-resources/image-58.png"), caption: [Thread, Block and Grid II])


In CUDA, GPU is viewed as compute device capable of executing a very high number of threads in parallel. GPU operates as a coprocessor to the main CPU (called host).

CUDA Program = host code + device code
+ Allocate memory on the GPU
+ Copy data from CPU memory to GPU memory
+ Invoke the CUDA kernel to perform program-specific computation.
+ Copy data back from GPU memory to CPU memory.
+ Destroy GPU memories.

Basic CUDA API
- `cudaError_t cudaMalloc(void** devPtr, size_t size);`
  在GPU的Global Memory中分配指定大小的内存，输出存储分配的GPU内存的指针`devPtr`。
- `cudaError_t cudaFree(void* devPtr);`
  释放之前通过`cudaMalloc`分配的设备内存。
- `cudaError_t cudaMemcpy(void* dst, const void* src, size_t count, cudaMemcpyKind kind);`
  于在主机（CPU）与设备（GPU）之间传输数据。
  `kind`参数指定数据传输的方向:`cudaMemcpyHostToDevice`, `cudaMemcpyDeviceToHost`, `cudaMemcpyDeviceToDevice`, `cudaMemcpyHostToHost`

例子：在GPU上执行数组求和
```c
float* a, *b, *c;
...
// Use cudaMalloc to allocate the memory on the GPU.
cudaMalloc((void**)&a, N * sizeof(float));
cudaMalloc((void**)&b, N * sizeof(float));
cudaMalloc((void**)&c, N * sizeof(float));

// transfer the data from the host memory to GPU global memory.
cudaMemcpy(a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
cudaMemcpy(b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);

// the kernel function can be invoked from the host side to perform the array summation on the GPU

// Copy the result from the GPU memory back to the host array gpuRef using cudaMemcpy
cudaMemcpy(gpuRef, d_c, N * sizeof(float), cudaMemcpyDeviceToHost);

// use cudaFree to release the memory used on the GPU.
cudaFree(a);
cudaFree(b);
cudaFree(c);
```

那么如何调用一个核函数呢？
- `kernel_name <<grid, block>> (argument list)`
  - `grid` => grid dimension, the number of blocks to launch
  - `block`=> block dimension, the number of threads within each block.

#figure(
  image("../../public/blog-resources/image-58.png"),
  caption: [Example: Launch a kernel],
)

在CUDA中，大多数GPU操作是异步的，即CPU不会等GPU操作完成就继续执行下一行代码。
也就是说如果你立即访问GPU的计算结果，很可能它还没算完。

故一般在核函数的调用后，我们要用`cudaDeviceSynchronize()`来等待GPU完成计算。

- `cudaError_t cudaDeviceSynchronize(void);`
  阻塞CPU，直到GPU上的所有任务都完成为止。即CPU等待GPU所有异步操作执行完毕，包括核函数执行、内存拷贝等。

CUDA中，函数有三种修饰符,global, device, host
#figure(
  image("../../public/blog-resources/image-58.png"),
  caption: [Qualifiers],
)

现在我们可以补全刚才的数组求和例子了。
```c
float* a, *b, *c;
...
cudaMalloc((void**)&a, N * sizeof(float));
cudaMalloc((void**)&b, N * sizeof(float));
cudaMalloc((void**)&c, N * sizeof(float));

cudaMemcpy(a, h_a, N * sizeof(float), cudaMemcpyHostToDevice);
cudaMemcpy(b, h_b, N * sizeof(float), cudaMemcpyHostToDevice);

// the kernel function can be invoked from the host side to perform the array summation on the GPU
sumArraysOnGPU<<<1,32>>>(float *h_a, float *h_b, float *gpuRef);

cudaMemcpy(gpuRef, d_c, N * sizeof(float), cudaMemcpyDeviceToHost);

cudaFree(a);
cudaFree(b);
cudaFree(c);

...

__global__ void sumArrayOnGPU(float *a, float *b, float *c)
{
  int i = threadIdx.x;
  c[i] = a[i] + b[i];
}
```
注意到：不需要显式地创建循环！
