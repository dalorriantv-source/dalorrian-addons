-- Dalorrian's Stat Tracker: a clean stats panel beside your character window. Base stats, melee, ranged,
-- spell and defense, plus item level, durability and movement speed. Hover any stat to see what it does.
-- /stats shows it on its own.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local DEFAULTS = { attach = true, scale = 1, decimals = 1, gear = true }
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
  -- (1.1.0) the average of what you're wearing: the game's own number counts empty slots as 0
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
  local overall, equipped = Safe(GetAverageItemLevel)
  equipped = Num(equipped) or Num(overall)
  if equipped and equipped > 0 then return equipped end
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
local PW, RH = 230, 15
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
    if self.tipText then
      self.hl:SetVertexColor(1, 1, 1, 0.06)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      local item = self.tipText:match("|H(item:[^|]+)|h")
      if item then GameTooltip:SetHyperlink(item) else GameTooltip:AddLine(self.tipText, 1, 1, 1, true) end
      GameTooltip:Show()
      return
    end
    if not self.tip then return end
    self.hl:SetVertexColor(1, 1, 1, 0.06)
    Tip:SetOwner(self, "ANCHOR_RIGHT")
    Tip:AddLine(self.name, GOLD[1], GOLD[2], GOLD[3])
    Tip:AddLine(TIPS[self.tip] or "", 1, 1, 1, true)
    Tip:Show()
  end)
  r:SetScript("OnClick", function(self) if self.onClick then self.onClick() end end)
  r:SetScript("OnLeave", function(self) self.hl:SetVertexColor(1, 1, 1, 0); GameTooltip:Hide() end)
  rows[i] = r
  return r
end

-- (1.1.0) every stat by key, so your spec can put them in its own order
local function Lines(spec)
  local ranged = spec and spec.ranged
  return {
    WDPS = ranged and { "Weapon DPS", RangedDPS, function(v) return v and Dec(v) end, "TIP_RangedDPS" }
      or { "Weapon DPS", MeleeDPS, function(v) return v and Dec(v) end, "TIP_MeleeDPS" },
    EXP = { "Expertise", function() return Num(Safe(GetExpertise)) end, Int, nil },
    HASTE = { "Haste", function()
      local v = Num(Safe(GetHaste))
      if v then return v end
      local cr = G("CR_HASTE_SPELL")
      if cr then return Num(Safe(GetCombatRatingBonus, cr)) end
    end, Pct, nil },
    STR = { "Strength", function() return Stat(1) end, Int, "TIP_Strength" },
    AGI = { "Agility", function() return Stat(2) end, Int, "TIP_Agility" },
    STA = { "Stamina", function() return Stat(3) end, Int, "TIP_Stamina" },
    INT = { "Intellect", function() return Stat(4) end, Int, "TIP_Intellect" },
    SPI = { "Spirit", function() return Stat(5) end, Int, "TIP_Spirit" },
    ARMOR = { "Armor", Armor, Int, "TIP_Armor" },
    AP = { "Attack Power", AttackPower, Int, "TIP_AttackPower" },
    RAP = { "Ranged Attack Power", RangedPower, Int, "TIP_RangedPower" },
    CRIT = ranged and { "Crit", RangedCrit, Pct, "TIP_RangedCrit" } or { "Crit", MeleeCrit, Pct, "TIP_MeleeCrit" },
    HIT = { "Hit", MeleeHit, Pct, "TIP_Hit" },
    SP = { "Spell Power", SpellPower, Int, "TIP_SpellPower" },
    HEAL = { "Healing", Healing, Int, "TIP_Healing" },
    SCRIT = { "Spell Crit", SpellCrit, Pct, "TIP_SpellCrit" },
    MP5 = { "Mana Regen", ManaRegen, function(v) return v and (Commas(v) .. " / 5 sec") end, "TIP_ManaRegen" },
    DEF = { "Defense", Defense, Int, "TIP_Defense" },
    DODGE = { "Dodge", function() return Num(Safe(GetDodgeChance)) end, Pct, "TIP_Dodge" },
    PARRY = { "Parry", function() return Num(Safe(GetParryChance)) end, Pct, "TIP_Parry" },
    BLOCK = { "Block", function() return Num(Safe(GetBlockChance)) end, Pct, "TIP_Block" },
  }
