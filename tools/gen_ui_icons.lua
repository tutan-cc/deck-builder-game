-- gen_ui_icons.lua
-- Aseprite 批处理：战斗 UI 图标组 + 卡背
-- 用法: aseprite -b --script gen_ui_icons.lua
--
-- 风格约定（和已有卡面/角色保持一致）：
--   1px 深描边(K) + 2~3 阶明暗 + 左上角高光(W)

local OUT = "D:/deepseek工作区/deck-builder-game/art/ui/"
local PREV = "D:/aseprite-build/out/ui_icons_preview.png"

---------------------------------------------------------------------------
-- 调色板
---------------------------------------------------------------------------
local P = {
  ["K"] = { 26, 22, 26, 255 },
  ["W"] = { 245, 248, 255, 255 },
  ["R"] = { 200, 62, 62, 255 },   -- 血 亮
  ["r"] = { 142, 38, 38, 255 },   -- 血 暗
  ["S"] = { 176, 190, 208, 255 }, -- 钢
  ["s"] = { 122, 136, 158, 255 },
  ["d"] = { 74, 86, 106, 255 },
  ["Y"] = { 232, 196, 96, 255 },  -- 金
  ["y"] = { 168, 134, 50, 255 },
  ["U"] = { 92, 152, 232, 255 },  -- 蓝
  ["u"] = { 46, 88, 158, 255 },
  ["C"] = { 168, 218, 255, 255 }, -- 蓝 高光
  ["P"] = { 150, 110, 200, 255 }, -- 紫
  ["p"] = { 96, 64, 144, 255 },
  ["O"] = { 226, 132, 60, 255 },  -- 橙
  ["G"] = { 110, 170, 90, 255 },
  ["g"] = { 68, 118, 58, 255 },
  ["N"] = { 30, 38, 66, 255 },   -- 卡背 深海军蓝
  ["n"] = { 40, 50, 84, 255 },   -- 卡背 斜纹（只差一阶，避免"浴巾"感）
}

---------------------------------------------------------------------------
-- 基础工具
---------------------------------------------------------------------------
local function grid(w, h)
  local g = {}
  for y = 0, h - 1 do
    g[y] = {}
    for x = 0, w - 1 do g[y][x] = nil end
  end
  return g
end

