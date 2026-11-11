-- gen_actors.lua
-- Aseprite 批处理：为玩家/敌人生成 16x16 逐帧动画条（4 帧 = 64x16）
-- 用法: aseprite -b --script gen_actors.lua

local SZ = 16
local FRAMES = 4
local OUT = "D:/deepseek工作区/deck-builder-game/art/actors/"
local PREV = "D:/aseprite-build/out/actors_preview.png"

---------------------------------------------------------------------------
-- 调色板
---------------------------------------------------------------------------
local P = {
  ["K"] = { 26, 22, 26, 255 },     -- 描边
  ["W"] = { 240, 244, 250, 255 },
  ["S"] = { 176, 190, 208, 255 },  -- 钢 亮
  ["s"] = { 122, 136, 158, 255 },  -- 钢 中
  ["d"] = { 74, 86, 106, 255 },    -- 钢 暗
  ["B"] = { 132, 90, 56, 255 },    -- 木/皮
  ["b"] = { 88, 58, 38, 255 },
  ["Y"] = { 232, 196, 96, 255 },   -- 金
  ["R"] = { 198, 74, 74, 255 },    -- 红
  ["r"] = { 140, 48, 48, 255 },
  ["G"] = { 110, 170, 90, 255 },   -- 绿
  ["g"] = { 68, 118, 58, 255 },
  ["P"] = { 150, 110, 200, 255 },  -- 紫
  ["p"] = { 98, 66, 146, 255 },
  ["O"] = { 222, 120, 60, 255 },   -- 橙
  ["o"] = { 160, 80, 36, 255 },
  ["F"] = { 233, 190, 150, 255 },  -- 肤色
  ["E"] = { 250, 250, 250, 255 },  -- 眼白
}

---------------------------------------------------------------------------
-- 基础网格
---------------------------------------------------------------------------
local function newpx()
  local t = {}
  for y = 0, SZ - 1 do
    t[y] = {}
    for x = 0, SZ - 1 do t[y][x] = nil end
  end
  return t
end

local function copy_px(src)
  local t = newpx()
  for y = 0, SZ - 1 do
    for x = 0, SZ - 1 do t[y][x] = src[y][x] end
  end
  return t
end

local function put(px, x, y, c)
  if x >= 0 and y >= 0 and x < SZ and y < SZ then px[y][x] = c end
end