end
-- the rest, after your spec's stats
local EXTRA = {
  { "Attack Speed", Speeds, function(v) return v end, "TIP_AttackSpeed" },
  { "Ranged Speed", RangedSpeed, function(v) return v and Dec(v) end, "TIP_RangedSpeed" },
  { "Damage Reduction", DamageReduction, Pct, "TIP_DamageReduction" },
  { "Item Level", ItemLevel, function(v) return v and Dec(v) end, "TIP_ItemLevel" },
  { "Durability", Durability, function(v) return v and (math.floor(v + 0.5) .. "%") end, "TIP_Durability" },
  { "Movement Speed", MoveSpeed, function(v) return v and (math.floor(v + 0.5) .. "%") end, "TIP_MoveSpeed" },
}

---------------------------------------------------------------------------
-- (1.1.0) your gear: green, gray or red stats beside each slot, and where to upgrade next
---------------------------------------------------------------------------
local SLOTS = {
  { "Head", 1, "L", "INVTYPE_HEAD" }, { "Neck", 2, "L", "INVTYPE_NECK" }, { "Shoulder", 3, "L", "INVTYPE_SHOULDER" },
  { "Back", 15, "L", "INVTYPE_CLOAK" }, { "Chest", 5, "L", "INVTYPE_CHEST" }, { "Wrist", 9, "L", "INVTYPE_WRIST" },
  { "Hands", 10, "R", "INVTYPE_HAND" }, { "Waist", 6, "R", "INVTYPE_WAIST" }, { "Legs", 7, "R", "INVTYPE_LEGS" },
  { "Feet", 8, "R", "INVTYPE_FEET" }, { "Finger0", 11, "R", "INVTYPE_FINGER" }, { "Finger1", 12, "R", "INVTYPE_FINGER" },
  { "Trinket0", 13, "R", "INVTYPE_TRINKET" }, { "Trinket1", 14, "R", "INVTYPE_TRINKET" },
  { "MainHand", 16, "B", "INVTYPE_WEAPONMAINHAND" }, { "SecondaryHand", 17, "B", "INVTYPE_WEAPONOFFHAND" }, { "Ranged", 18, "B", "INVTYPE_RANGED" },
}
local SLOT_EN = { INVTYPE_HEAD = "Head", INVTYPE_NECK = "Neck", INVTYPE_SHOULDER = "Shoulder", INVTYPE_CLOAK = "Back",
  INVTYPE_CHEST = "Chest", INVTYPE_WRIST = "Wrist", INVTYPE_HAND = "Hands", INVTYPE_WAIST = "Waist", INVTYPE_LEGS = "Legs",
  INVTYPE_FEET = "Feet", INVTYPE_FINGER = "Finger", INVTYPE_TRINKET = "Trinket", INVTYPE_WEAPONMAINHAND = "Main Hand",
  INVTYPE_WEAPONOFFHAND = "Off Hand", INVTYPE_RANGED = "Ranged" }
local function SlotName(s) local g = _G[s[4]]; return (type(g) == "string" and g ~= "") and g or Tr(SLOT_EN[s[4]]) end
local COLOR = { good = { 0.3, 1, 0.3 }, meh = { 0.62, 0.62, 0.62 }, bad = { 1, 0.3, 0.3 } }
local ORDER = { [1] = 1, [5] = 2, [7] = 3, [3] = 4, [10] = 5, [8] = 6, [6] = 7, [9] = 8, [15] = 9, [16] = 10, [18] = 11, [17] = 12, [2] = 13, [11] = 14, [12] = 15, [13] = 16, [14] = 17 }

local function ILvl(link)
  local lvl = C_Item and C_Item.GetDetailedItemLevelInfo and Num(Safe(C_Item.GetDetailedItemLevelInfo, link))
  if not lvl then local _, _, _, l = Safe((C_Item and C_Item.GetItemInfo) or GetItemInfo, link); lvl = Num(l) end
  return lvl or 0
end

