-- Dalorrian's Aggro Alert: a small warning over your head when you're about to pull a mob, with arrows
-- pointing at it. Gone the moment you're in combat or walk clear. /aggro for options.
--
-- How it knows: the aggro range follows the Classic rule (about 20 yards at your level, a yard more for
-- each level the mob is above you, a yard less for each level below, never under 5 or over 45). Distance
-- comes from the game's out-of-combat range checks, which answer in steps (10, 20, 28, 30, 35 yards).
-- Only mobs with a nameplate showing can be seen, so keep enemy nameplates on.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 1, 0.82, 0 }
local RED = { 1, 0.25, 0.2 }
local DEFAULTS = { volume = 100, margin = 5, scale = 1, sound = false, minLevel = 2, chime = "chime", units = "m", arrow = 1.5 }
-- (1.0.2) calm sounds to pick from
-- (1.0.17) sound packs: a pack plays one of its clips at random, never the same one twice in a row.
-- Each pack's clips live in Sounds\<pack>\. More packs from Dalorrian are on the way.
local PACKS = {
  dalorrian = { "careful", "hes_right_there", "hey_ya_ya_ya", "ooooo", "quiet", "tip_toe_dude", "watch_out" },
}
local SOUNDS = {
  { "Dalorrian Pack", "pack_dalorrian", { pack = "dalorrian" } },
  -- (1.3.1) packs of the game's own sounds, one at random each warning
  { "Bell Pack", "pack_bells", { game = { 5274, 3081, 3175, 8960 } } },
  { "Horn Pack", "pack_horns", { game = { 44292, 8459, 37666 } } },
  { "Alarm Pack", "pack_alarms", { game = { "RAID_WARNING", 8959, 12867, 17317 } } },
  { "Soft Chime", "chime", 3081 },
  { "Map Ping", "ping", 3175 },
  { "Soft Click", "click", 856 },
  { "Bell", "bell", 5274 },
  -- (1.0.16) more of the game's own sounds: every player already has them
  { "Boss Whisper Warning", "boss_whisper", 37666 },
  { "Role Check", "role_check", 17317 },
  { "Quest List Open", "quest_open", 875 },
  { "Pet Trap Ready", "trap_ready", 28814 },
  { "Ready Check", "ready_check", 8960 },
  { "Alarm Clock", "alarm2", 12867 },
  { "War Horn", "war_horn", 44292 },
  { "Queue Pop Horn", "queue_horn", 8459 },
  { "Orb Impact Low", "orb_low", 97598 },
  { "Orb Impact Medium", "orb_med", 97597 },
  { "Gold Trait", "gold_trait", 54125 },
  { "World Quest Complete", "wq_complete", 73277 },
  { "Honor Rank Up", "honor_rank", 77003 },
  -- (1.1.0) the loot sounds are gone: a warning should not sound like a drop
}
local lastClip = {}
-- (1.1.1) a new warning cuts off the one still playing, so it always plays right away
local playing
local function StopLast()
  if playing and StopSound then pcall(StopSound, playing, 0) end
  playing = nil
end
local function PlayFile(path)
  if not PlaySoundFile then return end
  local ok, played, handle = pcall(PlaySoundFile, path .. ".ogg", "Master")
  if not (ok and played) then ok, played, handle = pcall(PlaySoundFile, path .. ".mp3", "Master") end
  if ok and played then playing = handle; return true end
