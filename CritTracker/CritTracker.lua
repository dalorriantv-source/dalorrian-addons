-- Dalorrian's Crit Tracker: your best hit and best crit with every attack, ability and heal, with when and where.
-- A quiet line in chat when you beat a record, and one clean window with all of them. /crittracker for options.

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
local UnitDebuff, UnitGUID, UnitIsUnit, UnitLevel, UnitName = SafeApi(UnitDebuff), SafeApi(UnitGUID), SafeApi(UnitIsUnit), SafeApi(UnitLevel), SafeApi(UnitName)
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo and function()
  local t = { CombatLogGetCurrentEventInfo() }
  for i = 1, #t do if issecretvalue(t[i]) then return end end
  return unpack(t)
end
local C_UnitAuras = C_UnitAuras and setmetatable({}, { __index = function(_, k)
  local f = C_UnitAuras[k]
  if type(f) ~= "function" then return f end
  return function(...)
    local r = f(...)
    if type(r) == "table" and (issecretvalue(r.spellId) or issecretvalue(r.name) or issecretvalue(r.expirationTime)) then return nil end
    if issecretvalue(r) then return nil end
    return r
  end
end })
local DB, REC   -- settings (account), records (this character)
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local DEFAULTS = { announce = "crit", pet = true, heals = true, sort = "crit", filter = "all" }
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local function Say(msg) P("|cffffd100Crit Tracker:|r " .. msg) end
local Tip = ns.Tip or GameTooltip
local CF = ns.CreateFrame or CreateFrame   -- frames whose text is translated

local function Commas(n)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  local s = tostring(n)
  while true do
    local t, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
    s = t
    if k == 0 then return s end
  end
end
local function Nice(name) return name == "Melee" and Tr("Melee") or name end   -- the one name we make up ourselves
local function Where()
  local z, sz = GetRealZoneText and GetRealZoneText() or "", GetSubZoneText and GetSubZoneText() or ""
  if sz ~= "" and sz ~= z then return sz .. ", " .. z end
  return z
end

---------------------------------------------------------------------------
-- records: one per ability, kept per character
---------------------------------------------------------------------------
local MELEE_ICON = "Interface\\Icons\\INV_Sword_04"
local function Icon(spellId, name)
  local tex
  if spellId and spellId > 0 then
    if C_Spell and C_Spell.GetSpellTexture then tex = C_Spell.GetSpellTexture(spellId) end
    if not tex and GetSpellTexture then tex = GetSpellTexture(spellId) end
  end
  if not tex and name and GetSpellTexture then
    local ok, t = pcall(GetSpellTexture, name); if ok then tex = t end
  end
  return tex or "Interface\\Icons\\INV_Misc_QuestionMark"
end

