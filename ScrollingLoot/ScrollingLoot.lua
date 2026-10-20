-- Dalorrian's Scrolling Loot: what you loot floats up on screen, one clean line at a time.
-- /sloot for options. /sloot test shows sample loot without having to loot anything.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 1, 0.82, 0 }
local H, GAP, MAX = 24, 3, 8          -- line height, space between lines, most lines at once
local FADE_IN, FADE_OUT = 0.15, 0.6

local DEFAULTS = { scale = 1, hold = 4, money = true, up = true }

local P = ns.print or print   -- (1.1.0) Lang.lua: chat text in the player's language
local Tr = ns.Tr or function(x) return x end
local Tip = ns.Tip or GameTooltip
local function Say(msg) P("|cffffd100Scrolling Loot:|r " .. msg) end

local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local Count = (C_Item and C_Item.GetItemCount) or GetItemCount
local Instant = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant

---------------------------------------------------------------------------
-- where the lines start: drag it while unlocked
---------------------------------------------------------------------------
local anchor = CreateFrame("Frame", "ScrollingLootAnchor", UIParent, "BackdropTemplate")
anchor:SetSize(240, H)
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
-- (1.0.x fix) the gold "drag me" box is its own frame: hiding it never hides your loot
anchor.box = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
anchor.box:SetAllPoints()
anchor.box:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 2 })
anchor.box:SetBackdropColor(0.04, 0.04, 0.05, 0.85)
anchor.box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
anchor.label = anchor.box:CreateFontString(nil, "OVERLAY")
anchor.label:SetFont(FONT, 11, "")
anchor.label:SetShadowOffset(1, -1)
anchor.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
anchor.label:SetPoint("CENTER")
anchor.label:SetText("Scrolling Loot: Drag Me")
anchor.box:Hide()
anchor:EnableMouse(false)
anchor:RegisterForDrag("LeftButton")
anchor:SetScript("OnDragStart", anchor.StartMoving)
anchor:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(1)
  DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
end)

local function Place()
  anchor:ClearAllPoints()
  if DB.point then anchor:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
  else anchor:SetPoint("CENTER", UIParent, "CENTER", 260, -40) end   -- just right of your character
  anchor:SetScale(DB.scale or 1)
end

local function Lock(on)
  DB.unlocked = not on or nil
  anchor.box:SetShown(not on)
  anchor:EnableMouse(not on)
end

---------------------------------------------------------------------------
-- the lines: dark pill, a colored edge for the item's quality, icon, name, count
---------------------------------------------------------------------------
local pool, live = {}, {}

local function NewLine()
  local l = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
  l:SetHeight(H)
  l:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
  l:SetBackdropColor(0.04, 0.04, 0.05, 0.78)
  l:SetBackdropBorderColor(0, 0, 0, 1)
  l.edge = l:CreateTexture(nil, "ARTWORK")
  l.edge:SetPoint("TOPLEFT", 1, -1); l.edge:SetPoint("BOTTOMLEFT", 1, 1); l.edge:SetWidth(3)
  l.icon = l:CreateTexture(nil, "ARTWORK")
  l.icon:SetSize(H - 6, H - 6)
  l.icon:SetPoint("LEFT", 7, 0)
  l.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  -- (1.0.3) a thin border round the icon in the item's color, like your bags (gold for quest items)
  l.ib = CreateFrame("Frame", nil, l, "BackdropTemplate")
  l.ib:SetPoint("TOPLEFT", l.icon, "TOPLEFT", -1, 1)
  l.ib:SetPoint("BOTTOMRIGHT", l.icon, "BOTTOMRIGHT", 1, -1)
  l.ib:SetBackdrop({ edgeFile = W, edgeSize = 1 })
  l.text = l:CreateFontString(nil, "OVERLAY")
  l.text:SetFont(FONT, 12, "")
  l.text:SetShadowColor(0, 0, 0, 1)
  l.text:SetShadowOffset(1, -1)
  l.text:SetPoint("LEFT", l.icon, "RIGHT", 6, 0)
  l.text:SetJustifyH("LEFT")
  l.text:SetWordWrap(false)
  l.bags = l:CreateFontString(nil, "OVERLAY")
  l.bags:SetFont(FONT, 10, "")
  l.bags:SetShadowOffset(1, -1)
  l.bags:SetTextColor(0.6, 0.6, 0.62)
  l.bags:SetPoint("LEFT", l.text, "RIGHT", 6, 0)
  return l
