-- Typora 导出 docx 的样式适配过滤器，配合
-- everpine-thesis-reference.docx 中的段落与字符样式使用。
-- 覆盖以下内容：警告框映射、表格单元格字体、表号段落、
-- 图片居中与图题、公式段落、参考文献条目、行内代码随正文。

-- 1.1) 行内代码：Word 论文没有行内代码样式，惯例随正文呈现；
-- 这里把行内代码换成 custom-style 为 "Inline Code" 的 Span，
-- 该字符样式在参考文档中定义为空，完全继承所在段落的字体字号；
-- 代码块不受影响，仍走 Source Code 段落样式与语法高亮字符样式。
function Code(el)
  return pandoc.Span(el.text,
    pandoc.Attr("", {}, {["custom-style"] = "Inline Code"}))
end

-- 1) 警告框样式映射：Typora 把 GitHub 警告框导出为 pandoc 的
-- Div ("", ["<类型>", "alert"], [])，docx writer 只认 custom-style
-- 属性，这里把五个类型映射到参考文档中的五个段落样式
local kinds = { note = true, tip = true, important = true, warning = true, caution = true }

function Div(el)
  local kind = nil
  for _, c in ipairs(el.classes) do
    if kinds[c] then
      kind = c
      break
    end
  end
  if kind then
    el.attributes['custom-style'] = 'Alert ' .. kind
    return el
  end
end

-- 2) 表格单元格字体：pandoc 3.5 对单元格段落强制使用 Compact 样式
--（与紧凑列表共用），单元格内 Div 的 custom-style 压不过它；
-- 字符样式不受这个限制，所以把每个单元格的行内内容包进
-- custom-style 为 "Table Cell Char" 的 Span，五号黑体由参考文档
-- 中的字符样式给出，西文与数字沿用 Normal 的 Times New Roman。
-- 列对齐完全跟随 markdown：不重写 colspecs，未标对齐的列
-- 落回 Compact 的左对齐，:---、:---:、---: 原样呈现。
local function style_cell_block(blk)
  if blk.t == "Plain" or blk.t == "Para" then
    blk.content = { pandoc.Span(blk.content,
      pandoc.Attr("", {}, {["custom-style"] = "Table Cell Char"})) }
  end
  return blk
end

local function style_cell(cell)
  local out = {}
  for _, blk in ipairs(cell.content) do
    out[#out + 1] = style_cell_block(blk)
  end
  cell.content = out
  return cell
end

local function style_row(row)
  for i, cell in ipairs(row.cells) do
    row.cells[i] = style_cell(cell)
  end
end

function Table(tbl)
  for _, c in ipairs(tbl.classes) do
    if c == "ep-quote" then return tbl end
  end
  for _, row in ipairs(tbl.head.rows) do
    style_row(row)
  end
  for _, body in ipairs(tbl.bodies) do
    for _, row in ipairs(body.body) do
      style_row(row)
    end
  end
  return tbl
end

-- 3) 块级识别辅助
local stringify = pandoc.utils.stringify

-- 图片题注判空：Typora 对空 alt 也输出 [Str ""] 形式的题注
-- 而不是空列表，内容只有空白字符的 Str 一律按空处理。
local function caption_is_empty(cap)
  if cap == nil or #cap == 0 then return true end
  for _, inl in ipairs(cap) do
    if inl.t ~= "Str" or not inl.text:match("^%s*$") then
      return false
    end
  end
  return true
end

-- 整段只有图片（单图，或多图仅以换行分隔）时统一转为图片段；
-- pandoc 3.5 的 docx writer 只在 markdown 题注形状下生成
-- Captioned Figure，Typora 的原生形状（题注带 "fig:" 标题）下
-- 图片会落回正文段落带着首行缩进，题注文本只进图片描述属性，
-- 所以这里把图片与题注显式拆开，两种来源行为一致。
local function is_image_only_para(blk)
  if blk.t ~= "Para" then return false end
  local has_img = false
  for _, inl in ipairs(blk.content) do
    if inl.t == "Image" then
      has_img = true
    elseif inl.t ~= "LineBreak" and not (inl.t == "Str" and inl.text:match("^%s*$")) then
      return false
    end
  end
  return has_img
