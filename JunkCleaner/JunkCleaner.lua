-- Dalorrian's Junk Cleaner: sells your gray junk the moment you open a vendor, with one clean line in chat.
-- Bags full? /junk drop finds your least valuable gray item and asks before throwing it away.
-- Never sells anything green or better, quest items or crafting materials. /junk for options.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local ICON = "Interface\\Icons\\INV_Misc_Bag_10"
local DEFAULTS = { grays = true, whiteBelow = 0, summary = true, tips = true }
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local Tip = ns.Tip or GameTooltip
local CF = ns.CreateFrame or CreateFrame   -- frames whose text is translated
local function Say(msg) P("|cffffd100Junk Cleaner:|r " .. msg) end

local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Safe(fn, ...)
  if type(fn) ~= "function" then return nil end
  local ok, a, b, c, d, e, f, g, h, i, j, k, l, m, n, o = pcall(fn, ...)
  if not ok or Secret(a) then return nil end
  return a, b, c, d, e, f, g, h, i, j, k, l, m, n, o
end

local Container = C_Container or {}
local function NumSlots(bag) return tonumber(Safe(Container.GetContainerNumSlots or GetContainerNumSlots, bag)) or 0 end
-- what sits in a bag slot: id, count, quality, link, bound
local function SlotInfo(bag, slot)
  if Container.GetContainerItemInfo then
    local i = Safe(Container.GetContainerItemInfo, bag, slot)
    if type(i) == "table" and i.itemID then return i.itemID, i.stackCount or 1, i.quality, i.hyperlink, i.isBound end
    return
  end
  if GetContainerItemInfo then
    local _, count, _, quality, _, _, link, _, _, id = Safe(GetContainerItemInfo, bag, slot)
    return id, count or 1, quality, link, nil
  end
end
-- name, quality, item level, sell price, class, bind type, crafting reagent, equip slot
local function ItemFacts(id)
  local f = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local name, _, quality, ilvl, _, _, _, _, equip, _, price, classID, _, bindType, _, _, reagent = Safe(f, id)
  return name, quality, tonumber(ilvl) or 0, tonumber(price) or 0, classID, bindType, reagent, equip
end

