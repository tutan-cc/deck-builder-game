-- gen_backdrops.lua
-- 从 art/background.png 派生两份场景背景：
--   bg_campfire.png  夜战废墟 + 暖色火光 + 火坑
--   bg_event.png     冷调阴影 + 更重的暗角
-- 思路：不重画，只在原图上做调色和加道具，这样能保住 Kenney 原图的细节密度。

local SRC = "D:/deepseek工作区/deck-builder-game/art/background.png"
local OUT = "D:/deepseek工作区/deck-builder-game/art/backgrounds/"
local W, H = 256, 144

local function clamp255(v)
  if v < 0 then return 0 end
  if v > 255 then return 255 end
  return math.floor(v + 0.5)
end

local function load_src()
  local spr = app.open(SRC)
  return spr, spr.cels[1].image
end

-- 整体调色：按通道乘系数，再按纵坐标压暗（越靠上越暗，像夜色）
local function grade(img, mr, mg, mb, top_darken, vignette)
  for y = 0, H - 1 do
    for x = 0, W - 1 do
      local v = img:getPixel(x, y)
      local r = app.pixelColor.rgbaR(v)
      local g = app.pixelColor.rgbaG(v)
      local b = app.pixelColor.rgbaB(v)
      local a = app.pixelColor.rgbaA(v)
      r = r * mr
      g = g * mg
      b = b * mb
      -- 顶部压暗
      local t = 1.0 - (y / H) * 0.0
      if top_darken > 0 then
        local k = 1.0 - top_darken * (1.0 - y / H)
        r = r * k; g = g * k; b = b * k
      end
      -- 暗角
      if vignette > 0 then
        local dx = (x - W * 0.5) / (W * 0.5)
        local dy = (y - H * 0.5) / (H * 0.5)
        local d = math.sqrt(dx * dx + dy * dy) / 1.414
        local k = 1.0 - vignette * d * d
        r = r * k; g = g * k; b = b * k
      end
      img:putPixel(x, y, app.pixelColor.rgba(clamp255(r), clamp255(g), clamp255(b), a))
    end
  end
end

-- 火坑：一圈石头 + 中间焦黑
local function fire_pit(img, cx, cy)
  local function px(x, y, r, g, b)
    if x < 0 or y < 0 or x >= W or y >= H then return end
    img:putPixel(x, y, app.pixelColor.rgba(clamp255(r), clamp255(g), clamp255(b), 255))
  end
  -- 焦黑坑底（横向椭圆）
  for y = cy - 6, cy + 7 do
    for x = cx - 15, cx + 15 do
      local d = math.sqrt((x - cx) ^ 2 / (15 * 15) + (y - cy) ^ 2 / (6 * 6))
      if d <= 1.0 then
        local k = 0.18 + 0.5 * d
        px(x, y, 26 * k + 30, 22 * k + 24, 20 * k + 20)
      end
    end
  end
  -- 炭火余烬
  for i = -4, 4 do
    local y = cy + math.floor(math.sin(i * 1.7) * 1.5)
    px(cx + i, y, 150 + (i % 3) * 18, 60 + (i % 2) * 20, 20)
  end
  -- 石圈：沿椭圆排 8 块石头，每块 3x3，顶面提亮
  local n = 8
  for i = 0, n - 1 do
    local ang = math.pi * (0.1 + 0.8 * (i / (n - 1)))
    local sx = math.floor(cx + math.cos(ang) * 14.0)
    local sy = math.floor(cy + math.sin(ang) * 5.2)
    for dy = -1, 1 do
      for dx = -1, 1 do
        px(sx + dx, sy + dy, 92 + (dx + 1) * 6, 88 + (dx + 1) * 6, 84 + (dx + 1) * 6)
      end
    end
    -- 石头受光面
    px(sx, sy - 2, 138, 133, 126)
    px(sx + 1, sy - 2, 120, 115, 108)
  end
end

-- 暖光：火坑上方的橙色光晕（用加法近似）
local function fire_glow(img, cx, cy)
  for y = cy - 60, cy + 20 do
    for x = cx - 70, cx + 70 do
      if x < 0 or y < 0 or x >= W or y >= H then
        -- skip
      else
        local d = math.sqrt((x - cx) ^ 2 + ((y - cy) * 1.35) ^ 2)
        if d < 70 then
          local v = img:getPixel(x, y)
          local r = app.pixelColor.rgbaR(v)
          local g = app.pixelColor.rgbaG(v)
          local b = app.pixelColor.rgbaB(v)
          local a = app.pixelColor.rgbaA(v)
          local k = (1.0 - d / 70) ^ 2 * 0.55
          r = r + 120 * k
          g = g + 62 * k
          b = b + 18 * k
          img:putPixel(x, y, app.pixelColor.rgba(clamp255(r), clamp255(g), clamp255(b), a))
        end
      end
    end
  end
end

---------------------------------------------------------------------------
-- 营地
---------------------------------------------------------------------------
do
  local spr, img = load_src()
  grade(img, 1.02, 0.84, 0.66, 0.72, 0.42)   -- 暖、顶暗
  fire_pit(img, 128, 62)
  fire_glow(img, 128, 46)
  spr:saveAs(OUT .. "bg_campfire.png")
  spr:close()
end

---------------------------------------------------------------------------
-- 事件 / 商店 / 宝箱（共用一间"冷调密室"）
---------------------------------------------------------------------------
do
  local spr, img = load_src()
  grade(img, 0.52, 0.60, 0.82, 0.45, 0.70)  -- 冷、暗角重
  spr:saveAs(OUT .. "bg_event.png")
  spr:close()
end

print("BACKDROPS_OK 2")
