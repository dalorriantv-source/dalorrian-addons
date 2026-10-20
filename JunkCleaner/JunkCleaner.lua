-- Dalorrian's Junk Cleaner (1.1.0): every gray item in your bags in one list, cheapest first.
-- Destroy Next Item throws away the top one, one click at a time, so you stop whenever you want.
-- Only gray items ever make the list. Selling is left to the game or your other addons. /junk opens it.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local ICON = "Interface\\Icons\\Spell_Fire_Fire"
local DEFAULTS = { summary = true, confirm = false }
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
-- (1.1.0) the game's gold, silver and copper coins, drawn right in the text
local COIN = { "Interface\\MoneyFrame\\UI-GoldIcon", "Interface\\MoneyFrame\\UI-SilverIcon", "Interface\\MoneyFrame\\UI-CopperIcon" }
local function CoinText(c)
  c = math.floor(c or 0)
  local g, sv, cp = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  local function Icon(i) return "|T" .. COIN[i] .. ":0:0:2:0|t" end
  local out = {}
  if g > 0 then out[#out + 1] = g .. Icon(1) end
  if g > 0 or sv > 0 then out[#out + 1] = sv .. Icon(2) end
  out[#out + 1] = cp .. Icon(3)
  return table.concat(out, " ")
end
local function IdFrom(text)
  if type(text) ~= "string" then return nil end
  return tonumber(text:match("item:(%d+)")) or tonumber(text:match("^%s*(%d+)%s*$"))
end

---------------------------------------------------------------------------
-- the list: gray items only, cheapest stack first; your Keep list never shows up here
---------------------------------------------------------------------------
local function Junk()
  local out, total = {}, 0
  for bag = 0, (NUM_BAG_SLOTS or 4) do
    for slot = 1, NumSlots(bag) do
      local id, count, quality, link = SlotInfo(bag, slot)
      if id and not DB.never[id] then
        local name, q, _, price = ItemFacts(id)
        if (quality or q) == 0 then
          local value = price * (count or 1)
          total = total + value
          out[#out + 1] = { bag = bag, slot = slot, id = id, count = count or 1, value = value,
            name = name or ("item " .. id), link = link or name or ("item " .. id) }
        end
      end
    end
  end
  table.sort(out, function(a, b)
    if a.value ~= b.value then return a.value < b.value end
    if a.name ~= b.name then return a.name < b.name end
    return a.bag * 100 + a.slot < b.bag * 100 + b.slot
  end)
  return out, total
end
ns.Junk = Junk

local win
local WW, ROWH = 360, 24
local Refresh

-- throws away one item, but only if that slot still holds it (the click is yours, the game insists on that)
local function Destroy(e)
  if not e then return false end
  local id = SlotInfo(e.bag, e.slot)
  if id ~= e.id then return false end
  if ClearCursor then pcall(ClearCursor) end
  local pick = Container.PickupContainerItem or PickupContainerItem
  if not (pick and pcall(pick, e.bag, e.slot)) then return false end
  if CursorHasItem and CursorHasItem() and DeleteCursorItem then
    DeleteCursorItem()
    if DB.summary then Say(string.format(Tr("threw away %s"), e.link .. (e.count > 1 and (" x" .. e.count) or ""))) end
    return true
  end
  if ClearCursor then pcall(ClearCursor) end
  return false
end

local function Button(parent, w, label, danger, onClick)
  local b = CF("Button", nil, parent)
  b:SetSize(w, 26)
  b.bg = b:CreateTexture(nil, "BACKGROUND"); b.bg:SetAllPoints(); b.bg:SetTexture(W)
  b.edge = b:CreateTexture(nil, "BORDER"); b.edge:SetPoint("TOPLEFT", -1, 1); b.edge:SetPoint("BOTTOMRIGHT", 1, -1); b.edge:SetTexture(W)
  b.edge:SetVertexColor(0, 0, 0, 1)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); b.label:SetPoint("CENTER"); b.label:SetText(label)
  b.Paint = function(self, hover)
    local off = not self:IsEnabled()
    if danger then
      self.bg:SetVertexColor(hover and 0.42 or 0.26, hover and 0.1 or 0.07, hover and 0.1 or 0.07, off and 0.4 or 1)
      self.label:SetTextColor(1, 0.4, 0.4, off and 0.4 or 1)
    else
      self.bg:SetVertexColor(hover and 0.22 or 0.14, hover and 0.23 or 0.15, hover and 0.28 or 0.19, off and 0.4 or 1)
      self.label:SetTextColor(0.9, 0.9, 0.95, off and 0.4 or 1)
    end
  end
  b:SetScript("OnEnter", function(self) self:Paint(true) end)
  b:SetScript("OnLeave", function(self) self:Paint(false) end)
  b:SetScript("OnClick", onClick)
  b:Paint(false)
  return b
end

local function Build()
  win = CF("Frame", "JunkCleanerFrame", UIParent, "BackdropTemplate")
  win:SetSize(WW, 430)
  win:SetPoint("CENTER", -200, 40)
  win:SetFrameStrata("DIALOG")
  win:SetClampedToScreen(true)
  win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  win:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
  win:SetBackdropColor(0.05, 0.05, 0.07, 0.96)
  win:SetBackdropBorderColor(0.25, 0.26, 0.3, 1)
  tinsert(UISpecialFrames, "JunkCleanerFrame")   -- Escape closes it

  win.title = win:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge"); win.title:SetPoint("TOPLEFT", 14, -12)
  local close = CF("Button", nil, win)
  close:SetSize(22, 22); close:SetPoint("TOPRIGHT", -8, -8)
  close.label = close:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge"); close.label:SetPoint("CENTER"); close.label:SetText("x")
  close:SetScript("OnClick", function() win:Hide() end)

  -- what it all comes to at a vendor
  win.worth = win:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  win.worth:SetPoint("TOP", 0, -44)
  local line = win:CreateTexture(nil, "ARTWORK"); line:SetTexture(W); line:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.35)
  line:SetPoint("TOPLEFT", 14, -64); line:SetPoint("TOPRIGHT", -14, -64); line:SetHeight(1)

  local sf = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 10, -70); sf:SetPoint("BOTTOMRIGHT", -30, 74)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(WW - 40, 10)
  sf:SetScrollChild(child)
  win.child, win.rows = child, {}

  win.empty = win:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  win.empty:SetPoint("TOP", 0, -170); win.empty:SetWidth(WW - 40)

  win.hint = win:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  win.hint:SetPoint("BOTTOM", 0, 48); win.hint:SetWidth(WW - 24)

  -- Destroy Next Item: the cheapest one goes. Confirm Each Destroy makes it two clicks
  win.destroy = Button(win, WW - 128, "Destroy Next Item", true, function(self)
    if win.kept then return end
    local list = Junk()
    local e = list[1]
    if not e then Refresh() return end
    if DB.confirm and not self.armed then
      self.armed = true; self.label:SetText(Tr("Click Again"))
      C_Timer.After(3, function() if self.armed then self.armed = nil; Refresh() end end)
      return
    end
    self.armed = nil
    Destroy(e)
    C_Timer.After(0.2, Refresh)
  end)
  win.destroy:SetPoint("BOTTOMLEFT", 14, 14)

  -- Locked: the items you told it to leave alone
  win.keptBtn = Button(win, 96, "Locked", false, function()
    win.kept = true; Refresh()
  end)
  win.keptBtn:SetPoint("BOTTOMRIGHT", -14, 14)
  -- on the Locked list, one big button takes you back
  win.back = Button(win, WW - 28, "Back To Junk Cleaner", false, function()
    win.kept = nil; Refresh()
  end)
  win.back:SetPoint("BOTTOM", 0, 14)
  win.back:Hide()
  win:SetScript("OnHide", function() win.kept = nil; if win.destroy then win.destroy.armed = nil end end)
  win:Hide()