end
local function Chime(key)
  if type(key) == "string" and key:find("^v_") then key = "pack_dalorrian" end   -- the old single voice lines live in the pack now
  local found
  for _, s in ipairs(SOUNDS) do if s[2] == key then found = s end end
  if not found then for _, s in ipairs(SOUNDS) do if s[2] == "chime" then found = s end end end   -- a sound that was retired, or a pack whose addon is off: the soft chime instead
  local snd = found[3]
  StopLast()
  if type(snd) == "number" then
    if PlaySound then
      local ok, played, handle = pcall(PlaySound, snd, "Master")
      if ok and played then playing = handle end
    end
  elseif type(snd) == "table" and snd.game then
    if not snd.ids then
      local ids, seen = {}, {}
      for _, g in ipairs(snd.game) do
        local id = g
        if type(g) == "string" then id = SOUNDKIT and SOUNDKIT[g] end
        if type(id) == "number" and not seen[id] then seen[id] = true; ids[#ids + 1] = id end
      end
      snd.ids = ids
    end
    local n = #snd.ids
    if n == 0 or not PlaySound then return end
    local pick = math.random(n)
    if n > 1 and pick == lastClip[key] then pick = pick % n + 1 end
    lastClip[key] = pick
    for i = 0, n - 1 do   -- a sound this version of the game doesn't have: the next one instead
      local ok, played, handle = pcall(PlaySound, snd.ids[(pick + i - 1) % n + 1], "Master")
      if ok and played then playing = handle; return end
    end
  elseif type(snd) == "table" and snd.pack then
    local clips = PACKS[snd.pack] or {}
    if #clips == 0 then return end
    local pick = math.random(#clips)
    if #clips > 1 and pick == lastClip[snd.pack] then pick = pick % #clips + 1 end
    lastClip[snd.pack] = pick
    local base = snd.path or ("Interface\\AddOns\\AggroAlert\\Sounds\\" .. snd.pack)
    -- (1.2.0) Volume: the game can't turn one sound down, so each pack carries quieter copies in v10..v90
    local vol = DB and DB.volume or 100
    if vol >= 100 or not PlayFile(base .. "\\v" .. vol .. "\\" .. clips[pick]) then
      PlayFile(base .. "\\" .. clips[pick])   -- a pack without the quieter copies plays at full volume
    end
  elseif type(snd) == "string" then
    PlayFile("Interface\\AddOns\\AggroAlert\\Sounds\\" .. snd)
  end
end

-- (1.1.0) other addons can add their own packs:
--   AggroAlert_AddPack("Label", "Interface\\AddOns\\YourAddon\\Sounds\\folder", { "clip1", "clip2" })
-- clip names without .ogg/.mp3. The pack shows up in the Sound setting.
-- For the Volume slider, put quieter copies in folder\v10 .. folder\v90 (same names); without them it plays full volume.
local soundSetting   -- the Sound row in the settings, filled in further down
function AggroAlert_AddPack(label, path, clips)
  if type(label) ~= "string" or type(path) ~= "string" or type(clips) ~= "table" or #clips == 0 then return end
  local key = "pack_" .. label:lower():gsub("[^%w]+", "_")
  for _, s in ipairs(SOUNDS) do if s[2] == key then return end end
  PACKS[key] = clips
  local at = 2
  for i, s in ipairs(SOUNDS) do if type(s[3]) == "table" then at = i + 1 end end   -- packs stay together at the top
  table.insert(SOUNDS, at, { label, key, { pack = key, path = path } })
  if soundSetting then table.insert(soundSetting.choices, at + 1, { label, key }) end
end

local MAX_ARROWS = 6

local P = ns.print or print   -- (1.0.3) Lang.lua: chat text in the player's language
local function Say(msg) P("|cffffd100Aggro Alert:|r " .. msg) end
local Tip = ns.Tip or GameTooltip
local NewFrame = ns.CreateFrame or CreateFrame

-- (1.0.3) distance in meters (the default) or yards
local function Dist(yards)
  if DB and DB.units == "yd" then return math.floor(yards + 0.5) .. " yd" end
  return math.floor(yards * 0.9144 + 0.5) .. " m"
end

---------------------------------------------------------------------------
-- distance, in steps, out of combat only (the game allows these checks then)
---------------------------------------------------------------------------
local InRange = (C_Item and C_Item.IsItemInRange) or IsItemInRange
local ITEMS = { { 20, 10645 }, { 30, 835 }, { 35, 18904 } }   -- Gnomish Death Ray, Large Rope Net, Zorbin's Ultra-Shrinker
local function ItemIn(id, unit)
  if not InRange then return nil end
  local ok, r = pcall(InRange, id, unit)
  if not ok then return nil end
  return r
end
local function Interact(unit, i)
  if not CheckInteractDistance then return nil end
  local ok, r = pcall(CheckInteractDistance, unit, i)
  if not ok then return nil end
  return r
end
-- (1.0.5) every range check the game allows out of combat, each one saying "within R yards" or "further".
-- Together they box the mob in: nearer than the smallest yes, further than the biggest no. If the answers
-- don't agree with each other, that mob is skipped rather than guessed at.
local CHECKS = {
  { 9.9, function(u) return Interact(u, 3) end, "duel range" },
  { 11.1, function(u) return Interact(u, 2) end, "trade range" },
  { 20, function(u) return ItemIn(10645, u) end, "Gnomish Death Ray" },
  { 28, function(u) return Interact(u, 4) end, "follow range" },
  { 30, function(u) return ItemIn(835, u) end, "Large Rope Net" },
  { 35, function(u) return ItemIn(18904, u) end, "Zorbin's Ultra-Shrinker" },
}
local function Distance(unit)
  local lo, hi = 0, nil
  for _, c in ipairs(CHECKS) do
    local r = c[2](unit)
    if r == true then hi = hi and math.min(hi, c[1]) or c[1]
    elseif r == false then lo = math.max(lo, c[1]) end
  end
  if not hi then return nil end          -- further than every check
  if lo >= hi then return nil end        -- the answers disagree: don't guess
  return lo, hi
end

local function AggroRange(unit)
  local mine, theirs = UnitLevel("player"), UnitLevel(unit)
  if not theirs or theirs < 0 then return 45 end   -- a skull: as far as it gets
  return math.max(5, math.min(45, 20 + (theirs - mine)))
end

-- (1.3.0) elites hit like a mob a few levels higher: they count as 3 levels up for Warn For Mobs, and warn
-- 5 yards (about 4.5 m) sooner
local ELITE_LEVELS, ELITE_YARDS = 3, 5
local function Elite(unit)
  if DB and DB.elite == false then return false end
  local c = UnitClassification and UnitClassification(unit)
  return c == "elite" or c == "rareelite" or c == "worldboss"
end

-- a mob that can pull you: hostile, alive, not a player, not a critter, not already fighting
local function Threat(unit)
  if not UnitExists(unit) or UnitIsDead(unit) or UnitIsPlayer(unit) or UnitPlayerControlled(unit) then return false end
  if not UnitCanAttack("player", unit) then return false end
  local react = UnitReaction(unit, "player")
  if not react or react > 2 then return false end   -- only hostile (red) mobs pull you; neutral and unfriendly ones wait
  if UnitCreatureType(unit) == "Critter" then return false end
  if UnitAffectingCombat(unit) then return false end
  -- (1.0.2) by default only mobs 2 or more levels above you: your own level isn't worth a warning
  local mine, theirs = UnitLevel("player") or 0, UnitLevel(unit) or 0
  if theirs >= 0 and theirs - mine + (Elite(unit) and ELITE_LEVELS or 0) < (DB.minLevel or 2) then return false end
  return true
end

---------------------------------------------------------------------------
-- what you see: a small dark tag over your head, arrows round it, a "!" over each mob
---------------------------------------------------------------------------
local tag = NewFrame("Frame", "AggroAlertFrame", UIParent, "BackdropTemplate")
tag:SetSize(140, 20)
tag:SetFrameStrata("HIGH")
tag:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 2 })
tag:SetBackdropColor(0.04, 0.04, 0.05, 0.85)
tag:SetBackdropBorderColor(0, 0, 0, 1)
tag:SetMovable(true)
tag:SetClampedToScreen(true)
tag:RegisterForDrag("LeftButton")
tag:EnableMouse(false)
tag:SetScript("OnDragStart", tag.StartMoving)
tag:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local p, _, rp, x, y = self:GetPoint(1)
  DB.point, DB.rel, DB.x, DB.y = p, rp, x, y
