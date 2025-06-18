#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet IV",
  desc: [编译原理课程考试前的一些总结. Ch4],
  date: "2025-06-18",
  tags: (
    blog-tags.exam,
    blog-tags.compiler,
  ),
  show-outline: true,
)

= Chapter04语法分析

考点:
+ LL(1)分析
  - 消除左公因子、左递归、二义性等情况
  - 求FIRST集、FOLLOW集
  - 构造LL(1)分析表
  - 进行LL(1)分析
+ 进行LR分析——LR(0)、SLR(1)、LR(1)、LALR(1)
  - 构建项目集、CLOUSRE函数、GOTO函数、DFA
  - 构建LR分析表
  - 进行LR分析
  - 能分辨出一个文法是属于哪种LR文法


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

== 题型6-LR(0)分析
LR语法分析器通过维护一些状态，用这些状态来表明我们在语法分析过程中
所处的位置，从而做出shift或reduce决定。

大致流程:
+ 对文法进行拓广:对文法G[S],增加一条产生式S'→S,拓广为文法G'[S']
+ 根据产生式构造LR(0)项目集:CLOSURE函数和GOTO函数
+ 根据项目集构造LR(0)DFA
+ 根据LR(0)DFA构造LR(0)分析表
+ 根据LR(0)分析表对输入串进行LR(0)分析

状态由项目[item]集表示:在文法G中每个产生式的右部适当位置添加一个圆点构成项目

+ 移进项目[shift item]
  形如A->α•аβ,即圆点后面为终结符的项目.分析时把а移进符号栈[Shift]
+ 待约项目[reduce-expected item]
  形如A->α•Bβ,即圆点后面为非终结符的项目.期待着继续分析过程中首先能归约得到B
+ 归约项目[reduce item]
  形如A→α•,即圆点在最右端的项目.表明该产生式的右部已分析完，句柄已形成，可以把α归约为A[Reduce]
+ 接受项目[accept item]
  S'→S•,表明输入串可归约为文法开始符，分析结束

- LR(0)扩广文法:在原有文法上，新增开始符号S'和产生式S'→S
- CLOSURE函数(闭包):
  项目集I的闭包CLOSURE(I)定义为:
  + I的项目均在CLOSURE(I)中
  + 若A->α•Bβ属于CLOSURE(I),则每一形如B→•r的项目也属于CLOSURE(I)
  + 迭代直到收敛
  - CLOSURE(I)作为DFA的一个状态
- 状态转换函数GOTO(I, X)=CLOSURE(J), J = {任何形如A->αX•β的项目│A->α•Xβ∈I}

例子:G[S']: S'->E, E->aA|bB, A->cA|d, B->cB|d

状态集I={S'->•E, E->•aA, E->•bB}

有
```
# GOTO(I, X)即I中项目“移进”X的到的项目的闭包
GOTO(I, E) = CLOSURE(S'->E•) = {S'->E•},
GOTO(I, a) = CLOSURE(E->a•A) = {E->a•A, A->•cA, A->•d}
GOTO(I, b) = CLOSURE(E->b•B) = {E->b•B, B->•cB, B->•d}
```

LR(0)状态DFA
- 构造初始状态I0=CLOSURE({S'→•S})
- 然后逐步构造其他状态
- 若有GOTO(Ii, X)=Ij,的DFA中添加有向边Ii->Ij, X为边上的标签

例子:拓广文法G':S'→E,E→aA|bB,A→cA|d,B→cB|d;构造以LR(0)项目集为状态的DFA
+ 计算状态(闭包)
  ```
  I0=CLOSURE(S'->•E)={S'->•E, E->•aA, E->•bB}
  GOTO(I0, E)=CLOSURE(S'->E•)={S'->E•}=I1
  GOTO(I0, a)=CLOSURE(E->a•A)={E->a•A, A->•cA, A->•d}=I2
  GOTO(I0, b)=CLOSURE(E->b•B)={E->b•B, B->•cB, B->•d}=I3
  GOTO(I2, A)=CLOSURE(E->aA•)={E->aA•}=I4
  GOTO(I2, c)=CLOSURE(A->c•A)={A->c•A, A->•cA, A->•d}=I5
  GOTO(I2, d)=CLOSURE(A->d•)={A->d•}=I6
  GOTO(I3, B)=CLOSURE(E->bB•)={E->bB•}=I7
  GOTO(I3, c)=CLOSURE(B->c•B)={B->c•B, B->•cB, B->•d}=I8
  GOTO(I3, d)=CLOSURE(B->d•)={B->d•}=I9
  GOTO(I5, A)=CLOSURE(A->cA•)={A->cA•}=I10
  GOTO(I5, c)=CLOSURE(A->c•A)=I5
  GOTO(I5, d)=CLOSURE(A->d•)=I6
  GOTO(I8, B)=CLOSURE(B->cB•)={B->cB•}=I11
  GOTO(I8, c)=CLOSURE(B->c•B)=I8
  GOTO(I8, d)=CLOSURE(B->d•)=I9
  ```
+ 画出DFA
  #figure(image("../../public/blog-resources/image-32.png"))

LR(0)分析表的构造: ACTION与GOTO
+ 对于移进项目形如A->α•аβ, 若GOTO(k,a)=j，则置ACTION[k,a]=Sj (k和j都是状态编号)
+ 对于待约项目形如A->α•Bβ，若GOTO(k,B)=j，则置GOTO[k,B]=j
+ 对于规约项目形如A→α•，产生式A→α的编号为j，则对任何α，置ACTION[k,a]=rj，归约
+ 对于接受项目形如S'->S•，则置ACTION[k,\$]=ACCEPT

例子:对上一个例子继续构造LR(0)分析表
#figure(image("../../public/blog-resources/image-33.png"))

LR(0)分析器的工作流程:
- LR(0)分析器通过`状态栈 + 符号栈 + 输入串`，结合ACTION表和GOTO表,来决定每一步操作(移进、归约、接受或报错)。
- 核心机制：根据“状态栈栈顶状态”和“当前输入符号”查 ACTION 表，决定动作。
+ 移进操作[Shift]
  - 条件：ACTION[S, a] = Sj,即当前状态为S，当前输入符号为a，ACTION 表给出的是状态Sj
  - 动作: 将a移进符号栈，将Sj压入状态栈，并移进到状态Sj
+ 归约操作[Reduce]
  - 条件：ACTION[S, a] = rj，其中a是终结符或\$（使用第j个产生式A->β）
  - 动作:
    + 把符号栈和状态栈的 顶端各弹出|β|个元素(产生式右部元素数量)
    + 把非终结符A压入符号栈
    + 查GOTO[Q, A] = P，将P压入状态栈(其中Q是弹出后新的栈顶状态)
    + _同进同出_（两个栈同步弹出、同步压入）
+ 接受[Accept]
  + 条件：ACTION[S, \$] = acc
+ 报错[Error]
  + 条件：ACTION[S, a] 是空白

例题:
#figure(
  image("../../public/blog-resources/image-33.png"),
  caption: [根据文法规则与分析表对输入串`bccd$`进行LR(0)分析],
)
解答:
#table(
  columns: (auto, auto, auto, auto, auto, auto),
  table.header("步骤", "状态栈", "符号栈", "输入串", "ACTION", "GOTO"),
  [1], [0], [\$], [bccd\$], [S3], [],
  [2], [03], [\$b], [ccd\$], [S8], [],
  [3], [038], [\$bc], [cd\$], [S8], [],
  [4], [0388], [\$bcc], [d\$], [S9], [],
  [5], [03889], [\$bccd], [\$], [r6(B->d)], [11],
  [6], [0388(11)], [\$bccB], [\$], [r5(B->cB)], [11],
  [7], [038(11)], [\$bcB], [\$], [r5(B->cB)], [7],
  [8], [037], [\$bB], [\$], [r2(E->bB)], [1],
  [9], [01], [\$E], [\$], [acc], [],
)

如果该文法LR(0)DFA中没有任何_规约-规约冲突_，则该文法属于LR(0)文法

SLR(1)分析
若LR(1)冲突项对应产生式左部的两个非终结符的FOLLOW集的交集为空，则该文法属于SLR(1)文法

== 题型7-LR(1)分析
LR(1)分析的基本思想:在LR(0)的基础上设置展望信息(look-ahead)
- LR(1)方法按每个具体的句型设置展望信息
- 例：如果存在如下句型...αAa...，...βAb..，...γAc...，则
  + FOLLOW(A)={a,b,c}
  + 处理到句型...αA,只当输入符号为a时归约
  + 处理到句型...βA,只当输入符号为b时归约
  + 处理到句型...γA,只当输入符号为c时归约

LR(1)项目形如：[A->α•β, a]
- A->α•β是文法产生式
- · 表示分析到的位置（项目的点）
- a是展望符（lookahead），表示在归约A->α时，期望后面跟着的终结符号

LR(1)的初始项目为[S'->•S, \$]，初始状态为I0=CLOSURE([S'->•S, \$])

求闭包:对项集I，重复以下操作直到不变：
- 对于每一个项 [A->α·Bβ, a]中，若·后是非终结符B，则：
- 对B的每个产生式 B → γ
- 对每个 b ∈ FIRST(βa)，加入新项 [B → ·γ, b]
注意：展望符是从 βa 推导出 FIRST 集合！

其他地方与LR(0)类似

例子：文法G'[S']:
```
0: S'->S
1: S->aAd
2: S->bAc
3: S->aec
4: S->bed
5: A->e
```
构造状态及DFA为
```
I0=CLOSURE(S'->•S,$)={
  [S'->•S, $],
  # 此处FIRST($)={$}
  [S->•aAd, $],
  [S->•bAc, $],
  [S->•aec, $],
  [S->•bed, $],
}
I1=GOTO(I0, S)=CLOSURE(S'->S•,$)={[S'->S•, $]}
I2=GOTO(I0, a)=CLOSURE([S->a•Ad, $], [S->a•ec, $])={
  [S->a•Ad, $],
  # FIRST(d$)={d}
  [A->•e, d],
  [S->a•ec, $],
}
I3=GOTO(I0, b)=CLOSURE([S->b•Ac, $], [S->b•ed, $])={
  [S->b•Ac, $],
  # FIRST(c$)={c},
  [A->•e, c],
  [S->b•ed, $],
}
I4=GOTO(I2, A)=CLOSURE([S->aA•d, $])={
  [S->aA•d, $]
}
I5=GOTO(I2, e)=CLOSURE([S->ae•c, $], [A->e•, d])={
  [S->ae•c, $],
  [A->e•, d],
}
I6=GOTO(I3, A)=CLOSURE([S->bA•c, $])={
  [S->bA•c, $]
}
I7=GOTO(I3, e)=CLOSURE([S->be•d, $], [A->e•, c])={
  [S->be•d, $],
  [A->e•, c],
}
I8=GOTO(I4, d)=CLOSURE([S->aAd•, $])={
  [S->aAd•, $]
}
I9=GOTO(I5, c)=CLOSURE([S->aec•, $])={
  [S->aec•, $]
}
I10=GOTO(I6, c)=CLOSURE([S->bAc•, $])={
  [S->bAc•, $]
}
I11=GOTO(I7, d)=CLOSURE([S->bed•, $])={
  [S->bed•, $]
}
```
#figure(image("../../public/blog-resources/image-35.png"))

如何处理?
比如I5={[S->ae•c, \$], [A->e•, d],}
- 若输入字符为c ==> 移进
- 若输入字符为d ==> 使用A->e产生式规约

LR(1)文法：若在SLR(1)分析的基础上使用LR(1)分析能解决冲突，则称该文法属于LR(1)文法


LALR(1): 在LR(1)的基础上合并_同心集_

如果合并后没有冲突，则该文法属于LALR(1)文法

#figure(
  image("../../public/blog-resources/image-36.png"),
  caption: [
    LR分析小结

    LR(0)#sym.subset SLR #sym.subset LALR(1) #sym.subset LR(1)
  ],
)
