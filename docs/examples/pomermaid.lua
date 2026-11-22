-- pomermaid.lua: a pandoc Lua filter that draws each fenced `mermaid`
-- code block with pomermaid: pic for ms, MetaPost for ConTeXt, and
-- SVG for HTML. Other formats keep the code block.
--
--   pandoc --lua-filter pomermaid.lua -t ms --pdf-engine=pdfroff \
--     --pdf-engine-opt=-p doc.md -o doc.pdf
--
-- The attributes `width` and `size` of the code block, as
-- ```{.mermaid width=4i size=9}, are passed to pomermaid's --width
-- and --size.

local targets = {
  ms = 'pic',
  context = 'mp',
  html = 'svg', html4 = 'svg', html5 = 'svg',
}

function CodeBlock (el)
  if not el.classes:includes('mermaid') then return nil end
  local to = targets[FORMAT]
  if to == nil then return nil end
  local args = {'-t', to}
  for _, name in ipairs({'width', 'size'}) do
    if el.attributes[name] then
      table.insert(args, '--' .. name .. '=' .. el.attributes[name])
    end
  end
  local out = pandoc.pipe('pomermaid', args, el.text)
  if to == 'svg' then
    -- pdftocairo's SVG starts with an XML declaration, which HTML
    -- does not want.
    out = out:gsub('^<%?xml.-%?>%s*', '')
    return pandoc.RawBlock('html', '<div class="mermaid">' .. out .. '</div>')
  end
  return pandoc.RawBlock(FORMAT, out)
end
