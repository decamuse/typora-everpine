-- 警告框样式映射：Typora 把 GitHub 警告框导出为 pandoc 的
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
