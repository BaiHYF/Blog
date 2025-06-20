#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet II",
  desc: [编译原理课程考试前的一些总结. Ch6],
  date: "2025-06-16",
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

=== 直接计算-直接翻译
对于表达式$a < b$,将其翻译成如下固定的序列:

`a < b` <==> `if a < b then 1 else 0`

TAC序列:
```
(1) if a<b then goto (4)
(2) t := false
(3) goto (5)
(4) t := true
(5) (next...)
```

四元式序列:
```
#   OP   ARG1  ARG2 RESULT
(1) j<,  a,    b,   (4)
(2) =,   0,    _,   t
(3) jump, _,   _,   (5)
(4) =,   1,    _,   t
```

#figure(
  image("../../public/blog-resources/image-20.png"),
  caption: [例题],
)


=== 短路计算-直接翻译
在短路计算的算法下，我们为基本块B引入两个新的属性
+ B.true : 指向表达式为真时的转向
+ B.false : 指向表达式为假时的转向

“短路”的基本思想:
- 对于 $a and b$
  + 若$a$为假，则$a and b$的结果为假，不需要计算$b$,跳转到B.false
  + 若$a$为真，则$a and b$的结果为$b$
- 对于 $a or b$
  + 若$a$为真，则$a or b$的结果为真，不需要计算$b$,跳转到B.true
  + 若$a$为假，则$a or b$的结果为$b$

例子:
+ 语句 `a<b or c<d and e>f`
  翻译为四元式序列
  ```
  # 若a<b为真，则整个表达式为真，跳转到B.true
  # 否则继续执行到(2)，继续判断下一个子表达式的真假
  (1) j<, a, b, B.true
  (2) jump, _, _, (3)
  # 若c<d为假，则整个表达式为假，继续执行(4)，跳转到B.false
  # 否则跳转到(5)，判断e>f的真假
  (3) j<, c, d, (5)
  (4) jump, _, _, B.false
  # 若e>f为真，则整个表达式为真，跳转到B.true
  # 否则整个表达式为假，继续执行(6)，跳转到B.false
  (5) j>, e, f, B.true
  (6) jump, _, _, B.false
  ```
  翻译为三地址码
  ```
  (1) if a < b then goto (9)
  (2) goto (3)
  (3) if c < d then goto (5)
  (4) goto (7)
  (5) if e > f then goto (9)
  (6) goto (7)
  (7) t := 0
  (8) goto (10)
  (9) t := 1
  (10) ...
  ```
+ 条件控制语句`if (x < 100 || x > 200 && x != y) { x = 0; }`
  翻译为三地址码
  ```
  (1) if x < 100 then goto (7)
  (2) goto (3)
  (3) if x > 200 then goto (5)
  (4) goto (8)
  (5) if x != y then goto (7)
  (6) goto (8)
  (7) x := 0
  (8) ...
  ```

=== 布尔表达式--回填翻译算法
_本环节内容由LLM辅助生成_

布尔表达式的回填（Backpatching）翻译方案是一种用于生成三地址码的技术，特别适用于处理条件判断语句（如 if、while 等）。其核心思想是将跳转目标的指令位置延迟到后续步骤中填充，从而避免在中间代码生成阶段就确定具体的跳转地址。

+ 每个布尔表达式节点具有3个属性：
  - E.codebegin: 指向表达式的起始指令标签。
  - E.true：指向表达式为真时应跳转的目标指令标签。
  - E.false：指向表达式为假时应跳转的目标指令标签。
+ 回填机制
  - 未完成的跳转指令：在布尔表达式翻译过程中，某些跳转指令的目标位置尚未确定，先留空。
  - 待回填的指令列表：记录这些未完成的跳转指令的位置。
  - 当目标位置确定后，通过 backpatch() 函数将跳转指令的目标地址更新为正确的位置。

接下来的逻辑有些复杂，需要用伪代码配合描述。

一些函数的定义如下:
`merge(p1, p2)`: 用于把p1和p2为链首的两条链合并成1条，返回合并后的链首值
- p2为空链，则返回p1
- p2不为空，把p2的链尾的第四区段改为p1,然后返回p1

`backpatch(p, t)`用于把链首p所链接的每个四元式的第四区段都填为转移目标t

一些基本翻译规则
+ 单个比较，如`E = id1 rop id2`
  ```
  # 维护状态
  E.codebegin = next
  E.true = next
  E.false = next + 1
  # 然后翻译出两条四元式, 0表示待回填
  emit(jrop, id1.place, id2.place, 0)
  emit(jump, _, _, 0)
  ```
  比如对于`E1: a<b`，我们一开始先维护以下状态
  ```
  E1.codebegin = 0
  E1.true = 0
  E1.false = 1
  ```
  然后翻译出两条四元式，0表示待回填
  ```
  j<, a, b, 0
  jump, _, _, 0
  ```
+ 逻辑或 E = E1 or E2
  ```
  E.codebegin = E1.codebegin
  backpatch(E1.false, E2.codebegin)
  E.true = merge(E1.true, E2.true)
  E.false = E2.false
  ```
  比如对于表达式`E: a<b or c<d`,四元式编号从100开始

  我们定义`E1: a<b`, `E2: c<d`, 则有`E: E1 or E2`

  先生成子表达式`E1`与`E2`的状态与四元式
  ```
  (100) j<, a, b, 0
  (101) jump, _, _, 0
  (102) j<, c, d, 0
  (103) jump, _, _, 0

  ---

  E1.codebegin = 100
  E1.true = 100
  E1.false = 101
  E2.codebegin = 102
  E2.true = 102
  E2.false = 103
  ```

  然后依次执行四条“伪代码”
  ```
  # E.codebegin = E1.codebegin
  E.codebegin = 100

  # backpatch(E1.false, E2.codebegin)
  (101) jump, _, _, 0 ==> (101) jump, _, _, 102

  # E.true = merge(E1.true, E2.true)
  E.true = merge(100, 102) = 100
  (102) j<, c, d, 0 ==> (102) j<, c, d, 100

  # E.false = E2.false
  ```

  最终的状态以及四元式如下:
  ```
  E.codebegin = 100
  E.true = 100
  E.false = 102
  (100) j<, a, b, 0
  (101) jump, _, _, 102
  (102) j<, c, d, 100
  (103) jump, _, _, 0
  ```
+ 逻辑与 E = E1 and E2
  ```
  E.codebegin = E1.codebegin
  backpatch(E1.true, E2.codebegin)
  E.false = merge(E1.false, E2.false)
  E.true = E2.true
  ```
  基本的操作与逻辑或一样，这里就不赘述具体的详细过程了。

  比如对于表达式`E: a<b and c<d`,四元式编号从100开始

  我们定义`E1: a<b`, `E2: c<d`, 则有`E: E1 and E2`

  最终的状态以及四元式如下
  ```
  E1.codebegin = 100
  E1.true = 100
  E1.false = 101
  E2.codebegin = 102
  E2.true = 102
  E2.false = 103
  E.codebegin = 100
  E.false = 101
  E.true = 102

  (100) j<, a, b, 0 ===> (100) j<, a, b, 102
  (101) jump, _, _, 0
  (102) j<, c, d, 0
  (103) jump, _, _, 0 ===> (103) jump, _, _, 101
  ```

最后看一道复杂一些的例题
#figure(
  image("../../public/blog-resources/image-23.png"),
  caption: [例题],
)