end)
tag.text = tag:CreateFontString(nil, "OVERLAY")
tag.text:SetFont(FONT, 11, "")
tag.text:SetShadowOffset(1, -1)
tag.text:SetPoint("CENTER", 0, 0)
tag:Hide()

-- (1.0.4) a gold arrow floating over each mob, bobbing gently and pointing down at it, with the distance
-- under it. It hangs off the mob's nameplate, so it follows the mob on screen by itself.
local marks = {}
local function Mark(i)
  local m = marks[i]
  if m then return m end
  m = CreateFrame("Frame", nil, UIParent)
  m:SetSize(30, 44)
  m:SetFrameStrata("HIGH")
  m.arrow = m:CreateTexture(nil, "OVERLAY")
  m.arrow:SetTexture("Interface\\Minimap\\MiniMap-QuestArrow")
  m.arrow:SetSize(28, 28)
  m.arrow:SetPoint("TOP", 0, 0)
  m.arrow:SetRotation(math.pi)   -- pointing down at the mob
  m.dist = m:CreateFontString(nil, "OVERLAY")
  m.dist:SetFont(FONT, 12, "OUTLINE")
  m.dist:SetPoint("TOP", m.arrow, "BOTTOM", 0, 2)
  m.t = 0
  m:SetScript("OnUpdate", function(self, el)
    self.t = self.t + el
    local bob = math.sin(self.t * 4) * 3
    self.arrow:ClearAllPoints()
    self.arrow:SetPoint("TOP", self, "TOP", 0, bob)
  end)
  marks[i] = m
  return m
