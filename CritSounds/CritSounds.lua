-- Dalorrian's Crit Sounds: a sound and a big shaking number every time you crit.
-- The number pops over the mob you hit (keep enemy nameplates on), or in the middle of the screen when it can't
-- find the mob's nameplate (heals, nameplates off). /crits for options.

local ADDON, ns = ...
local DB
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local NUMFONT = DAMAGE_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local DEFAULTS = { screen = 0, sound = true, pack = nil, volume = 100, numbers = true, size = 48, shake = 1, heals = true, pet = true, gap = 0 }
local P = ns.print or print
local function Say(msg) P("|cffffd100Crit Sounds:|r " .. msg) end
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
  if t >= LIFE then
    f:SetScript("OnUpdate", nil); f:Hide(); f:ClearAllPoints()
    live[f] = nil; pool[#pool + 1] = f
    return
  end
  -- pop: starts big and snaps down to size in the first moment
  local pop = t < 0.12 and (1.7 - (t / 0.12) * 0.7) or 1
  f:SetScale(math.max(0.01, pop))
  -- shake: strong at first, dying out by 0.45 seconds
  local amp = (SHAKE[DB.shake or 1] or 7) * math.max(0, 1 - t / 0.45)
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
local function ShowNumber(amount, heal, guid)
  local f = GetNum()
  local plate = PlateFor(guid)
  f.anchor = plate or holder
  -- crits on the same mob stack upward a little so they don't sit on top of each other
  local same = 0
  for o in pairs(live) do if o.anchor == f.anchor then same = same + 1 end end
  f.x = (math.random() * 2 - 1) * 18
  f.y = (plate and 0 or 120) + math.min(same, 4) * ((DB.size or 48) * 0.6)
  f.text:SetFont(NUMFONT, DB.size or 48, "THICKOUTLINE")
  if heal then f.text:SetTextColor(0.3, 1, 0.35) else f.text:SetTextColor(1, 0.82, 0) end
  f.text:SetText(Commas(math.floor(amount + 0.5)) .. "!")
  f.t = 0
  live[f] = true
  f:SetAlpha(1)
  f:Show()
  Tick(f, 0)
  f:SetScript("OnUpdate", Tick)
end

---------------------------------------------------------------------------
-- (1.2.0) screen shake: the game world jolts for a moment, the interface stays put
---------------------------------------------------------------------------
local SCREEN = { [1] = 3, [2] = 7 }
local home, shakeT = nil, 0
local shaker = CreateFrame("Frame")
local function Restore()
  shaker:SetScript("OnUpdate", nil)
  if not home then return end
  WorldFrame:ClearAllPoints()
  for _, p in ipairs(home) do WorldFrame:SetPoint(unpack(p)) end
  home = nil
end
local function ScreenShake()
  local amp = SCREEN[DB.screen or 0]
  if not (amp and WorldFrame) then return end
  if WorldFrame.IsProtected and WorldFrame:IsProtected() and InCombatLockdown() then return end   -- never risk a blocked action
  if not home then
    home = {}
    for i = 1, (WorldFrame:GetNumPoints() or 0) do home[i] = { WorldFrame:GetPoint(i) } end
    if #home == 0 then home = nil; return end
  end
  shakeT = 0
  shaker:SetScript("OnUpdate", function(_, el)
    shakeT = shakeT + el
    if shakeT >= 0.25 then Restore() return end
    local a = amp * (1 - shakeT / 0.25)
    local dx, dy = (math.random() * 2 - 1) * a, (math.random() * 2 - 1) * a
    local ok = pcall(function()
      WorldFrame:ClearAllPoints()
      for _, p in ipairs(home) do WorldFrame:SetPoint(p[1], p[2], p[3], (p[4] or 0) + dx, (p[5] or 0) + dy) end
    end)
    if not ok then Restore() end
  end)
end

---------------------------------------------------------------------------
-- watching for crits
---------------------------------------------------------------------------
local me, pet
local function Crit(amount, heal, dest)
  if not DB or DB.off or not amount or amount <= 0 then return end
  if heal and not DB.heals then return end
  if DB.numbers then ShowNumber(amount, heal, dest) end
  if DB.sound then Sound() end
  if not heal then ScreenShake() end
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

local MinimapButton   -- made further down, after the settings
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("UNIT_PET")
ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "COMBAT_LOG_EVENT_UNFILTERED" then
    if DB then OnCombat() end
  elseif e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    CritSoundsDB = CritSoundsDB or {}
    DB = CritSoundsDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
  elseif e == "PLAYER_LOGIN" then
    me, pet = UnitGUID("player"), UnitGUID("pet")
    if not DB.pack and PACKS[1] then DB.pack = PACKS[1].key end
    pcall(MinimapButton)
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
    if not heal then ScreenShake() end
    if n < 3 then C_Timer.After(0.7, One) end
  end
  One()
end

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local OnOff = { { "On", true }, { "Off", false } }
ns.HelpConfig = {
  title = "Crit Sounds",
  tag = "Crit Sounds",
  settings = {
    { label = "Crit Sounds", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil end },
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
      get = function() return DB.numbers and true or false end, set = function(v) DB.numbers = v end },
    { label = "Number Size", choices = { { "Big", 36 }, { "Huge", 48 }, { "Massive", 64 } },
      get = function() return DB.size or 48 end, set = function(v) DB.size = v; ShowNumber(math.random(400, 2400), false) end },
    { label = "Shake", choices = { { "Off", 0 }, { "Normal", 1 }, { "Wild", 2 } },
      get = function() return DB.shake or 1 end, set = function(v) DB.shake = v; ShowNumber(math.random(400, 2400), false) end },
    { label = "Screen Shake", choices = { { "Off", 0 }, { "Small", 1 }, { "Big", 2 } },
      get = function() return DB.screen or 0 end, set = function(v) DB.screen = v; ScreenShake() end },
    { label = "Heal Crits", choices = OnOff,
      get = function() return DB.heals and true or false end, set = function(v) DB.heals = v end },
    { label = "Pet Crits", choices = OnOff,
      get = function() return DB.pet and true or false end, set = function(v) DB.pet = v end },
  },
  notes = {
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
    Tip:AddLine("Crit Sounds")
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
    print("|cffffd100Crit Sounds debug|r")
    print("  this session: " .. seen.hits .. " hits from you, " .. seen.crits .. " of them crits")
    print("  last hit: " .. tostring(seen.last))
    print("  on " .. tostring(not DB.off) .. ", sound " .. tostring(DB.sound) .. " (" .. (p and p.key or "no pack") .. "), numbers " ..
      tostring(DB.numbers) .. ", packs " .. #PACKS .. ", you " .. tostring(me))
    return
  elseif cmd == "test" then
    Test(); Say("three sample crits" .. ".")
  elseif cmd == "off" then
    DB.off = not DB.off or nil; Say(DB.off and "turned off" or "turned on")
  elseif cmd == "" then
    Say("a sound and a big shaking number every time you crit" .. ".")
    P("  /crits help   (" .. "all settings, and how to report a bug" .. ")")
    P("  /crits test   (" .. "three sample crits" .. ")")
  elseif ns.OpenHelp then
    ns.OpenHelp()
  end
end
