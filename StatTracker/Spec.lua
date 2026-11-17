-- Dalorrian's Stat Tracker (1.1.0): what each class and spec wants, and what your gear gives you.
-- Weights: 1 is what you want most, 0 does nothing for you. The game's own talent tab names are used when it has them.

local ADDON, ns = ...
-- (Forever) in dungeons and raids the game hides some values from addons ("secret values"), and touching one
-- is an error. These stand-ins hand back nil instead, so the addon quietly skips what it isn't allowed to see.
local issecretvalue = issecretvalue or function() return false end
local function AnySecret(...)
  for i = 1, select("#", ...) do if issecretvalue((select(i, ...))) then return true end end
  return false
end
local function Unsecret(a, b, c, d, e, ...)
  if issecretvalue(a) then a = nil end
  if issecretvalue(b) then b = nil end
  if issecretvalue(c) then c = nil end
  if issecretvalue(d) then d = nil end
  if issecretvalue(e) then e = nil end
  if select("#", ...) > 0 then return a, b, c, d, e, ... end
  return a, b, c, d, e
end
local function SafeApi(f) return f and function(...) return Unsecret(f(...)) end end
local UnitName = SafeApi(UnitName)

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

---------------------------------------------------------------------------
-- (1.3.0) enchants: the game leaves them out of an item's own stats, so they're read from the item's tooltip
---------------------------------------------------------------------------
-- the stat names, in English and in your game's language, to their short keys
local ENCH_WORDS = {
  ["agility"] = "AGI", ["strength"] = "STR", ["stamina"] = "STA", ["intellect"] = "INT", ["spirit"] = "SPI",
  ["attack power"] = "AP", ["ranged attack power"] = "RAP", ["spell power"] = "SP", ["spell damage"] = "SP",
  ["damage and healing spells"] = "SP", ["healing"] = "HEAL", ["healing spells"] = "HEAL", ["defense"] = "DEF",
  ["dodge"] = "DODGE", ["parry"] = "PARRY", ["block"] = "BLOCK", ["haste"] = "HASTE", ["hit"] = "HIT", ["critical strike"] = "CRIT",
  ["mana every 5 seconds"] = "MP5", ["mana per 5 sec."] = "MP5", ["mana regen"] = "MP5", ["all stats"] = "ALL",
  ["armor"] = "ARMOR", ["health"] = "HP", ["mana"] = "MANA",
}
for k, v in pairs({ STRENGTH = "STR", AGILITY = "AGI", STAMINA = "STA", INTELLECT = "INT", SPIRIT = "SPI" }) do
  local g = _G["ITEM_MOD_" .. k .. "_SHORT"] or _G["SPELL_STAT" .. ({ STR = 1, AGI = 2, STA = 3, INT = 4, SPI = 5 })[v] .. "_NAME"]
  if type(g) == "string" and g ~= "" then ENCH_WORDS[g:lower()] = v end
end
SHORT.ALL = "All Stats"; SHORT.ARMOR = "Armor"; SHORT.HP = "Health"; SHORT.MANA = "Mana"

