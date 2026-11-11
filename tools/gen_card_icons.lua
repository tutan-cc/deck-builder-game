-- gen_card_icons.lua -- 生成五张卡的 16x16 图标
-- Aseprite 批处理：为五张卡生成专属 16x16 像素图标
-- 用法: aseprite -b --script gen_card_icons.lua

local SZ = 16
local OUT = "D:/deepseek工作区/deck-builder-game/art/cards/icons/"
local PREV = "D:/aseprite-build/out/icons_preview.png"

---------------------------------------------------------------------------
-- 调色板（对着 Kenney Tiny Dungeon 的观感配的：冷调钢灰 + 暖色点缀 + 深描边）
---------------------------------------------------------------------------
local P = {
  ["K"] = { 26, 22, 26, 255 },    -- 描边
  ["W"] = { 238, 243, 250, 255 }, -- 高光
  ["S"] = { 176, 190, 208, 255 }, -- 钢 亮
  ["s"] = { 120, 134, 156, 255 }, -- 钢 中
  ["d"] = { 72, 84, 104, 255 },   -- 钢 暗
  ["B"] = { 132, 90, 56, 255 },   -- 木柄
  ["b"] = { 88, 58, 38, 255 },    -- 木柄暗
  ["Y"] = { 232, 196, 96, 255 },  -- 金
  ["O"] = { 214, 124, 64, 255 },  -- 橙（冲击）
  ["R"] = { 198, 74, 74, 255 },   -- 红
  ["U"] = { 108, 150, 214, 255 }, -- 蓝
  ["u"] = { 62, 96, 152, 255 },   -- 蓝暗
}

local function newpx()
  local t = {}
  for y = 0, SZ - 1 do
    t[y] = {}
    for x = 0, SZ - 1 do t[y][x] = nil end
  end
  return t
end

local function put(px, x, y, c)
  if x >= 0 and y >= 0 and x < SZ and y < SZ then px[y][x] = c end
end

