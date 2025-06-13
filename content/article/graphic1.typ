#import "/typ/templates/blog.typ": *
#show: main.with(
  title: "Graphic Basic 1",
  desc: [Viewing Transformation with Matrix Multiplation.],
  date: "2024-10-25",
  tags: (
    blog-tags.programming,
    blog-tags.gamedev,
  ),
  show-outline: true,
)

= Graphics Basics 1: Viewing Transformation with Matrix Multiplication

本文是我对 MVP 矩阵变换及视口变换的一些记录。并不包含完整的数学推导，更偏向随笔风格的技术笔记。

== Homogeneous Coordinates in 3D

在现代计算机图形学中，我们使用 *齐次坐标*（homogeneous coordinates）来表示三维空间中的点。这样可以统一各种几何变换（缩放、平移、旋转、切变）为矩阵乘法。

以下是齐次坐标表示及其常见变换矩阵的示意：

![image.png](https://prod-files-secure.s3.us-west-2.amazonaws.com/9f818825-dc97-4ead-98e8-502ed877201b/6c64db36-90ec-4497-97fe-f4fe37eba9ab/image.png)

#figure(
  image("../../public/blog-resources/image.png"),
  caption: [原坐标 × 变换矩阵 = 变换后的坐标],
)

使用列向量 `[x, y, z, w]` 表示点时，其实际坐标为 `[x/w, y/w, z/w]`。

== Model Transformation

MVP 中的 M（Model Matrix）将物体从其局部空间转换到世界空间（World Space）。从世界视角看，它负责“把物体放到该在的位置”。

通常我们根据需要构造一个 Model Matrix，然后对每个顶点执行矩阵乘法来完成位置、旋转、缩放等操作。

示例代码如下：

```cpp
// Model transformation
{
  static glm::mat4 model_mat = glm::mat4(1.0f);

  // Apply rotation
  model_mat = glm::rotate(model_mat, (float)deltaTime * 0.0001f, glm::vec3(0, 1, 0)) * model_mat;

  // Apply scaling
  static bool isScalingUp = true;
  static float scaleFactor = 1.0f;
  if (scaleFactor > 3.0f) isScalingUp = false;
  else if (scaleFactor < 1.0f) isScalingUp = true;

  scaleFactor += (isScalingUp ? 1.0f : -1.0f) * (float)deltaTime * 0.0003f;
  glm::vec3 scaleVec(scaleFactor, scaleFactor, scaleFactor);
  model_mat = glm::scale(glm::mat4(1.0f), scaleVec) * model_mat;

  renderer->setModelMatrix(model_mat);
}
```

初始化 `model_mat` 为单位矩阵，随后乘上旋转与缩放矩阵，最终传递给渲染器进行绘制。

== View Transformation (Camera Transformation)

MVP 中的 V 是 View Matrix，又称相机矩阵。它负责将世界中的物体“移动”到相机前方。

要构造 View Matrix，需先描述相机的参数：

#figure(image("../../public/blog-resources/image-1.png"))

e: 相机位置（eye）

g: 相机朝向（gaze）

t: 相机上方向（tilt）

#figure(
  image("../../public/blog-resources/image-2.png"),
  caption: [在 Camera Matrix 中设置 t = (0, 1, 0) 与设置 t = (1, 0, 0) 的对比],
)

在 OpenGL 中，默认的相机位置为原点，朝向为 z 轴负方向，上方向为 y 轴正方向。

```cpp
	renderer->setViewMatrix(TRRenderer::calcViewMatrix(cameraPos, lookAtTarget, glm::vec3(0.0, 1.0, 0.0f)));
```

== Projection Transformation

将三维物体投影到二维平面是“成像”的第一步。我们可选用：

- 正交投影（Orthographic Projection）

- 透视投影（Perspective Projection）

其作用是将场景投影到一个标准立方体 $[-1,1]^3$ 中：

#figure(
  image("../../public/blog-resources/image-3.png"),
  caption: [投影：将三维的变成二维的],
)

投影矩阵的功能就是将我们上一步得到的矩阵映射到 $[-1, 1]^3$ 的立方体内（之后屏幕渲染时会将这个立方体”拍扁“成 $[-1,1]^2$的正方形，毕竟屏幕是二维的）

作业一中关于 Projection Transformation 的代码如下

```cpp
// Set projection matrix
{
  renderer->setProjectMatrix(TRRenderer::calcPerspProjectMatrix(
    45.0f,
    static_cast<float>(width) / height,
    0.1f,
    10.0f
  ));

  // 说明：near < far，表明使用的是左手系，视野朝 z 正方向
  // renderer->setProjectMatrix(TRRenderer::calcOrthoProjectMatrix(...));
}

```

== Viewport Transformation

成像的第二步是视口变换（Viewport Transformation）。它把标准立方体 $[-1,1]^3$ 中的点，映射到实际屏幕像素的范围 $[0,W] × [0,H]$。

在代码中通常在 Renderer 初始化时设定：

```cpp
TRRenderer::TRRenderer(int width, int height)
  : m_backBuffer(nullptr), m_frontBuffer(nullptr)
{
  m_backBuffer = std::make_shared<TRFrameBuffer>(width, height);
  m_frontBuffer = std::make_shared<TRFrameBuffer>(width, height);

  // Setup viewport matrix (NDC space -> screen space)
  m_viewportMatrix = calcViewPortMatrix(width, height);
}

```

== Summary: From 3D World to 2D Screen

#figure(image("../../public/blog-resources/image-4.png"))

综上，一个点从模型空间（local space）被逐步转换到屏幕空间（screen space），经过如下变换流程：

$
  V_"screen" = M_"viewport" times M_"projection" times M_"camera" times M_"model" times V_"local"
$

注意：由于矩阵乘法的结合规则，变换顺序是从右往左。

虽然过程繁杂，但正是这些变换使我们能够将三维模型精确地呈现在二维屏幕上。
