-- Dalorrian's Auto Opener: opens your clams, bags of loot, crates and anything else that opens, by itself,
-- one after another whenever you're out of combat. (1.1.0)
-- With Open Automatically off, a button shows up instead: each click opens the next one. Shift-drag to move it,
-- right-click skips that kind of item. /opener for options.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local DEFAULTS = { size = 40, skip = {}, count = true, auto = true, summary = true }
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local function Say(msg) P("|cffffd100Auto Opener:|r " .. msg) end
local Tip = ns.Tip or GameTooltip

local tries, later   -- (1.1.1) set up with the auto opening further down
local GetInfo = C_Container and C_Container.GetContainerItemInfo
local NumSlots = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
local LOCKED_TEXT = LOCKED or "Locked"
local OPEN_TEXT = ITEM_OPENABLE or "<Right Click to Open>"

-- does the tooltip say it opens, or that it's a locked box?
local scan
local function TooltipLines(bag, slot)
  local lines = {}
  if C_TooltipInfo and C_TooltipInfo.GetBagItem then
    local ok, data = pcall(C_TooltipInfo.GetBagItem, bag, slot)
    if ok and data and data.lines then
      for _, l in ipairs(data.lines) do if l.leftText then lines[#lines + 1] = l.leftText end end
      return lines
    end
  end
  if not scan then
    scan = CreateFrame("GameTooltip", "AutoOpenerScan", nil, "GameTooltipTemplate")
    scan:SetOwner(WorldFrame, "ANCHOR_NONE")
  end
  scan:ClearLines()
  pcall(scan.SetBagItem, scan, bag, slot)
  for i = 1, scan:NumLines() do
    local fs = _G["AutoOpenerScanTextLeft" .. i]
    local t = fs and fs:GetText()
    if t then lines[#lines + 1] = t end
  end
  return lines
end

local function Openable(bag, slot)
  local info = GetInfo and GetInfo(bag, slot)
  local id, icon, count, hasLoot
  if info then
    id, icon, count, hasLoot = info.itemID, info.iconFileID, info.stackCount, info.hasLoot
  elseif GetContainerItemInfo then
    local tex, cnt, _, _, _, lootable, link = GetContainerItemInfo(bag, slot)
    icon, count, hasLoot = tex, cnt, lootable
    id = link and tonumber(link:match("item:(%d+)"))
  end
  if not id then return end
  if DB.skip[id] or (later and later[id]) then return end
  local lines = TooltipLines(bag, slot)
  local opens, locked = hasLoot and true or false, false
  for _, t in ipairs(lines) do
    if t == OPEN_TEXT then opens = true end
    if t == LOCKED_TEXT then locked = true end
  end
  if opens and not locked then return id, icon, count or 1 end
end

---------------------------------------------------------------------------
-- the button: a secure item button, so the click itself opens the item
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "AutoOpenerButton", UIParent, "SecureActionButtonTemplate, BackdropTemplate")
btn:SetSize(40, 40)
btn:SetPoint("CENTER", UIParent, "CENTER", 0, -180)
btn:SetFrameStrata("MEDIUM")
btn:SetClampedToScreen(true)
btn:SetMovable(true)
btn:RegisterForClicks("AnyUp", "AnyDown")
btn:RegisterForDrag("LeftButton")
btn:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 2 })
btn:SetBackdropColor(0, 0, 0, 0.8)
btn:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
btn.icon = btn:CreateTexture(nil, "ARTWORK")
btn.icon:SetPoint("TOPLEFT", 2, -2); btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
btn.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
btn.count:SetPoint("BOTTOMRIGHT", -3, 3)
btn.hl = btn:CreateTexture(nil, "HIGHLIGHT")
btn.hl:SetAllPoints(btn.icon); btn.hl:SetColorTexture(1, 1, 1, 0.15)
btn:SetAttribute("type1", "item")     -- left-click: open it
btn:Hide()

local function Scan()
  local first, total = nil, 0
  for bag = 0, 4 do
    for slot = 1, (NumSlots(bag) or 0) do
      local id, icon, count = Openable(bag, slot)
      if id then
        total = total + count
        if not first then first = { bag = bag, slot = slot, id = id, icon = icon, count = count } end
      end
    end
  end
  return first, total