end

local function figure_blocks(blk)
  local fig_attr = pandoc.Attr("", {}, {["custom-style"] = "Figure"})
  local cap_attr = pandoc.Attr("", {}, {["custom-style"] = "Image Caption"})
  local out = {}
  local last_has_cap = false
  for _, inl in ipairs(blk.content) do
    if inl.t == "Image" then
      local cap = inl.caption or {}
      last_has_cap = not caption_is_empty(cap)
      inl.caption = {}
      out[#out + 1] = pandoc.Div({ pandoc.Para({ inl }) }, fig_attr)
      if last_has_cap then
        out[#out + 1] = pandoc.Div({ pandoc.Para(cap) }, cap_attr)
      end
    end
  end
  if #out == 0 then
    return { blk }, false
  end
  return out, last_has_cap
end

-- 列表项里的图片：图片段紧随所属条目，保持条目与插图的对应关系，
-- 与顶层图片同一套 Figure / Image Caption 处理；图片作为条目的
-- 后续段落，按列表续行缩进在条目可用宽度内居中。代码块、引用块
-- 与告警框仍提升到列表之后，嵌套列表递归处理。
local function is_alert_div(blk)
  if blk.t ~= "Div" then return false end
  for _, c in ipairs(blk.classes) do
    if kinds[c] then return true end
  end
  return false
end

local function split_figs(blocks, in_list)
  local cap_attr = pandoc.Attr("", {}, {["custom-style"] = "Image Caption"})
  local out, figs = {}, {}
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    if is_image_only_para(b) then
      local fbs, has_cap = figure_blocks(b)
      -- 列表项内的图片留在原地：条目文字、插图、图题按 markdown
      -- 顺序连续输出，插图不会脱离所属条目堆到列表末尾
      local dest = out
      for _, fb in ipairs(fbs) do
        dest[#dest + 1] = fb
      end
      if not has_cap and blocks[i + 1] ~= nil
          and blocks[i + 1].t == "Para"
          and not is_image_only_para(blocks[i + 1])
          and stringify(blocks[i + 1]):match("^图%s*%d") then
        dest[#dest + 1] = pandoc.Div({ blocks[i + 1] }, cap_attr)
        i = i + 1
      end
    elseif b.t == "CodeBlock" or b.t == "BlockQuote" or is_alert_div(b) then
      local dest = in_list and figs or out
      dest[#dest + 1] = b
    elseif b.t == "BulletList" or b.t == "OrderedList" then
      local newitems = {}
      for _, item in ipairs(b.content) do
        local keep, f2 = split_figs(item, true)
        if #keep > 0 then
          newitems[#newitems + 1] = keep
        end
        for _, fb in ipairs(f2) do
          figs[#figs + 1] = fb
        end
      end
      if #newitems > 0 then
        b.content = newitems
        out[#out + 1] = b
      end
      -- 列表整体处理完后，条目里提升出的代码块与引用框紧跟列表；
      -- 列表项内 dest 与 figs 是同一个表，先把 figs 换成新表再回填，
      -- 避免对正在 ipairs 遍历的表追加元素导致死循环与内存耗尽
      local drained = figs
      figs = {}
      local dest = in_list and figs or out
      for _, fb in ipairs(drained) do
        dest[#dest + 1] = fb
      end
    else
      out[#out + 1] = b
    end
    i = i + 1
  end
  return out, figs
end

-- 独立成块的显示公式：Typora 把公式块导出为
-- Plain [Math DisplayMath "…"]，markdown 路径则是 Para，两种都接
local function is_display_math_block(blk)
  return (blk.t == "Plain" or blk.t == "Para") and #blk.content == 1
    and blk.content[1].t == "Math"
    and blk.content[1].mathtype == "DisplayMath"
end

-- 5) 列表里的代码块、引用块、告警框提升到列表之后：引用块与告警框
-- 要按整栏宽的单格表格渲染，代码块在列表项内会带上续行的编号缩进，
-- 三者统一放到列表之后。引用块与告警框内部的列表改为带前缀的段落：
-- pandoc 给列表段落写死的编号缩进（numbering 级，压过样式缩进）会让
-- 项目符号位置无法从参考文档控制，还会打断竖条与底纹；转成普通段落后，
-- 前缀落在文字起点，后跟制表符把正文推进到悬挂缩进位，换行对齐到
-- 正文而不是前缀下。制表符必须包在 run 里，裸 <w:tab/> 写在
-- 段落层会被 Word 忽略；制表位由段样式的显式 tab stop 给出，
-- 无序列表用 210 缇，有序列表编号更宽，用 315 缇。
local bullet_chars = { [1] = "•", [2] = "◦", [3] = "▪" }

local function prefixed_para(prefix, inlines)
  local content = { pandoc.Str(prefix),
    pandoc.RawInline("openxml", "<w:r><w:tab/></w:r>") }
  for _, il in ipairs(inlines) do
    content[#content + 1] = il
  end
  return pandoc.Para(content)
end

local function expand_quoted_list(blk, level)
  local out = {}
  for idx, item in ipairs(blk.content) do
    local prefix
    if blk.t == "BulletList" then
      prefix = bullet_chars[level] or "▪"
    else
      prefix = tostring(idx) .. "."
    end
    local first_done = false
    for _, ib in ipairs(item) do
      if ib.t == "BulletList" or ib.t == "OrderedList" then
        for _, sb in ipairs(expand_quoted_list(ib, level + 1)) do
          out[#out + 1] = sb
        end
      elseif (ib.t == "Para" or ib.t == "Plain") and not first_done then
        out[#out + 1] = prefixed_para(prefix, ib.content)
        first_done = true
      else
        out[#out + 1] = ib
      end
    end
    if not first_done then
      out[#out + 1] = prefixed_para(prefix, {})
    end
  end
  return out
end

local function flatten_quoted_lists(blocks)
  local out = {}
  for _, cb in ipairs(blocks) do
    if cb.t == "BulletList" or cb.t == "OrderedList" then
      for _, pb in ipairs(expand_quoted_list(cb, 1)) do
        out[#out + 1] = pb
      end
    else
      out[#out + 1] = cb
    end
  end
  return out
end

-- 无编号一级标题：摘要、目录、参考文献、致谢、附录按规范是
-- 一级标题样式但不带「第N章」编号；Heading1 样式的自动编号是
-- 样式级配置，单段取消不了，这里换挂到 Heading Unnumbered 样式
--（继承 Heading1 的三号加粗居中，numId 0 关闭编号，保留大纲级别）。
local unnumbered = {
  ["摘要"] = true, ["ABSTRACT"] = true, ["目录"] = true,
  ["参考文献"] = true, ["致谢"] = true, ["附录"] = true,
}

local function is_unnumbered_h1(blk)
  if blk.t ~= "Header" or blk.level ~= 1 then return false end
  local txt = stringify(blk):gsub("%s", "")
  return unnumbered[txt] == true
end

-- 6) 引用块与告警框整体转为单格表格（Quote Box 系列表格样式）：
-- Word 的段落底纹跟随段落缩进绘制、不覆盖「边框-文字间距」区域，
-- 段落方案下竖条贴边与文字内边距不可兼得；单格表格里竖条是表格
-- 左边框、底纹是单元格底纹（都贴表格边缘），文字内边距用单元格
-- 边距，互不牵连。这是 Word 提示框的通行做法。
local KIND_STYLE_IDS = { note = "QuoteBoxNote", tip = "QuoteBoxTip",
  important = "QuoteBoxImportant", warning = "QuoteBoxWarning", caution = "QuoteBoxCaution" }

local function get_alert_kind(blk)
  for _, c in ipairs(blk.classes) do
    if kinds[c] then return c end
  end
  return nil
end

local function unwrap_quotes(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    if b.t == "BlockQuote" then
      for _, sb in ipairs(unwrap_quotes(b.content)) do
        out[#out + 1] = sb
      end
    else
      out[#out + 1] = b
    end
  end
  return out
end

-- 引用框表格骨架：pandoc 3.5 的 Lua 无法构造 Table（无 TableBody
-- 构造器，纯表会被丢弃，pandoc.Table 在本版本不可调用），此前用
-- pandoc.write/pandoc.read 按内容逐个构建又会在引用块密集的大文
-- 档上内存耗尽。改为骨架只解析一次（固定短字符串，与文档大小无
-- 关），之后每个引用框在骨架副本里用 walk 把占位段替换成真实内容，
-- 单次成本只有一次浅遍历。
local SKELETONS = {}
local MARKER = "EPQUOTE_MARKER"

-- 骨架列宽 1.0001（tblW pct 5001，即 100.02% 版心）：pandoc 对
-- 显式列宽写 fixed 布局，Word 对超过 100% 的百分比表格按固定基
-- 准（约 432.4pt，pandoc 默认 Letter 版心宽）页面居中排版，宽度
-- 与内容无关、稳定落在代码块边框外侧约半磅处；pandoc 默认列宽
-- （100% 及以下）则按 gridCol 7920 缇渲染，框会窄于 A4 栏宽。
-- 符合规范的渲染器把 100.02% 按版心计算，同样是通栏效果。
local function get_skeleton(style_id)
  if SKELETONS[style_id] == nil then
    local nat = string.format(
      '[Table ("",["ep-quote"],[("custom-style","%s")]) '
      .. '(Caption Nothing []) [(AlignDefault,ColWidth 1.0002)] '
      .. '(TableHead ("",[],[]) []) '
      .. '[TableBody ("",[],[]) (RowHeadColumns 0) [] [Row ("",[],[]) '
      .. '[Cell ("",[],[]) AlignDefault (RowSpan 1) (ColSpan 1) '
      .. '[Para [Str "%s"]]]]] '
      .. '(TableFoot ("",[],[]) [])]',
      style_id, MARKER)
    local ok, doc = pcall(pandoc.read, nat, "native")
    if ok and doc ~= nil and doc.blocks ~= nil
        and doc.blocks[1] ~= nil and doc.blocks[1].t == "Table" then
      SKELETONS[style_id] = doc.blocks[1]
    else
      SKELETONS[style_id] = false
    end
  end
  return SKELETONS[style_id]
end

-- 框内段落分三套样式：无序列表段与有序列表段各挂悬挂缩进样式
--（有序编号更宽，制表位与悬挂位都取 315 缇以容纳两位数），其余
-- 挂 Quote Text。每段单独包一层 custom-style Div，避免整框共用
-- 一个样式后悬挂缩进误伤普通段。
local function prefixed_style(blk)
  if blk.t ~= "Para" or blk.content[1] == nil or blk.content[1].t ~= "Str" then
    return nil
  end
  if blk.content[2] == nil or blk.content[2].t ~= "RawInline" then
    return nil
  end
  if blk.content[1].text:match("^%d+%.$") then
    return "Quote List Ordered Para"
  end
  return "Quote List Para"
end

local function quote_inner(blocks)
  local out = {}
  for _, b in ipairs(blocks) do
    local style = prefixed_style(b) or "Quote Text"
    out[#out + 1] = pandoc.Div({ b },
      pandoc.Attr("", {}, {["custom-style"] = style}))
  end
  return out
end

local function quote_table(blocks, style_name)
  local inner = quote_inner(unwrap_quotes(blocks))
  local skeleton = get_skeleton(style_name)
  if skeleton == false then
    return pandoc.Div(inner,
      pandoc.Attr("", {}, {["custom-style"] = style_name}))
  end
  return pandoc.walk_block(skeleton, {
    Para = function(p)
      if #p.content == 1 and p.content[1].t == "Str"
          and p.content[1].text == MARKER then
        return inner
      end
      return p
    end,
  })
end

-- 4) 全文档遍历：
--    - 「表 + 数字」开头且紧贴表格的段落 → Table Caption
--    - 整段只有图片 → 逐图拆成 Figure 段（居中），非空题注拆出
--      Image Caption 段，紧随其后且无题注时的「图 + 数字」段落
--      也归为 Image Caption
--    - 列表里的代码块、引用块、告警框提升到列表之后
--    - 引用块与告警框内部的列表转成带「•」前缀的段落，
--      竖条与底纹保持连续，文字与前缀离竖条一个字符
--    - 独立成块的显示公式 → Formula（样式居中）
--    - 摘要、目录、参考文献、致谢、附录的一级标题 → Heading Unnumbered
--    - 「参考文献」一级标题之后、以 [数字] 开头的段落 → Bibliography
function Pandoc(doc)
  local blocks = split_figs(doc.blocks, false)
  local out = {}
  local i = 1
  while i <= #blocks do
    local b = blocks[i]
    local nxt = blocks[i + 1]
    if b.t == "Para" and nxt ~= nil and nxt.t == "Table"
        and stringify(b):match("^表%s*%d") then
      out[#out + 1] = pandoc.Div({ b },
        pandoc.Attr("", {}, {["custom-style"] = "Table Caption"}))
    elseif is_display_math_block(b) then
      out[#out + 1] = pandoc.Div({ pandoc.Para(b.content) },
        pandoc.Attr("", {}, {["custom-style"] = "Formula"}))
    elseif is_unnumbered_h1(b) then
      -- docx writer 对 Header 硬编码标题样式，Div 的 custom-style
      -- 压不上去，所以转成 Para 再挂样式；大纲级别在样式里保留
      out[#out + 1] = pandoc.Div({ pandoc.Para(b.content) },
        pandoc.Attr("", {}, {["custom-style"] = "Heading Unnumbered"}))
    else
      out[#out + 1] = b
    end
    i = i + 1
  end
  local in_refs = false
  for j = 1, #out do
    local b = out[j]
    local hdr = nil
    if b.t == "Header" then
      hdr = b
    elseif b.t == "Div" and b.content[1] ~= nil and b.content[1].t == "Header" then
      hdr = b.content[1]
    end
    if hdr ~= nil then
      in_refs = (hdr.level == 1 and stringify(hdr):match("^参考文献"))
    elseif b.t == "Div" and b.attributes["custom-style"] == "Heading Unnumbered"
        and b.content[1] ~= nil and b.content[1].t == "Para" then
      in_refs = (stringify(b.content[1]):match("^参考文献") ~= nil)
    elseif in_refs and b.t == "Para" and stringify(b):match("^%s*%[%d+%]") then
      out[j] = pandoc.Div({ b },
        pandoc.Attr("", {}, {["custom-style"] = "Bibliography"}))
    end
  end
  for j = 1, #out do
    local b = out[j]
    if b.t == "BlockQuote" then
      b.content = flatten_quoted_lists(b.content)
      out[j] = quote_table(b.content, "QuoteBox")
    elseif is_alert_div(b) then
      local kind = get_alert_kind(b)
      b.content = flatten_quoted_lists(b.content)
      out[j] = quote_table(b.content,
        KIND_STYLE_IDS[kind] or "QuoteBoxNote")
    end
  end
  doc.blocks = out
  return doc
end