end

local function Place()
  tag:ClearAllPoints()
  tag:SetScale(DB.scale or 1)
  if DB.point then tag:SetPoint(DB.point, UIParent, DB.rel or DB.point, DB.x or 0, DB.y or 0)
  else tag:SetPoint("CENTER", UIParent, "CENTER", 0, 120) end   -- over your head with the default camera
end

-- (1.0.7) one bar per mob, stacked upward from the main one; past 3 mobs a last bar says how many more
local bars = { tag }
local MAX_BARS = 3
local function Bar(i)
  if bars[i] then return bars[i] end
  local b = NewFrame("Frame", nil, UIParent, "BackdropTemplate")
  b:SetFrameStrata("HIGH")
  b:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 2 })
  b:SetBackdropColor(0.04, 0.04, 0.05, 0.85)
  b:SetBackdropBorderColor(0, 0, 0, 1)
  b:SetHeight(22)
  b.text = b:CreateFontString(nil, "OVERLAY")
  b.text:SetFont(FONT, 11, "")
  b.text:SetShadowOffset(1, -1)
  b.text:SetPoint("CENTER", 0, 0)
  b:SetPoint("BOTTOM", bars[i - 1] or Bar(i - 1), "TOP", 0, 3)
  bars[i] = b
  return b
end
local function HideAll()
  for _, b in ipairs(bars) do b:Hide() end
  for _, m in ipairs(marks) do m:Hide() end
end