end

local pending
local function Update()
  if not DB then return end
  if InCombatLockdown() then pending = true return end   -- the button can only change out of combat
  pending = nil
  local first, total = nil, 0
  if not DB.off and not DB.auto then first, total = Scan() end   -- (1.1.0) the button is for when it doesn't open by itself
  btn.item = first
  if first then
    btn:SetAttribute("item", first.bag .. " " .. first.slot)   -- "bag slot": opens exactly that one
    btn.icon:SetTexture(first.icon)
    btn.count:SetText(DB.count and total > 1 and total or "")
    btn:SetSize(DB.size or 40, DB.size or 40)
    btn:Show()
  else
    btn:SetAttribute("item", nil)
    btn:Hide()
  end
end

btn:SetScript("OnDragStart", function(self) if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end end)
btn:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(1)
  DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
end)
-- right-click: skip this kind of item from now on (Settings & Help can bring them back)
btn:HookScript("OnMouseUp", function(self, button)
  if button ~= "RightButton" or not self.item then return end
  local name = (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(self.item.id)) or (GetItemInfo and GetItemInfo(self.item.id)) or "?"
  DB.skip[self.item.id] = name
  P("|cffffd100Auto Opener:|r " .. string.format(Tr("skipping %s from now on. Settings & Help brings it back"), name) .. ".")
  Update()
end)
btn:SetScript("OnEnter", function(self)
  if not self.item then return end
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  pcall(GameTooltip.SetBagItem, GameTooltip, self.item.bag, self.item.slot)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine(Tr("Click: open it"), 1, 1, 1)
  GameTooltip:AddLine(Tr("Right-click: skip this item from now on"), 1, 1, 1)
  GameTooltip:AddLine(Tr("Shift-drag to move"), 0.6, 0.6, 0.6)
  GameTooltip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function Place()
  if InCombatLockdown() then return end
  btn:ClearAllPoints()
  if DB.point then btn:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
  else btn:SetPoint("CENTER", UIParent, "CENTER", 0, -180) end
end

---------------------------------------------------------------------------
-- (1.1.0) opening by itself: one at a time, only when nothing else is going on. At a vendor, bank, mailbox,
-- trade or auction house the same action would sell, store or attach the item, so it waits until those close.
---------------------------------------------------------------------------
local Use = (C_Container and C_Container.UseContainerItem) or UseContainerItem
local lastTry, queued = 0, false
tries, later = {}, {}
local function Shown(f) return f and f.IsShown and f:IsShown() end
local function Busy()
  return InCombatLockdown() or UnitIsDeadOrGhost("player") or (UnitOnTaxi and UnitOnTaxi("player"))
    or Shown(MerchantFrame) or Shown(BankFrame) or Shown(MailFrame) or Shown(SendMailFrame) or Shown(TradeFrame)
    or Shown(AuctionFrame) or Shown(AuctionHouseFrame) or Shown(GuildBankFrame) or Shown(LootFrame)
    or (UnitCastingInfo and UnitCastingInfo("player")) or (UnitChannelInfo and UnitChannelInfo("player"))
    or (SpellIsTargeting and SpellIsTargeting()) or (CursorHasItem and CursorHasItem())
    or (GetNumLootItems and GetNumLootItems() > 0)
end
---------------------------------------------------------------------------
-- (1.2.0) one quiet line when a batch is done: what you opened and what came out
---------------------------------------------------------------------------
local batch, catchUntil, finishAt = nil, 0, 0
local function ItemName(id)
  return (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)) or (GetItemInfo and GetItemInfo(id)) or "?"
