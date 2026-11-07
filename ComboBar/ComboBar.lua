-- Dalorrian's Combo Bar: your combo points as clean gold squares just under your character.
-- Rogues always, druids in cat form. Shift-drag to move. /combo for options.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local FULL = { 1, 0.42, 0.1 }        -- every point lit: the squares turn ember orange
local SIZE, GAP = 18, 4
local DEFAULTS = { scale = 1, vertical = false, fade = true, energy = true }   -- (1.3.0) DB.show: "always" or "combat"
local _, CLASS = UnitClass("player")
local CP = (Enum and Enum.PowerType and Enum.PowerType.ComboPoints) or 4

local P = ns.print or print   -- (1.1.0) Lang.lua: chat text in the player's language
local Tip = ns.Tip or GameTooltip
local function Say(msg) P("|cffffd100Combo Bar:|r " .. msg) end

local bar = CreateFrame("Frame", "ComboBarFrame", UIParent)
bar:SetMovable(true)
bar:SetClampedToScreen(true)
bar:EnableMouse(false)   -- it sits in the middle of the screen: it only catches the mouse while you hold Shift
bar:RegisterForDrag("LeftButton")
local dragging = false   -- (1.4.1) while stuck to your character, a drag nudges it instead
bar:SetScript("OnDragStart", function(self)
  if DB.stick == "target" then return end   -- (1.5.0) riding the target's nameplate
  if IsShiftKeyDown() or DB.unlocked then dragging = true; self:StartMoving() end
end)
bar:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  dragging = false
  if ns.Nudged and ns.Nudged() then return end
  local p, _, rp, x, y = self:GetPoint(1)
  DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
end)
bar:Hide()
bar.pips = {}

-- (1.4.0) the points can be squares, circles, diamonds, triangles or hexagons, in a color you pick.
-- Each point is three layers of the same shape: a black edge, a dark inside, and the colored fill.
local TEX = "Interface\\AddOns\\ComboBar\\Textures\\"
local SHAPES = { square = W, circle = TEX .. "circle", diamond = TEX .. "diamond", triangle = TEX .. "triangle", hexagon = TEX .. "hexagon" }
local COLORS = { gold = GOLD, orange = { 1, 0.55, 0.1 }, red = { 0.95, 0.2, 0.2 }, pink = { 1, 0.4, 0.75 },
  purple = { 0.7, 0.4, 1 }, blue = { 0.3, 0.55, 1 }, cyan = { 0.3, 0.9, 1 }, green = { 0.35, 0.95, 0.35 }, white = { 1, 1, 1 } }
local function Color()
  if DB.color == "class" then
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[CLASS]
    if c then return { c.r, c.g, c.b } end
  end
  return COLORS[DB.color or "gold"] or GOLD
end
local function Shape(p)
  local tex = SHAPES[DB.shape or "square"] or W
  local square = tex == W
  for _, t in ipairs({ p.edge, p.bg, p.fill }) do t:SetTexture(tex) end
  p.edge:SetVertexColor(0, 0, 0, 1)
  p.bg:SetVertexColor(0.04, 0.04, 0.05, 0.85)
  local inset = square and 3 or 4
  p.bg:ClearAllPoints(); p.bg:SetPoint("TOPLEFT", 2, -2); p.bg:SetPoint("BOTTOMRIGHT", -2, 2)
  p.fill:ClearAllPoints(); p.fill:SetPoint("TOPLEFT", inset, -inset); p.fill:SetPoint("BOTTOMRIGHT", -inset, inset)
  p.square = square
end
local function Pip(i)
  local p = bar.pips[i]
  if p then return p end
  p = CreateFrame("Frame", nil, bar)
  p:SetSize(SIZE, SIZE)
  p:EnableMouse(false)
  p.edge = p:CreateTexture(nil, "BACKGROUND"); p.edge:SetAllPoints()
  p.bg = p:CreateTexture(nil, "BORDER")
  p.fill = p:CreateTexture(nil, "ARTWORK")
  p.shine = p:CreateTexture(nil, "OVERLAY")      -- a thin highlight on top so it doesn't read flat (squares only)
  p.shine:SetPoint("TOPLEFT", p.fill, "TOPLEFT"); p.shine:SetPoint("TOPRIGHT", p.fill, "TOPRIGHT")
  p.shine:SetHeight(3)
  p.shine:SetColorTexture(1, 1, 1, 0.25)
  Shape(p)
  bar.pips[i] = p
  return p