-- 用字符画定义图标：每行必须正好 16 个字符
local function from_ascii(rows)
  local px = newpx()
  for y, row in ipairs(rows) do
    assert(#row == SZ, "第 " .. y .. " 行长度 " .. #row .. "，应为 " .. SZ)
    for x = 1, SZ do
      local ch = row:sub(x, x)
      if ch ~= "." then
        assert(P[ch], "未知颜色字符: " .. ch)
        px[y - 1][x - 1] = ch
      end
    end
  end
  return px
end

-- Bresenham 直线
local function line(px, x0, y0, x1, y1, c)
  local dx, dy = math.abs(x1 - x0), -math.abs(y1 - y0)
  local sx = (x0 < x1) and 1 or -1
  local sy = (y0 < y1) and 1 or -1
  local err = dx + dy
  while true do
    put(px, x0, y0, c)
    if x0 == x1 and y0 == y1 then break end
    local e2 = 2 * err
    if e2 >= dy then err = err + dy; x0 = x0 + sx end
    if e2 <= dx then err = err + dx; y0 = y0 + sy end
  end
end

-- 粗线：先铺一圈描边，再填芯
-- 只用 4 邻域：带对角描边时，多条平行线会互相吃掉描边糊成黑块。
local function thick_line(px, x0, y0, x1, y1, core, outline)
  outline = outline or "K"
  for _, o in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
    line(px, x0 + o[1], y0 + o[2], x1 + o[1], y1 + o[2], outline)
  end
  line(px, x0, y0, x1, y1, core)
end

-- 细线 + 4 邻域描边
local function thin_line(px, x0, y0, x1, y1, core, outline)
  outline = outline or "K"
  for _, o in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
    line(px, x0 + o[1], y0 + o[2], x1 + o[1], y1 + o[2], outline)
  end
  line(px, x0, y0, x1, y1, core)
end

---------------------------------------------------------------------------
-- 1. 打击：竖立的剑（钢刃 + 金护手 + 木柄）
---------------------------------------------------------------------------
local STRIKE = {
  ".......KK.......",
  "......KWWK......",
  "......KWSK......",
  "......KWSK......",
  "......KWSK......",
  "......KWSK......",
  "......KWSK......",
  "......KWSK......",
  "....KKKKKKKK....",
  "....KYYYYYYK....",
  "......KBBK......",
  "......KBBK......",
  "......KBBK......",
  "......KYYK......",
  ".......KK.......",
  "................",
}

---------------------------------------------------------------------------
-- 2. 防御：盾牌（钢面 + 金色盾芯）
---------------------------------------------------------------------------
local DEFEND = {
  "................",
  "....KKKKKKKK....",
  "...KSssssssSK...",
  "...KSssssssSK...",
  "...KSssYYssSK...",
  "...KSssYYssSK...",
  "...KSssssssSK...",
  "...KSssssssSK...",
  "...KSssssssSK...",
  "....KSssssSK....",
  "....KSssssSK....",
  ".....KSssSK.....",
  "......KSSK......",
  ".......KK.......",
  "................",
  "................",
}

---------------------------------------------------------------------------
-- 3. 横扫：三道斜向斩痕（多段/范围攻击的经典表达）
--    初版画成横向三根杠，读起来像"三"，重画成 45° 斜斩。
---------------------------------------------------------------------------
local function cleave_icon()
  local px = newpx()
  thin_line(px, 1, 10, 6, 5, "s")    -- 尾斩（最弱，先画，被主斩压住）
  thin_line(px, 5, 14, 11, 8, "S")   -- 次斩
  thick_line(px, 2, 12, 11, 3, "W")  -- 主斩
  return px
end

---------------------------------------------------------------------------
-- 4. 重击：巨锤（宽厚锤头 + 长柄）
---------------------------------------------------------------------------
local BASH = {
  "................",
  "..KKKKKKKKKKK...",
  "..KdddddddddK...",
  "..KdSSSSSSSdK...",
  "..KdSsssssSdK...",
  "..KdddddddddK...",
  "..KKKKKKKKKKK...",
  "......KBBK......",
  "......KBBK......",
  "......KBBK......",
  "......KBBK......",
  "......KBBK......",
  "......KYYK......",
  ".......KK.......",
  "................",
  "................",
}

---------------------------------------------------------------------------
-- 5. 铁壁：盾 + 贯穿其中的竖立剑（攻击与格挡并存）
--    初版横插一道斜线，糊成一团；改成沿盾中轴竖插，结构更清楚。
---------------------------------------------------------------------------
local function iron_wave()
  local px = from_ascii(DEFEND)
  -- 剑刃沿盾中轴（第 7、8 列）。用金色：盾面是浅钢，白刃在上面不显。
  for y = 2, 9 do
    put(px, 7, y, "Y")
    put(px, 8, y, "Y")
  end
  put(px, 7, 1, "K")          -- 剑尖
  put(px, 8, 1, "K")
  -- 护手
  for x = 5, 10 do put(px, x, 10, "Y") end
  return px
end

---------------------------------------------------------------------------
-- 输出
---------------------------------------------------------------------------
local function to_sprite(px, scale)
  scale = scale or 1
  local spr = Sprite(SZ * scale, SZ * scale)
  local img = spr.cels[1].image
  for y = 0, SZ - 1 do
    for x = 0, SZ - 1 do
      local ch = px[y][x]
      if ch then
        local c = P[ch]
        local col = app.pixelColor.rgba(c[1], c[2], c[3], c[4])
        for dy = 0, scale - 1 do
          for dx = 0, scale - 1 do
            img:putPixel(x * scale + dx, y * scale + dy, col)
          end
        end
      end
    end
  end
  return spr
end

local ICONS = {
  { name = "icon_strike", px = from_ascii(STRIKE) },
  { name = "icon_defend", px = from_ascii(DEFEND) },
  { name = "icon_cleave", px = cleave_icon() },
  { name = "icon_bash",   px = from_ascii(BASH) },
  { name = "icon_iron_wave", px = iron_wave() },
}

for _, it in ipairs(ICONS) do
  local spr = to_sprite(it.px, 1)
  spr:saveAs(OUT .. it.name .. ".png")
  spr:close()
end

-- 预览：五个并排，6 倍，垫中性底色
local GAP = 4
local total = SZ * #ICONS + GAP * (#ICONS - 1)
local spr = Sprite(total * 6, SZ * 6)
local img = spr.cels[1].image
local bg = app.pixelColor.rgba(64, 56, 68, 255)
for y = 0, SZ * 6 - 1 do
  for x = 0, total * 6 - 1 do img:putPixel(x, y, bg) end
end
for i, it in ipairs(ICONS) do
  local offx = (i - 1) * (SZ + GAP)
  for y = 0, SZ - 1 do
    for x = 0, SZ - 1 do
      local ch = it.px[y][x]
      if ch then
        local c = P[ch]
        local col = app.pixelColor.rgba(c[1], c[2], c[3], c[4])
        for dy = 0, 5 do
          for dx = 0, 5 do
            img:putPixel((offx + x) * 6 + dx, y * 6 + dy, col)
          end
        end
      end
    end
  end
end
spr:saveAs(PREV)
spr:close()

print("ICONS_OK count=" .. #ICONS)
