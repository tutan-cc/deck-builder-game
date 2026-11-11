-- gen_card_frames.lua
-- Aseprite 批处理：为 256x144 像素卡牌游戏生成 44x54 卡面边框
-- 用法: aseprite -b --script gen_card_frames2.lua

local W, H = 44, 54
local OUT = "D:/deepseek工作区/deck-builder-game/art/cards/"

---------------------------------------------------------------------------
-- 像素缓冲（自己做 alpha 合成）
---------------------------------------------------------------------------
local function newpx()
  local t = {}
  for y = 0, H - 1 do
    t[y] = {}
    for x = 0, W - 1 do t[y][x] = { 0, 0, 0, 0 } end
  end
  return t
end

local function blend(px, x, y, r, g, b, a)
  if x < 0 or y < 0 or x >= W or y >= H then return end
  a = a / 255
  if a <= 0 then return end
  local d = px[y][x]
  local da = d[4]
  local oa = a + da * (1 - a)
  if oa <= 0 then return end
  d[1] = (r * a + d[1] * da * (1 - a)) / oa
  d[2] = (g * a + d[2] * da * (1 - a)) / oa
  d[3] = (b * a + d[3] * da * (1 - a)) / oa
  d[4] = oa
end

---------------------------------------------------------------------------
-- 形状：2px 斜切角。必须做上下界检查 —— 否则 is_inside(-1,y) 会返回 true，
-- 左右描边被误判成"内部"而整条消失。
---------------------------------------------------------------------------
local function is_inside(x, y)
  if x < 0 or y < 0 or x >= W or y >= H then return false end
  local c = 2
  if x + y < c then return false end
  if (W - 1 - x) + y < c then return false end
  if x + (H - 1 - y) < c then return false end
  if (W - 1 - x) + (H - 1 - y) < c then return false end
  return true
end

local function is_body(x, y)
  return y >= 2 and is_inside(x, y)
end

local function is_outer(x, y)
  if not is_body(x, y) then return false end
  if not is_body(x - 1, y) then return true end
  if not is_body(x + 1, y) then return true end
  if not is_body(x, y - 1) then return true end
  if not is_body(x, y + 1) then return true end
  return false
end

local function is_ring2(x, y)
  if not is_body(x, y) or is_outer(x, y) then return false end
  if is_outer(x - 1, y) then return true end
  if is_outer(x + 1, y) then return true end
  if is_outer(x, y - 1) then return true end
  if is_outer(x, y + 1) then return true end
  return false
end

---------------------------------------------------------------------------
-- 一张卡面
---------------------------------------------------------------------------
local OUTLINE = { 14, 11, 13 }

local function draw_card(accent)
  local px = newpx()

  -- 1) 外描边（1px，全周）
  for y = 2, H - 1 do
    for x = 0, W - 1 do
      if is_outer(x, y) then
        blend(px, x, y, OUTLINE[1], OUTLINE[2], OUTLINE[3], 255)
      end
    end
  end

  -- 2) 第二圈：上/左受光（accent 着色），下/右落影
  for y = 2, H - 1 do
    for x = 0, W - 1 do
      if is_ring2(x, y) then
        local lit = is_outer(x, y - 1) or is_outer(x - 1, y)
        if lit then
          blend(px, x, y, accent[1], accent[2], accent[3], 60)
          blend(px, x, y, 255, 255, 255, 120)
        else
          blend(px, x, y, 0, 0, 0, 130)
        end
      end
    end
  end

  -- 3) 描述区压暗
  for y = 20, 33 do
    for x = 1, W - 2 do
      if is_body(x, y) and not is_outer(x, y) then
        blend(px, x, y, 0, 0, 0, 12)
      end
    end
  end

  -- 4) 标题铭牌 y35-51 + 顶部亮线
  for y = 35, 51 do
    for x = 1, W - 2 do
      if is_body(x, y) and not is_outer(x, y) then
        blend(px, x, y, 20, 16, 20, 165)
      end
    end
  end
  for x = 2, W - 3 do
    if is_body(x, 35) then blend(px, x, 35, 255, 255, 255, 70) end
  end

  -- 5) 图标凹槽 x12-32 / y2-19（只做上/左内阴影，不挖黑洞）
  local wx0, wy0, wx1, wy1 = 12, 2, 32, 19
  for y = wy0, wy1 do
    for x = wx0, wx1 do
      blend(px, x, y, 0, 0, 0, 20)
    end
  end
  for x = wx0, wx1 do
    blend(px, x, wy0, 0, 0, 0, 110)
    blend(px, x, wy1, 255, 255, 255, 35)
  end
  for y = wy0, wy1 do
    blend(px, wx0, y, 0, 0, 0, 110)
    blend(px, wx1, y, 255, 255, 255, 35)
  end

  -- 6) 费用宝石槽（圆心 7,6.5 半径 3.6）
  local cx, cy, rad = 7.0, 6.5, 3.6
  for y = 2, 11 do
    for x = 2, 12 do
      local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
      if d <= rad then
        if d > rad - 1.0 then
          blend(px, x, y, 140, 180, 225, 230)
        else
          blend(px, x, y, 28, 42, 70, 255)
        end
      end
    end
  end
  blend(px, 5, 5, 255, 255, 255, 160)

  return px