end

---------------------------------------------------------------------------
-- (1.2.0) a thin energy bar under the squares, with a spark that sweeps across every 2 seconds:
-- energy comes in ticks of 20 every 2 seconds, and the spark shows when the next one lands
---------------------------------------------------------------------------
local ENERGY = (Enum and Enum.PowerType and Enum.PowerType.Energy) or 3
local EH, TICK = 7, 2.0   -- (1.3.0) a little thicker so it's easy to see
local en = CreateFrame("Frame", nil, bar, "BackdropTemplate")
en:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
en:SetBackdropColor(0.04, 0.04, 0.05, 0.8)
en:SetBackdropBorderColor(0, 0, 0, 1)
en:EnableMouse(false)
-- (1.3.0) a real status bar does the filling: WoW: Forever can hand addons "secret" power numbers that
-- can't be measured, but a status bar can still show them, so the fill always follows your energy
en.sb = CreateFrame("StatusBar", nil, en)
en.sb:SetPoint("TOPLEFT", 1, -1); en.sb:SetPoint("BOTTOMRIGHT", -1, 1)
en.sb:SetStatusBarTexture(W)
en.sb:SetStatusBarColor(1, 0.96, 0.41, 0.9)   -- energy yellow, a shade off the gold squares
en.sb:SetMinMaxValues(0, 100); en.sb:SetValue(0)
en.spark = en.sb:CreateTexture(nil, "OVERLAY")
en.spark:SetColorTexture(1, 1, 1, 0.95)
en.spark:Hide()
en:Hide()
local function Plain(v) return type(v) == "number" and not (issecretvalue and issecretvalue(v)) end
local lastEnergy, lastTick
local function Energy()
  local cur, max = UnitPower("player"), UnitPowerMax("player")   -- your current power: energy while this bar shows
  if max == nil or (Plain(max) and max <= 0) then max = 100 end
  pcall(en.sb.SetMinMaxValues, en.sb, 0, max)
  pcall(en.sb.SetValue, en.sb, cur or 0)
  return cur
end
en:SetScript("OnUpdate", function(self)
  local cur = Energy()
  local now = GetTime()
  -- a natural tick: 20 energy (40 under Adrenaline Rush) arriving on its own, not a potion mid-tick
  if Plain(cur) then
    if lastEnergy and cur > lastEnergy then
      local gain = cur - lastEnergy
      if gain >= 18 and gain <= 45 and (not lastTick or now - lastTick > 1.6) then lastTick = now end
    end
    lastEnergy = cur
  end
  if lastTick and now - lastTick > 6 then lastTick = nil end   -- no ticks lately (full, or smooth regen): no spark
  local p = lastTick and (((now - lastTick) % TICK) / TICK) or nil
  local sb = self.sb
  self.spark:SetShown(p ~= nil)
  if p then
    self.spark:ClearAllPoints()
    if DB.vertical then
      self.spark:SetSize(sb:GetWidth(), 2); self.spark:SetPoint("BOTTOM", 0, sb:GetHeight() * p - 1)
    else
      self.spark:SetSize(2, sb:GetHeight()); self.spark:SetPoint("LEFT", sb:GetWidth() * p - 1, 0)
    end
  end
end)

local testing   -- /combo test: a fake count so you can see it without a target

local function Max()
  local m = UnitPowerMax and UnitPowerMax("player", CP)
  if not m or m <= 0 then m = MAX_COMBO_POINTS or 5 end
  return m
end