end

local function Fit(l)
  local w = 7 + (H - 6) + 6 + l.text:GetStringWidth() + 10
  if l.bags:GetText() and l.bags:GetText() ~= "" then w = w + 6 + l.bags:GetStringWidth() end
  l:SetWidth(math.max(80, math.ceil(w)))
end

local function Paint(l)
  local label = l.name
  if l.count and l.count > 1 then label = label .. " |cffffffffx" .. l.count .. "|r" end
  l.text:SetText(label)
  -- (1.0.2) what you looted is the big number; your bag total sits after it, small and gray, only when it adds something
  local extra = l.total and l.total > (l.count or 1)
  l.bags:SetText(extra and (l.total .. " " .. Tr("in bags")) or "")
  Fit(l)
end

-- put a line on screen; the same item again while it's still showing just adds to its count
local function Push(key, icon, name, count, r, g, b, total)
  for _, l in ipairs(live) do
    if l.key == key and l.age < (DB.hold or 4) then
      l.count = (l.count or 1) + (count or 1)
      if total then l.total = total end
      l.age = FADE_IN
      Paint(l)
      return l
    end
  end
  local l = table.remove(pool) or NewLine()
  l.key, l.name, l.count, l.total, l.age = key, name, count or 1, total, 0
  l.icon:SetTexture(icon or "Interface\\Icons\\INV_Misc_QuestionMark")
  l.edge:SetColorTexture(r or 1, g or 1, b or 1, 1)
  l.ib:SetBackdropBorderColor(r or 1, g or 1, b or 1, 1)
  l.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  l:SetBackdropBorderColor(0, 0, 0, 1)
  l.y = nil
  Paint(l)
  l:SetAlpha(0)
  l:Show()
  table.insert(live, 1, l)
  -- too many: the oldest starts fading now
  for i = MAX + 1, #live do
    local old = live[i]
    if old.age < (DB.hold or 4) then old.age = DB.hold or 4 end
  end
  return l
end

