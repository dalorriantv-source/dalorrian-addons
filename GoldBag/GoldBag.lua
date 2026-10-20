-- Dalorrian's Gold Bag: your gold in one small dark box, sitting on top of your bag bar.
-- Shift-drag to move it. /goldbag for options.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 1, 0.82, 0 }
local DEFAULTS = { scale = 1, short = false, alts = true }
local GICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:10:10:2:0|t"
local SICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:10:10:2:0|t"
local CICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:10:10:2:0|t"

local P = ns.print or print   -- (1.1.0) Lang.lua: chat text in the player's language
local Tr = ns.Tr or function(x) return x end
local Tip = ns.Tip or GameTooltip
local function Say(msg) P("|cffffd100Gold Bag:|r " .. msg) end

local function Commas(n)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  local s = tostring(n)
  while true do
    local t, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
    s = t
    if k == 0 then return s end
  end
end

-- 1,234g 56s 7c, or just the gold with /goldbag short
local function Money(c, short)
  c = c or 0
  local g, s, cp = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  if short then   -- the biggest coin you have: under a gold it shows your silver, under a silver your copper
    if g > 0 then return Commas(g) .. GICON elseif s > 0 then return s .. SICON else return cp .. CICON end
  end
  local out = {}
  if g > 0 then out[#out + 1] = Commas(g) .. GICON end
  if g > 0 or s > 0 then out[#out + 1] = s .. SICON end
  out[#out + 1] = cp .. CICON
  return table.concat(out, " ")
end

local box = CreateFrame("Frame", "GoldBagFrame", UIParent, "BackdropTemplate")
box:SetSize(40, 15)   -- (1.0.4) only as wide as what it shows
box:SetFrameStrata("MEDIUM")   -- (1.0.5) the same layer as the action bars, so windows and the world map cover it
box:SetFrameLevel(100)         -- but on top of the action bar art
box:SetClampedToScreen(true)
box:SetMovable(true)
box:EnableMouse(true)
box:RegisterForDrag("LeftButton")
box:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 2 })
box:SetBackdropColor(0.04, 0.04, 0.05, 0.9)
box:SetBackdropBorderColor(0, 0, 0, 1)
box.text = box:CreateFontString(nil, "OVERLAY")
box.text:SetFont(FONT, 10, "")
box.text:SetShadowColor(0, 0, 0, 1)
box.text:SetShadowOffset(1, -1)
box.text:SetTextColor(1, 1, 1)
box.text:SetPoint("RIGHT", -4, 0)
box.text:SetJustifyH("RIGHT")
box:Hide()

-- (1.2.0) every character's gold, kept as you log in on each one, for the hover
local ME, REALM
local function Remember(m)
  if not (DB and ME) then return end
  DB.chars = DB.chars or {}
  DB.chars[REALM] = DB.chars[REALM] or {}
  local _, class = UnitClass("player")
  DB.chars[REALM][ME] = { money = m, class = class, when = time() }
end

local start   -- what you had when you logged in, for the hover
local function Update()
  if not DB then return end
  local m = GetMoney()
  start = start or m
  Remember(m)
  if DB.hidden then box:Hide() return end
  box.text:SetText(Money(m, DB.short))
  box:SetWidth(math.max(24, math.ceil(box.text:GetStringWidth() + 10)))
  box:Show()
end

-- on top of the bag bar, right edges lined up. With the classic action bar the experience and reputation
-- bars sit above the bags, so it goes on top of whichever of those is highest. No bag bar: bottom right.
local function BagBar()
  local b = MainMenuBarBackpackButton
  if b and b:IsVisible() and b:GetRight() then return b end
end
local function Top(f, ref)
  if not (f and f.IsVisible and f:IsVisible() and f:GetTop() and f:GetLeft() and f:GetRight()) then return end
  if f:GetTop() * f:GetEffectiveScale() > ref:GetTop() * ref:GetEffectiveScale() + 60 then return end   -- not a bar that tall
  -- only bars that run over the bag bar's right end count
  local s, rs = f:GetEffectiveScale(), ref:GetEffectiveScale()
  local right = ref:GetRight() * rs
  if f:GetLeft() * s <= right and f:GetRight() * s >= right - 20 then return f:GetTop() * s end
end
local function Place()
  box:ClearAllPoints()
  box:SetScale(DB.scale or 1)
  if DB.point then
    box:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
    return
  end
  local bag = BagBar()
  if not bag then box:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -8, 48) return end
  local bs = bag:GetEffectiveScale()
  local top = bag:GetTop() * bs
  for _, f in ipairs({ MainMenuExpBar, ReputationWatchBar, MainMenuBarMaxLevelBar, StatusTrackingBarManager or false,
    MainStatusTrackingBarContainer or false, MainMenuBar or false }) do
    local t = Top(f, bag)
    if t and t > top then top = t end
  end
  local us = box:GetEffectiveScale()
  box:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMLEFT", (bag:GetRight() * bs) / us, (top / us) + 3)
