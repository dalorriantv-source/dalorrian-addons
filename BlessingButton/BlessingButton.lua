-- Dalorrian's Blessing Button: one button that buffs your group with the right blessings.
--
-- How it works:
--  * Every paladin running this addon works out the same plan on their own, from who is in the group:
--    which paladin gives which blessing to whom. Nothing to set up and nothing to sync.
--  * The button shows only when someone is missing one of YOUR blessings (or it is running out).
--    Each press casts the next one. Bind a key to it and just keep pressing.
--  * Paladins using PallyPower: their assignments are read and planned around, and if a PallyPower
--    raid leader assigns you, you follow that instead.
--
-- WoW: Forever (1.60): blessings last an hour, one blessing per paladin on each player, Kings is
-- baseline, no Greater Blessings, Salvation and Light are gone. So the plan is per player, and with
-- three paladins everyone gets Kings, Might or Wisdom, whichever fit them.
--
-- Addons can't cast by themselves: every cast is one press of the button (or its key).
-- The plan and the button only change out of combat (the game locks both in combat).

local ADDON, ns = ...
local P = ns.print or print
local Tr = ns.Tr or function(x) return x end
local Tip = ns.Tip or GameTooltip
local function Say(msg) P("|cffffd100Blessing Button:|r " .. msg) end

local DB
local DEFAULTS = { show = "auto", refresh = 300, fury = true, aura = true, scale = 1 }
local PREFIX, PP_PREFIX = "DalBlessBtn", "PLPWR"
local GOLD = { 1, 0.82, 0 }
local FLAT = "Interface\\Buttons\\WHITE8X8"
local issecret = issecretvalue or function() return false end

local function Meta(field)
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  local ok, v = pcall(get, ADDON, field)
  return ok and v or nil
end

---------------------------------------------------------------------------
-- Spells
---------------------------------------------------------------------------
-- pp = PallyPower's number for the blessing, so its assignments can be read
local BLESS = {
  kings  = { id = 20217, pp = 3, level = 20 },
  might  = { id = 19740, pp = 2, level = 4 },
  wisdom = { id = 19742, pp = 1, level = 14 },
}
local FROM_PP = { [1] = "wisdom", [2] = "might", [3] = "kings" }
local FURY = 25780
local AURAS = { 465, 7294, 19746 }   -- Devotion, Retribution, Concentration: handed out in this order

local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then return C_Spell.GetSpellName(id) end
  return GetSpellInfo and (GetSpellInfo(id)) or nil
end
local function SpellIcon(id)
  if C_Spell and C_Spell.GetSpellTexture then return C_Spell.GetSpellTexture(id) end
  return GetSpellTexture and GetSpellTexture(id) or nil
end
-- known by name too: every rank has its own ID, and casting by name picks your highest rank
local function Knows(id)
  if IsPlayerSpell and IsPlayerSpell(id) then return true end
  local name = SpellName(id)
  if not name then return false end
  if C_Spell and C_Spell.GetSpellInfo then
    local ok, info = pcall(C_Spell.GetSpellInfo, name)
    if ok and info then return true end
  end
  return false
end

-- when my blessing (or any aura by name) on a unit runs out: a time, 0 for no end, nil when missing
local function AuraEnd(unit, id, mine)
  local name = SpellName(id)
  if not name then return nil end
  local filter = mine and "HELPFUL|PLAYER" or "HELPFUL"
  if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName then
    local ok, a = pcall(C_UnitAuras.GetAuraDataBySpellName, unit, name, filter)
    if not ok or not a then return nil end
    local e = a.expirationTime
    if e == nil or issecret(e) then return 0 end
    return e
  end
  if UnitBuff then
    for i = 1, 40 do
      local n, _, _, _, _, e, src = UnitBuff(unit, i)
      if not n then return nil end
      if n == name and (not mine or src == "player") then return e or 0 end
    end
  end
  return nil
end

---------------------------------------------------------------------------
-- Who wants what (the WoW: Forever meta, best first)
---------------------------------------------------------------------------
-- Kings: 10% to all stats for everyone. Might: melee attack power (it does not help ranged attacks).
-- Wisdom: mana back over time, for anyone who casts. Tanks put Kings first for the stamina.
local WANT = {
  tank   = { "kings", "might" },
  ptank  = { "kings", "wisdom", "might" },   -- paladin tank: mana too
  melee  = { "might", "kings" },
  ret    = { "might", "kings", "wisdom" },
  hunter = { "kings", "wisdom", "might" },
  caster = { "wisdom", "kings" },
  lock   = { "kings", "wisdom" },            -- Life Tap covers most of their mana
  hybrid = { "wisdom", "kings", "might" },   -- a shaman or paladin we can't see the talents of
}

local roster, byKey = {}, {}      -- this group, sorted by name
local hints = {}                  -- key -> role, told by that player's own copy of this addon
local friends = {}                -- key -> true: paladins running this addon
local pp = {}                     -- key -> { cls = { [classID] = skill }, one = { [targetKey] = skill } }
local feral = {}                  -- key -> "tank" or "melee", once a druid is seen in bear or cat form
local seen = {}                   -- key -> role read from their talents (inspect), shared with the other paladins
local over = {}                   -- pal -> { targetKey -> blessing or "none" }, changed by hand in the plan grid
local ME

local function Strip(name)
  if type(name) ~= "string" or issecret(name) or name == "" then return nil end
  return (name:match("^([^%-]+)")) or name
end
local function Key(unit)
  local ok, n = pcall(UnitName, unit)
  if not ok then return nil end
  return Strip(n)
end
-- any name (a chat sender, a PallyPower name with "First Last") to someone in the group
local function Match(name)
  name = Strip(name)
  if not name then return nil end
  name = name:gsub("_", " ")
  if byKey[name] then return name end
  local first = name:match("^(%S+)")
  local hit
  for k in pairs(byKey) do
    if k:match("^(%S+)") == first then
      if hit then return nil end   -- two with that first name: don't guess
      hit = k
    end
  end
  return hit
end