-- every frame: slide each line to its spot (newest at the anchor, older ones pushed away) and fade them
local driver = CreateFrame("Frame")
driver:SetScript("OnUpdate", function(_, el)
  if #live == 0 then return end
  local hold = DB.hold or 4
  local dir = DB.up and 1 or -1
  for i = #live, 1, -1 do
    local l = live[i]
    l.age = l.age + el
    local a
    if l.age < FADE_IN then a = l.age / FADE_IN
    elseif l.age < hold then a = 1
    else a = 1 - (l.age - hold) / FADE_OUT end
    if a <= 0 then
      l:Hide()
      table.remove(live, i)
      pool[#pool + 1] = l
    else
      l:SetAlpha(a)
      local target = (i - 1) * (H + GAP) * dir
      if l.age >= hold then target = target + (l.age - hold) * 30 * dir end   -- drift as it fades
      l.y = l.y and (l.y + (target - l.y) * math.min(1, el * 12)) or target
      l:ClearAllPoints()
      l:SetPoint("BOTTOMLEFT", anchor, "BOTTOMLEFT", 0, l.y)
    end
  end
end)

---------------------------------------------------------------------------
-- reading the loot messages
---------------------------------------------------------------------------
-- turn "You receive loot: %s." into a pattern that finds the item link (and count)
local function Pattern(fmt)
  if type(fmt) ~= "string" then return end
  local p = fmt:gsub("%%%d?%$?", "%%"):gsub("([%(%)%.%[%]%*%+%-%?%^%$])", "%%%1")
  p = p:gsub("%%s", "(.+)"):gsub("%%d", "(%%d+)")
  return "^" .. p .. "$"
end
local MULTI, SINGLE = {}, {}
for _, n in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_CREATED_SELF_MULTIPLE", "LOOT_ITEM_BONUS_ROLL_SELF_MULTIPLE" }) do
  local p = Pattern(_G[n]); if p then MULTI[#MULTI + 1] = p end
end
for _, n in ipairs({ "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF", "LOOT_ITEM_CREATED_SELF", "LOOT_ITEM_BONUS_ROLL_SELF" }) do
  local p = Pattern(_G[n]); if p then SINGLE[#SINGLE + 1] = p end
end

local function QualityColor(q)
  local c = (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[q or 1])
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

local function ShowItem(link, count)
  if DB.off then return end
  local name, _, quality, _, _, _, _, _, _, icon = GetInfo(link)
  if not icon and Instant then local _, _, _, _, ic = Instant(link); icon = ic end
  name = name or link:match("%[(.-)%]") or "Item"
  local r, g, b = QualityColor(quality)
  local hex = string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
  local id = tonumber(link:match("item:(%d+)"))
  -- (1.0.3) quest items get gold, the way your bags show them
  local classID = Instant and select(6, Instant(link))
  local quest = classID == ((Enum and Enum.ItemClass and Enum.ItemClass.Questitem) or 12)
  local er, eg, eb = r, g, b
  if quest then er, eg, eb = GOLD[1], GOLD[2], GOLD[3] end
  local l = Push(id or link, icon, hex .. name .. "|r", count, er, eg, eb)
  if quest then l:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.9) end
  -- how many you have now, once the bags catch up
  if id and Count then
    C_Timer.After(0.3, function()
      local total = Count(id) or 0
      if l.key == (id or link) and total > 0 then l.total = total; Paint(l) end
    end)
  end
end

local function OnLoot(msg)
  for _, p in ipairs(MULTI) do
    local link, n = msg:match(p)
    if link then ShowItem(link, tonumber(n) or 1) return end
  end
  for _, p in ipairs(SINGLE) do
    local link = msg:match(p)
    if link then ShowItem(link, 1) return end
  end
end

-- money: read straight from the loot message ("You loot 1 Gold, 5 Silver"), so selling to a vendor never shows
local function Amount(fmt, msg)
  if type(fmt) ~= "string" then return 0 end
  local p = fmt:gsub("%%d", "(%%d+)")
  return tonumber(msg:match(p)) or 0
end
-- (1.0.4) money takes the color of the biggest coin in it: copper, silver or gold, edge and icon both
local COIN = {
  gold = { 1, 0.82, 0, "Interface\\MoneyFrame\\UI-GoldIcon" },
  silver = { 0.78, 0.8, 0.85, "Interface\\MoneyFrame\\UI-SilverIcon" },
  copper = { 0.78, 0.47, 0.22, "Interface\\MoneyFrame\\UI-CopperIcon" },
}
local function Coin(c)
  if c >= 10000 then return COIN.gold elseif c >= 100 then return COIN.silver else return COIN.copper end
end
local function ShowMoney(copper)
  if DB.off or not DB.money or not copper or copper <= 0 then return end
  local function coins(c) return "|cffffffff" .. ((GetCoinTextureString and GetCoinTextureString(c)) or (c .. "c")) .. "|r" end
  local k = Coin(copper)
  local l = Push("money", k[4], coins(copper), 1, k[1], k[2], k[3])
  -- more money while the line is still up adds to it
  if l.age > 0 and l.copper then l.copper = l.copper + copper else l.copper = copper end
  k = Coin(l.copper)
  l.edge:SetColorTexture(k[1], k[2], k[3], 1)
  l.icon:SetTexture(k[4])
  l.icon:SetTexCoord(0, 1, 0, 1)
  l.ib:SetBackdropBorderColor(0, 0, 0, 0)   -- coins need no border
  l.name, l.count = coins(l.copper), 1
  Paint(l)
end
local function OnMoney(msg)
  local c = Amount(GOLD_AMOUNT, msg) * 10000 + Amount(SILVER_AMOUNT, msg) * 100 + Amount(COPPER_AMOUNT, msg)
  ShowMoney(c)
end

local MinimapButton   -- (1.1.0) further down
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("CHAT_MSG_LOOT")
ev:RegisterEvent("CHAT_MSG_MONEY")
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" and a1 == "ScrollingLoot" then
    ScrollingLootDB = ScrollingLootDB or {}
    DB = ScrollingLootDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
  elseif e == "PLAYER_LOGIN" then
    Place()
    Lock(not DB.unlocked)
    anchor.label:SetText(Tr("Scrolling Loot") .. ": " .. Tr("Drag Me"))
    pcall(MinimapButton)
  elseif not DB then return
  elseif e == "CHAT_MSG_LOOT" then
    OnLoot(a1 or "")
  elseif e == "CHAT_MSG_MONEY" then
    OnMoney(a1 or "")
  end
end)

---------------------------------------------------------------------------
-- /sloot
---------------------------------------------------------------------------
local SAMPLES = { 2589, 2592, 4306, 2770, 858, 4500, 10305, 14047, 6948, 19019 }
local function Test()
  local i = 0
  local function one()
    i = i + 1
    if i > 7 then return end
    local id = SAMPLES[math.random(#SAMPLES)]
    if i == 4 then ShowMoney(math.random(150, 48000))
    elseif Item and Item.CreateFromItemID then
      local item = Item:CreateFromItemID(id)
      item:ContinueOnItemLoad(function() ShowItem(item:GetItemLink(), math.random(1, 3)) end)
    else
      ShowItem("|cff9d9d9d|Hitem:" .. id .. "::::::::|h[Test Item]|h|r", 1)
    end
    C_Timer.After(0.45, one)
  end
  one()
end

---------------------------------------------------------------------------
-- (1.1.0) Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Scrolling Loot",
  tag = "Scrolling Loot",
  settings = {
    { label = "Scrolling Loot", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil end },
    { label = "Show Money", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.money and true or false end, set = function(v) DB.money = v end },
    { label = "Lines Go", choices = { { "Up", true }, { "Down", false } },
      get = function() return DB.up and true or false end, set = function(v) DB.up = v end },
    { label = "Time On Screen", choices = { { "2 Sec", 2 }, { "4 Sec", 4 }, { "6 Sec", 6 }, { "10 Sec", 10 } },
      get = function() return DB.hold or 4 end, set = function(v) DB.hold = v end },
    { label = "Size", choices = { { "Small", 0.85 }, { "Normal", 1 }, { "Big", 1.25 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Place() end },
    { label = "Move It", choices = { { "Locked", "lock" }, { "Move It", "move" }, { "Reset", "reset" } },
      get = function() return DB.unlocked and "move" or "lock" end,
      set = function(v)
        if v == "move" then Lock(false)
        elseif v == "lock" then Lock(true)
        else DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; Place(); Lock(true) end
      end },
    { label = "Preview", choices = { { "Show Me", "test" } },
      get = function() return nil end, set = function() SlashCmdList.SCROLLINGLOOT("test") end },
  },
  notes = {
    { v = "1.1.1", "Settings rows with four choices fit inside the window now" },
    { v = "1.1.0", "A Settings & Help window, a minimap button and 10 languages" },
    { v = "1.0.4", "Money lines take the color of the biggest coin in them" },
    { v = "1.0.3", "Quest items get a gold border" },
    { v = "1.0.0", "First release: what you loot floats up on screen, one clean line at a time" },
  },
  report = function()
    return { "Hold " .. tostring(DB.hold) .. ", money " .. tostring(DB.money) .. ", up " .. tostring(DB.up) ..
      ", scale " .. tostring(DB.scale) .. (DB.off and ", turned off" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.ScrollingLootMinimapButton then return end
  local b = CreateFrame("Button", "ScrollingLootMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Misc_Bag_10")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 65)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.SCROLLINGLOOT("off")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Scrolling Loot")
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
function ScrollingLoot_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_SCROLLINGLOOT1 = "/sloot"
SLASH_SCROLLINGLOOT2 = "/scrollingloot"
SlashCmdList.SCROLLINGLOOT = function(msg)
  local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(%S*)")
  if cmd == "test" then
    Test()
  elseif cmd == "unlock" or cmd == "move" then
    Lock(false); Say("drag the gold box where you want your loot. /sloot lock when you're done.")
  elseif cmd == "lock" then
    Lock(true); Say("locked.")
  elseif cmd == "scale" and tonumber(arg) then
    DB.scale = math.max(0.5, math.min(2, tonumber(arg))); Place(); Say("size " .. DB.scale .. ".")
  elseif cmd == "time" and tonumber(arg) then
    DB.hold = math.max(1, math.min(15, tonumber(arg))); Say("each line stays " .. DB.hold .. " seconds.")
  elseif cmd == "money" then
    DB.money = not DB.money; Say("money " .. (DB.money and "shown." or "hidden."))
  elseif cmd == "down" then
    DB.up = not DB.up; Say("lines now go " .. (DB.up and "up." or "down."))
  elseif cmd == "reset" then
    DB.point, DB.rel, DB.x, DB.y, DB.scale, DB.hold = nil, nil, nil, nil, 1, 4; Place(); Say("back to the default spot and size.")
  elseif cmd == "off" then
    DB.off = not DB.off or nil; Say(DB.off and "turned off" or "turned on")
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("what you loot floats up on screen.")
    P("  /sloot help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /sloot test   (" .. "show sample loot" .. ")")
  end
end