-- show a list of { name, inside (true when already in its range), plate } entries
local function Show(list)
  if #list == 0 then HideAll() return end
  -- the ones you could pull any second first, then the rest
  table.sort(list, function(a, b) if a.inside ~= b.inside then return a.inside end return (a.gap or 0) < (b.gap or 0) end)
  -- (1.0.8) one short line, nothing more: "Careful" in gold when you're getting close, "Danger" in red when
  -- you could pull something any second. One mob gets its name, more get a count.
  local danger = list[1].inside
  local c = danger and RED or GOLD
  local word = danger and "Danger" or "Careful"
  local who = (#list == 1) and list[1].name or (#list .. " " .. "mobs")
  local anyElite = false
  for _, e in ipairs(list) do if e.elite then anyElite = true end end
  if anyElite then who = who .. " (" .. "Elite" .. ")" end   -- (1.3.0)
  local b = Bar(1)
  b.text:SetText("|TInterface\\DialogFrame\\UI-Dialog-Icon-AlertNew:14:14:0:0|t " .. word .. ": " .. who)
  b.text:SetTextColor(c[1], c[2], c[3])
  b:SetBackdropBorderColor(c[1] * 0.8, c[2] * 0.8, c[3] * 0.8, 1)
  b:SetWidth(math.max(80, b.text:GetStringWidth() + 20))
  b:SetHeight(22)
  b:Show()
  local shown = 1
  for i = shown + 1, #bars do bars[i]:Hide() end
  local nm = 0
  for i, e in ipairs(list) do
    if i > MAX_ARROWS then break end
    if e.nomark then break end
    nm = i
    local ec = e.inside and RED or GOLD
    local m = Mark(i)
    -- (1.0.11) arrow size from the settings
    local f = DB.arrow or 1.5
    m:SetSize(30 * f, 44 * f)
    m.arrow:SetSize(28 * f, 28 * f)
    m:ClearAllPoints()
    if e.plate then
      m:SetParent(e.plate)          -- rides along with the mob's nameplate
      m:SetFrameStrata("HIGH")
      m:SetPoint("BOTTOM", e.plate, "TOP", 0, 4)
    else                            -- the test: made-up spots on screen
      m:SetParent(UIParent)
      m:SetPoint("CENTER", UIParent, "CENTER", e.x or 0, e.y or 0)
    end
    m.arrow:SetVertexColor(ec[1], ec[2], ec[3], 1)
    m.dist:SetText("")
    m:Show()
  end
  for i = nm + 1, #marks do marks[i]:Hide() end
end


---------------------------------------------------------------------------
-- the scan: five times a second, only while you're out of combat
---------------------------------------------------------------------------
local testing, lastSound
local warned = {}
local function Scan()
  if not DB or DB.off or testing then return end
  if UnitAffectingCombat("player") or UnitIsDeadOrGhost("player") or UnitOnTaxi("player") then HideAll() return end
  local list, now = {}, {}
  local plates = C_NamePlate and C_NamePlate.GetNamePlates and C_NamePlate.GetNamePlates() or {}
  for _, plate in ipairs(plates) do
    local unit = plate.namePlateUnitToken or (plate.UnitFrame and plate.UnitFrame.unit)
    if unit and Threat(unit) then
      local lo, hi = Distance(unit)
      if lo then
        local range = AggroRange(unit)
        -- (1.0.6) how far before it pulls you, counted from the furthest it could be: it only says 0 and
        -- turns red when you're sure to be inside its range
        local left = math.floor(hi - range + 0.5)
        local near = math.floor(lo - range + 0.5)
        local elite = Elite(unit)
        if near <= (DB.margin or 5) + (elite and ELITE_YARDS or 0) then
          local guid = UnitGUID(unit)
          -- (1.0.9) red as soon as you could be inside its range, not only once you're sure to be: that's
          -- the moment to stop. Gold while you're close but still outside.
          list[#list + 1] = { name = UnitName(unit) or "?", inside = near < 0, gap = math.max(1, left), plate = plate, elite = elite }
          if guid then
            now[guid] = true
            -- (1.1.1) plays every time a mob pops up, no 3 second wait. The short gap only stops a stutter
            -- when you stand right on the edge of the range.
            if DB.sound and not warned[guid] and (GetTime() - (lastSound or 0)) > 0.4 then
              lastSound = GetTime()
              Chime(DB.chime or "chime")   -- a calm sound, never an alarm
            end
          end
        end
      end
    end
  end
  warned = now
  Show(list)
end

local lastError
local driver = CreateFrame("Frame")
local wait = 0
driver:SetScript("OnUpdate", function(_, el)
  wait = wait - el
  if wait > 0 then return end
  wait = 0.1   -- ten times a second: the arrows and the distance follow you as you move
  local ok, err = pcall(Scan)
  if not ok and err ~= lastError then lastError = err; Say("something went wrong, send Dalorrian this:" .. " " .. tostring(err)) end
end)

local MinimapButton   -- made further down, after the settings
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("PLAYER_REGEN_DISABLED")
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= "AggroAlert" then return end
    AggroAlertDB = AggroAlertDB or {}
    DB = AggroAlertDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    if type(DB.chime) == "string" and DB.chime:find("^v_") then DB.chime = "pack_dalorrian" end
  elseif e == "PLAYER_LOGIN" then
    Place()
    pcall(MinimapButton)
    -- the range checks use a few items' ranges: make sure the game knows them
    for _, it in ipairs(ITEMS) do
      if C_Item and C_Item.RequestLoadItemDataByID then pcall(C_Item.RequestLoadItemDataByID, it[2]) end
      if GetItemInfo then GetItemInfo(it[2]) end
    end
  elseif e == "PLAYER_REGEN_DISABLED" then
    HideAll()   -- in combat now: it steps away
  end
end)

---------------------------------------------------------------------------
-- /aggro
---------------------------------------------------------------------------
local function Test(stay)
  if not DB then return end
  testing = true
  -- (1.0.11) moving it: just the warning, no sample arrows (those sit over real mobs, not here)
  Show(stay and { { name = "Clattering Scorpid", inside = false, gap = 4, nomark = true } } or {
    { name = "Clattering Scorpid", inside = false, gap = 4, x = -260, y = 140 },
    { name = "Razormane Scout", inside = false, gap = 7, x = 240, y = 60 },
  })
  if not stay then C_Timer.After(6, function() if not tag:IsMouseEnabled() then testing = nil; HideAll() end end) end
end

---------------------------------------------------------------------------
-- (1.0.2) Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local function Choices(list, fmt)
  local out = {}
  for _, v in ipairs(list) do out[#out + 1] = { fmt(v), v } end
  return out
end
ns.HelpConfig = {
  title = "Aggro Alert",
  tag = "Aggro Alert",
  settings = {
    { label = "Aggro Alert", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil; if DB.off then HideAll() end end },
    { label = "Warn For Mobs", cycle = true,
      choices = { { "Any Level", -99 }, { "1+ Levels Above You", 1 }, { "2+ Levels Above You", 2 }, { "3+ Levels Above You", 3 }, { "5+ Levels Above You", 5 } },
      get = function() return DB.minLevel or 2 end, set = function(v) DB.minLevel = v end },
    { label = "Elites Warn Earlier", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.elite ~= false end, set = function(v) DB.elite = v end },
    { label = "Warn How Early", cycle = true,
      choices = Choices({ 3, 5, 8, 10, 15 }, function(v) return Dist(v) .. " Before" end),
      get = function() return DB.margin or 5 end, set = function(v) DB.margin = v end },
    { label = "Distance In", choices = { { "Meters", "m" }, { "Yards", "yd" } },
      get = function() return DB.units or "m" end,
      set = function(v)
        DB.units = v
        -- the Warn How Early labels follow along
        for _, st in ipairs(ns.HelpConfig.settings) do
          if st.label == "Warn How Early" then for _, c in ipairs(st.choices) do c[1] = Dist(c[2]) .. " Before" end end
        end
      end },
    { label = "Sound", cycle = true,
      choices = (function() local c = { { "Off", "off" } }; for _, s in ipairs(SOUNDS) do c[#c + 1] = { s[1], s[2] } end; return c end)(),
      get = function() return DB.sound and (DB.chime or "chime") or "off" end,
      set = function(v)
        if v == "off" then DB.sound = false else DB.sound = true; DB.chime = v; Chime(v) end   -- you hear it as you pick it
      end },
    { label = "Volume", slider = { 10, 100, 10 }, format = function(v) return v .. "%" end,
      get = function() return DB.volume or 100 end,
      set = function(v) DB.volume = v end,
      release = function() if DB.sound then Chime(DB.chime or "chime") end end },   -- you hear it when you let go
    { label = "Arrow Size", choices = { { "Small", 1 }, { "Normal", 1.5 }, { "Big", 2 } },
      get = function() return DB.arrow or 1.5 end, set = function(v) DB.arrow = v end },
    { label = "Size", choices = { { "Small", 0.8 }, { "Normal", 1 }, { "Big", 1.25 } },
      get = function() return DB.scale or 1 end, set = function(v) DB.scale = v; Place() end },
    { label = "Move The Warning", choices = { { "Locked", "lock" }, { "Move It", "move" } },
      get = function() return tag:IsMouseEnabled() and "move" or "lock" end,
      set = function(v) SlashCmdList.AGGROALERT(v == "move" and "unlock" or "lock") end },
  },
  notes = {
    { v = "1.3.1", "More sound packs under Sound: Bell, Horn and Alarm, made of the game's own sounds. Each plays one at random every warning, like the Dalorrian Pack" },
    { v = "1.3.0", "Elite mobs warn you a few meters sooner and say Elite on the warning, even at your own level" },
    { v = "1.2.0", "A Volume slider for the sound packs. The game's own sounds follow your Master volume" },
    { v = "1.1.1", "The sound plays every time a warning pops up, even right after the last one, instead of waiting for it to finish" },
    { v = "1.1.0", "Took the loot sounds out of the Sound list", "Other addons can add their own sound packs" },
    { v = "1.0.17", "The Dalorrian Pack: picks one of Dalorrian's voice lines at random each time, never the same one twice in a row" },
    { v = "1.0.16", "18 more of the game's own sounds to pick under Sound, from soft warnings to horns" },
    { v = "1.0.15", "Removed the Custom sound slots" },
    { v = "1.0.14", "New voice lines from Dalorrian, a little louder: Careful, He's Right There, Hey Ya Ya Ya, Ooooo, Quiet, Tip Toe Dude and Watch Out" },
    { v = "1.0.12", "Dalorrian's own voice lines to pick under Sound: Careful Now, Gotta Be Quiet, Ooooo, Sss Ah Ah, Tip Toe Dude and Yo He's Close" },
    { v = "1.0.11", "Bigger arrows over the mobs, with Arrow Size in the settings. Moving the warning no longer shows sample arrows" },
    { v = "1.0.9", "Turns red sooner, as soon as you might be inside a mob's range" },
    { v = "1.0.8", "Simpler: one short warning over your head, Careful in gold or Danger in red, and a small arrow over each mob" },
    { v = "1.0.7", "One bar for each mob you're close to, stacked over your head, with a count when there are more than 3",
      "No more distance numbers: gold means you're getting close, red means you could pull it any second" },
    { v = "1.0.5", "Distance is checked against every range the game allows, so it no longer jumps straight to 0" },
    { v = "1.0.4", "A gold arrow floats over each mob it warns about, with the distance under it" },
    { v = "1.0.3", "Speaks 10 languages, and shows distance in meters or yards (pick under Distance In)" },
    { v = "1.0.2", "Warns only for mobs 2 or more levels above you by default, with a Settings & Help window, a minimap button and calm sounds to pick from" },
    { v = "1.0.1", "Shows how far until a mob pulls you, with arrows pointing at each mob" },
    { v = "1.0.0", "First release: a warning over your head before you pull a mob" },
  },
  report = function()
    return { "Warn for " .. tostring(DB.minLevel) .. "+ levels, " .. tostring(DB.margin) .. " yards early, sound " ..
      (DB.sound and tostring(DB.chime) or "off") .. (DB.off and ", turned off" or "") }
  end,
}
for _, st in ipairs(ns.HelpConfig.settings) do if st.label == "Sound" then soundSetting = st end end

MinimapButton = function()
  if not Minimap or _G.AggroAlertMinimapButton then return end
  local b = CreateFrame("Button", "AggroAlertMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\Ability_Warrior_Challange")
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
    if button == "RightButton" then
      SlashCmdList.AGGROALERT("off")
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Aggro Alert")
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
      DB.minimapAngle = math.deg(math.atan2(cy / sc - my, cx / sc - mx))
      Spot()
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  Spot()
end
function AggroAlert_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_AGGROALERT1 = "/aggro"
SLASH_AGGROALERT2 = "/aggroalert"
SlashCmdList.AGGROALERT = function(msg)
  local cmd, arg = (msg or ""):lower():match("^(%S*)%s*(%S*)")
  if cmd == "debug" then
    -- for bug reports: target a mob and type /aggro debug. Plain chat, and any error is shown right here.
    print("|cffffd100Aggro Alert debug|r")
    local ok, err = pcall(function()
      local u = "target"
      if not UnitExists(u) then print("  target a mob first") return end
      print("  " .. tostring(UnitName(u)) .. ", level " .. tostring(UnitLevel(u)) .. " (you " .. tostring(UnitLevel("player")) .. "), reaction " .. tostring(UnitReaction(u, "player")) .. ", in combat " .. tostring(UnitAffectingCombat(u)))
      for _, c in ipairs(CHECKS) do
        local okc, r = pcall(c[2], u)
        print("  " .. c[3] .. " (" .. c[1] .. " yd): " .. (okc and tostring(r) or ("error " .. tostring(r))))
      end
      local lo, hi = Distance(u)
      print("  between " .. tostring(lo) .. " and " .. tostring(hi) .. " yd, its aggro range " .. tostring(AggroRange(u)) .. " yd, counts as a threat: " .. tostring(Threat(u)))
    end)
    if not ok then print("  error: " .. tostring(err)) end
    return
  elseif cmd == "help" or cmd == "settings" or cmd == "options" or cmd == "" then
    if cmd == "" then
      Say("warns you before you pull a mob, with arrows pointing at it. Keep enemy nameplates on" .. ".")
      P("  /aggro help   (" .. "all settings, and how to report a bug" .. ")")
      P("  /aggro test   (" .. "see a sample warning" .. ")")
    end
    if cmd ~= "" and ns.OpenHelp then ns.OpenHelp() end
  elseif cmd == "test" then
    Test(); Say("a sample for 6 seconds" .. ".")
  elseif cmd == "level" and tonumber(arg) then
    DB.minLevel = math.max(-99, math.min(10, tonumber(arg)))
  elseif cmd == "margin" and tonumber(arg) then
    DB.margin = math.max(0, math.min(15, tonumber(arg)))
  elseif cmd == "sound" then
    DB.sound = not DB.sound
  elseif cmd == "unlock" or cmd == "move" then
    Test(true); tag:EnableMouse(true); Say("drag the warning where you want it, then /aggro lock")
  elseif cmd == "lock" then
    tag:EnableMouse(false); testing = nil; HideAll(); Say("locked in place")
  elseif cmd == "scale" and tonumber(arg) then
    DB.scale = math.max(0.5, math.min(2, tonumber(arg))); Place()
  elseif cmd == "off" then
    DB.off = not DB.off or nil; if DB.off then HideAll() end; Say(DB.off and "turned off" or "turned on")
  elseif cmd == "reset" then
    DB.point, DB.rel, DB.x, DB.y, DB.scale = nil, nil, nil, nil, 1; Place()
  end
end