local CLASS_PP = { WARRIOR = 1, ROGUE = 2, PRIEST = 3, DRUID = 4, PALADIN = 5, HUNTER = 6, MAGE = 7, WARLOCK = 8, SHAMAN = 9 }

local function Role(m)
  if hints[m.key] then
    local h = hints[m.key]
    if h == "tank" then return m.class == "PALADIN" and "ptank" or "tank" end
    if WANT[h] then return h end
  end
  if m.tank then return m.class == "PALADIN" and "ptank" or "tank" end
  local s = seen[m.key]
  if s == "feral" then return feral[m.key] or "melee"
  elseif s == "tank" then return m.class == "PALADIN" and "ptank" or "tank"
  elseif s and WANT[s] then return s end
  local c = m.class
  if c == "WARRIOR" or c == "ROGUE" then return "melee"
  elseif c == "HUNTER" then return "hunter"
  elseif c == "MAGE" or c == "PRIEST" then return "caster"
  elseif c == "WARLOCK" then return "lock"
  elseif c == "DRUID" then return feral[m.key] or "caster"
  elseif c == "PALADIN" and m.fury then return "ptank" end
  return "hybrid"
end

-- the talent tree with the most points: yours, or the player you just inspected
local function BestTree(inspect)
  if not GetTalentTabInfo then return nil end
  local best, at = 0, nil
  for i = 1, 3 do
    local r = { pcall(GetTalentTabInfo, i, inspect) }
    if r[1] then
      local pts = (type(r[6]) == "number" and r[6]) or (type(r[4]) == "number" and r[4]) or 0   -- new and old API
      if pts > best then best, at = pts, i end
    end
  end
  return at
end
-- tree 1, 2, 3 -> what they want from us
local ROLE_BY_TREE = {
  PALADIN = { "hybrid", "tank", "ret" },     -- Holy, Protection, Retribution
  SHAMAN  = { "caster", "ret", "caster" },   -- Elemental, Enhancement (Might first), Restoration
  DRUID   = { "caster", "feral", "caster" }, -- Balance, Feral (bear or cat, told apart by form), Restoration
}

-- my own role, from where my talent points went (sent to the other paladins so they plan for it)
local function MyRole()
  local _, class = UnitClass("player")
  if class ~= "PALADIN" then return nil end
  if UnitGroupRolesAssigned and UnitGroupRolesAssigned("player") == "TANK" then return "tank" end
  return ROLE_BY_TREE.PALADIN[BestTree(false) or 0]
end

