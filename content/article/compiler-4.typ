#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet IV",
  desc: [编译原理课程考试前的一些总结. Ch4],
  date: "2025-06-17",
  tags: (
    blog-tags.exam,
    blog-tags.compiler,
  ),
  show-outline: true,
)

= Chapter04语法分析

== 题型1-自顶向下分析-改写文法
为了让语法分析的推到过程能顺利进行，我们需要保证文法满足一些性质。如无左公因子，无左递归等。

+ 消除左公因子
  + 提取左公因子
  + 剩余部分用一新引入的非终结符表示
  - 例子
  ```
  Grammar G[S]: S -> aSb | aS | ε
  提取左公因子 G[S]: S -> aS(b|ε)|ε
  剩余部分用一新引入的非终结符表示:
  G[S]: S -> aSS'|ε
        S'-> b|ε
  ```
+ 消除左递归
  + 直接左递归：引入的非终结符，`A -> Aα|β` 变为 `A -> βA', A' -> αA'|ε`
  + 间接左递归：先改写为直接左递归，再处理
  - 例子
  ```
  Grammar G[S]: (1) S->Qc|c (2) Q->Rb|b (3) R->Sa|a
  0. 排序非终结符 R Q S
  1. 对R: (1)代入(3)得 (4) R->Qca|ca|a
  2. 对Q: (4)代入(2)得 (5) Q->Qcab|cab|ab|b
  3. (5)有直接左递归，消除得到 (6)Q->cabQ'|abQ'|bQ', (7)Q'->cabQ'|ε
  4. 对S: (1)代入(6)得 S->cabQ'c|abQ'c|bQ'c|c
  5. 最后删除无用表达式，结果为
  G'[S]: S->cabQ'c|abQ'c|bQ'c|c, Q'->cabQ'|ε
  ```
+ 消除ε产生式
  + 简单的说就是把所有可能的ε的情况考虑到，然后用对应的终结符代替ε
  - 例子
  ```
  Grammar G[S]: S->Aa|b, A->Ac|Sd|ε
  消除ε产生式:
  新增产生式1.S->a(S->Aa->a)
  新增产生式2.A->c(A->Ac->c)
  处理后结果为:
  (1)S->Aa|b|a
  (2)A->Ac|Sd|c
  ```
  - 例子2:若由开始符号S→ε,则应补充S'→S|ε
  ```
  G[S]:S→aSbS|bSaS|ε消除ε产生式
  改写为:
  S'->S|ε
  S->aSbS|bSaS|abS|aSb|baS|bSa|ab|ba
  ```

例题:

对文法G[S]: S→Aa|b，A→Ac|Sd|ε消除左递归

解答:
```
0. 排序非终结符 S A
1. 对S: S→Aa|b 无直接左递归
2. 对A: A->Ac|Sd|ε 用S得产生式代入得:A->Ac|Aad|bd|ε
3. 提取左公因子: A->A(c|ad)|bd|ε
4. 消除直接左递归: A->bdA'|A', A'->cA'|adA'|ε

最终G[S]为
(1)S→Aa|b
(2)A->bdA'|A'
(3)A'->cA'|adA'|ε
```

== 题型2-计算文法非终结符的FIRST集和FOLLOW集

#figure(
  image("../../public/blog-resources/image-27.png"),
  caption: [
    $"FIRST"$集与$"FOLLOW"$集的直观理解

    $a in "FIRST"(A), b in "FOLLOW"(A)$
  ],
)

定义$"FIRST"(alpha)$，其中$alpha$是一个语法符号构成的任意串，
为一组可以被$alpha$推导出的终结符串的起始字符的集合。如果$alpha accent(=>, *) ε$，那ε也在
$"FIRST"(alpha)$中。

直观上说，文法符号串$alpha$的开始符号集是由推导出的开头的终结符（包括ε）
组成的。

例子
```
G[S]:
S->Ap FIRST(Ap)={a, c}
S->Bq FIRST(Bq)={b, d}
A->a  FIRST(a) ={a}
A->cA FIRST(cA)={c}
B->b  FIRST(b)={b}
B->dB FIRST(dB)={d}

FIRST(S)={a, b, c, d}
FIRST(A)={a, c}
FIRST(B)={b, d}
```