local function Points()
  if testing then return testing end
  local n
  if UnitPower then n = UnitPower("player", CP) end
  if (not n or n == 0) and GetComboPoints then n = GetComboPoints("player", "target") end   -- older clients keep points on the target
  return n or 0
end

local function Wanted()
  if testing then return true end
  if DB.off then return false end
  if CLASS == "ROGUE" then return true end
  if CLASS == "DRUID" then return UnitPowerType("player") == 3 end   -- energy means cat form
  return false
end

local function Layout()
  local m = Max()
  for _, p in ipairs(bar.pips) do p:Hide() end
  for i = 1, m do
    local p = Pip(i)
    p:ClearAllPoints()
    if DB.vertical then p:SetPoint("BOTTOM", bar, "BOTTOM", 0, (i - 1) * (SIZE + GAP))
    else p:SetPoint("LEFT", bar, "LEFT", (i - 1) * (SIZE + GAP), 0) end
    p:Show()
  end
  local long = m * SIZE + (m - 1) * GAP
  if DB.vertical then bar:SetSize(SIZE, long) else bar:SetSize(long, SIZE) end
  -- (1.2.0) the energy bar: under the squares, or beside them when they stand up
  en:ClearAllPoints()
  if DB.vertical then
    en:SetPoint("BOTTOMLEFT", bar, "BOTTOMRIGHT", 3, 0); en:SetSize(EH, long)
  else
    en:SetPoint("TOPLEFT", bar, "BOTTOMLEFT", 0, -3); en:SetSize(long, EH)
  end
  en.sb:SetOrientation(DB.vertical and "VERTICAL" or "HORIZONTAL")
  bar.max = m
end

