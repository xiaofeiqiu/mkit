# 炉边小屋 · 材质细化版

依据用户 2026-09-06 提供的中世纪等距建筑概念板，直接在 Aseprite 中通过原创 Lua 绘制脚本制作。参考板保存在 `style-reference.png`；没有裁切参考图的建筑作为成品。

- **画布**：512 × 480，RGBA 透明底，2:1 地面投影。
- **源文件**：`hearth-cottage-crafted.aseprite`，13 个可编辑图层。
- **透明 PNG**：`hearth-cottage-crafted.png`。
- **预览**：`hearth-cottage-crafted-preview.png`。
- **生成脚本**：`draw_crafted_house.lua`，固定随机种子，可复现。

这一版增加了单片搭接陶瓦、补瓦和局部苔色，逐块石材的色差与磕损，沿木构方向绘制的木纹和木节，檐下遮蔽、窗台水痕、铅条玻璃窗、老虎窗、石烟囱、铁灯、花箱、药草、木栅栏和旧石铺地。作为参考质感的 Aseprite 样张保留，上一版在上一级目录。

## 重新绘制

```sh
"/Users/dev/Applications/Aseprite.app/Contents/MacOS/aseprite" -b \
  --script-param output="/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/crafted" \
  --script "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/crafted/draw_crafted_house.lua"
```

`verify_crafted.lua` 重新打开源文件，检查尺寸、图层数、透明背景、内容边界及 PNG 逐像素一致性。结果见 `verification.txt`。
