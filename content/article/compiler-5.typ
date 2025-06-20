#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet V",
  desc: [编译原理课程考试前的一些总结. Ch3],
  date: "2025-06-19",
  tags: (
    blog-tags.exam,
    blog-tags.compiler,
  ),
  show-outline: true,
)

= Chapter03词法分析

正则表达式 <=> 正规文法 <=> 有穷自动机

== 题型1-正则表达式

#table(
  columns: (auto, auto),
  table.header("正则表达式", "含义"),
  [a\*], [0或多个a(#sym.epsilon, a, aa, ...)],
  [a+], [1或多个a(a, aa, ...)],
  [(a|b)(a|b)], [(aa, ab, ba, bb)],
  [(a|b)\*], [包括#sym.epsilon 在内的所有由a或b组成的字符串],
  [a-zA-Z], [a|b|...z|A|B...z的简写],
  [0-9], [0|1|...9的简写],
  [0([0-9])\*0], [以0开头，且以0结尾的数字字符串,如0110,040],
  [1\*(0|#sym.epsilon)1\*], [最多含有一个0的二进制串],
  [(0|1)\*00(0|1)\*], [包含00的所有二进制串],
)

例子：
+ C语言中标识符的正则表达式
  ```
  letter = [a-zA-Z] | _
  digit = [0-9]
  identifier = (letter)(letter | digit)*
  ```
+ C语言中十进制数字的正则表达式
  ```
  digit = [0-9]
  non_zero_digit = [1-9]
  demical_number = 0 | (non_zero_digit)(digit)*
  ```
+ 2的倍数的二进制的正则表达式
  ```
  # 即所有最后一位为0的二进制串
  (0|1)*0
  ```

== 题型2-正则表达式转换为NFA

+ NFA -> 每个输入可能有多个跳转
+ DFA -> 每个输入只能有一个跳转

+ 处理原子REs
  - 对于表达式#sym.epsilon:增加新状态i，作为NFA的初始状态,增加另一个新状态f，作为NFA的接受状态
  ```
       ε
  i -------> f
  ```
  - 对于表达式a:同上
  ```
       a
  i -------> f
  ```
+ 进一步处理复合REs
  #image("../../public/blog-resources/image-37.png")

例题:将正则表达式(a|b)\*abb转成NFA
#image("../../public/blog-resources/image-38.png")


== 题型3-NFA转换为DFA-ε闭包构造算法
状态集合I的ε闭包ε-closure(I)是状态集I中的所有状态S以及经任意条ε弧而能到达的状态的集合。

#image("../../public/blog-resources/image-39.png")

== 题型4-NFA转换为DFA-子集构造算法
子集构造[subset construction]算法
- 让DFA的每个状态对应NFA的一个状态集合
- 即DFA用它的一个状态记录在NFA读入一个输入符号后可能达到的所有状态
- 构造状态转移矩阵

例题
#image("../../public/blog-resources/image-40.png")

== 题型5-DFA最小化(化简)
- 去除多余状态
- 合并等价状态
  + 等价条件1：一致性---状态s和t必须同为可接受状态或不可接受状态。
  + 等价条件2：蔓延性---对于所有输入符号，状态s和状态t必须转换到等价的状态里。

例题
#image("../../public/blog-resources/image-41.png")