local Refresh   -- the window, further down
local function Record(name, spellId, amount, crit, heal, isPet, target)
  if not (DB and REC) or DB.off or not name then return end
  -- (1.3.4) a hit whose size is hidden makes no row: records are real numbers only
  if type(amount) ~= "number" or issecretvalue(amount) or amount <= 0 then return end
  if heal and not DB.heals then return end
  local key = (isPet and "pet:" or "") .. (heal and "heal:" or "") .. name
  local r = REC[key]
  if not r then
    r = { name = name, pet = isPet or nil, heal = heal or nil, uses = 0, crits = 0 }
    REC[key] = r
  end
  if not r.icon or r.icon:find("QuestionMark") then
    r.icon = name == "Melee" and MELEE_ICON or Icon(spellId, name)
  end
  r.uses = r.uses + 1
  if crit then r.crits = r.crits + 1 end
  if not crit then
    r.hsum, r.hn = (r.hsum or 0) + amount, (r.hn or 0) + 1   -- (1.3.4) for spotting crits
    r.hl = r.hl or {}   -- (1.3.5) the last 25 plain hits: their middle value is the ability's usual hit
    table.insert(r.hl, amount)
    if #r.hl > 25 then table.remove(r.hl, 1) end
  end
  local slot = crit and "crit" or "hit"
  local best = r[slot]
  if not best or amount > best.amt then
    local was = best and best.amt
    r[slot] = { amt = amount, when = time(), where = Where(), target = target }
    -- a quiet line in chat (crits only by default; normal hits are a lot of noise while leveling)
    if DB.announce == "all" or (DB.announce == "crit" and crit) then
      local who = (isPet and (Tr("Pet") .. " ") or "") .. Nice(name)
      local line
      if was then
        line = string.format(Tr(crit and "New best %s crit: %s (was %s)" or "New best %s hit: %s (was %s)"), who, Commas(amount), Commas(was))
      else
        line = string.format(Tr(crit and "First %s crit: %s" or "First %s hit: %s"), who, Commas(amount))
      end
      print("|cffffd100" .. Tr("Crit Tracker") .. ":|r " .. line)
    end
    -- (1.3.0) /crittracker whisper Name: beaten records go to a friend too (not first-ever ones, so leveling
    -- doesn't flood them, and at most one every 5 seconds). The friend sees English: it's your whisper
    if DB.whisper and was and crit and SendChatMessage and (GetTime() - (ns.lastWhisper or -10)) >= 5 then
      ns.lastWhisper = GetTime()
      local who = (isPet and "Pet " or "") .. Nice(name)
      pcall(SendChatMessage, string.format("Crit Tracker: new best %s crit: %s (was %s)", who, Commas(amount), Commas(was)), "WHISPER", nil, DB.whisper)
    end
  end
  if Refresh then Refresh() end
end

local me, pet
local function OnCombat()
  local _, sub, _, src, _, _, _, _, destName = CombatLogGetCurrentEventInfo()
  if not src then return end
  me = me or UnitGUID("player")
  local isPet = pet and src == pet
  if src ~= me and not (isPet and DB.pet) then return end
  if sub == "SWING_DAMAGE" then
    local amount, _, _, _, _, _, crit = select(12, CombatLogGetCurrentEventInfo())
    Record("Melee", nil, amount, crit, false, isPet, destName)
  elseif sub == "RANGE_DAMAGE" or sub == "SPELL_DAMAGE" or sub == "SPELL_PERIODIC_DAMAGE" then
    local spellId, spellName, _, amount, _, _, _, _, _, crit = select(12, CombatLogGetCurrentEventInfo())
    Record(spellName, spellId, amount, crit, false, isPet, destName)
  elseif sub == "SPELL_HEAL" or sub == "SPELL_PERIODIC_HEAL" then
    local spellId, spellName, _, amount, _, _, crit = select(12, CombatLogGetCurrentEventInfo())
    Record(spellName, spellId, amount, crit, true, isPet, destName)
  end
end

---------------------------------------------------------------------------
-- (1.1.0) WoW: Forever doesn't let addons read combat events, so this reads the game's own feed of hits on
-- your target (the numbers on a target portrait) and works out which ability did each one:
--   * a hit right after you cast something is that ability
--   * a magic hit with nothing just cast is a tick from the last thing you cast (a DoT like Serpent Sting)
--   * a physical hit with nothing just cast is your auto attack (Auto Shot, or Melee)
-- It's a good guess, not perfect: in a group other players' hits on the same mob can slip in, and a pet's
-- hits count as your auto attack.
---------------------------------------------------------------------------
local feedSeen = { events = 0, hits = 0, crits = 0, hidden = 0, log = {} }
local function Log(line)   -- the last few decisions, for /crittracker debug
  local L = feedSeen.log
  L[#L + 1] = line
  if #L > 8 then table.remove(L, 1) end
end
local cast = { t = 0 }   -- your last cast that could hit something
local recent = 0         -- when you last cast anything
local function SpellName(id)
  if C_Spell and C_Spell.GetSpellName then local ok, n = pcall(C_Spell.GetSpellName, id); if ok and n then return n end end
  if GetSpellInfo then local ok, n = pcall(GetSpellInfo, id); if ok and n then return n end end
end
local AUTO = { [75] = true, [6603] = true, [5019] = true }   -- Auto Shot, Auto Attack, Shoot (wands)
local function Harmful(id)
  local f = (C_Spell and C_Spell.IsSpellHarmful) or IsHarmfulSpell
  if not f then return true end
  local ok, v = pcall(f, id)
  if not ok then ok, v = pcall(f, SpellName(id) or "") end
  return not ok or v and true or false
end
local function Helpful(id)
  local f = (C_Spell and C_Spell.IsSpellHelpful) or IsHelpfulSpell
  if not f then return true end
  local ok, v = pcall(f, id)
  return not ok or v and true or false
end
local function OnCast(id)
  if not id or AUTO[id] then return end
  recent = GetTime()
  local name = SpellName(id)
  if not name then return end
  local harm, help = Harmful(id), Helpful(id)
  -- (1.1.3) only a spell that's clearly a heal or buff is left out; when the game can't say, it counts
  cast = { id = id, name = name, t = GetTime(), harm = harm or not help, help = help }
end
-- (1.1.3) this client moved these checks under C_Spell; the old names quietly said "no", so every Auto Shot
-- counted as Melee and, in a group, most hits were thrown away
local function AutoRepeat(id)
  local f = (C_Spell and C_Spell.IsAutoRepeatSpell) or IsAutoRepeatSpell
  if not f then return false end
  local ok, on = pcall(f, id)
  if ok and on then return true end
  local n = SpellName(id)
  if n then ok, on = pcall(f, n); if ok and on then return true end end
  return false
end
local function Meleeing()
  local f = (C_Spell and C_Spell.IsCurrentSpell) or IsCurrentSpell
  if not f then return false end
  local ok, on = pcall(f, 6603)
  return ok and on and true or false
end
local function AutoName()
  for _, id in ipairs({ 75, 5019 }) do
    if AutoRepeat(id) then return SpellName(id) or "Auto Shot", id end
  end
  return "Melee"
end
local function Acting()
  if GetTime() - recent < 1.5 then return true end
  return Meleeing() or AutoRepeat(75) or AutoRepeat(5019)
end
-- (1.1.2) a sting, curse or mark leaves a debuff and doesn't hit on its own: a physical hit right after one
-- of those is your auto attack, not the spell
local function Debuffed(c)
  local found = false
  pcall(function()
    if C_UnitAuras and C_UnitAuras.GetDebuffDataByIndex then
      for i = 1, 40 do
        local a = C_UnitAuras.GetDebuffDataByIndex("target", i)
        if not a then break end
        if a.spellId == c.id or a.name == c.name then found = true break end
      end
    elseif UnitDebuff then
      for i = 1, 40 do
        local n, _, _, _, _, _, _, _, _, id = UnitDebuff("target", i)
        if not n then break end
        if id == c.id or n == c.name then found = true break end
      end
    end
  end)
  return found
end
local function OnFeed(unit, action, flag, amount, school)
  feedSeen.events = feedSeen.events + 1
  -- (1.3.4) the damage meter gives the sizes: the feed only says when your target or you took a crit
  if ns.meter and ns.meter.ok > 0 then
    local okC, isCrit = pcall(function() return flag == "CRITICAL" end)
    if okC then ns.meter.flagOK = (ns.meter.flagOK or 0) + 1 else ns.meter.flagHidden = (ns.meter.flagHidden or 0) + 1 end
    if okC and isCrit then local f = ns.meter.flags; f[#f + 1] = GetTime(); ns.meter.flagCrit = (ns.meter.flagCrit or 0) + 1 end
    return
  end
  if (feedSeen.chat or 0) > 0 then return end   -- (1.3.2) the combat log lines work this session: they're exact
  local ok, isHit, isHeal, isCrit = pcall(function()
    return action == "WOUND", action == "HEAL", flag == "CRITICAL"
  end)
  if not ok then feedSeen.hidden = feedSeen.hidden + 1 return end
  if not (isHit or isHeal) then return end
  -- (1.3.3) a hidden amount still counts the hit and whether it crit
  local readable = type(amount) == "number" and not issecretvalue(amount) and pcall(function() return amount > 0 end)
  if not readable then feedSeen.hidden = feedSeen.hidden + 1; amount = nil
  elseif amount <= 0 then return end
  local now, target = GetTime(), nil
  pcall(function() target = UnitName("target") end)
  if isHeal then
    -- your heals: on you, or on a friendly target (not both, or a self-heal would count twice)
    if unit == "target" then
      local mine = false
      pcall(function() mine = UnitIsUnit("target", "player") end)
      if mine then return end
    end
    if cast.help and now - cast.t < 1.5 then
      Record(cast.name, cast.id, amount, isCrit, true, false, unit == "player" and UnitName("player") or target)
      feedSeen.hits = feedSeen.hits + 1; if isCrit then feedSeen.crits = feedSeen.crits + 1 end
    end
    return
  end
  if unit ~= "target" then return end
  if IsInGroup and IsInGroup() and not Acting() then feedSeen.skipped = (feedSeen.skipped or 0) + 1 return end   -- probably someone else's hit
  local name, id
  if cast.harm and not cast.used and now - cast.t < 1.2 and not (school == 1 and Debuffed(cast)) then
    name, id = cast.name, cast.id; cast.used = true
  elseif school and school ~= 1 and cast.harm and now - cast.t < 18 then
    name, id = cast.name, cast.id   -- a tick from what you cast last
  elseif school == 1 or school == nil then
    -- in a group a plain physical hit could be anyone's (a rogue's stab, a pet's bite): only counted solo
    if not Acting() or (IsInGroup and IsInGroup()) then feedSeen.skipped = (feedSeen.skipped or 0) + 1; Log(tostring(amount or "hidden") .. " physical: skipped (auto attack in a group, or not attacking)") return end
    name, id = AutoName()
  else
    Log(tostring(amount or "hidden") .. " school " .. tostring(school) .. ": skipped (no spell cast lately)")
    return
  end
  Log(tostring(amount or "hidden") .. (isCrit and " crit" or "") .. " school " .. tostring(school) .. " -> " .. tostring(name))
  feedSeen.hits = feedSeen.hits + 1; if isCrit then feedSeen.crits = feedSeen.crits + 1 end
  feedSeen.last = name .. " " .. tostring(amount or "hidden") .. (isCrit and " crit" or "")
  Record(name, id, amount, isCrit, false, false, target)
end
local feed = CreateFrame("Frame")
feed:SetScript("OnEvent", function(_, e, unit, a, b, c, d)
  -- (1.3.1) only a hidden unit is skipped here: 1.2.1 skipped every hit with any hidden detail (like its spell
  -- school), so hits that could be read were lost too. Hits that can't be read are still counted and skipped below
  if issecretvalue(unit) then return end
  if not DB or DB.off then return end
  if e == "UNIT_SPELLCAST_SUCCEEDED" then pcall(OnCast, b) return end   -- unit, castGUID, spellID
  local ok = pcall(OnFeed, unit, a, b, c, d)
  if not ok then feedSeen.hidden = feedSeen.hidden + 1 end
end)
-- (1.3.2) Forever hides the damage amount from addons on the target feed, so records come from the combat log
-- lines the game writes in chat instead ("Your Arcane Shot hit Boar 56 Arcane. (Critical)"), the same way
-- Dalorrian's Crit Numbers reads its crits. Only your own lines (starting with You or Your) count.
local CRIT_MARK = TEXT_MODE_A_STRING_RESULT_CRITICAL or "(Critical)"
local CRIT_SPELL = TEXT_MODE_A_STRING_RESULT_CRITICAL_SPELL
local function Clean(t)
  t = t:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|H.-|h(.-)|h", "%1"):gsub("|T.-|t", "")
  return (t:gsub("^%s+", ""))
end
local lastLine, lastAt = nil, 0
local function ReadLine(text)
  if type(text) ~= "string" or not DB or DB.off then return end
  local t = Clean(text)
  t = t:gsub("^%[?%d%d?:%d%d[:%d]*%s*[AaPp]?%.?[Mm]?%.?%]?%s*", "")   -- (1.3.3) a chat timestamp in front
  if t:find("%d") and (t:find(" hit", 1, true) or t:lower():find("crit", 1, true)) then feedSeen.sample = t:sub(1, 120) end
  local name, heal, critWord
  local your = t:match("^Your (.+)$")
  if your then
    -- the spell's name runs up to the first hit / crit / heal word ("Your Sinister Strike hit ...")
    local at, word
    for _, w in ipairs({ " hit ", " hits ", " crit ", " crits ", " critically ", " heal ", " heals " }) do
      local p = your:find(w, 1, true)
      if p and (not at or p < at) then at, word = p, w end
    end
    if not at or at < 2 then return end
    heal = word == " heal " or word == " heals " or (word == " critically " and your:find(" critically heal", 1, true) == at)
    name = your:sub(1, at - 1)
    critWord = word:find("crit", 1, true) ~= nil
  else
    local verb = t:match("^You (%a+) ")
    if not verb then return end
    verb = verb:lower()
    if not (verb:find("^hit") or verb:find("^crit")) then return end
    critWord = verb:find("^crit") ~= nil
    name = AutoName()
  end
  local crit = t:find(CRIT_MARK, 1, true) or (CRIT_SPELL and t:find(CRIT_SPELL, 1, true)) or critWord
  local cut = t:find(CRIT_MARK, 1, true) or #t + 1
  local body = t:sub(1, cut - 1):gsub("%b()", "")
  local amount
  for n in body:gmatch("%d[%d,%.]*") do amount = n end
  amount = amount and tonumber((amount:gsub("[,%.]", "")))
  if not amount or amount <= 0 then return end
  -- one line can show up in two chat windows: count it once
  local now = GetTime()
  if t == lastLine and now - lastAt < 0.2 then return end
  lastLine, lastAt = t, now
  feedSeen.chat = (feedSeen.chat or 0) + 1
  local id = cast.name == name and cast.id or nil
  local target
  pcall(function() target = UnitName("target") end)
  if heal then target = nil end
  feedSeen.last = name .. " " .. amount .. (crit and " crit" or "") .. " (chat)"
  Record(name, id, amount, crit and true or false, heal or false, false, target)
end
local hookedChat = {}
local function HookChat()
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local f = _G["ChatFrame" .. i]
    if f and not hookedChat[f] and f.AddMessage then
      hookedChat[f] = true
      hooksecurefunc(f, "AddMessage", function(_, text) pcall(ReadLine, text) end)
    end
  end
end
-- (1.3.4) Forever hides each hit's size from addons, but the game's own damage meter (C_DamageMeter) shows your
-- damage per ability as it adds up. Every time an ability's total goes up, the step is that hit's size, exactly,
-- and it's always yours (the meter is read for you alone). The game's hit feed says when your target took a crit:
-- a step that lands with one, and is clearly bigger than that ability's usual hit, is a crit.
local meter = { last = {}, lastHeal = {}, lastPet = {}, crit = 0, ok = 0, hidden = 0, flags = {}, pending = {} }
local function MeterSpells(kind, guid)
  local DM, E = C_DamageMeter, Enum
  if not (guid and DM and DM.GetCombatSessionSourceFromType and E and E.DamageMeterSessionType and E.DamageMeterType) then return end
  local ok, src = pcall(DM.GetCombatSessionSourceFromType, E.DamageMeterSessionType.Current, E.DamageMeterType[kind], guid)
  if ok and src and (issecretvalue(src) or issecretvalue(src.combatSpells)) then meter.hidden = meter.hidden + 1; meter.blindNow = true return end
  if not ok or not src then return end
  return src.combatSpells
end
-- every ability whose total went up since the last look: { name, id, step, heal, pet }
-- (1.3.7) how much of one meter line is your pet's. Its details can be one table or a list of them (one per who hit):
-- true = all pet, false = all yours, "part" = shared, with the pet's amount
local function PetPart(sp)
  local d = sp.combatSpellDetails
  if type(d) ~= "table" then return false end
  if d.isPet ~= nil then return d.isPet == true end
  local pet, n, all = 0, 0, 0
  for _, x in ipairs(d) do
    if type(x) == "table" then
      all = all + 1
      if x.isPet == true then n = n + 1; if type(x.amount) == "number" then pet = pet + x.amount end end
    end
  end
  if n == 0 then return false end
  if n == all then return true end
  return "part", pet
end
-- (1.3.7) the meter can list one ability more than once (one line per mob it hit, or yours and your pet's):
-- they're added up per ability first, or the step between two lines looked like a hit (Melee 145 over and over)
local function MeterSteps(kind, guid, last, heal, pet, out, skipPet)
  local sums, order = {}, {}
  local function Add(id, isPet, amt)
    local key = id .. (isPet and ":p" or "")
    if not sums[key] then sums[key] = { id = id, pet = isPet, total = 0 }; order[#order + 1] = key end
    sums[key].total = sums[key].total + amt
  end
  for _, sp in ipairs(MeterSpells(kind, guid) or {}) do
    local id, total = sp.spellID, sp.totalAmount
    if issecretvalue(id) or issecretvalue(total) then meter.hidden = meter.hidden + 1; meter.blindNow = true
    elseif type(id) == "number" and type(total) == "number" then
      meter.ok = meter.ok + 1
      local isPet, petAmt = pet, nil
      if not isPet then local ok, a, b = pcall(PetPart, sp); if ok then isPet, petAmt = a, b else isPet = false end end
      if isPet == "part" and type(petAmt) == "number" then
        Add(id, false, total - petAmt); Add(id, true, petAmt)
      else
        Add(id, isPet == true, total)
      end
    end
  end
  -- (1.3.9) per ability: a line the game hid (or left out) on the last look only catches up on its next one.
  -- This used to be one switch for everything, so a single hidden line (a hunter's pet, every look) stopped
  -- every record
  local seenAt = last.__t or {}
  last.__t = seenAt
  local tick = meter.tick or 0
  for _, key in ipairs(order) do
    local e = sums[key]
    local gap = seenAt[key] ~= nil and seenAt[key] < tick - 1
    seenAt[key] = tick
    local was = last[key] or 0
    -- (1.3.8) a smaller total is a mob's line leaving the meter, not a new fight (a new fight is caught by its
    -- session changing): it's only noted, never read as one giant hit
    local step = (e.total >= was) and math.floor(e.total - was + 0.5) or 0
    last[key] = e.total
    if gap and step > 0 then meter.gapSkip = (meter.gapSkip or 0) + 1; step = 0 end
    if step > 0 then
      local id = e.id
      local name = (id == 75 and (SpellName(75) or "Auto Shot")) or (id == 6603 and "Melee") or SpellName(id)
      -- the pet's own source already has its hits: don't count them twice
      if name and not (skipPet and e.pet) then out[#out + 1] = { name = name, id = id, step = step, heal = heal, pet = e.pet } end
    end
  end
end
local function Usual(s)
  local key = (s.pet and "pet:" or "") .. (s.heal and "heal:" or "") .. s.name
  local r = REC and REC[key]
  -- (1.3.5) the middle of the last plain hits: a few crits counted as hits by mistake can't drag it up
  -- (1.3.6) and the first few plain hits of a fresh ability, kept for this session before any record is written
  local list = (r and type(r.hl) == "table" and #r.hl >= 4) and r.hl or (meter.samples and meter.samples[key])
  if type(list) == "table" and #list >= 4 then
    local t = {}
    for i, v in ipairs(list) do t[i] = v end
    table.sort(t)
    return t[math.max(1, math.floor(#t * 0.3 + 0.5))], true   -- (1.3.8) the lower third: a few hits added together can't pull it up
  end
  -- (1.3.4) the average plain hit, not the best one: one missed crit sitting in Best Hit hid every crit after it
  if r and (r.hn or 0) >= 3 then return r.hsum / r.hn end
  return r and r.hit and r.hit.amt and r.hit.amt * 0.8
end
-- a new fight starts the meter over: every ability counts from zero again
local function NewFight()
  local DM, E = C_DamageMeter, Enum
  if not (DM and DM.GetCombatSessionFromType and E and E.DamageMeterSessionType) then return false end
  local ok, sess = pcall(DM.GetCombatSessionFromType, E.DamageMeterSessionType.Current, E.DamageMeterType.DamageDone)
  if not ok or type(sess) ~= "table" or issecretvalue(sess) then return false end
  local id = sess.sessionID or sess.combatSessionID or sess.id
  local dur = sess.durationSeconds or sess.duration
  if issecretvalue(id) then id = nil end
  if issecretvalue(dur) or type(dur) ~= "number" then dur = nil end
  local new = (id ~= nil and meter.sess ~= nil and id ~= meter.sess) or (dur and meter.dur and dur < meter.dur - 0.5)
  meter.sess, meter.dur = id or meter.sess, dur or meter.dur
  return new and true or false
end
local function MeterTick()
  if not DB or DB.off or not REC then return end
  if NewFight() then wipe(meter.last); wipe(meter.lastHeal); wipe(meter.lastPet); meter.fresh = true end
  local steps = {}
  meter.tick = (meter.tick or 0) + 1
  meter.blindNow = false
  local pg = UnitGUID("pet")
  local petList = pg and MeterSpells("DamageDone", pg)
  local petSource = petList and #petList > 0
  if petSource and DB.pet ~= false then MeterSteps("DamageDone", pg, meter.lastPet, false, true, steps) end   -- (1.3.4) your pet's own hits
  local before = #steps
  MeterSteps("DamageDone", UnitGUID("player"), meter.last, false, false, steps, petSource)
  if DB.pet == false then for i = #steps, before + 1, -1 do if steps[i].pet then table.remove(steps, i) end end end
  MeterSteps("HealingDone", UnitGUID("player"), meter.lastHeal, true, false, steps)
  -- (1.3.4) the game hid the meter for a while (some fights): the next readable look only catches up, because
  -- its steps hold many hits added together and would make fake records
  if meter.fresh then meter.fresh = false; meter.caught = (meter.caught or 0) + 1 return end   -- (1.3.8) a new fight's first look only learns the totals
  if #steps == 0 then return end
  -- (1.3.4) each step waits a moment before it's written down: the game's crit flag can come just before or just
  -- after the meter moves. A flag goes to one step only, the one furthest above its ability's usual hit (a crit lands
  -- at 1.5x to 2x), and only if it clears that by a good margin.
  local now = GetTime()
  for _, st in ipairs(steps) do st.t = now; meter.pending[#meter.pending + 1] = st end
end
local function MeterFlush()
  local now = GetTime()
  local flags, pending = meter.flags, meter.pending
  while flags[1] and now - flags[1] > 2 do table.remove(flags, 1) end
  local ready = {}
  for i = #pending, 1, -1 do if now - pending[i].t >= 0.3 then table.insert(ready, 1, table.remove(pending, i)) end end
  if #ready == 0 then return end
  local order = {}
  for _, st in ipairs(ready) do
    local u, solid = Usual(st)
    st.ratio = u and u > 0 and (st.step / u) or 1.4
    st.solid = solid
    order[#order + 1] = st
  end
  table.sort(order, function(a, b) return a.ratio > b.ratio end)
  -- (1.3.5) the crit flag is often hidden on Forever: when none can be read, a crit is spotted by its size alone.
  -- Crits land at 1.5x (spells) to 2x+ (attacks) of the usual hit; more than 2.6x is two hits added together.
  -- Auto attack needs 1.8x, because a main hand and off hand hit in the same moment add up to about 1.5x
  local noFlags = (meter.flagCrit or 0) == 0
  for _, st in ipairs(order) do
    if not st.heal and st.ratio >= 1.3 then
      for k, ft in ipairs(flags) do
        if math.abs(ft - st.t) <= 0.6 then st.crit = true; table.remove(flags, k); break end
      end
      -- (1.3.8) the size alone only decides when the game never shows its crit flag: where it does, two hits added
      -- together look exactly like one crit, so a big step without a flag is skipped instead
      local flagsWork = (meter.flagOK or 0) > 0
      if not st.crit and st.solid and st.ratio <= 2.6 and not flagsWork then
        local need = (st.id == 6603) and 1.8 or 1.4
        if st.ratio >= need then st.crit = true; meter.bySize = (meter.bySize or 0) + 1 end
      end
      if not st.crit and flagsWork and st.ratio >= 1.5 then st.unsure = true end
    end
  end
  local target
  pcall(function() target = UnitName("target") end)
  meter.samples = meter.samples or {}
  meter.log = meter.log or {}
  for _, st in ipairs(ready) do
    local key = (st.pet and "pet:" or "") .. (st.heal and "heal:" or "") .. st.name
    local note
    if not st.heal and not st.solid then
      -- (1.3.6) a fresh ability: its first plain hits only teach its usual size. Records start once it's known,
      -- so a first look that added several hits together can't sit in Best Hit
      local l = meter.samples[key] or {}
      meter.samples[key] = l
      l[#l + 1] = st.step
      if #l > 25 then table.remove(l, 1) end
      note = "learning"
    elseif not st.heal and (st.ratio > 2.6 or st.unsure) then
      -- (1.3.6) far above any crit: the meter added several hits together (it updates in bursts in dungeons)
      meter.batch = (meter.batch or 0) + 1
      note = "skipped, several hits at once"
    else
      Record(st.name, st.id, st.step, st.crit, st.heal, st.pet, (not st.heal) and target or nil)
      note = st.crit and "CRIT" or "hit"
    end
    table.insert(meter.log, string.format("%s %d (x%.1f) %s", st.name, st.step, st.ratio or 0, note))
    if #meter.log > 10 then table.remove(meter.log, 1) end
  end
end
local function MeterStart()
  if meter.started or not C_DamageMeter then return end
  meter.started = true
  -- the totals so far this fight count as already seen, so a /reload mid-fight doesn't make one giant "hit"
  pcall(function()   -- (1.3.7) the same adding-up as every look after
    MeterSteps("DamageDone", UnitGUID("player"), meter.last, false, false, {})
    MeterSteps("HealingDone", UnitGUID("player"), meter.lastHeal, true, false, {})
    if UnitGUID("pet") then MeterSteps("DamageDone", UnitGUID("pet"), meter.lastPet, false, true, {}) end
  end)
  local f, acc = CreateFrame("Frame"), 0
  f:SetScript("OnUpdate", function(_, el)
    acc = acc + el
    if acc < 0.1 then return end
    acc = 0
    pcall(MeterTick)
    pcall(MeterFlush)
  end)
end
ns.meter = meter
local function WatchFeed()
  pcall(MeterStart)
  pcall(HookChat)
  if not feed.RegisterUnitEvent then return end
  pcall(feed.RegisterUnitEvent, feed, "UNIT_COMBAT", "target", "player")
  pcall(feed.RegisterUnitEvent, feed, "UNIT_SPELLCAST_SUCCEEDED", "player")
end

---------------------------------------------------------------------------
-- the window: every ability, its best crit and best hit; hover a row for when and where
---------------------------------------------------------------------------
local win
local WW, ROWH = 540, 20   -- (1.2.0) wider for the Best Heal column
local COLS = {
  -- (1.1.4) no Crit % column: just the ability and its two records, ending before the scroll bar
  { key = "name", label = "Ability", x = 30, w = 200, justify = "LEFT" },
  { key = "crit", label = "Best Crit", x = 240, w = 85, justify = "RIGHT" },
  { key = "hit", label = "Best Hit", x = 329, w = 85, justify = "RIGHT" },
  -- (1.2.0) heals get their own column in green: Best Crit and Best Hit are for damage
  { key = "heal", label = "Best Heal", x = 418, w = 85, justify = "RIGHT" },
}
local function Solid(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetTexture(W); t:SetVertexColor(r, g, b, a or 1)
  return t
end
local function Text(parent, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  return fs
end
local function FlatButton(parent, w, label, onClick)
  local b = CF("Button", nil, parent)
  b:SetSize(w, 20)
  b.bg = Solid(b, "BACKGROUND", 0.14, 0.15, 0.19); b.bg:SetAllPoints()
  b.label = Text(b); b.label:SetPoint("CENTER"); b.label:SetJustifyH("CENTER"); b.label:SetText(label)
  b.SetOn = function(self, on)
    self.on = on
    if on then self.bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9); self.label:SetTextColor(0.1, 0.1, 0.1)
    else self.bg:SetVertexColor(0.14, 0.15, 0.19, 1); self.label:SetTextColor(0.85, 0.85, 0.9) end
  end
  b:SetScript("OnEnter", function(self) if not self.on then self.bg:SetVertexColor(0.22, 0.23, 0.28, 1) end end)
  b:SetScript("OnLeave", function(self) self:SetOn(self.on) end)
  b:SetScript("OnClick", onClick)
  b:SetOn(false)
  return b
end

-- (1.2.0) a heal's record is its biggest heal, crit or not
local function BestHeal(r)
  if not r.heal then return nil end
  local c, h = r.crit, r.hit
  if c and (not h or c.amt >= h.amt) then return c, true end
  return h, false
end

local function List()
  local out = {}
  for _, r in pairs(REC or {}) do
    if DB.filter == "all" or (DB.filter == "heal") == (r.heal and true or false) then out[#out + 1] = r end
  end
  local function v(r, k)
    if k == "name" then return r.name end
    if k == "pct" then return r.uses > 0 and r.crits / r.uses or 0 end
    if k == "heal" then local b = BestHeal(r); return b and b.amt or 0 end
    if r.heal then return 0 end   -- heals sort under Best Heal, not Best Crit or Best Hit
    return r[k] and r[k].amt or 0
  end
  if DB.sort == "pct" then DB.sort = "crit" end   -- the old Crit % sort
  local k = DB.sort or "crit"
  table.sort(out, function(a, b)
    local x, y = v(a, k), v(b, k)
    if x == y then return a.name < b.name end
    if k == "name" then return x < y end
    return x > y
  end)
  return out
end

local function Build()
  win = CF("Frame", "CritTrackerFrame", UIParent, "BackdropTemplate")
  win:SetSize(WW, 400)
  win:SetPoint("CENTER")
  win:SetFrameStrata("DIALOG")
  win:SetClampedToScreen(true)
  win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  win:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
  win:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
  win:SetBackdropBorderColor(0.25, 0.26, 0.3, 1)
  tinsert(UISpecialFrames, "CritTrackerFrame")   -- Escape closes it

  local title = Text(win, "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 14, -12); title:SetText("Crit Tracker")
  local who = Text(win, "GameFontDisableSmall"); who:SetPoint("LEFT", title, "RIGHT", 10, -1)
  win.who = who
  local close = CF("Button", nil, win)
  close:SetSize(20, 20); close:SetPoint("TOPRIGHT", -8, -8)
  close.label = Text(close, "GameFontHighlight"); close.label:SetPoint("CENTER"); close.label:SetText("x")
  close:SetScript("OnClick", function() win:Hide() end)

  -- All / Damage / Heals
  win.filters = {}
  local fx = 14
  for _, f in ipairs({ { "All", "all" }, { "Damage", "dmg" }, { "Heals", "heal" } }) do
    local b = FlatButton(win, 70, f[1], function() DB.filter = f[2]; Refresh() end)
    b:SetPoint("TOPLEFT", fx, -40); b.value = f[2]
    win.filters[#win.filters + 1] = b
    fx = fx + 74
  end
  -- reset: click twice
  local reset = FlatButton(win, 110, "Reset Records", nil)
  reset:SetPoint("TOPRIGHT", -14, -40)
  reset:SetScript("OnClick", function(self)
    if self.armed then
      wipe(REC); self.armed = nil; self.label:SetText("Reset Records"); Refresh(); Say("records cleared for this character")
    else
      self.armed = true; self.label:SetText("Click Again")
      C_Timer.After(3, function() if self.armed then self.armed = nil; self.label:SetText("Reset Records") end end)
    end
  end)

  -- column headers: click to sort
  win.heads = {}
  for _, c in ipairs(COLS) do
    local h = CF("Button", nil, win)
    h:SetSize(c.w, 18); h:SetPoint("TOPLEFT", c.x, -70)
    h.label = Text(h, "GameFontNormalSmall"); h.label:SetAllPoints(); h.label:SetJustifyH(c.justify); h.label:SetText(c.label)
    h:SetScript("OnClick", function() DB.sort = c.key; Refresh() end)
    h.key = c.key
    win.heads[#win.heads + 1] = h
  end
  local line = Solid(win, "ARTWORK", GOLD[1], GOLD[2], GOLD[3], 0.35)
  line:SetPoint("TOPLEFT", 14, -90); line:SetPoint("TOPRIGHT", -14, -90); line:SetHeight(1)

  local sf = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 0, -94); sf:SetPoint("BOTTOMRIGHT", -28, 34)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(WW - 28, 10)
  sf:SetScrollChild(child)
  win.child, win.rows = child, {}

  win.empty = Text(win, "GameFontDisable"); win.empty:SetPoint("TOP", 0, -120); win.empty:SetWidth(WW - 60); win.empty:SetJustifyH("CENTER")
  win.empty:SetText("Nothing yet. Go hit something")
  win.foot = Text(win, "GameFontDisableSmall"); win.foot:SetPoint("BOTTOMLEFT", 14, 12)
  win.foot:SetText("Hover a row for when and where. Click a column to sort")
  win:Hide()
end

local function Row(i)
  local r = win.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, win.child)
  r:SetSize(WW - 28, ROWH)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROWH)
  r.hl = Solid(r, "BACKGROUND", 1, 1, 1, 0); r.hl:SetAllPoints()
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", 12, 0)
  r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  r.cols = {}
  for _, c in ipairs(COLS) do
    local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")   -- plain: spell names stay as the game names them
    fs:SetPoint("LEFT", c.x, 0); fs:SetWidth(c.w); fs:SetJustifyH(c.justify); fs:SetWordWrap(false)
    r.cols[c.key] = fs
  end
  r:SetScript("OnEnter", function(self)
    self.hl:SetVertexColor(1, 1, 1, 0.06)
    local d = self.data
    if not d then return end
    Tip:SetOwner(self, "ANCHOR_RIGHT")
    -- (1.1.1) one block per record: the number on the right, then Target / Where / When lined up under it
    GameTooltip:AddLine((d.pet and (Tr("Pet") .. ": ") or "") .. Nice(d.name), GOLD[1], GOLD[2], GOLD[3])
    local blocks = { { "crit", "Best Crit", { 1, 0.82, 0 } }, { "hit", "Best Hit", { 1, 1, 1 } } }
    if d.heal then
      local hb, wasCrit = BestHeal(d)
      blocks = { { hb, wasCrit and "Best Heal (Crit)" or "Best Heal", { 0.4, 1, 0.47 } } }
    end
    for _, s in ipairs(blocks) do
      local b = type(s[1]) == "table" and s[1] or d[s[1]]
      if b then
        GameTooltip:AddLine(" ")
        GameTooltip:AddDoubleLine(Tr(s[2]), Commas(b.amt), 1, 1, 1, s[3][1], s[3][2], s[3][3])
        if b.target then GameTooltip:AddDoubleLine("    " .. Tr("Target"), b.target, 0.6, 0.6, 0.6, 0.9, 0.9, 0.9) end
        if b.where and b.where ~= "" then GameTooltip:AddDoubleLine("    " .. Tr("Where"), b.where, 0.6, 0.6, 0.6, 0.9, 0.9, 0.9) end
        if b.when then GameTooltip:AddDoubleLine("    " .. Tr("When"), date("%b %d, %I:%M %p", b.when), 0.6, 0.6, 0.6, 0.9, 0.9, 0.9) end
      end
    end
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", function(self) self.hl:SetVertexColor(1, 1, 1, 0); GameTooltip:Hide() end)
  win.rows[i] = r
  return r
end

Refresh = function()
  if not (win and win:IsShown()) then return end
  local list = List()
  for _, b in ipairs(win.filters) do b:SetOn(DB.filter == b.value) end
  for _, h in ipairs(win.heads) do
    -- (1.1.5) fixed colors that match the numbers under them: Best Hit white, Best Heal green, everything else gold
    if h.key == "hit" then h.label:SetTextColor(1, 1, 1)
    elseif h.key == "heal" then h.label:SetTextColor(0.4, 1, 0.47)
    else h.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end
  end
  win.who:SetText((UnitName("player") or "") .. "  ·  " .. Tr("Level") .. " " .. (UnitLevel("player") or ""))
  for i, d in ipairs(list) do
    local r = Row(i)
    r.data = d
    r.icon:SetTexture(d.icon)
    r.cols.name:SetText((d.pet and ("|cff9fd6ff" .. Tr("Pet") .. ":|r ") or "") .. (d.heal and "|cff66ff77" or "") .. Nice(d.name) .. (d.heal and "|r" or ""))
    local dash = "|cff666666-|r"
    if d.heal then
      local hb = BestHeal(d)
      r.cols.crit:SetText(dash); r.cols.hit:SetText(dash)
      r.cols.heal:SetText(hb and ("|cff66ff77" .. Commas(hb.amt) .. "|r") or dash)
    else
      r.cols.crit:SetText(d.crit and ("|cffffd100" .. Commas(d.crit.amt) .. "|r") or dash)
      r.cols.hit:SetText(d.hit and Commas(d.hit.amt) or dash)
      r.cols.heal:SetText(dash)
    end
    r:Show()
  end
  for i = #list + 1, #win.rows do win.rows[i]:Hide(); win.rows[i].data = nil end
  win.child:SetHeight(math.max(10, #list * ROWH))
  win.empty:SetShown(#list == 0)
end

local function Toggle()
  if not REC then return end
  if not win then Build() end
  if win:IsShown() then win:Hide() else win:Show(); Refresh() end
end
ns.ToggleRecords = Toggle

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local MinimapButton   -- further down
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("UNIT_PET")
-- older clients still hand addons the combat log; Forever (which has C_DamageMeter) blocks asking for it
if not C_DamageMeter then ev:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED") end
ev:SetScript("OnEvent", function(_, e, a1)
  if AnySecret(a1) then return end   -- (Forever) a hidden value: nothing to do with it
  if e == "COMBAT_LOG_EVENT_UNFILTERED" then
    if DB then OnCombat() end
  elseif e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    CritTrackerDB = CritTrackerDB or {}
    DB = CritTrackerDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    CritTrackerChar = CritTrackerChar or {}
    CritTrackerChar.records = CritTrackerChar.records or {}
    REC = CritTrackerChar.records
    -- (1.3.4) 1.3.3 made rows with only a count and no numbers: those go
    for k, r in pairs(REC) do if type(r) == "table" and not (r.crit or r.hit) then REC[k] = nil end end
    -- (1.3.6) the damage meter added several hits together in dungeons: damage rows start over once more
    if not CritTrackerChar.fix138 then   -- (1.3.8) several hits added together got through: damage records start over
      CritTrackerChar.fix138, CritTrackerChar.fix137, CritTrackerChar.fix136, CritTrackerChar.fix135 = true, true, true, true
      for k, r in pairs(REC) do if type(r) == "table" and not r.heal then REC[k] = nil end end
    end
    if not CritTrackerChar.fix136 then
      CritTrackerChar.fix136, CritTrackerChar.fix135 = true, true
      for k, r in pairs(REC) do if type(r) == "table" and not r.heal then REC[k] = nil end end
    end
    -- (1.3.5) damage rows with no crit ever had their crits land in Best Hit: that column starts over for them
    if not CritTrackerChar.fix135 then
      CritTrackerChar.fix135 = true
      for k, r in pairs(REC) do
        if type(r) == "table" and not r.heal and not r.crit and r.hit then r.hit, r.hsum, r.hn, r.hl = nil, nil, nil, nil; r.uses, r.crits = 0, 0 end
        if type(r) == "table" and not (r.crit or r.hit) then REC[k] = nil end
      end
    end
  elseif e == "PLAYER_LOGIN" then
    me, pet = UnitGUID("player"), UnitGUID("pet")
    pcall(MinimapButton)
    if C_DamageMeter then WatchFeed() end
  elseif e == "UNIT_PET" then
    pet = UnitGUID("pet")
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
local OnOff = { { "On", true }, { "Off", false } }
ns.HelpConfig = {
  title = "Crit Tracker",
  tag = "Crit Tracker",
  settings = {
    { label = "Crit Tracker", choices = { { "On", "on" }, { "Off", "off" } },
      get = function() return DB.off and "off" or "on" end,
      set = function(v) DB.off = (v == "off") or nil end },
    { label = "Chat Message", choices = { { "New Crits", "crit" }, { "Crits & Hits", "all" }, { "Off", "off" } },
      get = function() return DB.announce or "crit" end, set = function(v) DB.announce = v end },
    { label = "Track Pet", choices = OnOff,
      get = function() return DB.pet and true or false end, set = function(v) DB.pet = v end },
    { label = "Track Heals", choices = OnOff,
      get = function() return DB.heals and true or false end, set = function(v) DB.heals = v end },
    { label = "Records Window", choices = { { "Open It", "open" } },
      get = function() return nil end, set = function() Toggle() end },
  },
  notes = {
    { v = "1.3.9", "Records work again for hunters and anyone whose pet or a single ability is hidden by the game: one hidden line used to stop every record. Now only that line waits, and everything else is counted" },
    { v = "1.3.8", "Best Hit and Best Crit stop picking up several hits added together (like Melee 1,746 at level 26). A mob leaving the meter no longer counts as one giant hit, a new fight's first look only learns, and a big jump only counts as a crit when the game says it crit. Damage records start over once more" },
    { v = "1.3.7", "Fixed false crits (like Melee 145 over and over): the damage meter lists an ability once per mob it hit, and those lines were read as hits. They're added up first now. Your pet's share of a shared line is split off too. Damage records start over once more to clear the false ones" },
    { v = "1.3.6", "Best Hit no longer shows several hits added together. In dungeons the damage meter can add up a few hits at once: Crit Tracker now learns each ability's usual hit before writing records, and skips anything far above a crit. Damage records start over once so the wrong ones are gone" },
    { v = "1.3.5", "Best Crit fills in again. Forever often hides whether a hit was a crit, so Crit Tracker now also spots crits by size: a hit well above that ability's usual hit is a crit. Damage rows that never got a crit start their Best Hit over, since their crits had landed there" },
    { v = "1.3.4", "Real numbers are back: Crit Tracker now reads your hits from the game's own damage meter, so Best Crit and Best Hit show the actual size of each hit again. The rows from 1.3.3 that only had a count are cleared" },
    { v = "1.3.3", "Your hits and crits count again, even though Forever hides how big they are from addons: an ability with no known size shows how often it crits and how many times you used it" },
    { v = "1.3.2", "Records come in again: the game hides the damage amount from addons, so Crit Tracker now reads your hits and crits from the combat log lines in chat, like Crit Numbers does" },
    { v = "1.3.1", "Records keep coming in: since 1.2.1 a hit with any detail hidden by the game was skipped whole, even when its damage could be read" },
    { v = "1.3.0", "New: whisper your records to a friend. Type /crittracker whisper Name, and every time you beat one of your best crits they get a whisper with the new number. /crittracker whisper off stops it" },
    { v = "1.2.2", "More dungeon and raid fixes: a few more details the game hides there (like whether someone is away) are now skipped quietly instead of causing errors" },
    { v = "1.2.1", "Works in dungeons and raids without errors. WoW: Forever hides some details from addons there, and this addon now quietly skips them" },
    { v = "1.2.0", "New Best Heal column in green: your biggest heal with each healing spell. Best Crit and Best Hit are for damage" },
    { v = "1.1.5", "Column headers keep their colors: Best Crit gold, Best Hit white, like the numbers under them" },
    { v = "1.1.4", "Removed the Crit % column. The window shows each ability's best crit and best hit" },
    { v = "1.1.3", "Auto Shot is tracked as Auto Shot now (it was counted as Melee), and a lot of hits that were being missed are counted. In a group, plain auto attack hits aren't counted, since they could be anyone's" },
    { v = "1.1.2", "Fixed an auto attack crit landing right after a sting, curse or mark being counted as that spell" },
    { v = "1.1.1", "Cleaner hover: each record lists Target, Where and When on their own lines. The Crit % column no longer hides under the scroll bar" },
    { v = "1.1.0", "Works on WoW: Forever again. The game stopped letting addons read combat events, so hits now come from the game's feed of hits on your target, matched to what you just cast. Hits with nothing cast count as your auto attack" },
    { v = "1.0.0", "First release: your best hit and best crit with every attack, ability and heal, with when and where" },
  },
  report = function()
    local n = 0
    for _ in pairs(REC or {}) do n = n + 1 end
    return { "Records " .. n .. ", chat " .. tostring(DB.announce) .. ", pet " .. tostring(DB.pet) .. ", heals " .. tostring(DB.heals) ..
      (DB.off and ", turned off" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.CritTrackerMinimapButton then return end
  local b = CreateFrame("Button", "CritTrackerMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Misc_Head_Dragon_01")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 185)
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
    Tip:AddLine("Crit Tracker")
    Tip:AddLine("Left-click: your records", 1, 1, 1)
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
function CritTracker_OnCompartmentClick() Toggle() end

SLASH_CRITTRACKER1 = "/crittracker"
SLASH_CRITTRACKER2 = "/topcrits"
SlashCmdList.CRITTRACKER = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if cmd == "" or cmd == "show" or cmd == "records" then
    Toggle()
  elseif cmd == "whisper" then
    -- (1.3.0) whisper new records to a friend: /crittracker whisper Name (or "off")
    local who = (msg or ""):match("^%S+%s+(.-)%s*$")
    if not who or who == "" then
      Say(DB.whisper and string.format(Tr("whispering new records to %s. /crittracker whisper off to stop"), DB.whisper) or Tr("type /crittracker whisper Name to whisper your new records to a friend"))
    elseif who:lower() == "off" then
      DB.whisper = nil; Say(Tr("stopped whispering new records"))
    else
      DB.whisper = who; Say(string.format(Tr("new records will be whispered to %s"), who))
    end
  elseif cmd == "off" then
    DB.off = not DB.off or nil; Say(DB.off and "turned off" or "turned on")
  elseif cmd == "dm" then
    -- (1.3.3) what the game's own damage meter hands addons: a short look, for fixing records on Forever
    local DM = C_DamageMeter
    if not DM then print("Crit Tracker: no damage meter in this game") return end
    local lines = 0
    local function out(t) lines = lines + 1; if lines <= 60 then print(t) end end
    local function show(v)
      if issecretvalue(v) then return "SECRET" end
      if type(v) == "string" then return '"' .. v:sub(1, 30) .. '"' end
      return tostring(v)
    end
    local function dump(v, pad, depth)
      if issecretvalue(v) then out(pad .. "SECRET table") return end
      if type(v) ~= "table" then out(pad .. show(v)) return end
      local n = 0
      for k, x in pairs(v) do
        n = n + 1
        if n > 8 then out(pad .. "...") break end
        if type(x) == "table" and not issecretvalue(x) and depth < 4 then out(pad .. tostring(k) .. " = {"); dump(x, pad .. "  ", depth + 1)
        else out(pad .. tostring(k) .. " = " .. show(x)) end
      end
    end
    out("|cffffd100Crit Tracker: damage meter|r available " .. show(DM.IsDamageMeterAvailable and select(2, pcall(DM.IsDamageMeterAvailable))))
    for _, e in ipairs({ "DamageMeterSessionType", "DamageMeterType" }) do
      local t = Enum and Enum[e]
      local parts = {}
      for k, v in pairs(t or {}) do parts[#parts + 1] = k .. "=" .. tostring(v) end
      out(e .. ": " .. table.concat(parts, " "))
    end
    local guid = UnitGUID("player")
    local st = Enum and Enum.DamageMeterSessionType
    local mt = Enum and Enum.DamageMeterType
    local sess = st and (st.Current or st.Overall) or 1
    local dmg = mt and (mt.DamageDone or 0) or 0
    local ok, src = pcall(DM.GetCombatSessionSourceFromType, sess, dmg, guid)
    out("your damage (session " .. tostring(sess) .. ", type " .. tostring(dmg) .. "): " .. (ok and "" or ("error " .. tostring(src))))
    if ok then dump(src, "  ", 1) end
    if lines > 60 then print("(" .. (lines - 60) .. " more lines cut)") end
  elseif cmd == "debug" then
    local sample = feedSeen.sample   -- before this readout's own lines replace it
    print("|cffffd100Crit Tracker debug|r")
    print("  damage meter: readings " .. meter.ok .. ", hidden " .. meter.hidden .. ", catch-ups " .. (meter.caught or 0) .. ", running " .. tostring(meter.started or false))
    print("  meter steps skipped as several hits at once: " .. (meter.batch or 0) .. ", after a hidden look: " .. (meter.gapSkip or 0))
    for _, l in ipairs(meter.log or {}) do print("    step: " .. l) end
    print("  crit flags: readable " .. (meter.flagOK or 0) .. ", hidden " .. (meter.flagHidden or 0) .. ", crits flagged " .. (meter.flagCrit or 0) .. ", crits by size " .. (meter.bySize or 0))
    print("  combat log lines read " .. (feedSeen.chat or 0) .. (feedSeen.last and (", last " .. feedSeen.last) or ""))
    print("  last combat line seen: " .. tostring(sample))
    print("  target feed: events " .. feedSeen.events .. ", hits counted " .. feedSeen.hits .. ", crits " .. feedSeen.crits .. ", hidden " .. feedSeen.hidden .. ", skipped " .. (feedSeen.skipped or 0))
    print("  auto shot on " .. tostring(AutoRepeat(75)) .. ", melee on " .. tostring(Meleeing()) .. ", in group " .. tostring(IsInGroup and IsInGroup() or false))
    print("  last cast: " .. tostring(cast.name) .. " (counts as damage " .. tostring(cast.harm) .. ")")
    for _, l in ipairs(feedSeen.log) do print("    " .. l) end
  else
    if ns.OpenHelp then ns.OpenHelp() end
  end
end