定义FOLLOW(A)，对于非终结符A，
为可以出现在某个句型中A的紧接右边的终结符a的集合；
也就是说，存在形如S→αAβ的推导，其中a是某个终结符，β是某个符号串。

Follow集就是在文法的所有句子中，可能出现在“由非终结符A生成的部分”之后的终结符的集合。
例子
```
G[S]:
S->aA|d
A->bAS|ε

FOLLOW(S)={#, a, d}
FOLLOW(A)={#, a, d}

'#'表示输入串的结束符
```
注意：ε不存在于任何FOLLOW集中

例题
```
对文法G[E]:
1. E→TE'
2. E'→+TE'|ε
3. T→FT'
4. T'→*FT'|ε
5. F→(E)|n
求每个非终结符的FIRST集和FOLLOW集。
```
解答
```
FIRST(E)={(, n}   FOLLOW(E)={#, )}
FIRST(E')={+, ε}  FOLLOW(E')={#, )}
FIRST(T)={(, n}   FOLLOW(T)={#, +, )}
FIRST(T')={*, ε}  FOLLOW(T')={#, +, ) }
FIRST(F)={(, n)}  FOLLOW(F)={#, *, +, )}
```

== 题型3-对文法构造LL(1)预测分析表并对输入串进行LL(1)分析
LL(1) means 从左扫描，最左推导，向前看1个符号

预测分析表M:元素M[A,a]的内容是当非终结符A面临输入符号a(终结符或结束符\$)时应选
取的产生式；当无产生式时，元素内容为转向出错处理。

- 对于FIRST(α)中的每个终结符a，将A->α填入表M[A,a]中；
- 如果ε$in$FIRST(α)，则对于FOLLOW(A)中的每个终结符a，将A->α填入表M[A,a]中；
- 如果\$$in$FOLLOW(A)，也将A->α填入表M[A,\$]中。

#figure(
  image("../../public/blog-resources/image-28.png"),
  caption: [
    例题
  ],
)

例题2：
```
G[S]:
S->if E then S S'|other
S'->ε|else S
E->bool

FIRST(S)={if, other} FOLLOW(S)={#, else}
FIRST(S')={ε, else}  FOLLOW(S')={#, else}
FIRST(E)={bool}      FOLLOW(E)={then}
```
#table(
  columns: (auto, auto, auto, auto, auto, auto, auto),
  table.header(
    [非终结符],
    [if],
    [then],
    [else],
    [other],
    [bool],
    [\$],
  ),

  [S], [S->if E then S S'], [], [], [S->other], [], [],
  [S'], [], [], [S'->else S, S'-> ε], [], [], [S'->ε],
  [E], [], [], [], [], [E->bool], [],
)
_如上所示，预测表中一个单元格算出来两个推导式，这被称为冲突_

在预测表的基础上，我们可以对输入串进行LL(1)分析。
#figure(
  image("../../public/blog-resources/image-29.png"),
  caption: [
    例题：LL(1)分析
  ],
)

练习题：对文法G[S]：S→aBa，B→bB|ε，构造预测分析表，并对输入符号串
abba及aabb分别进行LL(1)预测分析，写出分析的全过程（表格形式）

解答：
+ 计算FIRST集和FOLLOW集
  ```
  FIRST(S)={a}    FOLLOW(S)={#}
  FIRST(B)={b, ε} FOLLOW(B)={#,a,b}
  ```
+ 构造预测分析表
  #table(
    columns: (auto, auto, auto, auto),
    table.header(
      [非终结符],
      [a],
      [b],
      [\#],
    ),

    [S],
    [
      S->aBa

      (由a$in$FIRST(S)得出)
    ],
    [],
    [],

    [B],
    [
      B->ε

      (由于ε$in$FIRST(B),故将(B->ε填入a$in$FOLLOW(B)中))
    ],
    [B->bB

      (b$in$FIRST(B)得出)],
    [],
  )
