-- Dalorrian's Loot Rolls: clean Need / Greed / Pass bars you can put anywhere.
-- /rolls for options. /rolls test shows sample rolls without needing a drop.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 1, 0.82, 0 }
local WIDTH, HEIGHT, GAP = 320, 44, 6
local DEFAULTS = { scale = 1, up = false, winner = true, stay = 5 }

local P = ns.print or print   -- (1.1.0) Lang.lua: chat text in the player's language
local Tr = ns.Tr or function(x) return x end
local Tip = ns.Tip or GameTooltip
local function Say(msg) P("|cffffd100Loot Rolls:|r " .. msg) end

---------------------------------------------------------------------------
-- where the rolls show up: drag it while unlocked
---------------------------------------------------------------------------
local anchor = CreateFrame("Frame", "LootRollsAnchor", UIParent, "BackdropTemplate")
anchor:SetSize(WIDTH, HEIGHT)
anchor:SetMovable(true)
anchor:SetClampedToScreen(true)
anchor:SetFrameStrata("DIALOG")
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
anchor.label:SetText("Loot Rolls: Drag Me")
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
  -- (1.0.5) the default spot is Dalorrian's own: right of your character, a little below eye level
  elseif DB.side == "left" then anchor:SetPoint("CENTER", UIParent, "CENTER", -435, -33)
  else anchor:SetPoint("CENTER", UIParent, "CENTER", 435, -33) end
  anchor:SetScale(DB.scale or 1)
end
local function Lock(on)
  DB.unlocked = not on or nil
  anchor.box:SetShown(not on)
  anchor:EnableMouse(not on)
end

---------------------------------------------------------------------------
-- one roll bar: icon, name, Need / Greed / Disenchant / Pass, a timer draining along the bottom
---------------------------------------------------------------------------
local bars, shown = {}, {}
local CHOICES = {
  { key = "need", id = 1, tex = "Interface\\Buttons\\UI-GroupLoot-Dice", tip = NEED or "Need" },
  { key = "greed", id = 2, tex = "Interface\\Buttons\\UI-GroupLoot-Coin", tip = GREED or "Greed" },
  { key = "de", id = 3, tex = "Interface\\Buttons\\UI-GroupLoot-DE", tip = ROLL_DISENCHANT or "Disenchant" },
  { key = "pass", id = 0, tex = "Interface\\Buttons\\UI-GroupLoot-Pass", tip = PASS or "Pass" },
}

local function Layout()
  local dir = DB.up and 1 or -1
  for i, b in ipairs(shown) do
    b:ClearAllPoints()
    if DB.up then b:SetPoint("BOTTOM", anchor, "BOTTOM", 0, (i - 1) * (HEIGHT + GAP))
    else b:SetPoint("TOP", anchor, "TOP", 0, -(i - 1) * (HEIGHT + GAP)) end
  end
end

local function Close(b)
  b:Hide()
  b.rollID, b.test, b.result, b.picked, b.won = nil, nil, nil, nil, nil
  for i, s in ipairs(shown) do if s == b then table.remove(shown, i) break end end
  Layout()
end

---------------------------------------------------------------------------
-- (1.1.0) after the roll: the bar stays up a few seconds with who won and what they rolled
---------------------------------------------------------------------------
local function Picked(b, choice)
  b.picked = choice
  b:SetAlpha(0.65)
  b.bind:SetText(string.format(Tr("You picked %s"), choice.tip))
  b.bind:SetTextColor(0.75, 0.75, 0.78)
end
local function ShowResult(b)
  local t
  if b.won == "allpass" then t = Tr("Everyone passed")
  elseif b.won and b.won.me then t = "|cffffd100" .. Tr("You won!") .. "|r" .. (b.won.roll and ("  " .. b.won.kind .. " " .. b.won.roll) or "")
  elseif b.won then t = string.format(Tr("Won by %s"), b.won.who) .. (b.won.roll and (", " .. b.won.kind .. " " .. b.won.roll) or "")
  else t = Tr("Waiting for the result") .. "..." end
  b.bind:SetText(t)
  b.bind:SetTextColor(1, 1, 1)
