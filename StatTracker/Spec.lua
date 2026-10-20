-- Dalorrian's Stat Tracker (1.1.0): what each class and spec wants, and what your gear gives you.
-- Weights: 1 is what you want most, 0 does nothing for you. The game's own talent tab names are used when it has them.

local ADDON, ns = ...

-- stat keys: WDPS (weapon damage) STR AGI STA INT SPI AP RAP CRIT HIT EXP HASTE SP HEAL SCRIT MP5 DEF DODGE PARRY BLOCK ARMOR
-- (1.1.0) from the WoW: Forever spec guides (Icy Veins, Oct 2026, level 30 beta). Forever merges melee, ranged and
-- spell hit into one Hit and crit into one Crit, adds Haste and Expertise, and makes Survival a melee spec.
-- Healing power includes a third of spell damage, so healers count spell damage a little.
local SPECS = {
  WARRIOR = {
    { "Arms", { WDPS = 1, HIT = 0.95, EXP = 0.9, CRIT = 0.9, STR = 0.85, AP = 0.6, AGI = 0.6, STA = 0.3 } },
    { "Fury", { WDPS = 1, HIT = 0.95, EXP = 0.9, CRIT = 0.9, STR = 0.85, AP = 0.6, AGI = 0.6, STA = 0.3 } },
    { "Protection", { WDPS = 1, HIT = 0.95, STR = 0.9, AGI = 0.8, ARMOR = 0.75, STA = 0.7, DEF = 0.55, DODGE = 0.5, PARRY = 0.45, CRIT = 0.5, BLOCK = 0.4, EXP = 0.6 } },
  },
  PALADIN = {
    { "Holy", { HEAL = 1, INT = 0.9, MP5 = 0.85, SCRIT = 0.7, HASTE = 0.65, SPI = 0.5, SP = 0.33, STA = 0.2 } },
    { "Protection", { STA = 1, SP = 0.9, STR = 0.8, BLOCK = 0.75, HIT = 0.7, DEF = 0.65, ARMOR = 0.6, WDPS = 0.5, INT = 0.45, AGI = 0.35, DODGE = 0.4, PARRY = 0.4 } },
    { "Retribution", { WDPS = 1, HIT = 0.95, EXP = 0.9, CRIT = 0.85, SP = 0.75, STR = 0.7, INT = 0.55, AGI = 0.45, AP = 0.5, STA = 0.3, SPI = 0.15 } },
  },
  HUNTER = {
    { "Beast Mastery", { WDPS = 1, HIT = 0.95, AGI = 0.9, CRIT = 0.8, RAP = 0.6, INT = 0.55, AP = 0.5, SPI = 0.15, STA = 0.2 }, { ranged = true } },
    { "Marksmanship", { WDPS = 1, HIT = 0.95, AGI = 0.9, CRIT = 0.85, RAP = 0.6, INT = 0.55, AP = 0.5, SPI = 0.15, STA = 0.2 }, { ranged = true } },
    { "Survival", { WDPS = 1, HIT = 0.95, AGI = 0.9, CRIT = 0.8, STR = 0.55, AP = 0.55, INT = 0.45, SPI = 0.15, STA = 0.2 } },   -- melee, two weapons
  },
  ROGUE = {
    { "Assassination", { WDPS = 1, HIT = 0.95, EXP = 0.9, AGI = 0.85, CRIT = 0.8, AP = 0.6, STR = 0.5, STA = 0.3 } },
    { "Combat", { WDPS = 1, HIT = 0.95, EXP = 0.9, AGI = 0.85, CRIT = 0.8, AP = 0.6, STR = 0.5, STA = 0.3 } },
    { "Subtlety", { WDPS = 1, HIT = 0.95, EXP = 0.9, AGI = 0.85, AP = 0.7, CRIT = 0.65, STR = 0.5, STA = 0.3 } },
  },
  PRIEST = {
    { "Discipline", { HEAL = 1, MP5 = 0.9, SPI = 0.85, INT = 0.7, SCRIT = 0.55, SP = 0.33, STA = 0.2 } },
    { "Holy", { HEAL = 1, MP5 = 0.9, SPI = 0.85, INT = 0.7, SCRIT = 0.45, SP = 0.33, STA = 0.2 } },
    { "Shadow", { SP = 1, SCRIT = 0.8, HIT = 0.7, INT = 0.5, STA = 0.4, MP5 = 0.35, SPI = 0.35 } },
  },
  SHAMAN = {
    { "Elemental", { SP = 1, SCRIT = 0.85, HIT = 0.75, INT = 0.6, MP5 = 0.5, SPI = 0.25, STA = 0.2 } },
    { "Enhancement", { WDPS = 1, HIT = 0.95, EXP = 0.9, CRIT = 0.8, STR = 0.75, INT = 0.6, AGI = 0.5, AP = 0.55, SPI = 0.35, SP = 0.25, STA = 0.2 } },
    { "Restoration", { HEAL = 1, SCRIT = 0.8, INT = 0.7, SPI = 0.6, MP5 = 0.6, SP = 0.33, STA = 0.2 } },
  },
  MAGE = {
    { "Arcane", { HIT = 1, SPI = 0.9, INT = 0.85, SP = 0.8, SCRIT = 0.55, MP5 = 0.2, STA = 0.2 } },
    { "Fire", { HIT = 1, SP = 0.95, SCRIT = 0.85, SPI = 0.65, INT = 0.55, STA = 0.25, MP5 = 0.2 } },
    { "Frost", { HIT = 1, SP = 0.95, SCRIT = 0.8, SPI = 0.65, INT = 0.55, STA = 0.25 } },
  },
  WARLOCK = {
    { "Affliction", { SP = 1, HIT = 0.9, SCRIT = 0.75, INT = 0.6, SPI = 0.55, HASTE = 0.5, STA = 0.4 } },
    { "Demonology", { SP = 1, HIT = 0.9, INT = 0.7, SCRIT = 0.65, SPI = 0.55, HASTE = 0.5, STA = 0.45 } },
    { "Destruction", { SP = 1, HIT = 0.9, HASTE = 0.8, SCRIT = 0.75, SPI = 0.55, INT = 0.5, STA = 0.4 } },
  },
  DRUID = {
    { "Balance", { SP = 1, INT = 0.85, HASTE = 0.7, SCRIT = 0.6, HIT = 0.6, SPI = 0.4, MP5 = 0.4, STA = 0.2 } },
    { "Feral Combat", { WDPS = 1, HIT = 0.95, EXP = 0.9, CRIT = 0.85, STR = 0.8, AGI = 0.75, AP = 0.6, STA = 0.55, ARMOR = 0.3, SPI = 0.15, INT = 0.1 } },
    { "Restoration", { HEAL = 1, INT = 0.85, SCRIT = 0.6, HASTE = 0.55, SPI = 0.55, MP5 = 0.55, SP = 0.33, STA = 0.2 } },
  },
}
ns.SPECS = SPECS

