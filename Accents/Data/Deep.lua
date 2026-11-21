-- Dalorrian's Accents (1.1.0): deep word banks for Skyborne and the 24 unlockable accents, so an everyday line
-- comes out in the accent, not just greetings and thanks. Same rules as Banks.lua: lex[group] = "a|b|c" swaps any
-- word in that Lexicon group, phrases swap a whole bit of a sentence. Every swap keeps the word's job in the
-- sentence (a verb stays a verb in the same tense), and none use class or role words.
local ADDON, ns = ...

local function Split(v)
  if type(v) ~= "string" or not v:find("|") then return v end
  local t = {}
  for x in v:gmatch("[^|]+") do t[#t + 1] = x end
  return t
end
-- these groups stand alone ("thanks!", "wow"), so a longer swap with a comma is fine there
local PASTONLY = { ran = true, took = true, slew = true, smote = true, bit = true, went = true, saw = true, fell = true, rode = true, drove = true, threw = true }
local ONEWORD = { night = 1, day = 1, morning = 1, leave = 1, left = 1, time = 1 }
local OFWORDS = { afraid = true, scared = true, frightened = true, fearful = true, terrified = true, nervous = true }
local BOTHWAYS = { fight = true, brawl = true, battle = true, scrap = true, duel = true, rumble = true, clash = true, scuffle = true }
local ALONE = { hello = 1, bye = 1, yes = 1, no = 1, okay = 1, thanks = 1, sorry = 1, damn = 1, wow = 1, lol = 1, ugh = 1 }
local function Clean(group, v)
  if ALONE[group] then return v end
  local keep = {}
  for x in v:gmatch("[^|]+") do
    -- a comma ("fine, I guess") or a simile ("slow as molasses") reads wrong after "so" or before a noun
    -- and one that brings its own "so" or "really" doubles up with the line's ("so so slow", "really real good")
    local lead = x:match("^(%a+) ")
    local w1, w2 = x:match("^(%a+) (%a+)")
    local doubled = (w1 and w1 == w2) or lead == "not" or lead == "so" or lead == "totally" or lead == "really" or lead == "super" or lead == "very" or lead == "real" or lead == "literally"
    -- (1.2.0) group-specific checks: "fight" is a verb as often as a noun, so only words that work both ways;
    -- "killed me" can't become "took down me"; "this zone" needs one place, not "this shores"; nothing left
    -- hanging ("a whale of a")
    local ok = not x:find(",", 1, true) and not x:find(" as ", 1, true) and not x:find(" like ", 1, true) and not doubled
    if ok and (group == "fight" or group == "fights") then ok = BOTHWAYS[x:gsub("s$", "")] == true end
    if ok and (group == "kill" or group == "killed" or group == "killing") then
      ok = not (x:find(" down$") or x:find(" out$") or x:find(" off$") or x:find(" up$") or x:find(" in$"))
    end
    -- (1.4.1) "my gear is" needs one thing, not "my grave goods is"
    if ok and (group == "zone" or group == "gear" or group == "stuff" or group == "armor" or group == "weapon" or group == "mount") then ok = not x:find("s$") or x == "goods" and false end
    -- "got killed" / "was killed": past-only forms ("ran through", "slew") can't follow got/was
    if ok and group == "killed" then ok = not PASTONLY[x:match("^(%a+)")] end
    if ok then ok = not (x:find(" a$") or x:find(" an$") or x:find(" of$") or x:find("^of ")) end
    -- (1.2.0) "at night", "leave the group", "what time": one plain word only
    if ok and ONEWORD[group] then ok = not x:find(" ", 1, true) end
    -- "afraid of the spiders": only words that take "of"
    if ok and group == "scared" then ok = OFWORDS[x] == true end
    if ok then keep[#keep + 1] = x end
  end
  if #keep == 0 then return nil end
  return table.concat(keep, "|")
end
local function D(key, b)
  if not ns.ACCENTS[key] then return end
  local lex = {}
  for g, v in pairs(b.lex or {}) do lex[g] = Clean(g, v) end
  b.lex = lex
  local p = {}
  for k, v in pairs(b.phrases or {}) do p[k] = Split(v) end
  ns.Bank(key, { lex = b.lex, phrases = p, interject = b.interject, interjectChance = b.ic })
end

---------------------------------------------------------------------------
-- Skyborne: wind, sky and open air. Light, bright, a touch lofty.
---------------------------------------------------------------------------
D("skyborne", {
  lex = {
    friend = "sky-kin|friend|wind-friend", friends = "sky-kin|friends|wind-friends", enemy = "storm-bringer|foe", enemies = "storm-bringers|foes",
    mob = "beast|grounded thing", mobs = "beasts|grounded things", boss = "great storm|tempest", bosses = "great storms|tempests",
    noob = "fledgling|young one", idiot = "featherbrain|fool", idiots = "featherbrains|fools", leader = "elder|leader", kid = "fledgling|little one",
    man = "fellow|sky-walker", woman = "lady|sky-walker",
    good = "fair|bright|soaring|lovely", bad = "ill-winded|stormy|dreadful", big = "vast|towering", small = "slight|small|wisp of a",
    strong = "mighty|gale-strong", weak = "frail|windless", fast = "swift|gale-swift", quickly = "swiftly|on the wind", slow = "becalmed|slow",
    slowly = "gently|slowly", easy = "light as a feather|easy", hard = "a headwind|hard", funny = "delightful|funny", stupid = "featherbrained|foolish",
    smart = "clear-sighted|wise", crazy = "wind-mad|wild", scary = "ill-winded|stormy", tired = "weary|wind-worn", hungry = "hungry|famished",
    happy = "light-hearted|bright", sad = "grounded|heavy-hearted", angry = "stormy|tempestuous", rich = "rich in windstones|wealthy",
    lucky = "wind-blessed|lucky", unlucky = "ill-winded|unlucky", ugly = "storm-wracked|ugly", pretty = "radiant|lovely",
    old = "ancient|old as the winds", new = "new|fresh as a breeze", expensive = "dear|costly", broken = "shattered|broken",
    boring = "becalmed|dull", important = "weighty|important", very = "truly|most", maybe = "perhaps|maybe", probably = "likely|perhaps",
    definitely = "surely|truly", always = "always", never = "never|not on any wind", soon = "soon|on the next breeze",
    money = "windstones|gold", food = "fare|food", drink = "skyberry wine|drink", weapon = "blade|weapon", armor = "armor|wind-mail",
    gear = "gear|kit", stuff = "stuff|gear", quest = "task|errand", quests = "tasks|errands", dungeon = "deep place|dark hold",
    dungeons = "deep places|dark holds", home = "the isles|Zephras|home", city = "Valanaar|the city", fight = "storm|battle", fights = "storms|battles",
    night = "night|starlit night", morning = "dawn|morning", day = "day|bright day", problem = "ill wind|trouble", idea = "notion|idea",
    magic = "arcane winds|magic", mount = "hippogryph|mount", world = "the skies|the world", life = "life", luck = "fair winds|luck",
    kill = "cast down|bring down|ground", killed = "cast down|brought down|grounded", killing = "casting down|grounding",
    die = "fall from the sky", died = "fell from the sky", attack = "strike|swoop on", help = "help|aid", helped = "helped|aided",
    come = "come|drift over", coming = "coming|drifting over",
    leave = "leave|take wing", left = "left|took wing", wait = "wait|hold", stop = "stop", find = "find|spot", found = "found|spotted",
    look = "look|glance", see = "see|spy", think = "think|sense", farm = "farm|gather", farming = "farming|gathering",
    hello = "Gale's greetings|well met", bye = "fair winds|winds be with you", yes = "yes|indeed", no = "no|nay",
    okay = "very well|okay", thanks = "my thanks|thanks", sorry = "forgive me|sorry", damn = "storms take it|blast",
    wow = "by the four winds|gale's breath", lol = "ha|heh", ugh = "ugh|ill winds", honestly = "truly|on the open wind",
    obviously = "clearly|plain as sky", annoying = "vexing|annoying", dangerous = "perilous|stormy", ridiculous = "absurd|wind-mad",
    finally = "at last|finally", almost = "nearly|almost", ready = "ready", late = "late|behind the wind",
    scared = "uneasy|wind-shaken", sick = "unwell|sick", group = "flight|group", guild = "flock|guild", zone = "skies|lands",
  },
  phrases = {
    ["i need"] = "I have need of|I need", ["we need"] = "we have need of", ["let's"] = "let us", ["over there"] = "yonder|on the far winds",
    ["hurry up"] = "swiftly now|quick as a gust", ["come on"] = "come, sky-kin", ["for real"] = "truly", ["my bad"] = "forgive me, an ill wind",
    ["no worries"] = "let it blow past", ["what's up"] = "how fare the winds", ["how's it going"] = "how fare the winds",
    ["kind of"] = "somewhat", ["sounds good"] = "a fair wind, that", ["i'm hungry"] = "I could eat a feast",
    ["that's crazy"] = "what a wild wind", ["see you"] = "fair winds", ["oh no"] = "storms, no",
  },
  interject = "by the winds|sky-kin|on my wings",
  ic = { 0, 0.15, 0.25 },
})

---------------------------------------------------------------------------
-- Noir Detective: a tired private eye in a rotten city. Hard-boiled, clipped, a little poetic.
---------------------------------------------------------------------------
D("noir", {
  lex = {
    friend = "pal|partner|chum|friend", friends = "pals|mugs|folks|the gang", enemy = "crook|heavy|rat", enemies = "crooks|heavies|rats",
    mob = "goon|thug|lug", mobs = "goons|thugs|heavies", boss = "kingpin|big boss|top dog", bosses = "kingpins|big shots",
    noob = "greenhorn|rookie|cub", idiot = "sap|chump|mug|palooka", idiots = "saps|chumps|mugs", leader = "big shot|the man in charge",
    kid = "kid|squirt", man = "fella|guy|joe", woman = "dame|doll|lady",
    good = "not bad|swell|clean|solid", bad = "rotten|crooked|dirty|lousy", big = "big|heavy|king-size", small = "small-time|two-bit|small",
    strong = "tough|hard as nails", weak = "soft|yellow|weak", fast = "fast|quick", quickly = "quick|on the double", slow = "slow as Sunday",
    easy = "easy money|a cakewalk|easy", hard = "a tough nut|hard", funny = "a real laugh|funny", stupid = "dumb|half-baked|thick",
    smart = "sharp|wise|on the ball", crazy = "screwy|off the rails|nuts", scary = "creepy|cold|spooky", tired = "beat|worn down|dog-tired",
    hungry = "hungry enough to eat the menu|hungry", happy = "fine|in a good mood, for once", sad = "blue|low|down", angry = "sore|steamed|hot under the collar",
    rich = "loaded|flush", poor = "broke|tapped out", lucky = "lucky", unlucky = "snakebit|unlucky", dead = "cold|on ice|dead",
    ugly = "ugly as sin|ugly", pretty = "a real looker|pretty", old = "old|beat-up", new = "new|brand-new", cheap = "cheap|two-bit",
    expensive = "steep|pricey", broken = "busted|bent", boring = "dull as dishwater|dull", important = "big|important",
    very = "plenty|real|very", maybe = "maybe|could be", probably = "likely|odds are", definitely = "sure as rain|for sure",
    always = "always", never = "never|not in this life", now = "now", later = "later|some other night", soon = "soon|any minute",
    again = "again|one more time", here = "here|in this joint", there = "there",
    money = "dough|clams|bread|scratch", food = "grub|chow", drink = "drink|stiff drink|bourbon", water = "water|rain",
    weapon = "piece|heater|blade", weapons = "pieces|heaters", armor = "armor|a good coat", gear = "gear|kit", stuff = "stuff|junk|evidence",
    item = "item|piece of evidence", items = "items|evidence", quest = "case|job", quests = "cases|jobs", dungeon = "joint|dive|hole",
    dungeons = "joints|dives", raid = "big job|raid", home = "my office|my place|home", city = "this rotten city|this town|the city",
    fight = "rumble|scrap|fight", fights = "rumbles|scraps", time = "time", night = "night|long night", day = "day|long day", morning = "morning|gray morning",
    tonight = "tonight|this night", today = "today", tomorrow = "tomorrow, if there is one|tomorrow", problem = "trouble|problem|mess",
    idea = "hunch|idea", magic = "magic|hocus-pocus", mount = "ride|car", bag = "satchel|bag", world = "world|rotten world",
    head = "head|noggin", face = "mug|face", game = "game|racket", life = "life", luck = "luck|lady luck",
    kill = "rub out|take down|put away", killed = "rubbed out|took down|iced", killing = "rubbing out|taking down",
    attack = "jump|lean on", help = "help|cover", die = "take the long sleep|die", died = "took the long sleep|bought it",
    wipe = "get rubbed out", wiped = "got rubbed out", find = "find|dig up", found = "found|dug up", look = "look|take a gander",
    see = "see|eyeball", think = "figure|reckon|think", thought = "figured|thought", know = "know", tell = "tell|level with",
    talk = "talk|spill", say = "say", leave = "leave|blow|beat it", left = "left|blew town", wait = "wait|sit tight", stop = "stop|cut it out",
    buy = "buy|pick up", sell = "sell|fence", farm = "work|grind", farming = "working|grinding", pull = "pull", pulled = "pulled",
    lose = "lose|blow", lost = "lost|blew", win = "win|come out on top", won = "won|came out on top",
    hello = "evening|hey pal", bye = "so long|see you around", yes = "yeah|sure", no = "no dice|nope", okay = "sure thing|alright",
    thanks = "thanks, pal|much obliged", sorry = "my mistake|sorry", damn = "damn|blast", wow = "well, I'll be|now that's a twist",
    lol = "heh|ha", ugh = "ugh|figures", honestly = "straight up|honestly", obviously = "plain as day|obviously",
    annoying = "a pain in the neck|annoying", dangerous = "dangerous|hot", ridiculous = "screwy|crazy", finally = "finally|at last",
    almost = "almost|just about", nobody = "nobody|not a soul", ready = "ready", late = "late|too late", scared = "jumpy|scared",
    sick = "sick|green around the gills", group = "outfit|gang", guild = "outfit|syndicate", zone = "part of town|district",
  },
  phrases = {
    ["i think"] = "I had a hunch|something told me|my gut said", ["i don't know"] = "beats me|I didn't have the answers", ["i dunno"] = "beats me",
    ["i'm tired"] = "I'm beat|I'm dog-tired", ["right now"] = "right now, in this rotten city", ["you guys"] = "you mugs|you lot",
    ["oh my god"] = "well, I'll be", ["omg"] = "well, I'll be", ["let's go"] = "let's move|let's hit the street", ["what the hell"] = "what in blazes",
    ["wtf"] = "what in blazes", ["no way"] = "not a chance|no dice", ["for real"] = "on the level", ["shut up"] = "clam up|zip it",
    ["hurry up"] = "step on it", ["come on"] = "come on, pal", ["calm down"] = "easy, pal", ["my bad"] = "my mistake",
    ["no worries"] = "forget about it", ["i need"] = "I need|what I needed was", ["how's it going"] = "how's tricks", ["what's up"] = "what's the word", ["good luck"] = "watch your back", ["be careful"] = "watch your back out there",
    ["i'm hungry"] = "my stomach was growling like a cop car", ["a lot of"] = "a whole lot of", ["kind of"] = "kinda",
    ["that's crazy"] = "that's one for the books", ["over there"] = "across the way", ["oh no"] = "oh, brother",
  },
  interject = "see|pal|in this town|and I'd know",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Pirate: Bloodsail sea dogs. Arr, ye, me, aye.
---------------------------------------------------------------------------
D("pirate", {
  lex = {
    friend = "matey|bucko|shipmate|friend", friends = "mateys|lads|shipmates|hearties", enemy = "scallywag|bilge rat|landlubber", enemies = "scallywags|bilge rats|landlubbers",
    mob = "sea dog|scurvy beast|brute", mobs = "scurvy beasts|brutes|bilge rats", boss = "captain|big fish|kraken", bosses = "captains|big fish",
    noob = "landlubber|greenhand|swabbie", idiot = "bilge rat|scallywag|barnacle-brain", idiots = "bilge rats|scallywags", leader = "captain|skipper",
    kid = "cabin boy|young pup", man = "sea dog|fella", woman = "lass",
    good = "fine|shipshape|grand|good", bad = "foul|scurvy|cursed|rotten", big = "mighty|huge|whale of a", small = "wee|puny|small",
    strong = "hearty|stout|mighty", weak = "lily-livered|feeble|weak", fast = "swift|quick as a squall", quickly = "smartly|quick-like",
    slow = "slow as a barnacle|slow", easy = "smooth sailin'|easy", hard = "rough waters|hard", funny = "funny|a right laugh",
    stupid = "barnacle-brained|daft", smart = "sharp|crafty|cunning", crazy = "mad as a sea dog|crazy", scary = "fearsome|ghostly|scary",
    tired = "weary|done in", hungry = "starvin'|hungry as a shark", happy = "jolly|merry", sad = "glum|blue as the sea", angry = "boilin'|fit to be tied",
    rich = "rich as a king|loaded with doubloons", poor = "broke|without a doubloon", lucky = "lucky", unlucky = "cursed|jinxed",
    dead = "dead|in Davy Jones' locker", ugly = "ugly as a squid|ugly", pretty = "fair|pretty", old = "old|salty", new = "new",
    cheap = "cheap", expensive = "dear|pricey", broken = "busted|scuttled", boring = "dull as the doldrums|dull", important = "important",
    very = "mighty|right|very", maybe = "maybe|mayhap", probably = "likely|probably", definitely = "aye, for sure|for certain",
    always = "always", never = "never|not on yer life", now = "now|this very tide", soon = "soon|by the next tide", here = "here|aboard",
    money = "doubloons|booty|gold|plunder", food = "grub|hardtack|vittles", drink = "grog|rum", water = "water|brine",
    weapon = "cutlass|blade|pistol", weapons = "cutlasses|blades", armor = "armor|gear", gear = "gear|loot|booty", stuff = "plunder|loot|stuff",
    item = "trinket|bauble", items = "trinkets|baubles|plunder", quest = "voyage|job", quests = "voyages|jobs", dungeon = "cove|hold|cave",
    dungeons = "coves|holds", raid = "raid|grand plunder", home = "ship|home port", city = "port|harbor town", fight = "battle|brawl|scrap",
    fights = "battles|brawls", time = "time", night = "night", morning = "mornin'", tonight = "tonight", today = "today",
    problem = "trouble|squall", idea = "notion|idea", magic = "sea-magic|magic", mount = "ship|steed", bag = "sea chest|bag", bags = "sea chests|bags",
    world = "seven seas|world", head = "noggin|head", game = "game", life = "life|life at sea", luck = "luck|fortune",
    kill = "sink|scuttle|run through", killed = "sunk|scuttled|ran through", killing = "sinkin'|scuttlin'", attack = "board|attack",
    die = "walk the plank|die", died = "walked the plank|went down", wipe = "go down with the ship", wiped = "went down with the ship",
    come = "come|come aboard", leave = "leave|shove off", left = "left|shoved off",
    get = "get|grab", take = "take", buy = "buy|trade for", sell = "sell|trade", find = "find|dig up", found = "found|dug up",
    look = "look", see = "see|spy", farm = "plunder|farm", farming = "plunderin'|farmin'", steal = "plunder",
    hello = "ahoy|avast", bye = "fair winds|farewell", yes = "aye|aye aye", no = "nay|no", okay = "aye|right", thanks = "thank ye|thanks",
    sorry = "beg pardon|sorry", damn = "blimey|shiver me timbers|blast", wow = "blow me down|shiver me timbers", lol = "har har|yo ho ho|har",
    ugh = "argh|ugh", honestly = "on me honor|honestly", obviously = "plain as the sea|obviously", annoying = "pesky|annoying",
    dangerous = "treacherous|dangerous", ridiculous = "barmy|ridiculous", finally = "at last|finally", nobody = "nary a soul|nobody",
    everyone = "all hands|everyone", ready = "ready|ready to sail", group = "ship's company|band", guild = "fleet|guild", zone = "waters|shores",
  },
  phrases = {
    ["you guys"] = "ye scallywags|me hearties", ["let's go"] = "weigh anchor|set sail", ["oh my god"] = "shiver me timbers",
    ["omg"] = "blow me down", ["what the hell"] = "what in Davy Jones' locker", ["wtf"] = "what in the briny deep", ["hurry up"] = "look lively",
    ["come on"] = "come on, ye dogs", ["i think"] = "I reckon", ["no way"] = "not on yer life", ["for real"] = "on me honor",
    ["shut up"] = "belay that", ["calm down"] = "steady as she goes", ["good luck"] = "fair winds to ye",
    ["over there"] = "off the port side|over yonder", ["right now"] = "this very tide", ["i don't know"] = "I don't rightly know",
  },
  interject = "arr|matey|savvy",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Goblin: time is money. Fast, greedy, everything's a deal.
---------------------------------------------------------------------------
D("goblin", {
  lex = {
    friend = "pal|buddy|business partner|friend", friends = "pals|associates|clients|buddies", enemy = "competitor|deadbeat|rival", enemies = "competitors|deadbeats|rivals",
    mob = "freeloader|nuisance|critter", mobs = "freeloaders|nuisances|critters", boss = "big customer|CEO|big shot", bosses = "big customers|big shots",
    noob = "rube|sucker|fresh customer", idiot = "sucker|chump|rube", idiots = "suckers|chumps|rubes", leader = "trade prince|boss",
    kid = "squirt|intern", man = "customer|guy", woman = "customer|lady",
    good = "profitable|top-notch|good", bad = "lousy|bad", big = "big|jumbo|premium-size", small = "pocket-size|small|cheap little",
    strong = "industrial-strength|strong", weak = "bargain-bin|flimsy|weak", fast = "express|fast|turbo", quickly = "pronto|quick-like|on the clock",
    slow = "slow|sluggish", easy = "easy|cheap and easy", hard = "hard|tough", funny = "funny|a riot", stupid = "dumb|cost-ineffective|stupid",
    smart = "savvy|shrewd|smart", crazy = "crazy|nuts|explosive", scary = "scary|bad for the margins", tired = "overworked|tired",
    hungry = "hungry", happy = "happy as a payday|happy", sad = "bankrupt-sad|bummed", angry = "steamed|furious",
    rich = "loaded|rolling in gold|rich", poor = "broke|bankrupt", lucky = "lucky|in the money", unlucky = "unlucky|out of pocket",
    ugly = "ugly|unmarketable", pretty = "shiny|pretty", old = "used|old|vintage", new = "brand new|new", cheap = "cheap|discount|bargain",
    expensive = "premium|pricey|top-shelf", broken = "busted|out of warranty", boring = "boring|unprofitable", important = "high-priority|important",
    very = "super|real|very", maybe = "maybe|depends on the price", probably = "probably", definitely = "guaranteed|definitely",
    always = "always", never = "never|not for any price", now = "now|right now", later = "later|next fiscal quarter", soon = "soon|any second",
    money = "gold|cash|profit|moolah", food = "grub|snacks|food", drink = "fizzy drink|kaja'cola|drink", weapon = "boomstick|blade|weapon",
    weapons = "boomsticks|weapons", armor = "armor|plating", gear = "merchandise|gear|inventory", stuff = "merchandise|stuff",
    item = "product|item", items = "products|goods|items", quest = "contract|job|deal", quests = "contracts|jobs|deals",
    dungeon = "dungeon|investment opportunity", raid = "big score|raid", home = "shop|home", city = "market|city|town",
    fight = "fight|hostile takeover", fights = "fights|hostile takeovers", time = "time|billable time", night = "night|overtime", day = "day",
    problem = "problem|liability", idea = "idea|business plan|scheme", magic = "magic|tech", mount = "rocket|ride|mount",
    bag = "bag|cargo hold", bags = "bags|inventory", world = "market|world", game = "game|racket", life = "life|business",
    kill = "liquidate|blow up|take out", killed = "liquidated|blew up|took out", killing = "liquidating|blowing up", attack = "attack|undercut",
    die = "go bankrupt|die", died = "went bankrupt|died", wipe = "go belly-up", wiped = "went belly-up", help = "help|invest in",
    buy = "buy|invest in", sell = "sell|flip|unload", get = "get", got = "got", give = "give", take = "take",
    make = "make|manufacture", work = "work|clock in", farm = "farm|mine for profit", farming = "farming|turning a profit",
    find = "find|scout", found = "found|scouted", leave = "leave|clock out", left = "left|clocked out", wait = "wait|hold on",
    hello = "hey pal|what's the deal", bye = "pleasure doing business|see ya", yes = "deal|yes|yeah", no = "no deal|no", okay = "deal|alright",
    thanks = "much obliged, pal|thanks", sorry = "sorry|no refunds", damn = "blasted|blast it", wow = "whoa|holy profits",
    lol = "heh heh|ha", ugh = "ugh", honestly = "honestly, and I don't say that for free|honestly", obviously = "obviously",
    annoying = "costly|annoying", dangerous = "explosive|dangerous", ridiculous = "ridiculous|a ripoff", finally = "finally|about time",
    nobody = "nobody|not one paying customer", everyone = "everybody|every customer", ready = "ready|open for business",
    late = "late|overdue", group = "team|company", guild = "cartel|company", zone = "territory|market",
  },
  phrases = {
    ["i think"] = "my gut says|I figure", ["i don't know"] = "no clue, and clues cost extra", ["right now"] = "right now, time is money",
    ["you guys"] = "you clients|you folks", ["let's go"] = "time is money, let's go", ["hurry up"] = "time is money, friend", ["come on"] = "come on, the meter's running",
    ["oh my god"] = "holy profits", ["omg"] = "holy profits", ["what the hell"] = "what in the bilgewater", ["wtf"] = "what in the bilgewater",
    ["no way"] = "not for any price", ["for real"] = "no joke", ["good luck"] = "may your profits be high", ["i need"] = "I need|I gotta get",
    ["a lot of"] = "a whole lot of|a bulk order of", ["for free"] = "for free? Ha", ["shut up"] = "zip it", ["my bad"] = "my mistake, no refunds",
    ["no worries"] = "no charge", ["how's it going"] = "how's business", ["what's up"] = "what's the deal",
  },
  interject = "pal|time is money|heh",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Kobold: candle-loving tunnel critters. Short, third person, worried about candles.
---------------------------------------------------------------------------
D("kobold", {
  lex = {
    friend = "friend|tunnel-friend", friends = "friends|tunnel-friends", enemy = "candle-taker|big meanie", enemies = "candle-takers|big meanies",
    mob = "big thing|scary thing", mobs = "big things|scary things", boss = "big boss|biggest one", bosses = "big bosses",
    noob = "new digger|small one", idiot = "dumb-dumb|rock-head", idiots = "dumb-dumbs|rock-heads", leader = "big boss|chief digger",
    kid = "little digger|pup", man = "big one|tall one", woman = "tall one",
    good = "good|shiny|nice", bad = "bad|dark|no good", big = "big big|very big", small = "small|tiny", strong = "strong|big strong",
    weak = "weak|small weak", fast = "fast|quick quick", quickly = "quick quick|fast fast", slow = "slow|slow slow", easy = "easy|easy easy",
    hard = "hard|very hard", funny = "funny|silly", stupid = "dumb|silly", smart = "smart|clever", crazy = "crazy|wild",
    scary = "scary|very dark", tired = "sleepy|tired", hungry = "hungry|want snack", happy = "happy|glowy", sad = "sad",
    angry = "angry|mad", rich = "rich|many shinies", lucky = "lucky", ugly = "ugly", pretty = "shiny|pretty",
    old = "old|dusty", new = "new|shiny new", expensive = "many shinies|pricey", broken = "broken|smashed",
    very = "very|very very", maybe = "maybe", probably = "maybe yes", always = "always", never = "never ever", now = "now|now now",
    money = "shinies|gold", food = "snacks|food", drink = "drink", weapon = "pokey stick|pick", weapons = "pokey sticks|picks",
    armor = "armor", gear = "shinies|gear", stuff = "stuff|loot", quest = "job|dig", quests = "jobs|digs", dungeon = "tunnel|cave|mine",
    dungeons = "tunnels|caves|mines", home = "tunnel|home", city = "big town", fight = "fight|scuffle", fights = "fights|scuffles",
    night = "dark time|night", day = "bright time|day", morning = "wake time|morning", problem = "problem|trouble", idea = "idea",
    magic = "magic|glowy stuff", mount = "mount", world = "world|big outside", head = "head", life = "life", luck = "luck",
    kill = "smack|whack|poke", killed = "smacked|whacked|poked", killing = "whacking|poking", attack = "smack|poke",
    die = "die|go dark", died = "died|went dark", wipe = "all go dark", wiped = "all went dark", come = "come|scurry over", leave = "leave|scurry away", left = "left|scurried away",
    find = "find|dig up", found = "found|dug up", get = "get|grab", take = "take", farm = "dig|farm", farming = "digging|farming",
    hello = "hello|hi hi", bye = "bye bye|bye", yes = "yes yes|yes", no = "no no|no", okay = "okay okay|okay", thanks = "thank thank|thanks",
    sorry = "sorry sorry|sorry", damn = "bad bad|rats", wow = "ooooh|wow", lol = "hehe|heh heh", ugh = "ugh",
    scared = "scared|very scared", dangerous = "dangerous|very dark", finally = "finally", ready = "ready|ready ready",
    group = "digging party|group", guild = "warren|guild", zone = "tunnel|zone",
  },
  phrases = {
    ["oh my god"] = "oh no oh no", ["omg"] = "oh no oh no", ["what the hell"] = "what the candle", ["wtf"] = "what the candle",
    ["i don't know"] = "Kobold not know", ["i think"] = "Kobold think", ["let's go"] = "go go go", ["hurry up"] = "quick quick",
    ["you guys"] = "you all", ["no way"] = "no no no", ["for real"] = "real real", ["be careful"] = "careful, very dark",
  },
  interject = "yes yes|no take candle|hehe",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Ogre: big, slow, simple. Me, dat, dis.
---------------------------------------------------------------------------
D("ogre", {
  lex = {
    friend = "friend|buddy|little friend", friends = "friends|buddies|little friends", enemy = "puny thing|bad guy", enemies = "puny things|bad guys",
    mob = "puny thing|meat", mobs = "puny things|meats", boss = "big boss|biggest guy", bosses = "big bosses", noob = "tiny guy|baby",
    idiot = "dummy|dum-dum", idiots = "dummies|dum-dums", leader = "boss|big boss", kid = "tiny one|baby", man = "little guy", woman = "little lady",
    good = "good|real good|nice", bad = "bad|not good", big = "big|real big", small = "tiny|puny|small", strong = "strong|real strong",
    weak = "puny|weak", fast = "fast|zoomy", quickly = "fast|quick", slow = "slow|real slow", easy = "easy|real easy", hard = "hard|real hard",
    funny = "funny", stupid = "dumb|stupid", smart = "smart|too smart", crazy = "crazy|bonkers", scary = "scary", tired = "sleepy|tired",
    hungry = "hungry|real hungry", happy = "happy", sad = "sad", angry = "mad|real mad", rich = "rich|lotsa shinies", ugly = "ugly",
    pretty = "pretty|shiny", old = "old", new = "new", expensive = "lotsa gold", broken = "smashed|broke", boring = "boring",
    very = "real|very", maybe = "maybe", probably = "maybe", definitely = "yes yes", always = "always", never = "never",
    money = "gold|shinies", food = "food|meat", drink = "drink|grog", weapon = "club|big club", weapons = "clubs", armor = "armor",
    gear = "stuff|shinies", stuff = "stuff", quest = "job", quests = "jobs", dungeon = "cave|hole", dungeons = "caves|holes",
    home = "cave|home", city = "town", fight = "fight|smash time", fights = "fights", problem = "problem", idea = "idea|big think",
    magic = "magic|fancy magic", mount = "ride", world = "world", head = "head|heads", life = "life", luck = "luck",
    kill = "smash|crush|squish", killed = "smashed|crushed|squished", killing = "smashing|squishing", attack = "smash|bonk",
    die = "die|go splat", died = "died|went splat", wipe = "all go splat", wiped = "all went splat", help = "help",
    think = "think|think real hard", know = "know", eat = "eat|munch", sleep = "sleep|nap",
    hello = "hi|hey", bye = "bye", yes = "yes|yup", no = "no|nope", okay = "okay|ok ok", thanks = "fank you|fanks",
    sorry = "sorry", damn = "dang|grr", wow = "whoa|wow", lol = "hur hur|hah", ugh = "ugh|grr",
    honestly = "for real", finally = "finally", ready = "ready", scared = "scared",
    group = "group|gang", guild = "clan|guild",
  },
  phrases = {
    ["oh my god"] = "whoa whoa", ["omg"] = "whoa", ["what the hell"] = "wut", ["wtf"] = "wut", ["i don't know"] = "me dunno",
    ["let's go"] = "we go now", ["hurry up"] = "go fast", ["you guys"] = "you guys",
  },
  interject = "hur|uh|me fink",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Raid Boss: a villain monologuing at the raid. Grand, cruel, theatrical.
---------------------------------------------------------------------------
D("raidboss", {
  lex = {
    friend = "minion|servant|ally", friends = "minions|servants|lackeys", enemy = "intruder|mortal|insect", enemies = "intruders|mortals|insects",
    mob = "minion|lackey|servant", mobs = "minions|lackeys|servants", boss = "master|overlord", bosses = "masters|overlords",
    noob = "insect|whelp|fool", idiot = "fool|insect|wretch", idiots = "fools|insects|wretches", leader = "commander|master",
    kid = "whelp|child", man = "mortal|creature", woman = "mortal|creature",
    good = "acceptable|worthy|adequate", bad = "pathetic|worthless|feeble", big = "colossal|mighty|vast", small = "insignificant|tiny|pitiful",
    strong = "mighty|unstoppable", weak = "pathetic|feeble|frail", fast = "swift|relentless", quickly = "swiftly|at once",
    slow = "sluggish|pitifully slow", easy = "trivial|effortless", hard = "a worthy trial|hard", funny = "amusing|laughable",
    stupid = "foolish|witless", smart = "cunning|clever, for a mortal", crazy = "mad|deranged", scary = "terrifying|dreadful",
    tired = "weary|drained", hungry = "ravenous|hungry", happy = "pleased|delighted", sad = "despairing|sorrowful", angry = "enraged|wrathful",
    rich = "wealthy|rich", poor = "destitute|poor", lucky = "fortunate|lucky", unlucky = "doomed|cursed", dead = "dead|defeated",
    ugly = "hideous|grotesque", pretty = "fair|pretty", old = "ancient|eternal", new = "new|fresh", expensive = "costly|precious",
    broken = "broken|shattered", boring = "tiresome|boring", important = "vital|of great consequence", very = "utterly|most|very",
    maybe = "perhaps|maybe", probably = "surely|likely", definitely = "certainly|inevitably", always = "always|eternally", never = "never|not in an eternity",
    now = "now", soon = "soon|very soon", later = "later|in time",
    money = "treasure|riches|gold", food = "feast|food", drink = "wine|drink", weapon = "blade|weapon|scythe", weapons = "blades|weapons",
    armor = "armor|plate", gear = "loot|treasure|gear", stuff = "loot|treasure", quest = "errand|pointless quest", quests = "errands|pointless quests",
    dungeon = "domain|lair|sanctum", dungeons = "domains|lairs", raid = "assault|raid", home = "throne|domain|home", city = "kingdom|city",
    fight = "battle|struggle|trial", fights = "battles|struggles", time = "time", night = "night|eternal night", day = "day",
    morning = "morning|dawn", problem = "nuisance|problem", idea = "scheme|plan|idea", magic = "power|magic|dark magic",
    mount = "steed|mount", world = "world|this world", head = "head|skull", life = "life|existence", luck = "luck|fortune", game = "game|little game",
    kill = "destroy|crush|annihilate", killed = "destroyed|crushed|annihilated", killing = "destroying|crushing",
    attack = "strike down|attack", die = "perish|die", died = "perished|died", wipe = "be annihilated", wiped = "were annihilated",
    lose = "lose|fail", lost = "lost|failed", win = "triumph|win", won = "triumphed|won", come = "come|approach", leave = "leave|flee",
    left = "left|fled", want = "want|desire", need = "need|require",
    help = "help|serve", stop = "stop|cease", wait = "wait|be patient", look = "look", see = "see|behold",
    hello = "welcome, mortals|so, you have come", bye = "begone|farewell, insects", yes = "yes|it is so", no = "no|never", okay = "very well|so be it",
    thanks = "your tribute is accepted|thanks", sorry = "an error. It will not happen again|sorry", damn = "curses|damnation",
    wow = "impossible|what is this", lol = "MUAHAHA|ha ha ha|heh heh", ugh = "bah|ugh", honestly = "truly|in all my years",
    obviously = "obviously|of course", annoying = "irksome|tiresome", dangerous = "deadly|perilous", ridiculous = "absurd|laughable",
    finally = "at last|finally", almost = "nearly|almost", nobody = "no one|none", everyone = "all of you|everyone",
    ready = "prepared|ready", scared = "afraid|terrified", group = "pitiful band|group", guild = "army|legion", zone = "domain|realm",
  },
  phrases = {
    ["i need"] = "I DEMAND|I require", ["we need"] = "we REQUIRE", ["you guys"] = "you mortals|you insects", ["let's go"] = "come, face me",
    ["oh my god"] = "IMPOSSIBLE", ["omg"] = "IMPOSSIBLE", ["what the hell"] = "WHAT IS THIS", ["wtf"] = "WHAT IS THIS",
    ["i think"] = "I foresee|I know", ["i don't know"] = "even I cannot see that", ["no way"] = "it cannot be", ["for real"] = "truly",
    ["hurry up"] = "do not keep me waiting", ["come on"] = "come, then", ["good luck"] = "you will need it", ["shut up"] = "SILENCE",
    ["i'm tired"] = "even I grow weary", ["right now"] = "this very moment", ["i will"] = "I shall", ["i'll"] = "I shall",
  },
  interject = "mortals|insects|foolish ones",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Bard: a traveling minstrel. Flowery, merry, half-sung.
---------------------------------------------------------------------------
D("bard", {
  lex = {
    friend = "good friend|fellow traveler|friend", friends = "good friends|fellow travelers|merry company", enemy = "villain|knave|foe",
    enemies = "villains|knaves|foes", mob = "beast|brute", mobs = "beasts|brutes", boss = "great villain|fearsome foe", bosses = "great villains",
    noob = "young squire|wide-eyed traveler", idiot = "fool|jester|buffoon", idiots = "fools|buffoons", leader = "hero|captain",
    kid = "lad|young one", man = "good sir|fellow", woman = "fair lady|good lady",
    good = "splendid|wondrous|fine|merry", bad = "dreadful|woeful|sorry", big = "mighty|grand|great", small = "humble|wee|small",
    strong = "mighty|valiant", weak = "frail|feeble", fast = "swift|fleet-footed", quickly = "swiftly|with haste", slow = "slow",
    easy = "a merry stroll|easy", hard = "a trial for the ages|hard", funny = "comical|merry|droll", stupid = "foolish|witless",
    smart = "wise|learned|clever", crazy = "mad|wild", scary = "fearsome|dread", tired = "weary|footsore", hungry = "famished|hungry",
    happy = "merry|joyful", sad = "woeful|melancholy", angry = "wrathful|cross", rich = "wealthy|rich", poor = "penniless|poor",
    lucky = "fortunate|blessed", unlucky = "ill-starred|unlucky", ugly = "unlovely|ugly", pretty = "fair|lovely|beauteous",
    old = "ancient|old", new = "new|fresh", expensive = "dear|costly", broken = "broken|in tatters", boring = "tedious|dull",
    important = "worthy of song|important", very = "most|ever so|very", maybe = "perchance|perhaps", probably = "likely|in all likelihood",
    definitely = "surely|truly", always = "always", never = "never|nevermore", now = "now|anon", soon = "soon|anon",
    money = "coin|gold|silver", food = "feast|supper|fare", drink = "ale|mead|wine", weapon = "blade|sword", weapons = "blades|swords",
    armor = "armor", gear = "gear|kit", stuff = "gear|loot", quest = "adventure|quest|tale", quests = "adventures|quests|tales",
    dungeon = "dark dungeon", dungeons = "dark dungeons", home = "hearth|home", city = "fair city|town",
    fight = "battle|clash", fights = "battles|clashes", night = "eve|night", morning = "morn|morning", day = "day", tonight = "this eve|tonight",
    problem = "woe|trouble", idea = "notion|fancy", magic = "magic|enchantment", mount = "noble steed|mount", world = "wide world|realm",
    life = "life|tale", luck = "fortune|luck", game = "game|merry game",
    kill = "slay|vanquish|defeat", killed = "slew|vanquished|defeated", killing = "slaying|vanquishing", attack = "charge|assail",
    die = "fall|perish", died = "fell|perished", wipe = "fall as one", wiped = "fell as one", come = "come|come hither", leave = "leave|depart", left = "left|departed", help = "help|aid",
    see = "see|behold", look = "look", say = "say|sing", said = "said|sang", tell = "tell|sing of", talk = "talk|speak",
    hello = "well met|good morrow", bye = "farewell|fare thee well", yes = "aye|yes", no = "nay|no", okay = "very well|agreed",
    thanks = "my thanks|thank thee", sorry = "forgive me|my apologies", damn = "alas|alack", wow = "what wonder|marvelous",
    lol = "ha ha|tra la la|ha", ugh = "alas|ugh", honestly = "truly|in truth", obviously = "plainly|clearly", annoying = "vexing|tiresome",
    dangerous = "perilous|dangerous", ridiculous = "absurd|preposterous", finally = "at long last|finally", nobody = "no soul|nobody",
    everyone = "all|everyone", ready = "ready|ready as a lute", group = "company|merry band", guild = "fellowship|guild",
  },
  phrases = {
    ["you guys"] = "you merry folk|you good folk", ["let's go"] = "onward, to adventure|let us away", ["oh my god"] = "by the stars|heavens",
    ["omg"] = "heavens", ["what the hell"] = "what woe is this", ["wtf"] = "what woe is this", ["i think"] = "methinks",
    ["i don't know"] = "that verse I know not", ["right now"] = "this very moment", ["for real"] = "in truth", ["no way"] = "it cannot be",
    ["hurry up"] = "make haste", ["good luck"] = "may fortune sing for you", ["my bad"] = "forgive me, a sour note",
    ["sounds good"] = "music to my ears", ["over there"] = "yonder", ["let's"] = "let us",
  },
  interject = "tra la la|hey nonny|as the song goes",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Drill Sergeant: yelling. Everything is an order. (The accent itself shouts in caps.)
---------------------------------------------------------------------------
D("sergeant", {
  lex = {
    friend = "soldier|private|recruit", friends = "soldiers|privates|recruits|troops", enemy = "hostile|target", enemies = "hostiles|targets",
    mob = "hostile|target", mobs = "hostiles|targets", boss = "high-value target|big target", bosses = "high-value targets",
    noob = "maggot|fresh recruit|green private", idiot = "maggot|knucklehead|meathead", idiots = "maggots|knuckleheads", leader = "commanding officer|CO",
    kid = "recruit|private", man = "soldier", woman = "soldier",
    good = "squared away|outstanding|good", bad = "sloppy|unacceptable|a disgrace", big = "big|massive", small = "puny|small",
    strong = "tough|strong", weak = "soft|weak", fast = "fast|double time", quickly = "on the double|double time|now",
    slow = "slow as molasses|slow", easy = "a cakewalk|easy", hard = "hard|a real test", funny = "funny|a riot", stupid = "brainless|dumb",
    smart = "sharp|smart", crazy = "crazy|nuts", scary = "scary|hairy", tired = "tired, and I don't care|tired", hungry = "hungry",
    happy = "happy|motivated", sad = "sad|soft", angry = "fired up|furious", lucky = "lucky", ready = "ready|locked and loaded",
    old = "old", new = "new", broken = "busted|broken", boring = "boring", important = "mission-critical|important",
    very = "very|extremely", maybe = "maybe", probably = "probably", definitely = "absolutely", always = "always",
    never = "never", now = "now|right now", soon = "soon|ASAP", later = "later",
    money = "funds|gold", food = "chow|rations", drink = "water|drink", weapon = "weapon|rifle", weapons = "weapons",
    armor = "armor|kit", gear = "gear|kit|equipment", stuff = "gear|equipment", quest = "mission|objective", quests = "missions|objectives",
    dungeon = "objective|target zone", dungeons = "objectives", raid = "operation|raid", home = "barracks|base", city = "base|town",
    fight = "engagement|fight", fights = "engagements|fights", time = "time", night = "night", morning = "zero six hundred|morning",
    problem = "problem|situation", idea = "plan|idea", mount = "transport|mount", bag = "pack|bag", bags = "packs|bags", world = "field|world",
    kill = "neutralize|take out|eliminate", killed = "neutralized|took out|eliminated", killing = "neutralizing|taking out",
    attack = "engage|attack", die = "go down|die", died = "went down|died", wipe = "go down to the last man", wiped = "went down to the last man",
    help = "help", wait = "wait|hold position",
    stop = "halt|stop", leave = "fall back|leave", left = "fell back|left", come = "fall in|come",
    hello = "listen up|ten-hut", bye = "dismissed|move out", yes = "sir yes sir|affirmative", no = "negative|no", okay = "roger|copy that",
    thanks = "appreciated|thanks", sorry = "no excuses|sorry", damn = "damn|blast", wow = "holy smokes|whoa", lol = "HA|HA HA",
    ugh = "ugh", honestly = "frankly|honestly", obviously = "obviously", annoying = "annoying|a pain", dangerous = "hot|dangerous",
    ridiculous = "ridiculous|a disgrace", finally = "finally|about time", nobody = "nobody|not one of you", everyone = "everybody|all of you",
    late = "late|behind schedule", group = "squad|unit", guild = "battalion|company", zone = "sector|zone",
  },
  phrases = {
    ["you guys"] = "you maggots|you sorry lot", ["let's go"] = "move out|move, move, move", ["hurry up"] = "double time", ["come on"] = "move it",
    ["oh my god"] = "holy smokes", ["omg"] = "holy smokes", ["what the hell"] = "what in the blue blazes", ["wtf"] = "what in the blue blazes",
    ["i think"] = "I figure", ["i don't know"] = "intel unknown", ["no way"] = "negative", ["i'm tired"] = "I don't get tired",
    ["good luck"] = "don't need luck, need discipline", ["calm down"] = "at ease", ["right now"] = "right now, not tomorrow",
    ["be careful"] = "eyes open", ["my bad"] = "no excuses", ["shut up"] = "zip it",
  },
  interject = "maggot|soldier|hoo-ah",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- High Epic: a grand old saga (Tolkien style). Lofty, archaic, everything is destiny.
---------------------------------------------------------------------------
D("epic", {
  lex = {
    friend = "companion|good friend|fellow", friends = "companions|fellowship|friends", enemy = "foe|servant of shadow", enemies = "foes|servants of shadow",
    mob = "foul creature|beast", mobs = "foul creatures|beasts", boss = "dark lord|great foe", bosses = "dark lords|great foes",
    noob = "young one|untried soul", idiot = "fool|witless one", idiots = "fools", leader = "lord|captain",
    kid = "young one|child", man = "man|wayfarer", woman = "lady|fair maiden",
    good = "noble|fair|good", bad = "foul|grievous|ill", big = "great|vast|mighty", small = "small|little", strong = "mighty|stout",
    weak = "frail|faint", fast = "swift|fleet", quickly = "swiftly|with all haste", slow = "slow|unhurried", easy = "light|easy",
    hard = "grievous|hard", funny = "merry|droll", stupid = "foolish|witless", smart = "wise|learned", crazy = "mad|fey",
    scary = "dread|fell", tired = "weary|spent", hungry = "hungry|in want of bread", happy = "glad|joyous", sad = "sorrowful|grieved",
    angry = "wroth|wrathful", rich = "rich|laden with treasure", poor = "poor|beggared", lucky = "fortunate|blessed",
    unlucky = "ill-fated|doomed", dead = "slain|dead", ugly = "foul|ill-favored", pretty = "fair|lovely", old = "ancient|of elder days",
    new = "new|fresh", expensive = "dear|costly", broken = "sundered|broken", boring = "dull|wearisome", important = "of great import|weighty",
    very = "most|exceedingly", maybe = "perchance|mayhap", probably = "likely", definitely = "surely|in truth", always = "always",
    never = "never|nevermore", now = "now|at this hour", later = "hereafter|later", soon = "ere long|soon", again = "once more|again",
    here = "here|in this place", there = "there|yonder",
    money = "treasure|gold", food = "bread|provisions", drink = "ale|draught", weapon = "blade|sword", weapons = "blades|swords",
    armor = "mail|armor", gear = "gear|treasure", stuff = "gear|treasure", quest = "quest|errand", quests = "quests|errands",
    dungeon = "deep places", dungeons = "deep places", raid = "great assault|siege", home = "hearth|home",
    city = "city|fair city", fight = "battle|fray", fights = "battles", time = "time", night = "night|dark of night",
    day = "day", morning = "morn|morning", tonight = "this night|tonight", tomorrow = "the morrow|tomorrow", problem = "peril|woe",
    idea = "counsel|thought", magic = "sorcery|magic", mount = "steed|horse", bag = "pack|bag", world = "Middle realms|world",
    head = "head|brow", life = "life|days", luck = "fortune|fate", game = "game|tale",
    kill = "slay|smite|fell", killed = "slew|smote|felled", killing = "slaying|smiting", attack = "assail|attack",
    die = "fall|perish", died = "fell|perished", wipe = "fall to the last", wiped = "fell to the last", come = "come|draw near", leave = "depart|leave", left = "departed|left",
    help = "aid|help", wait = "tarry|wait", stop = "halt|stop", see = "see|behold", look = "look", find = "find|seek out",
    hello = "hail|well met", bye = "farewell|go in peace", yes = "yea|yes", no = "nay|no", okay = "so be it|very well",
    thanks = "I am in your debt|my thanks", sorry = "forgive me|I am sorry", damn = "alas|curse it", wow = "behold|lo",
    lol = "ha|ha ha", ugh = "alas", honestly = "in truth|truly", obviously = "plainly|clearly", annoying = "wearisome|vexing",
    dangerous = "perilous|deadly", ridiculous = "folly|absurd", finally = "at long last|at last", almost = "well nigh|almost",
    nobody = "none|no one", everyone = "all|all who live", ready = "ready|girded for battle", late = "late|too late",
    scared = "afraid|fearful", group = "fellowship|company", guild = "order|fellowship", zone = "lands|realm",
  },
  phrases = {
    ["you guys"] = "you good people|you, my companions", ["let's go"] = "let us set forth|onward", ["let's"] = "let us",
    ["oh my god"] = "by the stars of old", ["omg"] = "by the stars", ["what the hell"] = "what devilry is this", ["wtf"] = "what devilry is this",
    ["i think"] = "I deem|I believe", ["i don't know"] = "that I cannot say", ["right now"] = "in this very hour", ["for real"] = "in truth",
    ["no way"] = "it cannot be", ["hurry up"] = "make haste", ["good luck"] = "may the stars light your path", ["i'm tired"] = "I am weary unto death",
    ["a long time"] = "an age of the world", ["over there"] = "yonder", ["i will"] = "I shall", ["i'll"] = "I shall",
    ["my bad"] = "forgive me, the fault is mine",
  },
  interject = "alas|in truth|as was foretold",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Grimdark (GRRM style): bleak, cynical, everyone dies, winter is always coming.
---------------------------------------------------------------------------
D("grimdark", {
  lex = {
    friend = "sworn sword|friend, for now|ally", friends = "sworn swords|allies, for now", enemy = "turncloak|enemy|traitor", enemies = "turncloaks|enemies|traitors",
    mob = "brute|sellsword", mobs = "brutes|sellswords", boss = "lord|great lord", bosses = "lords|great lords", noob = "green boy|squire",
    idiot = "fool|craven|halfwit", idiots = "fools|cravens", leader = "lord|liege", kid = "boy|green boy", man = "man|sellsword", woman = "lady|woman",
    good = "good|decent", bad = "grim|foul|bloody", big = "great|huge", small = "small|meager", strong = "hard|strong",
    weak = "soft|craven|weak", fast = "quick|fast", quickly = "quickly|before the crows come", slow = "slow", easy = "easy, until it isn't",
    hard = "hard|grim", funny = "funny, in a cruel way|funny", stupid = "foolish|craven", smart = "clever|cunning", crazy = "mad|mad as a king",
    scary = "grim|dreadful", tired = "weary|bone-tired", hungry = "starving|hungry as winter", happy = "content, for now|happy",
    sad = "grim|grieving", angry = "furious|vengeful", rich = "rich|rich as a lord", poor = "poor|poor as a crow", lucky = "lucky, this time",
    unlucky = "doomed|cursed", dead = "dead|crow food", ugly = "ugly|scarred", pretty = "fair|pretty", old = "old|old as the stones",
    new = "new|fresh-forged", expensive = "dear|costly", broken = "broken|shattered", boring = "dull|quiet, too quiet", important = "important",
    very = "very|bloody", maybe = "maybe|perhaps", probably = "likely|probably", definitely = "surely|for certain", always = "always",
    never = "never", now = "now|now, before it's too late", later = "later, if we live", soon = "soon",
    money = "gold dragons|coin|silver", food = "bread and salt|food", drink = "wine|sour wine", weapon = "sword|blade",
    weapons = "steel|swords", armor = "mail|armor", gear = "gear|steel", stuff = "gear|plunder", quest = "task|errand", quests = "tasks",
    dungeon = "keep|dungeon|black cells", dungeons = "keeps|dungeons", raid = "war|siege", home = "keep|hall|home", city = "keep|city",
    fight = "battle|bloodbath|fight", fights = "battles|bloodbaths", time = "time", night = "night|long night", day = "day",
    morning = "morning|grey morning", tonight = "tonight", tomorrow = "tomorrow, if it comes", problem = "trouble|problem",
    idea = "plan|scheme", magic = "sorcery|magic", mount = "horse|destrier", world = "realm|world", head = "head", life = "life",
    luck = "luck", game = "game",
    kill = "kill|slay", killed = "killed|slew", killing = "killing|slaying", attack = "attack|fall upon",
    die = "die", died = "died", wipe = "die, every last one", wiped = "died, every last one", help = "help|aid",
    leave = "leave|ride out", left = "left|rode out", come = "come|ride in",
    hello = "well met|hail", bye = "farewell|until we meet again, if we do", yes = "aye|yes", no = "no|never", okay = "aye|very well",
    thanks = "I'll remember that|thanks", sorry = "forgive me|sorry", damn = "seven hells|gods be good", wow = "gods|seven hells",
    lol = "heh|ha", ugh = "ugh|gods", honestly = "truly|honestly", obviously = "plainly|obviously", annoying = "galling|annoying",
    dangerous = "deadly|dangerous", ridiculous = "folly|ridiculous", finally = "at last|finally", nobody = "no one|nobody",
    everyone = "everyone|every last one", ready = "ready|ready to die", scared = "afraid|craven", group = "company|host",
    guild = "house|banner", zone = "lands|realm",
  },
  phrases = {
    ["you guys"] = "you lot", ["let's go"] = "ride out", ["oh my god"] = "seven hells", ["omg"] = "seven hells",
    ["what the hell"] = "what in the seven hells", ["wtf"] = "what in the seven hells", ["i think"] = "I suspect", ["i don't know"] = "who can say",
    ["good luck"] = "you'll need it|may the gods be kinder to you", ["no way"] = "never", ["for real"] = "truly",
    ["have fun"] = "enjoy it while it lasts", ["right now"] = "now", ["i'm tired"] = "I'm weary to the bone",
    ["sounds good"] = "good enough", ["it's fine"] = "it's fine, for now", ["we'll be fine"] = "we'll probably be fine",
    ["hurry up"] = "quickly, before the crows", ["calm down"] = "steady",
  },
  interject = "if we live|for now|winter is coming",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Wry Narrator (Pratchett style): dry, footnote-ish, gently absurd.
---------------------------------------------------------------------------
D("wry", {
  lex = {
    friend = "friend|associate|acquaintance of long standing", friends = "friends|associates|colleagues", enemy = "opponent|enemy, broadly speaking",
    enemies = "opponents|enemies, technically", mob = "creature|local resident", mobs = "creatures|local residents", boss = "large problem|boss",
    bosses = "large problems|bosses", noob = "beginner|newcomer", idiot = "idiot, in the technical sense|fool", idiots = "idiots|fools",
    leader = "leader|person in charge, allegedly", kid = "young person|kid", man = "fellow|chap", woman = "woman|lady",
    good = "good|surprisingly good|not bad at all", bad = "bad|less than ideal|regrettable", big = "big|rather large", small = "small|modest",
    strong = "strong|robust", weak = "weak|fragile", fast = "fast|brisk", quickly = "quickly|briskly", slow = "slow|unhurried", easy = "easy|simple enough",
    hard = "hard|tricky", funny = "funny|amusing", stupid = "stupid|ill-advised", smart = "clever|smart", crazy = "mad|unhinged",
    scary = "alarming|scary", tired = "tired|worn out", hungry = "peckish|hungry", happy = "pleased|happy", sad = "glum|sad",
    angry = "cross|annoyed", rich = "comfortably off|rich", poor = "short of funds|broke", lucky = "lucky|fortunate", unlucky = "unfortunate|unlucky",
    dead = "dead|no longer alive", ugly = "unlovely|ugly", pretty = "pretty|handsome", old = "old", new = "new|brand new",
    expensive = "expensive|eye-watering", broken = "broken|no longer working", boring = "dull|uneventful", important = "important|significant",
    very = "very|quite", maybe = "possibly|maybe", probably = "probably|in all likelihood", definitely = "almost certainly|definitely",
    always = "always|invariably", never = "never|at no point",
    money = "money|coin", food = "food|a meal", drink = "a drink|refreshment", weapon = "sharp object|weapon", weapons = "sharp objects|weapons",
    armor = "armor", gear = "gear|equipment", stuff = "stuff|kit", quest = "errand|quest", quests = "errands|quests",
    dungeon = "dungeon|damp hole", dungeons = "dungeons", home = "home", city = "city|town", fight = "fight|disagreement", fights = "fights|disagreements",
    problem = "problem|complication", idea = "idea|notion", magic = "magic", mount = "mount", world = "world", life = "life", luck = "luck",
    kill = "kill|dispatch", killed = "killed|dispatched", killing = "killing|dispatching", attack = "attack|have a go at",
    die = "die|stop living", died = "died|stopped living", wipe = "all die at once", wiped = "all died at once",
    hello = "hello|ah, hello", bye = "goodbye|cheerio", yes = "yes|indeed", no = "no|not really", okay = "right|okay",
    thanks = "thanks|much obliged", sorry = "sorry|apologies", damn = "drat|bother", wow = "well|goodness", lol = "ha|heh",
    ugh = "ugh|oh dear", honestly = "honestly|to be fair", obviously = "obviously|naturally", annoying = "irritating|annoying",
    dangerous = "dangerous|unwise", ridiculous = "ridiculous|absurd", finally = "finally|eventually", almost = "almost|very nearly",
    nobody = "nobody|no one in particular", everyone = "everyone|everybody, more or less", ready = "ready|more or less ready",
    late = "late|behind schedule", scared = "nervous|scared",
  },
  phrases = {
    ["i think"] = "I suspect|it seems to me", ["i don't know"] = "no one really knows", ["you guys"] = "you lot",
    ["oh my god"] = "good grief", ["omg"] = "good grief", ["what the hell"] = "what on earth", ["wtf"] = "what on earth",
    ["a lot"] = "a great deal", ["for real"] = "genuinely", ["no way"] = "surely not", ["i'm tired"] = "I am, it must be said, tired",
    ["let's go"] = "off we go, then", ["right now"] = "now, more or less", ["of course"] = "naturally", ["good luck"] = "best of luck, really",
    ["we'll be fine"] = "we'll probably be fine", ["it's fine"] = "it's fine, technically", ["sounds good"] = "that seems reasonable",
  },
  interject = "probably|as it happens|naturally",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Wizard: a pompous old wizard. Arcane, grand, a bit forgetful.
---------------------------------------------------------------------------
D("wizard", {
  lex = {
    friend = "apprentice|young friend|companion", friends = "apprentices|companions", enemy = "foe|dark sorcerer", enemies = "foes|dark sorcerers",
    mob = "creature|beast", mobs = "creatures|beasts", boss = "archfiend|great evil", bosses = "archfiends|great evils",
    noob = "apprentice|novice", idiot = "dunderhead|fool", idiots = "dunderheads|fools", leader = "archmage|master",
    kid = "young one|apprentice", man = "fellow|good sir", woman = "good lady|madam",
    good = "splendid|most excellent|good", bad = "dreadful|most foul|bad", big = "enormous|colossal", small = "minuscule|small",
    strong = "potent|mighty", weak = "feeble|frail", fast = "swift|quick as a spell", quickly = "posthaste|swiftly", slow = "sluggish|slow",
    easy = "elementary|simple", hard = "most vexing|hard", funny = "droll|amusing", stupid = "foolish|addled", smart = "learned|wise",
    crazy = "mad|unhinged", scary = "dreadful|ominous", tired = "weary|in need of a nap", hungry = "peckish|famished", happy = "delighted|pleased",
    sad = "melancholy|sad", angry = "incensed|cross", rich = "wealthy|rich", lucky = "fortunate", unlucky = "ill-starred|unlucky",
    old = "ancient|venerable", new = "novel|new", expensive = "dear|costly", broken = "broken|disenchanted", boring = "tedious|dull",
    important = "of grave importance|important", very = "most|exceedingly", maybe = "perhaps|possibly", probably = "very likely|probably",
    definitely = "most certainly|definitely", always = "always|forever", never = "never",
    money = "gold|coin", food = "victuals|food", drink = "potion|tea|drink", weapon = "staff|wand", weapons = "staves|wands",
    armor = "robes|armor", gear = "artifacts|gear", stuff = "stuff|kit", item = "artifact|item", items = "artifacts|items",
    quest = "quest|undertaking", quests = "quests|undertakings", dungeon = "dungeon|forbidden vault", dungeons = "dungeons|forbidden vaults",
    home = "tower|home", city = "city", fight = "duel|battle", fights = "duels|battles", night = "night|witching hour", morning = "morning",
    problem = "conundrum|problem", idea = "theory|idea", magic = "the arcane|magic", mount = "steed", bag = "satchel|bag",
    world = "realm|world", head = "head|mind", life = "life", luck = "fortune|luck",
    kill = "vanquish|disintegrate|smite", killed = "vanquished|disintegrated|smote", killing = "vanquishing|smiting", attack = "hex|attack",
    die = "perish|expire", died = "perished|expired", wipe = "perish together", wiped = "perished together", forget = "forget",
    forgot = "forgot|quite forgot", remember = "recall|remember", think = "think|deduce", know = "know|divine",
    hello = "greetings|ah, hello", bye = "farewell|until next time", yes = "indeed|yes", no = "no|certainly not", okay = "very well|indeed",
    thanks = "my gratitude|thanks", sorry = "my apologies|sorry", damn = "blast|confound it", wow = "by my beard|great heavens",
    lol = "ho ho|ha", ugh = "harrumph|ugh", honestly = "truly|honestly", obviously = "obviously|elementary", annoying = "vexing|irksome",
    dangerous = "perilous|dangerous", ridiculous = "preposterous|absurd", finally = "at last|finally", nobody = "no one",
    ready = "prepared|ready", scared = "apprehensive|scared", group = "circle|party", guild = "order|guild", zone = "realm|region",
  },
  phrases = {
    ["you guys"] = "you apprentices|you, my friends", ["let's go"] = "come along, apprentices", ["oh my god"] = "by my beard", ["omg"] = "by my beard",
    ["what the hell"] = "what sorcery is this", ["wtf"] = "what sorcery is this", ["i think"] = "I surmise|I believe", ["i don't know"] = "I have quite forgotten",
    ["i forgot"] = "it has slipped my mind", ["for real"] = "truly", ["no way"] = "preposterous", ["hurry up"] = "posthaste, posthaste",
    ["good luck"] = "may your spells hold true", ["right now"] = "at once", ["my bad"] = "a minor miscast", ["i'm tired"] = "I require a nap",
  },
  interject = "hmm|ahem|where was I",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Old Prospector: a grizzled miner. Folksy, gold-crazy.
---------------------------------------------------------------------------
D("prospector", {
  lex = {
    friend = "partner|pardner|friend", friends = "partners|fellers|folks", enemy = "claim jumper|varmint", enemies = "claim jumpers|varmints",
    mob = "varmint|critter", mobs = "varmints|critters", boss = "big varmint|big ol' critter", bosses = "big varmints", noob = "greenhorn|tenderfoot",
    idiot = "fool|numbskull|dang fool", idiots = "fools|numbskulls", leader = "foreman|boss", kid = "young'un|whippersnapper",
    man = "feller|fella", woman = "gal|lady",
    good = "fine|mighty fine|good", bad = "bad|plumb awful|rotten", big = "big|whoppin'", small = "tiny|puny", strong = "stout|strong",
    weak = "puny|weak", fast = "quick|fast", quickly = "quick-like|pronto", slow = "slow as a mule|slow", easy = "easy as pie|easy",
    hard = "hard as bedrock|hard", funny = "funny|a hoot", stupid = "dumb as a rock|dumb", smart = "smart|sharp", crazy = "plumb crazy|loco",
    scary = "spooky|scary", tired = "tuckered out|plumb tired", hungry = "hungry|starvin'", happy = "tickled|happy", sad = "sad|down in the mouth",
    angry = "riled up|mad", rich = "rich|struck it rich", poor = "busted flat|broke", lucky = "lucky", unlucky = "unlucky|snakebit",
    old = "old|dusty", new = "new|shiny", expensive = "pricey|dear", broken = "busted|broke", boring = "dull|boring",
    very = "mighty|plumb|very", maybe = "maybe|mebbe", probably = "likely|prob'ly", definitely = "sure as shootin'|for sure",
    always = "always", never = "never|nary once", now = "now|right now",
    money = "gold|nuggets|dust", food = "grub|beans", drink = "drink|whiskey", weapon = "pickaxe|shooter", weapons = "pickaxes",
    armor = "armor", gear = "gear|tools", stuff = "stuff|ore", item = "nugget|item", items = "nuggets|items", quest = "job|claim",
    quests = "jobs|claims", dungeon = "mine|shaft|cave", dungeons = "mines|shafts", home = "cabin|claim", city = "town|boomtown",
    fight = "scrap|fight", fights = "scraps|fights", night = "night", morning = "mornin'", problem = "trouble|problem",
    idea = "notion|idea", magic = "magic|hoodoo", mount = "mule|mount", bag = "sack|bag", world = "world|frontier",
    kill = "whup|take down", killed = "whupped|took down", killing = "whuppin'", attack = "whack|attack",
    die = "kick the bucket|die", died = "kicked the bucket|died", farm = "dig|mine", farming = "diggin'|minin'",
    find = "find", found = "found", get = "get|git", hello = "howdy|hey there", bye = "so long|be seein' ya", yes = "yep|sure enough", no = "nope|nah", okay = "alrighty|okay",
    thanks = "much obliged|thanks", sorry = "beg pardon|sorry", damn = "dagnabbit|consarn it|tarnation", wow = "well I'll be|eureka",
    lol = "heh heh|hee hee", ugh = "dagnabbit", honestly = "honest to goodness|honestly", annoying = "pesky|ornery",
    dangerous = "dangerous|risky", ridiculous = "plumb ridiculous", finally = "finally|at long last", ready = "ready|rarin' to go",
    group = "outfit|bunch", guild = "outfit|company", zone = "territory|country",
  },
  phrases = {
    ["you guys"] = "you fellers|you folks", ["let's go"] = "let's git goin'", ["oh my god"] = "well I'll be", ["omg"] = "tarnation",
    ["what the hell"] = "what in tarnation", ["wtf"] = "what in tarnation", ["i think"] = "I reckon", ["i don't know"] = "dunno, partner",
    ["no way"] = "no sirree", ["for real"] = "honest to goodness", ["hurry up"] = "git a move on", ["a lot"] = "a heap", ["a lot of"] = "a heap of", ["good luck"] = "may you strike it rich",
    ["right now"] = "right quick", ["over there"] = "yonder",
  },
  interject = "by gum|yessir|heh",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Caveman: ugg. Short words, no small words.
---------------------------------------------------------------------------
D("caveman", {
  lex = {
    friend = "friend|tribe friend", friends = "tribe|friends", enemy = "bad one|other tribe", enemies = "bad ones|other tribe",
    mob = "beast|big beast", mobs = "beasts", boss = "big beast|biggest beast", bosses = "big beasts", noob = "baby|small one",
    idiot = "rock head|dumb one", idiots = "rock heads", leader = "chief|big one", kid = "small one|baby", man = "man|big man", woman = "woman",
    good = "good|good good", bad = "bad|bad bad", big = "big|big big", small = "small|tiny", strong = "strong|strong like mammoth",
    weak = "weak|weak like baby", fast = "fast|fast like wind", quickly = "fast|now", slow = "slow|slow like rock", easy = "easy|easy easy",
    hard = "hard|hard like rock", funny = "funny", stupid = "dumb", smart = "smart|big brain", crazy = "crazy", scary = "scary|bad bad",
    tired = "tired|want sleep", hungry = "hungry|want meat", happy = "happy", sad = "sad", angry = "angry|mad",
    rich = "many shiny", poor = "no shiny", old = "old", new = "new", broken = "broke", very = "very|big", maybe = "maybe",
    always = "always", never = "never", now = "now", later = "later|after sun", soon = "soon",
    money = "shiny rocks|shiny", food = "meat|food", drink = "water|drink", weapon = "club|rock", weapons = "clubs|rocks", armor = "skins|armor",
    gear = "stuff|shiny", stuff = "stuff", quest = "job|hunt", quests = "hunts", dungeon = "cave|dark cave", dungeons = "caves",
    home = "cave", city = "big cave|village", fight = "fight|bonk time", fights = "fights", night = "dark time", day = "sun time",
    morning = "sun come", problem = "problem|bad thing", idea = "think|idea", magic = "fire magic|magic", mount = "big animal",
    world = "world|big land", head = "head", life = "life", luck = "luck",
    kill = "bonk|smash|club", killed = "bonked|smashed|clubbed", killing = "bonking|smashing", attack = "bonk|hit",
    die = "die|go sleep forever", died = "died", wipe = "all die", wiped = "all died", eat = "eat|eat meat", sleep = "sleep",
    hello = "ugg|hello", bye = "bye|ugg", yes = "yes|ugg yes", no = "no|ugg no", okay = "ok|ugg", thanks = "good|thank",
    sorry = "sorry", damn = "ugh|grr", wow = "ooh|whoa", lol = "hah|ha ha", ugh = "ugh",
    group = "tribe|hunt group", guild = "tribe", zone = "land",
  },
  phrases = {
    ["oh my god"] = "ooh ooh", ["omg"] = "ooh",
    ["what the hell"] = "what", ["wtf"] = "what", ["i don't know"] = "Ugg no know", ["i think"] = "Ugg think", ["let's go"] = "go go",
    ["hurry up"] = "go fast", ["you guys"] = "tribe",
  },
  interject = "ugg|grunt",
  ic = { 0, 0.1, 0.2 },
})

---------------------------------------------------------------------------
-- Robot: precise machine speech. (The accent itself shouts in caps.)
---------------------------------------------------------------------------
D("robot", {
  lex = {
    friend = "ally unit|friendly unit|human", friends = "ally units|friendly units|humans", enemy = "hostile unit|threat", enemies = "hostile units|threats",
    mob = "hostile unit|target", mobs = "hostile units|targets", boss = "primary target|priority threat", bosses = "primary targets",
    noob = "untrained unit|new unit", idiot = "faulty unit|malfunctioning human", idiots = "faulty units", leader = "command unit|leader",
    kid = "small human|junior unit", man = "human|male unit", woman = "human|female unit",
    good = "optimal|satisfactory", bad = "suboptimal|unacceptable", big = "large|oversized", small = "small|undersized",
    strong = "high-output|strong", weak = "low-output|weak", fast = "high-speed|fast", quickly = "at maximum speed|quickly",
    slow = "low-speed|slow", easy = "low difficulty|easy", hard = "high difficulty|hard", funny = "humorous|funny",
    stupid = "illogical|stupid", smart = "logical|efficient", crazy = "irrational|erratic", scary = "threatening|alarming",
    tired = "low on power|tired", hungry = "low on fuel|hungry", happy = "content|happy", sad = "sad|in low spirits",
    angry = "agitated|angry", rich = "high in currency|rich", lucky = "statistically fortunate|lucky", dead = "offline|terminated",
    old = "outdated|old", new = "new|recently installed", expensive = "high-cost|expensive", broken = "malfunctioning|broken",
    boring = "low-stimulation|boring", important = "high-priority|important", very = "highly|very", maybe = "probability fifty percent|maybe",
    probably = "probably|with high probability", definitely = "confirmed|definitely", always = "always", never = "never",
    now = "now|immediately",
    money = "currency|credits", food = "fuel|food", drink = "drink|beverage", weapon = "weapon|armament", weapons = "weapons|armaments",
    armor = "plating|armor", gear = "hardware|gear", stuff = "data|equipment", item = "object|item", items = "objects|items",
    quest = "task|directive", quests = "tasks|directives", dungeon = "hostile facility|dungeon", dungeons = "hostile facilities",
    home = "charging station|base", city = "population center|city", fight = "combat|engagement", fights = "combat engagements",
    time = "time", night = "night cycle", day = "day cycle", morning = "start of day cycle", problem = "error|problem",
    idea = "hypothesis|idea", magic = "unexplained energy|magic", mount = "transport unit|mount", bag = "storage unit|bag",
    bags = "storage units|bags", world = "world|planet", head = "head|processor", life = "existence|life", luck = "probability|luck",
    kill = "terminate|delete|neutralize", killed = "terminated|deleted|neutralized", killing = "terminating|deleting",
    attack = "engage|attack", die = "shut down|power off", died = "shut down|powered off", wipe = "fully shut down",
    wiped = "fully shut down", think = "compute|calculate", thought = "computed|calculated", know = "know",
    understand = "process|understand", remember = "recall|retrieve", forget = "delete|forget", see = "scan|see", look = "look",
    help = "assist|help", wait = "pause|wait", stop = "halt|stop", sleep = "enter sleep mode|sleep", eat = "refuel|eat",
    hello = "greetings|hello human", bye = "goodbye|powering down", yes = "affirmative|yes", no = "negative|no", okay = "acknowledged|okay",
    thanks = "gratitude logged|thank you", sorry = "apology issued|sorry", damn = "error|system fault", wow = "unexpected|does not compute",
    lol = "ha ha ha|laughter.exe", ugh = "error|sigh", honestly = "factually|honestly", obviously = "logically|obviously",
    annoying = "irritating|inefficient", dangerous = "high-risk|dangerous", ridiculous = "illogical|absurd", finally = "finally|at last",
    nobody = "zero units|nobody", everyone = "all units|everyone", ready = "ready|online", late = "behind schedule|late",
    scared = "alarmed|scared", group = "unit cluster|group", guild = "network|guild", zone = "sector|zone",
  },
  phrases = {
    ["you guys"] = "you humans|you units", ["let's go"] = "initiating movement", ["oh my god"] = "does not compute", ["omg"] = "does not compute",
    ["what the hell"] = "error. what", ["wtf"] = "error. what", ["i think"] = "my calculations show", ["i don't know"] = "insufficient data",
    ["i'm tired"] = "battery low", ["i'm hungry"] = "fuel low", ["no way"] = "impossible", ["for real"] = "confirmed",
    ["hurry up"] = "increase speed", ["good luck"] = "may your odds be favorable", ["brb"] = "rebooting", ["my bad"] = "user error",
  },
  interject = "beep|boop|processing",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Medieval Peasant: a muddy, humble serf. Folksy and lowly.
---------------------------------------------------------------------------
D("peasant", {
  lex = {
    friend = "neighbor|good fellow|friend", friends = "neighbors|good folk", enemy = "brigand|ruffian", enemies = "brigands|ruffians",
    mob = "beastie|wild thing", mobs = "beasties|wild things", boss = "lordship|great beast", bosses = "lordships", noob = "simple lad|new hand",
    idiot = "turnip-head|dolt", idiots = "turnip-heads|dolts", leader = "lord|master", kid = "wee one|lad", man = "fella|good man",
    woman = "goodwife|lass",
    good = "good|right good|fine", bad = "bad|wretched|awful", big = "big|great big", small = "wee|small", strong = "strong as an ox|strong",
    weak = "weak|poorly", fast = "quick|fast", quickly = "quick-like|right quick", slow = "slow|slow as mud", easy = "easy|simple",
    hard = "hard|backbreaking", funny = "funny|a right laugh", stupid = "daft|dim", smart = "clever|learned", crazy = "mad|touched",
    scary = "fearsome|scary", tired = "worn to the bone|tired", hungry = "starving|hungry", happy = "happy|glad", sad = "woeful|sad",
    angry = "cross|angry", rich = "rich as a lord|rich", poor = "poor|poor as dirt", lucky = "blessed|lucky", ugly = "ugly|muddy",
    pretty = "fair|pretty", old = "old|worn", new = "new", expensive = "dear|costly", broken = "broke|busted",
    very = "right|very", maybe = "maybe|happen", probably = "likely|probably", always = "always", never = "never",
    money = "coppers|coin|pennies", food = "turnips|pottage|bread", drink = "small beer|ale", weapon = "pitchfork|hoe", weapons = "pitchforks|hoes",
    armor = "armor|rags", gear = "gear|tools", stuff = "stuff|kit", quest = "chore|errand", quests = "chores|errands",
    dungeon = "dungeon|lord's cellar", dungeons = "dungeons", home = "hovel|cottage", city = "town|market town", fight = "fight|scrap",
    fights = "fights|scraps", night = "night", morning = "dawn|cockcrow", day = "day|working day", problem = "trouble|woe",
    idea = "notion|idea", magic = "witchery|magic", mount = "mule|donkey", bag = "sack|bag", bags = "sacks|bags", world = "world|shire",
    kill = "whack|thump|kill", killed = "whacked|thumped|killed", killing = "whacking|thumping", attack = "whack|attack",
    die = "die|catch the plague", died = "died|caught the plague", farm = "toil|farm", farming = "toiling|farming", work = "toil|work",
    hello = "good day|ow do", bye = "fare ye well|bye", yes = "aye|yes", no = "nay|no", okay = "right|aye", thanks = "ta|thank ye",
    sorry = "beg pardon|sorry", damn = "blimey|blast", wow = "cor|blimey", lol = "heh|haha", ugh = "ugh|oof",
    honestly = "honest|honestly", annoying = "a right pain|annoying", dangerous = "dangerous|perilous", finally = "at last|finally",
    group = "lot|band", guild = "village|guild", zone = "shire|parts",
  },
  phrases = {
    ["you guys"] = "you lot|you good folk", ["let's go"] = "best be off", ["oh my god"] = "cor blimey", ["omg"] = "cor",
    ["what the hell"] = "what in the muck", ["wtf"] = "what in the muck", ["i think"] = "I reckon", ["i don't know"] = "couldn't say",
    ["no way"] = "never in all my days", ["for real"] = "honest", ["hurry up"] = "look sharp", ["a lot"] = "a fair bit",
    ["good luck"] = "may the harvest be kind", ["i'm tired"] = "me back's killin' me",
  },
  interject = "begging your pardon|cor|mind you",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Cowboy: frontier drawl. Easygoing, folksy.
---------------------------------------------------------------------------
D("cowboy", {
  lex = {
    friend = "partner|pardner|buddy", friends = "partners|folks|cowpokes", enemy = "outlaw|varmint|bandit", enemies = "outlaws|varmints|bandits",
    mob = "varmint|critter", mobs = "varmints|critters", boss = "big outlaw|head honcho", bosses = "big outlaws|head honchos",
    noob = "greenhorn|tenderfoot", idiot = "fool|varmint|knucklehead", idiots = "fools|knuckleheads", leader = "trail boss|sheriff",
    kid = "kid|young'un", man = "feller|cowpoke", woman = "ma'am|gal",
    good = "fine|mighty fine|good", bad = "bad|rotten|lowdown", big = "big", small = "little|puny", strong = "tough|strong as an ox",
    weak = "weak|soft", fast = "quick|fast as a jackrabbit", quickly = "quick-like|pronto", slow = "slow as molasses|slow", easy = "easy as pie|easy",
    hard = "tough|hard", funny = "funny|a hoot", stupid = "dumb|dumber than a post", smart = "smart|sharp", crazy = "loco|crazy",
    scary = "spooky|scary", tired = "tuckered out|tired", hungry = "hungry as a bear|hungry", happy = "happy as a clam|happy", sad = "blue|sad",
    angry = "ornery|mad", rich = "rich|flush", poor = "broke|busted", lucky = "lucky", unlucky = "unlucky|snakebit",
    old = "old|weathered", new = "new|shiny", expensive = "pricey|steep", broken = "busted|broke", boring = "boring|dull",
    very = "mighty|real|very", maybe = "maybe|reckon so", probably = "prob'ly|likely", definitely = "sure as shootin'|definitely",
    always = "always", never = "never|not once", now = "now|right now",
    money = "dollars|gold|silver", food = "grub|beans|chow", drink = "whiskey|sarsaparilla", weapon = "six-shooter|iron|blade",
    weapons = "six-shooters|irons", armor = "chaps|armor", gear = "gear|saddlebags", stuff = "stuff|gear", quest = "job|errand", quests = "jobs",
    dungeon = "canyon|hideout", dungeons = "canyons|hideouts", home = "ranch|homestead", city = "town|frontier town", fight = "showdown|shootout",
    fights = "showdowns|shootouts", night = "night|nightfall", morning = "sunup|mornin'", day = "day", problem = "trouble|ruckus",
    idea = "notion|idea", magic = "magic|hoodoo", mount = "horse|steed", bag = "saddlebag|bag", bags = "saddlebags|bags",
    world = "frontier|world", life = "life", luck = "luck",
    kill = "take down|plug|kill", killed = "took down|plugged|killed", killing = "takin' down", attack = "draw on|attack",
    die = "bite the dust|die", died = "bit the dust|died", wipe = "all bite the dust", wiped = "all bit the dust", leave = "ride out|leave", left = "rode out|left", come = "come|ride in",
    hello = "howdy|hey there", bye = "so long|happy trails", yes = "yep|yessir", no = "nope|nah", okay = "alright|sure thing",
    thanks = "much obliged|thanks", sorry = "beg pardon|sorry", damn = "dang|dadgum", wow = "well I'll be|yeehaw", lol = "haw haw|heh",
    ugh = "dang", honestly = "honest|honestly", annoying = "ornery|pesky", dangerous = "dangerous|risky", ridiculous = "plumb ridiculous",
    finally = "finally|at last", nobody = "nobody|nary a soul", everyone = "everybody|y'all", ready = "ready|saddled up",
    group = "posse|outfit", guild = "posse|outfit", zone = "territory|county",
  },
  phrases = {
    ["you guys"] = "y'all|you folks", ["let's go"] = "let's ride|saddle up", ["oh my god"] = "well I'll be", ["omg"] = "well I'll be",
    ["what the hell"] = "what in tarnation", ["wtf"] = "what in tarnation", ["i think"] = "I reckon", ["i don't know"] = "couldn't tell ya",
    ["no way"] = "no sir", ["for real"] = "honest to goodness",
    ["hurry up"] = "giddy up", ["good luck"] = "happy trails", ["a lot"] = "a whole heap", ["a lot of"] = "a whole heap of",
    ["over there"] = "yonder", ["calm down"] = "whoa there",
  },
  interject = "partner|yeehaw|reckon",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Surfer: totally chill. Gnarly, rad, dude.
---------------------------------------------------------------------------
D("surfer", {
  lex = {
    friend = "dude|brah|bro|homie", friends = "dudes|brahs|bros", enemy = "kook|bummer dude", enemies = "kooks|bummer dudes",
    mob = "gnarly dude|creature", mobs = "gnarly dudes|creatures", boss = "big kahuna|monster wave", bosses = "big kahunas",
    noob = "grommet|kook", idiot = "kook|barney", idiots = "kooks|barneys", leader = "head dude|big kahuna", kid = "grommet|little dude",
    man = "dude|brah", woman = "dudette|lady",
    good = "rad|gnarly|epic|tubular", bad = "bogus|harsh|a bummer", big = "huge|massive", small = "tiny|small", strong = "buff|strong",
    weak = "weak|soft", fast = "fast|ripping", quickly = "quick|super fast", slow = "slow", easy = "chill|easy", hard = "gnarly|tough",
    funny = "hilarious|funny", stupid = "bogus|dumb", smart = "smart|brainy", crazy = "wild|bonkers|insane", scary = "sketchy|gnarly",
    tired = "wiped out|beat", hungry = "starving|hungry", happy = "stoked|amped", sad = "bummed|bummed out", angry = "heated|mad",
    rich = "loaded|rich", poor = "broke", lucky = "lucky|blessed", old = "old|vintage", new = "fresh|new", expensive = "spendy|pricey",
    broken = "busted|trashed", boring = "lame|boring", important = "a big deal|important", very = "totally|super|mega", maybe = "maybe",
    probably = "probably", definitely = "totally|for sure", always = "always", never = "never",
    money = "cash|gold", food = "grub|grinds", drink = "smoothie|drink", weapon = "board|weapon", weapons = "boards|weapons",
    armor = "wetsuit|armor", gear = "gear", stuff = "stuff", quest = "mission|thing", quests = "missions|things", dungeon = "dungeon|gnarly cave",
    dungeons = "dungeons|gnarly caves", home = "beach shack|crib", city = "town", fight = "throwdown|fight", fights = "throwdowns|fights",
    night = "night", morning = "dawn patrol|morning", problem = "bummer|problem", idea = "idea|vibe", magic = "magic|cosmic energy",
    mount = "ride|board", world = "world|ocean", life = "life|vibe", luck = "luck|good vibes",
    kill = "shred|wreck|smoke", killed = "shredded|wrecked|smoked", killing = "shredding|wrecking", attack = "drop in on|attack",
    die = "wipe out|die", died = "wiped out|died", wipe = "totally wipe out", wiped = "totally wiped out", leave = "bounce|leave", left = "bounced|left", hello = "hey dude|aloha|sup", bye = "later dude|catch you on the flip side",
    yes = "yeah dude|totally", no = "nah dude|nah", okay = "right on|cool", thanks = "thanks, brah|mahalo", sorry = "my bad, dude|sorry",
    damn = "bummer|whoa", wow = "whoa|duuude", lol = "haha|hehe", ugh = "bummer", honestly = "honestly, dude|for real",
    annoying = "harsh|annoying", dangerous = "sketchy|dangerous", ridiculous = "bonkers|ridiculous", finally = "finally",
    ready = "ready|amped", scared = "sketched out|scared", group = "squad|posse", guild = "tribe|guild", zone = "beach|zone",
  },
  phrases = {
    ["you guys"] = "you dudes|you brahs", ["let's go"] = "let's paddle out|let's ride", ["oh my god"] = "duuude", ["omg"] = "whoa dude",
    ["what the hell"] = "what the heck, dude", ["wtf"] = "dude, what", ["i think"] = "I'm feeling like", ["i don't know"] = "no clue, dude",
    ["calm down"] = "chill, brah", ["no way"] = "no way, dude", ["for real"] = "for real, dude", ["hurry up"] = "let's go, dude",
    ["good luck"] = "good vibes, brah", ["my bad"] = "my bad, dude", ["no worries"] = "no worries, brah", ["i'm tired"] = "I'm totally wiped",
  },
  interject = "dude|brah|like",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Butler: an impeccable, very proper manservant.
---------------------------------------------------------------------------
D("butler", {
  lex = {
    friend = "esteemed friend|esteemed guest", friends = "esteemed guests|honored company", enemy = "unwelcome guest|intruder", enemies = "unwelcome guests|intruders",
    mob = "unwanted guest|creature", mobs = "unwanted guests|creatures", boss = "most unwelcome guest|master of the house", bosses = "unwelcome guests",
    noob = "new arrival|young master", idiot = "dunce|ill-mannered fellow", idiots = "dunces", leader = "master|head of household",
    kid = "young master|child", man = "gentleman|sir", woman = "lady|madam",
    good = "most satisfactory|excellent|fine", bad = "most regrettable|unfortunate|poor", big = "considerable|large", small = "modest|small",
    strong = "formidable|strong", weak = "delicate|weak", fast = "prompt|swift", quickly = "promptly|at once", slow = "unhurried|slow",
    easy = "no trouble at all|simple", hard = "rather trying|difficult", funny = "most amusing|droll", stupid = "unwise|ill-advised",
    smart = "astute|clever", crazy = "rather unhinged|mad", scary = "unsettling|alarming", tired = "fatigued|weary", hungry = "in want of luncheon|hungry",
    happy = "delighted|pleased", sad = "downcast|sad", angry = "displeased|cross", rich = "well-to-do|wealthy", poor = "of modest means|poor",
    lucky = "fortunate", unlucky = "unfortunate", dead = "deceased|dead", ugly = "unsightly|plain", pretty = "handsome|lovely",
    old = "venerable|old", new = "new", expensive = "costly|dear", broken = "in need of repair|broken", boring = "tedious|dull",
    important = "of some importance|important", very = "most|quite", maybe = "perhaps|possibly", probably = "very likely|probably",
    definitely = "certainly|most assuredly", always = "always", never = "never",
    money = "funds|gold", food = "luncheon|supper|refreshments", drink = "tea|refreshment", weapon = "implement|weapon", weapons = "implements|weapons",
    armor = "attire|armor", gear = "attire|effects", stuff = "luggage|baggage", item = "article|item", items = "articles|items",
    quest = "errand|matter", quests = "errands|matters", dungeon = "cellar", dungeons = "cellars", home = "manor|residence",
    city = "city|town", fight = "altercation|fight", fights = "altercations", night = "evening|night", morning = "morning",
    problem = "difficulty|matter", idea = "suggestion|idea", magic = "magic", mount = "carriage|mount", bag = "valise|bag", bags = "luggage|bags",
    world = "world", head = "head", life = "life", luck = "fortune|luck",
    kill = "see off|deal with|dispatch", killed = "saw off|dealt with|dispatched", killing = "dealing with|dispatching", attack = "confront|attack",
    die = "pass on|perish", died = "passed on|perished", wipe = "all perish", wiped = "all perished", help = "assist|help",
    get = "get", give = "give", leave = "take one's leave|leave", left = "took my leave|left", wait = "wait|stand by",
    hello = "good evening|welcome", bye = "good day|very good", yes = "very good|yes", no = "I'm afraid not|no", okay = "very good|certainly",
    thanks = "much obliged|thank you", sorry = "my sincere apologies|sorry", damn = "dear me|oh dear", wow = "goodness|my word",
    lol = "ahem|quite", ugh = "dear me", honestly = "if I may say so|honestly", obviously = "naturally|of course",
    annoying = "trying|tiresome", dangerous = "hazardous|dangerous", ridiculous = "absurd|unseemly", finally = "at last|finally",
    nobody = "no one|nobody", everyone = "all present|everyone", ready = "prepared|ready", late = "behind schedule|late",
    scared = "uneasy|afraid", group = "party|company", guild = "household|guild", zone = "grounds|area",
  },
  phrases = {
    ["you guys"] = "you fine people|you good people", ["let's go"] = "shall we proceed", ["oh my god"] = "good heavens", ["omg"] = "my word",
    ["what the hell"] = "what on earth", ["wtf"] = "I beg your pardon", ["i think"] = "if I may suggest|I believe", ["i don't know"] = "I couldn't say",
    ["i need"] = "I require", ["i want"] = "I should like", ["no way"] = "I hardly think so", ["for real"] = "quite so",
    ["hurry up"] = "with some haste, if you please", ["good luck"] = "best of fortune", ["shut up"] = "if you would kindly be quiet",
    ["my bad"] = "my apologies", ["no worries"] = "think nothing of it", ["can you"] = "might you", ["could you"] = "would you be so kind as to",
  },
  interject = "if I may|sir|madam",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Grumpy Old Man: complains about everything. Back in my day.
---------------------------------------------------------------------------
D("grumpy", {
  lex = {
    friend = "sonny|buddy|friend", friends = "kids|you people|friends", enemy = "hooligan|punk", enemies = "hooligans|punks",
    mob = "pest|nuisance", mobs = "pests|nuisances", boss = "big lummox|boss", bosses = "big lummoxes", noob = "whippersnapper|young pup",
    idiot = "nincompoop|knucklehead|lummox", idiots = "nincompoops|knuckleheads", leader = "the one in charge, apparently|leader",
    kid = "whippersnapper|kid", man = "fella|guy", woman = "lady|missus",
    good = "fine|good", bad = "terrible|lousy|garbage", big = "big|too big", small = "puny|too small", strong = "strong",
    weak = "weak|soft", fast = "too fast|fast", quickly = "quick, quick|fast", slow = "slow|slow as my knees", easy = "easy, too easy|easy",
    hard = "hard|too hard", funny = "funny, I suppose|funny", stupid = "dumb|stupid", smart = "smart|too smart for your own good",
    crazy = "crazy|nuts", scary = "scary", tired = "tired|always tired", hungry = "hungry", happy = "happy, for once|fine",
    sad = "miserable|sad", angry = "cranky|mad", rich = "rich|spoiled", poor = "broke", lucky = "lucky|spoiled", old = "old|older than you",
    new = "newfangled|new", cheap = "cheap|cheaply made", expensive = "highway robbery|expensive", broken = "busted|broken",
    boring = "boring|a snooze", important = "important", very = "very|darn", maybe = "maybe", probably = "probably", definitely = "definitely",
    always = "always", never = "never", now = "now", soon = "soon, they say",
    money = "money|good money", food = "supper|food", drink = "coffee|drink", weapon = "cane|weapon", weapons = "weapons", armor = "armor",
    gear = "junk|gear", stuff = "junk|stuff", quest = "chore|errand", quests = "chores|errands", dungeon = "dungeon|dank hole",
    home = "porch|home", city = "town", fight = "fight|ruckus", fights = "fights", night = "night", morning = "crack of dawn|morning",
    problem = "problem|racket", idea = "idea|crazy idea", magic = "magic, or whatever", mount = "mount", game = "game|newfangled game",
    world = "world", life = "life", luck = "luck",
    kill = "whack|kill", killed = "whacked|killed", die = "die", died = "died", hello = "yeah, hello|hello", bye = "bye|good riddance",
    yes = "yeah, yeah|yes", no = "no|nope", okay = "fine|okay", thanks = "thanks, I suppose|thanks", sorry = "sorry, sorry|sorry",
    damn = "dagnabbit|consarn it|blast", wow = "huh|well", lol = "hmph|heh", ugh = "ugh|harrumph", honestly = "honestly|frankly",
    obviously = "obviously", annoying = "annoying|infuriating", dangerous = "dangerous", ridiculous = "ridiculous|preposterous",
    finally = "finally|about time", nobody = "nobody", everyone = "everybody", ready = "ready, if I have to", late = "late|always late",
    group = "group|bunch", guild = "guild|club",
  },
  phrases = {
    ["you guys"] = "you kids|you people", ["let's go"] = "fine, let's go", ["oh my god"] = "good grief", ["omg"] = "good grief",
    ["what the hell"] = "what in the Sam Hill", ["wtf"] = "what in the Sam Hill", ["i think"] = "if you ask me", ["i don't know"] = "how should I know",
    ["no way"] = "not on your life", ["hurry up"] = "I'm not getting any younger", ["come on"] = "come on, already",
    ["right now"] = "right now, not next week", ["calm down"] = "keep your shirt on", ["have fun"] = "have fun, I guess",
    ["sounds good"] = "fine, whatever", ["good luck"] = "good luck, you'll need it", ["i'm tired"] = "my back's acting up",
  },
  interject = "hmph|back in my day|kids these days",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Valley Girl: like, totally.
---------------------------------------------------------------------------
D("valley", {
  lex = {
    friend = "bestie|girl|friend", friends = "besties|girls|you guys", enemy = "hater|total creep", enemies = "haters|creeps",
    mob = "creep|thing", mobs = "creeps|things", boss = "big creep|boss", bosses = "big creeps", noob = "newbie|total newbie",
    idiot = "loser|airhead", idiots = "losers|airheads", leader = "queen bee|leader", kid = "kid", man = "guy|dude", woman = "girl|lady",
    good = "amazing|cute|totally good", bad = "gross|so bad|the worst", big = "huge|like, huge", small = "tiny|teeny", strong = "strong|so strong",
    weak = "weak|so weak", fast = "fast|super fast", quickly = "super fast|quick", slow = "slow|so slow", easy = "easy|so easy",
    hard = "hard|literally impossible", funny = "hilarious|so funny", stupid = "dumb|so dumb", smart = "smart|so smart", crazy = "crazy|insane",
    scary = "creepy|so scary", tired = "exhausted|so tired", hungry = "starving|so hungry", happy = "happy|so happy", sad = "sad|devastated",
    angry = "mad|so mad", rich = "rich|loaded", poor = "broke", lucky = "lucky|blessed", ugly = "ugly|gross", pretty = "gorgeous|so cute",
    old = "old|so last season", new = "new|so new", expensive = "pricey|so expensive", broken = "broken|totally broken",
    boring = "boring|so boring", important = "important|a big deal", very = "so|totally|super", maybe = "maybe", probably = "probably",
    definitely = "totally|definitely", always = "always|literally always", never = "never|literally never",
    money = "money|cash", food = "food|snacks", drink = "latte|drink", weapon = "weapon", gear = "outfit|gear", stuff = "stuff",
    item = "thing|item", items = "things|items", quest = "thing|quest", quests = "things|quests", dungeon = "dungeon|gross dungeon",
    home = "house|place", city = "city|mall", fight = "fight|drama", fights = "fights|drama", problem = "problem|drama",
    idea = "idea", magic = "magic", mount = "ride|car", world = "world", life = "life", luck = "luck", game = "game",
    kill = "destroy|totally kill", killed = "destroyed|totally killed", killing = "destroying", die = "die|literally die", died = "died|literally died",
    hello = "hiii|hey girl", bye = "byeee|bye", yes = "yes|totally", no = "no|ew, no", okay = "okay|kk", thanks = "thank you sooo much|thanks",
    sorry = "sorry|sorryyy", damn = "ugh|oh my gosh", wow = "oh my gosh|wow", lol = "lol|hahaha", ugh = "ugh|ew",
    honestly = "literally|honestly", obviously = "obviously|duh", annoying = "so annoying|annoying", dangerous = "sketchy|dangerous",
    ridiculous = "ridiculous|so extra", finally = "finally|finally!", nobody = "nobody", everyone = "everyone|literally everyone",
    ready = "ready", scared = "scared|freaked out", group = "group|squad",
  },
  phrases = {
    ["you guys"] = "you girls|you guys", ["let's go"] = "let's go, girls", ["oh my god"] = "oh my gosh", ["omg"] = "oh my gosh",
    ["what the hell"] = "what even", ["wtf"] = "um, what", ["i think"] = "I feel like", ["i don't know"] = "I don't even know",
    ["no way"] = "no way|shut up", ["for real"] = "for real|literally", ["i'm tired"] = "I'm literally so tired",
    ["that's crazy"] = "that's so crazy", ["good luck"] = "good luck, babe",
  },
  interject = "like|totally|literally",
  ic = { 0, 0.2, 0.35 },
})

---------------------------------------------------------------------------
-- Conspiracy Guy: everything is connected. Wake up.
---------------------------------------------------------------------------
D("conspiracy", {
  lex = {
    friend = "friend|fellow truth-seeker", friends = "friends|truth-seekers", enemy = "agent|plant", enemies = "agents|plants",
    mob = "agent|so-called creature", mobs = "agents|so-called creatures", boss = "puppet master|boss, so they say", bosses = "puppet masters",
    noob = "sheep|newbie", idiot = "sheep|sheeple", idiots = "sheeple|sheep", leader = "puppet|so-called leader", kid = "kid", man = "guy", woman = "lady",
    good = "good, suspiciously|fine|good", bad = "bad|rigged", big = "big|massive", small = "small", strong = "strong", weak = "weak",
    fast = "fast|too fast", quickly = "quickly", slow = "slow|deliberately slow", easy = "easy, too easy|easy", hard = "hard|rigged",
    funny = "funny|suspicious", stupid = "dumb|brainwashed", smart = "smart|awake", crazy = "crazy, they want you to think|crazy",
    scary = "scary", tired = "tired|drained, by design", hungry = "hungry", happy = "happy", sad = "sad", angry = "mad|furious",
    rich = "rich|connected", poor = "broke", lucky = "lucky, supposedly", unlucky = "unlucky, or so they say", dead = "dead, supposedly",
    old = "old", new = "new|brand new, convenient", expensive = "expensive|overpriced on purpose", broken = "broken|sabotaged",
    boring = "boring", important = "important|classified", very = "very|extremely", maybe = "maybe", probably = "probably",
    definitely = "definitely|a hundred percent", always = "always", never = "never",
    money = "gold|money", food = "food|processed food", drink = "drink|raw milk", weapon = "weapon", gear = "gear", stuff = "stuff|evidence",
    item = "item|evidence", items = "items|evidence", quest = "mission|so-called quest", quests = "missions|so-called quests",
    dungeon = "secret base|dungeon", dungeons = "secret bases|dungeons", home = "bunker|home", city = "city", fight = "fight|cover-up",
    problem = "problem|cover-up", idea = "theory|idea", magic = "magic, allegedly|magic", mount = "mount", world = "world|simulation",
    game = "game|simulation", life = "life", luck = "luck, so called",
    kill = "kill|silence", killed = "killed|silenced", die = "die|disappear", died = "died|disappeared", drop = "drop", dropped = "dropped",
    hello = "hey|psst", bye = "bye|stay safe", yes = "yes|exactly", no = "no|that's what they want", okay = "okay|fine", thanks = "thanks",
    sorry = "sorry", damn = "damn|figures", wow = "whoa|I knew it", lol = "lol|ha", ugh = "ugh",
    honestly = "honestly", obviously = "obviously|it's obvious", annoying = "annoying", dangerous = "dangerous",
    ridiculous = "ridiculous", finally = "finally", nobody = "nobody|no one they'll tell you about", everyone = "everyone",
    group = "group|cell", guild = "guild|secret society",
  },
  phrases = {
    ["you guys"] = "you sheep|you guys", ["oh my god"] = "I knew it", ["omg"] = "I knew it", ["what the hell"] = "what are they hiding",
    ["wtf"] = "what are they hiding", ["i think"] = "I'm pretty sure", ["i don't know"] = "nobody knows, and that's the point",
    ["no way"] = "that's what they want you to think", ["for real"] = "for real, look it up", ["think about it"] = "really think about it", ["good luck"] = "stay woke", ["let's go"] = "let's go, quietly",
  },
  interject = "think about it|look it up|wake up",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- Sports Announcer: everything is a big play!
---------------------------------------------------------------------------
D("announcer", {
  lex = {
    friend = "teammate|star player|friend", friends = "teammates|the squad|the team", enemy = "opponent|the other team", enemies = "opponents|the visitors",
    mob = "opponent|challenger", mobs = "opponents|challengers", boss = "heavyweight champion|big boss", bosses = "heavyweights|champions",
    noob = "rookie|first-year player", idiot = "bench warmer|blunder machine", idiots = "bench warmers", leader = "captain|coach",
    kid = "rookie|young star", man = "player|competitor", woman = "player|competitor",
    good = "incredible|sensational|unbelievable", bad = "brutal|disastrous|rough", big = "huge|massive", small = "small", strong = "powerful|dominant",
    weak = "weak|shaky", fast = "lightning fast|blazing", quickly = "in record time|lightning fast", slow = "slow|sluggish",
    easy = "routine|easy", hard = "a nail-biter|tough", funny = "hilarious|funny", stupid = "baffling|questionable", smart = "brilliant|savvy",
    crazy = "unbelievable|insane", scary = "nerve-wracking|scary", tired = "gassed|exhausted", hungry = "hungry for the win|hungry",
    happy = "ecstatic|thrilled", sad = "heartbroken|crushed", angry = "fired up|furious", rich = "loaded|rich", lucky = "lucky|charmed",
    unlucky = "unlucky|snakebit", dead = "down|out of the game", old = "veteran|old", new = "new", expensive = "pricey|top-dollar",
    broken = "busted|broken", boring = "slow|boring", important = "huge|crucial", very = "absolutely|incredibly", maybe = "maybe",
    probably = "likely|probably", definitely = "without a doubt|definitely", always = "always", never = "never",
    now = "now|right now", soon = "any moment now|soon",
    money = "prize money|gold", food = "snacks|hot dogs", drink = "sports drink|drink", weapon = "weapon|blade", gear = "gear|equipment",
    stuff = "stuff|gear", quest = "match|challenge", quests = "matches|challenges", dungeon = "arena|stadium", dungeons = "arenas|stadiums",
    raid = "championship|big game", home = "home field|home", city = "city|stadium", fight = "match|bout|showdown", fights = "matches|bouts",
    time = "time|game time", night = "game night|night", day = "game day|day", problem = "setback|problem", idea = "play|idea|game plan",
    magic = "magic|some kind of magic", mount = "ride|mount", world = "world|league", game = "game|match", life = "career|life", luck = "luck",
    kill = "take down|crush|knock out", killed = "took down|crushed|knocked out", killing = "taking down|crushing", attack = "charge|attack",
    die = "go down|die", died = "went down|died", wipe = "get swept", wiped = "got swept", win = "win|take it home", won = "won|took it home",
    lose = "lose|drop the game", lost = "lost|dropped the game", pull = "pull", pulled = "pulled",
    hello = "welcome back, folks|hello", bye = "that's all for tonight, folks|bye", yes = "yes|YES", no = "no|NO", okay = "okay|alright",
    thanks = "a class act|thanks", sorry = "a rough play|sorry", damn = "oh, that hurts|ouch", wow = "WOW|unbelievable|what a play",
    lol = "ha|hahaha", ugh = "ouch|oof", honestly = "honestly", obviously = "clearly|obviously", annoying = "frustrating|annoying",
    dangerous = "risky|dangerous", ridiculous = "ridiculous|unreal", finally = "finally|at long last", almost = "almost|so close",
    nobody = "nobody|not a soul", everyone = "everybody|the whole crowd", ready = "ready|warmed up", late = "late|in overtime",
    scared = "nervous|rattled", group = "team|squad", guild = "franchise|club", zone = "field|zone",
  },
  phrases = {
    ["you guys"] = "you folks|you fine people", ["let's go"] = "here we go, folks|and they're off", ["oh my god"] = "OH MY", ["omg"] = "OH MY",
    ["what the hell"] = "what a turn of events", ["wtf"] = "what just happened", ["i think"] = "if you ask me, folks|I think",
    ["i don't know"] = "nobody saw that coming", ["no way"] = "NO WAY", ["for real"] = "believe it", ["good luck"] = "may the best team win",
    ["right now"] = "right now, live", ["oh no"] = "OH NO", },
  interject = "folks|what a play|unbelievable",
  ic = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- (1.1.0) everyday verbs for the subtler voices, so ordinary lines carry them too
---------------------------------------------------------------------------
D("wry", { lex = {
  want = "want", need = "need", find = "locate|find", try = "have a go|try", trying = "having a go|trying",
  sleep = "have a kip|sleep", buy = "purchase|buy", sell = "flog|sell", stop = "leave off|stop", work = "the day job|work",
  look = "have a look|look", know = "know, roughly|know", think = "suspect|think", understand = "follow|understand", forget = "forget",
  play = "play|potter about", laugh = "laugh", hope = "rather hope|hope", kinda = "somewhat|sort of", sucks = "is regrettable|sucks",
  wait = "hang on|wait", leave = "wander off|leave", left = "wandered off|left", helped = "helped, unexpectedly|helped",
} })
D("grumpy", { lex = {
  want = "want|need, apparently", need = "need", find = "find|dig up", try = "try|give it a go", trying = "trying",
  sleep = "nap|sleep", buy = "buy|pay through the nose for", sell = "sell|get rid of", stop = "stop|quit it", work = "work|the grind",
  look = "look|squint", know = "know|figure", think = "think|reckon", understand = "get|understand", forget = "forget",
  play = "play|fool around", hope = "hope", sucks = "stinks|sucks", wait = "wait|hold your horses", leave = "leave|get going",
  kinda = "sorta|kinda", annoyed = "cranky|annoyed", hours = "hours", minutes = "minutes",
} })
D("conspiracy", { lex = {
  want = "want", need = "need", find = "find|uncover", found = "found|uncovered",
  try = "try|attempt", sleep = "sleep|go off-grid", buy = "buy|fund them with", sell = "sell|get rid of", stop = "stop",
  work = "work|the system", look = "look", know = "know", think = "think|suspect", understand = "understand|see the pattern",
  forget = "forget", hope = "hope", sucks = "sucks|is suspicious", wait = "wait|hold on, listen", drop = "drop|vanish",
  dropped = "dropped|vanished", server = "server|surveillance server", servers = "servers|surveillance servers", disconnected = "disconnected",
} })
D("wizard", { lex = {
  want = "desire|want", need = "require|need", find = "seek out|find", try = "attempt|try", trying = "attempting|trying",
  sleep = "slumber|nap", buy = "procure|buy", sell = "sell|part with", stop = "cease|stop", work = "study|work",
  look = "look", know = "know", think = "ponder|think", understand = "comprehend|understand", hope = "hope|trust",
  play = "dabble|play", wait = "wait|be patient", leave = "depart|leave", left = "departed|left", make = "conjure|make",
  sucks = "is most vexing|sucks", kinda = "somewhat|rather",
} })

---------------------------------------------------------------------------
-- (1.2.0) the same grammar checks for the groups that trip up a sentence, on every accent (the eight races too)
---------------------------------------------------------------------------
local TRICKY = { fight = 1, fights = 1, kill = 1, killed = 1, killing = 1, zone = 1, big = 1, small = 1, good = 1, bad = 1,
  night = 1, day = 1, morning = 1, leave = 1, left = 1, time = 1, scared = 1, old = 1, new = 1, gear = 1, stuff = 1, armor = 1, weapon = 1, mount = 1 }
for _, d in pairs(ns.ACCENTS) do
  if d.lex then
    for g in pairs(TRICKY) do
      local list = d.lex[g]
      if type(list) == "table" then
        local kept = Clean(g, table.concat(list, "|"))
        if kept then d.lex[g] = Split(kept); if type(d.lex[g]) == "string" then d.lex[g] = { d.lex[g] } end
        else d.lex[g] = nil end
      end
    end
  end
end

---------------------------------------------------------------------------
-- (1.4.1) "horde players", "city guards", "alliance side": these words often sit in front of another word, so their
-- swaps never bring their own "the" (that made "any horde players" into "any the Horde players")
---------------------------------------------------------------------------
local NOTHE = { horde = 1, alliance = 1, city = 1, world = 1, home = 1, magic = 1, work = 1, zone = 1, guild = 1, group = 1, server = 1 }
for _, d in pairs(ns.ACCENTS) do
  for g in pairs(NOTHE) do
    local list = d.lex and d.lex[g]
    if type(list) == "table" then
      local out, seen = {}, {}
      for _, v in ipairs(list) do
        local w = v:gsub("^[Tt][Hh][Ee] ", "")
        -- a place's own name can't follow "the" ("in the Stormwind"), and a plural can't take "is" ("Alliance cousins is")
        local bad = (g == "city" and w:find("^%u")) or w:find("s$") or w:find("^[Oo]ur ") or w:find("^[Mm]y ")
        if not bad and not seen[w:lower()] then seen[w:lower()] = true; out[#out + 1] = w end
      end
      d.lex[g] = #out > 0 and out or nil
    end
  end
end