---------------------------------------------------------------------------
-- (1.4.1) Stick To Character: the camera always looks at your character, so the bar sits a set
-- distance under (or over) the middle of the screen, and that distance and the bar's size follow
-- the camera zoom. Shift-drag (or Move It) nudges it, and the nudge is kept.
-- (1.4.0 rode on the game's Personal Resource Display, but on Forever that sits in a fixed spot,
-- with its own health, energy and combo points, so it's no longer used and gets switched back off.)
---------------------------------------------------------------------------
local follow = CreateFrame("Frame")
local function Sticking() return DB and (DB.stick == "below" or DB.stick == "above" or DB.stick == "left" or DB.stick == "right") end
local function Riding() return Sticking() or (DB and DB.stick == "target") end
local function Zoom()
  local ok, z = pcall(GetCameraZoom)
  if ok and type(z) == "number" and z > 0 then return z end
  return 15
end
local lastZ, spotY, spotS, spotX
-- (1.4.2) how tall each race stands, in yards: the camera looks at the top of your head,
-- so Over sits just above the middle of the screen and Under sits a body height below it
local TALL = { Human = 1.9, Dwarf = 1.5, NightElf = 2.3, Gnome = 1.0, Draenei = 2.3, Worgen = 2.2,
  Orc = 1.9, Scourge = 1.8, Tauren = 2.5, Troll = 2.2, BloodElf = 1.9, Goblin = 1.1, Pandaren = 2.0 }
local function Tall()
  local ok, _, race = pcall(UnitRace, "player")
  return (ok and race and TALL[race]) or 1.9
end
local function Spot()
  local d = math.max(1.5, Zoom())
  local H = UIParent:GetHeight() or 768
  local yard = (H / 2) / (d * 0.57)                        -- how tall a yard looks at your character
  local s = (DB.scale or 1) * math.max(0.6, math.min(1.5, 18 / (d + 3)))   -- normal size at the usual zoom
  local half = ((bar:GetHeight() or 30) * s) / 2           -- keep the whole bar clear of you
  local halfW = ((bar:GetWidth() or 30) * s) / 2
  local h = Tall()
  local x, y = 0, 0
  if DB.stick == "above" then y = 0.18 * h * yard + 8 + half   -- (1.4.3) a little more room over the head
  elseif DB.stick == "left" or DB.stick == "right" then        -- (1.4.4) beside you, level with your middle
    x = 0.3 * h * yard + 10 + halfW
    if DB.stick == "left" then x = -x end
    y = -0.5 * h * yard
  else y = -(1.02 * h * yard + 6 + half) end                    -- (1.4.3) all the way under the feet
  return y, s, x
end
local function Follow(force)
  if dragging then return end
  local z = Zoom()
  if not force and lastZ and math.abs(z - lastZ) < 0.01 then return end
  lastZ = z
  spotY, spotS, spotX = Spot()
  bar:SetScale(spotS)
  bar:ClearAllPoints()
  bar:SetPoint("CENTER", UIParent, "CENTER", ((spotX or 0) + (DB.stickX or 0)) / spotS, (spotY + (DB.stickY or 0)) / spotS)
end
function ns.Nudged()
  if not Sticking() or not spotS then return false end
  local cx, cy = bar:GetCenter()
  if cx then
    DB.stickX = cx * spotS - (UIParent:GetWidth() or 0) / 2 - (spotX or 0)
    DB.stickY = cy * spotS - (UIParent:GetHeight() or 0) / 2 - spotY
  end
  Follow(true)
  return true
end
local function UndoPlate()   -- (1.4.1) turn off what 1.4.0 switched on, once
  if DB.plateUndone then return end
  DB.plateUndone = true
  if DB.stick == nil then return end   -- never touched Stick To: 1.4.0 changed nothing for you
  local set = (C_CVar and C_CVar.SetCVar) or SetCVar
  if set then pcall(set, "nameplateShowSelf", "0"); pcall(set, "NameplatePersonalShowAlways", "0") end
end
-- (1.5.0) Over Target: the bar rides on your target's nameplate, the way NugComboBar can.
-- No nameplate showing (nameplates off, target out of sight, or a friendly plate the game locks): it sits in its usual spot.
local function TargetPlate()
  if not (C_NamePlate and C_NamePlate.GetNamePlateForUnit) then return nil end
  local ok, p = pcall(C_NamePlate.GetNamePlateForUnit, "target")
  if not ok or not p or (p.IsForbidden and p:IsForbidden()) then return nil end
  local uf = p.UnitFrame
  if uf and not (uf.IsForbidden and uf:IsForbidden()) then
    -- (1.5.1) right on top of the health bar (some nameplate looks put the name under the bar)
    local hb = uf.healthBar or uf.HealthBar or (uf.HealthBarsContainer and uf.HealthBarsContainer.healthBar)
    if type(hb) == "table" and hb.IsShown and hb:IsShown() then return hb end
    if type(uf.name) == "table" and uf.name.IsShown and uf.name:IsShown() then return uf.name end
    return uf
  end
  return p
end
local onPlate
local function Place()
  bar:ClearAllPoints()
  onPlate = nil
  if DB.stick == "target" then
    follow:SetScript("OnUpdate", nil)
    local plate = TargetPlate()
    if plate then
      onPlate = plate
      bar:SetScale((DB.scale or 1) * 0.8)
      bar:SetPoint("BOTTOM", plate, "TOP", 0, (DB.plateGap or 2) / ((DB.scale or 1) * 0.8))   -- (1.6.0) Target Height
      return
    end
  end
  if Sticking() then
    follow:SetScript("OnUpdate", function() Follow() end)
    Follow(true)
    return
  end
  follow:SetScript("OnUpdate", nil)
  if DB.point then bar:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
  else bar:SetPoint("CENTER", UIParent, "CENTER", 0, -110) end   -- just under your character
  bar:SetScale(DB.scale or 1)
end

local function Update()
  if not DB then return end
  if not Wanted() then bar:Hide() return end
  local m, n = Max(), Points()
  if bar.max ~= m then Layout() end
  local base = Color()
  local c = (n >= m) and (base == COLORS.orange and GOLD or FULL) or base   -- every point lit: ember orange
  for i = 1, m do
    local p = bar.pips[i]
    if i <= n then
      p.fill:SetVertexColor(c[1], c[2], c[3], 1); p.fill:Show(); p.shine:SetShown(p.square)
    else
      p.fill:Hide(); p.shine:Hide()
    end
  end
  -- (1.3.0) Show: Always, or only In Combat (moving it or a preview always shows it)
  local away = DB.show == "combat" and not UnitAffectingCombat("player") and not DB.unlocked and not testing
  if away then bar:Hide() else bar:Show() end
  en:SetShown(DB.energy and (UnitPowerType("player") == ENERGY or testing) and true or false)
  if en:IsShown() then Energy() end
  bar:SetAlpha(((n == 0 and not DB.unlocked) and 0.5 or 1) * (DB.alpha or 100) / 100)   -- (1.4.2) Opacity slider
end

local MinimapButton   -- (1.1.0) further down
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "UNIT_POWER_FREQUENT", "UNIT_POWER_UPDATE", "UNIT_MAXPOWER", "UNIT_DISPLAYPOWER", "PLAYER_TARGET_CHANGED",
  "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_SHAPESHIFT_FORM", "UNIT_COMBO_POINTS", "PLAYER_ENTERING_WORLD",
  "MODIFIER_STATE_CHANGED", "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= "ComboBar" then return end
    -- (1.6.1) new players start with red circles over their target, shown in combat;
    -- anyone who already had Combo Bar keeps the look they had (gold squares in their usual spot)
    local fresh = ComboBarDB == nil
    ComboBarDB = ComboBarDB or {}
    DB = ComboBarDB
    if fresh then
      DB.stick, DB.shape, DB.color, DB.show = "target", "circle", "red", "combat"
    else
      if DB.shape == nil then DB.shape = "square" end
      if DB.color == nil then DB.color = "gold" end
    end
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    if DB.show == nil then DB.show = (DB.fade == false) and "always" or "combat" end   -- (1.3.0) from the old When Empty
    return
  end
  if not DB then return end
  if e == "MODIFIER_STATE_CHANGED" then bar:EnableMouse((DB.stick ~= "target" and (IsShiftKeyDown() or DB.unlocked)) and true or false) return end
  -- (1.5.0) Over Target: move with the target and its nameplate coming and going
  if e == "NAME_PLATE_UNIT_ADDED" or e == "NAME_PLATE_UNIT_REMOVED" then
    if DB.stick == "target" then
      local mine = false
      pcall(function() mine = UnitIsUnit(a1, "target") end)
      if mine or e == "NAME_PLATE_UNIT_REMOVED" then Place() end
    end
    return
  end
  if e == "PLAYER_TARGET_CHANGED" and DB.stick == "target" then Place() end
  if e == "PLAYER_LOGIN" then pcall(UndoPlate); Layout(); Place(); pcall(MinimapButton) end
  if (e == "UNIT_POWER_FREQUENT" or e == "UNIT_POWER_UPDATE" or e == "UNIT_MAXPOWER" or e == "UNIT_DISPLAYPOWER") and a1 ~= "player" then return end
  Update()
end)

