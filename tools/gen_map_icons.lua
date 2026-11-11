-- gen_map_icons.lua
-- Aseprite 批处理：地图 7 种房间的 12x12 图标
-- 用法: aseprite -b --script gen_map_icons.lua

local SZ = 12
local OUT = "D:/deepseek工作区/deck-builder-game/art/map/"
local PREV = "D:/aseprite-build/out/map_icons_preview.png"

local P = {
  ["K"] = { 26, 22, 26, 255 },
  ["W"] = { 245, 248, 255, 255 },
  ["S"] = { 176, 190, 208, 255 },
  ["s"] = { 122, 136, 158, 255 },
  ["d"] = { 74, 86, 106, 255 },
  ["B"] = { 148, 104, 62, 255 },
  ["b"] = { 96, 64, 38, 255 },
  ["Y"] = { 232, 196, 96, 255 },
  ["y"] = { 168, 134, 50, 255 },
  ["R"] = { 200, 62, 62, 255 },
  ["r"] = { 142, 38, 38, 255 },
  ["O"] = { 226, 132, 60, 255 },
  ["o"] = { 168, 84, 34, 255 },
  ["G"] = { 110, 170, 90, 255 },
}

local function grid(w, h)
  local g = {}
  for y = 0, h - 1 do
    g[y] = {}
    for x = 0, w - 1 do g[y][x] = nil end
  end
  return g
end