end

---------------------------------------------------------------------------
-- 输出
---------------------------------------------------------------------------
local function to_sprite(px, scale)
  scale = scale or 1
  local spr = Sprite(W * scale, H * scale)
  local img = spr.cels[1].image
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local p = px[y][x]
      if p[4] > 0 then
        local col = app.pixelColor.rgba(
          math.floor(p[1] + 0.5), math.floor(p[2] + 0.5),
          math.floor(p[3] + 0.5), math.floor(p[4] * 255 + 0.5))
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

local ACCENTS = {
  attack = { 255, 96, 96 },
  skill  = { 96, 176, 255 },
  power  = { 186, 120, 255 },
}
local BASE_COLORS = {
  attack = { 107, 66, 66 },
  skill  = { 66, 82, 107 },
  power  = { 77, 66, 107 },
}

for name, accent in pairs(ACCENTS) do
  local spr = to_sprite(draw_card(accent), 1)
  spr:saveAs(OUT .. "card_frame_" .. name .. ".png")
  spr:close()
end

-- 预览：三种底色并排，8 倍
local GAP = 6
local total_w = W * 3 + GAP * 2
local prev = {}
for y = 0, H - 1 do
  prev[y] = {}
  for x = 0, total_w - 1 do prev[y][x] = { 0, 0, 0, 0 } end
end
local order = { "attack", "skill", "power" }
for i, name in ipairs(order) do
  local offx = (i - 1) * (W + GAP)
  local base = BASE_COLORS[name]
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      prev[y][offx + x] = { base[1] / 255, base[2] / 255, base[3] / 255, 1 }
    end
  end
  local card = draw_card(ACCENTS[name])
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local p = card[y][x]
      if p[4] > 0 then
        local d = prev[y][offx + x]
        local a = p[4]
        local oa = a + d[4] * (1 - a)
        d[1] = (p[1] / 255 * a + d[1] * d[4] * (1 - a)) / oa
        d[2] = (p[2] / 255 * a + d[2] * d[4] * (1 - a)) / oa
        d[3] = (p[3] / 255 * a + d[3] * d[4] * (1 - a)) / oa
        d[4] = oa
      end
    end
  end
end

local S = 8
local spr = Sprite(total_w * S, H * S)
local img = spr.cels[1].image
for y = 0, H - 1 do
  for x = 0, total_w - 1 do
    local p = prev[y][x]
    local col = app.pixelColor.rgba(
      math.floor(p[1] * 255 + 0.5), math.floor(p[2] * 255 + 0.5),
      math.floor(p[3] * 255 + 0.5), math.floor(p[4] * 255 + 0.5))
    for dy = 0, S - 1 do
      for dx = 0, S - 1 do
        img:putPixel(x * S + dx, y * S + dy, col)
      end
    end
  end
end
spr:saveAs("D:/aseprite-build/out/preview_cards.png")  -- 预览图放临时目录，不污染 art/cards
spr:close()

print("GEN_OK frames=3 preview=" .. (total_w * S) .. "x" .. (H * S))