local function Money(c)
  c = math.floor(c or 0)
  local g, s, cp = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  local out = {}
  if g > 0 then out[#out + 1] = g .. "g" end
  if g > 0 or s > 0 then out[#out + 1] = s .. "s" end
  out[#out + 1] = cp .. "c"
  return table.concat(out, " ")
end
local function CoinText(c)
  if GetCoinTextureString then local ok, t = pcall(GetCoinTextureString, c); if ok and t then return t end end
  return Money(c)
end
local function IdFrom(text)
  if type(text) ~= "string" then return nil end
  return tonumber(text:match("item:(%d+)")) or tonumber(text:match("^%s*(%d+)%s*$"))
end

---------------------------------------------------------------------------
-- what counts as junk
---------------------------------------------------------------------------
local QUEST, TRADE, WEAPON, ARMOR = 12, 7, 2, 4
local NOT_GEAR = { INVTYPE_BODY = true, INVTYPE_TABARD = true, INVTYPE_BAG = true, INVTYPE_QUIVER = true }
-- returns true when this item should go, plus its price for one
local function IsJunk(id, quality, bound)
  if not id or DB.never[id] then return false end
  local name, q, ilvl, price, classID, _, reagent, equip = ItemFacts(id)
  if not name or price <= 0 then return false end   -- nothing to sell it for
  quality = quality or q
  if DB.always[id] then return true, price end
  if classID == QUEST or classID == TRADE or reagent then return false end   -- quest items and crafting materials stay
  if quality == 0 then return DB.grays and true or false, price end
  if quality == 1 and (DB.whiteBelow or 0) > 0 and bound and (classID == WEAPON or classID == ARMOR)
     and not NOT_GEAR[equip or ""] and ilvl > 0 and ilvl < DB.whiteBelow then
    return true, price
  end
  return false   -- green or better, and everything else, is never sold
end

---------------------------------------------------------------------------
-- selling at a vendor: a few items at a time, and only while the vendor window is open
---------------------------------------------------------------------------
local merchantOpen = false
local queue, sold = {}, { items = 0, money = 0 }
local busy = false
local BATCH, GAP = 10, 0.25

local function Finish()
  busy = false
  if sold.items > 0 and DB.summary then
    if sold.items == 1 then Say(string.format(Tr("sold 1 item for %s"), Money(sold.money)))
    else Say(string.format(Tr("sold %s items for %s"), sold.items, Money(sold.money))) end
  end
  sold.items, sold.money = 0, 0
end

local function Step()
  if not merchantOpen then wipe(queue); Finish() return end
  local n = 0
  while #queue > 0 and n < BATCH do
    local e = table.remove(queue, 1)
    local id, count = SlotInfo(e.bag, e.slot)
    if id == e.id and merchantOpen then   -- still the same item in that slot
      local use = Container.UseContainerItem or UseContainerItem
      if use and pcall(use, e.bag, e.slot) then
        sold.items = sold.items + (count or 1)
        sold.money = sold.money + e.price * (count or 1)
        n = n + 1
      end
    end
  end
  if #queue > 0 and merchantOpen then C_Timer.After(GAP, Step) else Finish() end
end

local function SellJunk()
  if not DB or DB.off or busy or not merchantOpen then return end
  wipe(queue)
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, NumSlots(bag) do
      local id, count, quality, _, bound = SlotInfo(bag, slot)
      if id then
        local junk, price = IsJunk(id, quality, bound)
        if junk then queue[#queue + 1] = { bag = bag, slot = slot, id = id, price = price } end
      end
    end
  end
  if #queue == 0 then return end
  busy = true
  Step()
end
ns.SellJunk = SellJunk

---------------------------------------------------------------------------
-- Make Room: your least valuable gray item, thrown away only after you click Delete
---------------------------------------------------------------------------
local function Cheapest()
  local best
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, NumSlots(bag) do
      local id, count, quality, link = SlotInfo(bag, slot)
      if id and not DB.never[id] then
        local name, q, _, price = ItemFacts(id)
        if (quality or q) == 0 then
          local value = price * (count or 1)
          if not best or value < best.value then
            best = { bag = bag, slot = slot, id = id, count = count or 1, value = value, link = link or name or ("item " .. id) }
          end
        end
      end
    end
  end
  return best
end
ns.Cheapest = Cheapest

local box
local function Box()
  if box then return box end
  box = CF("Frame", "JunkCleanerDropBox", UIParent, "BackdropTemplate")
  box:SetSize(340, 112)
  box:SetPoint("TOP", 0, -160)
  box:SetFrameStrata("DIALOG")
  box:SetClampedToScreen(true)
  box:EnableMouse(true)
  box:SetMovable(true); box:RegisterForDrag("LeftButton")
  box:SetScript("OnDragStart", box.StartMoving); box:SetScript("OnDragStop", box.StopMovingOrSizing)
  box:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
  box:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
  box:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.8)
  local t = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  t:SetPoint("TOP", 0, -12); t:SetText("Make Room")
  box.item = box:CreateFontString(nil, "OVERLAY", "GameFontHighlight")   -- plain: item names stay as the game names them
  box.item:SetPoint("TOP", 0, -36); box.item:SetWidth(310); box.item:SetWordWrap(false)
  box.value = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  box.value:SetPoint("TOP", 0, -56)
  local function Btn(label, x, danger, fn)
    local b = CF("Button", nil, box)
    b:SetSize(110, 22); b:SetPoint("BOTTOM", x, 10)
    b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetTexture(W)
    b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); b.label:SetPoint("CENTER"); b.label:SetText(label)
    local function Paint(hover)
      if danger then b.bg:SetVertexColor(hover and 0.4 or 0.24, hover and 0.1 or 0.08, hover and 0.1 or 0.08, 1); b.label:SetTextColor(1, 0.35, 0.35)
      else b.bg:SetVertexColor(hover and 0.22 or 0.14, hover and 0.23 or 0.15, hover and 0.28 or 0.19, 1); b.label:SetTextColor(0.85, 0.85, 0.9) end
    end
    b:SetScript("OnEnter", function() Paint(true) end)
    b:SetScript("OnLeave", function() Paint(false) end)
    b:SetScript("OnClick", fn)
    Paint(false)
    return b
  end
  -- the only way anything gets destroyed: you click Delete, and the slot still holds that item
  box.delete = Btn("Delete", -60, true, function()
    local e = box.target
    box:Hide()
    if not e then return end
    local id = SlotInfo(e.bag, e.slot)
    if id ~= e.id then Say("that item moved. Try /junk drop again") return end
    if ClearCursor then pcall(ClearCursor) end
    local pick = Container.PickupContainerItem or PickupContainerItem
    if not (pick and pcall(pick, e.bag, e.slot)) then return end
    if CursorHasItem and CursorHasItem() and DeleteCursorItem then
      DeleteCursorItem()
      Say(string.format(Tr("threw away %s"), e.link))
    elseif ClearCursor then
      pcall(ClearCursor)
    end
  end)
  Btn("Cancel", 60, false, function() box:Hide() end)
  box:Hide()
  return box
end

local function MakeRoom()
  if not DB then return end
  local e = Cheapest()
  if not e then Say("no gray items in your bags") return end
  local b = Box()
  b.target = e
  b.item:SetText(e.link .. (e.count > 1 and (" x" .. e.count) or ""))
  b.value:SetText(e.value > 0 and string.format(Tr("worth %s at a vendor"), CoinText(e.value)) or Tr("worth nothing at a vendor"))
  b:Show()
end
ns.MakeRoom = MakeRoom

---------------------------------------------------------------------------
-- item tooltips: what a gray item sells for
---------------------------------------------------------------------------
local function AddValue(tt, link)
  if not (DB and DB.tips and not DB.off) then return end
  local id = IdFrom(link)
  if not id then return end
  local _, quality, _, price = ItemFacts(id)
  if quality ~= 0 or price <= 0 then return end
  tt:AddLine("|cffffd100" .. Tr("Junk Cleaner") .. ":|r " .. Tr("sells for") .. " " .. CoinText(price) .. (DB.never[id] and ("  |cff999999(" .. Tr("kept") .. ")|r") or ""), 1, 1, 1)
  tt:Show()
end
local function HookTooltips()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt)
      if tt ~= GameTooltip then return end
      local ok, _, link = pcall(TooltipUtil.GetDisplayedItem, tt)
      if ok and link and not Secret(link) then pcall(AddValue, tt, link) end
    end)
  elseif GameTooltip and GameTooltip.HookScript then
    GameTooltip:HookScript("OnTooltipSetItem", function(self)
      local _, link = self:GetItem()
      if link then pcall(AddValue, self, link) end
    end)
  end
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local MinimapButton   -- further down
local MERCHANT = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Merchant
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "MERCHANT_SHOW", "MERCHANT_CLOSED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" }) do
  pcall(ev.RegisterEvent, ev, e)