end
local function Result(b)
  if b.result then return end
  if not DB.winner then Close(b) return end
  b.result, b.rollID = true, nil
  b.left = DB.stay or 5
  for _, btn in pairs(b.buttons) do btn:Hide() end
  b.timer:Hide()
  b:SetAlpha(1)
  ShowResult(b)
end

local function Choose(b, choice)
  if b.test then
    Say(string.format(Tr("test roll: you picked %s on %s"), choice.tip, b.itemName or "?"))
    if DB.winner then Picked(b, choice) else Close(b) end
    return
  elseif b.rollID then
    RollOnLoot(b.rollID, choice.id)
    -- Bind on Pickup asks the game's usual "are you sure" first: the bar waits until the game says the roll is in
    if b.bop and choice.id ~= 0 then b:SetAlpha(0.5) end
    if DB.winner then Picked(b, choice) return end
    if b.bop and choice.id ~= 0 then return end
  end
  Close(b)
end

local function NewBar()
  local b = CreateFrame("Frame", nil, anchor, "BackdropTemplate")
  b:SetSize(WIDTH, HEIGHT)
  b:SetFrameStrata("DIALOG")
  b:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 2 })
  b:SetBackdropColor(0.04, 0.04, 0.05, 0.92)
  b:SetBackdropBorderColor(0, 0, 0, 1)
  -- (1.0.1) shift-drag any roll bar to move them all
  b:EnableMouse(true)
  b:RegisterForDrag("LeftButton")
  b:SetScript("OnDragStart", function() if IsShiftKeyDown() or DB.unlocked then anchor:StartMoving() end end)
  b:SetScript("OnDragStop", function()
    anchor:StopMovingOrSizing()
    local p, _, rp, x, y = anchor:GetPoint(1)
    DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
  end)

  -- the item: hover for its tooltip, shift-click to link it, ctrl-click to try it on
  b.item = CreateFrame("Button", nil, b, "BackdropTemplate")
  b.item:SetSize(HEIGHT - 8, HEIGHT - 8)
  b.item:SetPoint("LEFT", 4, 0)
  b.item:SetBackdrop({ edgeFile = W, edgeSize = 1 })
  b.item.icon = b.item:CreateTexture(nil, "ARTWORK")
  b.item.icon:SetPoint("TOPLEFT", 1, -1); b.item.icon:SetPoint("BOTTOMRIGHT", -1, 1)
  b.item.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  b.item.count = b.item:CreateFontString(nil, "OVERLAY")
  b.item.count:SetFont(FONT, 11, "OUTLINE")
  b.item.count:SetPoint("BOTTOMRIGHT", -2, 2)
  b.item:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    if b.test then
      if b.itemLink then GameTooltip:SetHyperlink(b.itemLink) else GameTooltip:AddLine(b.itemName or "") end
    elseif b.rollID then GameTooltip:SetLootRollItem(b.rollID) end
    GameTooltip:Show()
  end)
  b.item:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b.item:SetScript("OnClick", function()
    local link = b.test and b.itemLink or (b.rollID and GetLootRollItemLink(b.rollID))
    if link and HandleModifiedItemClick then HandleModifiedItemClick(link) end
  end)

  b.name = b:CreateFontString(nil, "OVERLAY")
  b.name:SetFont(FONT, 12, "")
  b.name:SetShadowColor(0, 0, 0, 1); b.name:SetShadowOffset(1, -1)
  b.name:SetPoint("TOPLEFT", b.item, "TOPRIGHT", 8, -3)
  b.name:SetJustifyH("LEFT")
  b.name:SetWordWrap(false)
  b.bind = b:CreateFontString(nil, "OVERLAY")
  b.bind:SetFont(FONT, 10, "")
  b.bind:SetShadowOffset(1, -1)
  b.bind:SetPoint("TOPLEFT", b.name, "BOTTOMLEFT", 0, -3)

  -- the timer: a thin bar along the bottom in the item's color
  b.timer = CreateFrame("StatusBar", nil, b)
  b.timer:SetStatusBarTexture(W)
  b.timer:SetPoint("BOTTOMLEFT", b.item, "BOTTOMRIGHT", 8, 0)
  b.timer:SetPoint("BOTTOMRIGHT", b, "BOTTOMRIGHT", -6, 4)
  b.timer:SetHeight(3)
  b.timer.bg = b.timer:CreateTexture(nil, "BACKGROUND")
  b.timer.bg:SetAllPoints(); b.timer.bg:SetColorTexture(1, 1, 1, 0.08)

  -- the choices, right to left: Pass, Disenchant, Greed, Need
  b.buttons = {}
  local last
  for i = #CHOICES, 1, -1 do
    local c = CHOICES[i]
    local btn = CreateFrame("Button", nil, b)
    btn:SetSize(26, 26)
    if last then btn:SetPoint("RIGHT", last, "LEFT", -2, 0) else btn:SetPoint("RIGHT", b, "RIGHT", -6, 3) end
    btn:SetNormalTexture(c.tex .. "-Up")
    btn:SetHighlightTexture(c.tex .. "-Highlight", "ADD")
    btn:SetPushedTexture(c.tex .. "-Down")
    btn.choice = c
    btn:SetScript("OnClick", function(self) Choose(b, self.choice) end)
    btn:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(self.choice.tip)
      if self.reason then GameTooltip:AddLine(self.reason, 1, 0.3, 0.3, true) end
      GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    btn:SetMotionScriptsWhileDisabled(true)
    b.buttons[c.key] = btn
    last = btn
  end
  b.name:SetPoint("RIGHT", last, "LEFT", -6, 0)

  b:SetScript("OnUpdate", function(self, el)
    local left
    if self.result then
      self.left = (self.left or 0) - el
      if self.left <= 0 then Close(self) elseif self.left < 0.6 then self:SetAlpha(self.left / 0.6) end
      return
    end
    if self.test then
      self.left = (self.left or 0) - el
      left = self.left
    elseif self.rollID then
      left = (GetLootRollTimeLeft(self.rollID) or 0) / 1000
    end
    if not left then return end
    if left <= 0 then
      if self.test and DB.winner then   -- a sample result, so you can see how it looks
        self.won = (math.random(2) == 1) and { me = true, kind = NEED or "Need", roll = math.random(1, 100) }
          or { who = "Stabby", kind = GREED or "Greed", roll = math.random(1, 100) }
      end
      Result(self)
      return
    end
    self.timer:SetValue(left)
  end)
  return b
