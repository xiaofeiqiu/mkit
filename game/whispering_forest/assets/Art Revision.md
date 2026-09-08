# 晨铃城素材修订：绿色与场景尺度

2026-09-06 · 按用户实机反馈修订。

用户指出原样板素材偏黄、场景比例不对，并明确要调整人物、NPC、树木与建筑的整体大小关系。本次使用内置 imagegen 编辑环境图集与草地；在 Godot 中统一可见人物高度、物件尺度、碰撞及头顶标记。

## 尺度基准

以下是 1× 镜头下的世界显示尺寸；默认镜头 1.1×，所有物件共同放大，UI 独立。

| 项目 | 修订后的基准 |
|---|---|
| 玩家 / 普通人形 NPC | 可见身体约 72 px，高度按内容而非源图留白计算 |
| 普通哥布林 / 精英 | 身体约 56 / 74 px |
| 住宅与街区 | 图集区域显示宽 300–380 px，配置 64–78 逻辑单位脚底碰撞 |
| 大树 | 场内图集区域宽 210–258 px，树冠高度明显超过人物 |
| 灌木 | 图集区域宽 32–48 px，控制在人物膝部至腰部附近 |
| 门洞 | 按人物高度检查可通过的净高，不能比人物矮 |

人物脚底仍落在统一斜视平面，地面格子仍是 64×32。角色头身比、正式逐帧动画是后续美术工序，不把整体缩放当作完成动画。

## 配色基准

树冠采用中绿、深绿和少量浅绿高光；草地为自然中绿。蓝灰屋顶、灰白石材、棕木构成主城建筑。金色只少量保留在铜铃及火系/怒气反馈中。去掉黄花树效果、橙黄窗光和偏黄环境粒子。

## 生成提示词记录

生成工具：OpenAI 内置 imagegen。编辑目标均为样板原创源图或本次中间图，完整原图保留在生成目录；最终采用的文件在素材清单记录。

### environment

```text
Use case: precise-object-edit. Asset type: production transparent isometric game environment sprite atlas. Edit target: supplied environment atlas. Primary request: correct its heavy yellow cast to a natural green village palette while STRICTLY PRESERVING every object's exact silhouette, position, scale, spacing, and atlas layout. Replace yellow/golden blossoms and yellow leaves across the whole oak canopy with ordinary living emerald, medium leaf green and sage green oak leaves, cool forest-green shadows. The tree is a green leafy summer oak, NOT a yellow flowering tree. Keep bright leaf highlights restrained and pale green; no golden sunbeams. Cottage: keep its architecture, blue-grey slate roof, timber and door identical; walls neutral light grey/beige, wood natural brown; windows subtle neutral daylight, no orange glowing windows. Gate: same stone pillars and wood geometry; grey stone and green ivy; preserve little brass bell as the only small gold detail. Shrub: dark/mid green foliage with small white daisies and a few lavender flowers, remove all yellow/orange flowers. Lighting neutral diffuse daylight, gentle shadow on lower-right, no warm color grading. Four sprites stay exactly in their current regions: top-left oak, top-right cottage, lower-left gate, lower-right shrub. Do not move or resize them. Keep genuine alpha transparency in all empty pixels; no white background, no checkerboard graphic, no ground scene. Original hand-painted raster game art, clear broad foliage masses at small game scale, less sparkling fine detail. No text, no UI.
```

### grass

```text
Use case: precise-object-edit. Asset type: seamless top-down grass material for an isometric village game. Edit target: supplied grass texture. Replace the pervasive yellow/olive cast with fresh natural medium green grass, muted sage highlights and cool forest-green shadows. It should read unmistakably green, never yellow, golden, brown, orange, neon lime or teal. Reduce excessive high-frequency clover detail: softly painted short meadow grass with occasional small clover leaves, broad calm readable areas so small game characters remain easy to see. Preserve continuous uniform scale and edge-to-edge seamless repeat, no focal point, no vignette, no directional cast shadows, no added objects, no flowers, no path, no border. Neutral diffuse midday daylight, no sunset filter. Opaque square texture.
```

### environment_alpha

```text
Use case: background-extraction. Edit target: supplied green tree/cottage/gate/shrub sprite atlas. Remove ONLY the grey-and-white checkerboard background and replace it with genuine alpha transparency. All background, including enclosed openings under the gate and between leaves, must be transparent pixels. The checkerboard is unwanted painted background, not an object. Keep the green leaves, neutral daylight, blue slate roof, neutral stone and all object pixels, outlines, shapes, layout and image dimensions EXACTLY unchanged. No color adjustment. No new background, no checkered graphic. Output a truly transparent RGBA PNG suitable for game sprites.
```

### grass_green

```text
Use case: precise-object-edit. Edit target: supplied grass texture. Change ONLY its colors to a clearly natural GREEN meadow palette with NO yellow/olive cast. Base grass should be approximately #548163 (RGB 84,129,99), mid-tone #628E67, highlights #83AF83 and shadow #3D654A. Color channels must have visibly more blue than the supplied yellow-green texture. Green leaves, green clover, soft neutral daylight. Preserve exact texture layout, plant shapes, small detail and seamless edge-to-edge tiling. Do not add plants, do not add paths or flowers, no vignette, no shadows. Opaque square image.
```

