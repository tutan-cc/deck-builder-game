-- gen_fx.lua
-- Aseprite 批处理：战斗特效帧条
--   slash_*  斩击弧（24x24, 3 帧）
--   hit_*    打击星芒（16x16, 3 帧）
--   puff_*   死亡烟雾（16x16, 4 帧）
-- 特效要压在背景上，所以必须带 alpha —— 调色板条目直接写四通道。

local OUT = "D:/deepseek工作区/deck-builder-game/art/fx/"
local PREV = "D:/aseprite-build/out/fx_preview.png"

local P = {
  ["K"] = { 26, 22, 26, 255 },
  ["W"] = { 255, 255, 255, 255 },
  ["w"] = { 255, 255, 255, 150 },
  ["v"] = { 255, 255, 255, 70 },
  ["Y"] = { 255, 226, 140, 255 },
  ["y"] = { 255, 226, 140, 120 },
  ["R"] = { 255, 170, 120, 255 },
  ["r"] = { 255, 170, 120, 90 },
  ["G"] = { 190, 196, 210, 255 },
  ["g"] = { 190, 196, 210, 140 },
  ["h"] = { 190, 196, 210, 60 },
}

local function grid(w, h)
  local g = {}
  for yy = 0, h - 1 do
    g[yy] = {}
    for xx = 0, w - 1 do g[yy][xx] = nil end
  end
  return g
end

local function save(g, w, h, name)
  local spr = Sprite(w, h)
  local img = spr.cels[1].image
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      local ch = g[yy][xx]
      if ch then
        local c = P[ch]
        img:putPixel(xx, yy, app.pixelColor.rgba(c[1], c[2], c[3], c[4]))
      end
    end
  end
  spr:saveAs(OUT .. name .. ".png")
  spr:close()
end

local ALL = {}

