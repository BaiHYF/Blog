#import "/typ/templates/mod.typ": sys-is-html-target

// #let blog-description = [
//   于我而言,这个站点的诞生,源于中山大学计算机学院低年级学生群体中在过去某时刻
//   突然兴起的(现在也许仍没结束)博客潮流.与小学生看到同学们都在玩蛋仔派对故而自
//   己也要加入,爱美的女生关注当下最流行的时尚穿搭类似,这个站点存在的最原始的原因
//   能被很简单的概括:我看到不少同学都搭了博客,我觉得好像很highclass,我也要搭一个.

//   将这中间的各种折腾,尝试与取舍,思考全部忽略,我最后正在使用的就是当下这个,
//   国内网络访问也许会很慢的,域名非常奇怪的,托管在某美国公司服务器中的站点.
// ]

#let blog-description = [
  这个博客的建立，最初的动因并不复杂。在我所处的中山大学计算机学院低年级群体中，曾在某个阶段悄然兴起了一股搭建个人博客的风潮。起初我只是出于好奇，也受到周围同学的影响，想亲自尝试一下。或许当时我并不完全清楚自己到底想通过博客实现什么，但我意识到，这可能是一个值得投入的方向。

  在搭建博客的过程中，我经历了不少尝试与取舍，从工具选择到平台部署，从内容规划到样式设计，这个过程本身就让我对技术、表达以及个人数字空间的理解更为深入。最终，我选择了当前这个版本：一个托管于海外服务器，并没有独特的域名，访问速度在国内可能并不理想的简单站点。

  省流：
  本站基于Astro构建，使用了#link("https://github.com/Myriad-Dreamin/tylant")[一个基于Typst的模板]，托管在Github Page上，因此也不保证中国大陆用户的可访问性。。
]

// #let self-intro = [
//   在某种意义上,自我介绍是一个很有意思的过程,我需要将脑海中碎片化的自我认知总结起来,
//   并且有选择性的进行展示.

//   我目前正在用的网名是`Baihyf`.其灵感来源于#link("https://www.gushiwen.cn/shiwenv_ed47f295101d.aspx")[某首唐诗]中的某一句.

//   我是一名马上就要成社畜的学生,很社恐,自认为是二次元.

//   自认为基本符合大多数社会上对*学计算机*的的刻板印象.
//   不过不同于我认识的大多数同专业的同学,我对这门学科并没有太强烈的热情与喜爱
//   ,仅仅是不厌恶而已.

//   大多数的时候我会感觉自己有点颓废,一点点.

//   偶然间会有欲望写点东西，动机也许是希望在这世界上至少留下点痕迹.
//   也许写下当下的心情,也许是对学习的记录,也许是一些杂七杂八的的未经整理的文字.

//   反正我都放在这里了.
// ]

#let self-intro = [
  从某种意义上说，自我介绍是一个整理自我认知的过程。我需要将内心那些零散的认知加以梳理，并在公开表达中有所取舍。

  我目前使用的网名是 `Baihyf`，来源于#link("https://www.gushiwen.cn/shiwenv_ed47f295101d.aspx")[一首唐诗]中的诗句。这是一个我个人较为认同的意象投射。

  我是一名即将毕业的学生。自认为性格很内向，有轻微的社交恐惧。

  某种程度上，我符合外界对计算机专业学生的刻板印象。但与许多同龄人相比，我对这门学科并没有特别强烈的兴趣，也称不上热爱，更准确的说法是“不讨厌”。

  大多数时候，我对自己的评价是状态低落但尚可维持，偶尔会陷入无意义感中。

  偶尔会产生写作的冲动，动因可能是想记录一些思考，也可能只是单纯地希望在这个世界留下某些痕迹。这些文字有时是情绪的表达，有时是学习过程的记录，也有时是一些尚未成形的片段和观点。

  我将它们汇集在这里，作为某种存在的证据。
]

#if sys-is-html-target {
  // 添加脚本部分
  show raw: it => html.elem("script", it.text)
  {
    ```js
      function updateImageByTheme() {
        const isDark = document.documentElement.classList.contains('dark');
        const imgElement = document.getElementById('theme-image');
        if (isDark) {
          imgElement.src = "/blog//images/0612_10.png";
        } else {
          imgElement.src = "/blog//images/0612_5.png";
        }
        console.log("Updating theme to:", isDark ? "dark" : "light");
      }

      window.addEventListener('load', updateImageByTheme);

      window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', updateImageByTheme);

      const observer = new MutationObserver(updateImageByTheme);
      observer.observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });
    ```
  }
  show raw: it => html.elem("style", it.text)
  {
    ```css
    .blog-desc .thumbnail-container {
      flex: 0 0 22em;
      border-radius: 0.5em;
      margin-left: 2em;
      margin-block-start: 0.5em;
      margin-block-end: 2em;
      gap: 1em;
    }

    .blog-desc .thumbnail-container,
    .blog-desc .thumbnail {
      float: right;
      width: 150%;
      height: 150%;
      margin-right: 3em; margin-left: 3em;
    }

    .thumbnail {
      --thumbnail-fg: var(--main-color);
      --thumbnail-bg: transparent;
    }

    .dark .thumbnail {
      --thumbnail-bg: var(--main-color);
      --thumbnail-fg: transparent;
    }

    @media (max-width: 800px) {
      .blog-desc {
        display: flex;
        flex-direction: column;
        align-items: center;
      }
      .blog-desc .thumbnail-container {
        margin-left: 1em;
        margin-block-start: 1em;
        margin-block-end: 1em;
      }
      .blog-desc .thumbnail-container,
      .blog-desc .thumbnail {
        width: 90%;
        height: 90%;
        margin-left: 5em;
      }
    }
    ```
  }


  let div = html.elem.with("div")
  let img = html.elem.with("img")

  let artwork = html.elem(
    "img",
    attrs: (
      class: "thumbnail",
      id: "theme-image",
      src: "/blog//images/0612_10.png", // 默认深色模式
      alt: "Irene",
      style: "width: 100%; height: auto; display: block;",
    ),
  )

  div(
    attrs: (
      class: "blog-desc",
      style: "display: flex; align-items: flex-start; justify-content: space-between; gap: 1em;",
    ),
    {
      div(
        attrs: (style: "margin-left: 2em"),
        blog-description,
      )
      context div(
        attrs: (
          class: "thumbnail-container",
        ),
        artwork,
      )
    },
  )
}

= About Me
#text(self-intro)