## 参考图校准与城市拼装（v0.3）

用户随后提供明亮绿色的画面参考与法兰城式街区参考，均存于 `game-design/TileMap-ref/`。当前地表采用 `grass-daylight.png`，并在Godot材质绘制中以 `Color(0.89,0.84,1.03)` 调整显示颜色，保留源图像素。参考草地局部均色约RGB(0.417,0.650,0.382)，本次生成草地局部均色约(0.466,0.774,0.371)，该乘色用于接近参考；局部取样只作校色辅助，最终仍以实机整体比较为准。旧 `grass-green.png` 偏暗，已停止加载。

城镇扩为48×40逻辑格的五街区。草地和石路是重复纹理；12栋住宅、12棵树、16丛花草、1座城门和5座传送石分别实例化，召唤台与池水由引擎绘制。没有使用整城生成图片作为场景。`scripts/maps.gd`存摆放、`city.gd`存传送站/落点，`terrain.gd`存地面，`prop.gd`处理独立脚底锚点、Y遮挡与碰撞。正式专用服务建筑后续替换复用住宅，无需重绘整个城市。

新城门与传送石均为独立原创RGBA素材。城门图集按有效透明边界裁区，显示宽310px，两个门柱分别配置碰撞；石头显示宽79px，脚底碰撞15单位，正常人形身高仍为72px。传送石五次复用同一纹理，地点文字使用中英UI层；传送效果在代码中播放。

以下为本轮追加提示词：

### grass_reference

```text
Use case: precise-object-edit. Asset type: seamless grass texture for a bright classic isometric RPG. Image 1 is the texture to edit. Image 2 is the user's exact BRIGHTNESS and GREEN reference only; do not copy any buildings, UI, text, or composition from it. Match the cheerful sunlit mint/leaf-green grass in image 2. The current image 1 is much too dark, blue-grey and desaturated. Raise midtone brightness substantially, aim for base #79B976, lights #9CCB88 and shadows #5A985D, with fresh balanced green rather than olive yellow or blue-grey teal. Keep the small grass texture calm and soft, fewer high-frequency clover outlines; retain seamless tile repeat across all four edges. Neutral bright daytime light, not sunset or moody forest. An opaque square grass material only, no path, no furniture, no flowers, no text, no vignette. Preserve original texture as the source but closely follow the second image's light cheerful grass colors.
```

### city_gate

```text
Use case: stylized-concept. Asset type: one original transparent game sprite of a COMPACT CITY GATE. This is for the first scene of a bright classic isometric JRPG: a small welcoming walled town, not a giant royal capital. Orthographic 2:1 isometric view, visible front arch and right side, ground diamond axis slope 1:2. A substantial pale limestone arched gateway with two short square watchtowers, blue slate roofs, cream plaster, restrained warm wooden doors fully open; the opening is wide and tall enough for travelers. A small blue banner on each tower, a little climbing green ivy at the base, restrained hand-painted detail. Broad clear silhouettes readable at 320 px displayed width. Bright soft neutral midday daylight, cheerful light stone, fresh leaf green accents, blue roof. NO yellow wash, NO dark fantasy, NO glossy 3D render, NO sunset. Entire gate including tower tops and base fits within the square canvas with at least 40px empty margins. Empty open passage remains transparent, no floor plaza, no surrounding ground, no additional loose objects, no UI or lettering. TRUE TRANSPARENT ALPHA background, an actual RGBA sprite PNG, never a drawn checkerboard or solid white backdrop.
```

### waystone

```text
Use case: stylized-concept. Asset type: one original TRANSPARENT game sprite of a town teleport waystone, for a bright cheerful classic isometric JRPG. A modest standing pale grey stone monolith, softly rounded angular top, about the height of a human and a half, rooted in a low circular carved limestone plinth. A single luminous cyan-blue crystal inset in its center and a simple abstract circular rune, a few tiny blue light motes close to the stone. It should read as an accessible everyday transport landmark in a peaceful city, not an enormous divine portal. Orthographic 2:1 isometric camera: see stone front, right side, and the top of the plinth, consistent upper-left soft daylight. Bright neutral limestone, restrained cool blue magic, tiny natural green grass tufts at the base only. Clear simple silhouette readable at 65px wide and 105px tall in-game, hand-painted raster game art with broad shapes. Full object entirely visible with ample empty margin. Actual RGBA transparent background, no painted checkerboard, no floor scene, no shadow plane, no text, no UI, no labels, no surrounding architecture.
```

## v0.4 人物动态与立体造型

人物已按新的两张参考改为简洁立体体块。当前源资产为可编辑3D关节模型，八方向与步态从同一模型渲染；旧四向人物/单姿态导师源图仍保留，运行时已经切换至characters/目录。详细造型、帧数、锚点、动作与验证记录见[人物动态说明](../art/characters/README.md)。环境仍使用独立生成素材拼装，后续继续统一环境笔触与人物表现。
