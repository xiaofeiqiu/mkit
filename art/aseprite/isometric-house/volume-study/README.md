# 炉边小屋 · 实体结构修订

根据用户关于“屋顶、墙面、门窗太平”的反馈，将小屋重建为可编辑三维实体，再导入 Aseprite 整理成分层像素文件。

## 文件

- `hearth-cottage-volume.aseprite`：640 × 640，15 个图层，可选浅色背景默认隐藏。
- `hearth-cottage-volume.png`：透明 RGBA 导出。
- `hearth-cottage-volume-preview.png`：浅色底全图预览。
- `structure-details.png`：门窗与屋顶细节放大图。
- `cottage-volume.blend`：完整可编辑模型、材质、相机和灯光。
- `build_cottage.py`：确定性模型生成和渲染脚本。
- `assemble_aseprite.lua`：Aseprite 原生分层、保存与验证脚本。
- `geometry-record.json`：投影、尺寸、结构深度和材质分组记录。

## 这次的结构变化

- 墙厚 30 cm，门窗通过布尔运算切出贯穿墙体的真实开口。
- 门板退入约 24 cm，玻璃退入约 28 cm，保留窗洞的侧壁、顶面和自然遮蔽。
- 石窗台、托块、门拱砌块、窗框和外露木梁均为有厚度的实体。
- 每片瓦是独立封闭曲面，厚约 2.5 cm，有轻微拱起、下端抬升与上下层搭接。搭接处已留出净距，避免瓦片互相穿插。
- 老虎窗、烟囱内腔、灯架、花箱、花盆和木桶也有实际几何结构。
- 固定正交相机，地面两轴 2:1，俯角 30°，主光来自画面左上。

Aseprite 图层按最终渲染中的可见像素分组，完整保留材质和跨物体阴影。局部颜色、纹理可在 Aseprite 内编辑；修改墙体、洞口或朝向时，使用 Blender 源文件重新渲染，可得到被遮住的完整结构。

## 验证

`inspect_geometry.py` 用射线验证门板和两面玻璃确实处在墙内，而非贴在外墙上的平面。记录见 `geometry-verification.txt`。

`assemble_aseprite.lua` 在保存后重新打开 Aseprite 文件，验证 15 个图层、真实透明背景、画布边界，以及分层合成与 Blender RGBA 图逐像素一致。记录见 `verification.txt`。

## 重建

```sh
"/Applications/Blender.app/Contents/MacOS/Blender" --background \
  --python "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/volume-study/build_cottage.py"

"/Users/dev/Applications/Aseprite.app/Contents/MacOS/aseprite" -b \
  --script-param output="/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/volume-study" \
  --script "/Users/dev/workspace/gamedev/mkit/art/aseprite/isometric-house/volume-study/assemble_aseprite.lua"
```