local function ClassToken() local ok, _, c = pcall(UnitClass, "player"); return ok and c or nil end
ns.ClassToken = ClassToken

-- points in each talent tree: the first small number the game hands back (its order differs between clients)
local function TabInfo(i)
  local r = { pcall(GetTalentTabInfo, i) }
  if not r[1] then return nil, 0 end
  local name, pts
  for k = 2, #r do
    local v = r[k]
    if type(v) == "string" and not name then name = v end
    if type(v) == "number" and k > 2 and v >= 0 and v <= 61 and not pts then pts = v end
  end
  return name, pts or 0
end

local function CharKey()
  local ok, g = pcall(UnitGUID, "player")
  return (ok and g) or ((UnitName("player") or "") .. "-" .. (GetRealmName and GetRealmName() or ""))
end
ns.CharKey = CharKey

-- your spec: what you picked, or the tree with the most points (the first tree before you have any)
function ns.CurrentSpec(DB)
  local list = SPECS[ClassToken() or ""]
  if not list then return nil end
  DB.specFor = DB.specFor or {}
  local pick = DB.specFor[CharKey()]
  local auto = not pick
  if auto then
    local best, most = 1, 0
    for i = 1, 3 do
      local _, pts = TabInfo(i)
      if pts > most then best, most = i, pts end
    end
    pick = best
  end
  local s = list[pick] or list[1]
  local name = TabInfo(pick)
  if type(name) ~= "string" or name == "" then name = ns.Tr and ns.Tr(s[1]) or s[1] end
  local opts = s[3] or {}
  return { index = pick, name = name, weights = s[2], auto = auto, ranged = opts.ranged }