end
local function Opening(id)
  if not batch then batch = { opened = {}, openOrder = {}, got = {}, gotOrder = {}, money = GetMoney() } end
  local n = ItemName(id)
  if not batch.opened[n] then batch.openOrder[#batch.openOrder + 1] = n end
  batch.opened[n] = (batch.opened[n] or 0) + 1
  catchUntil = GetTime() + 5   -- the loot that follows is from this
end
local PREFIXES = {}
for _, f in ipairs({ LOOT_ITEM_SELF, LOOT_ITEM_SELF_MULTIPLE, LOOT_ITEM_PUSHED_SELF, LOOT_ITEM_PUSHED_SELF_MULTIPLE }) do
  local pre = type(f) == "string" and f:match("^(.-)%%s")
  if pre and pre ~= "" then PREFIXES[pre] = true end
end
if not next(PREFIXES) then PREFIXES["You receive"] = true end
local function Looted(msg)
  if not batch or GetTime() > catchUntil or type(msg) ~= "string" then return end
  local mine = false
  for pre in pairs(PREFIXES) do if msg:sub(1, #pre) == pre then mine = true end end
  if not mine then return end
  local link = msg:match("|c%x+|Hitem:.-|h%[.-%]|h|r") or msg:match("|Hitem:.-|h%[.-%]|h")
  if not link then return end
  local qty = tonumber(msg:match("|h|r?x(%d+)") or msg:match("x(%d+)%.?$")) or 1
  if not batch.got[link] then batch.gotOrder[#batch.gotOrder + 1] = link end
  batch.got[link] = (batch.got[link] or 0) + qty
end
local function Money(c)
  if GetMoneyString then return GetMoneyString(c, true) end
  if GetCoinTextureString then return GetCoinTextureString(c) end
  return math.floor(c / 10000) .. "g " .. (math.floor(c / 100) % 100) .. "s " .. (c % 100) .. "c"
end
local function Finish()
  local b = batch
  batch = nil
  if not b or not DB.summary then return end
  local opened, total = {}, 0
  for _, n in ipairs(b.openOrder) do total = total + b.opened[n] end
  local what = (#b.openOrder == 1) and (b.opened[b.openOrder[1]] > 1 and (b.opened[b.openOrder[1]] .. " " .. b.openOrder[1]) or b.openOrder[1])
    or (total .. " " .. Tr("items"))
  local parts = {}
  for _, l in ipairs(b.gotOrder) do parts[#parts + 1] = l .. (b.got[l] > 1 and (" x" .. b.got[l]) or "") end
  local gained = GetMoney() - (b.money or GetMoney())
  if gained > 0 then parts[#parts + 1] = Money(gained) end
  if #parts == 0 then parts[1] = Tr("nothing") end
  print("|cffffd100" .. Tr("Auto Opener") .. ":|r " .. string.format(Tr("opened %s: %s"), what, table.concat(parts, ", ")))
end
local function FinishSoon()
  -- the batch is done once nothing new has opened for a couple of seconds
  if not batch then return end
  finishAt = GetTime() + 2.5
  C_Timer.After(2.6, function() if batch and GetTime() >= finishAt then Finish() end end)
end
-- the button (Open Automatically off) counts too
btn:HookScript("PreClick", function(self, button) if button == "LeftButton" and self.item then Opening(self.item.id) end end)

local AutoOpen
AutoOpen = function()
  queued = false
  if not DB or DB.off or not DB.auto or not Use then return end
  if Busy() then return end   -- an event brings it back (combat ends, a window closes, the loot is taken)
  local wait = 0.6 - (GetTime() - lastTry)
  if wait > 0 then queued = true; C_Timer.After(wait, AutoOpen) return end
  local first = Scan()
  if not first then return end
  -- (1.1.1) something that won't open yet (a gift before its day, say) is left alone for the rest of the session
  -- instead of being tried over and over
  local key = first.bag .. ":" .. first.slot .. ":" .. first.id .. ":" .. (first.count or 1)   -- a stack going down is progress
  tries[key] = (tries[key] or 0) + 1
  if tries[key] > 2 then
    later[first.id] = true
    queued = true; C_Timer.After(0.3, AutoOpen)
    return
  end
  lastTry = GetTime()
  Opening(first.id)
  pcall(Use, first.bag, first.slot)
  -- the loot window closing (or the bags changing) asks for the next one; this is the backstop
  queued = true; C_Timer.After(1.5, AutoOpen)
end
local function Soon()
  if queued then return end
  queued = true
  C_Timer.After(0.3, AutoOpen)
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local MinimapButton
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("BAG_UPDATE_DELAYED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:RegisterEvent("LOOT_CLOSED")
ev:RegisterEvent("CHAT_MSG_LOOT")
for _, e in ipairs({ "MERCHANT_CLOSED", "BANKFRAME_CLOSED", "MAIL_CLOSED", "TRADE_CLOSED", "AUCTION_HOUSE_CLOSED", "PLAYER_UNGHOST", "PLAYER_ALIVE" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    AutoOpenerDB = AutoOpenerDB or {}
    DB = AutoOpenerDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
  elseif e == "PLAYER_LOGIN" then
    Place()
    pcall(MinimapButton)
    C_Timer.After(2, function() Update(); Soon() end)   -- item info is still loading right at login
  elseif e == "CHAT_MSG_LOOT" then
    Looted(a1)
  elseif e == "PLAYER_REGEN_ENABLED" then
    if pending then Update() end
    Soon()
  else
    if e == "LOOT_CLOSED" and batch then catchUntil = GetTime() + 1; FinishSoon() end
    Update()
    Soon()
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local function SkipCount() local n = 0; for _ in pairs(DB and DB.skip or {}) do n = n + 1 end return n end
ns.HelpConfig = {
  title = "Auto Opener",
  tag = "Auto Opener",
  settings = {
    { label = "Auto Opener", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil; Update(); Soon() end },
    { label = "Open Automatically", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.auto and true or false end,
      set = function(v) DB.auto = v; Update(); Soon() end },
    { label = "Chat Summary", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.summary and true or false end, set = function(v) DB.summary = v end },
    { label = "Button Size", choices = { { "Small", 32 }, { "Normal", 40 }, { "Big", 52 } },
      get = function() return DB.size or 40 end, set = function(v) DB.size = v; Update() end },
    { label = "Show Count", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.count and true or false end, set = function(v) DB.count = v; Update() end },
    { label = "Skipped Items", choices = { { "Bring Them Back", "clear" } },
      get = function() return nil end,
      set = function()
        local n = SkipCount()
        wipe(DB.skip); Update(); Soon()
        Say(string.format(Tr("%s skipped items are back"), n))
      end },
    { label = "Button Spot", choices = { { "Reset", "reset" } },
      get = function() return nil end,
      set = function() DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; Place() end },
  },
  notes = {
    { v = "1.2.0", "One quiet line in chat after a batch: what you opened and what came out, gold included" },
    { v = "1.1.1", "Something that can't be opened yet is left alone instead of being tried again and again" },
    { v = "1.1.0", "Opens everything by itself, one after another, whenever you're out of combat. Turn Open Automatically off to get the button back" },
    { v = "1.0.0", "First release: one button that opens your clams, bags of loot and crates, one per click" },
  },
  report = function()
    return { "Auto " .. tostring(DB.auto) .. ", size " .. tostring(DB.size) .. ", skipped " .. SkipCount() .. ", showing " .. tostring(btn:IsShown()) ..
      (DB.off and ", turned off" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.AutoOpenerMinimapButton then return end
  local b = CreateFrame("Button", "AutoOpenerMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Misc_Shell_03")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 165)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.AUTOOPENER("off")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Auto Opener")
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
function AutoOpener_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

-- key binding (Key Bindings > AddOns): open the next item
BINDING_HEADER_AUTOOPENER = "Dalorrian's Auto Opener"
_G["BINDING_NAME_CLICK AutoOpenerButton:LeftButton"] = Tr("Open the next item")

SLASH_AUTOOPENER1 = "/opener"
SLASH_AUTOOPENER2 = "/autoopener"
SlashCmdList.AUTOOPENER = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if cmd == "off" then
    DB.off = not DB.off or nil; Update(); Soon(); Say(DB.off and "turned off" or "turned on")
  elseif cmd == "" then
    Say("opens your clams, bags of loot and crates by itself whenever you're out of combat" .. ".")
    P("  /opener help   (" .. "all settings, and how to report a bug" .. ")")
  elseif ns.OpenHelp then
    ns.OpenHelp()
  end
end
