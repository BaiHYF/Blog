#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Compiler CheetSheet III",
  desc: [编译原理课程考试前的一些总结. Ch5],
  date: "2025-06-17",
  tags: (
    blog-tags.exam,
    blog-tags.compiler,
  ),
  show-outline: true,
)

= Chapter05语法制导的翻译

== 题型1-注释语法分析树

#figure(
  image("../../public/blog-resources/image-24.png"),
  caption: [$n$表示表达式的结尾标记],
)

== 题型2-SDD的属性判断
属性分类：
- 综合属性[synthesized attribute]:
  从语法树的角度来看，如果一个结点的某一属性值是由该结点的子结点的属性值计算来的，则称该属性为综合属性($下->上$)
- 继承属性[inherited attribute]：
  从语法树的角度来看，若一个结点的某一属性值是由该结点的兄弟结点和（或）父结点的属性值计算来的，则称该属性为继承属性($上->下$)

S-属性文法：一个所有属性都是综合属性的SDD
- 每个节点的属性值仅由其子节点的属性值计算而来（自底向上传递信息）
- 可以保证求值顺序与LR分析的输出顺序相同
- 可按照语法分析树结点的任何_自底向上_顺序来计算属性值

L-属性文法：的产生式右部所关联的各个属性之间，依赖图的边总是从左到右
- 每个属性要么是一个综合属性
- 每个属性要么是一个继承属性，但有以下约束：
  $A->X_1 X_2 ... X_n$中，$X_i$的属性只能依赖_A的继承属性_，$X_1 ... X_(i-1)$的属性，以及$X_i$自己的属性

人话:L-属性定义的自的是确保属性计算可以按从左到右的顺序进行;继承属性不能依赖右边的符号，否则计算顺序会混乱（因为右边的符号可能还未被处理);不能有循环依赖，否则无法确定计算顺序

_只能依赖左边的属性_ -> L(Left)属性

#figure(
  image("../../public/blog-resources/image-25.png"),
  caption: [例题],
)

== 题型3-构造递归下降翻译器

通俗的讲就是讲文法写成代码的形式（？）

例子：给定LL(1)文法G[E]及翻译模式
```
E→ T {R.in=T.val;} R{E.val=R.val;}
R→ +T {R1.in = R.in + T.val;} R1{R.val = R1.val;}
R→ -T {R1.in = R.in - T.val;} R1{R.val = R1.val;}
R→ ε {R.val = R.in;}
T→ num{T.val = num.val;}
```
构造相应的递归下降预测翻译程序如下
```
int E() {
  t_val = T();
  r_in = t_val;
  r_val = R(r_in);
  e_val = r_val;
  return e_val;
}

int R(int r_in) {
  if (current_token.val == '+){
    match('+');
    t_val = T();
    r1_in = r_in + t_val;
    r1_val = R1(r1_in);
    r_val = r1_val;
    return r_val;
  } else if (current_token.val == '-'){
    match('-');
    t_val = T();
    r1_in = r_in - t_val;
    r1_val = R1(r1_in);
    r_val = r1_val;
    return r_val;
  } else {
    // current_token.val == ε
    r_val = r_in;
    return r_val;
  }
}

int T() {
  if (current_token.type == NUM) {
    t_val = current_token.val;
    match(NUM);
    return t_val;
  } else {
    error("expecting a number");
  }
}
```

#figure(
  image("../../public/blog-resources/image-26.png"),
  caption: [例题],
)

参考解答为
```
void S() {
  a_num = A();
  b_in_num = a_num;
  b_num = B(b_in_num);
  if (b_num == 0) {
    printf("Accepted!");
  } else {
    printf("Refused!");
  }
}

int A() {
  if (current_token.val == 'a') {
    match('a');
    a1_num = A();
    a_num = a1_num + 1;
    return a_num;
  } else if (current_token.val == ε) {
    a_num = 0;
    return a_num;
  } else {
    ERROR();
  }
}

int B(int b_in_num) {
  if (current_token.val == 'a') {
    match('a');
    b1_in_num = b_in_num;
    b1_num = B(b1_in_num);
    b_num = b1_num - 1;
    return b_num;
  } else if (current_token.val == 'b') {
    match('b');
    b1_in_num = b_in_num;
    b1_num = B(b1_in_num);
    b_num = b1_num;
    return b_num;
  } else if (current_token.val == ε) {
    b_num = b_in_num;
    return b_num;
  } else {
    ERROR();
  }
}

```