end

local function Row(i)
  local r = win.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, win.child)
  r:SetSize(WW - 40, ROWH)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROWH)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r.hl = r:CreateTexture(nil, "BACKGROUND"); r.hl:SetAllPoints(); r.hl:SetTexture(W); r.hl:SetVertexColor(1, 1, 1, 0)
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(20, 20); r.icon:SetPoint("LEFT", 4, 0)
  r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")   -- plain: item names stay as the game names them
  r.name:SetPoint("LEFT", 30, 0); r.name:SetWidth(WW - 160); r.name:SetJustifyH("LEFT"); r.name:SetWordWrap(false)
  r.value = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  r.value:SetPoint("RIGHT", -6, 0); r.value:SetWidth(100); r.value:SetJustifyH("RIGHT")
  r:SetScript("OnEnter", function(self)
    self.hl:SetVertexColor(1, 1, 1, 0.06)
    local d = self.data
    if not d then return end
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if d.bag and GameTooltip.SetBagItem then pcall(GameTooltip.SetBagItem, GameTooltip, d.bag, d.slot)
    elseif d.id and GameTooltip.SetItemByID then pcall(GameTooltip.SetItemByID, GameTooltip, d.id) end
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Tr(win.kept and "Right-click to unlock it" or "Right-click to lock it"), 0.6, 0.6, 0.6)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function(self) self.hl:SetVertexColor(1, 1, 1, 0); GameTooltip:Hide() end)
  r:SetScript("OnClick", function(self, button)
    local d = self.data
    if button ~= "RightButton" or not d then return end
    if win.kept then
      DB.never[d.id] = nil; Say(string.format(Tr("%s is unlocked and back on the junk list"), d.link))
    else
      DB.never[d.id] = true; Say(string.format(Tr("%s is locked and off the junk list"), d.link))
    end
    Refresh()
  end)
  win.rows[i] = r
  return r