-- /combo test: walks the points up to full and back down, so you can see it without a target
local function Test()
  if testing then return end
  local step, up = 0, true
  testing = 0
  Update()
  C_Timer.NewTicker(0.45, function(self)
    step = up and step + 1 or step - 1
    if step >= Max() then up = false end
    testing = math.max(0, step)
    Update()
    if step <= 0 and not up then testing = nil; self:Cancel(); Update() end
  end)
end

---------------------------------------------------------------------------
-- (1.1.0) Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Combo Bar",
  tag = "Combo Bar",
  settings = {
    -- (1.6.0) grouped: what it looks like, where it sits, when it shows
    { header = "Look" },
    { label = "Combo Bar", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil; Update() end },
    { label = "Shape", cycle = true, choices = { { "Squares", "square" }, { "Circles", "circle" }, { "Diamonds", "diamond" }, { "Triangles", "triangle" }, { "Hexagons", "hexagon" } },
      get = function() return DB.shape or "square" end,
      set = function(v) DB.shape = v; for _, p in ipairs(bar.pips) do Shape(p) end; Update() end },
    { label = "Color", cycle = true, choices = { { "Gold", "gold" }, { "Orange", "orange" }, { "Red", "red" }, { "Pink", "pink" },
        { "Purple", "purple" }, { "Blue", "blue" }, { "Cyan", "cyan" }, { "Green", "green" }, { "White", "white" }, { "Class Color", "class" } },
      get = function() return DB.color or "gold" end, set = function(v) DB.color = v; Update() end },
    { label = "Direction", choices = { { "Horizontal", false }, { "Vertical", true } },
      get = function() return DB.vertical and true or false end,
      set = function(v) DB.vertical = v; Layout(); Place(); Update() end },
    { label = "Energy Bar", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.energy and true or false end, set = function(v) DB.energy = v; Update() end },
    { label = "Size", choices = { { "Small", 0.8 }, { "Normal", 1 }, { "Big", 1.3 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Place() end },
    { label = "Opacity", slider = { 10, 100, 5 }, format = function(v) return v .. "%" end,
      get = function() return DB.alpha or 100 end, set = function(v) DB.alpha = v; Update() end },
    { header = "Position" },
    { label = "Stick To", cycle = true, choices = { { "Screen", "screen" }, { "Under Character", "below" }, { "Over Character", "above" },
        { "Left of Character", "left" }, { "Right of Character", "right" }, { "Over Target", "target" } },
      get = function() return Riding() and DB.stick or "screen" end,
      set = function(v) DB.stick = v; Place(); Update() end },
    { label = "Target Height", slider = { 0, 60, 2 }, format = function(v) return "+" .. v end,
      get = function() return DB.plateGap or 2 end, set = function(v) DB.plateGap = v; Place() end },
    { label = "Move It", choices = { { "Locked", "lock" }, { "Move It", "move" }, { "Reset", "reset" } },
      get = function() return DB.unlocked and "move" or "lock" end,
      set = function(v) SlashCmdList.COMBOBAR(v == "move" and "unlock" or v) end },
    { header = "Showing" },
    { label = "Show", choices = { { "Always", "always" }, { "In Combat", "combat" } },
      get = function() return DB.show or "combat" end, set = function(v) DB.show = v; Update() end },
    { label = "Preview", choices = { { "Show Me", "test" } },
      get = function() return nil end, set = function() SlashCmdList.COMBOBAR("test") end },
  },
  notes = {
    { v = "1.6.1", "New players start with red circles over their target, shown in combat. If you already use Combo Bar, nothing changes" },
    { v = "1.6.0", "Settings are grouped now: Look, Position and Showing",
      "New Target Height slider: how far over your target's health bar the points sit with Over Target, so you can leave room for its buffs and debuffs" },
    { v = "1.5.1", "Over Target sits right on top of the target's health bar now, not up in the air" },
    { v = "1.5.0", "New Stick To choice: Over Target puts your points on your target's nameplate, like NugComboBar. Needs enemy nameplates on (V key). With no nameplate showing it sits in its usual spot" },
    { v = "1.4.4", "Stick To has Left of Character and Right of Character now, made for the Vertical bar. Stick To is one button that cycles, so it fits" },
    { v = "1.4.3", "Over Character sits a bit higher over your head, and Under Character sits fully under your feet" },
    { v = "1.4.2", "Over Character and Under Character sit right on your character now: just over your head, or just under your feet",
      "New Opacity slider to make the bar see-through" },
    { v = "1.4.1", "Stick To Character now follows your character and sizes with the camera zoom. Shift-drag nudges it into place. It no longer turns on the game's Personal Resource Display (the extra health, energy and combo points), and switches it back off",
      "Shape is one button now, like Color, so the settings fit" },
    { v = "1.4.0", "Pick the shape of your points (squares, circles, diamonds, triangles or hexagons) and their color, class color included",
      "New Stick To setting: Under Character or Over Character keeps the bar on your character, moving and sizing with it as the camera zooms. It rides on the game's Personal Resource Display, which it switches on for you" },
    { v = "1.3.0", "Direction now reads Horizontal or Vertical",
      "New Show setting: Always, or only In Combat",
      "The energy bar fills and drains with your energy, and it's a little thicker so it's easier to see" },
    { v = "1.2.0", "A thin energy bar under the squares, with a spark that sweeps across every 2 seconds to show when your next energy tick lands" },
    { v = "1.1.0", "A Settings & Help window, a minimap button and 10 languages" },
    { v = "1.0.0", "First release: your combo points as clean gold squares just under your character" },
  },
  report = function()
    return { "Class " .. tostring(CLASS) .. ", max " .. tostring(Max()) .. ", vertical " .. tostring(DB.vertical) ..
      ", show " .. tostring(DB.show) .. ", stick " .. tostring(DB.stick) .. " (zoom " .. string.format("%.1f", Zoom()) .. "), power " .. tostring(UnitPowerType("player")) .. (DB.off and ", turned off" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.ComboBarMinimapButton then return end
  local b = CreateFrame("Button", "ComboBarMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\Ability_Rogue_SliceDice")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 105)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.COMBOBAR("off")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Combo Bar")
    Tip:AddLine("Left-click: Settings & Help", 1, 1, 1)
    Tip:AddLine(DB.off and "Right-click: turn it on" or "Right-click: turn it off", 1, 1, 1)
    Tip:AddLine("Drag to move", 0.6, 0.6, 0.6)
    Tip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local sc = Minimap:GetEffectiveScale()
      DB.minimapAngle = math.deg((math.atan2 or math.atan)(cy / sc - my, cx / sc - mx))
      Spot()
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  Spot()
end
function ComboBar_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_COMBOBAR1 = "/combo"
SLASH_COMBOBAR2 = "/combobar"
SlashCmdList.COMBOBAR = function(msg)
  local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(%S*)")
  if cmd == "test" then
    if not Wanted() then Say("your class doesn't use combo points, but here's how it looks.") end
    Test()
  elseif cmd == "vertical" then
    DB.vertical = not DB.vertical; Layout(); Place(); Update(); Say(DB.vertical and "Vertical" or "Horizontal")
  elseif cmd == "unlock" or cmd == "move" then
    DB.unlocked = true; bar:EnableMouse(true); bar:Show(); Update()
    Say("drag it where you want it, then /combo lock. Shift-drag works any time.")
  elseif cmd == "lock" then
    DB.unlocked = nil; bar:EnableMouse(false); Update(); Say("locked.")
  elseif cmd == "scale" and tonumber(arg) then
    DB.scale = math.max(0.5, math.min(3, tonumber(arg))); Place(); Say("size " .. DB.scale .. ".")
  elseif cmd == "fade" or cmd == "show" then
    DB.show = (DB.show == "combat") and "always" or "combat"; Update(); Say(DB.show == "combat" and "In Combat" or "Always")
  elseif cmd == "debug" then
    local cur, max = UnitPower("player"), UnitPowerMax("player")
    local function S(v) return (issecretvalue and issecretvalue(v)) and "secret" or tostring(v) end
    local a, b = en.sb:GetMinMaxValues()
    Say("power type " .. tostring(UnitPowerType("player")) .. ", energy " .. S(cur) .. " / " .. S(max) ..
      ", bar shown " .. tostring(en:IsShown()) .. ", bar size " .. math.floor(en:GetWidth()) .. "x" .. math.floor(en:GetHeight()) ..
      ", bar value " .. S(en.sb:GetValue()) .. " of " .. S(b) .. ", tick " .. tostring(lastTick ~= nil))
  elseif cmd == "off" then
    DB.off = not DB.off or nil; Update(); Say(DB.off and "turned off" or "turned on")
  elseif cmd == "reset" then
    DB.point, DB.rel, DB.x, DB.y, DB.scale, DB.stickX, DB.stickY = nil, nil, nil, nil, 1, nil, nil; Place(); Say("back under your character.")
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("your combo points, just under your character. Shift-drag to move.")
    P("  /combo help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /combo test   (" .. "see it fill up, no target needed" .. ")")
  end
end
