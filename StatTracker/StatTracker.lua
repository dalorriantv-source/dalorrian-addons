-- Dalorrian's Stat Tracker: a clean stats panel beside your character window. Base stats, melee, ranged,
-- spell and defense, plus item level, durability and movement speed. Hover any stat to see what it does.
-- /stats shows it on its own.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local DEFAULTS = { attach = true, scale = 1, decimals = 1 }
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local Tip = ns.Tip or GameTooltip
local CF = ns.CreateFrame or CreateFrame   -- frames whose text is translated
local function Say(msg) P("|cffffd100Stat Tracker:|r " .. msg) end
local ICON = "Interface\\Icons\\INV_Misc_Note_01"

---------------------------------------------------------------------------
-- reading stats. WoW: Forever can be missing an API or hand back a value addons may not read, so every
-- call goes through Safe: anything it can't read comes back nil, and a nil stat is simply not shown.
---------------------------------------------------------------------------
local function Secret(v) return issecretvalue and issecretvalue(v) end
local function Safe(fn, ...)
  if type(fn) ~= "function" then return nil end
  local r = { pcall(fn, ...) }
  if not r[1] then return nil end
  for i = 2, #r do if Secret(r[i]) then return nil end end
  return unpack(r, 2, #r)
end
local function G(name) return _G[name] end   -- a global that may not exist in this client
local function Num(v) v = tonumber(v); if v and v == v and v ~= math.huge then return v end end

local function Commas(n)
  n = math.floor(n + 0.5)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  local s = tostring(n)
  while true do
    local t, k = s:gsub("^(%-?%d+)(%d%d%d)", "%1,%2")
    s = t
    if k == 0 then return s end
  end
end
local function Dec(v) return string.format("%." .. (DB and DB.decimals or 1) .. "f", v) end
local function Pct(v) v = Num(v); return v and (Dec(v) .. "%") or nil end

local function ClassToken() local _, c = Safe(UnitClass, "player"); return c end
local function UsesMana()
  local f = (UnitPowerType)
  local t = Safe(f, "player")
  if t == 0 then return true end
  local m = Num(Safe(UnitPowerMax, "player", 0))
  return m and m > 0
end
local function HasRanged()
  if ClassToken() == "HUNTER" then return true end
  local id = Safe(GetInventoryItemID, "player", 18)
  return id ~= nil
end

local STAT = { "Strength", "Agility", "Stamina", "Intellect", "Spirit" }
local function Stat(i)
  local _, eff = Safe(UnitStat, "player", i)
  return Num(eff)
end
local function Armor()
  local _, eff = Safe(UnitArmor, "player")
  return Num(eff)
end
local function AttackPower()
  local base, pos, neg = Safe(UnitAttackPower, "player")
  base = Num(base); if not base then return nil end
  return base + (Num(pos) or 0) + (Num(neg) or 0)
end
local function RangedPower()
  local base, pos, neg = Safe(UnitRangedAttackPower, "player")
  base = Num(base); if not base then return nil end
  return base + (Num(pos) or 0) + (Num(neg) or 0)
end
local function MeleeCrit() return Num(Safe(GetCritChance)) end
local function RangedCrit() return Num(Safe(GetRangedCritChance)) end
local function MeleeHit()
  local v = Num(Safe(GetHitModifier))
  if v then return v end
  local cr = G("CR_HIT_MELEE")
  if cr then return Num(Safe(GetCombatRatingBonus, cr)) end
end
local function Speeds()
  local mh, oh = Safe(UnitAttackSpeed, "player")
  mh, oh = Num(mh), Num(oh)
  if not mh or mh <= 0 then return nil end
  if oh and oh > 0 then return Dec(mh) .. " / " .. Dec(oh) end
  return Dec(mh)
end
local function MeleeDPS()
  local lo, hi, loOff, hiOff, _, _, pct = Safe(UnitDamage, "player")
  local mh, oh = Safe(UnitAttackSpeed, "player")
  lo, hi, mh = Num(lo), Num(hi), Num(mh)
  if not (lo and hi and mh and mh > 0) then return nil end
  local dps = (lo + hi) / 2 / mh
  loOff, hiOff, oh = Num(loOff), Num(hiOff), Num(oh)
  if loOff and hiOff and oh and oh > 0 and hiOff > 0 then dps = dps + (loOff + hiOff) / 2 / oh end
  return dps
end
local function RangedSpeed()
  local speed = Num(Safe(UnitRangedDamage, "player"))
  if speed and speed > 0 then return speed end
end
local function RangedDPS()
  local speed, lo, hi = Safe(UnitRangedDamage, "player")
  speed, lo, hi = Num(speed), Num(lo), Num(hi)
  if not (speed and speed > 0 and lo and hi and hi > 0) then return nil end
  return (lo + hi) / 2 / speed
end
-- spells: the best of the magic schools (holy, fire, nature, frost, shadow, arcane)
local function BestSchool(fn)
  local best
  for school = 2, 7 do
    local v = Num(Safe(fn, school))
    if v and (not best or v > best) then best = v end
  end
  return best
end
local function SpellPower() return BestSchool(GetSpellBonusDamage) end
local function SpellCrit() return BestSchool(GetSpellCritChance) end
local function Healing() return Num(Safe(GetSpellBonusHealing)) end
local function ManaRegen()   -- per 5 seconds, not casting
  local base = Num(Safe(GetManaRegen))
  if base then return base * 5 end
end
local function Defense()
  local base, mod = Safe(UnitDefense, "player")
  base = Num(base)
  if base then return base + (Num(mod) or 0) end
  local cr = G("CR_DEFENSE_SKILL")
  if cr then
    local r = Num(Safe(GetCombatRating, cr))
    if r then return r end
  end
end
local function DamageReduction()
  local armor = Armor()
  if not armor then return nil end
  local level = Num(Safe(UnitLevel, "player")) or 1
  if C_PaperDollInfo and C_PaperDollInfo.GetArmorEffectiveness then
    local v = Num(Safe(C_PaperDollInfo.GetArmorEffectiveness, armor, level))
    if v then return v * 100 end
  end
  -- the classic formula: armor / (armor + 400 + 85 x level), capped at 75%
  local dr = armor / (armor + 400 + 85 * level)
  return math.min(dr, 0.75) * 100
end
local function ItemLevel()
  local overall, equipped = Safe(GetAverageItemLevel)
  equipped = Num(equipped) or Num(overall)
  if equipped and equipped > 0 then return equipped end
  -- work it out from what you're wearing
  local sum, n = 0, 0
  for slot = 1, 17 do
    if slot ~= 4 then   -- shirts don't count
      local link = Safe(GetInventoryItemLink, "player", slot)
      if link then
        local lvl = C_Item and C_Item.GetDetailedItemLevelInfo and Num(Safe(C_Item.GetDetailedItemLevelInfo, link))
        if not lvl then local _, _, _, l = Safe((C_Item and C_Item.GetItemInfo) or GetItemInfo, link); lvl = Num(l) end
        if lvl then sum, n = sum + lvl, n + 1 end
      end
    end
  end
  if n > 0 then return sum / n end
end
local function Durability()
  local low
  for slot = 1, 19 do
    local cur, max = Safe(GetInventoryItemDurability, slot)
    cur, max = Num(cur), Num(max)
    if cur and max and max > 0 then
      local p = cur / max * 100
      if not low or p < low then low = p end
    end
  end
  return low
end
local function MoveSpeed()
  local current, run = Safe(GetUnitSpeed, "player")
  current, run = Num(current), Num(run)
  local v = (current and current > 0) and current or run
  if v then return v / 7 * 100 end
end

---------------------------------------------------------------------------
-- what's shown: { header, { label, read, format, tip }, ... }
---------------------------------------------------------------------------
local function Int(v) return v and Commas(v) or nil end
-- a stat that's 0 for you (healing on a warrior, parry on a hunter) is left out so the panel stays short
local function IntNZ(v) return v and v > 0 and Commas(v) or nil end
local function PctNZ(v) v = Num(v); return v and v > 0 and (Dec(v) .. "%") or nil end
local function Sections()
  local out = {}
  local base = { "Base" }
  for i, name in ipairs(STAT) do
    base[#base + 1] = { name, function() return Stat(i) end, Int, "TIP_" .. name }
  end
  base[#base + 1] = { "Armor", Armor, Int, "TIP_Armor" }
  out[#out + 1] = base
  out[#out + 1] = { "Melee",
    { "Attack Power", AttackPower, Int, "TIP_AttackPower" },
    { "Crit", MeleeCrit, Pct, "TIP_MeleeCrit" },
    { "Hit", MeleeHit, Pct, "TIP_Hit" },
    { "Attack Speed", Speeds, function(v) return v end, "TIP_AttackSpeed" },
    { "Damage Per Second", MeleeDPS, function(v) return v and Dec(v) end, "TIP_MeleeDPS" },
  }
  if HasRanged() then
    out[#out + 1] = { "Ranged",
      { "Ranged Attack Power", RangedPower, Int, "TIP_RangedPower" },
      { "Crit", RangedCrit, Pct, "TIP_RangedCrit" },
      { "Ranged Speed", RangedSpeed, function(v) return v and Dec(v) end, "TIP_RangedSpeed" },
      { "Damage Per Second", RangedDPS, function(v) return v and Dec(v) end, "TIP_RangedDPS" },
    }
  end
  if UsesMana() then
    out[#out + 1] = { "Spell",
      { "Spell Power", SpellPower, IntNZ, "TIP_SpellPower" },
      { "Spell Crit", SpellCrit, Pct, "TIP_SpellCrit" },
      { "Healing", Healing, IntNZ, "TIP_Healing" },
      { "Mana Regen", ManaRegen, function(v) return v and (Commas(v) .. " / 5 sec") end, "TIP_ManaRegen" },
    }
  end
  out[#out + 1] = { "Defense",
    { "Defense", Defense, Int, "TIP_Defense" },
    { "Dodge", function() return Num(Safe(GetDodgeChance)) end, Pct, "TIP_Dodge" },
    { "Parry", function() return Num(Safe(GetParryChance)) end, PctNZ, "TIP_Parry" },
    { "Block", function() return Num(Safe(GetBlockChance)) end, PctNZ, "TIP_Block" },
    { "Damage Reduction", DamageReduction, Pct, "TIP_DamageReduction" },
  }
  out[#out + 1] = { "General",
    { "Item Level", ItemLevel, function(v) return v and Dec(v) end, "TIP_ItemLevel" },
    { "Durability", Durability, function(v) return v and (math.floor(v + 0.5) .. "%") end, "TIP_Durability" },
    { "Movement Speed", MoveSpeed, function(v) return v and (math.floor(v + 0.5) .. "%") end, "TIP_MoveSpeed" },
  }
  return out
end

-- one plain line on what each stat does (English here; the Locales files translate them)
local TIPS = {
  TIP_Strength = "Raises melee attack power, and how much you block with a shield",
  TIP_Agility = "Raises crit, dodge and armor, and attack power for hunters, rogues and druids",
  TIP_Stamina = "More health",
  TIP_Intellect = "More mana and a higher spell crit chance",
  TIP_Spirit = "How fast you get health and mana back when you're not casting",
  TIP_Armor = "Lowers the physical damage you take",
  TIP_AttackPower = "Adds to the damage of your melee attacks",
  TIP_MeleeCrit = "Chance your melee attacks crit for double damage",
  TIP_Hit = "Lowers the chance your attacks miss",
  TIP_AttackSpeed = "Seconds between swings, main hand and off hand",
  TIP_MeleeDPS = "Your weapons' average damage each second, before abilities",
  TIP_RangedPower = "Adds to the damage of your ranged attacks",
  TIP_RangedCrit = "Chance your ranged attacks crit for double damage",
  TIP_RangedSpeed = "Seconds between ranged shots",
  TIP_RangedDPS = "Your ranged weapon's average damage each second, before abilities",
  TIP_SpellPower = "Adds to the damage of your spells",
  TIP_SpellCrit = "Chance your spells crit for extra damage or healing",
  TIP_Healing = "Adds to the healing of your spells",
  TIP_ManaRegen = "Mana you get back every 5 seconds while you're not casting",
  TIP_Defense = "Lowers the chance you get hit or crit, and raises dodge, parry and block",
  TIP_Dodge = "Chance to dodge a melee attack completely",
  TIP_Parry = "Chance to parry a melee attack from the front",
  TIP_Block = "Chance to block part of a hit with your shield",
  TIP_DamageReduction = "How much less physical damage you take thanks to your armor",
  TIP_ItemLevel = "The average item level of what you're wearing",
  TIP_Durability = "Your most worn item. Repair before it reaches 0%",
  TIP_MoveSpeed = "How fast you're moving compared to normal running speed",
}
ns.STAT_TIPS = TIPS

---------------------------------------------------------------------------
-- the panel
---------------------------------------------------------------------------
local panel, rows = nil, {}
local PW, RH = 210, 15
local standalone = false   -- opened with /stats (stays open on its own)

local function Text(parent, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  return fs
end

local function Row(i)
  local r = rows[i]
  if r then return r end
  r = CF("Button", nil, panel)
  r:SetSize(PW - 16, RH)
  r.hl = r:CreateTexture(nil, "BACKGROUND"); r.hl:SetAllPoints(); r.hl:SetTexture(W); r.hl:SetVertexColor(1, 1, 1, 0)
  r.label = Text(r, "GameFontHighlightSmall"); r.label:SetPoint("LEFT", 4, 0)
  r.value = Text(r, "GameFontHighlightSmall"); r.value:SetPoint("RIGHT", -4, 0); r.value:SetJustifyH("RIGHT")
  r:SetScript("OnEnter", function(self)
    if not self.tip then return end
    self.hl:SetVertexColor(1, 1, 1, 0.06)
    Tip:SetOwner(self, "ANCHOR_RIGHT")
    Tip:AddLine(self.name, GOLD[1], GOLD[2], GOLD[3])
    Tip:AddLine(TIPS[self.tip] or "", 1, 1, 1, true)
    Tip:Show()
  end)
  r:SetScript("OnLeave", function(self) self.hl:SetVertexColor(1, 1, 1, 0); GameTooltip:Hide() end)
  rows[i] = r
  return r
end

local function Paint()
  if not (panel and panel:IsShown()) then return end
  local y, n = -34, 0
  for _, sec in ipairs(Sections()) do
    local lines = {}
    for k = 2, #sec do
      local s = sec[k]
      local ok, v = pcall(s[2])
      local shown = ok and v ~= nil and s[3](v) or nil
      if shown then lines[#lines + 1] = { s[1], shown, s[4] } end
    end
    if #lines > 0 then
      n = n + 1
      local h = Row(n)
      h.tip, h.name = nil, nil
      h.label:SetFontObject("GameFontNormalSmall"); h.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
      h.label:SetText(sec[1]); h.value:SetText("")
      h:ClearAllPoints(); h:SetPoint("TOPLEFT", 8, y); h:Show()
      y = y - RH - 1
      for _, l in ipairs(lines) do
        n = n + 1
        local r = Row(n)
        r.tip, r.name = l[3], Tr(l[1])
        r.label:SetFontObject("GameFontHighlightSmall"); r.label:SetTextColor(0.78, 0.78, 0.82)
        r.label:SetText(l[1]); r.value:SetText(l[2]); r.value:SetTextColor(1, 1, 1)
        r:ClearAllPoints(); r:SetPoint("TOPLEFT", 8, y); r:Show()
        y = y - RH
      end
      y = y - 6
    end
  end
  for i = n + 1, #rows do rows[i]:Hide() end
  panel:SetHeight(-y + 6)
end

local function Place()
  if not panel then return end
  panel:SetScale(DB.scale or 1)
  panel:ClearAllPoints()
  local cf = _G.CharacterFrame
  if not standalone and cf and cf:IsShown() then
    panel:SetPoint("TOPLEFT", cf, "TOPRIGHT", 4, -12)
  elseif DB.point then
    panel:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
  else
    panel:SetPoint("CENTER", UIParent, "CENTER", 260, 40)
  end
end

local function Build()
  panel = CF("Frame", "StatTrackerFrame", UIParent, "BackdropTemplate")
  panel:SetSize(PW, 120)
  panel:SetFrameStrata("HIGH")
  panel:SetClampedToScreen(true)
  panel:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
  panel:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
  panel:SetBackdropBorderColor(0.25, 0.26, 0.3, 1)
  panel:EnableMouse(true)
  panel:SetMovable(true)
  panel:RegisterForDrag("LeftButton")
  panel:SetScript("OnDragStart", function(self) if standalone then self:StartMoving() end end)
  panel:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint(1)
    DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
  end)
  local title = Text(panel, "GameFontNormal"); title:SetPoint("TOPLEFT", 10, -10); title:SetText("Stat Tracker")
  local close = CF("Button", nil, panel)
  close:SetSize(18, 18); close:SetPoint("TOPRIGHT", -6, -6)
  close.t = Text(close, "GameFontHighlight"); close.t:SetPoint("CENTER"); close.t:SetText("x")
  close:SetScript("OnClick", function() standalone = false; panel:Hide() end)
  local line = panel:CreateTexture(nil, "ARTWORK"); line:SetTexture(W); line:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.35)
  line:SetPoint("TOPLEFT", 8, -28); line:SetPoint("TOPRIGHT", -8, -28); line:SetHeight(1)
  -- speed changes as you move, and durability as you fight: a light refresh every second while it's open
  local acc = 0
  panel:SetScript("OnUpdate", function(_, el) acc = acc + el; if acc >= 1 then acc = 0; Paint() end end)
  panel:Hide()
end

local function Open(alone)
  if not DB then return end
  if not panel then Build() end
  standalone = alone and true or false
  Place()
  panel:Show()
  Paint()
end
local function Toggle()
  if panel and panel:IsShown() and standalone then panel:Hide(); standalone = false return end
  Open(true)
end
ns.ToggleStats = Toggle
ns.StatSections = Sections

-- riding along with the character window
local function HookCharacter()
  local cf = _G.CharacterFrame
  if not cf or cf.statTrackerHooked then return end
  cf.statTrackerHooked = true
  cf:HookScript("OnShow", function() if DB and DB.attach and not standalone then Open(false) end end)
  cf:HookScript("OnHide", function() if panel and not standalone then panel:Hide() end end)
end

---------------------------------------------------------------------------
-- events: repaint soon after anything that changes your stats
---------------------------------------------------------------------------
local soon
local function Soon()
  if soon or not (panel and panel:IsShown()) then return end
  soon = true
  C_Timer.After(0.2, function() soon = nil; Paint() end)
end

local MinimapButton
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP", "UPDATE_INVENTORY_DURABILITY", "COMBAT_RATING_UPDATE",
  "SKILL_LINES_CHANGED", "PLAYER_DAMAGE_DONE_MODS", "SPELL_POWER_CHANGED", "PLAYER_ENTERING_WORLD" }) do
  pcall(ev.RegisterEvent, ev, e)
end
if ev.RegisterUnitEvent then
  for _, e in ipairs({ "UNIT_STATS", "UNIT_AURA", "UNIT_ATTACK_POWER", "UNIT_RANGED_ATTACK_POWER", "UNIT_ATTACK_SPEED",
    "UNIT_DAMAGE", "UNIT_RANGEDDAMAGE", "UNIT_RESISTANCES", "UNIT_MAXPOWER" }) do
    pcall(ev.RegisterUnitEvent, ev, e, "player")
  end
end
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    StatTrackerDB = StatTrackerDB or {}
    DB = StatTrackerDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
  elseif e == "PLAYER_LOGIN" then
    pcall(HookCharacter)
    pcall(MinimapButton)
  else
    Soon()
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Stat Tracker",
  tag = "Stat Tracker",
  settings = {
    { label = "Show With Character Window", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.attach and true or false end,
      set = function(v) DB.attach = v; if not v and panel and not standalone then panel:Hide() end end },
    { label = "Panel Size", choices = { { "Small", 0.85 }, { "Normal", 1 }, { "Big", 1.2 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Place() end },
    { label = "Decimals", choices = { { "1", 1 }, { "2", 2 } },
      get = function() return DB.decimals or 1 end, set = function(v) DB.decimals = v; Paint() end },
  },
  notes = {
    { v = "1.0.0", "First release: a clean stats panel beside your character window. Base stats, melee, ranged, spell and defense, plus item level, durability and movement speed. Hover any stat to see what it does" },
  },
  report = function()
    local n = 0
    for _, sec in ipairs(Sections()) do
      for k = 2, #sec do local ok, v = pcall(sec[k][2]); if ok and v ~= nil then n = n + 1 end end
    end
    return { "Stats read " .. n .. ", attach " .. tostring(DB.attach) .. ", scale " .. tostring(DB.scale) .. ", class " .. tostring(ClassToken()) }
  end,
}

MinimapButton = function()
  if not Minimap or _G.StatTrackerMinimapButton then return end
  local b = CreateFrame("Button", "StatTrackerMinimapButton", Minimap)
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
    local a = math.rad(DB.minimapAngle or 230)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then if ns.OpenHelp then ns.OpenHelp() end
    else Toggle() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Stat Tracker")
    Tip:AddLine("Left-click: show or hide your stats", 1, 1, 1)
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
function StatTracker_OnCompartmentClick() Toggle() end

SLASH_STATTRACKER1 = "/stats"
SLASH_STATTRACKER2 = "/stattracker"
SlashCmdList.STATTRACKER = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if cmd == "" or cmd == "show" then
    Toggle()
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("your stats, in one clean panel.")
    P("  /stats   (" .. "show or hide your stats" .. ")")
    P("  /stats help   (" .. "all settings, and how to report a bug" .. ")")
  end
end
