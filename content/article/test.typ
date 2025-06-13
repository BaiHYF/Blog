#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Test astro-typst",
  desc: [This is a test post.],
  date: "2001-01-01",
  tags: (
    blog-tags.misc,
  ),
  show-outline: false,
)
== Test image
#figure(
  image("../../public/images/0612_5.png", width: 80%),
  caption: [
    A image test.

    I love Irene:)
  ],
)

// == Test grid
// #grid(
//   columns: (1fr, 1fr),
//   [
//     A image test.

//     I love Irene:)
//   ],
//   image("../../public/images/irene-版画-transparent.png", width: 80%),
// )

== Test Table
#import "@preview/tablem:0.1.0": tablem

#tablem[
  | *English* | *German* | *Chinese* | *Japanese* |
  | --------- | -------- | --------- | ---------- |
  | Cat | Katze | 猫 | 猫 |
  | Fish | Fisch | 鱼 | 魚 |
]

#table(
  columns: (auto, auto, auto, auto),
  table.header(
    [English],
    [German],
    [Chinese],
    [Japanese],
  ),

  [Cat], [Katze], [猫], [猫],
  [Fish], [Fisch], [鱼], [魚],
)

== Test code
#import "@preview/codly:1.3.0": *
#import "@preview/codly-languages:0.1.1": *
// #show: codly-init.with()


```rust
println!("Hello, world!");
```
