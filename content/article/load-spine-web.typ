#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "在网页中加载Spine动画",
  desc: [简单的记录这个过程.],
  date: "2025-06-14",
  tags: (
    blog-tags.web,
    blog-tags.gamedev,
  ),
  show-outline: false,
)

= 简要介绍Spine动画
简单来说，Spine是一个常用的2D骨骼动画工具。用这个工具生成的动画一般成为Spine动画，广泛应用。
在各种游戏开发中。

这里假设我们已经通过某种渠道获取了Spine动画的源文件，它一般由三个子文件组成。
- 图集文件，后缀为`.atlas`：描述纹理集（Texture Atlas）的布局信息，包括多个图像资源的坐标与尺寸。
- 骨骼数据文件，后缀为`.skel`或`.json`：存储骨骼结构、动画关键帧数据及绑定信息，决定了动画的运动逻辑。
- 动画资源文件，后缀为`.png`：即纹理集图像文件，包含动画中所有骨骼部件所使用的图像资源。

我们一般将这三个文件放在同一个文件夹中。
```
\spine-ani
├─ spine-ani.atlas
├─ spine-ani.skel (or spine-ani.json)
└─ spine-ani.png
```

= 在网页中加载Spine动画

接下来我尝试记录在网页中加载Spine动画的过程。

== 引入Spine Runtimes
在有了动画源文件后，我们想要加载动画，需要用到spine动画相关的第三方库，它通常被称为
Spine Runtimes。我们可以去#link("https://github.com/EsotericSoftware/spine-runtimes")[github仓库]上下载。

注意Spine动画每个版本的库是不兼容的，要找到对应原动画文件版本的库，比如我这里用的是spine 3.8。
就要去#link("https://github.com/EsotericSoftware/spine-runtimes/tree/3.8")[spine runtime 3.8 仓库]下载。

我们在对应仓库中的`spine-ts/build`中下载`spine-player.js`(与`spine-player.js.map`),还有
`spine-ts/player/css`中的`spine-player.css`文件，这些就是我们需要的所有三方库。

把它们放在网页对应的js与css目录下。

== 嵌入网页中

这个过程反而比较简单，只需要几个步骤。

+ 添加Spine Runtimes
  ```html
  <script src="path_to_your_spine-player.js"></script>
  <link rel="stylesheet" href="path_to_your_spine-player.css">
  ```
+ 为模型创建一个container
  ```html
  <div id="spine-container"></div>
  ```
+ 最后在container中创建spine模型
  ```html
  <script>
    new spine.SpinePlayer("container", {
      skelUrl: "path-to-your-skeleton.skel",
      // or use `jsonUrl: "path-to-your-skeleton.json"`
      atlasUrl: "path-to-your-altas.atlas",

      premultipliedAlpha: true,
      backgroundColor: "#00000000",
      alpha: true,
      animation: "your default animation",
    });
  </script>
  ```

这样就大功告成了，本站点主页的模型就是这样创建的。

完整代码为：
```html
  <script src="path_to_your_spine-player.js"></script>
  <link rel="stylesheet" href="path_to_your_spine-player.css">
  <div id="spine-container"></div>
  <script>
    new spine.SpinePlayer("container", {
      skelUrl: "path-to-your-skeleton.skel",
      // or use `jsonUrl: "path-to-your-skeleton.json"`
      atlasUrl: "path-to-your-altas.atlas",

      premultipliedAlpha: true,
      backgroundColor: "#00000000",
      alpha: true,
      animation: "your default animation",
    });
  </script>
```

= 参考资料
#link("https://zh.esotericsoftware.com/spine-player")[spine player官方文档]