-- every slot: what's in it, its stats and what that means for your spec
local function Gear(spec)
  local out = {}
  local w = spec and spec.weights or {}
  local mh = Safe(GetInventoryItemLink, "player", 16)
  local twoHand = false
  if mh then local _, _, _, _, _, _, _, _, equip = Safe((C_Item and C_Item.GetItemInfo) or GetItemInfo, mh); twoHand = equip == "INVTYPE_2HWEAPON" end
  for _, s in ipairs(SLOTS) do
    local link = Safe(GetInventoryItemLink, "player", s[2])
    local g = { slot = s, link = link }
    if link then
      g.stats = ns.ItemStats(link)
      g.verdict = ns.Verdict(g.stats, w)
      g.ilvl = ILvl(link)
    elseif s[2] == 17 and twoHand then
      g.skip = true   -- a two-hander fills both hands
    end
    out[#out + 1] = g
  end
  return out
end

-- the labels beside each slot on your character window: a small dark box, one stat per line
local labels, toggle = {}, nil
local function Label(s, slot)
  local box = labels[s[2]]
  if box then return box end
  box = CreateFrame("Frame", nil, slot)
  box:SetFrameLevel(slot:GetFrameLevel() + 2)
  box.bg = box:CreateTexture(nil, "BACKGROUND"); box.bg:SetAllPoints(); box.bg:SetTexture(W); box.bg:SetVertexColor(0, 0, 0, 0.6)
  box.text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  box.text:SetPoint("CENTER")
  box.text:SetSpacing(1)
  if s[3] == "L" then box:SetPoint("LEFT", slot, "RIGHT", 5, 0); box.text:SetJustifyH("LEFT")
  elseif s[3] == "R" then box:SetPoint("RIGHT", slot, "LEFT", -5, 0); box.text:SetJustifyH("RIGHT")
  else box:SetPoint("BOTTOM", slot, "TOP", 0, 4); box.text:SetJustifyH("CENTER") end
  labels[s[2]] = box
  return box
end

-- Gear Stats: On / Off, right on the character window
local PaintGear
local function GearToggle()
  if toggle then return toggle end
  local head = _G.CharacterHeadSlot
  if not head then return end
  toggle = CreateFrame("Button", nil, head)
  toggle:SetSize(100, 18)
  toggle:SetPoint("BOTTOMLEFT", head, "TOPLEFT", 0, 6)
  toggle.bg = toggle:CreateTexture(nil, "BACKGROUND"); toggle.bg:SetAllPoints(); toggle.bg:SetTexture(W)
  toggle.text = toggle:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall"); toggle.text:SetPoint("CENTER")
  toggle:SetScript("OnClick", function() DB.gear = not DB.gear; PaintGear() end)
  toggle:SetScript("OnEnter", function(self) self.bg:SetVertexColor(0.22, 0.23, 0.28, 0.95) end)
  toggle:SetScript("OnLeave", function(self) self.bg:SetVertexColor(0.08, 0.08, 0.1, 0.85) end)
  toggle.bg:SetVertexColor(0.08, 0.08, 0.1, 0.85)
  return toggle
end

PaintGear = function()
  local cf = _G.CharacterFrame
  if not (DB and cf and cf:IsShown()) then return end
  local t = GearToggle()
  if t then
    t.text:SetText(Tr(DB.gear and "Gear Stats: On" or "Gear Stats: Off"))
    if DB.gear then t.text:SetTextColor(0.3, 1, 0.3) else t.text:SetTextColor(0.6, 0.6, 0.6) end
  end
  local spec = ns.CurrentSpec(DB)
  for _, g in ipairs(Gear(spec)) do
    local s = g.slot
    local slot = _G["Character" .. s[1] .. "Slot"]
    if slot then
      local box = Label(s, slot)
      if DB.gear and g.stats and next(g.stats) and spec then
        local c = COLOR[g.verdict] or COLOR.meh
        box.text:SetText(ns.StatText(g.stats, spec.weights)); box.text:SetTextColor(c[1], c[2], c[3])
        box:SetSize((box.text:GetStringWidth() or 40) + 8, (box.text:GetStringHeight() or 12) + 4)
        box:Show()
      else
        box:Hide()
      end
    end
  end
end
ns.PaintGear = PaintGear

local function Paint()
  PaintGear()
  if not (panel and panel:IsShown()) then return end
  local y, n = -34, 0
  local function Head(text)
    n = n + 1
    local h = Row(n)
    h.tip, h.name, h.onClick, h.tipText = nil, nil, nil, nil
    h.label:SetFontObject("GameFontNormalSmall"); h.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    h.label:SetText(text); h.value:SetText("")
    h:ClearAllPoints(); h:SetPoint("TOPLEFT", 8, y); h:Show()
    y = y - RH - 1
    return h
  end
  local function Line(label, value, tip, r, g, b)
    n = n + 1
    local row = Row(n)
    row.tip, row.name, row.onClick, row.tipText = tip, Tr(label), nil, nil
    row.label:SetFontObject("GameFontHighlightSmall"); row.label:SetTextColor(0.78, 0.78, 0.82)
    row.label:SetText(label); row.value:SetText(value or ""); row.value:SetTextColor(r or 1, g or 1, b or 1)
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", 8, y); row:Show()
    y = y - RH
    return row
  end

  -- who you are: race, class and spec. Click the spec to change it
  local spec = ns.CurrentSpec(DB)
  local race = Safe(UnitRace, "player") or ""
  local cname, ctoken = Safe(UnitClass, "player")
  local cc = ctoken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[ctoken]
  local who = Head(race .. " " .. (cname or ""))
  if cc then who.label:SetTextColor(cc.r, cc.g, cc.b) end
  if spec then
    local r = Line(spec.name .. (spec.auto and ("  |cff888888(" .. Tr("auto") .. ")|r") or ""), Tr("Change"), nil, GOLD[1], GOLD[2], GOLD[3])
    r.label:SetTextColor(1, 1, 1)
    r.tipText = Tr("Click to change your spec")
    r.onClick = function() ns.NextSpec(DB); Paint() end
  end
  y = y - 6

  -- your most important stats, best first
  local L = Lines(spec)
  local w = spec and spec.weights or {}
  local keys = {}
  for k in pairs(L) do keys[#keys + 1] = k end
  table.sort(keys, function(a, b) local x, z = w[a] or 0, w[b] or 0; if x ~= z then return x > z end return a < b end)
  local top, rest = {}, {}
  for _, k in ipairs(keys) do
    -- a hunter's attack power on gear counts for shots too, but the melee number is not one to watch
    local watch = not (k == "AP" and ClassToken() == "HUNTER")
    -- a stat this client can't read (Expertise before gear has it) waits in More Stats instead of showing a dash
    local readable = k == "WDPS"
    if watch and (w[k] or 0) >= 0.5 and #top < 6 and not readable then
      local d = L[k]; local ok, v = pcall(d[2]); readable = ok and v ~= nil
    end
    if watch and (w[k] or 0) >= 0.5 and #top < 6 and readable then top[#top + 1] = k else rest[#rest + 1] = k end
  end
  Head(Tr("Most Important Stats"))
  for i, k in ipairs(top) do
    local d = L[k]
    local ok, v = pcall(d[2])
    local shown = ok and v ~= nil and d[3](v) or "-"
    if k == "WDPS" and shown == "-" then shown = Tr("no weapon") end
    local r = Line(d[1], shown, d[4])
    r.label:SetText(i .. ". " .. Tr(d[1]))
  end
  y = y - 6

  -- everything else, folded away until you want it
  local more = Head(Tr("More Stats") .. (DB.more and "  -" or "  +"))
  more.onClick = function() DB.more = not DB.more; Paint() end
  more.tipText = Tr(DB.more and "Click to hide" or "Click to show")
  if DB.more then
    for _, k in ipairs(rest) do
      local d = L[k]
      local ok, v = pcall(d[2])
      local shown = ok and v ~= nil and d[3](v) or nil
      if shown and shown ~= "0" and shown ~= (Dec(0) .. "%") then Line(d[1], shown, d[4]) end
    end
    for _, d in ipairs(EXTRA) do
      local ok, v = pcall(d[2])
      local shown = ok and v ~= nil and d[3](v) or nil
      if shown then Line(d[1], shown, d[4]) end
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
  cf:HookScript("OnShow", function() if DB and DB.attach and not standalone then Open(false) end; C_Timer.After(0.05, ns.PaintGear) end)
  cf:HookScript("OnHide", function() if panel and not standalone then panel:Hide() end end)
end

---------------------------------------------------------------------------
-- events: repaint soon after anything that changes your stats
---------------------------------------------------------------------------
local soon
local function Soon()
  if soon then return end
  local cf = _G.CharacterFrame
  if not ((panel and panel:IsShown()) or (cf and cf:IsShown())) then return end
  soon = true
  C_Timer.After(0.2, function() soon = nil; Paint() end)
end

local MinimapButton
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "PLAYER_EQUIPMENT_CHANGED", "PLAYER_LEVEL_UP", "UPDATE_INVENTORY_DURABILITY", "COMBAT_RATING_UPDATE",
  "SKILL_LINES_CHANGED", "PLAYER_DAMAGE_DONE_MODS", "SPELL_POWER_CHANGED", "PLAYER_ENTERING_WORLD",
  "CHARACTER_POINTS_CHANGED", "PLAYER_TALENT_UPDATE", "GET_ITEM_INFO_RECEIVED" }) do
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
    -- (1.1.0) colored stats beside each slot on your character window
    { label = "Gear Stats On Character Window", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.gear and true or false end, set = function(v) DB.gear = v; Paint() end },
  },
  notes = {
    { v = "1.1.0", "Pick your spec (or let it read your talents) and the panel puts your most important stats first",
      "On your character window, each piece of gear shows its stats in green when they're good for your spec, gray when they're so-so and red when they're wrong for you",
      "A Gear Stats button on your character window turns those on and off",
      "Item level counts only what you're wearing, so empty slots no longer drag it down. Everything else sits under More Stats",
      "Stat priorities follow the current WoW: Forever spec guides: weapon damage comes first for melee and hunters, Survival hunters are melee, and Haste and Expertise count" },
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