end

-- Auto, then each spec, then Auto again
function ns.NextSpec(DB)
  DB.specFor = DB.specFor or {}
  local k = CharKey()
  local cur = DB.specFor[k]
  if not cur then DB.specFor[k] = 1
  elseif cur >= 3 then DB.specFor[k] = nil
  else DB.specFor[k] = cur + 1 end
end

---------------------------------------------------------------------------
-- reading gear: the stats on an item, and how good they are for your spec
---------------------------------------------------------------------------
-- order matters: ranged attack power before attack power, spell crit before crit
local MAP = {
  { "DAMAGE_PER_SECOND", "WDPS" }, { "EXPERTISE", "EXP" }, { "HASTE", "HASTE" },
  { "RANGED_ATTACK_POWER", "RAP" }, { "ATTACK_POWER", "AP" }, { "STRENGTH", "STR" }, { "AGILITY", "AGI" },
  { "STAMINA", "STA" }, { "INTELLECT", "INT" }, { "SPIRIT", "SPI" }, { "SPELL_HEALING", "HEAL" }, { "HEALING", "HEAL" },
  { "SPELL_DAMAGE", "SP" }, { "SPELL_POWER", "SP" }, { "POWER_REGEN0", "MP5" }, { "MANA_REGENERATION", "MP5" },
  { "DEFENSE", "DEF" }, { "DODGE", "DODGE" }, { "PARRY", "PARRY" }, { "BLOCK", "BLOCK" },
  { "SPELL_CRIT", "SCRIT" }, { "CRIT", "CRIT" }, { "SPELL_HIT", "HIT" }, { "HIT", "HIT" },
}
local SHORT = { WDPS = "DPS", EXP = "Exp", HASTE = "Haste", STR = "Str", AGI = "Agi", STA = "Sta", INT = "Int", SPI = "Spi", AP = "AP", RAP = "RAP", CRIT = "Crit", HIT = "Hit",
  SP = "SP", HEAL = "Heal", SCRIT = "Crit", MP5 = "MP5", DEF = "Def", DODGE = "Dodge", PARRY = "Parry", BLOCK = "Block" }
ns.SHORT = SHORT

function ns.ItemStats(link)
  local f = (C_Item and C_Item.GetItemStats) or GetItemStats
  if type(f) ~= "function" or not link then return nil end
  local ok, t = pcall(f, link)
  if not ok or type(t) ~= "table" then return nil end
  local out = {}
  for key, v in pairs(t) do
    if type(key) == "string" and type(v) == "number" and v > 0 then
      for _, m in ipairs(MAP) do
        if key:find(m[1], 1, true) then out[m[2]] = (out[m[2]] or 0) + v; break end
      end
    end
  end
  return out
end

-- "good" (something your spec wants), "bad" (only things it doesn't), "meh" (a bit of use), or nil (no stats)
function ns.Verdict(stats, w)
  if not stats or not next(stats) then return nil end
  local good, meh = false, false
  for k in pairs(stats) do
    local v = w[k] or 0
    if v >= 0.5 then good = true elseif v >= 0.15 then meh = true end
  end
  if good then return "good" elseif meh then return "meh" end
  return "bad"
end

-- "+5 Agi +3 Sta": the stats your spec cares about first
function ns.StatText(stats, w)
  local list = {}
  for k, v in pairs(stats) do list[#list + 1] = { k, v } end
  table.sort(list, function(a, b) local x, y = w[a[1]] or 0, w[b[1]] or 0; if x ~= y then return x > y end return a[2] > b[2] end)
  local out = {}
  for i = 1, math.min(3, #list) do
    local k, v = list[i][1], list[i][2]
    local n = (k == "WDPS") and string.format("%.1f", v) or tostring(math.floor(v + 0.5))
    out[#out + 1] = (k == "WDPS" and "" or "+") .. n .. " " .. (ns.Tr and ns.Tr(SHORT[k] or k) or SHORT[k] or k)
  end
  return table.concat(out, "\n")   -- (1.1.0) one stat per line, so they stack neatly beside the slot
end