local function from_ascii(rows)
  local h = #rows
  local w = #rows[1]
  local g = grid(w, h)
  for y, row in ipairs(rows) do
    assert(#row == w, "第 " .. y .. " 行长度 " .. #row .. "，应为 " .. w .. " : " .. row)
    for x = 1, w do
      local ch = row:sub(x, x)
      if ch ~= "." then
        assert(P[ch], "未知颜色: " .. ch)
        g[y - 1][x - 1] = ch
      end
    end
  end
  return g, w, h
end

local function draw(g, w, h, name)
  local spr = Sprite(w, h)
  local img = spr.cels[1].image
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local ch = g[y][x]
      if ch then
        local c = P[ch]
        img:putPixel(x, y, app.pixelColor.rgba(c[1], c[2], c[3], c[4]))
      end
    end
  end
  spr:saveAs(OUT .. name .. ".png")
  spr:close()
end

local ALL = {}  -- 收集用于预览

local function emit(name, rows)
  local g, w, h = from_ascii(rows)
  draw(g, w, h, name)
  ALL[#ALL + 1] = { name = name, g = g, w = w, h = h }
end

---------------------------------------------------------------------------
-- 1/2. 生命：满心 / 空心（9x8）
---------------------------------------------------------------------------
emit("heart_full", {
  "..KK.KK..",
  ".KWRKRRK.",
  "KWRRRRRRK",
  "KRRRRRrRK",
  ".KRRRrrK.",
  "..KRRrK..",
  "...KRK...",
  "....K....",
})

emit("heart_empty", {
  "..KK.KK..",
  ".KdKddK..",
  "KdddddddK",
  "KdddddddK",
  ".KdddddK.",
  "..KddddK.",
  "...KdK...",
  "....K....",
})

---------------------------------------------------------------------------
-- 3. 格挡：盾徽（9x10）
---------------------------------------------------------------------------
emit("block_shield", {
  ".KKKKKKK.",
  "KSsSSSsSK",
  "KSsssssSK",
  "KSsWWssSK",
  "KSsssssSK",
  "KSsssssSK",
  ".KSsssSK.",
  "..KSsSK..",
  "...KSK...",
  "....K....",
})

---------------------------------------------------------------------------
-- 4. 状态：力量（上箭头 金）/ 易伤（裂盾 红）/ 虚弱（下箭头 紫）
---------------------------------------------------------------------------
emit("status_strength", {
  "...KK...",
  "..KYYK..",
  ".KYYYYK.",
  "KYyYYyYK",
  "..KYYK..",
  "..KYYK..",
  "..KyyK..",
  "..KKKK..",
})

-- 易伤 = "受到的伤害增加"。原本画裂心，但跟血量的红心在同一行里撞脸，
-- 改成红色裂盾：语义是"护甲被打碎"，跟格挡的灰盾靠颜色+裂纹区分。
local function vulnerable_icon()
  local g, w, h = from_ascii({
    ".KKKKK.",
    "KRRRRRK",
    "KRRKRRK",
    "KRKRRRK",
    ".KKRRK.",
    "..KRK..",
    "...K...",
  })
  ALL[#ALL + 1] = { name = "status_vulnerable", g = g, w = w, h = h }
  draw(g, w, h, "status_vulnerable")
end

vulnerable_icon()

emit("status_weak", {
  "..KKKK..",
  "..KPPK..",
  "..KPPK..",
  "..KPPK..",
  ".KPpPpK.",
  ".KPPPPK.",
  "..KPPK..",
  "...KK...",
})

---------------------------------------------------------------------------
-- 5~8. 敌人意图：剑 / 盾 / 增益 / 减益（9x9）
---------------------------------------------------------------------------
emit("intent_attack", {
  "....K....",
  "...KWK...",
  "...KWK...",
  "...KWK...",
  "...KWK...",
  ".KKKWKKK.",
  ".KYYYYYK.",
  "...KYK...",
  "...KKK...",
})

emit("intent_defend", {
  "..KKKKK..",
  ".KSsssSK.",
  ".KSsssSK.",
  ".KSsWssK.",
  ".KSsssSK.",
  "..KSssK..",
  "...KSK...",
  "....K....",
  ".........",
})

emit("intent_buff", {
  "....K....",
  "...KYK...",
  "..KYYYK..",
  ".KYYYYYK.",
  "KKKYYYKKK",
  "...KYK...",
  "...KYK...",
  "...KYK...",
  "...KKK...",
})

emit("intent_debuff", {
  "...KKK...",
  "...KPK...",
  "...KPK...",
  "...KPK...",
  "KKKPPKKK.",
  ".KPPPPK..",
  "..KPPPK..",
  "...KPK...",
  "....K....",
})

---------------------------------------------------------------------------
-- 9. 能量球（11x11，程序化：球体 + 顶部高光）
---------------------------------------------------------------------------
local function energy_orb()
  local w, h = 11, 11
  local g = grid(w, h)
  local cx, cy, r = 5.0, 5.0, 5.0
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
      if d <= r then
        if d > r - 1.0 then
          g[y][x] = "K"
        elseif d > r - 2.0 then
          g[y][x] = "U"
        elseif d > r - 3.1 then
          g[y][x] = "u"
        else
          g[y][x] = "U"
        end
      end
    end
  end
  -- 高光：左上两点
  g[2][3] = "C"; g[2][4] = "C"; g[3][3] = "C"
  g[3][4] = "W"
  draw(g, w, h, "energy_orb")
  ALL[#ALL + 1] = { name = "energy_orb", g = g, w = w, h = h }
end
energy_orb()

---------------------------------------------------------------------------
-- 10. 卡背（44x54）：深蓝底 + 金边 + 中央菱形徽记
---------------------------------------------------------------------------
local function card_back()
  local w, h = 44, 54
  local g = grid(w, h)
  local function put(x, y, c)
    if x >= 0 and y >= 0 and x < w and y < h then g[y][x] = c end
  end
  local function inside(x, y)
    if x < 0 or y < 0 or x >= w or y >= h then return false end
    local c = 2
    if x + y < c then return false end
    if (w - 1 - x) + y < c then return false end
    if x + (h - 1 - y) < c then return false end
    if (w - 1 - x) + (h - 1 - y) < c then return false end
    return true
  end
  -- 底：深海军蓝 + 极淡斜纹（只差一阶，避免"浴巾"感）
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if inside(x, y) then
        put(x, y, ((x + y) % 6 < 1) and "n" or "N")
      end
    end
  end
  -- 外描边
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if inside(x, y) then
        if not inside(x - 1, y) or not inside(x + 1, y) or not inside(x, y - 1) or not inside(x, y + 1) then
          put(x, y, "K")
        end
      end
    end
  end
  -- 双线金框：外深内亮，做出浮雕
  local m1, m2 = 3, 4
  for x = m1, w - 1 - m1 do
    put(x, m1, "y"); put(x, h - 1 - m1, "y")
  end
  for y = m1, h - 1 - m1 do
    put(m1, y, "y"); put(w - 1 - m1, y, "y")
  end
  for x = m2, w - 1 - m2 do
    put(x, m2, "Y"); put(x, h - 1 - m2, "Y")
  end
  for y = m2, h - 1 - m2 do
    put(m2, y, "Y"); put(w - 1 - m2, y, "Y")
  end
  -- 四角金饰：小 L 形，撑住画面四角
  local corners = { { 6, 6 }, { 37, 6 }, { 6, 47 }, { 37, 47 } }
  for _, c in ipairs(corners) do
    put(c[1], c[2], "Y")
    put(c[1], c[2] + 1, "Y"); put(c[1], c[2] + 2, "y")
    put(c[1] + 1, c[2], "Y"); put(c[1] + 2, c[2], "y")
  end
  -- 中央菱形徽记
  local cx, cy = 21.5, 27.0
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local t = math.abs(x - cx) / 8.5 + math.abs(y - cy) / 10.5
      if t <= 1.0 then
        if t > 0.86 then put(x, y, "Y") else put(x, y, "n") end
      end
    end
  end
  -- 宝石
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local t = math.abs(x - cx) / 3.2 + math.abs(y - cy) / 4.0
      if t <= 1.0 then
        if t > 0.72 then put(x, y, "r") else put(x, y, "R") end
      end
    end
  end
  put(20, 25, "W")
  draw(g, w, h, "card_back")
  ALL[#ALL + 1] = { name = "card_back", g = g, w = w, h = h }
end
card_back()

---------------------------------------------------------------------------
-- 预览：按格子排布，6 倍
---------------------------------------------------------------------------
local S = 6
local gap = 10
-- 三行：小图标 / 意图 / 卡背
local row1 = { "heart_full", "heart_empty", "block_shield", "energy_orb", "status_strength", "status_vulnerable", "status_weak" }
local row2 = { "intent_attack", "intent_defend", "intent_buff", "intent_debuff" }

local byname = {}
for _, it in ipairs(ALL) do byname[it.name] = it end

local function row_width(names)
  local wsum = 0
  for i, n in ipairs(names) do
    wsum = wsum + byname[n].w * S
    if i < #names then wsum = wsum + gap end
  end
  return wsum
end

local maxw = math.max(row_width(row1), row_width(row2), byname["card_back"].w * S)
local rowH1 = 10 * S
local rowH2 = 9 * S
local rowH3 = byname["card_back"].h * S
local totalH = rowH1 + gap + rowH2 + gap + rowH3
local spr = Sprite(maxw + 20, totalH + 20)
local img = spr.cels[1].image
local bg = app.pixelColor.rgba(58, 50, 60, 255)
for y = 0, totalH + 19 do
  for x = 0, maxw + 19 do img:putPixel(x, y, bg) end
end

local function blit(it, ox, oy)
  for y = 0, it.h - 1 do
    for x = 0, it.w - 1 do
      local ch = it.g[y][x]
      if ch then
        local c = P[ch]
        local col = app.pixelColor.rgba(c[1], c[2], c[3], c[4])
        for dy = 0, S - 1 do
          for dx = 0, S - 1 do
            local px, py = ox + x * S + dx, oy + y * S + dy
            if px >= 0 and py >= 0 and px < maxw + 20 and py < totalH + 20 then
              img:putPixel(px, py, col)
            end
          end
        end
      end
    end
  end
end

local ox = 10
for _, n in ipairs(row1) do
  blit(byname[n], ox, 10)
  ox = ox + byname[n].w * S + gap
end
ox = 10
local y2 = 10 + rowH1 + gap
for _, n in ipairs(row2) do
  blit(byname[n], ox, y2)
  ox = ox + byname[n].w * S + gap
end
blit(byname["card_back"], 10, y2 + rowH2 + gap)

spr:saveAs(PREV)
spr:close()

print("UI_ICONS_OK count=" .. #ALL)
