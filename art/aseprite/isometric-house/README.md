# Hearth Cottage / 炉边小屋

按本次要求直接使用 Aseprite Lua API 绘制的等距像素小屋。

- 画布：256 × 240，RGBA，透明背景，地面两轴为 2:1 像素投影。
- 可编辑源文件：`hearth-cottage.aseprite`，12 个图层。
- 透明成图：`hearth-cottage.png`。
- 隐藏地块和步道的导出：`hearth-cottage-no-ground.png`。
- 浅色背景预览：`hearth-cottage-preview.png`；四倍最近邻预览：`hearth-cottage-preview-4x.png`。
- 图层：可选背景、草地与土层、投影与步道、石地基、墙面、木梁、窗户、门与台阶、瓦顶、烟囱、灯与花箱、花草。
- 原创绘制脚本：`draw_house.lua`。固定构图及确定性配色，重新执行可以复现。

## Aseprite 安装

已从 [Aseprite 官方 v1.3.18.3 源码包](https://github.com/aseprite/aseprite/releases/tag/v1.3.18.3) 编译 Apple Silicon 原生图形界面版本，安装到：

`/Users/dev/Applications/Aseprite.app`

本地编译版报告版本为 `Aseprite 1.3.18.3-dev`。使用 Xcode 16.2、CMake 3.x、Ninja 及官方 `m124-08a5439a6b` ARM64 Skia 预编译依赖；Release 构建。编译缓存位于 `/private/tmp/aseprite-house-build`，安装后的应用不依赖该缓存。

## 重新绘制与验证

```sh
"/Users/dev/Applications/Aseprite.app/Contents/MacOS/aseprite" -b \
  --script-param output="/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house" \
  --script "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/draw_house.lua"

"/Users/dev/Applications/Aseprite.app/Contents/MacOS/aseprite" -b \
  --script-param output="/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house" \
  --script "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/verify_house.lua"

"/Users/dev/Applications/Aseprite.app/Contents/MacOS/aseprite" -b \
  "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/hearth-cottage-preview.png" \
  --scale 4 \
  --save-as "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/hearth-cottage-preview-4x.png"
```

`verify_house.lua` 检查源文件尺寸、图层数、单帧、透明背景、画布边界，以及 PNG 与 Aseprite 合成结果逐像素一致性。

这是独立的 Aseprite 像素画样件；`.gdignore` 将绘制源文件和展示预览保留为独立美术资料。
