-- Dalorrian's Crit Numbers (folder CritSounds): a big number, and an optional sound, every time you crit.
-- The number pops over the mob you hit (keep enemy nameplates on), or in the middle of the screen when it can't
-- find the mob's nameplate (heals, nameplates off). /crits for options.

local ADDON, ns = ...
local DB
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local NUMFONT = DAMAGE_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local DEFAULTS = { sound = true, pack = nil, volume = 100, numbers = true, size = 48, shake = 1, heals = true, pet = true, gap = 0, replace = true }
local P = ns.print or print
local function Say(msg) P("|cffffd100Crit Numbers:|r " .. msg) end
local Tip = ns.Tip or GameTooltip

---------------------------------------------------------------------------
-- sound packs. Crit sounds come from outside the game: CC0 sounds and clips Dalorrian records.
-- Other addons add packs with:
--   CritSounds_AddPack("Label", "Interface\\AddOns\\YourAddon\\Sounds\\folder", { "clip1", "clip2" }, { "streak2", "streak3" })
-- clip names without .ogg/.mp3. The optional streak list plays in order when crits come close together
-- (the 2nd crit within 4 seconds plays the first one, the 3rd the second, and so on).
-- For the Volume slider, put quieter copies in folder\v10 .. folder\v90 (same names).
---------------------------------------------------------------------------
local PACKS = {}   -- { label, key, path, clips, streak }
local soundSetting
function CritSounds_AddPack(label, path, clips, streak)
  if type(label) ~= "string" or type(path) ~= "string" or type(clips) ~= "table" or #clips == 0 then return end
  local key = label:lower():gsub("[^%w]+", "_")
  for _, p in ipairs(PACKS) do if p.key == key then return end end
  PACKS[#PACKS + 1] = { label = label, key = key, path = path, clips = clips, streak = type(streak) == "table" and streak or nil }
  if soundSetting then table.insert(soundSetting.choices, #soundSetting.choices + 1, { label, key }) end
end
-- (1.1.0) the Dalorrian Pack ships with the addon: Dalorrian's own crit lines
CritSounds_AddPack("Dalorrian Pack", "Interface\\AddOns\\CritSounds\\Sounds\\dalorrian", { "all_day", "boing", "boom", "booty",
  "crit_snozeberries", "critcritcrit", "damage", "gewww", "ho_yeh", "nice", "schwing", "skeet" })
local function Pack(key)
  for _, p in ipairs(PACKS) do if p.key == key then return p end end
  return PACKS[1]   -- the saved pack is gone (its addon is off): the first one there is
end

local playing, lastSound, lastClip = nil, 0, {}
local streakN, streakT = 0, 0
local function PlayFile(path)
  if not PlaySoundFile then return end
  local ok, played, handle = pcall(PlaySoundFile, path .. ".ogg", "Master")
  if not (ok and played) then ok, played, handle = pcall(PlaySoundFile, path .. ".mp3", "Master") end
  if ok and played then playing = handle; return true end
end
local function Play(p, clip)
  if playing and StopSound then pcall(StopSound, playing, 0) end   -- the new crit cuts the old sound off
  playing = nil
  local vol = DB.volume or 100
  if vol >= 100 or not PlayFile(p.path .. "\\v" .. vol .. "\\" .. clip) then PlayFile(p.path .. "\\" .. clip) end
end
local function Sound(preview)
  local p = Pack(DB.pack)
  if not p then return end
  local now = GetTime()
  if not preview and (now - lastSound) < (DB.gap or 0) then return end
  lastSound = now
  -- a streak: crits close together climb the pack's streak list
  if not preview and p.streak and now - streakT <= 4 then streakN = streakN + 1 else streakN = 1 end
  streakT = now
  if not preview and p.streak and streakN >= 2 then
    Play(p, p.streak[math.min(streakN - 1, #p.streak)])
    return
  end
  local n = #p.clips
  local pick = math.random(n)
  if n > 1 and pick == lastClip[p.key] then pick = pick % n + 1 end   -- never the same one twice in a row
  lastClip[p.key] = pick
  Play(p, p.clips[pick])
end

---------------------------------------------------------------------------
-- the big numbers: pop in large, shake, float up and fade
---------------------------------------------------------------------------
local holder = CreateFrame("Frame", "CritSoundsFrame", UIParent)
holder:SetAllPoints()
holder:SetFrameStrata("HIGH")
local pool, live = {}, {}
local function Commas(n)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  local s = tostring(n)
  while true do
    local t, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
    s = t
    if k == 0 then return s end
  end
end
local function GetNum()
  local f = table.remove(pool)
  if f then return f end
  f = CreateFrame("Frame", nil, holder)
  f:SetSize(10, 10)
  f.text = f:CreateFontString(nil, "OVERLAY")
  f.text:SetPoint("CENTER")
  f.text:SetShadowColor(0, 0, 0, 1)
  f.text:SetShadowOffset(2, -2)
  return f
end
local SHAKE = { [0] = 0, [1] = 7, [2] = 14 }
local LIFE = 1.3
local function Tick(f, el)
  f.t = f.t + el
  local t = f.t
  if f.small then   -- (1.3.0) a normal hit: drifts up and fades, the way the game's own numbers do
    if t >= 1.1 then
      f:SetScript("OnUpdate", nil); f:Hide(); f:ClearAllPoints(); f.small = nil
      live[f] = nil; pool[#pool + 1] = f
      return
    end
    f:SetScale(1)
    f:SetAlpha(t > 0.6 and math.max(0, 1 - (t - 0.6) / 0.5) or 1)
    f:ClearAllPoints()
    f:SetPoint("BOTTOM", f.anchor, f.anchor == holder and "CENTER" or "TOP", f.x, f.y + 24 + t * 55)
    return
  end
  if t >= LIFE then
    f:SetScript("OnUpdate", nil); f:Hide(); f:ClearAllPoints()
    live[f] = nil; pool[#pool + 1] = f
    return
  end
  -- pop: starts big and snaps down to size in the first moment
  local pop = t < 0.12 and (1.7 - (t / 0.12) * 0.7) or 1
  f:SetScale(math.max(0.01, pop))
  -- shake: strong at first, dying out by 0.45 seconds
  local amp = 0   -- (1.3.3) no shaking: the number pops in big and floats away
  local dx = amp > 0 and (math.random() * 2 - 1) * amp or 0
  local dy = amp > 0 and (math.random() * 2 - 1) * amp or 0
  -- float up and fade once the shaking is done
  local rise = t > 0.45 and (t - 0.45) * 40 or 0
  f:SetAlpha(t > 0.8 and math.max(0, 1 - (t - 0.8) / (LIFE - 0.8)) or 1)
  f:ClearAllPoints()
  f:SetPoint("BOTTOM", f.anchor, f.anchor == holder and "CENTER" or "TOP", (f.x + dx) / pop, (f.y + 24 + rise + dy) / pop)
end
local function PlateFor(guid)
  if not (guid and C_NamePlate and C_NamePlate.GetNamePlates) then return end
  for _, plate in ipairs(C_NamePlate.GetNamePlates()) do
    local u = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    if u and UnitGUID(u) == guid and not (plate.IsForbidden and plate:IsForbidden()) then return plate end
  end
end
-- (1.3.10) crit colors to pick from in Settings & Help (red is damage you take, pink is experience, green is heals)
local CRIT_COLORS = { purple = { 0.72, 0.4, 1 }, orange = { 1, 0.6, 0.1 }, gold = { 1, 0.82, 0 },
  cyan = { 0.3, 0.9, 1 }, red = { 1, 0.2, 0.2 }, pink = { 1, 0.35, 0.8 }, white = { 1, 1, 1 }, lime = { 0.6, 1, 0.2 } }
local function ShowNumber(amount, heal, guid)
  local f = GetNum()
  local plate = PlateFor(guid)
  f.anchor = plate or holder
  -- crits on the same mob stack upward a little so they don't sit on top of each other
  local same = 0
  for o in pairs(live) do if o.anchor == f.anchor then same = same + 1 end end
  f.x = (math.random() * 2 - 1) * 18
  f.y = (plate and 0 or 120) + math.min(same, 4) * ((DB.size or 64) * 0.6)
  f.text:SetFont(NUMFONT, DB.size or 64, "THICKOUTLINE")
  if heal then f.text:SetTextColor(0.3, 1, 0.35) else f.text:SetTextColor(unpack(CRIT_COLORS[DB.critColor or "purple"] or CRIT_COLORS.purple)) end   -- (1.3.10) Crit Color
  f.text:SetText(Commas(math.floor(amount + 0.5)))
  f.small = nil
  f.t = 0
  live[f] = true
  f:SetAlpha(1)
  f:Show()
  Tick(f, 0)
  f:SetScript("OnUpdate", Tick)
end

-- (1.3.0) a normal hit, small and plain like the game's: white for weapon hits, yellow for spells
local function ShowSmall(amount, guid, school)
  local f = GetNum()
  local plate = PlateFor(guid)
  f.anchor = plate or holder
  f.small = true
  f.x = (math.random() * 2 - 1) * 26
  f.y = plate and 0 or 120
  f.text:SetFont(NUMFONT, DB.hitSize or 28, "OUTLINE")   -- (1.3.6) Hit Number Size
  if school and school ~= 1 then f.text:SetTextColor(1, 0.88, 0.25) else f.text:SetTextColor(1, 1, 1) end
  f.text:SetText(Commas(math.floor(amount + 0.5)))
  f.t = 0
  live[f] = true
  f:SetAlpha(1)
  f:Show()
  Tick(f, 0)
  f:SetScript("OnUpdate", Tick)
end

-- (1.3.0) Crit Sounds draws every hit, so the game's own damage numbers are switched off (they'd show twice).
-- Your old setting is kept and put back if you pick The Game's, or turn Crit Sounds or its numbers off.
local function Replacing() return DB and DB.replace and DB.numbers and not DB.off end
-- (1.3.4) newer clients keep these under "_v2" names, and DoT ticks and pet hits have their own: all of them
-- go off, or your numbers show twice
local FCT = { "floatingCombatTextCombatDamage", "floatingCombatTextCombatLogPeriodicSpells",
  "floatingCombatTextPetMeleeDamage", "floatingCombatTextPetSpellDamage" }
local function GameNumbers()
  local get = (C_CVar and C_CVar.GetCVar) or GetCVar
  local set = (C_CVar and C_CVar.SetCVar) or SetCVar
  if not (get and set) then return end
  if type(DB.savedFCT) ~= "table" then   -- 1.3.0 kept one value
    local old = DB.savedFCT
    DB.savedFCT = nil
    if old ~= nil then DB.savedFCT = { floatingCombatTextCombatDamage = old, floatingCombatTextCombatDamage_v2 = old } end
  end
  if Replacing() then
    local saved = DB.savedFCT or {}
    for _, base in ipairs(FCT) do
      for _, name in ipairs({ base, base .. "_v2" }) do
        local ok, v = pcall(get, name)
        if ok and v ~= nil then
          if saved[name] == nil then saved[name] = tostring(v) end
          pcall(set, name, "0")
        end
      end
    end
    DB.savedFCT = saved
  elseif DB.savedFCT then
    for name, v in pairs(DB.savedFCT) do pcall(set, name, v) end
    DB.savedFCT = nil
  end
end

-- (1.3.2) Screen Shake is gone: the big number still shakes on its own

---------------------------------------------------------------------------
-- watching for crits
---------------------------------------------------------------------------
local me, pet
local function Crit(amount, heal, dest)
  if not DB or DB.off then return end
  local readable = type(amount) == "number" and pcall(function() return amount > 0 end)   -- (1.2.2) the game can hide the number
  if readable and amount <= 0 then return end
  if heal and not DB.heals then return end
  if DB.numbers and readable then ShowNumber(amount, heal, dest) end
  if DB.sound then Sound() end
end
local seen = { hits = 0, crits = 0 }   -- (1.1.1) for /crits debug
local function OnCombat()
  local _, sub, _, src, _, _, _, dest = CombatLogGetCurrentEventInfo()
  if not src then return end
  me = me or UnitGUID("player")
  if src ~= me and not (DB.pet and pet and src == pet) then return end
  if sub == "SWING_DAMAGE" or sub == "RANGE_DAMAGE" or sub == "SPELL_DAMAGE" then
    seen.hits = seen.hits + 1
    local c = select(sub == "SWING_DAMAGE" and 18 or 21, CombatLogGetCurrentEventInfo())
    if c then seen.crits = seen.crits + 1 end
    seen.last = sub .. " " .. tostring(select(sub == "SWING_DAMAGE" and 12 or 15, CombatLogGetCurrentEventInfo())) .. " crit=" .. tostring(c)
  end
  if sub == "SWING_DAMAGE" then
    local amount, _, _, _, _, _, crit = select(12, CombatLogGetCurrentEventInfo())
    if crit then Crit(amount, false, dest) end
  elseif sub == "RANGE_DAMAGE" or sub == "SPELL_DAMAGE" or sub == "SPELL_PERIODIC_DAMAGE" then
    local amount, _, _, _, _, _, crit = select(15, CombatLogGetCurrentEventInfo())
    if crit then Crit(amount, false, dest) end
  elseif sub == "SPELL_HEAL" or sub == "SPELL_PERIODIC_HEAL" then
    local amount, _, _, crit = select(15, CombatLogGetCurrentEventInfo())
    if crit then Crit(amount, true, dest) end
  end
end

---------------------------------------------------------------------------
-- (1.2.1) WoW: Forever doesn't let addons read the combat log events at all, so crits are read from the
-- combat log lines the game writes in your chat ("Your Arcane Shot hit Boar 56 Arcane. (Critical)").
-- Only lines that start with You/Your count, so crits on you or from other players never set it off.
---------------------------------------------------------------------------
local CRIT_MARK = TEXT_MODE_A_STRING_RESULT_CRITICAL or "(Critical)"
local CRIT_SPELL = TEXT_MODE_A_STRING_RESULT_CRITICAL_SPELL
local YOU = { UNIT_YOU_SOURCE_POSSESSIVE or "Your", UNIT_YOU_SOURCE or "You" }
local HEALS = { "heal", "Heal" }
local function Clean(t)
  t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
  return (t:gsub("^%s+", ""))
end
local lastLine, lastAt = nil, 0
local function ReadLine(text)
  if type(text) ~= "string" then return end
  seen.lines = (seen.lines or 0) + 1
  local at = text:find(CRIT_MARK, 1, true) or (CRIT_SPELL and text:find(CRIT_SPELL, 1, true))
  if not at then return end
  local t = Clean(text)
  local mine = false
  for _, y in ipairs(YOU) do if t:sub(1, #y) == y and t:sub(#y + 1, #y + 1):match("[%s']") then mine = true end end
  if not mine then return end
  -- one line can show up in two chat windows: count it once
  local now = GetTime()
  if t == lastLine and now - lastAt < 0.2 then return end
  lastLine, lastAt = t, now
  local body = t:sub(1, (t:find(CRIT_MARK, 1, true) or #t + 1) - 1):gsub("%b()", "")
  local amount
  for n in body:gmatch("%d[%d,%.]*") do amount = n end
  amount = amount and tonumber((amount:gsub("[,%.]", "")))
  if not amount then return end
  local heal = false
  for _, h in ipairs(HEALS) do if body:find(h, 1, true) then heal = true end end
  seen.hits = seen.hits + 1; seen.crits = seen.crits + 1
  seen.chat = (seen.chat or 0) + 1
  seen.last = t
  local guid
  pcall(function() guid = UnitExists("target") and UnitGUID("target") or nil end)
  Crit(amount, heal, guid)
end
local hooked = {}
local function HookChat()
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local f = _G["ChatFrame" .. i]
    if f and not hooked[f] and f.AddMessage then
      hooked[f] = true
      hooksecurefunc(f, "AddMessage", function(_, text)
        if DB and not DB.off then
          local ok = pcall(ReadLine, text)
          if not ok then seen.secret = (seen.secret or 0) + 1 end
        end
      end)
    end
  end
end

-- (1.2.2) the other way in: the game tells unit frames when your target takes a crit (the same feed as the
-- numbers on a target portrait). Used when the chat lines can't be read. In a group it only counts while
-- you're attacking or just cast something, so other players' crits mostly stay quiet.
local acted = 0
-- (1.2.4) this client keeps these checks under C_Spell; the old names always said "no"
local function On(f, id)
  if not f then return false end
  local ok, v = pcall(f, id)
  return ok and v and true or false
end
local function Acting()
  if GetTime() - acted < 1.5 then return true end
  local cur = (C_Spell and C_Spell.IsCurrentSpell) or IsCurrentSpell
  local rep = (C_Spell and C_Spell.IsAutoRepeatSpell) or IsAutoRepeatSpell
  return On(cur, 6603) or On(rep, 75) or On(rep, 5019)   -- auto attack, Auto Shot, Shoot
end
-- (1.3.1) every mob with a nameplate counts too, not just your target, so AoE (Consecration, Multi-Shot,
-- Arcane Explosion) gets numbers. Keep enemy nameplates on to see them.
local function Which(unit)
  if unit == "target" then return "target" end
  if type(unit) == "string" and unit:match("^nameplate%d+$") then
    local same = false
    pcall(function() same = UnitIsUnit(unit, "target") end)
    if not same then pcall(function() same = UnitGUID(unit) == UnitGUID("target") end) end
    if same then return nil end   -- your target already reported this hit
    return unit
  end
end
-- (1.3.4) the same hit can come in twice (as your target and as its nameplate): the second one is dropped
local recentHits = {}
local function Repeat(amount, flag, unit)
  local now = GetTime()
  local who = unit
  pcall(function() who = UnitGUID(unit) or unit end)
  local key = tostring(who) .. ":" .. tostring(amount) .. ":" .. tostring(flag)
  for k, t in pairs(recentHits) do if now - t > 0.15 then recentHits[k] = nil end end
  if recentHits[key] then return true end
  recentHits[key] = now
  return false
end
local function OnUnitCombat(unit, action, flag, amount, school)
  seen.uc = (seen.uc or 0) + 1
  local u = Which(unit)
  if not u then return end
  if u ~= "target" then seen.plates = (seen.plates or 0) + 1 end
  local ok, hit, crit = pcall(function() return action == "WOUND", flag == "CRITICAL" end)
  if not ok then seen.ucHidden = (seen.ucHidden or 0) + 1 return end
  if not hit then return end
  local okR, dup = pcall(Repeat, amount, flag, unit)
  if okR and dup then return end
  if IsInGroup and IsInGroup() then
    local okA, act = pcall(Acting)
    if not (okA and act) then return end
  end
  if not crit then
    if Replacing() then
      local guid
      pcall(function() guid = UnitGUID(u) end)
      pcall(ShowSmall, amount, guid, school)
    end
    return
  end
  seen.ucCrits = (seen.ucCrits or 0) + 1
  if (seen.chat or 0) > 0 then return end   -- the chat lines work this session: they're exact, use those
  seen.hits = seen.hits + 1; seen.crits = seen.crits + 1
  local shown = "?"
  pcall(function() shown = tostring(amount) end)
  seen.last = u .. " crit " .. shown
  local guid
  pcall(function() guid = UnitGUID(u) end)
  Crit(amount, false, guid)
end
local feed = CreateFrame("Frame")
feed:SetScript("OnEvent", function(_, e, unit, a, b, c, d)
  if not DB or DB.off then return end
  if e == "UNIT_SPELLCAST_SUCCEEDED" then acted = GetTime() return end
  local ok = pcall(OnUnitCombat, unit, a, b, c, d)
  if not ok then seen.ucHidden = (seen.ucHidden or 0) + 1 end
end)
local function WatchTarget()
  pcall(feed.RegisterEvent, feed, "UNIT_COMBAT")   -- every unit: your target and every nameplate
  if feed.RegisterUnitEvent then pcall(feed.RegisterUnitEvent, feed, "UNIT_SPELLCAST_SUCCEEDED", "player") end
end

local MinimapButton   -- made further down, after the settings
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("UNIT_PET")
-- older clients still hand addons the combat log; Forever (which has C_DamageMeter) blocks asking for it
if not C_DamageMeter then ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") end
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "COMBAT_LOG_EVENT_UNFILTERED" then
    if DB then OnCombat() end
  elseif e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    CritSoundsDB = CritSoundsDB or {}
    DB = CritSoundsDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    -- (1.3.6) crit sizes went up a step: move an older pick up with them
    if not DB.size2 then
      DB.size2 = true
      local up = { [36] = 48, [48] = 64, [64] = 80 }
      DB.size = up[DB.size or 48] or 64
    end
  elseif e == "PLAYER_LOGIN" then
    me, pet = UnitGUID("player"), UnitGUID("pet")
    if not DB.pack and PACKS[1] then DB.pack = PACKS[1].key end
    pcall(MinimapButton)
    if C_DamageMeter then HookChat(); WatchTarget() end
    pcall(GameNumbers)
  elseif e == "UNIT_PET" then
    pet = UnitGUID("pet")
  end
end)

local function Test()
  if not DB then return end
  local n = 0
  local function One()
    n = n + 1
    local heal = n == 3
    local amount = heal and math.random(300, 900) or math.random(400, 2400)
    local guid = UnitExists("target") and UnitGUID("target") or nil
    if DB.numbers then ShowNumber(amount, heal, guid) end
    if DB.sound then Sound() end
    if n < 3 then C_Timer.After(0.7, One) end
  end
  One()
end

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local OnOff = { { "On", true }, { "Off", false } }
ns.HelpConfig = {
  title = "Crit Numbers",
  tag = "Crit Numbers",
  settings = {
    { label = "Crit Numbers", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil; pcall(GameNumbers) end },
    { label = "Sound", cycle = true,
      choices = { { "Off", "off" } },
      get = function() return DB.sound and (Pack(DB.pack) and Pack(DB.pack).key) or "off" end,
      set = function(v)
        if v == "off" then DB.sound = false else DB.sound = true; DB.pack = v; Sound(true) end   -- you hear it as you pick it
      end },
    { label = "Volume", slider = { 10, 100, 10 }, format = function(v) return v .. "%" end,
      get = function() return DB.volume or 100 end,
      set = function(v) DB.volume = v end,
      release = function() if DB.sound then Sound(true) end end },
    { label = "Sound Gap", choices = { { "None", 0 }, { "1 Sec", 1 }, { "3 Sec", 3 } },
      get = function() return DB.gap or 0 end, set = function(v) DB.gap = v end },
    { label = "Big Numbers", choices = OnOff,
      get = function() return DB.numbers and true or false end, set = function(v) DB.numbers = v; pcall(GameNumbers) end },
    { label = "Damage Numbers", choices = { { "Crit Numbers", true }, { "The Game's", false } },
      get = function() return DB.replace and true or false end, set = function(v) DB.replace = v; pcall(GameNumbers) end },
    -- (1.3.6) bigger crits, and the size of normal hits is yours to pick too
    { label = "Crit Number Size", choices = { { "Big", 48 }, { "Huge", 64 }, { "Massive", 80 } },
      get = function() return DB.size or 64 end, set = function(v) DB.size = v; ShowNumber(math.random(400, 2400), false) end },
    -- (1.3.11) one button that steps through every color: your crits, your pick
    { label = "Crit Color", cycle = true, choices = { { "Purple", "purple" }, { "Orange", "orange" }, { "Gold", "gold" },
      { "Cyan", "cyan" }, { "Red", "red" }, { "Pink", "pink" }, { "White", "white" }, { "Lime", "lime" } },
      get = function() return DB.critColor or "purple" end, set = function(v) DB.critColor = v; ShowNumber(math.random(400, 2400), false) end },
    { label = "Hit Number Size", choices = { { "Small", 22 }, { "Medium", 28 }, { "Large", 36 } },
      get = function() return DB.hitSize or 28 end, set = function(v) DB.hitSize = v; ShowSmall(math.random(40, 240), nil, 1) end },
    { label = "Heal Crits", choices = OnOff,
      get = function() return DB.heals and true or false end, set = function(v) DB.heals = v end },
    { label = "Pet Crits", choices = OnOff,
      get = function() return DB.pet and true or false end, set = function(v) DB.pet = v end },
  },
  notes = {
    { v = "1.4.0", "Crit Sounds is now Crit Numbers: the big numbers are the main event, and the sounds are optional. Your settings and /crits stay the same" },
    { v = "1.3.11", "Crit Color has more to pick from: Purple, Orange, Gold, Cyan, Red, Pink, White and Lime. Click it to step through them and see each one" },
    { v = "1.3.10", "Pick your crit color under Crit Color: Purple, Orange or Gold. Purple to start (pink was too close to the game's experience numbers)" },
    { v = "1.3.9", "Crit numbers are hot pink, so a crit can't be mistaken for anything else" },
    { v = "1.3.8", "Crit numbers are back to the game's gold" },
    { v = "1.3.7", "Crit numbers are orange, so they stand apart from white weapon hits and yellow spell hits" },
    { v = "1.3.6", "Crit numbers are bigger (Big, Huge or Massive under Crit Number Size), and Hit Number Size sets normal hits to Small, Medium or Large" },
    { v = "1.3.5", "Normal hit numbers are a bit bigger" },
    { v = "1.3.4", "Fixed numbers still showing twice: the game's damage numbers (including DoT ticks and pet hits) are all switched off now, and a hit that comes in twice is only drawn once" },
    { v = "1.3.3", "No more shaking: the Shake setting is gone and crit numbers just pop in big and float away" },
    { v = "1.3.2", "Removed Screen Shake. The big crit number still shakes" },
    { v = "1.3.1", "Numbers and crit sounds on every mob with a nameplate, not just your target, so AoE shows too. Keep enemy nameplates on" },
    { v = "1.3.0", "No more doubled numbers: Crit Sounds now draws every hit on your target, small like the game's, with crits big and shaking. The game's own damage numbers are switched off while it does (Damage Numbers in Settings & Help puts them back)" },
    { v = "1.2.4", "In a group, your Auto Shot and auto attack crits are heard again (they were being skipped)" },
    { v = "1.2.3", "Screen Shake works in combat now: it's a quick camera wiggle. WoW doesn't let addons move the game world during a fight" },
    { v = "1.2.2", "A second way to catch your crits on WoW: Forever, from your target, for when the combat log lines can't be read" },
    { v = "1.2.1", "Crits work again on WoW: Forever. The game stopped letting addons read combat events, so crits are now read from the combat log lines in your chat. Keep the Combat Log tab (it's there by default)" },
    { v = "1.2.0", "Screen Shake: the world jolts for a moment when you crit (off by default, pick Small or Big)" },
    { v = "1.1.1", "/crits debug shows how many of your hits were crits this session" },
    { v = "1.1.0", "The Dalorrian Pack: 12 crit lines from Dalorrian, one at random every crit" },
    { v = "1.0.0", "First release: a sound and a big shaking number every time you crit, with sound packs, a Volume slider and crit streaks" },
  },
  report = function()
    local p = Pack(DB.pack)
    return { "Sound " .. (DB.sound and (p and p.key or "none") or "off") .. ", volume " .. tostring(DB.volume) ..
      ", numbers " .. tostring(DB.numbers) .. ", packs " .. #PACKS .. (DB.off and ", turned off" or "") }
  end,
}
for _, st in ipairs(ns.HelpConfig.settings) do if st.label == "Sound" then soundSetting = st end end
for _, p in ipairs(PACKS) do soundSetting.choices[#soundSetting.choices + 1] = { p.label, p.key } end

MinimapButton = function()
  if not Minimap or _G.CritSoundsMinimapButton then return end
  local b = CreateFrame("Button", "CritSoundsMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\Ability_CriticalStrike")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 205)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then SlashCmdList.CRITSOUNDS("off")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Crit Numbers")
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
function CritSounds_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_CRITSOUNDS1 = "/crits"
SLASH_CRITSOUNDS2 = "/critsounds"
SlashCmdList.CRITSOUNDS = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if cmd == "debug" then
    local p = Pack(DB.pack)
    print("|cffffd100Crit Numbers debug|r")
    print("  this session: " .. seen.hits .. " hits from you, " .. seen.crits .. " of them crits")
    print("  last crit: " .. tostring(seen.last))
    print("  chat lines read " .. (seen.lines or 0) .. ", unreadable " .. (seen.secret or 0) .. ", combat log tab " ..
      ((ChatFrame2 and ChatFrame2.IsShown and "found") or "missing") .. ", crits from chat " .. (seen.chat or 0))
    print("  target feed: events " .. (seen.uc or 0) .. ", from nameplates " .. (seen.plates or 0) .. ", crits " .. (seen.ucCrits or 0) .. ", hidden " .. (seen.ucHidden or 0))
    print("  on " .. tostring(not DB.off) .. ", sound " .. tostring(DB.sound) .. " (" .. (p and p.key or "no pack") .. "), numbers " ..
      tostring(DB.numbers) .. ", packs " .. #PACKS .. ", you " .. tostring(me))
    return
  elseif cmd == "test" then
    Test(); Say("three sample crits" .. ".")
  elseif cmd == "off" then
    DB.off = not DB.off or nil; pcall(GameNumbers); Say(DB.off and "turned off" or "turned on")
  elseif cmd == "" then
    Say("a sound and a big shaking number every time you crit" .. ".")
    P("  /crits help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /crits test   (" .. "three sample crits" .. ")")
  elseif ns.OpenHelp then
    ns.OpenHelp()
  end
end
