-- Dalorrian's Accents: how each race builds a sentence, not just which words it uses.
-- Each phrase is matched anywhere in a line and swapped whole ("i think" -> "I daresay").
local ADDON, ns = ...
local Bank = ns.Bank

local function H(key, phrases, extra)
  local t = {}
  for k, v in pairs(phrases) do
    if type(v) == "string" and v:find("|") then
      local list = {}
      for x in v:gmatch("[^|]+") do list[#list + 1] = x end
      t[k] = list
    else
      t[k] = v
    end
  end
  Bank(key, { phrases = t })
  local d = ns.ACCENTS[key]
  if d and extra then for k, v in pairs(extra) do d[k] = v end end
end

---------------------------------------------------------------------------
-- Human: a noble of Stormwind. Polite, formal, a little pompous.
---------------------------------------------------------------------------
H("human", {
  ["i think"] = "I daresay|I believe|I should think", ["i guess"] = "I suppose|I daresay", ["i feel like"] = "I rather feel",
  ["i don't know"] = "I could not say|I know not|I haven't the faintest idea", ["i dunno"] = "I could not say",
  ["do you"] = "would you|might you", ["can you"] = "would you kindly|might you", ["could you"] = "would you be so kind as to",
  ["can someone"] = "might someone|would someone kindly", ["can anyone"] = "might anyone|would anyone kindly",
  ["can somebody"] = "might somebody", ["want to"] = "wish to|care to", ["you want to"] = "you wish to|you care to",
  ["going to"] = "going to|about to", ["i'm going to"] = "I shall|I intend to", ["i am going to"] = "I shall|I intend to",
  ["i'll"] = "I shall", ["i will"] = "I shall", ["we'll"] = "we shall", ["we will"] = "we shall", ["let's"] = "let us",
  ["let's go"] = "onward!|let us be off|forward, friends", ["a lot"] = "a great deal|a good deal", ["lots of"] = "a great many",
  ["kind of"] = "rather|somewhat", ["sort of"] = "somewhat|rather", ["pretty good"] = "rather good|quite good",
  ["pretty bad"] = "rather dreadful|quite poor", ["really good"] = "most excellent|truly splendid", ["right now"] = "at present|this very moment",
  ["of course"] = "but of course|naturally", ["no way"] = "certainly not|I think not", ["oh my god"] = "good heavens|heavens above|by the Light",
  ["omg"] = "good heavens|by the Light", ["what the hell"] = "what the devil|what in the Light's name", ["wtf"] = "what the devil",
  ["shut up"] = "hold your tongue|do be quiet", ["you guys"] = "you good people|you fine folk", ["how's it going"] = "how fare you|how do you do",
  ["what's up"] = "what news|how fare you", ["by the way"] = "incidentally|I might add", ["for real"] = "truly|in earnest",
  ["i need"] = "I require|I am in need of", ["we need"] = "we require|we are in need of", ["i want"] = "I should like|I desire",
  ["that's"] = "that is", ["this is"] = "this is", ["it's"] = "it is", ["not bad"] = "not bad at all|quite acceptable",
  ["anyway"] = "in any case|at any rate", ["probably"] = "in all likelihood|most likely", ["maybe"] = "perhaps|mayhap",
  ["sounds good"] = "splendid|capital idea", ["my bad"] = "my apologies|forgive me", ["no worries"] = "think nothing of it",
  ["good luck"] = "good fortune to you|may the Light guide you", ["have fun"] = "enjoy yourselves|do enjoy",
  ["hurry up"] = "make haste|do hurry", ["come on"] = "come now|do come along", ["over there"] = "yonder|over there",
})

---------------------------------------------------------------------------
-- Night elf: ancient, patient, poetic. Ten thousand years of perspective.
---------------------------------------------------------------------------
H("nightelf", {
  ["i think"] = "I sense|I believe|I feel", ["i feel"] = "I sense|I feel", ["i don't know"] = "I cannot say|the stars have not shown me",
  ["a long time"] = "an age|many long years", ["long time"] = "an age", ["right now"] = "in this moment|now",
  ["let's go"] = "come, let us go|let us move", ["let's"] = "let us", ["oh my god"] = "by Elune|Elune's light",
  ["omg"] = "by Elune", ["what the hell"] = "by Elune|what darkness is this", ["wtf"] = "by Elune",
  ["good luck"] = "Ishnu-alah|good fortune to you", ["you guys"] = "you all|you young ones", ["i'm going to"] = "I shall|I will",
  ["i will"] = "I shall", ["i'll"] = "I shall", ["a lot"] = "much|a great deal", ["kind of"] = "somewhat", ["i'm tired"] = "I grow weary",
  ["how's it going"] = "how fares your path|how fare you", ["what's up"] = "how fares your path", ["hurry up"] = "swiftly now|make haste",
  ["calm down"] = "be at peace|patience", ["be careful"] = "tread softly|walk with care", ["have fun"] = "find joy in it",
  ["i need"] = "I require|I have need of", ["we need"] = "we have need of", ["so long"] = "an age", ["so old"] = "ancient",
  ["for real"] = "truly", ["no way"] = "it cannot be", ["come on"] = "come now", ["my bad"] = "forgive me",
})

---------------------------------------------------------------------------
-- Tauren: calm, warm, close to the land. Speaks slowly, rarely rushes.
---------------------------------------------------------------------------
H("tauren", {
  ["i think"] = "I feel|the winds tell me|I believe", ["i don't know"] = "I cannot say|only the Earth Mother knows",
  ["right now"] = "in this moment|now", ["a lot"] = "much|a great deal", ["let's go"] = "come, let us walk|let us go",
  ["let's"] = "let us", ["oh my god"] = "by the Earth Mother|Earth Mother preserve us", ["omg"] = "by the Earth Mother",
  ["what the hell"] = "by the Earth Mother|what trouble is this", ["wtf"] = "by the Earth Mother", ["good luck"] = "may the winds guide you|walk with the Earth Mother",
  ["you guys"] = "little ones|friends", ["i'm going to"] = "I will", ["calm down"] = "be at peace|breathe, little one",
  ["how's it going"] = "how goes your path|how fare you", ["what's up"] = "how goes your path", ["take it easy"] = "walk in peace",
  ["hurry up"] = "quickly now, little one", ["i'm tired"] = "my hooves are weary", ["i'm hungry"] = "I am ready to graze",
  ["be careful"] = "walk with care", ["have fun"] = "find joy in it", ["i need"] = "I have need of", ["kind of"] = "somewhat",
  ["for real"] = "truly", ["my bad"] = "forgive me, friend", ["no way"] = "it cannot be",
})

---------------------------------------------------------------------------
-- Forsaken: dry, grim, darkly funny. Dead, and over it.
---------------------------------------------------------------------------
H("forsaken", {
  ["i think"] = "I suspect|I think", ["i don't know"] = "who knows|I neither know nor care", ["i don't care"] = "I stopped caring when I died|I care not",
  ["oh my god"] = "by the Dark Lady|how grim", ["omg"] = "how grim|by the Dark Lady", ["what the hell"] = "what in the Shadowlands|what fresh horror",
  ["wtf"] = "what fresh horror", ["i'm dying"] = "I'm already dead|I died once, it was fine",
  ["i'm dead"] = "I'm deader than usual", ["good luck"] = "try not to die. Or do, it's not so bad", ["you guys"] = "you living lot|you breathers",
  ["have fun"] = "enjoy it, if you're capable", ["i love"] = "I almost tolerate|I can stomach", ["i hate"] = "I loathe|I truly despise",
  ["a lot"] = "a great deal|plenty", ["let's go"] = "let's shamble on|onward, then", ["how's it going"] = "still rotting?|how's the decay",
  ["what's up"] = "still breathing?|what news from the living", ["i'm hungry"] = "I hunger|I could eat a brain", ["i'm tired"] = "my bones are tired",
  ["so cool"] = "so grim", ["so cute"] = "so disgustingly alive", ["feel better"] = "decay gracefully", ["take care"] = "stay dead",
  ["i miss"] = "I faintly remember", ["hurry up"] = "move it, corpse", ["calm down"] = "breathe. Oh wait",
  ["my bad"] = "my mistake. Mistakes happen when your brain is rotting", ["no way"] = "absolutely not",
})

---------------------------------------------------------------------------
-- Gnome: fast, excited, technical. Everything is an experiment.
---------------------------------------------------------------------------
H("gnome", {
  ["i think"] = "I calculate|by my calculations|I hypothesize", ["i don't know"] = "insufficient data|I'd need to run the numbers",
  ["a lot"] = "a whole lot|roughly a metric ton", ["right now"] = "right this second|immediately", ["let's go"] = "engage!|let's zip|full speed ahead",
  ["oh my god"] = "oh my gears|great gizmos", ["omg"] = "oh my gears|great gizmos", ["what the hell"] = "what in Gnomeregan", ["wtf"] = "what in Gnomeregan",
  ["you guys"] = "you folks|team", ["kind of"] = "roughly|approximately", ["not working"] = "malfunctioning|on the fritz",
  ["doesn't work"] = "malfunctions|is on the fritz", ["figure it out"] = "run the numbers", ["i'm tired"] = "my batteries are low|I'm low on power",
  ["good luck"] = "may your gears never grind", ["how's it going"] = "how are your gears turning", ["what's up"] = "status report",
  ["i'm hungry"] = "I need to refuel", ["hurry up"] = "chop chop|faster faster", ["for sure"] = "one hundred percent",
  ["no way"] = "statistically impossible", ["of course"] = "obviously, by simple deduction", ["calm down"] = "deep breaths, recalibrate",
  ["my bad"] = "user error, mine", ["i'm sure"] = "I'm ninety-nine percent sure", ["i'm not sure"] = "I'm about sixty percent sure",
}, {
  -- more exclamation marks, the more excited (stronger) it gets
  post = function(s, strength)
    if strength >= 2 and math.random() < 0.3 then s = s:gsub("%.$", "!") end
    if strength >= 3 and math.random() < 0.25 then s = s:gsub("!$", "!!") end
    return s
  end,
})

---------------------------------------------------------------------------
-- the strong three get their swears and cries too
---------------------------------------------------------------------------
H("orc", { ["oh my god"] = "by the ancestors|by Doomhammer", ["omg"] = "by Doomhammer", ["what the hell"] = "gol'kosh|what is this", ["wtf"] = "gol'kosh",
  ["you guys"] = "brothers|blood-kin", ["good luck"] = "fight well|strength and honor", ["let's go"] = "lok'tar!|for the Horde!", ["calm down"] = "steady, brother" })
H("troll", { ["oh my god"] = "by da loa|ma'tuba", ["omg"] = "by da loa", ["what the hell"] = "what da voodoo|ma'tuba", ["wtf"] = "what da voodoo",
  ["you guys"] = "you mon|my people", ["good luck"] = "good juju ta ya", ["let's go"] = "taz'dingo!|let's go, mon", ["calm down"] = "easy, mon" })
H("dwarf", { ["oh my god"] = "by me beard|by the Light", ["omg"] = "by me beard", ["what the hell"] = "what in the blazes|what in tarnation", ["wtf"] = "what in the blazes",
  ["you guys"] = "ye lot|lads", ["good luck"] = "good luck tae ye", ["let's go"] = "let's go, lads!|fer Ironforge!", ["calm down"] = "easy, lad" })

-- "group up" is a verb: never "party up" or "company up"
for key, v in pairs({ human = "band together|form a party", nightelf = "gather together", tauren = "band together|gather as one herd",
  forsaken = "band together", gnome = "team up|assemble the team", orc = "form a warband|join up", troll = "team up, mon|team up",
  dwarf = "team up|band together" }) do
  H(key, { ["group up"] = v, ["grouping up"] = "teaming up" })   -- (1.4.6) "want to group" is left to KeepHere: "want to group up" read "team up up"
end
-- Forsaken irony stays clear: good never comes out as "dreadful"
do
  local p = ns.ACCENTS.forsaken.lex.good
  for i = #p, 1, -1 do if p[i] == "dreadful" then table.remove(p, i) end end
end

-- game names that are one thing: never "auction manor" or "guild hall-bank"
local LOCK = { "auction house", "flight path", "guild bank", "guild chat", "trade chat", "bank alt", "group finder", "dungeon finder",
  "world buff", "world buffs", "raid lead", "group leader", "party leader", "hearth stone", "mount up", "dungeon journal",
  "okay good", "ok good", "oh good", "all good", "good to go", "it's not", "not so", "not right now",
  "go farm", "go grind", "go quest", "go level", "go solo", "go farming", "go questing", "go grinding", "the night", "tonight",
  -- (1.2.0) set phrases about time and turns: "one more age" and "what tide" broke them
  "one more time", "next time", "last time", "this time", "every time", "first time", "what time", "on time", "in time",
  "any time", "some time", "same time", "a long time", "for a while", "go to bed", "going to bed",
  "run it", "run it back", "pull more", "the rest of",
  -- (1.4.3)
  "take it easy", "world boss", "world bosses", "world buff", "world buffs", "world chat", "world pvp", "i'm going to bed",
  "im going to bed", "i am going to bed", "going to sleep", "go to sleep", "go to bed", "easy money", "play wow" }
for _, key in ipairs(ns.ORDER) do
  local d = ns.ACCENTS[key]
  if not d.whole then
    local t = {}
    for _, p in ipairs(LOCK) do if not (d.phrases and d.phrases[p]) then t[p] = p end end
    Bank(key, { phrases = t })
  end
end

-- Troll: "mon" once per message is flavor, twice is a parody
do
  local d = ns.ACCENTS.troll
  local old = d.post
  d.post = function(s, strength, opts)
    if old then s = old(s, strength, opts) end
    local seen = false
    s = s:gsub("(,?%s*)(%f[%a][Mm]on)(%f[^%a])", function(pre, m, post)
      if seen then return "" end
      seen = true
      return pre .. m .. post
    end)
    s = s:gsub(",%s*([%.!%?])", "%1"):gsub("([%.!%?])%s*[%.!%?]+", "%1"):gsub("%s%s+", " ")
    return (s:gsub("%s+$", ""))
  end
  -- and the closers that are just "mon" again are skipped when a "mon" is already in
  local keep = {}
  for _, c in ipairs(d.closers or {}) do if not c:lower():find("mon") then keep[#keep + 1] = c end end
  d.closers = keep
end
-- Troll: "be" for "is/are" most of the time, not every time
do
  local d = ns.ACCENTS.troll
  d.words.is, d.words.are, d.words.am = nil, nil, nil
  table.insert(d.rules, 1, { "^is$", "be", min = 1, chance = 0.55 })
  table.insert(d.rules, 1, { "^are$", "be", min = 1, chance = 0.55 })
  table.insert(d.rules, 1, { "^am$", "be", min = 1, chance = 0.7 })
end
do
  local d = ns.ACCENTS.troll
  -- "think" is "tink", never "dink"; "three" is "tree"
  table.insert(d.rules, 1, { "^thank", "t'ank", min = 1, stop = true })
  table.insert(d.rules, 1, { "^thr", "tr", min = 2, chance = 0.8, stop = true })
  table.insert(d.rules, 1, { "^th(in[kg])", "t%1", min = 1, stop = true })
  table.insert(d.rules, 1, { "^thought", "t'ought", min = 1, stop = true })
  -- "my friend" must not become "me my mon"
  local f = d.lex.friend
  for i = #f, 1, -1 do if f[i] == "my mon" then table.remove(f, i) end end
  -- cheers belong after a cheer, not after any line
  local keep = {}
  for _, c in ipairs(d.closers) do if c ~= "Taz'dingo!" and c ~= "Mado'ru." then keep[#keep + 1] = c end end
  d.closers = keep
end

-- Undead: dry wit in words, the odd rattle, never a pile of emotes
do
  local d = ns.ACCENTS.forsaken
  d.say.lol = { "Heh.", "How droll.", "Ha. Ha.", "I'd laugh, but my lungs rotted.", "*dry rattling laugh*", "Heh heh. Grim.", "Hilarious. Truly." }
  d.lex.lol = { "heh", "how droll", "ha", "heh heh" }
  d.interject = { "heh", "breather", "hmph", "how grim" }
  d.openers = { "Hrrm.", "Hmph.", "Listen, breather.", "Ah, the living." }
  d.closers = { "For the Dark Lady.", "Death awaits.", "Heh.", "*rattles bones*", "We are the Forsaken.", "How grim.", "Not that it matters." }
  d._index = nil
end

-- "drink" is a thing and a verb ("need to drink"): only swaps that work both ways
for key, v in pairs({ orc = "drink|swig", troll = "drink|sip", tauren = "drink|sip", forsaken = "drink|swill", human = "drink|sip",
  dwarf = "drink|swig|sup", gnome = "drink|sip", nightelf = "drink|sip" }) do
  local d = ns.ACCENTS[key]
  local t = {}
  for w in v:gmatch("[^|]+") do t[#t + 1] = w end
  d.lex.drink = t
  if d.words then d.words.drink = nil end
  Bank(key, { phrases = { ["quest item"] = "quest item", ["quest items"] = "quest items" } })
end

-- "tank" and "hard" are also verbs and adverbs ("I can tank", "carried us hard"): leave them be
for _, key in ipairs(ns.ORDER) do
  local d = ns.ACCENTS[key]
  if d.lex then d.lex.tank, d.lex.hard = nil, nil end
  if d.words then d.words.hard = nil end
end
Bank("human", { phrases = { ["i need to"] = { "I must", "I simply must" }, ["we need to"] = { "we must" }, ["i think"] = { "I daresay", "I believe", "methinks" } } })
Bank("nightelf", { phrases = { ["i need to"] = { "I must" }, ["we need to"] = { "we must" } } })
Bank("tauren", { phrases = { ["i need to"] = { "I must" }, ["we need to"] = { "we must" } } })
Bank("gnome", { phrases = { ["you guys"] = { "you folks", "you team" } } })
Bank("tauren", { phrases = { ["you guys"] = { "you friends", "little ones" } } })
Bank("human", { lex = {} })
do
  local h = ns.ACCENTS.human.lex.but
  if h then for i = #h, 1, -1 do if h[i] == "however" then table.remove(h, i) end end end
  for _, key in ipairs(ns.ORDER) do local d = ns.ACCENTS[key]; if d.lex then d.lex.later = nil end end
end

-- Dwarf: Scots people can read at a glance ("aye", "wee", "lad", "cannae"), not ones that look like typos
do
  local d = ns.ACCENTS.dwarf
  local OBSCURE = { guid = 1, whit = 1, braw = 1, wabbit = 1, siller = 1, rammy = 1, feart = 1, crivens = 1, whaur = 1, scoff = 1, sup = 1 }
  for g, list in pairs(d.lex) do
    for i = #list, 1, -1 do if OBSCURE[list[i]:lower()] then table.remove(list, i) end end
    if #list == 0 then d.lex[g] = nil end
  end
  for k, v in pairs(d.words or {}) do
    if type(v) == "table" then
      for i = #v, 1, -1 do if OBSCURE[v[i]:lower()] then table.remove(v, i) end end
      if #v == 0 then d.words[k] = nil elseif #v == 1 then d.words[k] = v[1] end
    elseif OBSCURE[v:lower()] then d.words[k] = nil end
  end
  d.openers = { "Och,", "Aye,", "Listen here,", "By me beard," }
end

-- No catchphrases tacked onto the end of a line ("Now where's me ale?"): they get repetitive fast.
-- Openers stay only when they're a short word or two ("Och,", "Hmph."), and they stay rare.
for _, key in ipairs(ns.ORDER) do
  local d = ns.ACCENTS[key]
  d.closers = nil
  if d.openers then
    local keep = {}
    for _, o in ipairs(d.openers) do
      local _, n = o:gsub("%S+", "")
      if n <= 2 then keep[#keep + 1] = o end
    end
    d.openers = #keep > 0 and keep or nil
  end
end
do
  local function Without(list, bad) if not list then return end for i = #list, 1, -1 do if bad[list[i]] then table.remove(list, i) end end end
  local o = ns.ACCENTS.orc.lex
  Without(o.obviously, { ["everyone know"] = 1 }); Without(o.bad, { soft = 1 }); Without(o.gear, { spoils = 1 })
  Bank("dwarf", { phrases = { ["let me know"] = "let me know", ["you know"] = "ye know" } })
end

-- No class or role words, in or out: "LF healer" stays "healer", and no swap ever brings in "warrior", "priest" or "mage"
-- (in a group-finding line a class name means something specific)
do
  local CLASS = { "warriors?", "priests?", "priestess", "shamans?", "druids?", "mages?", "hunters?", "huntress", "rogues?", "paladins?", "warlocks?" }
  local function HasClass(x)
    if type(x) ~= "string" then return false end
    local l = " " .. x:lower() .. " "
    for _, c in ipairs(CLASS) do if l:find("[^%a]" .. c .. "[^%a]") then return true end end
    return false
  end
  local ROLE = { "healer", "healers", "tank", "tanks", "dps", "warrior", "rogue", "mage", "hunter", "priest", "paladin", "warlock", "druid", "shaman" }
  for _, key in ipairs(ns.ORDER) do
    local d = ns.ACCENTS[key]
    for _, g in ipairs(ROLE) do
      if d.lex then d.lex[g] = nil end
      if d.words then d.words[g] = nil end
      if d.more then d.more[g] = nil end
      if d.heavy then d.heavy[g] = nil end
    end
    for _, t in ipairs({ d.lex, d.words, d.more, d.heavy }) do
      if t then
        for g, v in pairs(t) do
          if type(v) == "table" then
            for i = #v, 1, -1 do if HasClass(v[i]) then table.remove(v, i) end end
            if #v == 0 then t[g] = nil end
          elseif HasClass(v) then t[g] = nil end
        end
      end
    end
  end
end

-- (1.4.5) no catchphrases dropped in front of a line that has nothing to do with them ("Fun fact: need a heal").
-- Gnome keeps its sound in its words, not tacked-on bits
do
  local g = ns.ACCENTS.gnome
  g.openers = nil
  g.interject = { "technically" }
  local l = g.say and g.say.lol
  if l then for i = #l, 1, -1 do if l[i]:find("detected") then table.remove(l, i) end end end
  local function Drop(key, bad)
    local d = ns.ACCENTS[key]
    if not (d and d.openers) then return end
    for i = #d.openers, 1, -1 do if bad[d.openers[i]] then table.remove(d.openers, i) end end
    if #d.openers == 0 then d.openers = nil end
  end
  Drop("noir", { ["Funny thing."] = 1 })
  Drop("human", { ["Pray tell,"] = 1 })
  for _, key in ipairs(ns.ORDER) do ns.ACCENTS[key]._index = nil end
end