end

box:SetScript("OnDragStart", function(self) if IsShiftKeyDown() then self:StartMoving() end end)
box:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(1)
  DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
end)
box:SetScript("OnEnter", function(self)
  self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
  local diff = GetMoney() - (start or GetMoney())
  Tip:SetOwner(self, "ANCHOR_TOPLEFT")
  Tip:AddDoubleLine("Gold Bag", Money(GetMoney()), GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)   -- always the full amount
  if diff >= 0 then Tip:AddDoubleLine("This session", "+" .. Money(diff), 0.8, 0.8, 0.8, 0.4, 1, 0.4)
  else Tip:AddDoubleLine("This session", "-" .. Money(-diff), 0.8, 0.8, 0.8, 1, 0.4, 0.4) end
  -- (1.2.0) your other characters and the total
  if DB.alts and DB.chars then
    local realms, total, count = {}, 0, 0
    for realm in pairs(DB.chars) do realms[#realms + 1] = realm end
    table.sort(realms, function(a, b) if a == REALM then return true elseif b == REALM then return false end return a < b end)
    for _, realm in ipairs(realms) do
      local list = {}
      for name, c in pairs(DB.chars[realm]) do list[#list + 1] = { name = name, c = c } end
      table.sort(list, function(a, b) return (a.c.money or 0) > (b.c.money or 0) end)
      if #list > 0 then
        Tip:AddLine(" ")
        if #realms > 1 then GameTooltip:AddLine(realm, 0.6, 0.6, 0.6) end
        for _, e in ipairs(list) do
          local cc = RAID_CLASS_COLORS and e.c.class and RAID_CLASS_COLORS[e.c.class]
          local r, g, b = 1, 1, 1
          if cc then r, g, b = cc.r, cc.g, cc.b end
          local label = e.name .. ((realm == REALM and e.name == ME) and "  *" or "")
          GameTooltip:AddDoubleLine(label, Money(e.c.money or 0), r, g, b, 1, 1, 1)
          total = total + (e.c.money or 0); count = count + 1
        end
      end
    end
    if count > 1 then Tip:AddDoubleLine("All Characters", Money(total), GOLD[1], GOLD[2], GOLD[3], GOLD[1], GOLD[2], GOLD[3]) end
  end
  Tip:AddLine("Shift-drag to move.", 0.6, 0.6, 0.6)
  Tip:Show()
end)
box:SetScript("OnLeave", function(self)
  self:SetBackdropBorderColor(0, 0, 0, 1)
  GameTooltip:Hide()
end)

local MinimapButton   -- (1.1.0) further down
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:RegisterEvent("PLAYER_MONEY")
for _, e in ipairs({ "PLAYER_LEVEL_UP", "UPDATE_FACTION", "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED" }) do pcall(ev.RegisterEvent, ev, e) end
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= "GoldBag" then return end
    GoldBagDB = GoldBagDB or {}
    DB = GoldBagDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
  elseif e == "PLAYER_ENTERING_WORLD" then
    ME, REALM = UnitName("player"), GetRealmName and GetRealmName() or "?"
    Place(); Update()
    pcall(MinimapButton)
    -- bar addons (Bartender and friends) move the bag buttons a moment after login
    C_Timer.After(2, function() Place(); Update() end)
  elseif e == "PLAYER_MONEY" then
    Update()
  else
    C_Timer.After(0.5, Place)   -- a bar showed up or went away above the bags
  end
end)

---------------------------------------------------------------------------
-- (1.1.0) Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Gold Bag",
  tag = "Gold Bag",
  settings = {
    { label = "Gold Bag", choices = { { "Shown", "on" }, { "Hidden", "off" } },
      get = function() return DB.hidden and "off" or "on" end,
      set = function(v) DB.hidden = (v == "off") or nil; Update() end },
    { label = "Show", choices = { { "All Coins", "full" }, { "Biggest Coin", "short" } },
      get = function() return DB.short and "short" or "full" end,
      set = function(v) DB.short = (v == "short"); Update() end },
    { label = "Hover Shows", choices = { { "All Characters", true }, { "This Character", false } },
      get = function() return DB.alts and true or false end, set = function(v) DB.alts = v end },
    { label = "Size", choices = { { "Small", 0.85 }, { "Normal", 1 }, { "Big", 1.25 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Place() end },
    { label = "Spot", choices = { { "Stick To Bags", "stick" } },
      get = function() return DB.point and "moved" or "stick" end,
      set = function() DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; Place() end },
  },
  notes = {
    { v = "1.2.0", "Hover the gold bag to see every character's gold and your total. Each character shows up the next time you log in on it. Pick This Character under Hover Shows to keep it to one" },
    { v = "1.1.0", "A Settings & Help window, a minimap button and 10 languages" },
    { v = "1.0.5", "Sits under the world map and other windows instead of on top of them" },
    { v = "1.0.0", "First release: your gold in one small box on top of your bag bar" },
  },
  report = function()
    return { "Short " .. tostring(DB.short) .. ", scale " .. tostring(DB.scale) .. ", moved " .. tostring(DB.point ~= nil) ..
      (DB.hidden and ", hidden" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.GoldBagMinimapButton then return end
  local b = CreateFrame("Button", "GoldBagMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Misc_Coin_02")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 145)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.GOLDBAG("hide")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Gold Bag")
    Tip:AddLine("Left-click: Settings & Help", 1, 1, 1)
    Tip:AddLine(DB.hidden and "Right-click: show it" or "Right-click: hide it", 1, 1, 1)
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
function GoldBag_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_GOLDBAG1 = "/goldbag"
SlashCmdList.GOLDBAG = function(msg)
  local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(%S*)")
  if cmd == "short" or cmd == "gold" then
    DB.short = true; Update(); Say("biggest coin only. /goldbag full brings them all back.")
  elseif cmd == "full" then
    DB.short = false; Update(); Say("gold, silver and copper.")
  elseif cmd == "scale" and tonumber(arg) then
    DB.scale = math.max(0.5, math.min(2, tonumber(arg))); Place(); Say("size " .. DB.scale .. ".")
  elseif cmd == "reset" or cmd == "stick" then
    DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil
    if cmd == "reset" then DB.scale = 1 end
    Place(); Say("stuck to your bag bar. It follows the bags wherever your bar is.")
  elseif cmd == "hide" then
    DB.hidden = not DB.hidden or nil
    Update()
    Say(DB.hidden and "hidden. /goldbag hide again to bring it back." or "shown.")
  elseif cmd == "forget" and arg ~= "" then
    -- a character you deleted: /goldbag forget <name>
    local gone
    for _, chars in pairs(DB.chars or {}) do
      for name in pairs(chars) do if name:lower() == arg then chars[name] = nil; gone = name end end
    end
    Say(gone and string.format(Tr("forgot %s"), gone) or string.format(Tr("no character called %s"), arg))
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("your gold, on top of your bag bar. Shift-drag to move.")
    P("  /goldbag help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /goldbag short   (" .. "biggest coin" .. ")   /goldbag full   (" .. "gold, silver and copper" .. ")")
    P("  /goldbag stick   (" .. "back on your bag bar" .. ")   /goldbag hide")
  end
end
