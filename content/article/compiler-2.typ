#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet II",
  desc: [编译原理课程考试前的一些总结. Ch6],
  date: "2025-06-15",
  tags: (
    blog-tags.exam,
    blog-tags.compiler,
  ),
  show-outline: true,
)

= Chapter06中间代码生成

== 题型1--为表达式构造DAG与值编码
构造DAG的值编码方法:
- 语法树或DAG中的结点存放在一个记录数组中
- 数组的每一行表示一个记录,即一个结点
- 每个记录中,都有结点编号
- 叶子结点:一个附加字段,存放标识符的词法值lexval
- 内部结点:两个附加字段,分别指明其左石结点

Example:
- 表达式：`i = i + 10`
- DAG:
```
       =
      /  \
     |    +
      \  / \
       i   10
```
- 值编码
#table(
  columns: (auto, auto, auto, auto),
  [1], [id], [i], [],
  [2], [num], [10], [],
  [3], [+], [1], [2],
  [4], [=], [1], [3],
)

== 题型2--表达式三元式与四元式序列
三地址码[Three-AddressCode，TAC]
- 三地址码中，一条指令右侧最多有一个运算符，即不允许出现组合的算术表达式

#figure(
  image("../../public/blog-resources/image-16.png"),
  caption: [三元式],
)

#figure(
  image("../../public/blog-resources/image-17.png"),
  caption: [四元式],
)

一些特殊的运算符:
+ 取地址`arr[i]` => `[]=`
+ 函数参数`f(x)` => `param`
+ 函数调用/返回 => `call`
+ 相反数`-x` => `minus`

#figure(
  image("../../public/blog-resources/image-18.png"),
  caption: [例题],
)

== 题型3--按照翻译方案将表达式(特别是数据引用)翻译成三地址码
关键是数组元素的寻址

+ `A[i]`
```
t0 = i x w (w为每个元素的宽度)
t1 = A[t0]
```
+ `A[i][j]`
```
t0 = i x n (n为数组第2维度的元素个数)
t1 = j + t0
t2 = t1 x w
t3 = A[t2]
```

#figure(
  image("../../public/blog-resources/image-19.png"),
  caption: [例题],
)

== 题型4--条件判断与回填(难点)