end

local function Kept()
  local out = {}
  local f = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  for id in pairs(DB.never or {}) do
    local name, link = Safe(f, id)
    out[#out + 1] = { id = id, name = name or ("item " .. id), link = link or name or ("item " .. id), count = 1, value = 0 }
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out
end

Refresh = function()
  if not (win and win:IsShown()) then return end
  local list, total
  if win.kept then list, total = Kept(), 0 else list, total = Junk() end
  if win.kept then
    win.title:SetText(Tr("Locked Items") .. " |cffffffff(" .. #list .. ")|r")
    win.worth:SetText(Tr("Never on the junk list"))
    win.empty:SetText(Tr("Nothing locked"))
    win.hint:SetText(Tr("Right-click an item to unlock it"))
    win.destroy:Hide(); win.keptBtn:Hide(); win.back:Show()
  else
    win.title:SetText(Tr("Junk Items") .. " |cffffffff(" .. #list .. ")|r")
    win.worth:SetText(CoinText(total))
    win.empty:SetText(Tr("No junk in your bags"))
    win.hint:SetText(Tr("Cheapest first. Right-click an item to lock it"))
    win.destroy:Show(); win.keptBtn:Show(); win.back:Hide()
    win.destroy:SetEnabled(#list > 0)
    if not win.destroy.armed then win.destroy.label:SetText(Tr("Destroy Next Item")) end
  end
  win.destroy:Paint(false); win.keptBtn:Paint(false); win.back:Paint(false)
  local icon = (C_Item and C_Item.GetItemIconByID) or GetItemIcon
  for i, d in ipairs(list) do
    local r = Row(i)
    r.data = d
    r.icon:SetTexture(Safe(icon, d.id) or "Interface\\Icons\\INV_Misc_QuestionMark")
    r.name:SetText(d.link .. (d.count > 1 and (" |cffffffffx" .. d.count .. "|r") or ""))
    r.value:SetText(win.kept and "" or (d.value > 0 and CoinText(d.value) or "|cff888888" .. Tr("no value") .. "|r"))
    -- the next one to go is marked
    if i == 1 and not win.kept then r.name:SetText("|cffff6666>|r " .. r.name:GetText()) end
    r:Show()
  end
  for i = #list + 1, #win.rows do win.rows[i]:Hide(); win.rows[i].data = nil end
  win.child:SetHeight(math.max(10, #list * ROWH))
  win.empty:SetShown(#list == 0)
end
ns.Refresh = Refresh

local function Toggle()
  if not DB then return end
  if not win then Build() end
  if win:IsShown() then win:Hide() else win:Show(); Refresh() end
end
ns.Toggle = Toggle

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local MinimapButton   -- further down
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "BAG_UPDATE_DELAYED", "GET_ITEM_INFO_RECEIVED" }) do pcall(ev.RegisterEvent, ev, e) end
local pending
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    JunkCleanerDB = JunkCleanerDB or {}
    DB = JunkCleanerDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    DB.never = DB.never or {}
    DB.always, DB.grays, DB.whiteBelow, DB.tips = nil, nil, nil, nil   -- (1.1.0) selling is gone
  elseif not DB then
    return
  elseif e == "PLAYER_LOGIN" then
    pcall(MinimapButton)
  elseif win and win:IsShown() and not pending then
    pending = true
    C_Timer.After(0.1, function() pending = nil; Refresh() end)   -- one refresh for a burst of bag changes
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
    { label = "Confirm Each Destroy", choices = OnOff,
      get = function() return DB.confirm and true or false end, set = function(v) DB.confirm = v end },
    { label = "Chat Message", choices = OnOff,
      get = function() return DB.summary and true or false end, set = function(v) DB.summary = v end },
    { label = "Junk Items", choices = { { "Open It", "open" } },
      get = function() return nil end, set = function() if not (win and win:IsShown()) then Toggle() end end },
  },
  notes = {
    { v = "1.1.0", "Junk Cleaner is now a Junk Items list: every gray item in your bags, cheapest first. Destroy Next Item throws away the top one, one click at a time, so you stop whenever you want",
      "Only gray items ever make the list. Right-click one to lock it, and Locked shows what you've locked",
      "Selling is gone: the game and your other addons already handle that" },
    { v = "1.0.0", "First release: your gray junk sells by itself when you open a vendor, with one line in chat saying what it came to. Green or better, quest items and crafting materials are never sold. Bags full? Make Room finds your least valuable gray item and asks before throwing it away" },
  },
  report = function()
    local n = 0
    for _ in pairs(DB.never or {}) do n = n + 1 end
    local list = Junk()
    return { "Junk " .. #list .. ", locked " .. n .. ", confirm " .. tostring(DB.confirm) }
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
    if button == "RightButton" then if ns.OpenHelp then ns.OpenHelp() end
    else ns.Toggle() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Junk Cleaner")
    Tip:AddLine("Left-click: Junk Items", 1, 1, 1)
    Tip:AddLine("Right-click: Settings & Help", 1, 1, 1)
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
function JunkCleaner_OnCompartmentClick() Toggle() end

SLASH_JUNKCLEANER1 = "/junk"
SLASH_JUNKCLEANER2 = "/junkcleaner"
SlashCmdList.JUNKCLEANER = function(msg)
  msg = msg or ""
  local cmd, rest = msg:match("^(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  local id = IdFrom(rest)
  local label = (rest ~= "" and rest) or ""
  if (cmd == "keep" or cmd == "lock") and id then
    DB.never[id] = true; Refresh()
    Say(string.format(Tr("%s is locked and off the junk list"), label))
  elseif (cmd == "unkeep" or cmd == "unlock") and id then
    DB.never[id] = nil; Refresh()
    Say(string.format(Tr("%s is unlocked and back on the junk list"), label))
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Toggle()
  end
end