local function from_ascii(rows)
  local w = #rows[1]
  local g = grid(w, #rows)
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
  return g, w, #rows
end

local function put(g, x, y, c)
  if g[y] and g[y][x] ~= nil or (g[y] and x >= 0 and x < #g[y]) then
    if y >= 0 and y < #g and x >= 0 and x < #g[y] then g[y][x] = c end
  end
end

local function triangle(g, x1, y1, x2, y2, x3, y3, c)
  -- 全部图标都是 SZ×SZ，直接用它，别用 #g / #g[1]：
  -- 空网格里全是 nil，长度运算符会返回 0，循环体一次都不跑。
  local w, h = SZ, SZ
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local function edge(ax, ay, bx, by)
        return (bx - ax) * (y - ay) - (by - ay) * (x - ax)
      end
      local p1 = edge(x1, y1, x2, y2)
      local p2 = edge(x2, y2, x3, y3)
      local p3 = edge(x3, y3, x1, y1)
      local has_neg = (p1 < 0) or (p2 < 0) or (p3 < 0)
      local has_pos = (p1 > 0) or (p2 > 0) or (p3 > 0)
      if not (has_neg and has_pos) then g[y][x] = c end
    end
  end
end

local ALL = {}
local function emit(name, rows)
  local g, w, h = from_ascii(rows)
  ALL[#ALL + 1] = { name = name, g = g, w = w, h = h }
end
local function emitg(name, g, w, h)
  -- 注意：不能用 #g[1] 推宽度。程序化网格里大量 nil，
  -- Lua 的长度运算符遇到第一个 nil 就停，会返回 0。
  ALL[#ALL + 1] = { name = name, g = g, w = w or SZ, h = h or SZ }
end

---------------------------------------------------------------------------
-- 战斗：剑（和卡牌/意图的剑保持同一套语义）
---------------------------------------------------------------------------
emit("room_battle", {
  ".....KK.....",
  "....KWWK....",
  "....KWSK....",
  "....KWSK....",
  "....KWSK....",
  "..KKKKKKKK..",
  "..KYYYYYYK..",
  "....KBBK....",
  "....KBBK....",
  "....KYYK....",
  ".....KK.....",
  "............",
})

---------------------------------------------------------------------------
-- 精英：骷髅（比普通战斗更凶）
---------------------------------------------------------------------------
emit("room_elite", {
  "............",
  "...KKKKKK...",
  "..KWWWWWWK..",
  "..KWWWWWWK..",
  "..KWKKWWKK..",
  "..KWKKWWKK..",
  "..KWWWWWWK..",
  "..KWKWWKWK..",
  "...KWWWWK...",
  "....KKKK....",
  "............",
  "............",
})

---------------------------------------------------------------------------
-- 事件：问号
---------------------------------------------------------------------------
emit("room_event", {
  "............",
  "....KKKK....",
  "...KYYYYK...",
  "..KYYKKYYK..",
  "..KYK..KYK..",
  "......KYYK..",
  ".....KYYK...",
  ".....KYK....",
  "............",
  ".....KYK....",
  ".....KKK....",
  "............",
})

---------------------------------------------------------------------------
-- 宝箱
---------------------------------------------------------------------------
emit("room_treasure", {
  "............",
  "............",
  "...KKKKKK...",
  "..KBBBBBBK..",
  "..KBbBBbBK..",
  "..KKKKKKKK..",
  "..KBBBBBBK..",
  "..KBKYYKBK..",
  "..KBKYYKBK..",
  "..KBBBBBBK..",
  "..KKKKKKKK..",
  "............",
})

---------------------------------------------------------------------------
-- 商店：金币（圆盘 + 内圈 + 高光）
---------------------------------------------------------------------------
local function coin()
  local w, h = SZ, SZ
  local g = grid(w, h)
  local cx, cy, r = 5.5, 5.5, 4.6
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      local d = math.sqrt((x - cx) ^ 2 + (y - cy) ^ 2)
      if d <= r then
        -- 只留 1px 暗金边，内部整片亮金：原来多套了一圈，看着像齿轮
        if d > r - 1.0 then g[y][x] = "y" else g[y][x] = "Y" end
      end
    end
  end
  put(g, 3, 3, "W"); put(g, 4, 3, "W"); put(g, 3, 4, "W")
  -- 中央菱形
  g[5][6] = "Y"; g[6][5] = "Y"; g[6][6] = "y"; g[6][7] = "Y"; g[7][6] = "Y"
  emitg("room_shop", g)
end
coin()

---------------------------------------------------------------------------
-- 营地：火焰（外红、中橙、芯金）
---------------------------------------------------------------------------
local function flame()
  local w, h = SZ, SZ
  local g = grid(w, h)
  triangle(g, 3, 10, 6, 2, 8, 10, "r")   -- 外层（右倾一点，火苗不是对称的）
  triangle(g, 4, 10, 6, 4, 8, 10, "O")
  triangle(g, 5, 10, 6, 6, 7, 10, "Y")
  triangle(g, 5, 10, 6, 8, 7, 10, "W")
  emitg("room_campfire", g)
end
flame()

---------------------------------------------------------------------------
-- Boss：王冠（底座 + 三个尖 + 宝石）
---------------------------------------------------------------------------
local function crown()
  local w, h = SZ, SZ
  local g = grid(w, h)
  -- 底座
  for y = 7, 8 do
    for x = 2, 10 do g[y][x] = "Y" end
  end
  for x = 2, 10 do g[9][x] = "y" end
  -- 三个尖
  triangle(g, 2, 7, 3, 3, 4, 7, "Y")
  triangle(g, 5, 7, 6, 2, 7, 7, "Y")
  triangle(g, 8, 7, 9, 3, 10, 7, "Y")
  -- 尖顶宝石
  g[3][3] = "R"; g[2][6] = "R"; g[8][6] = "R"
  -- 描边：空白且 4 邻域有实心处补 K
  local add = {}
  for y = 0, h - 1 do
    for x = 0, w - 1 do
      if g[y][x] == nil then
        for _, o in ipairs({ { -1, 0 }, { 1, 0 }, { 0, -1 }, { 0, 1 } }) do
          local nx, ny = x + o[1], y + o[2]
          if nx >= 0 and ny >= 0 and nx < w and ny < h and g[ny][nx] then
            add[#add + 1] = { x, y }
            break
          end
        end
      end
    end
  end
  for _, p in ipairs(add) do g[p[2]][p[1]] = "K" end
  emitg("room_boss", g)
end
crown()

---------------------------------------------------------------------------
-- 输出 + 预览
---------------------------------------------------------------------------
local function save(g, w, h, name)
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

for _, it in ipairs(ALL) do save(it.g, it.w, it.h, it.name) end

-- 预览：7 个一排，8 倍
local S = 8
local gap = 6
local total = #ALL * SZ + gap * (#ALL - 1)
local spr = Sprite(total * S, SZ * S)
local img = spr.cels[1].image
local bg = app.pixelColor.rgba(58, 50, 60, 255)
for y = 0, SZ * S - 1 do
  for x = 0, total * S - 1 do img:putPixel(x, y, bg) end
end
for i, it in ipairs(ALL) do
  local ox = (i - 1) * (SZ + gap)
  for y = 0, it.h - 1 do
    for x = 0, it.w - 1 do
      local ch = it.g[y][x]
      if ch then
        local c = P[ch]
        local col = app.pixelColor.rgba(c[1], c[2], c[3], c[4])
        for dy = 0, S - 1 do
          for dx = 0, S - 1 do
            img:putPixel((ox + x) * S + dx, y * S + dy, col)
          end
        end
      end
    end
  end
end
spr:saveAs(PREV)
spr:close()

print("MAP_ICONS_OK count=" .. #ALL)