end

local function Free()
  for _, b in ipairs(bars) do if not b:IsShown() then return b end end
  local b = NewBar()
  bars[#bars + 1] = b
  return b
end

local function Enable(btn, on, reason)
  btn:SetEnabled(on)
  btn:SetAlpha(on and 1 or 0.35)
  local t = btn:GetNormalTexture()
  if t and t.SetDesaturated then t:SetDesaturated(not on) end
  btn.reason = (not on) and reason or nil
end

-- fill a bar and show it
local function Open(b, d)
  b.itemName, b.itemLink = d.name, d.link
  local c = ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[d.quality or 1]
  local r, g, bl = (c and c.r) or 1, (c and c.g) or 1, (c and c.b) or 1
  b.item.icon:SetTexture(d.texture or "Interface\\Icons\\INV_Misc_QuestionMark")
  b.item:SetBackdropBorderColor(r, g, bl, 1)
  b.item.count:SetText((d.count or 1) > 1 and d.count or "")
  b.name:SetText(d.name or "")
  b.name:SetTextColor(r, g, bl)
  b.timer:SetStatusBarColor(r, g, bl, 0.9)
  b.timer:SetMinMaxValues(0, d.time or 60)
  b.timer:SetValue(d.time or 60)
  if d.bop then
    b.bind:SetText(ITEM_BIND_ON_PICKUP or "Binds when picked up")
    b.bind:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    b:SetBackdropBorderColor(GOLD[1] * 0.75, GOLD[2] * 0.75, 0, 1)   -- gold edge for Bind on Pickup, like the game does
  else
    b.bind:SetText("")
    b:SetBackdropBorderColor(0, 0, 0, 1)
  end
  for _, btn in pairs(b.buttons) do btn:Show() end   -- (1.1.0) a bar that showed a result had them hidden
  Enable(b.buttons.need, d.canNeed, d.reasonNeed)
  Enable(b.buttons.greed, d.canGreed, d.reasonGreed)
  b.buttons.de:SetShown(d.canDE and true or false)
  if d.canDE then Enable(b.buttons.de, true) end
  -- line the buttons up from the right, skipping Disenchant when it's not offered
  local last
  for i = #CHOICES, 1, -1 do
    local btn = b.buttons[CHOICES[i].key]
    if btn:IsShown() then
      btn:ClearAllPoints()
      if last then btn:SetPoint("RIGHT", last, "LEFT", -2, 0) else btn:SetPoint("RIGHT", b, "RIGHT", -6, 3) end
      last = btn
    end
  end
  b.name:SetPoint("RIGHT", last, "LEFT", -6, 0)
  b.bop = d.bop
  b.timer:Show()
  b:SetAlpha(1)
  b:Show()
  table.insert(shown, b)
  Layout()
end

local function OpenRoll(rollID, rollTime)
  if not rollID then return end
  for _, b in ipairs(shown) do if b.rollID == rollID then return end end
  local texture, name, count, quality, bop, canNeed, canGreed, canDE, rN, rG = GetLootRollItemInfo(rollID)
  if not name then return end
  local b = Free()
  b.rollID, b.test = rollID, nil
  Open(b, {
    texture = texture, name = name, count = count, quality = quality, bop = bop,
    canNeed = canNeed, canGreed = canGreed, canDE = canDE,
    reasonNeed = rN and _G["LOOT_ROLL_INELIGIBLE_REASON" .. rN], reasonGreed = rG and _G["LOOT_ROLL_INELIGIBLE_REASON" .. rG],
    link = GetLootRollItemLink(rollID), time = (rollTime or GetLootRollTimeLeft(rollID) or 60000) / 1000,
  })
end

-- the game's own roll windows step aside for ours
local function HideBlizzard(rollID)
  for i = 1, (NUM_GROUP_LOOT_FRAMES or 4) do
    local f = _G["GroupLootFrame" .. i]
    if f and f:IsShown() and (not rollID or f.rollID == rollID) then
      if GroupLootContainer_RemoveFrame and GroupLootContainer then GroupLootContainer_RemoveFrame(GroupLootContainer, f)
      else f:Hide() end
    end
  end
end

-- reading the roll results from chat: who rolled what, who won
local function Pattern(fmt)
  if type(fmt) ~= "string" then return end
  local order, n = {}, 0
  local p = fmt:gsub("%%(%d?)%$?([sd])", function(pos, kind)
    n = n + 1
    order[n] = tonumber(pos) or n
    return "\001" .. kind
  end)
  p = p:gsub("([%(%)%.%[%]%*%+%-%?%^%$%%])", "%%%1")
  p = p:gsub("\001s", "(.+)"):gsub("\001d", "(%%d+)")
  return { pat = "^" .. p .. "$", order = order }
end
local function Match(pt, msg)
  if not pt then return end
  local caps = { msg:match(pt.pat) }
  if #caps == 0 then return end
  local out = {}
  for i, pos in ipairs(pt.order) do out[pos] = caps[i] end
  return out
end
local ROLLED = {
  { Pattern(LOOT_ROLL_ROLLED_NEED), NEED or "Need" },
  { Pattern(LOOT_ROLL_ROLLED_GREED), GREED or "Greed" },
  { Pattern(LOOT_ROLL_ROLLED_DE), ROLL_DISENCHANT or "Disenchant" },
}
local WON, YOUWON, ALLPASS = Pattern(LOOT_ROLL_WON), Pattern(LOOT_ROLL_YOU_WON), Pattern(LOOT_ROLL_ALL_PASSED)
local rolls = {}   -- item name -> player -> { kind, roll }
local function ItemName(s) return s and (s:match("%[(.-)%]") or s) end
local function BarFor(name)
  for _, b in ipairs(shown) do if not b.test and b.itemName == name and (b.result or b.picked or b.rollID) then return b end end
end
local function OnRollChat(msg)
  if not DB.winner or type(msg) ~= "string" then return end
  for _, r in ipairs(ROLLED) do
    local c = Match(r[1], msg)   -- "Need Roll - 87 for [item] by Stabby"
    if c then
      local item = ItemName(c[2])
      rolls[item] = rolls[item] or {}
      rolls[item][c[3]] = { kind = r[2], roll = tonumber(c[1]) }
      return
    end
  end
  local c = Match(YOUWON, msg)
  local who, me
  if c then who, me = UnitName("player"), true
  else
    c = Match(WON, msg)
    if c then who = c[1] end
  end
  if c then
    local item = ItemName(me and c[1] or c[2])
    local mine = rolls[item] and rolls[item][me and (YOU or "You") or who] or (rolls[item] and rolls[item][who])
    local b = BarFor(item)
    if b then
      b.won = { who = who, me = me, kind = mine and mine.kind, roll = mine and mine.roll }
      if b.result then ShowResult(b) end
    end
    rolls[item] = nil
    return
  end
  c = Match(ALLPASS, msg)
  if c then
    local b = BarFor(ItemName(c[1]))
    if b then b.won = "allpass"; if b.result then ShowResult(b) end end
  end
end

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local MinimapButton   -- (1.1.0) further down
local ev = CreateFrame("Frame")
ev:RegisterEvent("CHAT_MSG_LOOT")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("START_LOOT_ROLL")
ev:RegisterEvent("CANCEL_LOOT_ROLL")
ev:SetScript("OnEvent", function(_, e, a1, a2)
  if e == "ADDON_LOADED" and a1 == "LootRolls" then
    LootRollsDB = LootRollsDB or {}
    DB = LootRollsDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    if (DB.v or 0) < 2 then DB.up = false; DB.v = 2 end   -- (1.0.3) new rolls stack downward from the spot by default
    if DB.v < 3 then DB.point, DB.rel, DB.x, DB.y, DB.v = nil, nil, nil, nil, 3 end   -- (1.0.4) everyone starts beside the character
  elseif e == "PLAYER_LOGIN" then
    Place()
    Lock(not DB.unlocked)
    anchor.label:SetText(Tr("Loot Rolls") .. ": " .. Tr("Drag Me"))
    pcall(MinimapButton)
    -- after a /reload mid-roll, the game reopens its windows: ours take over from them
    if GroupLootFrame_OpenNewFrame then
      hooksecurefunc("GroupLootFrame_OpenNewFrame", function(id, t)
        if DB.off then return end
        OpenRoll(id, t); HideBlizzard(id)
      end)
    end
    if GetActiveLootRollIDs and not DB.off then
      for _, id in ipairs(GetActiveLootRollIDs() or {}) do OpenRoll(id) end
      HideBlizzard()
    end
  elseif not DB or DB.off then return
  elseif e == "START_LOOT_ROLL" then
    OpenRoll(a1, a2)
    C_Timer.After(0, function() HideBlizzard(a1) end)
  elseif e == "CANCEL_LOOT_ROLL" then
    for _, b in ipairs(shown) do if b.rollID == a1 then Result(b) break end end
  elseif e == "CHAT_MSG_LOOT" then
    OnRollChat(a1)
  end
end)

---------------------------------------------------------------------------
-- /rolls
---------------------------------------------------------------------------
local SAMPLES = {
  { id = 2589, quality = 1, count = 4, canNeed = true, canGreed = true, time = 20 },
  { id = 4306, quality = 2, canNeed = false, canGreed = true, reasonNeed = "You can't use this.", time = 30, canDE = true },
  { id = 19019, quality = 5, bop = true, canNeed = true, canGreed = true, time = 45 },
  { id = 14047, quality = 3, bop = true, canNeed = true, canGreed = true, time = 60, canDE = true },
}
local GetInfo = (C_Item and C_Item.GetItemInfo) or GetItemInfo
local function Test(n)
  n = math.max(1, math.min(4, n or 3))
  for i = 1, n do
    local s = SAMPLES[i]
    local function go()
      local name, link, quality, _, _, _, _, _, _, tex = GetInfo(s.id)
      local b = Free()
      b.rollID, b.test, b.left = nil, true, s.time
      Open(b, { texture = tex, name = name or ("Test Item " .. i), link = link, quality = quality or s.quality, count = s.count,
        bop = s.bop, canNeed = s.canNeed, canGreed = s.canGreed, canDE = s.canDE, reasonNeed = s.reasonNeed, time = s.time })
    end
    if Item and Item.CreateFromItemID then Item:CreateFromItemID(s.id):ContinueOnItemLoad(go) else go() end
  end
end

---------------------------------------------------------------------------
-- (1.1.0) Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Loot Rolls",
  tag = "Loot Rolls",
  settings = {
    { label = "Loot Rolls", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil end },
    { label = "Show Who Won", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.winner and true or false end, set = function(v) DB.winner = v end },
    { label = "Result Stays", choices = { { "3 Sec", 3 }, { "5 Sec", 5 }, { "8 Sec", 8 }, { "12 Sec", 12 } },
      get = function() return DB.stay or 5 end, set = function(v) DB.stay = v end },
    { label = "New Rolls Stack", choices = { { "Down", false }, { "Up", true } },
      get = function() return DB.up and true or false end, set = function(v) DB.up = v; Layout() end },
    { label = "Size", choices = { { "Small", 0.85 }, { "Normal", 1 }, { "Big", 1.2 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Place() end },
    { label = "Move It", choices = { { "Locked", "lock" }, { "Move It", "move" }, { "Reset", "reset" } },
      get = function() return DB.unlocked and "move" or "lock" end,
      set = function(v)
        if v == "move" then Lock(false)
        elseif v == "lock" then Lock(true)
        else DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; Place(); Lock(true) end
      end },
    { label = "Preview", choices = { { "Show Me", "test" } },
      get = function() return nil end, set = function() SlashCmdList.LOOTROLLS("test") end },
  },
  notes = {
    { v = "1.1.0", "After a roll the bar stays up a few seconds with who won and what they rolled. Pick how long under Result Stays", "A Settings & Help window, a minimap button and 10 languages" },
    { v = "1.0.5", "Shift-drag any roll bar to move them all" },
    { v = "1.0.0", "First release: clean Need, Greed and Pass bars you can put anywhere" },
  },
  report = function()
    return { "Winner " .. tostring(DB.winner) .. " " .. tostring(DB.stay) .. "s, up " .. tostring(DB.up) .. ", scale " .. tostring(DB.scale) ..
      (DB.off and ", turned off" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.LootRollsMinimapButton then return end
  local b = CreateFrame("Button", "LootRollsMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Buttons\\UI-GroupLoot-Dice-Up")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 45)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.LOOTROLLS("test")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Loot Rolls")
    Tip:AddLine("Left-click: Settings & Help", 1, 1, 1)
    Tip:AddLine("Right-click: show sample rolls", 1, 1, 1)
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
function LootRolls_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_LOOTROLLS1 = "/rolls"
SLASH_LOOTROLLS2 = "/lootrolls"
SlashCmdList.LOOTROLLS = function(msg)
  local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(%S*)")
  if cmd == "test" then
    Test(tonumber(arg) or 3)
    Say("sample rolls up. Shift-drag one to move them, /rolls clear to close.")
  elseif cmd == "clear" then
    for i = #shown, 1, -1 do if shown[i].test then Close(shown[i]) end end
  elseif cmd == "unlock" or cmd == "move" then
    Lock(false); Say("drag the gold box where you want your rolls. /rolls lock when you're done.")
  elseif cmd == "lock" then
    Lock(true); Say("locked.")
  elseif cmd == "left" or cmd == "right" then
    DB.side = cmd; DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; Place()
    Say("rolls now show on your " .. cmd .. ". Shift-drag a bar to fine tune it.")
  elseif cmd == "scale" and tonumber(arg) then
    DB.scale = math.max(0.5, math.min(2, tonumber(arg))); Place(); Say("size " .. DB.scale .. ".")
  elseif cmd == "down" then
    DB.up = not DB.up; Layout(); Say("new rolls stack " .. (DB.up and "up." or "down."))
  elseif cmd == "off" then
    DB.off = not DB.off or nil
    Say(DB.off and "off: the game's own roll windows are back after /reload." or "turned on")
  elseif cmd == "reset" then
    DB.point, DB.rel, DB.x, DB.y, DB.scale = nil, nil, nil, nil, 1; Place(); Say("back to the default spot and size.")
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("clean Need, Greed and Pass bars you can put anywhere.")
    P("  /rolls help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /rolls test   (" .. "show sample rolls, nothing is really rolled" .. ")")
    P("  /rolls left   /rolls right   (" .. "which side of you they show on" .. ")")
  end
end