-- (1.3.2) the tooltip's lines for a slot: { text, r, g, b, type }. A hidden game tooltip first (it always has
-- the text and colors), then C_TooltipInfo, whose lines can come without text on Forever
local scan
local function ScanLines(slot)
  local out = {}
  if not CreateFrame then return out end
  local owner = WorldFrame or UIParent
  if not scan then scan = CreateFrame("GameTooltip", "StatTrackerScanTip", nil, "GameTooltipTemplate") end
  scan:SetOwner(owner, "ANCHOR_NONE")
  scan:ClearLines()
  local ok, has = pcall(scan.SetInventoryItem, scan, "player", slot)
  if not ok then return out end
  for i = 1, scan:NumLines() do
    local fs = _G["StatTrackerScanTipTextLeft" .. i]
    if fs then
      local r, g, b = fs:GetTextColor()
      out[#out + 1] = { fs:GetText(), r, g, b }
    end
  end
  scan:Hide()
  return out
end
local function InfoLines(slot)
  local out = {}
  if not (C_TooltipInfo and C_TooltipInfo.GetInventoryItem) then return out end
  local ok, data = pcall(C_TooltipInfo.GetInventoryItem, "player", slot)
  if not ok or type(data) ~= "table" or type(data.lines) ~= "table" then return out end
  for _, l in ipairs(data.lines) do
    if TooltipUtil and TooltipUtil.SurfaceArgs and l.leftText == nil then pcall(TooltipUtil.SurfaceArgs, l) end
    local c = l.leftColor
    out[#out + 1] = { l.leftText, c and c.r, c and c.g, c and c.b, l.type }
  end
  return out
end
local function HasText(t) for _, l in ipairs(t) do if type(l[1]) == "string" and l[1] ~= "" then return true end end end
local function TipLines(slot)
  local t = ScanLines(slot)
  if HasText(t) then return t end
  return InfoLines(slot)
end
ns.TipLines = TipLines

-- (1.3.1) item effects in green that are the item's own, not an enchant
local OWN = { "^Equip:", "^Use:", "^Chance on hit:", "^%(" }
for _, g in ipairs({ ITEM_SPELL_TRIGGER_ONEQUIP, ITEM_SPELL_TRIGGER_ONUSE, ITEM_SPELL_TRIGGER_ONPROC }) do
  if type(g) == "string" and g ~= "" then OWN[#OWN + 1] = "^" .. g:gsub("%p", "%%%0") end
end
local STOP = { "^Durability", "^Requires", "^Classes:", "^Races:" }
for _, g in ipairs({ DURABILITY_TEMPLATE, ITEM_MIN_LEVEL, ITEM_CLASSES_ALLOWED, ITEM_RACES_ALLOWED }) do
  if type(g) == "string" and g ~= "" then local p = g:match("^([^%%]+)"); if p and #p > 2 then STOP[#STOP + 1] = "^" .. p:gsub("%p", "%%%0") end end
end
local function Any(t, list) for _, p in ipairs(list) do if t:find(p) then return true end end end

local function EnchantLine(slot)
  local lines = TipLines(slot)
  local ET = Enum and Enum.TooltipDataLineType and Enum.TooltipDataLineType.ItemEnchantmentPermanent
  local prefix = type(ENCHANTED_TOOLTIP_LINE) == "string" and ENCHANTED_TOOLTIP_LINE:match("^(.-)%%s") or "Enchanted: "
  for i, l in ipairs(lines) do
    local t = l[1]
    if i > 1 and type(t) == "string" and not issecretvalue(t) and t ~= "" then
      if ET and l[5] == ET then return (t:gsub("^" .. prefix:gsub("%p", "%%%0"), "")) end
      if prefix ~= "" and t:sub(1, #prefix) == prefix then return t:sub(#prefix + 1) end
      -- Classic tooltips: the enchant is the green line above durability ("+7 Agility", "Crusader", "Healing Power").
      -- The item's own green lines (Equip:, Use:) come after it, so stop there
      if Any(t, STOP) then return nil end
      local r, g, b = l[2], l[3], l[4]
      if type(g) == "number" and g > 0.9 and r < 0.3 and b < 0.3 and not Any(t, OWN) then return t end
    end
  end
end
ns.EnchantLine = EnchantLine

-- (1.3.0) every WoW: Forever enchant by the name the game may show, per slot, with what it does (short).
-- Slots: 2 neck, 15 back, 5 chest, 9 wrist, 10 hands, 8 feet, 16 main hand (one-hand and two-hand), 17 off hand / shield.
local FOREVER = {
  [2] = { ["agility"] = { "+5 Agi", { AGI = 5 } }, ["deflection"] = { "+5 Def", { DEF = 5 } }, ["strength"] = { "+5 Str", { STR = 5 } },
    ["spell power"] = { "+6 SP", { SP = 6 } }, ["healing power"] = { "+11 Heal +4 SP", { HEAL = 11, SP = 4 } } },
  [15] = { ["greater resistance"] = { "+5 All Res" }, ["superior defense"] = { "+70 Armor", { ARMOR = 70 } }, ["superior defence"] = { "+70 Armor", { ARMOR = 70 } },
    ["agility"] = { "+5 Agi", { AGI = 5 } }, ["dodge"] = { "+1% Dodge", { DODGE = 1 } }, ["greater fire resistance"] = { "+15 Fire Res" },
    ["greater nature resistance"] = { "+15 Nature Res" }, ["stealth"] = { "+1 Stealth" }, ["subtlety"] = { "-2% Threat" } },
  [5] = { ["absorption"] = { "Absorb 50" }, ["major stamina"] = { "+10 Sta", { STA = 10 } }, ["major intellect"] = { "+10 Int", { INT = 10 } },
    ["greater stats"] = { "+4 All Stats", { STR = 4, AGI = 4, STA = 4, INT = 4, SPI = 4 } } },
  [9] = { ["mana regeneration"] = { "+4 MP5", { MP5 = 4 } }, ["superior agility"] = { "+9 Agi", { AGI = 9 } }, ["superior strength"] = { "+9 Str", { STR = 9 } },
    ["greater spellpower"] = { "+16 SP", { SP = 16 } }, ["greater spell power"] = { "+16 SP", { SP = 16 } }, ["healing power"] = { "+24 Heal +8 SP", { HEAL = 24, SP = 8 } },
    ["superior deflection"] = { "+4 Def", { DEF = 4 } }, ["superior intellect"] = { "+9 Int", { INT = 9 } }, ["superior stamina"] = { "+9 Sta", { STA = 9 } } },
  [10] = { ["advanced mining"] = { "+5 Mining" }, ["advanced herbalism"] = { "+5 Herbalism" }, ["advanced skinning"] = { "+10 Skinning" },
    ["minor haste"] = { "+1% Haste", { HASTE = 1 } }, ["riding skill"] = { "Mount Speed" }, ["lotus claw"] = { "Death Lotus" },
    ["arcane power"] = { "+20 Arcane" }, ["fire power"] = { "+20 Fire" }, ["frost power"] = { "+20 Frost" }, ["holy power"] = { "+20 Holy" },
    ["natural power"] = { "+20 Nature" }, ["nature power"] = { "+20 Nature" }, ["shadow power"] = { "+20 Shadow" },
    ["healing power"] = { "+35 Heal +12 SP", { HEAL = 35, SP = 12 } }, ["superior strength"] = { "+15 Str", { STR = 15 } },
    ["superior agility"] = { "+15 Agi", { AGI = 15 } }, ["threat"] = { "+2% Threat" } },
  [8] = { ["minor speed"] = { "Run Speed" }, ["greater stamina"] = { "+7 Sta", { STA = 7 } }, ["spirit"] = { "+5 Spi", { SPI = 5 } },
    ["greater agility"] = { "+7 Agi", { AGI = 7 } } },
  [16] = { ["insight"] = { "Insight" }, ["recovery"] = { "Recovery" }, ["revelation"] = { "Revelation" }, ["lesser beastslayer"] = { "Beastslayer" },
    ["lesser elemental slayer"] = { "Elemental Slayer" }, ["winter's might"] = { "+15 Frost" }, ["demonslaying"] = { "Demonslaying" },
    ["fiery weapon"] = { "Fiery" }, ["icy chill"] = { "Icy Chill" }, ["unholy weapon"] = { "Unholy" }, ["crusader"] = { "Crusader" },
    ["lifestealing"] = { "Lifestealing" }, ["mighty intellect"] = { "+22 Int", { INT = 22 } }, ["mighty spirit"] = { "+22 Spi", { SPI = 22 } },
    ["spell power"] = { "+30 SP", { SP = 30 } }, ["superior striking"] = { "+5 Dmg" }, ["healing power"] = { "+55 Heal +19 SP", { HEAL = 55, SP = 19 } },
    ["agility"] = { "+15 Agi", { AGI = 15 } }, ["strength"] = { "+15 Str", { STR = 15 } },
    -- two-handers (the same names on a two-hander are bigger: handled in EnchantInfo)
    ["superior impact"] = { "+9 Dmg" }, ["major intellect"] = { "+9 Int", { INT = 9 } }, ["major spirit"] = { "+9 Spi", { SPI = 9 } },
    ["mighty healing power"] = { "+100 Heal +34 SP", { HEAL = 100, SP = 34 } }, ["mighty spell power"] = { "+55 SP", { SP = 55 } },
    ["spellblasting"] = { "+65 SP", { SP = 65 } } },
  [17] = { ["superior spirit"] = { "+9 Spi", { SPI = 9 } }, ["critical strike"] = { "+1% Crit", { CRIT = 1 } }, ["excellent stamina"] = { "+12 Sta", { STA = 12 } },
    ["excellent spirit"] = { "+12 Spi", { SPI = 12 } }, ["superior intellect"] = { "+9 Int", { INT = 9 } }, ["wisdom"] = { "+6 Int +5 Spi", { INT = 6, SPI = 5 } } },
}
local TWO_HAND = { ["strength"] = { "+25 Str", { STR = 25 } }, ["agility"] = { "+25 Agi", { AGI = 25 } } }
ns.FOREVER_ENCHANTS = FOREVER

local function IsTwoHand(slot)
  if slot ~= 16 then return false end
  local link = GetInventoryItemLink and GetInventoryItemLink("player", 16)
  if not link or issecretvalue(link) then return false end
  local f = (C_Item and C_Item.GetItemInfo) or GetItemInfo
  local ok, _, _, _, _, _, _, _, _, equip = pcall(f, link)
  return ok and equip == "INVTYPE_2HWEAPON"
end

-- { stats = { AGI = 7 }, text = "+7 Agi" } or { text = "Crusader" } or nil
function ns.EnchantInfo(slot)
  local okLine, line = pcall(EnchantLine, slot)
  if not okLine then line = nil end
  if not line then return nil end
  -- a Forever enchant the game shows by name ("Healing Power", "Greater Stats"): use what it really does on this slot
  local key = line:lower():gsub("^enchant [%a%- ]+ %- ", ""):gsub("%s+$", ""):gsub("\226\128\153", "'")
  local known = (IsTwoHand(slot) and TWO_HAND[key]) or (FOREVER[slot] and FOREVER[slot][key])
  if not known and slot == 16 then known = FOREVER[17][key] end
  if known then
    local st = {}
    for k, v in pairs(known[2] or {}) do st[k] = v end
    local txt = known[1]:gsub("(%a[%a ]*)", function(w) return ns.Tr and ns.Tr(w) or w end)
    return { stats = st, text = txt }
  end
  local stats, parts = {}, {}
  -- "+1% Dodge", "+15 Fire Resistance", "Healing +24"
  for pct, name in line:gmatch("%+(%d+)%%%s+([^,%+]+)") do
    name = name:gsub("%s+$", ""):gsub("%.$", ""):gsub(" and$", "")
    parts[#parts + 1] = "+" .. pct .. "% " .. name
  end
  local nameFirst = false
  for name, n in line:gmatch("(%a[%a ]-)%s+%+(%d+)") do
    name = name:gsub("^and ", ""):gsub("^[Ss]pell [Dd]amage$", "spell damage")
    local k = ENCH_WORDS[name:lower()]
    if k then nameFirst = true; stats[k] = (stats[k] or 0) + tonumber(n); parts[#parts + 1] = "+" .. n .. " " .. (ns.Tr and ns.Tr(SHORT[k] or k) or SHORT[k] or k) end
  end
  for n, name in (nameFirst and "" or line):gmatch("%+(%d+)%s+([^,%+%%]+)") do
    local raw = name:gsub("%s+$", ""):gsub("%.$", ""):gsub(" and$", "")
    name = name:gsub("%s+$", ""):gsub("%.$", ""):lower()
    local key = ENCH_WORDS[name]
    if not key then for w, k in pairs(ENCH_WORDS) do if name:find(w, 1, true) then key = k; break end end end
    if key then
      stats[key] = (stats[key] or 0) + tonumber(n)
      parts[#parts + 1] = "+" .. n .. " " .. (ns.Tr and ns.Tr(SHORT[key] or key) or SHORT[key] or key)
    else
      -- resistances, weapon damage, skills: keep the game's words, shortened
      local short = raw:gsub("[Rr]esistances?", "Res"):gsub("[Ww]eapon [Dd]amage", "Dmg"):gsub("^[Dd]amage$", "Dmg"):gsub("[Ss]pell [Dd]amage", "SP")
      parts[#parts + 1] = "+" .. n .. " " .. short
    end
  end
  local text = #parts > 0 and table.concat(parts, " ") or line
  if #text > 18 then text = text:sub(1, 17) .. "." end
  return { stats = stats, text = text }
end
