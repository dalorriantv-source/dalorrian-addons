-- Dalorrian's Accents: early unlocks. Every unlockable accent also opens by milestone (messages sent);
-- each one has a fun secret way to open it sooner, and finding it earns a hidden award.
local ADDON, ns = ...
local date = date

local function Count(k, n) local DB = ns.DB; DB.ec[k] = (DB.ec[k] or 0) + (n or 1); return DB.ec[k] end
-- (1.2.0) a value the game hides (Forever does that in instances) reads as blank, never as an error
local function Plain(v) if v == nil or (issecretvalue and issecretvalue(v)) or type(v) ~= "string" then return "" end return v end
local function Zone() return Plain(GetRealZoneText and GetRealZoneText()) end
local function SubZone() return Plain(GetSubZoneText and GetSubZoneText()) end
local function Occur(text, word) local _, n = text:lower():gsub("%f[%a]" .. word .. "%f[%A]", ""); return n end

local CITIES = { ["Stormwind City"] = true, ["Ironforge"] = true, ["Darnassus"] = true, ["Orgrimmar"] = true,
  ["Thunder Bluff"] = true, ["Undercity"] = true, ["Valanaar"] = true }
local OGRE = { ["Dustwallow Marsh"] = true, ["Feralas"] = true, ["Alterac Mountains"] = true, ["Burning Steppes"] = true,
  ["Dire Maul"] = true, ["Badlands"] = true }

-- key -> test on each accented message (key = accent used, where = chat, text = what you typed)
ns.EARLY = {
  pirate = function(text) local s, z = SubZone(), Zone(); return s == "Booty Bay" or s == "Ratchet" or z == "Booty Bay" or z == "Ratchet" end,
  goblin = function(text) return Count("gold", Occur(text, "gold")) >= 10 end,
  murloc = function(text) return text:lower():find("mrgl", 1, true) ~= nil end,
  kobold = function(text) return text:lower():find("you no take candle", 1, true) ~= nil end,
  -- (1.2.0) also any ogre camp by name ("Vul'Gol Ogre Mound" in Duskwood, "Mo'grosh Stronghold"...)
  ogre = function(text) local s = SubZone():lower(); return OGRE[Zone()] == true or s:find("ogre", 1, true) ~= nil or s:find("mo'grosh", 1, true) ~= nil end,
  bard = function(text)
    local z = Zone()
    if CITIES[z] then local DB = ns.DB; DB.ec.cities = DB.ec.cities or {}; DB.ec.cities[z] = true end
    local n = 0
    for _ in pairs(ns.DB.ec.cities or {}) do n = n + 1 end
    return n >= 3
  end,
  noir = function(text) local h = tonumber(date("%H")); return h ~= nil and h < 5 end,
  sergeant = function(text)
    local letters = text:gsub("[^%a]", "")
    if #letters < 6 or letters:upper() ~= letters then return false end
    return Count("caps5") >= 5
  end,
  epic = function(text) return #text > 150 end,
  wry = function(text) return Count("probably", Occur(text, "probably")) >= 5 end,
  -- the fantasy and silly ones
  wizard = function(text) return text:lower():find("abracadabra", 1, true) ~= nil end,
  -- (1.2.0) mines, quarries and dig sites ("Fargodeep Mine", "Gold Coast Quarry", "Bael Modan Excavation"), and the Deadmines
  prospector = function(text)
    local s, z = SubZone():lower(), Zone():lower()
    for _, w in ipairs({ "mine", "quarry", "excavation", "dig site" }) do if s:find(w, 1, true) or z:find(w, 1, true) then return true end end
    return false
  end,
  caveman = function(text) local _, n = text:gsub("%S+", ""); if n > 2 then return false end; return Count("short") >= 10 end,
  robot = function(text) return text:lower():find("beep boop", 1, true) ~= nil end,
  peasant = function(text) return GetMoney and GetMoney() < 10000 and (UnitLevel("player") or 1) >= 20 end,
  cowboy = function(text) return Occur(text, "howdy") > 0 end,
  surfer = function(text) return IsSwimming and IsSwimming() and true or false end,
  butler = function(text) local n = Occur(text, "please") + Occur(text, "thanks") + select(2, text:lower():gsub("thank you", "")); return Count("polite", n) >= 10 end,
  grumpy = function(text) return text:lower():find("back in my day", 1, true) ~= nil end,
  valley = function(text) return Count("like", Occur(text, "like")) >= 20 end,
  conspiracy = function(text) return text:lower():find("wake up", 1, true) ~= nil end,
  announcer = function(text) if not text:find("!!") then return false end; return Count("bang") >= 5 end,
}

function ns.OpenEarly(key)
  local DB = ns.DB
  if DB.early[key] or ns.IsUnlocked(key) then return end
  DB.early[key] = true
  local d = ns.ACCENTS[key]
  if ns.Toast then ns.Toast("Secret unlock!", d.name, d.blurb or "", d.icon) end
  if ns.Announce then ns.Announce(string.format(ns.Tr and ns.Tr("unlocked %s") or "unlocked %s", ns.Tr and ns.Tr(d.name) or d.name)) end
end

function ns.CheckEarly(key, where, text)
  if type(text) ~= "string" then return end
  for k, test in pairs(ns.EARLY) do
    if ns.ACCENTS[k] and not ns.DB.early[k] then
      local ok, hit = pcall(test, text)
      if ok and hit and not ns.IsUnlocked(k) then ns.OpenEarly(k) end
    end
  end
end

-- the two that come from the game, not from chat
function ns.EarlyEvent(e, a1, a2, a3, a4, a5)
  if not (ns.CDB and ns.CDB.on) then return end
  if e == "PLAYER_DEAD" then
    if Count("deaths") >= 3 and not ns.IsUnlocked("grimdark") then ns.OpenEarly("grimdark") end
  elseif e == "ENCOUNTER_END" or e == "BOSS_KILL" then
    -- encounterID, name, difficulty, groupSize, success (BOSS_KILL is the backup where ENCOUNTER_END doesn't fire).
    -- (1.2.0) Forever can hide "success": a hidden one counts as a kill when the fight ended in a dungeon
    local inInstance, kind = IsInInstance()
    local won = e == "BOSS_KILL" or (issecretvalue and issecretvalue(a5)) or a5 == 1
    if won and inInstance and (kind == "party" or kind == "raid") and not ns.IsUnlocked("raidboss") then ns.OpenEarly("raidboss") end
  end
  if ns.CheckAwards then ns.CheckAwards() end
end