local function sheet(frames, w, h, name)
  local spr = Sprite(w * #frames, h)
  local img = spr.cels[1].image
  for i, g in ipairs(frames) do
    local ox = (i - 1) * w
    for yy = 0, h - 1 do
      for xx = 0, w - 1 do
        local ch = g[yy][xx]
        if ch then
          local c = P[ch]
          img:putPixel(ox + xx, yy, app.pixelColor.rgba(c[1], c[2], c[3], c[4]))
        end
      end
    end
  end
  spr:saveAs(OUT .. name .. ".png")
  spr:close()
  ALL[#ALL + 1] = { name = name, frames = frames, w = w, h = h }
end

---------------------------------------------------------------------------
-- 1. 斩击弧：以圆心画圆弧带，三帧分别"起势 / 全开 / 消散"
--    角度用弧度，0 = 正右，逆时针为正。
---------------------------------------------------------------------------
local function slash_frame(a0, a1, color, thick, alpha_char)
  local w, h = 24, 24
  local g = grid(w, h)
  local cx, cy, r = 11.5, 11.5, 9.0
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      local dx, dy = xx - cx, yy - cy
      local dist = math.sqrt(dx * dx + dy * dy)
      if math.abs(dist - r) <= thick then
        local ang = math.atan(dy, dx)
        -- 归一到 [0, 2π)
        if ang < 0 then ang = ang + math.pi * 2 end
        if ang >= a0 and ang <= a1 then
          -- 靠近弧中间更亮，两端渐隐
          local t = (ang - a0) / math.max(0.0001, (a1 - a0))
          local mid = 1.0 - math.abs(t - 0.5) * 2.0
          if mid > 0.55 then
            g[yy][xx] = color
          elseif mid > 0.2 then
            g[yy][xx] = alpha_char
          end
        end
      end
    end
  end
  return g
end

local D = math.pi / 180.0
sheet({
  slash_frame(250 * D, 295 * D, "W", 1.2, "w"),
  slash_frame(200 * D, 340 * D, "W", 1.6, "Y"),
  slash_frame(190 * D, 350 * D, "w", 2.2, "v"),
}, 24, 24, "slash")

---------------------------------------------------------------------------
-- 2. 打击星芒：四条对角尖刺，三帧"小 → 大 → 散"
---------------------------------------------------------------------------
local function star_frame(len, core, tip)
  local w, h = 16, 16
  local g = grid(w, h)
  local cx, cy = 7.5, 7.5
  local dirs = { { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 } }
  for _, d in ipairs(dirs) do
    for step = 0, len do
      local t = step / len
      local xx = math.floor(cx + d[1] * t * len + 0.5)
      local yy = math.floor(cy + d[2] * t * len + 0.5)
      if xx >= 0 and yy >= 0 and xx < w and yy < h then
        g[yy][xx] = (t < 0.55) and core or tip
      end
    end
  end
  -- 十字细刺
  for i = 1, math.floor(len * 0.6) do
    if cx + i < w then g[math.floor(cy)][math.floor(cx + i)] = tip end
    if cx - i >= 0 then g[math.floor(cy)][math.floor(cx - i)] = tip end
    if cy + i < h then g[math.floor(cy + i)][math.floor(cx)] = tip end
    if cy - i >= 0 then g[math.floor(cy - i)][math.floor(cx)] = tip end
  end
  g[7][7] = "W"
  return g
end

sheet({
  star_frame(2, "W", "Y"),
  star_frame(6, "W", "Y"),
  star_frame(4, "Y", "y"),
}, 16, 16, "hit")

---------------------------------------------------------------------------
-- 3. 死亡烟雾：圆斑扩张 + 逐帧变淡
---------------------------------------------------------------------------
local function puff_frame(r, color, ring)
  local w, h = 16, 16
  local g = grid(w, h)
  local cx, cy = 7.5, 7.5
  for yy = 0, h - 1 do
    for xx = 0, w - 1 do
      local d = math.sqrt((xx - cx) ^ 2 + (yy - cy) ^ 2)
      if d <= r then
        -- 圆边做抖动：完美圆看起来像泡泡，破一点才像烟
        local edge = d > r - 1.4
        local keep = ((xx * 7 + yy * 13) % 5) < 3
        if edge and not keep then
          -- 挖掉一部分边缘像素
        elseif edge then
          g[yy][xx] = ring
        else
          g[yy][xx] = color
        end
      end
    end
  end
  return g
end

sheet({
  puff_frame(2.5, "G", "K"),
  puff_frame(4.5, "G", "g"),
  puff_frame(6.0, "g", "h"),
  puff_frame(7.0, "h", "h"),
}, 16, 16, "puff")

---------------------------------------------------------------------------
-- 4. 护盾破碎：先是盾面出现裂纹，然后碎块四散飞开
---------------------------------------------------------------------------
local function block_break_frame(radius, blob, color, draw_shield)
  local w, h = 16, 16
  local g = grid(w, h)
  local cx, cy = 7.5, 7.5

  if draw_shield then
    -- 中心还完整的一块小盾
    local rows = {
      "..KKKK..",
      "..KGGK..",
      "..KGGK..",
      "..KGgK..",
      "...KGK..",
      "....K...",
    }
    for yy, row in ipairs(rows) do
      for xx = 1, #row do
        local ch = row:sub(xx, xx)
        if ch ~= "." then
          local px_ = math.floor(cx - 4 + (xx - 1))
          local py_ = math.floor(cy - 3 + (yy - 1))
          if px_ >= 0 and py_ >= 0 and px_ < w and py_ < h then
            g[py_][px_] = ch
          end
        end
      end
    end
  end

  -- 六片碎块沿圆周飞散
  local n = 6
  for i = 0, n - 1 do
    local ang = (i / n) * math.pi * 2 + 0.35
    local bx = cx + math.cos(ang) * radius
    local by = cy + math.sin(ang) * radius
    for dy = 0, blob - 1 do
      for dx = 0, blob - 1 do
        local x = math.floor(bx + dx - 0.5)
        local y = math.floor(by + dy - 0.5)
        if x >= 0 and y >= 0 and x < w and y < h then
          g[y][x] = color
        end
      end
    end
  end
  return g
end

sheet({
  block_break_frame(2.5, 2, "G", true),
  block_break_frame(5.0, 2, "g", false),
  block_break_frame(7.0, 1, "h", false),
}, 16, 16, "block_break")

---------------------------------------------------------------------------
-- 预览：三套横排，6 倍
---------------------------------------------------------------------------
local S = 6
local gap = 10
local rowW = 0
for _, it in ipairs(ALL) do
  local rw = it.w * #it.frames * S
  if rw > rowW then rowW = rw end
end
local totalH = 0
for _, it in ipairs(ALL) do totalH = totalH + it.h * S + gap end
local spr = Sprite(rowW + 12, totalH + 6)
local img = spr.cels[1].image
local bg1 = app.pixelColor.rgba(52, 44, 54, 255)
local bg2 = app.pixelColor.rgba(96, 70, 52, 255)  -- 模拟沙地底色，看 alpha 效果
for yy = 0, totalH + 5 do
  for xx = 0, rowW + 11 do
    img:putPixel(xx, yy, ((xx + yy) % 16 < 8) and bg1 or bg2)
  end
end
local oy = 3
for _, it in ipairs(ALL) do
  for i, g in ipairs(it.frames) do
    local ox = 3 + (i - 1) * it.w * S
    for yy = 0, it.h - 1 do
      for xx = 0, it.w - 1 do
        local ch = g[yy][xx]
        if ch then
          local c = P[ch]
          local col = app.pixelColor.rgba(c[1], c[2], c[3], c[4])
          for dy = 0, S - 1 do
            for dx = 0, S - 1 do
              img:putPixel(ox + xx * S + dx, oy + yy * S + dy, col)
            end
          end
        end
      end
    end
  end
  oy = oy + it.h * S + gap
end
spr:saveAs(PREV)
spr:close()

print("FX_OK " .. #ALL .. " sheets")