local function Units()
  local list = {}
  if IsInRaid() then
    for i = 1, GetNumGroupMembers() do list[#list + 1] = "raid" .. i end
  else
    list[1] = "player"
    for i = 1, GetNumSubgroupMembers() do list[#list + 1] = "party" .. i end
  end
  return list
end

local function ReadRoster()
  wipe(roster); wipe(byKey)
  for _, u in ipairs(Units()) do
    local k = UnitExists(u) and Key(u)
    if k and not byKey[k] then
      local _, class = UnitClass(u)
      local m = { key = k, unit = u, class = class, level = UnitLevel(u) or 0 }
      m.tank = (UnitGroupRolesAssigned and UnitGroupRolesAssigned(u) == "TANK") or
               (GetPartyAssignment and GetPartyAssignment("MAINTANK", u)) or false
      if class == "DRUID" and UnitPowerType then
        local pt = UnitPowerType(u)
        if pt == 1 then feral[k] = "tank" elseif pt == 3 then feral[k] = "melee" end
      elseif class == "PALADIN" then
        m.fury = AuraEnd(u, FURY) ~= nil
      end
      roster[#roster + 1] = m; byKey[k] = m
    end
  end
  table.sort(roster, function(a, b) return a.key < b.key end)
  if ME then hints[ME] = MyRole() end   -- the same role the others get from us
  for k in pairs(friends) do if not byKey[k] then friends[k] = nil end end
end

---------------------------------------------------------------------------
-- The plan: who gives what to whom
---------------------------------------------------------------------------
local mine = {}   -- targetKey -> blessing key, my part of the plan
local full = {}   -- pal -> { targetKey -> blessing }, every paladin's part (the grid shows it)
local planInfo = { pals = 0, fixed = 0, order = {} }

local function PPSkill(pal, m)
  local a = pp[pal]
  if not a then return nil end
  local s = (a.one and a.one[m.key]) or (a.cls and a.cls[CLASS_PP[m.class] or 0])
  if s and s > 0 then return s end
end
local function Fixed(pal)   -- a paladin who follows PallyPower assignments
  local a = pp[pal]
  if not a then return false end
  for _, s in pairs(a.cls or {}) do if s > 0 then return true end end
  for _, s in pairs(a.one or {}) do if s > 0 then return true end end
  return false
end
local function Can(pal, b)
  if pal == ME then return Knows(BLESS[b].id) end
  local m = byKey[pal]
  return m and m.level >= BLESS[b].level
end

local function Plan()
  wipe(mine); wipe(full); wipe(planInfo.order)
  if not ME or not byKey[ME] then return end
  local ours, fixed = {}, {}
  for _, m in ipairs(roster) do
    if m.class == "PALADIN" then
      if Fixed(m.key) then fixed[#fixed + 1] = m.key
      elseif m.key == ME or friends[m.key] then ours[#ours + 1] = m.key end
    end
  end
  planInfo.pals, planInfo.fixed = #ours, #fixed
  for _, k in ipairs(ours) do full[k] = {}; planInfo.order[#planInfo.order + 1] = k end
  for _, k in ipairs(fixed) do full[k] = {}; planInfo.order[#planInfo.order + 1] = k end
  for i, m in ipairs(roster) do
    local given, used = {}, {}
    -- first what's set: PallyPower assignments, then changes made by hand in the grid
    for _, f in ipairs(fixed) do
      used[f] = true
      local b = FROM_PP[PPSkill(f, m) or 0]
      if b then given[b] = true; full[f][m.key] = b end
    end
    for _, pal in ipairs(ours) do
      local o = over[pal] and over[pal][m.key]
      if o then
        used[pal] = true
        if o ~= "none" and not given[o] then given[o] = true; full[pal][m.key] = o end
      end
    end
    -- then the rest of what they want, best first; the paladin order turns with each player so the work is shared
    if #ours > 0 then
      for _, b in ipairs(WANT[Role(m)]) do
        if not given[b] then
          for j = 0, #ours - 1 do
            local pal = ours[((i - 1 + j) % #ours) + 1]
            if not used[pal] and Can(pal, b) then
              used[pal], given[b] = true, true
              full[pal][m.key] = b
              break
            end
          end
        end
      end
    end
  end
  for k, b in pairs(full[ME] or {}) do mine[k] = b end
end

---------------------------------------------------------------------------
-- What to cast next
---------------------------------------------------------------------------
local nextCast   -- { spell, unit, icon, who, key }
local waiting = { total = 0, far = 0 }

local function InRange(spell, unit)
  if UnitIsUnit(unit, "player") then return true end
  if C_Spell and C_Spell.IsSpellInRange then
    local ok, r = pcall(C_Spell.IsSpellInRange, spell, unit)
    if ok and r ~= nil and not issecret(r) then return r and true or false end
  elseif IsSpellInRange then
    return IsSpellInRange(spell, unit) == 1
  end
  return UnitInRange and (UnitInRange(unit)) or false
end
local function Ready(unit)
  return UnitExists(unit) and UnitIsConnected(unit) and not UnitIsDeadOrGhost(unit) and UnitIsVisible(unit)
end

local function Pick()
  nextCast = nil
  waiting.total, waiting.far = 0, 0
  local _, class = UnitClass("player")
  if class ~= "PALADIN" or not ME then return end
  if UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then return end
  local me = byKey[ME]
  -- Righteous Fury when you're the tank
  if DB.fury and me and Role(me) == "ptank" and Knows(FURY) and not AuraEnd("player", FURY) then
    nextCast = { spell = SpellName(FURY), unit = "player", icon = SpellIcon(FURY), who = UnitName("player") }
    waiting.total = 1
    return
  end
  -- an aura, only if you have none on
  if DB.aura then
    local on, known = false, {}
    for _, id in ipairs(AURAS) do
      if Knows(id) then known[#known + 1] = id end
      if AuraEnd("player", id) then on = true end
    end
    if not on and #known > 0 then
      local pals, at = {}, 1
      for _, m in ipairs(roster) do if m.class == "PALADIN" and (m.key == ME or friends[m.key]) then pals[#pals + 1] = m.key end end
      for i, k in ipairs(pals) do if k == ME then at = i end end
      local id = known[((at - 1) % #known) + 1]
      if me and Role(me) == "ptank" and Knows(AURAS[1]) then id = AURAS[1] end   -- tanks: Devotion
      nextCast = { spell = SpellName(id), unit = "player", icon = SpellIcon(id), who = UnitName("player") }
    end
  end
  -- blessings: the one missing or closest to running out, among those in range
  local now, best, bestLeft = GetTime(), nil, nil
  for _, m in ipairs(roster) do
    local b = mine[m.key]
    if b and Ready(m.unit) then
      local id = BLESS[b].id
      local e = AuraEnd(m.unit, id, true)
      local left = (e == nil and -1) or (e == 0 and math.huge) or (e - now)
      if left < (DB.refresh or 300) then
        local spell = SpellName(id)
        if InRange(spell, m.unit) then
          waiting.total = waiting.total + 1
          if not bestLeft or left < bestLeft then best, bestLeft = { spell = spell, unit = m.unit, icon = SpellIcon(id), who = m.key, b = b }, left end
        else
          waiting.far = waiting.far + 1
        end
      end
    end
  end
  if nextCast then waiting.total = waiting.total + 1
  else nextCast = best end
end

---------------------------------------------------------------------------
-- The button
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "BlessingButtonCast", UIParent, "SecureActionButtonTemplate,BackdropTemplate")
btn:SetSize(40, 40)
btn:SetFrameStrata("MEDIUM")
btn:SetClampedToScreen(true)
btn:SetMovable(true)
btn:RegisterForDrag("LeftButton")
-- a key bound to it fires on key down when the game is set to cast on key down
btn:RegisterForClicks((GetCVarBool and GetCVarBool("ActionButtonUseKeyDown")) and "AnyDown" or "AnyUp")
btn:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 2 })
btn:SetBackdropColor(0.04, 0.04, 0.05, 0.9)
btn:SetBackdropBorderColor(0, 0, 0, 1)
btn.icon = btn:CreateTexture(nil, "ARTWORK")
btn.icon:SetPoint("TOPLEFT", 2, -2); btn.icon:SetPoint("BOTTOMRIGHT", -2, 2)
btn.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
btn.count = btn:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
btn.count:SetPoint("BOTTOMRIGHT", -2, 3)
btn.who = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
btn.who:SetPoint("TOP", btn, "BOTTOM", 0, -2)
btn:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
btn:SetPushedTexture("Interface\\Buttons\\UI-Quickslot-Depress")
btn:Hide()

local function SetCast()
  if InCombatLockdown() then return end
  if nextCast then
    btn:SetAttribute("type", "spell")
    btn:SetAttribute("spell", nextCast.spell)
    btn:SetAttribute("unit", nextCast.unit)
  else
    btn:SetAttribute("type", nil)
  end
  btn:SetAttribute("type2", "settings")   -- right-click: not a cast (opens the settings below)
end

local function Paint()
  if InCombatLockdown() or not DB then return end
  local _, class = UnitClass("player")
  local want = class == "PALADIN" and DB.show ~= "off" and (DB.show == "always" or nextCast ~= nil)
  btn:SetShown(want and true or false)
  if not want then return end
  btn:SetScale(DB.scale or 1)
  if nextCast then
    btn.icon:SetTexture(nextCast.icon or 134400)
    btn.icon:SetDesaturated(false)
    btn.count:SetText(waiting.total > 1 and waiting.total or "")
    local m = byKey[nextCast.who]
    local cc = m and RAID_CLASS_COLORS and RAID_CLASS_COLORS[m.class]
    btn.who:SetText(nextCast.who and (nextCast.who:match("^(%S+)") or nextCast.who) or "")
    if cc then btn.who:SetTextColor(cc.r, cc.g, cc.b) else btn.who:SetTextColor(1, 1, 1) end
    btn:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
  else
    btn.icon:SetTexture(SpellIcon(BLESS.kings.id) or 134400)
    btn.icon:SetDesaturated(true)
    btn.count:SetText("")
    btn.who:SetText(waiting.far > 0 and (waiting.far .. " " .. Tr("out of range")) or "")
    btn.who:SetTextColor(0.6, 0.6, 0.6)
    btn:SetBackdropBorderColor(0, 0, 0, 1)
  end
end

local planDirty, scanDirty = true, true
local GridPaint, InspectNext   -- further down
local function Refresh()
  if InCombatLockdown() or not DB then return end
  local _, class = UnitClass("player")
  if class ~= "PALADIN" then btn:Hide(); planDirty, scanDirty = false, false; return end
  if planDirty then ReadRoster(); Plan(); planDirty = false end
  Pick(); SetCast(); Paint()
  scanDirty = false
  if InspectNext then InspectNext() end
  if GridPaint then GridPaint() end
end

-- each press: make sure it casts what's needed right now (only possible out of combat)
btn:SetScript("PreClick", function(_, button)
  if button ~= "RightButton" and not InCombatLockdown() then Pick(); SetCast() end
end)
btn:SetScript("PostClick", function(_, button)
  if button == "RightButton" then if ns.OpenHelp then ns.OpenHelp() end
  else scanDirty = true end
end)
btn:SetScript("OnDragStart", function(self) if IsShiftKeyDown() and not InCombatLockdown() then self:StartMoving() end end)
btn:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(1)
  DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
end)
btn:SetScript("OnEnter", function(self)
  Tip:SetOwner(self, "ANCHOR_TOP")
  Tip:AddLine("Blessing Button", GOLD[1], GOLD[2], GOLD[3])
  if nextCast then
    Tip:AddDoubleLine("Next", nextCast.spell .. "  >  " .. (nextCast.who or ""), 0.8, 0.8, 0.8, 1, 1, 1)
  else
    Tip:AddLine("Everyone has your blessings.", 0.6, 1, 0.6)
  end
  if waiting.total > 1 then Tip:AddDoubleLine("Waiting", tostring(waiting.total), 0.8, 0.8, 0.8, 1, 1, 1) end
  if waiting.far > 0 then Tip:AddDoubleLine("Out of range", tostring(waiting.far), 0.8, 0.8, 0.8, 1, 0.5, 0.5) end
  local n = { kings = 0, might = 0, wisdom = 0 }
  for _, b in pairs(mine) do n[b] = n[b] + 1 end
  Tip:AddLine(" ")
  Tip:AddLine("Your part of the plan", GOLD[1], GOLD[2], GOLD[3])
  for _, b in ipairs({ "kings", "might", "wisdom" }) do
    if n[b] > 0 then Tip:AddDoubleLine(SpellName(BLESS[b].id) or b, tostring(n[b]), 1, 1, 1, 1, 1, 1) end
  end
  if planInfo.pals > 1 then Tip:AddLine(string.format(Tr("Shared with %d paladins using Blessing Button"), planInfo.pals), 0.6, 0.6, 0.6) end
  if planInfo.fixed > 0 then Tip:AddLine(string.format(Tr("%d paladins follow PallyPower"), planInfo.fixed), 0.6, 0.6, 0.6) end
  Tip:AddLine(" ")
  Tip:AddLine("Click or use your key to cast. Bind it in Key Bindings, AddOns.", 0.6, 0.6, 0.6, true)
  Tip:AddLine("Right-click: settings. Shift-drag to move.", 0.6, 0.6, 0.6)
  Tip:AddLine("/bless plan: the whole plan", 0.6, 0.6, 0.6)
  Tip:Show()
end)
btn:SetScript("OnLeave", function() GameTooltip:Hide() end)

local function Place()
  if InCombatLockdown() then return end
  btn:ClearAllPoints()
  if DB.point then btn:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
  else btn:SetPoint("CENTER", UIParent, "CENTER", 0, -160) end
end

---------------------------------------------------------------------------
-- Talking to the other paladins (this addon and PallyPower)
---------------------------------------------------------------------------
local function Channel()
  if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
  if IsInRaid() then return "RAID" end
  if IsInGroup() then return "PARTY" end
end
local function Send(msg)
  local ch = Channel()
  local send = C_ChatInfo and C_ChatInfo.SendAddonMessage
  if ch and send and not InCombatLockdown() then pcall(send, PREFIX, msg, ch) end
end
local lastHello, helloSoon = 0, false
local function Hello(force)
  local ch = Channel()
  local _, class = UnitClass("player")
  if not ch or class ~= "PALADIN" or InCombatLockdown() then return end
  local since = GetTime() - lastHello
  if since < (force and 3 or 10) then
    -- just said hello: say it once more a moment later, for whoever joined since
    if force and not helloSoon and C_Timer then
      helloSoon = true
      C_Timer.After(3, function() helloSoon = false; Hello(true) end)
    end
    return
  end
  lastHello = GetTime()
  Send("H|" .. (Meta("Version") or "?") .. "|" .. (MyRole() or ""))
end

local function Trusted(sender, name)   -- PallyPower: only you, your leader or an assist can set your assignments
  if sender == name then return true end
  local m = byKey[sender]
  return m and (UnitIsGroupLeader(m.unit) or UnitIsGroupAssistant(m.unit)) and true or false
end
local function PPFor(key)
  pp[key] = pp[key] or { cls = {}, one = {} }
  return pp[key]
end
local function Digits(t, s)
  for i = 1, 9 do t[i] = tonumber(s:sub(i, i)) or 0 end
end

-- changes made by hand in the grid, sent in pieces small enough for one message each
local VALID = { kings = true, might = true, wisdom = true, none = true, auto = true }
local function SetOver(pal, tgt, b)
  if b == "auto" then
    if over[pal] then over[pal][tgt] = nil end
  else
    over[pal] = over[pal] or {}
    over[pal][tgt] = b
  end
  planDirty = true
end
local function SendOvers(list)   -- list of { pal, target, blessing }
  local part = {}
  local function Flush() if #part > 0 then Send("O|" .. table.concat(part, ";")); wipe(part) end end
  for _, e in ipairs(list) do
    part[#part + 1] = e[1] .. ">" .. e[2] .. ">" .. e[3]
    if #table.concat(part, ";") > 200 then local last = table.remove(part); Flush(); part[1] = last end
  end
  Flush()
end
local function ShareMyOvers()   -- for someone who just joined: the changes we're allowed to make
  local list = {}
  for pal, t in pairs(over) do
    if Trusted(ME, pal) then for tgt, b in pairs(t) do list[#list + 1] = { pal, tgt, b } end end
  end
  SendOvers(list)
end

local function OnPallyPower(msg, sender)
  local cmd = msg:match("^(%u+)")
  if cmd == "SELF" then
    local assign = msg:match("@([0-9n]*)")
    if assign then Digits(PPFor(sender).cls, assign) end
  elseif cmd == "ASSIGN" then
    local name, c, s = msg:match("^ASSIGN (.+) (%d+) (%d+)$")
    local k = Match(name)
    if k and Trusted(sender, k) then PPFor(k).cls[tonumber(c)] = tonumber(s) end
  elseif cmd == "PASSIGN" then
    local name, assign = msg:match("^PASSIGN (.+)@([0-9n]*)$")
    local k = Match(name)
    if k and Trusted(sender, k) then Digits(PPFor(k).cls, assign) end
  elseif cmd == "MASSIGN" then
    local name, s = msg:match("^MASSIGN (.+) (%d+)$")
    local k = Match(name)
    if k and Trusted(sender, k) then for i = 1, 9 do PPFor(k).cls[i] = tonumber(s) end end
  elseif cmd == "NASSIGN" then
    for pal, _, tgt, s in msg:sub(9):gmatch("([^@ ]+) ([^@ ]+) ([^@ ]+) ([^@ ]+)") do
      local k, t = Match(pal), Match(tgt)
      if k and t and Trusted(sender, k) then PPFor(k).one[t] = tonumber(s) end
    end
  elseif cmd == "CLEAR" then
    if pp[sender] then wipe(pp[sender].cls); wipe(pp[sender].one) end
  else
    return
  end
  planDirty = true
end

local function OnMessage(prefix, msg, sender)
  if type(msg) ~= "string" or issecret(msg) then return end
  local k = Match(sender)
  if not k then ReadRoster(); k = Match(sender) end   -- someone who just joined
  if not k or k == ME then return end
  if prefix == PREFIX then
    local kind, a, b = strsplit("|", msg)
    if kind == "H" then   -- hello: a paladin running this addon, and their role
      if not friends[k] then Hello(true); ShareMyOvers() end   -- someone new: tell them about us too
      friends[k] = true
      hints[k] = (b ~= "" and b) or nil
      planDirty = true
    elseif kind == "R" then   -- someone's role, read from their talents
      local t = Match(a)
      if t and (WANT[b] or b == "feral" or b == "tank") and seen[t] ~= b then seen[t] = b; planDirty = true end
    elseif kind == "O" then   -- changes made by hand in the grid
      for pal, tgt, bl in (a or ""):gmatch("([^>;]+)>([^>;]+)>([^>;]+)") do
        local pk, tk = Match(pal), Match(tgt)
        if pk and tk and VALID[bl] and Trusted(k, pk) then SetOver(pk, tk, bl) end
      end
    elseif kind == "C" then   -- back to automatic
      for pal in pairs(over) do if Trusted(k, pal) then over[pal] = nil end end
      planDirty = true
    end
  elseif prefix == PP_PREFIX then
    OnPallyPower(msg, k)
  end
end


---------------------------------------------------------------------------
-- Reading talents: shamans, druids and paladins who don't run this addon get inspected
-- (one at a time, out of combat, when close), and what's learned is shared with the other paladins
---------------------------------------------------------------------------
local tried, pending = {}, nil
InspectNext = function()
  if InCombatLockdown() or not (NotifyInspect and CanInspect) then return end
  local now = GetTime()
  if pending and now - pending.t < 4 then return end
  pending = nil
  if InspectFrame and InspectFrame:IsShown() then return end   -- you're looking at someone yourself
  for _, m in ipairs(roster) do
    if ROLE_BY_TREE[m.class] and m.key ~= ME and not hints[m.key] and not seen[m.key]
       and now - (tried[m.key] or -999) > 60 and UnitIsConnected(m.unit) then
      local ok, can = pcall(CanInspect, m.unit)
      local okd, near = pcall(CheckInteractDistance, m.unit, 1)
      if ok and can and okd and near then
        tried[m.key] = now
        pending = { key = m.key, guid = UnitGUID(m.unit), t = now }
        pcall(NotifyInspect, m.unit)
        return
      end
    end
  end
end
local function OnInspect(guid)
  if not pending or guid ~= pending.guid then return end
  local m = byKey[pending.key]
  pending = nil
  if not m then return end
  local tree = BestTree(true)
  local role = tree and ROLE_BY_TREE[m.class] and ROLE_BY_TREE[m.class][tree]
  if role then
    seen[m.key] = role; planDirty = true
    Send("R|" .. m.key .. "|" .. role)
  end
end

---------------------------------------------------------------------------
-- The plan grid: every player, and what each paladin gives them. Click a square to change it.
---------------------------------------------------------------------------
local grid
local CreateFrameT = ns.CreateFrame or CreateFrame   -- Lang.lua: text on these frames is translated
local ROLE_LABEL = { tank = "Tank", ptank = "Tank", melee = "Melee", ret = "Melee, mana", hunter = "Hunter",
  caster = "Caster", lock = "Caster", hybrid = "Healer" }
local CYCLE = { kings = "might", might = "wisdom", wisdom = "none", none = "kings" }
local ROW_H, NAME_W, ROLE_W, CELL_W, MAX_ROWS = 22, 130, 90, 58, 15

local function CanChange(pal)
  if pal == ME then return true end
  return IsInGroup() and (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and true or false
end
local function ChangeCell(pal, tgt, button)
  if Fixed(pal) then Say("that paladin follows PallyPower. Change it there."); return end
  if not CanChange(pal) then Say("only the leader or an assist can change another paladin's blessings."); return end
  local b = button == "RightButton" and "auto" or CYCLE[(full[pal] and full[pal][tgt]) or "none"]
  SetOver(pal, tgt, b)
  SendOvers({ { pal, tgt, b } })
  Refresh()
end
local function First(k) return k and (k:match("^(%S+)") or k) or "" end
local function ClassColor(class)
  local c = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
  if c then return c.r, c.g, c.b end
  return 1, 1, 1
end

local function Cell(row, j)
  local c = CreateFrameT("Button", nil, row, "BackdropTemplate")
  c:SetSize(CELL_W - 6, ROW_H - 2)
  c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  c:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })
  c.icon = c:CreateTexture(nil, "ARTWORK")
  c.icon:SetSize(ROW_H - 6, ROW_H - 6); c.icon:SetPoint("CENTER")
  c.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
  c.dash = c:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  c.dash:SetPoint("CENTER"); c.dash:SetText("-")
  c:SetScript("OnClick", function(self, button) ChangeCell(self.pal, self.tgt, button) end)
  c:SetScript("OnEnter", function(self)
    local b = full[self.pal] and full[self.pal][self.tgt]
    Tip:SetOwner(self, "ANCHOR_RIGHT")
    Tip:AddLine(First(self.pal) .. "  >  " .. First(self.tgt), GOLD[1], GOLD[2], GOLD[3])
    Tip:AddLine(b and SpellName(BLESS[b].id) or "Nothing", 1, 1, 1)
    if over[self.pal] and over[self.pal][self.tgt] then Tip:AddLine("Set by hand", 1, 0.82, 0) end
    if Fixed(self.pal) then Tip:AddLine("From PallyPower", 0.6, 0.6, 0.6)
    else
      Tip:AddLine("Left-click: change it", 0.6, 0.6, 0.6)
      Tip:AddLine("Right-click: back to automatic", 0.6, 0.6, 0.6)
    end
    Tip:Show()
  end)
  c:SetScript("OnLeave", function() GameTooltip:Hide() end)
  c:SetPoint("LEFT", row, "LEFT", NAME_W + ROLE_W + (j - 1) * CELL_W, 0)
  return c
end

local function BuildGrid()
  grid = CreateFrameT("Frame", "BlessingButtonGrid", UIParent, "BackdropTemplate")
  grid:SetFrameStrata("DIALOG"); grid:SetToplevel(true)
  grid:SetPoint("CENTER"); grid:SetClampedToScreen(true)
  grid:SetMovable(true); grid:EnableMouse(true); grid:RegisterForDrag("LeftButton")
  grid:SetScript("OnDragStart", grid.StartMoving); grid:SetScript("OnDragStop", grid.StopMovingOrSizing)
  grid:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })
  grid:SetBackdropColor(0.06, 0.07, 0.09, 0.97)
  grid:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.6)
  tinsert(UISpecialFrames, "BlessingButtonGrid")   -- Esc closes it
  local head = grid:CreateTexture(nil, "ARTWORK")
  head:SetTexture(FLAT); head:SetVertexColor(0.10, 0.11, 0.14)
  head:SetPoint("TOPLEFT", 1, -1); head:SetPoint("TOPRIGHT", -1, -1); head:SetHeight(34)
  grid.title = grid:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  grid.title:SetPoint("TOPLEFT", 14, -10); grid.title:SetText("Blessing Plan")
  local close = CreateFrameT("Button", nil, grid)
  close:SetSize(26, 26); close:SetPoint("TOPRIGHT", -5, -5)
  close.label = close:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
  close.label:SetPoint("CENTER"); close.label:SetText("x"); close.label:SetTextColor(0.6, 0.6, 0.65)
  close:SetScript("OnClick", function() grid:Hide() end)
  -- column titles
  local function Head(text, x)
    local fs = grid:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetPoint("TOPLEFT", 16 + x, -46); fs:SetText(text)
    return fs
  end
  Head("Player", 0); Head("Wants", NAME_W)
  grid.heads = {}
  grid.names = CreateFrame("Frame", nil, grid)   -- a plain frame: paladin names are never translated
  grid.names:SetAllPoints()
  -- rows
  local sf = CreateFrame("ScrollFrame", nil, grid, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 16, -64)
  grid.sf = sf
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(10, 10)
  sf:SetScrollChild(child)
  grid.child, grid.rows = child, {}
  grid.foot = grid:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  grid.foot:SetJustifyH("LEFT")
  grid.foot:SetText("Left-click a square to change it, right-click for automatic. The leader and assists can change anyone's.")
  local reset = CreateFrameT("Button", nil, grid, "BackdropTemplate")
  reset:SetSize(130, 22)
  reset:SetBackdrop({ bgFile = FLAT }); reset:SetBackdropColor(0.14, 0.15, 0.19, 1)
  reset.label = reset:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  reset.label:SetPoint("CENTER"); reset.label:SetText("All Automatic")
  reset:SetScript("OnEnter", function(self) self:SetBackdropColor(0.22, 0.23, 0.28, 1) end)
  reset:SetScript("OnLeave", function(self) self:SetBackdropColor(0.14, 0.15, 0.19, 1) end)
  reset:SetScript("OnClick", function()
    for pal in pairs(over) do if CanChange(pal) then over[pal] = nil end end
    Send("C"); planDirty = true; Refresh()
  end)
  grid.reset = reset
  grid:Hide()
end

GridPaint = function()
  if not (grid and grid:IsShown()) then return end
  local pals = planInfo.order
  local w = 16 + NAME_W + ROLE_W + math.max(#pals, 1) * CELL_W + 40
  local shown = math.min(#roster, MAX_ROWS)
  grid:SetSize(math.max(w, 460), 64 + math.max(shown, 1) * ROW_H + 64)
  grid.sf:SetSize(w - 40, math.max(shown, 1) * ROW_H)
  grid.child:SetSize(w - 40, #roster * ROW_H)
  grid.foot:SetPoint("BOTTOMLEFT", 16, 40); grid.foot:SetWidth(math.max(w, 460) - 32)
  grid.reset:SetPoint("BOTTOMLEFT", 16, 10)
  for j, pal in ipairs(pals) do
    local h = grid.heads[j]
    if not h then
      h = grid.names:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
      h:SetWidth(CELL_W - 4); h:SetJustifyH("CENTER")
      grid.heads[j] = h
    end
    h:ClearAllPoints(); h:SetPoint("TOPLEFT", 16 + NAME_W + ROLE_W + (j - 1) * CELL_W - 2, -46)
    h:SetText(First(pal) .. (Fixed(pal) and "*" or ""))
    h:SetTextColor(pal == ME and GOLD[1] or 1, pal == ME and GOLD[2] or 1, pal == ME and GOLD[3] or 1)
    h:Show()
  end
  for j = #pals + 1, #grid.heads do grid.heads[j]:Hide() end
  for i, m in ipairs(roster) do
    local row = grid.rows[i]
    if not row then
      row = CreateFrame("Frame", nil, grid.child)
      row:SetSize(10, ROW_H)
      row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
      row.bg = row:CreateTexture(nil, "BACKGROUND"); row.bg:SetAllPoints(); row.bg:SetTexture(FLAT)
      row.bg:SetVertexColor(1, 1, 1, (i % 2 == 0) and 0.03 or 0)
      row.name = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      row.name:SetPoint("LEFT", 4, 0); row.name:SetWidth(NAME_W - 8); row.name:SetJustifyH("LEFT")
      row.role = ns.TrText and ns.TrText(row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")) or row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
      row.role:SetPoint("LEFT", NAME_W, 0); row.role:SetWidth(ROLE_W - 6); row.role:SetJustifyH("LEFT")
      row.cells = {}
      grid.rows[i] = row
    end
    row:SetWidth(w - 40)
    row.name:SetText(First(m.key)); row.name:SetTextColor(ClassColor(m.class))
    row.role:SetText(ROLE_LABEL[Role(m)] or "")
    for j, pal in ipairs(pals) do
      local c = row.cells[j] or Cell(row, j)
      row.cells[j] = c
      c.pal, c.tgt = pal, m.key
      local b = full[pal] and full[pal][m.key]
      if b then
        c.icon:SetTexture(SpellIcon(BLESS[b].id) or 134400); c.icon:Show(); c.dash:Hide()
        c.icon:SetAlpha(AuraEnd(m.unit, BLESS[b].id) and 1 or 0.4)   -- faded: they don't have it on yet
      else
        c.icon:Hide(); c.dash:Show()
      end
      local hand = over[pal] and over[pal][m.key]
      c:SetBackdropColor(0.10, 0.11, 0.14, 1)
      if hand then c:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1) else c:SetBackdropBorderColor(0, 0, 0, 1) end
      c:Show()
    end
    for j = #pals + 1, #row.cells do row.cells[j]:Hide() end
    row:Show()
  end
  for i = #roster + 1, #grid.rows do grid.rows[i]:Hide() end
end

function ns.ToggleGrid()
  local _, class = UnitClass("player")
  if class ~= "PALADIN" then Say("this addon is for paladins."); return end
  if not grid then BuildGrid() end
  if grid:IsShown() then grid:Hide(); return end
  grid:Show()
  planDirty = true
  if InCombatLockdown() then GridPaint() else Refresh() end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local MinimapButton
local ev = CreateFrame("Frame")
local function Reg(e) pcall(ev.RegisterEvent, ev, e) end
for _, e in ipairs({ "ADDON_LOADED", "PLAYER_ENTERING_WORLD", "GROUP_ROSTER_UPDATE", "PLAYER_REGEN_ENABLED",
  "UNIT_AURA", "UNIT_SPELLCAST_SUCCEEDED", "SPELLS_CHANGED", "PLAYER_LEVEL_UP", "PLAYER_ROLES_ASSIGNED",
  "CHAT_MSG_ADDON", "PLAYER_TALENT_UPDATE", "CHARACTER_POINTS_CHANGED", "UNIT_DISPLAYPOWER", "PLAYER_ALIVE", "PLAYER_UNGHOST",
  "INSPECT_READY" }) do Reg(e) end

ev:SetScript("OnEvent", function(_, e, a1, a2, a3, a4)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    BlessingButtonDB = BlessingButtonDB or {}
    DB = BlessingButtonDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    _G["BINDING_NAME_CLICK BlessingButtonCast:LeftButton"] = Tr("Cast the next blessing")
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
      C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
      C_ChatInfo.RegisterAddonMessagePrefix(PP_PREFIX)
    end
  elseif not DB then
    return
  elseif e == "PLAYER_ENTERING_WORLD" then
    ME = Key("player")
    Place(); pcall(MinimapButton)
    planDirty = true; Hello(true)
  elseif e == "CHAT_MSG_ADDON" then
    if a1 == PREFIX or a1 == PP_PREFIX then OnMessage(a1, a2, a4) end
  elseif e == "UNIT_AURA" then
    if a1 == "player" or (a1 and (a1:find("^raid%d") or a1:find("^party%d"))) then scanDirty = true end
  elseif e == "UNIT_SPELLCAST_SUCCEEDED" then
    if a1 == "player" then scanDirty = true end
  elseif e == "UNIT_DISPLAYPOWER" then
    if a1 and a1 ~= "player" and UnitClass(a1) and select(2, UnitClass(a1)) == "DRUID" then planDirty = true end
  elseif e == "INSPECT_READY" then
    OnInspect(a1)
  elseif e == "GROUP_ROSTER_UPDATE" or e == "PLAYER_ROLES_ASSIGNED" then
    if not IsInGroup() then wipe(over); wipe(seen); wipe(pp) end   -- left the group: start fresh next time
    planDirty = true; Hello()
  elseif e == "PLAYER_TALENT_UPDATE" or e == "CHARACTER_POINTS_CHANGED" then
    planDirty = true; Hello(true)
  else
    planDirty = true
  end
end)

-- light upkeep: half a second after a change, otherwise every 2 seconds (people walk in and out of range)
local tick = 0
ev:SetScript("OnUpdate", function(_, dt)
  tick = tick + dt
  if (planDirty or scanDirty) and tick > 0.5 or tick > 2 then
    tick = 0
    Refresh()
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons), minimap button, slash command
---------------------------------------------------------------------------
BINDING_HEADER_BLESSINGBUTTON = "Dalorrian's Blessing Button"
_G["BINDING_NAME_CLICK BlessingButtonCast:LeftButton"] = "Cast the next blessing"

ns.HelpConfig = {
  title = "Blessing Button",
  tag = "Blessing Button",
  settings = {
    { label = "Whole Plan", choices = { { "Open", "open" } },
      get = function() return nil end, set = function() ns.ToggleGrid() end },
    { label = "Button", choices = { { "When Needed", "auto" }, { "Always", "always" }, { "Hidden", "off" } },
      get = function() return DB.show end, set = function(v) DB.show = v; Refresh() end },
    { label = "Recast", choices = { { "1 Min Left", 60 }, { "5 Min Left", 300 }, { "10 Min Left", 600 } },
      get = function() return DB.refresh end, set = function(v) DB.refresh = v; Refresh() end },
    { label = "Righteous Fury", choices = { { "When Tanking", true }, { "Off", false } },
      get = function() return DB.fury and true or false end, set = function(v) DB.fury = v; Refresh() end },
    { label = "Aura Reminder", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.aura and true or false end, set = function(v) DB.aura = v; Refresh() end },
    { label = "Size", choices = { { "Small", 0.8 }, { "Normal", 1 }, { "Big", 1.3 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Refresh() end },
    { label = "Spot", choices = { { "Reset", "reset" } },
      get = function() return DB.point and "moved" or "reset" end,
      set = function() DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; Place() end },
  },
  notes = {
    { v = "1.0.0", "First release: one button that buffs your group with the right blessings for WoW: Forever",
      "Paladins running it share the work out by themselves, with nothing to set up",
      "Shows only when someone needs one of your blessings. Bind a key in Key Bindings, AddOns",
      "Works next to PallyPower: its assignments are read and planned around",
      "Talents are read by inspecting, so shamans, druids and paladins get what fits their spec",
      "A plan grid (right-click the minimap button): see who gives what, and click a square to change it" },
  },
  report = function()
    local n = 0
    for _ in pairs(mine) do n = n + 1 end
    return { "Group " .. #roster .. ", paladins with this addon " .. planInfo.pals .. ", PallyPower " .. planInfo.fixed ..
      ", my blessings " .. n .. ", show " .. tostring(DB.show) .. ", recast " .. tostring(DB.refresh) ..
      ", role " .. tostring(MyRole()) }
  end,
}

local function PrintPlan()
  local _, class = UnitClass("player")
  if class ~= "PALADIN" then Say("this addon is for paladins.") return end
  if InCombatLockdown() then Say("try again out of combat.") return end
  planDirty = true; Refresh()
  local by = {}
  for _, m in ipairs(roster) do
    local b = mine[m.key]
    if b then by[b] = by[b] or {}; table.insert(by[b], m.key:match("^(%S+)") or m.key) end
  end
  Say(string.format(Tr("your blessings (%d paladins sharing):"), math.max(1, planInfo.pals)))
  local any
  for _, b in ipairs({ "kings", "might", "wisdom" }) do
    if by[b] then any = true; P("  " .. (SpellName(BLESS[b].id) or b) .. ": " .. table.concat(by[b], ", ")) end
  end
  if not any then P("  " .. Tr("nothing to give right now.")) end
end

MinimapButton = function()
  if not Minimap or _G.BlessingButtonMinimapButton then return end
  local b = CreateFrame("Button", "BlessingButtonMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture(SpellIcon(BLESS.kings.id) or "Interface\\Icons\\Spell_Magic_MageArmor")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 200)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then ns.ToggleGrid() elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Blessing Button")
    Tip:AddLine("Left-click: Settings & Help", 1, 1, 1)
    Tip:AddLine("Right-click: the whole plan", 1, 1, 1)
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
function BlessingButton_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_BLESSINGBUTTON1 = "/bless"
SLASH_BLESSINGBUTTON2 = "/blessingbutton"
SlashCmdList.BLESSINGBUTTON = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if cmd == "plan" or cmd == "grid" then
    ns.ToggleGrid()
  elseif cmd == "who" then
    PrintPlan()
  elseif cmd == "show" or cmd == "always" then
    DB.show = "always"; Refresh(); Say("the button stays up. /bless auto shows it only when needed.")
  elseif cmd == "auto" then
    DB.show = "auto"; Refresh(); Say("the button shows only when someone needs a blessing.")
  elseif cmd == "hide" then
    DB.show = "off"; Refresh(); Say("hidden. Your key still works. /bless auto brings it back.")
  elseif cmd == "reset" then
    DB.point, DB.rel, DB.x, DB.y = nil, nil, nil, nil; DB.scale = 1; Place(); Refresh(); Say("back in the middle of the screen.")
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("one button that gives your group the right blessings. Each press casts the next one.")
    P("  /bless help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /bless plan   (" .. "the whole plan, change who gives what" .. ")   /bless who   (" .. "who you bless" .. ")")
    P("  /bless show   /bless auto   /bless hide   /bless reset")
  end
end