end
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    JunkCleanerDB = JunkCleanerDB or {}
    DB = JunkCleanerDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    DB.never = DB.never or {}
    DB.always = DB.always or {}
  elseif not DB then
    return
  elseif e == "PLAYER_LOGIN" then
    pcall(HookTooltips)
    pcall(MinimapButton)
  elseif e == "MERCHANT_SHOW" or (e == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and MERCHANT and a1 == MERCHANT) then
    if merchantOpen then return end   -- both events can come for one vendor
    merchantOpen = true
    C_Timer.After(0.2, SellJunk)   -- a moment for the vendor window to settle
  elseif e == "MERCHANT_CLOSED" or (e == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and MERCHANT and a1 == MERCHANT) then
    merchantOpen = false
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local OnOff = { { "On", true }, { "Off", false } }
ns.HelpConfig = {
  title = "Junk Cleaner",
  tag = "Junk Cleaner",
  settings = {
    { label = "Junk Cleaner", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end, set = function(v) DB.off = (v == "off") or nil end },
    { label = "Sell Grays", choices = OnOff,
      get = function() return DB.grays and true or false end, set = function(v) DB.grays = v end },
    { label = "Sell White Gear Below", choices = { { "Off", 0 }, { "Level 10", 10 }, { "Level 20", 20 }, { "Level 30", 30 } },
      get = function() return DB.whiteBelow or 0 end, set = function(v) DB.whiteBelow = v end },
    { label = "Chat Summary", choices = OnOff,
      get = function() return DB.summary and true or false end, set = function(v) DB.summary = v end },
    { label = "Show Junk Value On Tooltips", choices = OnOff,
      get = function() return DB.tips and true or false end, set = function(v) DB.tips = v end },
    { label = "Make Room", choices = { { "Find It", "find" } },
      get = function() return nil end, set = function() MakeRoom() end },
  },
  notes = {
    { v = "1.0.0", "First release: your gray junk sells by itself when you open a vendor, with one line in chat saying what it came to. Green or better, quest items and crafting materials are never sold. Bags full? Make Room finds your least valuable gray item and asks before throwing it away" },
  },
  report = function()
    local n, a = 0, 0
    for _ in pairs(DB.never or {}) do n = n + 1 end
    for _ in pairs(DB.always or {}) do a = a + 1 end
    return { "Grays " .. tostring(DB.grays) .. ", white below " .. tostring(DB.whiteBelow) .. ", keep " .. n .. ", always sell " .. a .. (DB.off and ", turned off" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.JunkCleanerMinimapButton then return end
  local b = CreateFrame("Button", "JunkCleanerMinimapButton", Minimap)
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
    local a = math.rad(DB.minimapAngle or 235)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then MakeRoom()
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Junk Cleaner")
    Tip:AddLine("Left-click: Settings & Help", 1, 1, 1)
    Tip:AddLine("Right-click: Make Room", 1, 1, 1)
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
function JunkCleaner_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_JUNKCLEANER1 = "/junk"
SLASH_JUNKCLEANER2 = "/junkcleaner"
SlashCmdList.JUNKCLEANER = function(msg)
  msg = msg or ""
  local cmd, rest = msg:match("^(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  local id = IdFrom(rest)
  local label = (rest ~= "" and rest) or ""
  if cmd == "drop" or cmd == "room" then
    MakeRoom()
  elseif cmd == "keep" and id then
    DB.never[id] = true; DB.always[id] = nil
    Say(string.format(Tr("%s will never be sold"), label))
  elseif cmd == "unkeep" and id then
    DB.never[id] = nil
    Say(string.format(Tr("%s can be sold again"), label))
  elseif cmd == "sell" and id then
    DB.always[id] = true; DB.never[id] = nil
    Say(string.format(Tr("%s will always be sold"), label))
  elseif cmd == "unsell" and id then
    DB.always[id] = nil
    Say(string.format(Tr("%s is off the always-sell list"), label))
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("sells your gray junk when you open a vendor.")
    P("  /junk drop   (" .. "find your least valuable gray item to throw away" .. ")")
    P("  /junk keep <" .. "item" .. ">   /junk unkeep <" .. "item" .. ">   (" .. "never sell it" .. ")")
    P("  /junk sell <" .. "item" .. ">   /junk unsell <" .. "item" .. ">   (" .. "always sell it" .. ")")
    P("  /junk help   (" .. "all settings, and how to report a bug" .. ")")
  end
end
