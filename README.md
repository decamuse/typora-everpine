<div align="center">
  <img src="笔记图片/cover.png" alt="Everpine：低饱和多彩 Typora 主题" width="100%">
</div>
<div align="center">

[![Typora](https://img.shields.io/badge/Typora-Theme-a7c080?style=flat-square)](https://typora.io)
[![Style](https://img.shields.io/badge/Style-Dark%20%26%20Light%20Multicolor-83c092?style=flat-square)](#五成品截图)
[![License](https://img.shields.io/badge/License-MIT-7fbbb3?style=flat-square)](LICENSE)

</div>

## 一、简介

Everpine 是一套低饱和多彩的 Typora 主题，包含深色版 Everpine 与浅色版 Everpine Light。两套主题采用统一的设计语言与色相体系，浅色版针对各色阶重新校准了对比度，并非简单的反色处理。

正文采用分级配色：一级标题为亮绿，二级及以下标题依次使用绿、青、紫、橙、灰绿，并逐级降低明度；加粗文字采用暖黄，行内代码采用泡沫青，表头采用蓝色，告警框则提供五种颜色分类。

窗口整体采用卡片式设计，目录、正文、代码块、表格、引用块与图片分别使用独立的底色层级，并统一应用细线描边、分层阴影与 150ms 过渡动效。

主题完整适配并重绘了 Typora 界面，包括菜单页、偏好设置、查找替换、弹窗、文件树与滚动条。

导出功能同样经过适配，覆盖 PDF、HTML 与 Word 三种格式，确保不同格式下的配色、排版与文档样式保持统一。

建议搭配 [typora_plugin](https://github.com/obgnail/typora_plugin) 插件使用。

## 二、字体

主题为正文、界面和代码分别配置了两款字体，共提供两套字体搭配。六款字体均随主题附带，安装后重启 Typora 即可生效。两套方案可通过修改 CSS 中对应的字体名称顺序进行切换。

### 2.1 默认方案

适合接口文档、开发笔记、技术博客等注重信息密度与阅读效率的场景：

| 位置 | 字体 | 应用位置 |
|:---|:---|:---|
| 正文 | [Source Han Sans SC（思源黑体）](https://github.com/adobe-fonts/source-han-sans) | 标题、段落、列表、表格、引用与左侧大纲 |
| 界面 | [LXGW WenKai（霞鹜文楷）](https://github.com/lxgw/LxgwWenKai) | 菜单、标题栏、窗口标签、文件树、偏好设置与正文目录标签 |
| 代码 | [Maple Mono NL NF Mono CN](https://github.com/subframe7536/maple-font) | 代码块、行内代码、键帽 |

### 2.2 阅读方案

适合散文随笔、评论专栏、论文报告等注重文字表现与阅读体验的场景：

| 位置 | 字体 | 应用位置 |
|:---|:---|:---|
| 正文 | [Source Han Serif SC（思源宋体）](https://github.com/adobe-fonts/source-han-serif) | 标题、段落、列表、表格、引用与左侧大纲 |
| 界面 | [Zhuque Fangsong（朱雀仿宋）](https://github.com/TrionesType/zhuque) | 菜单、标题栏、窗口标签、文件树、偏好设置与正文目录标签 |
| 代码 | [Cascadia Mono（不包含中文）](https://github.com/microsoft/cascadia-code) | 代码块、行内代码、键帽 |

## 三、安装方法

### 3.1 样式安装

> - 建议使用 Typora 1.8 及以上版本。告警框语法（GitHub Style Alert）自 1.8 起支持，低版本会将告警框渲染为普通引用块。
> - 主题主要在 Windows 环境下开发和调试，macOS 与 Linux 尚未经过完整测试。

1. 打开主题文件夹：Typora 菜单栏选择 「文件」 → 「偏好设置」 → 「外观」 → 「打开主题文件夹」；
2. 复制 `everpine.css`、`everpine-light.css` 与 `fonts` 文件夹到该目录，三者必须保持同级；
3. 重启 Typora，菜单栏选择 「主题」 → 「Everpine」 或 「Everpine Light」。

Typora 主题文件夹的默认路径：

- Windows：`C:\Users\<用户名>\AppData\Roaming\Typora\themes`
- macOS：`~/Library/Application Support/abnerworks.Typora/themes`
- Linux：`~/.config/Typora/themes`

### 3.2 导出配置

**PDF**：

1. 「文件」 → 「偏好设置」 → 「导出」 → 「PDF」；
2. 页面大小选 A4，页边距选自定义，上方 12 mm、下方 14 mm、左右各 14 mm。

![PDF 导出配置：页面大小与自定义页边距](笔记图片/偏好设置-导出PDF.png)

**Word**：

1. 「文件」 → 「偏好设置」 → 「导出」 → 「Word (.docx)」；

2.  「自定义参数」中填入过滤器参数，将路径替换为 `everpine-alert.lua` 实际存放位置：

   ```shell
   --lua-filter <过滤器存放路径>\everpine-alert.lua
   ```

3. 「样式文件」选择 `everpine-thesis-reference.docx`。


![Word 导出配置：样式文件与自定义参数](笔记图片/偏好设置-导出Word.png)

## 四、自定义

主题的自定义参数集中在 `everpine.css` 和 `everpine-light.css` 文件开头的 `:root` 区块。

| 变量组 | 控制内容 |
|:---|:---|
| `--ep-font-body` / `--ep-font-code` / `--ep-font-ui` | 正文、代码、界面三类字体 |
| `--ep-bg-*` | 各表面底色：窗口、侧栏、正文卡、抬升面、引用、代码块、浮层 |
| `--ep-text-*`、`--ep-comment` | 正文、次级、弱化三级文字色与代码注释色 |
| `--ep-green` 等 13 个强调色 | 标题层级色、加粗、行内代码、告警框、列表符号等 |
| `--ep-line-1` ～ `--ep-line-4` | 四档细线边框 |
| `--ep-radius-*` | 五档圆角：卡片、代码块、块级元素、行内 chip、提示 |
| `--ep-shadow-*` | 卡片、块级、浮层、图片四组阴影 |
| `--ep-speed`、`--ep-ease` | 全局动效时长与缓动曲线 |

## 五、成品截图

### 5.1 深色 Everpine

> 本例字体采用默认方案

#### 目录与正文

![正式文章](./笔记图片/正式文章.png)

![深色主题：大纲目录与正文卡片](笔记图片/目录+正文.png)

![深色主题：文件树与正文卡片](笔记图片/文件树+正文.png)

#### 引用与告警框

![深色主题：引用块与五色告警框](笔记图片/引用与告警框.png)

#### 表格

![深色主题：蓝色表头表格](笔记图片/表格.png)

#### 代码块

![深色主题：代码块与六色语法配色](笔记图片/代码块.png)

#### 数学公式

![深色主题：Mermaid 流程图与数学公式](笔记图片/数学公式.png)

#### 偏好设置

![深色主题：偏好设置窗口](笔记图片/偏好设置.png)

#### 菜单页

![深色主题：菜单页](笔记图片/菜单页.png)

### 5.2 浅色 Everpine Light

> 本例字体采用阅读方案

#### 文件树与正文

![浅色-正式文章](./笔记图片/浅色-正式文章.png)

![浅色主题：大纲目录与正文卡片](笔记图片/浅色-目录+正文.png)

![浅色主题：文件树与正文卡片](笔记图片/浅色-文件树+正文.png)

#### 引用与告警框

![浅色主题：引用块与五色告警框](笔记图片/浅色-引用与告警框.png)

#### 表格

![浅色-表格](./笔记图片/浅色-表格.png)

#### 代码块

![浅色主题：独立浅底代码面板与六色语法配色](笔记图片/浅色-代码块.png)

#### 数学公式

![浅色-数学公式](./笔记图片/浅色-数学公式.png)

#### 偏好设置

![浅色-偏好设置](./笔记图片/浅色-偏好设置.png)

#### 菜单页

![浅色-菜单页](./笔记图片/浅色-菜单页.png)

### 5.3 导出效果

#### PDF

![PDF 导出：大纲面板与告警框](笔记图片/导出-PDF.png)

#### HTML

![HTML 导出：侧栏大纲与暗色告警框](笔记图片/导出-HTML.png)

#### Word

![Word 导出：导航窗格与告警框样式](笔记图片/导出-Word.png)

## 六、许可

本主题采用 MIT 许可证发布。

内置的六款字体均采用 SIL OFL 1.1 许可证，版权归各自作者所有，可随主题一同分发。各字体对应的许可证文件均存放在 `fonts` 目录中。

| 字体 | 许可证文件 |
|:---|:---|
| Source Han Sans SC（思源黑体） | `fonts/LICENSE-SourceHanSansSC.txt` |
| Maple Mono NL NF Mono CN | `fonts/LICENSE-MapleMono.txt` |
| LXGW WenKai（霞鹜文楷） | `fonts/LICENSE-LXGWWenKai.txt` |
| Source Han Serif SC（思源宋体） | `fonts/LICENSE-SourceHanSerifSC.txt` |
| Zhuque Fangsong（朱雀仿宋） | `fonts/LICENSE-ZhuqueFangsong.txt` |
| Cascadia Mono | `fonts/LICENSE-CascadiaMono.txt` |