local function from_ascii(rows)
  local px = newpx()
  assert(#rows == SZ, "需要 " .. SZ .. " 行，实际 " .. #rows)
  for y, row in ipairs(rows) do
    assert(#row == SZ, "第 " .. y .. " 行长度 " .. #row .. "，应为 " .. SZ)
    for x = 1, SZ do
      local ch = row:sub(x, x)
      if ch ~= "." then
        assert(P[ch], "未知颜色: " .. ch)
        px[y - 1][x - 1] = ch
      end
    end
  end
  return px
end

-- 整体竖直位移（做呼吸/起伏）
local function shift(px, dy)
  local t = newpx()
  for y = 0, SZ - 1 do
    local sy = y - dy
    if sy >= 0 and sy < SZ then
      for x = 0, SZ - 1 do t[y][x] = px[sy][x] end
    end
  end
  return t
end

-- 实心椭圆（不描边）
local function ellipse(px, cx, cy, rx, ry, c)
  for y = 0, SZ - 1 do
    for x = 0, SZ - 1 do
      local dx = (x - cx) / rx
      local dy = (y - cy) / ry
      if dx * dx + dy * dy <= 1.0 then put(px, x, y, c) end
    end
  end
end

-- 实心三角形（扫描线）
local function triangle(px, x1, y1, x2, y2, x3, y3, c)
  local minx = math.max(0, math.floor(math.min(x1, x2, x3)))
  local maxx = math.min(SZ - 1, math.ceil(math.max(x1, x2, x3)))
  local miny = math.max(0, math.floor(math.min(y1, y2, y3)))
  local maxy = math.min(SZ - 1, math.ceil(math.max(y1, y2, y3)))
  local function edge(ax, ay, bx, by, qx, qy)
    return (bx - ax) * (qy - ay) - (by - ay) * (qx - ax)
  end
  for y = miny, maxy do
    for x = minx, maxx do
      local p1 = edge(x1, y1, x2, y2, x, y)
      local p2 = edge(x2, y2, x3, y3, x, y)
      local p3 = edge(x3, y3, x1, y1, x, y)
      local neg = (p1 < 0) or (p2 < 0) or (p3 < 0)
      local pos = (p1 > 0) or (p2 > 0) or (p3 > 0)
      if not (neg and pos) then put(px, x, y, c) end
    end
  end
end

-- 自动描边：给空白像素、且 4 邻域有实心的地方补 K
-- 比手画描边可靠，形状改了描边会跟着变
local function add_outline(px, only_if_missing)
  local add = {}
  for y = 0, SZ - 1 do
    for x = 0, SZ - 1 do
      if px[y][x] == nil then
        local n = { { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }
        for i = 1, 4 do
          local nx, ny = x + n[i][1], y + n[i][2]
          if nx >= 0 and ny >= 0 and nx < SZ and ny < SZ and px[ny][nx] then
            add[#add + 1] = { x, y }
            break
          end
        end
      end
    end
  end
  for _, p in ipairs(add) do px[p[2]][p[1]] = "K" end
end

---------------------------------------------------------------------------
-- 1. 战士（玩家）：骑士
---------------------------------------------------------------------------
local WARRIOR = {
  "................",
  "......KKKK......",
  ".....KSSSSK.....",
  ".....KSddSK.....",
  ".....KSSSSK.....",
  "......KKKK......",
  "....KKSSSSKK....",
  "...KSSKRRKSSK...",
  "...KSSKRRKSSK...",
  "...KSSKRRKSSK...",
  "....KKSSSSKK....",
  ".....KSSSSK.....",
  ".....KSKKSK.....",
  ".....KSKKSK.....",
  "....KKKKKKKK....",
  "................",
}

---------------------------------------------------------------------------
-- 2. 猎手（玩家备选）：兜帽弓箭手
---------------------------------------------------------------------------
local HUNTER = {
  "................",
  ".....KKKKKK.....",
  "....KGGGGGGK....",
  "...KGGGGGGGGK...",
  "...KGKFFFFKGK...",
  "...KGKFFFFKGK...",
  "...KggFFFFggK...",
  "....KGGGGGGK....",
  "...KKGGGGGGKK...",
  "..KBBKGGGGKBBK..",
  "..KBBKGGGGKBBK..",
  "...KKGGGGGGKK...",
  "....KBBBBBBK....",
  "....KBKKKKBK....",
  "...KKK....KKK...",
  "................",
}

---------------------------------------------------------------------------
-- 3. 蝙蝠：身体固定，翅膀靠三角形生成（上→中→下→中）
---------------------------------------------------------------------------
local function bat_frame(tip_y, dy)
  local px = newpx()
  -- 翅膀（先画，身体会盖住根部）
  triangle(px, 5, 7, 0, tip_y, 5, 10, "P")
  triangle(px, 10, 7, 15, tip_y, 10, 10, "P")
  -- 身体
  ellipse(px, 7.5, 8.5, 2.4, 3.2, "p")
  ellipse(px, 7.5, 8.0, 2.0, 2.6, "P")
  -- 耳朵
  put(px, 6, 4, "P"); put(px, 9, 4, "P")
  put(px, 6, 3, "p"); put(px, 9, 3, "p")
  -- 眼睛
  put(px, 6, 7, "R"); put(px, 9, 7, "R")
  put(px, 7, 7, "R"); put(px, 8, 7, "R")
  -- 脚
  put(px, 7, 11, "p"); put(px, 8, 11, "p")
  add_outline(px)
  -- dy：整体上下位移，用来做俯冲/蓄力
  if dy and dy ~= 0 then px = shift(px, dy) end
  return px
end

---------------------------------------------------------------------------
-- 4. 螃蟹：身体固定，钳子开合 + 轻微起伏
---------------------------------------------------------------------------
local function crab_frame(claw_dx, bob)
  local px = newpx()
  -- 身体
  ellipse(px, 7.5, 9.0 + bob, 4.6, 3.0, "o")
  ellipse(px, 7.5, 8.6 + bob, 4.0, 2.4, "O")
  -- 眼睛（两根立起来的眼柄）
  put(px, 6, 5 + bob, "o"); put(px, 6, 6 + bob, "o")
  put(px, 9, 5 + bob, "o"); put(px, 9, 6 + bob, "o")
  put(px, 6, 4 + bob, "E"); put(px, 9, 4 + bob, "E")
  put(px, 6, 3 + bob, "K"); put(px, 9, 3 + bob, "K")
  -- 钳子（左右各一，cx 随开合移动）
  ellipse(px, 2.0 - claw_dx, 8.0 + bob, 1.9, 1.9, "o")
  ellipse(px, 2.0 - claw_dx, 7.6 + bob, 1.3, 1.3, "O")
  ellipse(px, 13.0 + claw_dx, 8.0 + bob, 1.9, 1.9, "o")
  ellipse(px, 13.0 + claw_dx, 7.6 + bob, 1.3, 1.3, "O")
  -- 钳口（缺一块，暗示张开）
  put(px, math.floor(2.0 - claw_dx), 8 + bob, "K")
  put(px, math.floor(13.0 + claw_dx), 8 + bob, "K")
  -- 腿
  for i = 0, 1 do
    put(px, 4 + i, 12 + bob, "o"); put(px, 11 - i, 12 + bob, "o")
  end
  add_outline(px)
  return px
end

---------------------------------------------------------------------------
-- 组装动画条（4 帧横排）
---------------------------------------------------------------------------
local function sheet(frames, name)
  local spr = Sprite(SZ * #frames, SZ)
  local img = spr.cels[1].image
  for i, px in ipairs(frames) do
    local ox = (i - 1) * SZ
    for y = 0, SZ - 1 do
      for x = 0, SZ - 1 do
        local ch = px[y][x]
        if ch then
          local c = P[ch]
          img:putPixel(ox + x, y, app.pixelColor.rgba(c[1], c[2], c[3], c[4]))
        end
      end
    end
  end
  spr:saveAs(OUT .. name .. ".png")
  spr:close()
end

-- 战士 / 猎手：4 帧呼吸（0, -1, 0, +1）
local w_base = from_ascii(WARRIOR)
sheet({ shift(w_base, 0), shift(w_base, -1), shift(w_base, 0), shift(w_base, 1) }, "actor_warrior")

local h_base = from_ascii(HUNTER)
sheet({ shift(h_base, 0), shift(h_base, -1), shift(h_base, 0), shift(h_base, 1) }, "actor_hunter")

-- 蝙蝠：翅尖 3 → 6 → 10 → 6
sheet({ bat_frame(3), bat_frame(6), bat_frame(10), bat_frame(6) }, "actor_bat")

-- 螃蟹：钳子张开程度 + 起伏
sheet({ crab_frame(0.0, 0), crab_frame(1.2, -1), crab_frame(0.0, 0), crab_frame(0.4, 1) }, "actor_crab")

-- 攻击帧（3 帧，不循环）：扑击时播一次，播完回待机
-- 螃蟹：蓄力下蹲 → 钳子全开并上扑 → 收势
sheet({ crab_frame(0.0, 2), crab_frame(2.6, -1), crab_frame(0.6, 0) }, "actor_crab_att")
-- 蝙蝠：收翅后仰 → 俯冲前扑 → 回位
sheet({ bat_frame(2, -1), bat_frame(9, 1), bat_frame(4, 0) }, "actor_bat_att")

-- 玩家攻击（3 帧）：举剑 → 挥出 → 收势
-- 剑平时不出现，只在攻击帧画出来（1px 白刃 + 深色描边）
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

local function warrior_attack_frame(tip_x, tip_y)
  local px = shift(w_base, 0)
  for _, o in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
    line(px, 12 + o[1], 10 + o[2], tip_x + o[1], tip_y + o[2], "K")
  end
  line(px, 12, 10, tip_x, tip_y, "W")
  put(px, tip_x, tip_y, "W")
  return px
end

sheet({
  warrior_attack_frame(14, 3),
  warrior_attack_frame(15, 8),
  warrior_attack_frame(13, 13),
}, "actor_warrior_att")

-- 猎手攻击：举弓 → 拉满 → 放
local function hunter_attack_frame(tip_x, tip_y)
  local px = shift(h_base, 0)
  for _, o in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
    line(px, 12 + o[1], 9 + o[2], tip_x + o[1], tip_y + o[2], "K")
  end
  line(px, 12, 9, tip_x, tip_y, "B")
  put(px, tip_x, tip_y, "W")
  return px
end

sheet({
  hunter_attack_frame(14, 4),
  hunter_attack_frame(15, 9),
  hunter_attack_frame(13, 12),
}, "actor_hunter_att")

---------------------------------------------------------------------------
-- 预览：4 个角色 × 4 帧，5 倍
---------------------------------------------------------------------------
local names = { "actor_warrior", "actor_hunter", "actor_bat", "actor_crab", "actor_bat_att", "actor_crab_att" }
local pw = (SZ * FRAMES) * 5
local ph = SZ * 5
local gap = 8
local spr = Sprite(pw, (ph + gap) * #names - gap)
local img = spr.cels[1].image
local bg = app.pixelColor.rgba(70, 58, 66, 255)
for y = 0, ph * #names + gap * (#names - 1) - 1 do
  for x = 0, pw - 1 do img:putPixel(x, y, bg) end
end

local framesets = {
  { shift(w_base, 0), shift(w_base, -1), shift(w_base, 0), shift(w_base, 1) },
  { shift(h_base, 0), shift(h_base, -1), shift(h_base, 0), shift(h_base, 1) },
  { bat_frame(3), bat_frame(6), bat_frame(10), bat_frame(6) },
  { crab_frame(0.0, 0), crab_frame(1.2, -1), crab_frame(0.0, 0), crab_frame(0.4, 1) },
  { bat_frame(2, -1), bat_frame(9, 1), bat_frame(4, 0) },
  { crab_frame(0.0, 2), crab_frame(2.6, -1), crab_frame(0.6, 0) },
}
for r, frames in ipairs(framesets) do
  local oy = (r - 1) * (ph + gap)
  for i, px in ipairs(frames) do
    local ox = (i - 1) * SZ * 5
    for y = 0, SZ - 1 do
      for x = 0, SZ - 1 do
        local ch = px[y][x]
        if ch then
          local c = P[ch]
          local col = app.pixelColor.rgba(c[1], c[2], c[3], c[4])
          for dy = 0, 4 do
            for dx = 0, 4 do
              img:putPixel(ox + x * 5 + dx, oy + y * 5 + dy, col)
            end
          end
        end
      end
    end
  end
end
spr:saveAs(PREV)
spr:close()

print("ACTORS_OK 4 sheets x " .. FRAMES .. " frames")
