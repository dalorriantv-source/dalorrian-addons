-- Dalorrian's Accents: the chat hook, your stats, unlocks, ranks and awards.
local ADDON, ns = ...
local issecretvalue = issecretvalue or function() return false end
local P = function(...) return (ns.print or print)(...) end
local Tr = function(x) return (ns.Tr or function(y) return y end)(x) end
local function Say(msg) P("|cffff8fb0Accents:|r " .. Tr(msg)) end
ns.Say = Say

local DB, CDB
ns.VERSION = (C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(ADDON, "Version"))
  or (GetAddOnMetadata and GetAddOnMetadata(ADDON, "Version")) or "?"

---------------------------------------------------------------------------
-- Settings and saved data
---------------------------------------------------------------------------
-- where accents apply (Where tab): chat type -> one switch
ns.WHERE = {
  { key = "SAY", label = "Say", on = true },
  { key = "YELL", label = "Yell", on = true },
  { key = "PARTY", label = "Party", on = true },
  { key = "RAID", label = "Raid", on = true },
  { key = "INSTANCE", label = "Instance", on = true },
  { key = "GUILD", label = "Guild", on = true },
  { key = "OFFICER", label = "Officer", on = true },
  { key = "WHISPER", label = "Whispers", on = false },
  { key = "EMOTE", label = "Emotes", on = false },
  { key = "CHANNEL", label = "General & Trade", on = false },
}
local CHAT_TO_WHERE = {
  SAY = "SAY", YELL = "YELL", PARTY = "PARTY", PARTY_LEADER = "PARTY", RAID = "RAID", RAID_LEADER = "RAID",
  RAID_WARNING = "RAID", INSTANCE_CHAT = "INSTANCE", INSTANCE_CHAT_LEADER = "INSTANCE", GUILD = "GUILD",
  OFFICER = "OFFICER", WHISPER = "WHISPER", BN_WHISPER = "WHISPER", EMOTE = "EMOTE", CHANNEL = "CHANNEL",
}
ns.CHAT_TO_WHERE = CHAT_TO_WHERE
-- where awards are announced (like Questie): Say, Party (party or raid), Instance, Guild
ns.ANNOUNCE = {
  { key = "SAY", label = "Say", on = false },
  { key = "PARTY", label = "Party", on = true },
  { key = "INSTANCE", label = "Instance", on = true },
  { key = "GUILD", label = "Guild", on = false },
}

local function Defaults()
  AccentsDB = AccentsDB or {}
  DB = AccentsDB
  DB.total = DB.total or 0
  DB.per = DB.per or {}
  DB.used = DB.used or {}
  DB.chan = DB.chan or {}
  DB.stat = DB.stat or {}
  DB.awards = DB.awards or {}
  DB.secret = DB.secret or {}
  DB.early = DB.early or {}
  DB.ec = DB.ec or {}
  DB.rank = DB.rank or {}
  DB.where = DB.where or {}
  for _, w in ipairs(ns.WHERE) do if DB.where[w.key] == nil then DB.where[w.key] = w.on end end
  DB.announce = DB.announce or {}
  for _, a in ipairs(ns.ANNOUNCE) do if DB.announce[a.key] == nil then DB.announce[a.key] = a.on end end
  if DB.toasts == nil then DB.toasts = true end
  if DB.sound == nil then DB.sound = true end
  if DB.chatButton == nil then DB.chatButton = true end
  AccentsCharDB = AccentsCharDB or {}
  CDB = AccentsCharDB
  CDB.strength = 3   -- (1.0.0) always full strength
  if CDB.on == nil then CDB.on = false end
  ns.DB, ns.CDB = DB, CDB
end
ns.Defaults = Defaults

local function Today() return date("%Y-%m-%d") end
local function Stat(k, n) DB.stat[k] = (DB.stat[k] or 0) + (n or 1); return DB.stat[k] end
ns.Stat = Stat

---------------------------------------------------------------------------
-- Your race's accent, unlocks and ranks
---------------------------------------------------------------------------
local RACE_ACCENT = { Orc = "orc", Troll = "troll", Tauren = "tauren", Scourge = "forsaken", Undead = "forsaken",
  Human = "human", Dwarf = "dwarf", Gnome = "gnome", NightElf = "nightelf",
  Skyborne = "skyborne", SkyborneElf = "skyborne", ShenDorei = "skyborne", Shendorei = "skyborne" }
function ns.MyRaceAccent()
  local ok, _, file = pcall(UnitRace, "player")
  if ok and not issecretvalue(file) and file and RACE_ACCENT[file] then return RACE_ACCENT[file] end
  return "human"
end
function ns.MyFaction()
  local ok, f = pcall(UnitFactionGroup, "player")
  return ok and not issecretvalue(f) and f or nil
end

function ns.Current()
  local key = CDB and CDB.accent
  if not key or not ns.ACCENTS[key] or not ns.IsUnlocked(key) then key = ns.MyRaceAccent() end
  return key
end

