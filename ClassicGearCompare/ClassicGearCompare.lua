-- Dalorrian's Classic Gear Compare (1.0.0): hover any piece of gear and see what it did in Classic.
-- Unchanged gear shows nothing. Changed gear gets an "In Classic" block: the stats in two clean columns
-- (the ones Forever changed are tinted), and its old Use, Equip and Chance on hit effects when Forever changed those.
-- Gear that didn't exist in Classic says "New in Forever". /gearcompare opens the settings.

local ADDON, ns = ...
local DB
local DEFAULTS = { on = true, newLine = true }
local ICON = "Interface\\Icons\\INV_Helmet_03"
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local Tip = ns.Tip or GameTooltip
local function Say(msg) P("|cffffd100Classic Gear Compare:|r " .. msg) end

local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Safe(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b = pcall(fn, ...)
  if not ok or Secret(a) then return nil end
  return a, b
end

---------------------------------------------------------------------------
-- what an item did in Classic (Data.lua), read once per item
---------------------------------------------------------------------------
-- Classic stat numbers -> the game's own stat keys (their names come from the game, in every language)
local STAT = { [0] = "ITEM_MOD_MANA_SHORT", [1] = "ITEM_MOD_HEALTH_SHORT", [3] = "ITEM_MOD_AGILITY_SHORT",
  [4] = "ITEM_MOD_STRENGTH_SHORT", [5] = "ITEM_MOD_INTELLECT_SHORT", [6] = "ITEM_MOD_SPIRIT_SHORT",
  [7] = "ITEM_MOD_STAMINA_SHORT" }
local DPS, ARMOR = "ITEM_MOD_DAMAGE_PER_SECOND_SHORT", "RESISTANCE0_NAME"
-- the order lines are shown in, like the game's own tooltip
local ORDER = { DPS, ARMOR, "ITEM_MOD_STRENGTH_SHORT", "ITEM_MOD_AGILITY_SHORT", "ITEM_MOD_STAMINA_SHORT",
  "ITEM_MOD_INTELLECT_SHORT", "ITEM_MOD_SPIRIT_SHORT", "ITEM_MOD_HEALTH_SHORT", "ITEM_MOD_MANA_SHORT",
  "RESISTANCE1_NAME", "RESISTANCE2_NAME", "RESISTANCE3_NAME", "RESISTANCE4_NAME", "RESISTANCE5_NAME", "RESISTANCE6_NAME" }
local RANK = {}
for i, k in ipairs(ORDER) do RANK[k] = i end

local cache = {}
local function Classic(id)
  local c = cache[id]
  if c ~= nil then return c or nil end
  local raw = ns.CLASSIC and ns.CLASSIC[id]
  if not raw then cache[id] = false; return nil end
  c = { stats = {} }
  if raw == "X" then c.random = true end
  for part in raw:gmatch("[^;]+") do
    local tag, body = part:sub(1, 1), part:sub(2)
    if tag == "S" then
      for t, a in body:gmatch("(%-?%d+):(%-?%d+)") do
        local key = STAT[tonumber(t)]
        if key then c.stats[key] = (c.stats[key] or 0) + tonumber(a) end
      end
    elseif tag == "A" then c.stats[ARMOR] = tonumber(body)
    elseif tag == "R" then
      for s, a in body:gmatch("(%d+):(%-?%d+)") do c.stats["RESISTANCE" .. s .. "_NAME"] = tonumber(a) end
    elseif tag == "D" then c.stats[DPS] = tonumber(body)
    elseif tag == "E" then c.fx = true
    end
  end
  cache[id] = c
  return c
end

-- Classic effects in the player's language (English when a language has no text for one)
local fxLang, fxEnglish
local function Effects(id)
  local all = ns.CLASSIC_FX
  if not all then return nil end
  if not fxLang then
    local code = (ns.L and ns.L.code) or (GetLocale and GetLocale()) or "enUS"
    if code == "esMX" then code = "esES" end
    local build = all[code] or all.enUS
    fxLang = build and build() or {}
  end
  local fx = fxLang[id]
  if fx then return fx end
  if not fxEnglish then fxEnglish = all.enUS and all.enUS() or {} end
  return fxEnglish[id]
end

-- what the item does now, straight from the game
local function Live(link)
  local get = (C_Item and C_Item.GetItemStats) or GetItemStats
  local t = Safe(get, link)
  return type(t) == "table" and t or nil
end

local function Equippable(link)
  local f = (C_Item and C_Item.IsEquippableItem) or IsEquippableItem
  return Safe(f, link) and true or false
end

---------------------------------------------------------------------------
-- the tooltip lines
---------------------------------------------------------------------------
local GRAY = { 0.62, 0.62, 0.62 }
local NAME = { 0.8, 0.8, 0.8 }
local CHANGED = { 1, 0.62, 0.25 }

local function StatName(key)
  local n = _G[key]
  if type(n) == "string" and n ~= "" then return (n:gsub(":%s*$", "")) end
  return (key:gsub("^ITEM_MOD_", ""):gsub("_SHORT$", ""):gsub("_", " "):lower():gsub("^%l", string.upper))
end

local function Value(key, v)
  if not v or v == 0 then return Tr("none") end
  if key == DPS then return string.format("%.1f", v) end
  if key == ARMOR then return tostring(v) end
  return (v > 0 and "+" or "") .. v
end

local function Differs(key, a, b)
  a, b = a or 0, b or 0
  if key == DPS then return math.abs(a - b) > 0.15 end
  return a ~= b
end

local function AddLines(tt, link)
  if not DB or not DB.on or type(link) ~= "string" then return end
  local id = tonumber(link:match("item:(%d+)"))
  if not id then return end
  local c = Classic(id)
  if not c then
    if DB.newLine and Equippable(link) then
      tt:AddLine(" ")
      tt:AddLine(Tr("New in Forever"), 0.45, 0.8, 1)
      tt:Show()
    end
    return
  end
  if c.random then return end            -- "of the Bear" style gear: its stats were never fixed
  local live = Live(link)
  if not live then return end

  -- every stat either version has, in the game's order
  local keys, seen, changed = {}, {}, false
  local function Want(k)
    if seen[k] or not RANK[k] and not (type(_G[k]) == "string" and k:find("^ITEM_MOD_")) then return end
    seen[k] = true
    keys[#keys + 1] = k
  end
  for k in pairs(c.stats) do Want(k) end
  for k, v in pairs(live) do if type(v) == "number" and v ~= 0 then Want(k) end end
  table.sort(keys, function(a, b)
    local ra, rb = RANK[a] or 99, RANK[b] or 99
    if ra ~= rb then return ra < rb end
    return a < b
  end)
  local rows = {}
  for _, k in ipairs(keys) do
    local was, now = c.stats[k], live[k]
    -- armor and damage per second aren't always reported: unknown counts as unchanged
    local unknown = (k == ARMOR or k == DPS) and now == nil
    local diff = not unknown and Differs(k, was, now)
    if diff then changed = true end
    rows[#rows + 1] = { k = k, was = was, diff = diff }
  end
  local fx = c.fx and Effects(id)
  if not changed and not fx then return end

  tt:AddLine(" ")
  tt:AddLine(Tr("In Classic"), 1, 0.82, 0)
  for _, r in ipairs(rows) do
    if r.was or r.diff then
      local col = r.diff and CHANGED or GRAY
      tt:AddDoubleLine(StatName(r.k), Value(r.k, r.was), NAME[1], NAME[2], NAME[3], col[1], col[2], col[3])
    end
  end
  if fx then
    local label = { [0] = ITEM_SPELL_TRIGGER_ONUSE or "Use:", [1] = ITEM_SPELL_TRIGGER_ONEQUIP or "Equip:",
      [2] = ITEM_SPELL_TRIGGER_ONPROC or "Chance on hit:" }
    for _, e in ipairs(fx) do
      tt:AddLine((label[e[1]] or "") .. " " .. e[2], CHANGED[1], CHANGED[2], CHANGED[3], true)
    end
  end
  tt:Show()
end

local function OnItem(tt)
  if not tt or tt.__cgcDone or not tt.GetItem then return end
  local ok, _, link = pcall(tt.GetItem, tt)
  if not ok or not link or Secret(link) then return end
  tt.__cgcDone = true
  local fine, err = pcall(AddLines, tt, link)
  if not fine and ns.Errors then ns.Errors(err) end
end

local hooked = {}
local function Hook(tt)
  if not tt or hooked[tt] or not tt.HookScript then return end
  hooked[tt] = true
  pcall(tt.HookScript, tt, "OnTooltipCleared", function(self) self.__cgcDone = nil end)
  if not (TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall) then
    pcall(tt.HookScript, tt, "OnTooltipSetItem", OnItem)
  end
end
local function HookAll()
  for _, name in ipairs({ "GameTooltip", "ItemRefTooltip", "ShoppingTooltip1", "ShoppingTooltip2",
    "ItemRefShoppingTooltip1", "ItemRefShoppingTooltip2" }) do
    Hook(_G[name])
  end
end
if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
  TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt) OnItem(tt) end)
end

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local OnOff = { { "On", true }, { "Off", false } }
ns.HelpConfig = {
  title = "Classic Gear Compare",
  tag = "Classic Gear Compare",
  settings = {
    { label = "Classic Stats in Tooltips", choices = OnOff,
      get = function() return DB.on and true or false end, set = function(v) DB.on = v end },
    { label = "New in Forever Line", choices = OnOff,
      get = function() return DB.newLine and true or false end, set = function(v) DB.newLine = v end },
  },
  notes = {
    { v = "1.0.0", "First release: hover any piece of gear to see what it did in Classic. Stats Forever changed are tinted, and its old Use, Equip and Chance on hit effects show when Forever changed them",
      "Gear that's new in Forever says so. Gear that didn't change shows nothing extra" },
  },
  report = function()
    local n = 0
    for _ in pairs(ns.CLASSIC or {}) do n = n + 1 end
    return { "Classic items " .. n .. ", on " .. tostring(DB.on) .. ", new line " .. tostring(DB.newLine) }
  end,
}

local function MinimapButton()
  if not Minimap or _G.ClassicGearCompareMinimapButton then return end
  local b = CreateFrame("Button", "ClassicGearCompareMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture(ICON)
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 160)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function() if ns.OpenHelp then ns.OpenHelp() end end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Classic Gear Compare")
    Tip:AddLine("Hover any gear to see what it did in Classic", 1, 1, 1, true)
    Tip:AddLine("Click: Settings & Help", 1, 1, 1)
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
function ClassicGearCompare_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_CLASSICGEARCOMPARE1 = "/gearcompare"
SLASH_CLASSICGEARCOMPARE2 = "/classicgearcompare"
SlashCmdList.CLASSICGEARCOMPARE = function(msg)
  local cmd = ((msg or ""):match("^%s*(%S*)") or ""):lower()
  if cmd == "on" then DB.on = true; Say(Tr("Classic stats in tooltips are on"))
  elseif cmd == "off" then DB.on = false; Say(Tr("Classic stats in tooltips are off"))
  elseif ns.OpenHelp then ns.OpenHelp() end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    ClassicGearCompareDB = ClassicGearCompareDB or {}
    DB = ClassicGearCompareDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
  elseif e == "PLAYER_LOGIN" then
    HookAll()
    pcall(MinimapButton)
  end
end)