+ 对abba进行LL(1)分析
  #table(
    columns: (auto, auto, auto, auto),
    table.header(
      [步骤],
      [分析栈],
      [剩余输入串],
      [动作],
    ),

    [1], [S], [abba], [S->aBa],
    [2], [aBa], [abba], [match(a)],
    [3], [aB], [bba], [B->bB],
    [4], [aBb], [bba], [match(b)],
    [5], [aB], [ba], [B->bB],
    [6], [aBb], [ba], [match(b)],
    [7], [aB], [a], [B->ε],
    [8], [a], [a], [match(a)],
    [9], [], [], [ACCEPT],
  )
  + 对aabb进行LL(1)分析
  #table(
    columns: (auto, auto, auto, auto),
    table.header(
      [步骤],
      [分析栈],
      [剩余输入串],
      [动作],
    ),

    [1], [S], [aabb], [S->aBa],
    [2], [aBa], [aabb], [match(a)],
    [3], [aB], [abb], [B->ε],
    [4], [a], [abb], [match(a)],
    [5], [], [bb], [ERROR],
  )

== 题型4-移进规约分析[SR Parsing]
+ 对输入符号串自左向右进行扫描，并把当前输入符号下推入栈中（移进），边移进边分析，一旦栈顶符号串形成某个句型的句柄（为某产生式的右部）时，就用相应的非终结符（产生式的左部）替换它（归约）。
+ 重复这一过程，直到输入符号串的末端，此时如果栈中只剩文法开始符号，则输入符号串是文法的句子，否则不是。

#figure(
  image("../../public/blog-resources/image-30.png"),
  caption: [
    例题：移进规约分析
  ],
)
#figure(
  image("../../public/blog-resources/image-30.png"),
  caption: [
    例题：移进规约分析2
  ],
)

== 题型5-算符优先分析
在移进规约分析的基础上，对算符优先文法进行扩展，添加算符优先关系表。

+ 将输入串的符号依次_移进_到符号栈中，直到栈顶终结符的优先级_$succ$(大于)_当前输入符号
+ 由栈顶向下找到第一个$a_(i-1) prec a_(i)$(小于), 从$a_i$的前一个终结符(如果有)开始，到栈顶终结符(如果有)
  这一串符号串为_最左素短语_，用相应的产生式进行规约
+ 重复直到ACCEPT或ERROR

例题:

有文法G[S]：S→(L)|a，L→L,S|S，对输入符号串(a, (a, a))进行算法优先
分析（假设有如下算法优先关系表）

#table(
  columns: (auto, auto, auto, auto, auto, auto),
  table.header(
    [],
    [a],
    [(],
    [)],
    [,],
    [\$],
  ),

  [a], [], [], [#sym.succ], [#sym.succ], [#sym.succ],
  [(], [#sym.prec], [#sym.prec], [#sym.equiv], [#sym.prec], [],
  [)], [], [], [#sym.succ], [#sym.succ], [#sym.succ],
  [,], [#sym.prec], [#sym.prec], [#sym.succ], [#sym.succ], [],
  [\$], [#sym.prec], [#sym.prec], [], [], [],
)

解答:
#table(
  columns: (auto, auto, auto, auto, auto),
  table.header(
    [步骤],
    [符号栈],
    [优先关系],
    [输入串],
    [动作],
  ),

  [1], [\$], [\$ #sym.prec (], [(a,(a,a))], [Shift],
  [2], [\$(], [( #sym.prec a], [a,(a,a))], [Shift],
  [3], [\$(a], [a #sym.succ ,], [,(a,a))], [Reduce S->a],
  [4], [\$(S], [( #sym.prec ,], [,(a,a))], [Shift],
  [5], [\$(S,], [, #sym.prec (], [(a,a))], [Shift],
  [6], [\$(S,(], [( #sym.prec a], [a,a))], [Shift],
  [7], [\$(S,(a], [a #sym.succ ,], [,a))], [Reduce S->a],
  [8], [\$(S,(S], [( #sym.prec ,], [,a))], [Shift],
  [9], [\$(S,(S,], [, #sym.prec a], [a))], [Shift],
  [10], [\$(S,(S,a], [a #sym.succ )], [))], [Reduce S->a],
  [11], [\$(S,(S,S], [, #sym.succ )], [))], [Reduce L->S, L->L,S],
  [12], [\$(S,(L], [( #sym.equiv )], [))], [Shift],
  [13], [\$(S,(L)], [) #sym.succ )], [)], [Reduce S->(L)],
  [14], [\$(S,S], [, #sym.succ )], [)], [Reduce L->S, L->L,S],
  [15], [\$(L], [( #sym.equiv )], [)], [Shift],
  [16], [\$(L)], [], [], [Reduce S->(L)],
  [17], [\$S], [], [], [ACCEPT],
)
