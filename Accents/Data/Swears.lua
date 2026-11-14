-- Dalorrian's Accents: swear words, swapped for each race's own (funny, clean) way of swearing.
-- Swapped by how the word is used: on its own ("shit!"), as a thing ("this shit"), for emphasis ("fucking annoying"),
-- as a curse ("screw this"), an insult ("asshole") or a whole phrase ("what the fuck").
-- Slurs are never touched. Players who want their swears kept turn it off in Settings (Swear Words: Keep).
local ADDON, ns = ...
local E = ns.Engine

local function L(v) local t = {}; for x in v:gmatch("[^|]+") do t[#t + 1] = x end; return t end

local RACE = {
  skyborne = { dgood = "soaringly good", ex = "Ill winds|Storms take it|By the four winds", noun = "storm-muck|bilge of the clouds|rubbish", int = "storm-cursed|ill-winded|wretched",
    verb = "storms take|curse", doomed = "grounded|lost to the gale", insult = "featherbrain|windbag|storm-cursed fool", ass = "tail feathers|backside",
    wtf = "what ill wind|by the four winds, what", stfu = "still your winds|hush, featherbrain", yes = "yes, by the four winds|gladly, gladly", no = "never, not on any wind|no, by the winds",
    place = "the endless storm", bull = "hot air|wind and nonsense", mad = "storm-tossed|tempestuous", whine = "howling" },
  orc = { dgood = "mighty good", ex = "Gol'kosh|Grr|Blood and thunder|Bah", noun = "dung|boar dung|filth", int = "blood-cursed|stupid|cursed",
    verb = "smash|curse", doomed = "doomed|smashed|done for", insult = "ur'gora|weakling|coward|peon", ass = "hide|rump",
    wtf = "what in Doomhammer's name|by the ancestors, what", stfu = "silence, peon|quiet, weakling", yes = "lok'tar, yes|zug zug, YES",
    no = "never|NO. Never", place = "the Twisting Nether", bull = "boar dung|lies", mad = "angry like boar|raging", whine = "whining like peon" },
  troll = { dgood = "real good", ex = "Bah|Curses|Ma'tuba|Oh mon", noun = "bad mojo|junk|raptor dung", int = "cursed|crazy|dang", verb = "hex|curse",
    doomed = "cursed|done for|in trouble", insult = "zagota|fool|bad mojo", ass = "behind|rump", wtf = "what da voodoo|ma'tuba, what",
    stfu = "hush, mon|quiet, zagota", yes = "ya mon|taz'dingo, yes", no = "no way, mon|nah, never", place = "da Nether",
    bull = "bad mojo|lies", mad = "real mad|hot", whine = "cryin'" },
  tauren = { dgood = "truly good", ex = "By the Earth Mother|Hrm|Alas", noun = "kodo dung|mud|dung", int = "wretched|troublesome|foul", verb = "curse|trample",
    doomed = "lost|trampled|in deep trouble", insult = "ill-mannered calf|foolish one|lost calf", ass = "hindquarters|rump",
    wtf = "what in the Earth Mother's name|by the Earth Mother, what", stfu = "be silent, little one|peace, calf",
    yes = "yes, by the Earth Mother|truly yes", no = "no, by the Earth Mother|never", place = "the Emerald Nightmare",
    bull = "kodo dung|nonsense", mad = "stampeding mad|stormy", whine = "bellowing" },
  forsaken = { dgood = "disturbingly good", ex = "Rot it|Curses|Plague take it", noun = "rot|filth|offal", int = "festering|rotten|wretched", verb = "rot|curse",
    doomed = "doomed|rotten|finished", insult = "maggot|wretch|fleshbag", ass = "bony backside|rotting rump",
    wtf = "what fresh horror|what in the Shadowlands", stfu = "silence, breather|hush, maggot", yes = "deliciously yes|yes, gladly",
    no = "absolutely not|never, breather", place = "the Shadowlands", bull = "rot|lies", mad = "seething|livid", whine = "moaning" },
  human = { dgood = "jolly good", ex = "Confound it|Blast|Good heavens|Drat", noun = "rubbish|nonsense|horse muck", int = "blasted|bloody|confounded",
    verb = "confound|blast", doomed = "doomed|done for|in a dreadful state", insult = "scoundrel|cad|knave", ass = "posterior|backside",
    wtf = "what the devil|what in the Light's name", stfu = "hold your tongue|do be quiet", yes = "most certainly|indeed, yes",
    no = "certainly not|absolutely not", place = "the devil", bull = "rubbish|poppycock", mad = "cross|positively livid", whine = "grumbling" },
  dwarf = { dgood = "bloody good", ex = "Blast|Och|By me beard|Bah", noun = "muck|rubbish|ram dung", int = "flamin'|bloody|blasted", verb = "blast|curse",
    doomed = "done for|in a right mess|flattened", insult = "numpty|eejit|scoundrel", ass = "arse|backside",
    wtf = "what in the blazes|what in tarnation", stfu = "pipe down, lad|shut yer gob", yes = "aye, by me beard|och aye",
    no = "nae chance|no way, lad", place = "the blazes", bull = "rubbish|hogwash", mad = "ragin'|fumin'", whine = "moanin'" },
  gnome = { dgood = "optimally good", ex = "Fiddlesticks|Drat|Gears and sprockets|Oh bother", noun = "scrap|junk|slag", int = "dratted|gear-grinding|blasted",
    verb = "drat|scrap", doomed = "doomed|kaput|in critical failure", insult = "malfunctioning unit|dunderhead|nincompoop",
    ass = "chassis|rear housing", wtf = "what in Gnomeregan|what the sprockets", stfu = "mute, please|volume down, please",
    yes = "affirmative, absolutely|yes yes yes", no = "negative, absolutely not|statistically never", place = "the scrap heap",
    bull = "nonsense|faulty data", mad = "overheated|steaming", whine = "beeping" },
  nightelf = { dgood = "truly good", ex = "By Elune|Alas|Curses", noun = "filth|corruption|satyr dung", int = "accursed|wretched|cursed", verb = "curse|banish",
    doomed = "doomed|lost to the Nightmare|cursed", insult = "satyr|defiler|foolish one", ass = "hide|backside",
    wtf = "what in Elune's name|by Elune, what", stfu = "be silent|silence, young one", yes = "yes, by Elune|truly yes",
    no = "never, by Elune|it shall not be", place = "the Nightmare", bull = "falsehood|lies", mad = "wrathful|furious", whine = "lamenting" },
  pirate = { dgood = "mighty fine|shipshape", ex = "Blimey|Shiver me timbers|Blow me down|Arr", noun = "bilge|bilge water|barnacles", int = "blasted|scurvy|cursed",
    verb = "scuttle|keelhaul", doomed = "sunk|shipwrecked|done for", insult = "bilge rat|scallywag|scurvy dog", ass = "poop deck|stern",
    wtf = "what in Davy Jones' locker|blimey, what", stfu = "belay that talk|stow it, matey", yes = "aye, by thunder|aye aye", no = "nay, never|not on yer life",
    place = "Davy Jones' locker", bull = "bilge|barnacles", mad = "fit to be tied|ragin' like a storm", whine = "bellyachin'" },
  goblin = { dgood = "profitable|top quality", ex = "Holy moolah|Bankruptcy|Aw, scrap", noun = "junk|scrap|bad merchandise", int = "lousy|blasted|overpriced",
    verb = "bankrupt|scrap", doomed = "bankrupt|broke|in the red", insult = "cheapskate|chump|deadbeat", ass = "assets|rear",
    wtf = "what in the Trade Prince's name|what the scrap", stfu = "zip it, pal|can it, chump", yes = "deal of the century|absolutely, pal", no = "no deal|not for any price",
    place = "the bargain bin", bull = "a scam|a rip-off", mad = "steamed|livid", whine = "haggling" },
  kobold = { dgood = "good good", ex = "Candle out|Bad bad|No no no", noun = "dirt|rocks|wax", int = "bad bad|stupid stupid", verb = "stab|poke",
    doomed = "doomed doomed|in big trouble", insult = "candle thief|dirt head", ass = "tail|bottom", wtf = "what what|who take candle, what",
    stfu = "shush shush|quiet quiet", yes = "yes yes YES", no = "NO NO NO", place = "the deep tunnel", bull = "lies lies", mad = "mad mad", whine = "squeaking" },
  ogre = { dgood = "real good|tasty good", ex = "Ow|Hurr|Bah", noun = "poo|mud|stinky", int = "stupid|stinky|dumb", verb = "smash|bonk",
    doomed = "smashed|dead dead", insult = "dumb dumb|stinky head", ass = "butt|big butt", wtf = "what dat|huh what", stfu = "shush, other head|quiet, head",
    yes = "YAH|yah yah", no = "NO!|me say no", place = "da bad place", bull = "stinky lies", mad = "angry angry", whine = "cry cry" },
  raidboss = { dgood = "IMPRESSIVELY good", ex = "IMPOSSIBLE|CURSE YOU|NOOO", noun = "filth|insolence|refuse", int = "insolent|wretched|accursed",
    verb = "obliterate|curse", doomed = "DOOMED|finished", insult = "insect|worm|fool", ass = "hide|hindquarters", wtf = "WHAT SORCERY|IMPOSSIBLE, what",
    stfu = "SILENCE, insect|SILENCE", yes = "YES! IT SHALL BE SO|YES", no = "NEVER|I THINK NOT", place = "the Abyss", bull = "LIES|insolence",
    mad = "FURIOUS|enraged", whine = "groveling" },
  bard = { dgood = "most excellent|passing good", ex = "Zounds|Fie|Gadzooks|Out, damned spot", noun = "dross|offal|rubbish", int = "accursed|wretched|pox-ridden",
    verb = "a pox upon|fie upon", doomed = "undone|ruined", insult = "knave|varlet|scurvy knave|lily-livered coward", ass = "posterior|hindquarters",
    wtf = "what devilry is this|zounds, what", stfu = "hold thy tongue|peace, knave", yes = "aye, verily|yea, forsooth", no = "nay, never|nay, I say",
    place = "the devil", bull = "falsehood|knavery", mad = "wroth|in high dudgeon", whine = "bemoaning" },
  noir = { dgood = "not bad at all|clean", ex = "Damn this city|Swell|Just my luck", noun = "garbage|trouble|a bad deal", int = "rotten|lousy|crooked",
    verb = "forget|scram from", doomed = "finished|washed up|in deep trouble", insult = "rat|two-bit crook|sap", ass = "hide|tail",
    wtf = "what in the blazes|what kind of racket", stfu = "can it, pal|zip it, sap", yes = "you bet, pal|sure as rain", no = "not a chance, pal|no dice",
    place = "the gutter", bull = "a lie|a racket", mad = "burned up|sore", whine = "griping" },
  sergeant = { dgood = "OUTSTANDING", ex = "SON OF A BISCUIT|GOOD GRAVY|HOLY MOLY", noun = "GARBAGE|SLOP|NONSENSE", int = "SORRY-ASS|PATHETIC|SLOPPY",
    verb = "FORGET|SCREW", doomed = "TOAST|DONE FOR", insult = "MAGGOT|KNUCKLEHEAD|SORRY EXCUSE FOR A SOLDIER", ass = "BEHIND|CAN",
    wtf = "WHAT IN THE SAM HILL|WHAT IN TARNATION", stfu = "SHUT YOUR CAKEHOLE|ZIP IT, MAGGOT", yes = "OORAH|HOO-AH", no = "NEGATIVE|NOT ON MY WATCH",
    place = "LATRINE DUTY", bull = "GARBAGE|NONSENSE", mad = "STEAMING MAD|FURIOUS", whine = "CRYING" },
  epic = { dgood = "fair and goodly|most excellent", ex = "Alas|By the stars|Woe", noun = "filth|ruin|refuse", int = "accursed|fell|foul",
    verb = "a curse upon|woe to", doomed = "doomed|lost|undone", insult = "wretch|craven|servant of shadow", ass = "hide|hindquarters",
    wtf = "what devilry|by the stars, what", stfu = "be silent|peace, fool", yes = "yea, verily|aye, and gladly", no = "nay, never|it shall not be",
    place = "the darkness", bull = "falsehood|lies", mad = "wrathful|grim of mood", whine = "lamenting" },
  grimdark = { dgood = "bloody good|good enough", ex = "Gods be damned|Bloody gods|Gods above", noun = "dung|filth|blood and dung", int = "bloody|cursed|craven",
    verb = "curse|damn", doomed = "dead men|doomed|finished", insult = "craven|turncloak|cur", ass = "arse|hide",
    wtf = "what in the gods' names|gods, what", stfu = "hold your tongue|shut your mouth", yes = "aye, gods yes|aye", no = "never|gods, no",
    place = "the deepest hell", bull = "lies|horse dung", mad = "furious|blood-mad", whine = "whimpering" },
  wry = { dgood = "suspiciously good|not bad at all", ex = "Good grief|Oh dear|Bother", noun = "rubbish|nonsense|mess", int = "wretched|blessed|ridiculous",
    verb = "bother|blow", doomed = "in Trouble|in a bit of a pickle", insult = "pillock|absolute pillock|ninny", ass = "backside|posterior",
    wtf = "good grief, what|what on earth", stfu = "do be quiet|hush now", yes = "oh, absolutely|yes, enthusiastically", no = "absolutely not|no, and also no",
    place = "the bad place", bull = "nonsense|utter nonsense", mad = "cross|quite cross", whine = "grumbling" },
  wizard = { dgood = "magnificently good|arcanely excellent", ex = "By the arcane|Confound it|Blast and bother", noun = "rubbish|arcane residue|mundane nonsense", int = "accursed|wretched|blasted",
    verb = "a hex upon|confound", doomed = "doomed|thoroughly disenchanted", insult = "dunce|charlatan|half-wit", ass = "posterior|robes",
    wtf = "what arcane nonsense|by the arcane, what", stfu = "silence, apprentice|hold thy tongue", yes = "indubitably yes|most certainly", no = "absolutely not|never, by the arcane",
    place = "the Twisting Nether", bull = "poppycock|balderdash", mad = "incensed|positively livid", whine = "sniveling" },
  prospector = { dgood = "mighty fine", ex = "Dagnabbit|Consarn it|Tarnation|Dad-gum it", noun = "horse apples|fool's gold|hogwash", int = "dad-gum|consarned|dagnabbed",
    verb = "dagnabbit", doomed = "plumb done for|in a heap o' trouble", insult = "varmint|claim jumper|dang fool", ass = "hindquarters|caboose",
    wtf = "what in tarnation|what in the Sam Hill", stfu = "pipe down, varmint|hush yer mouth", yes = "yessiree|you betcha", no = "not on yer life|nope, nope, nope",
    place = "tarnation", bull = "hogwash|horse apples", mad = "madder'n a wet hen|fit to be tied", whine = "bellyachin'" },
  caveman = { dgood = "big good", ex = "UGG|Ugg mad|Grr", noun = "mammoth poo|dirt|bad rocks", int = "stupid|bad bad|dumb", verb = "smash|bonk",
    doomed = "doomed|squished", insult = "rock head|small brain", ass = "butt", wtf = "what|huh, what", stfu = "quiet!|shh! Ugg think!",
    yes = "UGG YES", no = "UGG NO", place = "big hole", bull = "lies", mad = "angry angry", whine = "cry" },
  robot = { dgood = "OPTIMAL", ex = "ERROR|FATAL ERROR|SYSTEM FAILURE", noun = "GARBAGE DATA|CORRUPTED FILES|SPAM", int = "CORRUPTED|DEFECTIVE|BROKEN",
    verb = "DELETE|UNINSTALL", doomed = "BRICKED|OFFLINE", insult = "OBSOLETE UNIT|DEFECTIVE HUMAN|VIRUS", ass = "CHASSIS|REAR PANEL",
    wtf = "DOES NOT COMPUTE|ERROR, WHAT", stfu = "MUTE.EXE|SILENCE, HUMAN", yes = "AFFIRMATIVE. VERY AFFIRMATIVE", no = "NEGATIVE. ABSOLUTELY NEGATIVE",
    place = "THE RECYCLE BIN", bull = "FALSE DATA|INVALID INPUT", mad = "OVERHEATING|IN RAGE MODE", whine = "BEEPING" },
  peasant = { dgood = "proper good", ex = "Cor blimey|Gor|Lawks|Oh, bother", noun = "muck|mud|pig slop", int = "bloomin'|blinkin'|flippin'",
    verb = "plague take|blast", doomed = "done for|in the muck", insult = "turnip head|nitwit|muck-for-brains", ass = "backside|bum",
    wtf = "what in the blazes|cor, what", stfu = "shut yer cakehole|oi, quiet", yes = "aye, right you are|oh, aye", no = "not bloomin' likely|no fear",
    place = "the muck pit", bull = "codswallop|tosh", mad = "proper cross|right cheesed off", whine = "moanin'" },
  cowboy = { dgood = "mighty fine", ex = "Dagnabbit|Tarnation|Shoot|Well, horse feathers", noun = "cow pies|horse feathers|hogwash", int = "dang|dadgum|ornery",
    verb = "dang", doomed = "done for|six feet under", insult = "yellow-bellied varmint|no-good outlaw|tenderfoot", ass = "hide|saddle end",
    wtf = "what in tarnation|what in the Sam Hill", stfu = "hush up, partner|zip it, varmint", yes = "yeehaw, yes|you betcha", no = "not on yer life|nope, nohow",
    place = "tarnation", bull = "hogwash|horse feathers", mad = "madder'n a hornet|fit to be tied", whine = "bellyachin'" },
  surfer = { dgood = "totally rad", ex = "Bogus|Harsh, dude|Wipeout", noun = "kelp|seaweed|bogus junk", int = "freakin'|totally bogus|gnarly",
    verb = "forget|bail on", doomed = "wiped out|so wiped out", insult = "kook|barney|total kook", ass = "board shorts|behind",
    wtf = "duuude, what|whoa, what", stfu = "chill, brah|mellow out, dude", yes = "totally, dude|for sure, brah", no = "nah, brah|no way, dude",
    place = "the deep end", bull = "bogus|total kelp", mad = "so bummed|totally harshed", whine = "whining" },
  butler = { dgood = "most satisfactory", ex = "Good heavens|Goodness me|Dear me", noun = "rubbish|refuse|unpleasantness", int = "regrettable|unfortunate|most unpleasant",
    verb = "dispense with|be rid of", doomed = "in a most regrettable state|done for", insult = "scoundrel|ruffian|cad", ass = "posterior|person",
    wtf = "good heavens, what|what on earth", stfu = "if you would kindly be quiet|a little quiet, if you please", yes = "most certainly|indeed, very much so", no = "I'm afraid not|certainly not",
    place = "the servants' quarters", bull = "nonsense|utter rubbish", mad = "quite displeased|most cross", whine = "complaining" },
  grumpy = { dgood = "not terrible", ex = "Dagnabbit|Good grief|Consarn it|Bah", noun = "garbage|nonsense|hooey", int = "darn|dadburn|blasted",
    verb = "forget|to heck with", doomed = "done for|toast", insult = "whippersnapper|young fool|knucklehead", ass = "behind|keister",
    wtf = "what in tarnation|what the dickens", stfu = "pipe down|quiet, I'm napping", yes = "yes, yes, fine|I suppose so", no = "absolutely not|not in my day",
    place = "the old folks' home", bull = "hooey|baloney", mad = "fit to be tied|cranky", whine = "whining" },
  valley = { dgood = "like, sooo good", ex = "Ugh|Oh my gosh|Gag me", noun = "gross stuff|ew|drama", int = "freaking|literally|totally",
    verb = "ugh,|so over", doomed = "so over|literally dead", insult = "loser|total loser|creep", ass = "butt|behind",
    wtf = "like, what even|oh my gosh, what", stfu = "talk to the hand|like, shush", yes = "like, totally|for sure", no = "as if|ew, no",
    place = "the mall food court", bull = "so fake|drama", mad = "so mad|literally fuming", whine = "complaining" },
  conspiracy = { dgood = "suspiciously good", ex = "I KNEW IT|Wake up|Classic cover-up", noun = "propaganda|lies|a psy-op", int = "rigged|suspicious|staged",
    verb = "expose|don't trust", doomed = "compromised|set up", insult = "sheep|government plant|shill", ass = "behind|tinfoil hat",
    wtf = "what in the name of the cover-up|wake up, what", stfu = "they're listening, shh|not here, they're watching", yes = "EXACTLY|you see it too", no = "that's what they want you to think|no, wake up",
    place = "the secret bunker", bull = "propaganda|a cover-up", mad = "furious, and they know it|livid", whine = "spreading lies" },
  announcer = { dgood = "WORLD-CLASS", ex = "OH NO|WHAT A DISASTER|OH MY", noun = "a fumble|a disaster|garbage time", int = "UNBELIEVABLE|WILD|INSANE",
    verb = "take down", doomed = "in deep trouble|DOWN and OUT", insult = "rookie|benchwarmer|bum", ass = "behind|backfield",
    wtf = "WHAT IN THE WORLD|WHAT ON EARTH", stfu = "and the commentator goes quiet|let's hear the crowd", yes = "YES! YES! YES|ABSOLUTELY", no = "NO! NO! NO|ABSOLUTELY NOT",
    place = "the penalty box", bull = "a bad call|a FLAG on the play", mad = "FURIOUS|seeing red", whine = "complaining to the ref" },
}

-- single words, by group (see Lexicon.lua)
local GROUP = { swear = "noun", swearing = "int", fuck = "verb", fucked = "doomed", insult = "insult", bitch = "insult",
  ass = "ass", damnit = "ex", pissed = "mad", hell = "place", bullshit = "bull", bitching = "whine" }
for g in pairs(GROUP) do E.SWEAR_GROUP[g] = true end

-- whole phrases, built from each race's lists
local function each(list, f) local t = {}; for _, x in ipairs(L(list)) do t[#t + 1] = f(x) end; return t end
local PHRASES = {
  wtf = { "what the fuck", "what the actual fuck", "what the hell", "what the shit", "wth" },
  stfu = { "shut the fuck up", "stfu", "shut the hell up", "stfu dude", "stfu bro", "stfu man", "shut the fuck up dude" },
  yes = { "hell yeah", "hell yes", "hell yea", "fuck yeah", "fuck yes" },
  no = { "hell no", "fuck no", "fuck that" },
  ex = { "holy shit", "oh shit", "oh fuck", "god damn it", "goddamn it", "damn it", "for fuck's sake", "ffs", "omfg", "fuck me", "oh my fucking god", "son of a bitch" },
  doomed = { "fucked up", "so fucked", "screwed up" },
  mad = { "pissed off" },
  insult = { "dick bag", "dickbag", "douche bag", "douchebag", "scumbag", "dirt bag", "dirtbag", "jackass", "jack ass", "dipshit",
    "shithead", "dickhead", "dumb ass", "bitch ass", "fuckface", "fuckhead", "piece of crap" },
}
for _, list in pairs(PHRASES) do for _, p in ipairs(list) do E.SWEAR_PHRASE[p] = true end end
local BUILT = {
  ["piece of shit"] = function(r) return each(r.noun, function(x) return "piece of " .. x end) end,
  ["full of shit"] = function(r) return each(r.noun, function(x) return "full of " .. x end) end,
  ["this shit"] = function(r) return each(r.noun, function(x) return "this " .. x end) end,
  ["fuck off"] = function(r) return each(r.place, function(x) return "go to " .. x end) end,
  ["piss off"] = function(r) return each(r.place, function(x) return "go to " .. x end) end,
  ["go to hell"] = function(r) return each(r.place, function(x) return "go to " .. x end) end,
  ["fuck you"] = function(r) return each(r.verb, function(x) return x .. " you" end) end,
  ["screw you"] = function(r) return each(r.verb, function(x) return x .. " you" end) end,
  ["fuck this"] = function(r) return each(r.verb, function(x) return x .. " this" end) end,
  ["screw this"] = function(r) return each(r.verb, function(x) return x .. " this" end) end,
  ["screw that"] = function(r) return each(r.verb, function(x) return x .. " that" end) end,
  ["fuck it"] = function(r) return each(r.verb, function(x) return x .. " it" end) end,
  ["kick ass"] = function(r) return each(r.ass, function(x) return "kick " .. x end) end,
  ["damn good"] = function(r) return L(r.dgood) end,
  ["so damn"] = function(r) return each(r.int, function(x) return "so " .. x end) end,
}
for p in pairs(BUILT) do E.SWEAR_PHRASE[p] = true end

for key, r in pairs(RACE) do
  local d = ns.ACCENTS[key]
  if d then
    d.lex = d.lex or {}
    for g, slot in pairs(GROUP) do d.lex[g] = L(r[slot]) end
    local ph = {}
    for slot, list in pairs(PHRASES) do
      for _, p in ipairs(list) do
        local v = L(r[slot])
        if slot == "ex" then for i, x in ipairs(v) do v[i] = x .. "," end end
        ph[p] = v
      end
    end
    for p, f in pairs(BUILT) do ph[p] = f(r) end
    ns.Bank(key, { phrases = ph })
    d.lex.damn = L(r.ex)
    if d.words then for _, w in ipairs({ "damn", "shit", "fuck", "hell", "crap" }) do d.words[w] = nil end end
  end
end
E.SWEAR_GROUP.damn = true