-- the accents you start without, in the order they unlock
function ns.UnlockList()
  local list = {}
  for _, k in ipairs(ns.ORDER) do local d = ns.ACCENTS[k]; if not d.starter and not d.secret then list[#list + 1] = k end end
  return list
end
-- messages needed for the n-th unlock: 10, 28, 52, 80, 112 ... about 2,250 for the 37th
function ns.UnlockAt(n) return math.floor(10 * n ^ 1.5 + 0.5) end
function ns.IsUnlocked(key)
  local def = ns.ACCENTS[key]
  if not def then return false end
  if def.secret then return DB and DB.secret and DB.secret[key] or false end
  if def.starter or (DB and DB.unlockAll) then return true end
  if DB and DB.early and DB.early[key] then return true end
  for i, k in ipairs(ns.UnlockList()) do
    if k == key then return (DB and DB.total or 0) >= ns.UnlockAt(i), ns.UnlockAt(i) end
  end
  return false
end
function ns.UnlockedCount()
  local n = 0
  for _, k in ipairs(ns.ORDER) do if not ns.ACCENTS[k].secret and ns.IsUnlocked(k) then n = n + 1 end end
  return n
end
-- accents everyone can see (the secret one does not count toward totals)
function ns.PublicCount()
  local n = 0
  for _, k in ipairs(ns.ORDER) do if not ns.ACCENTS[k].secret then n = n + 1 end end
  return n
end
-- the accents to list: everything but a secret you have not found
function ns.ListOrder()
  -- everything shows; locked ones show as "???" (the secret one last)
  local list, last = {}, {}
  for _, k in ipairs(ns.ORDER) do if ns.ACCENTS[k].secret then last[#last + 1] = k else list[#list + 1] = k end end
  for _, k in ipairs(last) do list[#list + 1] = k end
  return list
end
-- the secret accent: say "it just works" with Accents on
function ns.CheckSecret(original)
  if type(original) ~= "string" or not ns.ACCENTS.godd then return end
  if DB.secret.godd or not original:lower():find("it just works", 1, true) then return end
  DB.secret.godd = true
  local d = ns.ACCENTS.godd
  if ns.GoddBadge then pcall(ns.GoddBadge) elseif ns.Toast then ns.Toast("Secret accent found!", d.name, d.blurb, d.icon) end
  if ns.Announce then ns.Announce(Tr("found a secret accent!")) end
end

ns.RANK_AT = { 10, 50, 100, 250, 500, 1000, 2500, 5000 }
ns.GENERIC_RANKS = { "Novice", "Speaker", "Talker", "Orator", "Voice", "Master", "Legend", "Living Legend" }
function ns.RankOf(key, count)
  count = count or (DB and DB.per[key]) or 0
  local r = 0
  for i, at in ipairs(ns.RANK_AT) do if count >= at then r = i end end
  return r
end
function ns.RankTitle(key, r)
  local def = ns.ACCENTS[key]
  if not def or not r or r < 1 then return nil end
  if def.ranks and def.ranks[r] then return def.ranks[r] end
  return def.name .. " " .. ns.GENERIC_RANKS[r]
end

---------------------------------------------------------------------------
-- Awards: 22 you can see and 40 hidden ones
---------------------------------------------------------------------------
local function Per(k) return (DB.per[k] or 0) end
local function UsedCount() local n = 0; for k in pairs(DB.used) do if ns.ACCENTS[k] then n = n + 1 end end; return n end
local function BestRank() local b = 0; for k in pairs(DB.per) do b = math.max(b, ns.RankOf(k)) end; return b end
local function Chan(k) return DB.chan[k] or 0 end
ns.AWARDS = {
  { id = "first", name = "First Words", desc = "Send your first message in an accent.", icon = "Spell_Holy_Silence", check = function() return DB.total >= 1 end },
  { id = "m100", name = "Chatterbox", desc = "Send 100 messages in accents.", icon = "INV_Misc_Note_01", check = function() return DB.total >= 100 end },
  { id = "m500", name = "Silver Tongue", desc = "Send 500 messages in accents.", icon = "INV_Misc_Coin_04", check = function() return DB.total >= 500 end },
  { id = "m1000", name = "Golden Tongue", desc = "Send 1,000 messages in accents.", icon = "INV_Misc_Coin_02", check = function() return DB.total >= 1000 end },
  { id = "m5000", name = "Voice of Azeroth", desc = "Send 5,000 messages in accents.", icon = "INV_Misc_Horn_01", check = function() return DB.total >= 5000 end },
  { id = "poly3", name = "Polyglot", desc = "Talk in 3 different accents.", icon = "INV_Misc_Book_09", check = function() return UsedCount() >= 3 end },
  { id = "poly10", name = "Many Mouths", desc = "Talk in 10 different accents.", icon = "INV_Misc_Book_11", check = function() return UsedCount() >= 10 end },
  { id = "poly25", name = "Master of Tongues", desc = "Talk in 25 different accents.", icon = "INV_Misc_Book_07", check = function() return UsedCount() >= 25 end },
  { id = "polyall", name = "Speaks Everything", desc = "Talk in every accent there is.", icon = "INV_Misc_Book_06", check = function() return UsedCount() >= math.max(ns.PublicCount(), 40) end },
  { id = "unlock10", name = "Collector", desc = "Unlock 10 accents.", icon = "INV_Misc_Bag_10", check = function() return ns.UnlockedCount() >= 10 end },
  { id = "unlockall", name = "Completionist", desc = "Unlock every accent.", icon = "INV_Misc_Bag_08", check = function() return ns.UnlockedCount() >= math.max(ns.PublicCount(), 40) end },
  { id = "party", name = "Party Animal", desc = "Send 100 accented messages in party, raid or instance chat.", icon = "Spell_Holy_PrayerOfHealing", check = function() return Chan("PARTY") + Chan("RAID") + Chan("INSTANCE") >= 100 end },
  { id = "guild", name = "Guild Voice", desc = "Send 100 accented messages in guild chat.", icon = "INV_Shirt_GuildTabard_01", check = function() return Chan("GUILD") + Chan("OFFICER") >= 100 end },
  { id = "say", name = "Town Crier", desc = "Send 50 accented messages in /say.", icon = "INV_Misc_Bell_01", check = function() return Chan("SAY") >= 50 end },
  { id = "yell", name = "Loudmouth", desc = "Send 25 accented yells.", icon = "Ability_Warrior_BattleShout", check = function() return Chan("YELL") >= 25 end },
  { id = "streak3", name = "Daily Habit", desc = "Talk in an accent 3 days in a row.", icon = "INV_Misc_PocketWatch_01", check = function() return (DB.streakBest or 0) >= 3 end },
  { id = "streak7", name = "Week of Words", desc = "Talk in an accent 7 days in a row.", icon = "INV_Misc_PocketWatch_02", check = function() return (DB.streakBest or 0) >= 7 end },
  { id = "streak30", name = "Born This Way", desc = "Talk in an accent 30 days in a row.", icon = "INV_Misc_PocketWatch_03", check = function() return (DB.streakBest or 0) >= 30 end },
  { id = "rank3", name = "Moving Up", desc = "Reach rank 3 (100 messages) in any accent.", icon = "INV_Misc_Ribbon_01", check = function() return BestRank() >= 3 end },
  { id = "rank6", name = "Mastered", desc = "Reach rank 6 (1,000 messages) in any accent.", icon = "INV_Crown_01", check = function() return BestRank() >= 6 end },
  { id = "heavy", name = "Laying It On Thick", desc = "Send 100 accented messages.", icon = "INV_Hammer_15", check = function() return (DB.stat.heavy or 0) >= 100 end },
  { id = "method", name = "Method Actor", desc = "Send 100 messages in a row in one accent, without switching or turning it off.", icon = "INV_Misc_Mask_01", check = function() return (DB.runBest or 0) >= 100 end },
  -- hidden
  { id = "murloc", hidden = true, name = "Mrglglgl", clue = "Something from the shallows wants to talk.", desc = "Send 100 messages as a Murloc.", icon = "INV_Misc_Fish_14", check = function() return Per("murloc") >= 100 end },
  { id = "kobold", hidden = true, name = "Candle Keeper", clue = "Some say it's all about the candle.", desc = "Send 50 messages as a Kobold.", icon = "INV_Misc_Candle_01", check = function() return Per("kobold") >= 50 end },
  { id = "night", hidden = true, name = "Night Owl", clue = "Talk when good folk are asleep.", desc = "Send an accented message between 2 and 5 in the morning.", icon = "Spell_Nature_Sleep", check = function() return (DB.stat.night or 0) >= 1 end },
  { id = "crisis", hidden = true, name = "Identity Crisis", clue = "Who are you, really?", desc = "Switch accents 10 times in 10 minutes.", icon = "Spell_Shadow_Charm", check = function() return (DB.stat.crisis or 0) >= 1 end },
  { id = "wrong", hidden = true, name = "Wrong Crowd", clue = "Talk like the other side.", desc = "Send 50 messages in a race accent of the other faction.", icon = "INV_BannerPVP_01", check = function() return (DB.stat.wrong or 0) >= 50 end },
  { id = "roots", hidden = true, name = "True to Your Roots", clue = "Stay loyal to where you come from.", desc = "Send 500 messages in your own race's accent.", icon = "INV_Misc_Root_01", check = function() return (DB.stat.roots or 0) >= 500 end },
  { id = "essay", hidden = true, name = "Essay", clue = "Some thoughts don't fit in one message.", desc = "Send an accented message so long it splits in two.", icon = "INV_Scroll_03", check = function() return (DB.stat.split or 0) >= 1 end },
  { id = "laconic", hidden = true, name = "Few Words", clue = "Say less.", desc = "Send 25 accented messages of one word.", icon = "INV_Misc_Note_04", check = function() return (DB.stat.oneword or 0) >= 25 end },
  { id = "shouty", hidden = true, name = "INDOOR VOICE", clue = "WHY IS EVERYONE YELLING", desc = "Send 50 accented messages typed in all caps.", icon = "Spell_Holy_Silence", check = function() return (DB.stat.caps or 0) >= 50 end },
  { id = "ooc", hidden = true, name = "Out of Character", clue = "(( Sometimes you just need to be you. ))", desc = "Send 25 messages that start with (( while an accent is on.", icon = "INV_Misc_Mask_02", check = function() return (DB.stat.ooc or 0) >= 25 end },
  { id = "bypass", hidden = true, name = "Off the Record", clue = "A quick shift in tone.", desc = "Send 10 plain messages with Shift+Enter while an accent is on.", icon = "INV_Letter_08", check = function() return (DB.stat.bypass or 0) >= 10 end },
  { id = "fans", hidden = true, name = "Fan Club", clue = "People will ask. Tell them.", desc = "Tell 5 people about Accents when they ask.", icon = "INV_Misc_Toy_01", check = function() return (DB.stat.shares or 0) >= 5 end },
  { id = "kindred", hidden = true, name = "Kindred Voices", clue = "Find another who talks funny.", desc = "Talk in an accent in a group with another Accents user.", icon = "Spell_Holy_PrayerOfSpirit", check = function() return (DB.stat.kindred or 0) >= 1 end },
  { id = "speechless", hidden = true, name = "Make Up Your Mind", clue = "On. Off. On. Off.", desc = "Turn Accents on and off 20 times in one day.", icon = "INV_Gizmo_01", check = function() return (DB.stat.flip or 0) >= 1 end },
  { id = "early_pirate", hidden = true, name = "Sea Legs", clue = "Some ports have a way with words.", desc = "Unlock Pirate early: talk in Booty Bay or Ratchet.", icon = "INV_Misc_Bandana_03", check = function() return DB.early and DB.early.pirate end },
  { id = "early_goblin", hidden = true, name = "Time Is Money", clue = "Talk about money. A lot.", desc = "Unlock Goblin early: say \"gold\" 10 times.", icon = "INV_Misc_Coin_02", check = function() return DB.early and DB.early.goblin end },
  { id = "early_murloc", hidden = true, name = "Mrglglgl", clue = "Some words are older than words.", desc = "Unlock Murloc early: say \"mrgl\".", icon = "INV_Misc_Fish_14", check = function() return DB.early and DB.early.murloc end },
  { id = "early_kobold", hidden = true, name = "Candle Keeper", clue = "Somebody wants their candle back.", desc = "Unlock Kobold early: say \"you no take candle\".", icon = "INV_Misc_Candle_01", check = function() return DB.early and DB.early.kobold end },
  { id = "early_ogre", hidden = true, name = "Two Heads", clue = "Talk where the big ones live.", desc = "Unlock Ogre early: talk in an ogre zone.", icon = "Spell_Nature_Strength", check = function() return DB.early and DB.early.ogre end },
  { id = "early_raidboss", hidden = true, name = "Final Words", clue = "Speak over a fallen boss.", desc = "Unlock Raid Boss early: kill a dungeon boss with Accents on.", icon = "Spell_Shadow_DeathScream", check = function() return DB.early and DB.early.raidboss end },
  { id = "early_bard", hidden = true, name = "Touring Company", clue = "Every city needs a show.", desc = "Unlock Bard early: talk in 3 capital cities.", icon = "INV_Misc_Book_09", check = function() return DB.early and DB.early.bard end },
  { id = "early_noir", hidden = true, name = "After Hours", clue = "The city talks different after midnight.", desc = "Unlock Noir Detective early: talk after midnight.", icon = "Ability_Stealth", check = function() return DB.early and DB.early.noir end },
  { id = "early_sergeant", hidden = true, name = "Outside Voice", clue = "SOME PEOPLE ONLY KNOW ONE VOLUME.", desc = "Unlock Drill Sergeant early: send 5 messages in all caps.", icon = "Ability_Warrior_BattleShout", check = function() return DB.early and DB.early.sergeant end },
  { id = "early_epic", hidden = true, name = "An Epic", clue = "Some tales run long.", desc = "Unlock High Epic early: send a message over 150 characters.", icon = "INV_Misc_Book_07", check = function() return DB.early and DB.early.epic end },
  { id = "early_grimdark", hidden = true, name = "Everyone Dies", clue = "Everyone dies. You, three times.", desc = "Unlock Grimdark early: die 3 times with Accents on.", icon = "INV_Sword_04", check = function() return DB.early and DB.early.grimdark end },
  { id = "early_wry", hidden = true, name = "Probably", clue = "Probably. Almost certainly probably.", desc = "Unlock Wry Narrator early: say \"probably\" 5 times.", icon = "INV_Misc_Book_11", check = function() return DB.early and DB.early.wry end },
  { id = "early_wizard", hidden = true, name = "Abracadabra", clue = "Every wizard knows the word.", desc = "Unlock Wizard early: say \"abracadabra\".", icon = "INV_Staff_13", check = function() return DB.early and DB.early.wizard end },
  { id = "early_prospector", hidden = true, name = "Strike It Rich", clue = "Talk where the gold comes from.", desc = "Unlock Old Prospector early: talk inside a mine.", icon = "INV_Pick_02", check = function() return DB.early and DB.early.prospector end },
  { id = "early_caveman", hidden = true, name = "Ugg", clue = "Fewer words. More meaning.", desc = "Unlock Caveman early: send 10 messages of two words or less.", icon = "INV_Misc_Bone_01", check = function() return DB.early and DB.early.caveman end },
  { id = "early_robot", hidden = true, name = "Beep Boop", clue = "Speak the language of machines.", desc = "Unlock Robot early: say \"beep boop\".", icon = "INV_Gizmo_02", check = function() return DB.early and DB.early.robot end },
  { id = "early_peasant", hidden = true, name = "Dirt Poor", clue = "Talk while your purse is light.", desc = "Unlock Medieval Peasant early: talk with less than 1 gold at level 20 or higher.", icon = "INV_Misc_Food_11", check = function() return DB.early and DB.early.peasant end },
  { id = "early_cowboy", hidden = true, name = "Howdy", clue = "Greet folks the old way.", desc = "Unlock Cowboy early: say \"howdy\".", icon = "INV_Misc_Horn_01", check = function() return DB.early and DB.early.cowboy end },
  { id = "early_surfer", hidden = true, name = "Hang Ten", clue = "Talk while the water's nice.", desc = "Unlock Surfer early: talk while swimming.", icon = "INV_Misc_Fish_09", check = function() return DB.early and DB.early.surfer end },
  { id = "early_butler", hidden = true, name = "Impeccable Manners", clue = "Mind your pleases and thank yous.", desc = "Unlock Butler early: say please or thank you 10 times.", icon = "INV_Misc_Bell_01", check = function() return DB.early and DB.early.butler end },
  { id = "early_grumpy", hidden = true, name = "Back In My Day", clue = "Tell them how it used to be.", desc = "Unlock Grumpy Old Man early: say \"back in my day\".", icon = "INV_Misc_Spectacles_01", check = function() return DB.early and DB.early.grumpy end },
  { id = "early_valley", hidden = true, name = "Like, Totally", clue = "Like, use a certain word. Like, a lot.", desc = "Unlock Valley Girl early: say \"like\" 20 times.", icon = "INV_Misc_Gem_Pearl_04", check = function() return DB.early and DB.early.valley end },
  { id = "early_conspiracy", hidden = true, name = "Wake Up", clue = "Tell people to open their eyes.", desc = "Unlock Conspiracy Guy early: say \"wake up\".", icon = "INV_Misc_Eye_01", check = function() return DB.early and DB.early.conspiracy end },
  { id = "early_announcer", hidden = true, name = "And The Crowd Goes Wild", clue = "Get excited!! Really excited!!", desc = "Unlock Sports Announcer early: send 5 messages with \"!!\".", icon = "INV_Misc_Horn_02", check = function() return DB.early and DB.early.announcer end },
  { id = "justworks", hidden = true, name = "It Just Works", clue = "No hints. Good luck.", desc = "Find the secret accent.", icon = "Trade_Engineering", check = function() return DB.secret and DB.secret.godd end },
  { id = "whisper", hidden = true, name = "Sweet Nothings", clue = "Some things are just between two.", desc = "Send 50 accented whispers.", icon = "INV_ValentinesCard01", check = function() return Chan("WHISPER") >= 50 end },
}

---------------------------------------------------------------------------
-- Announcing (like Questie: a star, the addon's name, then the news)
---------------------------------------------------------------------------
-- during a boss fight the game blocks addons from posting to chat: award news waits and goes out after (up to 10 minutes)
local function Locked()
  local f = C_ChatInfo and C_ChatInfo.InChatMessagingLockdown
  if not f then return false end
  local ok, v = pcall(f)
  return ok and v == true
end
local function Send(msg, chatType, lang, target, tries)
  local f = (C_ChatInfo and C_ChatInfo.SendChatMessage) or SendChatMessage
  if not f then return end
  if Locked() then
    tries = (tries or 0) + 1
    if tries <= 300 and C_Timer then C_Timer.After(2, function() Send(msg, chatType, lang, target, tries) end) end
    return
  end
  pcall(f, msg, chatType, lang, target)
end
ns.Send = Send

local function Marker()
  local loc = GetLocale and GetLocale()
  if loc == "ruRU" then return "{звезда} Accents: " end
  if loc == "frFR" then return "{rt1} Accents : " end
  return "{rt1} Accents: "
end
ns.Marker = Marker

local pending = {}
local function Announce(msg)
  pending[#pending + 1] = msg
end
ns.Announce = Announce

-- (1.3.0) one short line, at most once a minute to your group: "{star} Accents: unlocked Pirate, earned Night Owl".
-- The details are on your own screen (the toast); a busy minute only shows in your own chat
local lastPublic = -100
local function FlushAnnounce()
  if #pending == 0 then return end
  local lines = pending
  pending = {}
  local shown = {}
  for i = 1, math.min(2, #lines) do shown[i] = (lines[i]:gsub("[!%.]+$", "")) end
  local text = table.concat(shown, ", ")
  if #lines > 2 then text = text .. " " .. string.format(Tr("and %d more"), #lines - 2) end
  Say(text)
  if GetTime() - lastPublic < 60 then return end
  lastPublic = GetTime()
  text = Marker() .. text
  if #text > 250 then text = Marker() .. lines[1] end
  local a = DB.announce
  if a.SAY then Send(text, "SAY") end   -- now, while the key press lasts (Say needs one)
  C_Timer.After(0.4, function()
    if a.PARTY and IsInGroup() and not IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then Send(text, IsInRaid() and "RAID" or "PARTY") end
    if a.INSTANCE and IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then Send(text, "INSTANCE_CHAT") end
    if a.GUILD and IsInGuild and IsInGuild() then Send(text, "GUILD") end
  end)
end
ns.FlushAnnounce = FlushAnnounce

-- for players with Accents: our star turns into the Accents icon
local ICON = "Interface\\Icons\\Spell_Shadow_SoothingKiss"
ns.ICON = ICON
local function LogoFilter(_, _, msg, ...)
  if type(msg) ~= "string" or issecretvalue(msg) then return false end
  local new, n = msg:gsub("^{rt1} Accents ?:", "|T" .. ICON .. ":0|t Accents:")
  if n == 0 then new, n = msg:gsub("^{звезда} Accents ?:", "|T" .. ICON .. ":0|t Accents:") end
  if n > 0 then return false, new, ... end
  return false
end
local addFilter = (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter) or ChatFrame_AddMessageEventFilter
if addFilter then
  for _, e in ipairs({ "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
    "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_GUILD", "CHAT_MSG_SAY" }) do
    pcall(addFilter, e, LogoFilter)
  end
end

---------------------------------------------------------------------------
-- After each accented message: stats, ranks, unlocks, awards
---------------------------------------------------------------------------
local function Streak()
  local today = Today()
  if DB.lastDay == today then return end
  local y = date("%Y-%m-%d", time() - 86400)
  DB.streak = (DB.lastDay == y) and (DB.streak or 0) + 1 or 1
  DB.lastDay = today
  DB.streakBest = math.max(DB.streakBest or 0, DB.streak)
end

function ns.CheckAwards(quiet)
  local new = {}
  for _, a in ipairs(ns.AWARDS) do
    if not DB.awards[a.id] then
      local ok, got = pcall(a.check)
      if ok and got then
        DB.awards[a.id] = time()
        new[#new + 1] = a
      end
    end
  end
  if quiet then return end
  for _, a in ipairs(new) do
    if ns.Toast then ns.Toast("Award earned!", a.name, a.desc, "Interface\\Icons\\" .. a.icon) end
    -- (1.3.0) short, and the hidden award a secret unlock gives isn't said twice (the unlock already is)
    if not a.id:find("^early_") then Announce(string.format(Tr("earned %s"), Tr(a.name))) end
  end
end

local kindred = {}   -- other Accents users seen in your group: name -> time
ns.kindred = kindred

function ns.Counted(key, where, original, strength)
  local def = ns.ACCENTS[key]
  local before = ns.UnlockedCount()
  DB.total = DB.total + 1
  DB.per[key] = Per(key) + 1
  DB.used[key] = true
  DB.chan[where] = Chan(where) + 1
  if strength == 3 then Stat("heavy") end
  local letters = original:gsub("[^%a]", "")
  if #letters >= 4 and letters:upper() == letters then Stat("caps") end
  if not original:find("%S%s+%S") then Stat("oneword") end
  local h = tonumber(date("%H"))
  if h and h >= 2 and h < 5 then Stat("night") end
  if DB.runKey == key then DB.run = (DB.run or 0) + 1 else DB.runKey, DB.run = key, 1 end
  DB.runBest = math.max(DB.runBest or 0, DB.run)
  local fac = ns.MyFaction()
  if def and def.faction and fac and def.faction ~= fac then Stat("wrong") end
  if key == ns.MyRaceAccent() then Stat("roots") end
  if where == "PARTY" or where == "RAID" or where == "INSTANCE" then
    for _, t in pairs(kindred) do if GetTime() - t < 600 then Stat("kindred"); break end end
    if ns.Hello then ns.Hello(true) end
  end
  Streak()
  -- a new rank in this accent
  local r = ns.RankOf(key)
  if r > (DB.rank[key] or 0) then
    DB.rank[key] = r
    local title = ns.RankTitle(key, r)
    if ns.Toast then ns.Toast("New rank!", title, string.format(Tr("%d messages as %s"), ns.RANK_AT[r], Tr(def.name)), def.icon) end
    Announce(string.format(Tr("%s rank: %s"), Tr(def.name), Tr(title)))
  end
  -- a new accent unlocked
  local after = ns.UnlockedCount()
  if after > before then
    for i, k in ipairs(ns.UnlockList()) do
      if ns.UnlockAt(i) == DB.total and not DB.early[k] then
        local d = ns.ACCENTS[k]
        if ns.Toast then ns.Toast("Accent unlocked!", d.name, d.blurb or "", d.icon) end
        Announce(string.format(Tr("unlocked %s"), Tr(d.name)))
      end
    end
  end
  ns.CheckSecret(original)
  if ns.CheckEarly then pcall(ns.CheckEarly, key, where, original) end
  ns.CheckAwards()
  if ns.RefreshUI then ns.RefreshUI() end
end

-- turning it on and off, and switching accents (two hidden awards)
function ns.SetOn(on)
  if on == CDB.on then return end
  CDB.on = on and true or false
  if not on then DB.run = 0 end
  local today = Today()
  if DB.flipDay ~= today then DB.flipDay, DB.flipN = today, 0 end
  DB.flipN = (DB.flipN or 0) + 1
  if DB.flipN >= 20 then DB.stat.flip = 1 end
  ns.CheckAwards()
  FlushAnnounce()
  if ns.RefreshUI then ns.RefreshUI() end
end
function ns.SetAccent(key)
  if not ns.ACCENTS[key] then return false end
  local ok, at = ns.IsUnlocked(key)
  if not ok and ns.ACCENTS[key].secret then Say(Tr("Unknown accent. /accents to see them all.")); return false end
  if not ok then Say(string.format(Tr("That one is still locked: it opens at %d messages (you have %d), or find its secret way in."), at or 0, DB.total)); return false end
  if CDB.accent ~= key then
    CDB.accent = key
    DB.run = 0
    DB.switches = DB.switches or {}
    table.insert(DB.switches, time())
    while #DB.switches > 10 do table.remove(DB.switches, 1) end
    if #DB.switches >= 10 and DB.switches[#DB.switches] - DB.switches[1] <= 600 then DB.stat.crisis = 1 end
    ns.CheckAwards()
    FlushAnnounce()
  end
  if ns.RefreshUI then ns.RefreshUI() end
  return true
end
function ns.SetStrength(n)
  CDB.strength = 3   -- (1.0.0) accents are always at full strength
  if ns.RefreshUI then ns.RefreshUI() end
end

---------------------------------------------------------------------------
-- The chat hook: your message changes the moment you press Enter
---------------------------------------------------------------------------
local function GroupNames()
  local names = {}
  local function add(unit)
    local ok, n = pcall(UnitName, unit)
    if ok and type(n) == "string" and not issecretvalue(n) then names[#names + 1] = n end
  end
  add("player"); add("target")
  if IsInRaid() then for i = 1, 40 do add("raid" .. i) end
  else for i = 1, 4 do add("party" .. i) end end
  return names
end
ns.GroupNames = GroupNames

-- mostly letters other than English (Russian, Korean, Chinese...): left alone
local function English(text)
  local high = select(2, text:gsub("[\128-\255]", ""))
  local low = select(2, text:gsub("%a", ""))
  return low > 0 and high < low
end

local function Turn(key, text, strength)
  local keep = DB and DB.keepSwears
  local out = ns.Engine.Apply(key, text, strength, { names = GroupNames(), keepSwears = keep })
  if #out > 255 then out = ns.Engine.Apply(key, text, strength, { names = GroupNames(), noFlavor = true, keepSwears = keep }) end
  return out
end
ns.Turn = Turn

local function Handle(editBox)
  local text = editBox:GetText()
  if type(text) ~= "string" or issecretvalue(text) or text == "" or text:sub(1, 1) == "/" then return end
  if not (CDB and CDB.on) then return end
  local ct = editBox:GetAttribute("chatType")
  local where = ct and CHAT_TO_WHERE[ct]
  if not where or not DB.where[where] then return end
  local key = ns.Current()
  if text:find("^%s*%(%(") then Stat("ooc"); ns.CheckAwards(); FlushAnnounce(); return end
  if IsShiftKeyDown() then Stat("bypass"); ns.CheckAwards(); FlushAnnounce(); return end
  if not English(text) then return end
  local strength = 3
  local out = Turn(key, text, strength)
  if type(out) ~= "string" or out == "" then return end
  if #out > 255 then
    -- (1.2.0) cut into as many messages as it takes (Murloc can more than double a line), at most 3
    local parts, rest = {}, out
    while #rest > 255 and #parts < 2 do
      local cut = ns.Engine.SplitPoint(rest, 255)
      if not cut then break end
      parts[#parts + 1] = rest:sub(1, cut - 1); rest = rest:sub(cut + 1)
    end
    if #rest > 255 then return end   -- can't be cut cleanly: it goes out as you typed it
    local lang = editBox.languageID
    local target = (ct == "WHISPER" or ct == "BN_WHISPER") and editBox:GetAttribute("tellTarget")
      or (ct == "CHANNEL" and editBox:GetAttribute("channelTarget")) or nil
    for _, p in ipairs(parts) do Send(p, ct, lang, target) end   -- these now, the last part the game sends right after
    out = rest
    Stat("split")
  end
  if out ~= text then editBox:SetText(out) end
  ns.Counted(key, where, text, strength)
  ns.lastAccented = { t = GetTime(), where = where }
  FlushAnnounce()
end

-- what the hooks saw (for /accents debug)
ns.dbg = { calls = 0, sends = 0, lastSend = "none", paths = {} }
local function OnParse(editBox, send, ...)
  local d = ns.dbg
  d.calls = d.calls + 1
  if send ~= nil and send ~= 0 and send ~= false then d.lastSend = type(send) .. ":" .. tostring(send) end
  if not (send == 1 or send == true) then return end
  d.sends = d.sends + 1
  if type(editBox) ~= "table" or not editBox.GetText then return end
  -- the same line can reach us twice (old name and new name of the same code): change it once
  local text = editBox:GetText()
  if editBox.__accentsOut and text == editBox.__accentsOut then return end
  -- one send can call more than one of our hooks in the same moment: only the first one counts
  local now = GetTime and GetTime() or 0
  if editBox.__accentsAt == now then return end
  editBox.__accentsAt = now
  local ok, err = pcall(Handle, editBox)
  if not ok then ns.lastError = err end
  editBox.__accentsOut = editBox:GetText()
end

-- hook every way this client can read a chat line before sending it
local hookedBoxes = {}
local function HookBox(eb)
  if not eb or hookedBoxes[eb] then return end
  if type(eb.ParseText) == "function" then
    hooksecurefunc(eb, "ParseText", OnParse)
    hookedBoxes[eb] = true
    ns.dbg.paths.box = (ns.dbg.paths.box or 0) + 1
  end
end
function ns.Hook()
  if not ns.hooked then
    ns.hooked = true
    if type(ChatEdit_ParseText) == "function" then
      hooksecurefunc("ChatEdit_ParseText", OnParse)
      ns.dbg.paths.global = true
    end
    if type(ChatFrameEditBoxMixin) == "table" and type(ChatFrameEditBoxMixin.ParseText) == "function" then
      hooksecurefunc(ChatFrameEditBoxMixin, "ParseText", OnParse)
      ns.dbg.paths.mixin = true
    end
    if type(ChatFrameUtil) == "table" and type(ChatFrameUtil.ParseText) == "function" then
      hooksecurefunc(ChatFrameUtil, "ParseText", OnParse)
      ns.dbg.paths.util = true
    end
  end
  for i = 1, (NUM_CHAT_WINDOWS or 10) do HookBox(_G["ChatFrame" .. i .. "EditBox"]) end
  if ChatEdit_GetActiveWindow then HookBox(ChatEdit_GetActiveWindow()) end
end
function ns.HookNames()
  local t = {}
  for k, v in pairs(ns.dbg.paths) do t[#t + 1] = k .. (type(v) == "number" and ("x" .. v) or "") end
  table.sort(t)
  return #t > 0 and table.concat(t, "+") or "none"
end

-- the chat box you are typing in (for the one-shot commands like /orc)
function ns.ActiveEditBox()
  local eb = (ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()) or (ChatEdit_GetLastActiveWindow and ChatEdit_GetLastActiveWindow())
  if eb then return eb end
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local e = _G["ChatFrame" .. i .. "EditBox"]
    if e and e:IsShown() then return e end
  end
  return _G.ChatFrame1EditBox
end

-- /orc hello there: one line in that accent, to the channel your chat box is set to
function ns.OneShot(key, msg)
  msg = msg and msg:gsub("^%s+", "") or ""
  if not ns.ACCENTS[key] then return end
  if msg == "" then ns.SetAccent(key); ns.SetOn(true); Say(string.format(Tr("talking as %s. /accents off to stop."), Tr(ns.ACCENTS[key].name))); return end
  local ok, at = ns.IsUnlocked(key)
  if not ok and ns.ACCENTS[key].secret then Say(Tr("Unknown accent. /accents to see them all.")); return end
  if not ok then Say(string.format(Tr("%s unlocks at %d accented messages (you have %d)."), Tr(ns.ACCENTS[key].name), at or 0, DB.total)); return end
  local eb = ns.ActiveEditBox()
  local ct = (eb and eb:GetAttribute("chatType")) or "SAY"
  if not CHAT_TO_WHERE[ct] then ct = "SAY" end
  local target = (ct == "WHISPER") and eb:GetAttribute("tellTarget") or (ct == "CHANNEL" and eb:GetAttribute("channelTarget")) or nil
  local strength = 3
  local out = Turn(key, msg, strength)
  -- (1.2.0) too long for one message: two messages, cut between words and never inside a link
  if #out > 255 then
    local cut = ns.Engine.SplitPoint(out, 255)
    if cut then Send(out:sub(1, cut - 1), ct, eb and eb.languageID, target); out = out:sub(cut + 1)
    else out = msg:sub(1, 255) end
  end
  Send(out, ct, eb and eb.languageID, target)
  ns.Counted(key, CHAT_TO_WHERE[ct], msg, strength)
  ns.lastAccented = { t = GetTime(), where = CHAT_TO_WHERE[ct] }
  FlushAnnounce()
end

---------------------------------------------------------------------------
-- Other Accents users in your group (for Kindred Voices) and "someone asked"
---------------------------------------------------------------------------
local PREFIX = "DACCENTS"
if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then pcall(C_ChatInfo.RegisterAddonMessagePrefix, PREFIX) end
local lastHello = 0
function ns.Hello(soft)
  if not IsInGroup() then return end
  if GetTime() - lastHello < (soft and 120 or 20) then return end
  lastHello = GetTime()
  local ch = IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and "INSTANCE_CHAT" or (IsInRaid() and "RAID" or "PARTY")
  if C_ChatInfo and C_ChatInfo.SendAddonMessage and not Locked() then pcall(C_ChatInfo.SendAddonMessage, PREFIX, "H~" .. (ns.VERSION or ""), ch) end
end

-- (1.0.1) only a question about how YOU talk counts. "which addon" alone fired on any addon talk in guild
local ASK = { "how are you talking", "how do you talk", "why are you talking", "why do you talk", "how are you typing",
  "why are you typing", "talk like that", "type like that", "talking like that", "typing like that", "how u talk",
  "how r u talking", "what's with the accent", "whats with the accent", "what is with the accent", "your accent",
  "ur accent", "accent addon", "accents addon" }
-- "what addon" counts only next to a word about talking
local ADDONQ = { "what addon", "which addon", "is that an addon", "what mod", "is that a mod" }
local TALKW = { "talk", "typing", "accent", "speak", "voice", "chat like" }
local function Asked(msg)
  local m = msg:lower()
  for _, p in ipairs(ASK) do if m:find(p, 1, true) then return true end end
  for _, p in ipairs(ADDONQ) do
    if m:find(p, 1, true) then
      for _, w in ipairs(TALKW) do if m:find(w, 1, true) then return true end end
    end
  end
  return false
end

local ev = CreateFrame("Frame")
ns.ev = ev
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:RegisterEvent("GROUP_ROSTER_UPDATE")
ev:RegisterEvent("CHAT_MSG_ADDON")
pcall(ev.RegisterEvent, ev, "PLAYER_DEAD")
pcall(ev.RegisterEvent, ev, "ENCOUNTER_END")
pcall(ev.RegisterEvent, ev, "BOSS_KILL")
for _, e in ipairs({ "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER", "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER",
  "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_GUILD", "CHAT_MSG_SAY", "CHAT_MSG_WHISPER" }) do
  pcall(ev.RegisterEvent, ev, e)
end
local ASK_WHERE = { CHAT_MSG_PARTY = "PARTY", CHAT_MSG_PARTY_LEADER = "PARTY", CHAT_MSG_RAID = "RAID", CHAT_MSG_RAID_LEADER = "RAID",
  CHAT_MSG_INSTANCE_CHAT = "INSTANCE", CHAT_MSG_INSTANCE_CHAT_LEADER = "INSTANCE", CHAT_MSG_GUILD = "GUILD",
  CHAT_MSG_SAY = "SAY", CHAT_MSG_WHISPER = "WHISPER" }
ev:SetScript("OnEvent", function(_, e, a1, a2, a3, a4, a5)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    Defaults()
    ns.CheckAwards(true)   -- awards you already qualify for are kept quietly
  elseif e == "PLAYER_LOGIN" then
    pcall(ns.Hook); if C_Timer then C_Timer.After(3, function() pcall(ns.Hook) end) end
    if ns.BuildUI then pcall(ns.BuildUI) end
    if ns.RegisterOneShots then pcall(ns.RegisterOneShots) end
    C_Timer.After(5, function() ns.Hello() end)
  elseif e == "PLAYER_DEAD" or e == "ENCOUNTER_END" or e == "BOSS_KILL" then
    if ns.EarlyEvent then pcall(ns.EarlyEvent, e, a1, a2, a3, a4, a5) end
  elseif e == "GROUP_ROSTER_UPDATE" then
    ns.Hello()
  elseif e == "CHAT_MSG_ADDON" then
    if issecretvalue(a1) or a1 ~= PREFIX or issecretvalue(a4) then return end
    local me = UnitName("player")
    local who = type(a4) == "string" and a4:match("^[^%-]+") or a4
    if who and who ~= me then kindred[who] = GetTime() end
  elseif ASK_WHERE[e] then
    if issecretvalue(a1) or issecretvalue(a2) or type(a1) ~= "string" then return end
    local last = ns.lastAccented
    if not last or GetTime() - last.t > 180 then return end
    -- (1.0.1) asked where you were talking (a whisper always counts)
    if e ~= "CHAT_MSG_WHISPER" and last.where and (last.where == "YELL" and "SAY" or last.where) ~= ASK_WHERE[e] then return end
    local me = UnitName("player")
    local who = type(a2) == "string" and a2:match("^[^%-]+") or a2
    if who == me or not Asked(a1) then return end
    if ns.ShowAsk then ns.ShowAsk(who, ASK_WHERE[e], a2) end
  end
end)

-- the answer when someone asks (one click: the player decides to send it)
function ns.TellThem(where, fullName)
  local msg = Marker() .. Tr("It's Dalorrian's Accents, on CurseForge. Type /orc or /dwarf to try it!")
  local ct = (where == "PARTY" and (IsInRaid() and "RAID" or "PARTY")) or (where == "INSTANCE" and "INSTANCE_CHAT") or where
  if where == "WHISPER" then Send(msg, "WHISPER", nil, fullName) else Send(msg, ct) end
  Stat("shares")
  ns.CheckAwards()
  FlushAnnounce()
end
