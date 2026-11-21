-- Dalorrian's Accents: the first ten unlockable accents (they unlock in this order as you send accented messages).
-- "a|b|c" in say, lex, words and phrases means: pick one of these.
local ADDON, ns = ...
local E = ns.Engine
local random = math.random

local function L(v)
  if type(v) ~= "string" or not v:find("|") then return v end
  local t = {}
  for x in v:gmatch("[^|]+") do t[#t + 1] = x end
  return t
end
local function Add(key, d)
  for _, f in ipairs({ "say", "lex", "words", "phrases", "more" }) do
    if d[f] then for k, v in pairs(d[f]) do d[f][k] = L(v) end end
  end
  for _, f in ipairs({ "openers", "interject" }) do if type(d[f]) == "string" then d[f] = L(d[f]) end end
  if d.lex then for g, v in pairs(d.lex) do if type(v) == "string" then d.lex[g] = { v } end end end
  ns.AddAccent(key, d)
end
local ARTICLES = { the = 1, a = 1, an = 1 }

---------------------------------------------------------------------------
-- 1. Pirate (Bloodsail)
---------------------------------------------------------------------------
Add("pirate", {
  name = "Pirate", group = "fantasy", icon = "Interface\\Icons\\INV_Misc_Bandana_03",
  blurb = "Arr! Bloodsail talk, matey.",
  ranks = { "Deckhand", "Powder Monkey", "Swabbie", "Buccaneer", "First Mate", "Captain", "Admiral", "Dread Pirate" },
  say = {
    greet = "Ahoy!|Ahoy, mateys!|Ahoy there!", bye = "Fair winds!|Fair winds, matey!|I be off, mateys!",
    goodnight = "Off to me hammock!|Time to sleep with the fishes. The livin' kind.", thanks = "Thank ye kindly!|Much obliged, matey!",
    welcome = "Anytime, matey!", sorry = "Shiver me timbers, my mistake!|Beg pardon, matey!", yes = "Aye!|Aye aye!|Aye, matey!",
    no = "Nay!|Nay, matey!", okay = "Aye aye, cap'n!|Aye.", lol = "Yo ho ho!|Har har har!|Arr har har!",
    brb = "Back in a tick, matey!|Hold fast, I'll be back!", back = "I be back, mateys!", ready = "Ready to plunder!|Ready, cap'n!",
    wait = "Avast!|Hold fast!", go = "Charge, ye dogs!|All hands, attack!|Yo ho, let's go!", oom = "Me magic be empty as a rum barrel!",
    heal = "Heal me, I be sinkin'!|Patch me up, matey!", gg = "Fine sailin', mateys!|A fine haul!", nice = "Arr, fine work!|Shiver me timbers!",
    wow = "Shiver me timbers!|Blow me down!", dead = "I be feedin' the fishes.|Davy Jones got me.", help = "Help, I be sinkin'!|All hands, help!",
    run = "Abandon ship!|Retreat, ye dogs!", idk = "Blimey if I know!", congrats = "Arr, a fine treasure!",
  },
  phrases = { ["you are"] = "ye be", ["you're"] = "ye be", ["i am"] = "I be", ["i'm"] = "I be", ["we are"] = "we be", ["we're"] = "we be",
    ["it is"] = "it be", ["it's"] = "it be", ["that is"] = "that be", ["that's"] = "that be", ["is it"] = "be it", ["are you"] = "be ye",
    ["oh my god"] = "shiver me timbers|blow me down", ["omg"] = "shiver me timbers", ["i think"] = "I reckon|me gut says", ["i don't know"] = "blimey if I know", ["let's go"] = "weigh anchor!|let's set sail" },
  words = { my = "me", you = "ye", your = "yer", yourself = "yerself", hello = "ahoy", yes = "aye", no = "nay", stop = "avast",
    is = "be", are = "be", the = "th'", of = "o'", ["and"] = "an'", to = "t'" },
  lex = {
    friend = "matey|bucko", friends = "mateys|me hearties|ye scallywags", enemy = "scallywag|bilge rat|landlubber",
    enemies = "scallywags|bilge rats", mob = "sea dog|beastie", mobs = "sea dogs|beasties", boss = "cap'n|big fish",
    noob = "landlubber|swabbie", idiot = "bilge rat|scallywag|landlubber", leader = "cap'n", money = "doubloons|booty|pieces of eight|gold",
    food = "grub|hardtack|salted fish", drink = "drink|swig", gear = "booty|loot|plunder", stuff = "stuff",
    quest = "voyage|errand", dungeon = "hold|cove", home = "ship", city = "port", good = "fine|grand|shipshape",
    bad = "rotten|bilge-worthy|cursed", big = "mighty|massive", kill = "sink|plunder|scuttle", killed = "sunk|scuttled|plundered",
    look = "lookie", wow = "blimey|arr", lol = "har har|yo ho ho", very = "mighty|right", run = "run",
  },
  rules = { { "ing$", "in'", min = 2, chance = 0.8 } },
  openers = "Arr,|Ahoy,|Yo ho,", interject = "arr|matey",
})

---------------------------------------------------------------------------
-- 2. Goblin (everything is a deal)
---------------------------------------------------------------------------
Add("goblin", {
  name = "Goblin", group = "monster", icon = "Interface\\Icons\\INV_Misc_Coin_02",
  blurb = "Time is money, friend!",
  ranks = { "Grunt Laborer", "Peddler", "Hustler", "Trader", "Tycoon", "Trade Prince Hopeful", "Baron", "Trade Prince" },
  say = {
    greet = "Time is money, friend!|Hey, hey, customer!|Whaddaya need, pal?", bye = "Pleasure doin' business!|Gotta run, deals don't close themselves!",
    thanks = "Thanks, I'll put it on yer tab!|Much obliged, pal!", welcome = "No charge. This time.", sorry = "My bad. Want a refund? No refunds.",
    yes = "Deal!|You got it, pal!|It's a deal!", no = "No deal!|Not for that price!", okay = "Deal.|Fine, fine, deal.",
    lol = "Heh heh heh!|Hah! Good one, pal!", brb = "Back in a sec, gotta check my investments.", back = "I'm back! Miss me? That'll cost ya.",
    ready = "Ready! Time is money!", wait = "Hold up, hold up!", go = "Go go go! Time is money!", oom = "Outta mana, and mana ain't cheap!",
    heal = "Heal me! I'll pay ya later!", gg = "Profitable run, friends!|Good business, everybody!", nice = "Profitable!|Now we're talkin'!",
    wow = "Holy moolah!|Whoa, that's gotta be worth somethin'!", dead = "I'm dead. Somebody check my pockets. Actually, don't.",
    help = "Help! I'll make it worth yer while!", run = "Run! Cut our losses!", idk = "Dunno, but I'll sell ya a guess.",
    congrats = "Ding! Your value just went up!",
  },
  phrases = { ["i think"] = "the way I see it|between you and me", ["i don't know"] = "dunno|beats me, pal", ["a lot"] = "a whole lotta|a fortune",
    ["for free"] = "for free, if ya can believe it", ["let's go"] = "time is money, let's go|move it, time is money", ["you guys"] = "you folks|customers",
    ["oh my god"] = "holy moolah", ["omg"] = "holy moolah", ["no way"] = "no deal" },
  lex = {
    friend = "pal|buddy|friend|customer", friends = "pals|folks|customers", boss = "big boss|big spender|top dog", noob = "sucker|new customer",
    idiot = "chump|sucker|knucklehead", money = "gold|moolah|cash|profit", good = "profitable|lucrative|top quality",
    bad = "lousy|bad for business|a rip-off", expensive = "highway robbery|a rip-off|pricey", cheap = "a bargain|a steal",
    big = "huge|massive|primo", kill = "liquidate|take out|bankrupt", killed = "liquidated|bankrupted|took out", gear = "merchandise|goods|loot",
    stuff = "stuff", quest = "job|gig|contract", help = "help", very = "real|super", wow = "holy moolah|whoa", lol = "heh heh|hah",
  },
  openers = "Listen, pal,|Okay okay,", interject = "pal|friend",
})

---------------------------------------------------------------------------
-- 3. Murloc (no words, only murloc)
---------------------------------------------------------------------------
local MRGL = { "mrgl", "mrrgl", "mrglgl", "glrgl", "mrrrggk", "mrgle", "rwlrwlrwl", "mmmrrglll", "grrml", "mrlgl" }
Add("murloc", {
  name = "Murloc", group = "monster", icon = "Interface\\Icons\\INV_Misc_Fish_14",
  blurb = "Mrglglglgl! (Nobody will understand you. That's the point.)",
  ranks = { "Tadpole", "Mudfin", "Snapper", "Tidehunter", "Oracle", "Warrior of the Tide", "Murloc King", "Mrgl Mrgl" },
  -- every word becomes murloc; item links and names stay so the line is still useful
  whole = function(text, strength)
    local s, saved = E.Protect(text, nil)
    local n = 0
    s = s:gsub("[%a']+", function(w)
      n = n + 1
      local m = MRGL[random(#MRGL)]
      if strength >= 3 and random() < 0.08 then m = "aaaughibbrgubugbugrguburgle" end
      if w:upper() == w and #w > 1 then m = m:upper() elseif w:find("^%u") then m = m:gsub("^%l", string.upper) end
      return m
    end)
    if strength >= 2 and not s:find("[!%?]$") then s = s:gsub("%.?$", "!") end
    return E.Restore(s, saved)
  end,
})

---------------------------------------------------------------------------
-- 4. Kobold (you no take candle!)
---------------------------------------------------------------------------
Add("kobold", {
  name = "Kobold", group = "monster", icon = "Interface\\Icons\\INV_Misc_Candle_01",
  blurb = "You no take candle!",
  ranks = { "Tunneler", "Digger", "Candle Holder", "Miner", "Geomancer", "Taskmaster", "Kobold Chieftain", "Keeper of the Candle" },
  say = {
    greet = "Hello! You no take candle!|Hi hi!|Kobold say hi!", bye = "Kobold go now. Keep candle safe!|Bye bye!",
    thanks = "Thank thank!|Kobold thank you! No take candle though.", yes = "Yes yes!|Yes! Yes yes!", no = "No no no!|NO!",
    okay = "Okay okay!|Yes yes, okay.", lol = "Hehehe!|Kobold laugh! Hehe!", brb = "Kobold be back! Watch candle!",
    back = "Kobold back! Candle still here?", ready = "Ready ready!", wait = "Wait wait!|Stop! Kobold not ready!",
    go = "Go go go!|Charge! Kobold brave!", heal = "Heal kobold! Hurt hurt!", dead = "Kobold dead. Candle out.",
    wow = "Ooooh! Shiny!|Whoa whoa!", help = "Help kobold!|Help help!", run = "RUN! Run run run!", gg = "Kobold win! Yes yes!",
    nice = "Shiny!|Good good!", idk = "Kobold not know.",
  },
  phrases = { ["i am"] = "kobold", ["i'm"] = "kobold", ["i don't"] = "kobold no", ["i can't"] = "kobold no can", ["i will"] = "kobold will",
    ["i'll"] = "kobold will", ["i have"] = "kobold have", ["i want"] = "kobold want", ["i need"] = "kobold need", ["i think"] = "kobold think" },
  words = { i = "kobold", my = "kobold's", me = "kobold", mine = "kobold's", ["don't"] = "no", ["can't"] = "no can", ["isn't"] = "not",
    light = "candle", torch = "candle", lamp = "candle", fire = "candle" },
  lex = {
    good = "good good|shiny|nice", bad = "bad bad|no good", money = "shinies|gold", gear = "shinies|stuff", big = "big big|huge",
    small = "tiny|little", friend = "friend|kobold friend", friends = "friends|kobolds", dungeon = "tunnel|mine|cave", dungeons = "tunnels|mines",
    kill = "stab|poke|kill", killed = "stabbed|poked|killed", scary = "scary scary", very = "very very",
  },
  drop = ARTICLES,
  interject = "yes yes|candle",
})

---------------------------------------------------------------------------
-- 5. Ogre (big, slow, two heads)
---------------------------------------------------------------------------
Add("ogre", {
  name = "Ogre", group = "monster", icon = "Interface\\Icons\\Spell_Nature_Strength",
  blurb = "Me smash! No, ME smash!",
  ranks = { "Runt", "Brute", "Basher", "Thug", "Mauler", "Warlord", "Gronn Friend", "Ogre Lord" },
  say = {
    greet = "Hello! Me say hello!|Me see you. Hello.", bye = "Me go now. Bye.|Ogre go home.", thanks = "Fank you!|Me fank you.",
    yes = "Yah!|Yah yah!|Me say yes.", no = "No!|Me say no!", okay = "Okay. Me do.|Yah, okay.", lol = "Hur hur hur!|HURR!",
    ready = "Me ready to smash!", go = "SMASH!|Ogre smash!|Me go smash!", wait = "Wait! Me tink.", dead = "Me dead. Ow.",
    heal = "Me hurt! Fix me!", gg = "Good smash!|We smash good!", nice = "Good smash!|Me like!", wow = "Whoa!|Me head hurt!",
    idk = "Me no know. Other head know?", help = "Help ogre!", hungry = "Me hungry! Me eat!",
  },
  phrases = { ["i am"] = "me", ["i'm"] = "me", ["i don't"] = "me no", ["i can't"] = "me no can", ["i will"] = "me gonna", ["i'll"] = "me gonna",
    ["i think"] = "me tink", ["you are"] = "you", ["you're"] = "you", ["it is"] = "it", ["it's"] = "it", ["i have"] = "me got" },
  words = { i = "me", my = "me", ["don't"] = "no", ["can't"] = "no can", think = "tink", thing = "ting", things = "tings", this = "dis",
    that = "dat", the = "da", thanks = "fanks", ["isn't"] = "not" },
  lex = { kill = "smash|crush|bonk", killed = "smashed|crushed|bonked", attack = "smash|bonk", good = "good|strong|tasty", bad = "bad|stinky",
    big = "big|biggest", small = "puny|tiny", food = "meat|food|grub", idiot = "dummy|dumb dumb", smart = "smart|clever",
    weapon = "club|big stick", friend = "friend|buddy", friends = "friends|buddies", very = "very|super" },
  drop = { a = 1, an = 1, is = 1, are = 1, am = 1 },
})

---------------------------------------------------------------------------
-- 6. Raid Boss (dramatic villain monologue)
---------------------------------------------------------------------------
Add("raidboss", {
  name = "Raid Boss", group = "fantasy", icon = "Interface\\Icons\\Spell_Shadow_DeathScream", slash = "raidboss",
  blurb = "FOOLS! You DARE talk to me?!",
  ranks = { "Trash Mob", "Elite", "Miniboss", "Dungeon Boss", "Raid Boss", "Final Boss", "World Ender", "Unkillable" },
  say = {
    greet = "So. More mortals come to face me.|You DARE approach me?|Welcome... to your DOOM.",
    bye = "Flee, then! I will be waiting.|This is not over, mortals!", thanks = "Your gratitude amuses me.|I accept your tribute.",
    sorry = "I do not apologize. But... very well.", yes = "YES!|It shall be so!", no = "NO!|NEVER!|I think NOT!",
    okay = "It shall be done.|So be it.", lol = "MWAHAHAHA!|HAHAHAHA!|Ha... ha... HAHAHA!", ready = "I have waited ages for this.",
    wait = "SILENCE! Not yet!", go = "Face me!|Come, then! FACE ME!|Bring them to me!", dead = "Impossible... I... was... invincible...",
    heal = "My power... fades... HEAL ME!", gg = "You have... defeated me... for now.", nice = "Impressive... for a mortal.",
    wow = "IMPOSSIBLE!|What is this?!", help = "Minions! To me!", run = "Run, little mortals! RUN!", congrats = "You grow stronger. It will not save you.",
  },
  phrases = { ["i will"] = "I SHALL", ["i'll"] = "I SHALL", ["you guys"] = "mortals|fools|insects", ["let's go"] = "FACE ME|come, then",
    ["i think"] = "I foresee|I KNOW", ["i don't know"] = "even I cannot see that", ["oh my god"] = "IMPOSSIBLE", ["omg"] = "IMPOSSIBLE",
    ["come on"] = "COME, mortals", ["i'm going to"] = "I SHALL", ["we need"] = "I DEMAND", ["i need"] = "I DEMAND" },
  lex = {
    friend = "mortal|minion|insect", friends = "mortals|fools|insects|minions", enemy = "challenger|mortal", enemies = "challengers|mortals",
    boss = "champion|foe", good = "worthy|impressive|adequate", bad = "pathetic|feeble|worthless", big = "mighty|colossal",
    small = "insignificant|puny", kill = "obliterate|annihilate|crush", killed = "obliterated|annihilated|crushed", die = "perish",
    died = "perished", noob = "insect|whelp", idiot = "fool|insect|wretch", gear = "trinkets|trophies", money = "tribute|gold",
    help = "serve", healer = "pathetic healer|healer", tank = "tank", very = "utterly|truly",
  },
  openers = "FOOLS!|Mortals!|SILENCE!",
  -- the big words land in capitals
  post = function(s, strength)
    if strength < 2 then return s end
    local BIG = { dare = 1, doom = 1, death = 1, dead = 1, die = 1, perish = 1, perished = 1, kill = 1, killed = 1, obliterate = 1, obliterated = 1,
      annihilate = 1, annihilated = 1, crush = 1, crushed = 1, mortals = 1, fools = 1, insects = 1, never = 1, power = 1, all = 1, now = 1,
      everything = 1, nothing = 1, pathetic = 1, worthless = 1, feeble = 1, mine = 1, fail = 1, fall = 1, burn = 1, suffer = 1 }
    s = s:gsub("%f[%a](%a+)%f[%A]", function(w) if BIG[w:lower()] then return w:upper() end end)
    if strength >= 3 then s = s:gsub("%.$", "!") end
    return s
  end,
})

---------------------------------------------------------------------------
-- 7. Bard (Shakespearean)
---------------------------------------------------------------------------
Add("bard", {
  name = "Bard", group = "fantasy", icon = "Interface\\Icons\\INV_Misc_Book_09",
  blurb = "Prithee, good gentles, list to my verse!",
  ranks = { "Groundling", "Player", "Minstrel", "Troubadour", "Poet", "Playwright", "Laureate", "The Immortal Bard" },
  say = {
    greet = "Well met!|Good morrow!|Good morrow, good gentles!", bye = "Fare thee well!|Adieu, adieu!|Parting is such sweet sorrow.",
    goodnight = "Good night, sweet friends.|To sleep, perchance to dream.", thanks = "I thank thee!|Many thanks, good friend!",
    welcome = "'Tis nothing, good friend.", sorry = "I beg thy pardon!|Forgive me, good friend!", yes = "Aye!|Yea, verily!",
    no = "Nay!|Nay, good friend!", okay = "Verily.|As thou wilt.", lol = "Ha! Thou art a wit!|Most merry!",
    ready = "I am ready, good friends!", wait = "Hold!|Soft, wait!", go = "Once more unto the breach!|Onward, good friends!",
    dead = "Alas, I am slain!|O, I die!", heal = "Prithee, heal me!", gg = "Well fought, good gentles!", nice = "Most excellent!",
    wow = "Zounds!|Forsooth!", idk = "I know not.", help = "Help, ho!|Prithee, aid me!", run = "Fly, fly!",
  },
  phrases = { ["you are"] = "thou art", ["you're"] = "thou art", ["are you"] = "art thou", ["do you"] = "dost thou", ["did you"] = "didst thou",
    ["have you"] = "hast thou", ["you have"] = "thou hast", ["you've"] = "thou hast", ["can you"] = "canst thou", ["will you"] = "wilt thou",
    ["it is"] = "'tis", ["it's"] = "'tis", ["it was"] = "'twas", ["i think"] = "methinks", ["please"] = "prithee",
    ["oh my god"] = "zounds|good heavens", ["omg"] = "zounds", ["let's go"] = "once more unto the breach|onward" },
  words = { you = "thee|thou", your = "thy", yours = "thine", yourself = "thyself", does = "doth", has = "hath", yes = "aye",
    no = "nay", before = "ere", often = "oft", nothing = "naught", maybe = "perchance", hello = "well met", okay = "verily" },
  lex = {
    friend = "good friend|good fellow", friends = "good gentles|good friends", enemy = "villain|foe", idiot = "knave|varlet|fool",
    idiots = "knaves|varlets", good = "fair|most excellent|goodly", bad = "foul|wretched|vile", very = "most|passing",
    kill = "slay|smite", killed = "slew|smote", help = "aid", money = "coin|ducats", food = "victuals|food", drink = "drink|sup",
  },
  openers = "Hark!|Forsooth,|Lo,",
})

---------------------------------------------------------------------------
-- 8. Noir Detective
---------------------------------------------------------------------------
Add("noir", {
  name = "Noir Detective", group = "silly", icon = "Interface\\Icons\\Ability_Stealth", slash = "noir",
  blurb = "It was a dark and stormy night. Then the healer went oom.",
  ranks = { "Gumshoe", "Flatfoot", "Shamus", "Private Eye", "Detective", "Inspector", "Hard-Boiled", "The Last Honest Man" },
  say = {
    greet = "Evening.|Evening, pal.|Well, well. Look who walked in.", bye = "I walked out into the rain.|See you around, pal.",
    goodnight = "Another long night. Time to sleep it off.", thanks = "Thanks, pal. I owe you one.|Appreciate it, doll.",
    sorry = "My mistake. Wasn't my first.", yes = "Yeah.|Sure, pal.", no = "No dice.|Not a chance, pal.", okay = "Sure thing.|Fine. Let's do it.",
    lol = "Heh. Funny.|I almost smiled. Almost.", ready = "I was born ready. Born tired, too.", go = "Let's go. This city won't fix itself.",
    dead = "So this is how it ends. Face down in a dungeon.", heal = "I need a medic. And a drink.", gg = "Case closed.|Another case closed.",
    nice = "Not bad, pal.", wow = "Well, I'll be.|Now that's a twist.", idk = "Beats me. Always does.", help = "I could use some help, pal.",
    oom = "Out of mana. Out of luck.",
  },
  phrases = { ["i think"] = "I had a hunch|something told me", ["i don't know"] = "beats me|I didn't have the answers", ["i'm tired"] = "I was tired. Tired of all of it",
    ["right now"] = "right now, in this rotten city", ["you guys"] = "you mugs|you lot", ["oh my god"] = "well, I'll be", ["omg"] = "well, I'll be",
    ["let's go"] = "let's go. This city won't wait" },
  lex = {
    friend = "pal|partner|doll|chum", friends = "pals|mugs|folks", enemy = "crook|heavy|rat", enemies = "crooks|heavies|rats",
    boss = "the big boss|the kingpin", mob = "goon|thug", mobs = "goons|thugs", money = "dough|clams|bread", city = "this rotten city|town",
    night = "night", good = "not bad|clean", bad = "rotten|crooked|dirty", kill = "rub out|take down",
    killed = "rubbed out|put on ice|took down", die = "take the long sleep", died = "took the long sleep", idiot = "sap|mug|chump",
    drink = "drink|stiff drink", gun = "piece", quest = "case|job", quests = "cases|jobs",
  },
  openers = "Listen, pal.|Funny thing.",
})

---------------------------------------------------------------------------
-- 9. Drill Sergeant (everything shouted)
---------------------------------------------------------------------------
Add("sergeant", {
  name = "Drill Sergeant", group = "silly", icon = "Interface\\Icons\\Ability_Warrior_BattleShout", slash = "sarge",
  blurb = "DROP AND GIVE ME TWENTY, MAGGOT!",
  ranks = { "Maggot", "Recruit", "Private", "Corporal", "Sergeant", "Drill Instructor", "Sergeant Major", "Living Legend" },
  say = {
    greet = "LISTEN UP, MAGGOTS!|ATTENTION!|EYES FRONT, MAGGOTS!", bye = "DISMISSED!|I'M OUTTA HERE, MAGGOTS!",
    thanks = "THANK YOU! NOW GIVE ME TWENTY!|APPRECIATED, PRIVATE!", sorry = "MY FAULT! I'LL GIVE MYSELF TWENTY!",
    yes = "SIR, YES SIR!|AFFIRMATIVE!", no = "NEGATIVE!|SIR, NO SIR!", okay = "ROGER THAT!|COPY THAT!", lol = "THAT'S NOT FUNNY, MAGGOT! OKAY, IT'S A LITTLE FUNNY.",
    ready = "LOCKED AND LOADED!", wait = "HOLD THE LINE!|AS YOU WERE!", go = "MOVE MOVE MOVE!|DOUBLE TIME, MAGGOTS!|CHARGE!",
    dead = "I'M DOWN! DO NOT LEAVE ME, MAGGOTS!", heal = "MEDIC! MEDIC!", gg = "OUTSTANDING WORK, MAGGOTS!", nice = "OUTSTANDING!",
    wow = "WELL, I'LL BE!", help = "I NEED BACKUP!", run = "FALL BACK! FALL BACK!", oom = "I'M OUT OF AMMO! MANA! WHATEVER!",
  },
  phrases = { ["can you"] = "you WILL", ["could you"] = "you WILL", ["i think"] = "I KNOW", ["let's go"] = "MOVE MOVE MOVE",
    ["you guys"] = "you maggots", ["i'm tired"] = "PAIN IS WEAKNESS LEAVING THE BODY", ["hurry up"] = "DOUBLE TIME" },
  lex = { friend = "private|soldier|maggot", friends = "maggots|recruits|soldiers", noob = "maggot|recruit", idiot = "maggot|knucklehead",
    good = "outstanding|squared away", bad = "sloppy|a disgrace", quickly = "double time", kill = "neutralize|take out",
    killed = "neutralized|took out", boss = "target", mob = "hostile", mobs = "hostiles" },
  caps = "upper",
})

---------------------------------------------------------------------------
-- 10. High Epic (in the spirit of Tolkien: old, grand, journeying)
---------------------------------------------------------------------------
Add("epic", {
  name = "High Epic", group = "fantasy", icon = "Interface\\Icons\\INV_Misc_Book_07", slash = "epic",
  blurb = "Old and grand, like the great journeys of fantasy. Inspired by Tolkien.",
  ranks = { "Wanderer", "Traveler", "Companion", "Ranger", "Lorekeeper", "Hero of Old", "Loremaster", "Living Legend" },
  say = {
    greet = "Well met, friend.|Hail, and well met!|Greetings, good folk.", bye = "Farewell, and may your road be straight.|Go in peace, friend.",
    goodnight = "Rest now. The road will wait for the morning.", thanks = "My thanks to you.|I am in your debt.", welcome = "It was gladly given.",
    sorry = "Forgive me, friend.", yes = "Yea.|It is so.", no = "Nay.|It shall not be.", okay = "So be it.|Let it be so.",
    lol = "Ha! A merry jest!", ready = "We are ready. Let us go forth.", wait = "Hold! Not yet.", go = "Forth now, and fear no darkness!|Onward!",
    dead = "Darkness takes me...", heal = "Tend my wounds, I beg you.", gg = "The deed is done.|Victory is ours, though dearly bought.",
    nice = "Well done, friend.", wow = "By the stars!|Marvelous!", idk = "That I cannot say.", help = "To me! Aid me!", run = "Fly, fly!",
  },
  phrases = { ["i think"] = "methinks|I deem", ["a long time"] = "many long years|an age of the world", ["let's go"] = "let us set forth|let us go forth",
    ["right now"] = "in this very hour", ["i'm tired"] = "I am weary unto my bones", ["you guys"] = "my friends|good folk",
    ["oh my god"] = "by the stars|alas", ["omg"] = "by the stars", ["i don't know"] = "that I cannot say", ["a lot"] = "a great deal" },
  words = { before = "ere", nothing = "naught", maybe = "mayhap", yes = "yea", no = "nay", okay = "so be it" },
  lex = {
    friend = "companion|good friend|kinsman", friends = "companions|fellows|good folk", enemy = "foe|fell foe", enemies = "foes|fell foes",
    mob = "fell creature|foul thing", mobs = "fell creatures|foul things", boss = "dread lord|great evil|ancient foe",
    dungeon = "deep place|hall of stone", dungeons = "deep places|halls of stone", good = "fair|noble|goodly", bad = "fell|foul|dark",
    big = "great|mighty", old = "ancient|of old", kill = "slay|smite", killed = "slew|smote", money = "treasure|gold", food = "provisions|fare",
    home = "hearth|homeland", weapon = "blade|sword of old", quest = "quest|errand", scary = "dread|fell", very = "most|exceeding",
  },
  openers = "Lo,|Hearken,",
})

---------------------------------------------------------------------------
-- 11. Grimdark (in the spirit of George R.R. Martin: bleak, oaths, steel)
---------------------------------------------------------------------------
Add("grimdark", {
  name = "Grimdark", group = "fantasy", icon = "Interface\\Icons\\INV_Sword_04", slash = "grimdark",
  blurb = "Bleak, bloody and honest about it. Inspired by George R.R. Martin.",
  ranks = { "Smallsword", "Squire", "Sellsword", "Hedge Knight", "Sworn Sword", "Lord", "Warlord", "Kingmaker" },
  say = {
    greet = "Well met. Keep your hand off your sword.|Gods be good.|You're still alive, then.", bye = "Gods keep you. Not that they will.|Farewell. Try not to die.",
    goodnight = "Sleep with one eye open.", thanks = "I'll remember that. I remember everything.|My thanks. Don't make me regret it.",
    sorry = "Sorry changes nothing. But aye, sorry.", yes = "Aye.", no = "No.|Never.", okay = "Aye. So be it.",
    lol = "Ha. Laugh while you can.", ready = "Ready. Pray it's enough.", wait = "Hold.", go = "To arms!|Steel and blood, let's go!",
    dead = "I'm dead. Should have seen it coming.", heal = "Bind my wounds before I bleed out.", gg = "We lived. Today.|Victory. Count the dead later.",
    nice = "Not bad. Not dead, either.", wow = "Gods above.", idk = "Only the gods know, and they don't care.", help = "To me! Steel, to me!",
    run = "Run, and live to fight another day!",
  },
  phrases = { ["i think"] = "I fear|if the gods are good", ["oh my god"] = "gods be good|gods help us", ["omg"] = "gods above",
    ["let's go"] = "to arms, then|we ride", ["good luck"] = "may the gods be with you. They won't be", ["you guys"] = "you lot|my brothers",
    ["i'm tired"] = "I'm tired, and tired men die", ["i'm hungry"] = "I'm hungry, and the larder's empty" },
  words = { sir = "ser", yes = "aye" },
  lex = {
    friend = "brother|sworn brother", friends = "brothers|you lot", enemy = "turncloak|oathbreaker|enemy", enemies = "turncloaks|oathbreakers|enemies",
    boss = "warlord|butcher", good = "decent|fine|well-made", bad = "craven|rotten|bloody", kill = "kill|butcher",
    killed = "butchered|killed", die = "die badly|die", died = "died badly|died", money = "silver|coin", drink = "drink|sour wine",
    idiot = "craven|fool|green boy", noob = "green boy|squire", weapon = "steel|blade", gear = "steel|plunder", scary = "grim|bloody",
  },
  openers = "Gods,|Listen,",
})

---------------------------------------------------------------------------
-- 12. Wry Narrator (in the spirit of Terry Pratchett: dry, warm, Capitalized Things)
---------------------------------------------------------------------------
Add("wry", {
  name = "Wry Narrator", group = "fantasy", icon = "Interface\\Icons\\INV_Misc_Book_11", slash = "wry",
  blurb = "Dry, warm, and slightly too observant. Inspired by Terry Pratchett.",
  ranks = { "Apprentice", "Junior Wizard", "Senior Wrangler", "Lecturer in Recent Runes", "Bursar", "Archchancellor", "Narrator", "Footnote" },
  say = {
    greet = "Hello. Nice day for it.|Ah. Hello.|Oh, it's you. Good.", bye = "Right then. Off I go.|Goodbye, and mind the edge.",
    goodnight = "Off to bed, which is where the best ideas go to die.", thanks = "Thanks. I'll pretend I don't owe you.",
    sorry = "Sorry. That was an Accident, with a capital A.", yes = "Yes. Probably.|Yes, more or less.", no = "No. Definitely. Well, mostly.",
    okay = "Right. Yes. Fine.", lol = "Ha. That was nearly funny.|Heh. Good one.", ready = "Ready, in the broad sense of the word.",
    go = "Charge! (Carefully.)", dead = "Dead. Embarrassing, really.", heal = "A Healer would be nice about now.",
    gg = "Well, that could have gone worse. It usually does.", nice = "Not bad at all. Suspiciously not bad.", wow = "Well I never.|Gosh.",
    idk = "No idea, which is my usual state of affairs.", help = "Help would be appreciated. Quite a lot of help.", run = "Run! Tactically!",
  },
  phrases = { ["i think"] = "it occurred to me|I was fairly sure", ["oh my god"] = "good grief|well I never", ["omg"] = "good grief",
    ["a lot"] = "a great deal, or more", ["you guys"] = "you lot|everyone, more or less", ["right now"] = "right now, more or less" },
  lex = {
    boss = "Large Problem|Boss", healer = "Healer", tank = "Tank", mob = "Thing|Creature of Unclear Intent", mobs = "Things|Creatures of Unclear Intent",
    good = "not entirely terrible|rather good|quite good", bad = "not ideal|unfortunate|regrettable", idiot = "pillock|the sort of person who",
    money = "money (of which there was not enough)|money", kill = "deal with|dispatch", killed = "dealt with|dispatched",
    died = "died (briefly)|died", dungeon = "Dungeon|damp Dungeon", magic = "Magic", very = "rather|quite",
  },
  interject = "more or less|as these things go|in a manner of speaking|probably",
  interjectChance = { 0, 0.25, 0.4 },
  openers = "Now,|Right,",
})

---------------------------------------------------------------------------
-- 13. Wizard (pompous, arcane, very learned)
---------------------------------------------------------------------------
Add("wizard", {
  name = "Wizard", group = "fantasy", icon = "Interface\\Icons\\INV_Staff_13",
  blurb = "Ahem. By the arcane laws, this blurb is correct.",
  ranks = { "Apprentice", "Initiate", "Adept", "Conjurer", "Magus", "Archmage", "Grand Magister", "Keeper of the Arcane" },
  say = {
    greet = "Greetings, seekers of knowledge.|Ah, visitors. How... unexpected.|Salutations!", bye = "I must return to my tomes. Farewell!|I vanish! In a puff of smoke!",
    thanks = "Your gratitude is noted. In my journal.|Thank you, apprentice.", sorry = "A minor miscalculation. It happens to the best of us. Rarely.",
    yes = "Indubitably!|Quite so.|Affirmative, by the arcane laws.", no = "Absolutely not.|The stars say no.", okay = "Very well.|So it is written.",
    lol = "Ha! A most amusing incantation.|Heh. Clever.", ready = "My spells are prepared.", wait = "Patience! I am concentrating!",
    go = "Onward, by the arcane!|Unleash the spells!", oom = "My mana reserves are depleted. Most inconvenient.", heal = "Mend me, I've been... disenchanted.",
    gg = "A triumph of intellect!", nice = "Most impressive.|Splendidly cast.", wow = "By the arcane!|Fascinating!", dead = "Slain! The indignity!",
    idk = "That is beyond even my studies.", help = "Assistance, apprentices!", run = "Teleport! Or, failing that, RUN!",
  },
  phrases = { ["i think"] = "I deduce|my calculations suggest|it is my learned opinion that", ["i don't know"] = "that is beyond my studies",
    ["a lot"] = "a great quantity", ["oh my god"] = "by the arcane", ["omg"] = "by the arcane", ["you guys"] = "my apprentices|you lot",
    ["let's go"] = "onward, by the arcane", ["right now"] = "forthwith", ["of course"] = "naturally, obviously" },
  lex = {
    friend = "apprentice|colleague", friends = "apprentices|colleagues", good = "splendid|most excellent|exquisite", bad = "dreadful|unscholarly|amateurish",
    big = "colossal|considerable", small = "minuscule|negligible", idiot = "dunce|half-wit|fool", smart = "learned|erudite",
    magic = "arcane power|magic", kill = "disintegrate|vanquish|smite", killed = "disintegrated|vanquished", money = "gold|reagent money",
    quest = "endeavor|undertaking", hard = "arcane", easy = "elementary", very = "most|exceedingly", look = "observe", think = "deduce",
  },
  openers = "Ahem.|Hmm, yes.",
})

---------------------------------------------------------------------------
-- 14. Old Prospector
---------------------------------------------------------------------------
Add("prospector", {
  name = "Old Prospector", group = "silly", icon = "Interface\\Icons\\INV_Pick_02",
  blurb = "There's gold in them thar hills, consarn it!",
  ranks = { "Greenhorn", "Panhandler", "Claim Jumper", "Digger", "Old Timer", "Mother Lode", "Gold Baron", "Legend of the Hills" },
  say = {
    greet = "Well howdy, stranger!|Hoo-wee, company!", bye = "I'm headin' back to my claim!|Happy trails, and watch fer claim jumpers!",
    thanks = "Much obliged!|Thank ye kindly!", yes = "Yessiree!|You betcha!", no = "Nope!|Not on yer life!", okay = "Right as rain.|Sure thing.",
    lol = "Hee hee hee!|Hoo-wee, that's a knee-slapper!", ready = "Ready as a mule with a full belly!", go = "Giddyup!|Let's git!",
    dead = "Dagnabbit, I'm dead!", heal = "Patch me up, I'm leakin'!", gg = "Struck it rich!|Eureka!", nice = "Well butter my biscuit!",
    wow = "Hoo-wee!|Great googly moogly!|Eureka!", idk = "Darned if I know!", help = "Help! Claim jumpers!", run = "Skedaddle!",
  },
  phrases = { ["i think"] = "I reckon|seems to me", ["oh my god"] = "great googly moogly|hoo-wee", ["omg"] = "hoo-wee", ["a lot"] = "a whole heap",
    ["you guys"] = "you young'uns|y'all", ["right now"] = "right quick", ["let's go"] = "giddyup|let's git" },
  words = { you = "ye", your = "yer", the = "th'", ["and"] = "an'", ["isn't"] = "ain't", ["aren't"] = "ain't", them = "'em", there = "thar", gold = "gold" },
  lex = {
    friend = "partner|pardner|young'un", friends = "young'uns|pardners|folks", money = "gold|nuggets|gold dust", good = "fine|dandy|mighty fine",
    bad = "rotten|no-good|lousy", big = "big|whoppin'", idiot = "varmint|fool|dang fool", mob = "varmint|critter", mobs = "varmints|critters",
    dungeon = "mine|cave", dungeons = "mines|caves", kill = "whup", killed = "whupped", very = "mighty|plumb",
  },
  rules = { { "ing$", "in'", min = 1, chance = 0.9 } },
  openers = "Hoo-wee,|Well,",
})

---------------------------------------------------------------------------
-- 15. Caveman
---------------------------------------------------------------------------
Add("caveman", {
  name = "Caveman", group = "silly", icon = "Interface\\Icons\\INV_Misc_Bone_01",
  blurb = "Ugg. Fire good. Mob bad.",
  ranks = { "Pebble", "Rock", "Big Rock", "Club Holder", "Fire Maker", "Mammoth Hunter", "Tribe Chief", "First Human" },
  say = {
    greet = "Ugg!|Ugg. Hello.", bye = "Ugg go cave now.|Bye. Ugg.", thanks = "Ugg thank.|Good. Ugg happy.", yes = "Ugg!|Yes. Ugg yes.",
    no = "No! Ugg no!", okay = "Ugg okay.", lol = "Ha! Ha! Ugg laugh!|HUH HUH HUH!", ready = "Ugg ready! Club ready!", go = "UGG GO!|Smash!",
    dead = "Ugg dead. Ow.", heal = "Ugg hurt! Fix Ugg!", gg = "Ugg win!|Big hunt good!", nice = "Good! Very good!", wow = "OOH!|Ugg amazed!",
    idk = "Ugg not know.", help = "Help Ugg!", run = "RUN! Big thing!", hungry = "Ugg hungry. Ugg want meat.",
  },
  phrases = { ["i am"] = "Ugg", ["i'm"] = "Ugg", ["i don't"] = "Ugg no", ["i can't"] = "Ugg no can", ["i think"] = "Ugg think", ["i will"] = "Ugg will",
    ["i'll"] = "Ugg will", ["i want"] = "Ugg want", ["i need"] = "Ugg need", ["i have"] = "Ugg have" },
  words = { i = "Ugg", me = "Ugg", my = "Ugg's", ["don't"] = "no", ["can't"] = "no can", fire = "fire", torch = "fire", light = "fire" },
  lex = { good = "good|big good", bad = "bad|no good", big = "big|big big", small = "small|tiny", kill = "bonk|smash|club",
    killed = "bonked|smashed|clubbed", weapon = "club|rock", money = "shiny rocks", food = "meat", friend = "tribe friend", friends = "tribe",
    boss = "big beast", dungeon = "dark cave", magic = "sky fire", very = "big" },
  drop = { a = 1, an = 1, the = 1, is = 1, are = 1, am = 1, to = 1, of = 1 },
})

---------------------------------------------------------------------------
-- 16. Robot
---------------------------------------------------------------------------
Add("robot", {
  name = "Robot", group = "silly", icon = "Interface\\Icons\\INV_Gizmo_02",
  blurb = "BEEP. PROCESSING REQUEST. HUMOR MODULE ONLINE.",
  ranks = { "Prototype", "Unit 1", "Drone", "Automaton", "Android", "Supercomputer", "Singularity", "Overlord Unit" },
  say = {
    greet = "GREETINGS, HUMANS.|HELLO. BEEP BOOP.|INITIATING GREETING.", bye = "POWERING DOWN.|LOGGING OFF. BEEP.",
    thanks = "GRATITUDE.EXE EXECUTED.|THANK YOU, HUMAN.", sorry = "ERROR. APOLOGY.EXE.", yes = "AFFIRMATIVE.|YES. BEEP.",
    no = "NEGATIVE.|DOES NOT COMPUTE.", okay = "ACKNOWLEDGED.|ROGER.", lol = "HA. HA. HA. LAUGHTER SIMULATED.|LOL.EXE",
    ready = "ALL SYSTEMS GO.", wait = "PLEASE STAND BY.", go = "ENGAGING.|EXECUTING ATTACK PROTOCOL.", dead = "CRITICAL FAILURE. REBOOTING.",
    heal = "REPAIRS REQUIRED.", gg = "MISSION COMPLETE.", nice = "OPTIMAL.|EXCELLENT OUTPUT.", wow = "DOES NOT COMPUTE.|SYSTEM SHOCK.",
    idk = "INSUFFICIENT DATA.", help = "REQUESTING ASSISTANCE.", run = "RETREAT PROTOCOL ENGAGED.", oom = "POWER LEVEL: ZERO.",
  },
  phrases = { ["i think"] = "MY CALCULATIONS SAY", ["i don't know"] = "INSUFFICIENT DATA", 
    ["you guys"] = "HUMANS", ["oh my god"] = "SYSTEM ERROR", ["omg"] = "SYSTEM ERROR", ["let's go"] = "INITIATING DEPARTURE" },
  lex = { friend = "human|unit", friends = "humans|units", good = "optimal|efficient", bad = "suboptimal|defective", kill = "terminate|delete",
    killed = "terminated|deleted", die = "shut down", died = "shut down", food = "fuel", sleep = "recharge", tired = "low on battery",
    happy = "functioning normally", sad = "malfunctioning", angry = "overheating", boss = "target", mob = "hostile unit", mobs = "hostile units" },
  caps = "upper",
  post = function(s, strength)
    if strength >= 2 and math.random() < 0.25 then s = (s:find("[%.!%?]$") and s or (s .. ".")) .. " BEEP." end
    return s
  end,
})

---------------------------------------------------------------------------
-- 17. Medieval Peasant
---------------------------------------------------------------------------
Add("peasant", {
  name = "Medieval Peasant", group = "silly", icon = "Interface\\Icons\\INV_Misc_Food_11",
  blurb = "Oh, 'tis a lovely bit o' mud today.",
  ranks = { "Serf", "Mud Farmer", "Turnip Grower", "Village Idiot", "Freeholder", "Town Crier", "Village Elder", "Peasant Royalty" },
  say = {
    greet = "Mornin', m'lord.|Oh! 'Ello there!", bye = "Back to the fields wiv me.|Off I go, mind the mud.", thanks = "Ta very much!|Bless ye!",
    sorry = "Beg pardon, beg pardon!", yes = "Aye!|Right you are!", no = "Oh no no no.|Not likely!", okay = "Right you are.",
    lol = "Hehehe! Ooh, that's a good 'un!", ready = "Got me pitchfork, ready!", go = "Right, off we go then!|Grab yer pitchforks!",
    dead = "Ah well. Least it ain't the plague.", heal = "Fetch the leeches!|I needs a barber-surgeon!", gg = "Huzzah!|Well I never! We won!",
    nice = "Ooh, lovely!", wow = "Cor blimey!|Gor!", idk = "Couldn't say, m'lord.", help = "'Elp! 'Elp!", run = "Run fer it!",
  },
  phrases = { ["i think"] = "I reckon|me mum always said", ["oh my god"] = "cor blimey|lawks", ["omg"] = "cor blimey", ["you guys"] = "you lot",
    ["right now"] = "right now, before the harvest", ["a lot"] = "a right lot" },
  words = { my = "me", you = "ye", hello = "'ello", with = "wiv", ["isn't"] = "ain't", them = "'em", nothing = "nuffin'", something = "summat" },
  lex = { friend = "mate|neighbor", friends = "you lot|neighbors", money = "coin|turnips|a few coppers", food = "turnips|gruel|bread",
    good = "lovely|grand", bad = "rotten|terrible", leader = "m'lord", boss = "the lord|the big 'un", home = "hovel|hut", mob = "beastie",
    dungeon = "dungeon", weapon = "pitchfork|hoe", idiot = "turnip head|nitwit", very = "right|proper" },
  rules = { { "^h(%a)", "'%1", min = 2, chance = 0.5 } },
})

---------------------------------------------------------------------------
-- 18. Cowboy
---------------------------------------------------------------------------
Add("cowboy", {
  name = "Cowboy", group = "silly", icon = "Interface\\Icons\\INV_Misc_Horn_01",
  blurb = "Well howdy, partner. Yeehaw!",
  ranks = { "Greenhorn", "Ranch Hand", "Wrangler", "Cowpoke", "Gunslinger", "Sheriff", "Trail Boss", "Legend of the West" },
  say = {
    greet = "Howdy, partner!|Well howdy!|Howdy, y'all!", bye = "Happy trails!|I'm ridin' off into the sunset.", thanks = "Much obliged, partner.",
    sorry = "My mistake, partner.", yes = "Yup.|You bet.", no = "Nope.|Not a chance, partner.", okay = "Reckon so.|Alrighty.",
    lol = "Haw haw!|Yeehaw, that's funny!", ready = "Saddled up and ready.", wait = "Whoa there!|Hold yer horses!", go = "Yeehaw!|Let's ride!",
    dead = "Reckon I'm pushin' up daisies.", heal = "Patch me up, doc.", gg = "Yeehaw! We won!|That's how it's done in the West.",
    nice = "Mighty fine!", wow = "Well I'll be!|Yeehaw!", idk = "Couldn't tell ya, partner.", help = "Need a hand here, partner!", run = "Skedaddle!",
  },
  phrases = { ["i think"] = "I reckon", ["oh my god"] = "well I'll be|good gravy", ["omg"] = "well I'll be", ["you guys"] = "y'all",
    ["right now"] = "right quick", ["let's go"] = "let's ride|saddle up", ["a lot"] = "a whole heap", ["i'm going to"] = "I'm fixin' to" },
  words = { ["isn't"] = "ain't", ["aren't"] = "ain't", them = "'em" },
  lex = { friend = "partner|pardner|buckaroo", friends = "y'all|partners|cowpokes", good = "mighty fine|fine|dandy", bad = "ornery|rotten|no-good",
    big = "big ol'|mighty big", idiot = "varmint|greenhorn|tenderfoot", mob = "varmint|critter", mobs = "varmints|critters", mount = "horse|steed",
    money = "gold|bucks", boss = "head honcho|big bad outlaw", enemy = "outlaw|varmint", kill = "lasso|wrangle|take down", killed = "wrangled|took down",
    town = "town", very = "mighty|real", city = "town" },
  rules = { { "ing$", "in'", min = 1, chance = 0.8 } },
  openers = "Well,|Yeehaw,",
})

---------------------------------------------------------------------------
-- 19. Surfer
---------------------------------------------------------------------------
Add("surfer", {
  name = "Surfer", group = "silly", icon = "Interface\\Icons\\INV_Misc_Fish_09",
  blurb = "Duuude. Totally bodacious.",
  ranks = { "Grommet", "Beach Bum", "Wave Catcher", "Shredder", "Big Wave Rider", "Surf God", "Tsunami", "One With The Wave" },
  say = {
    greet = "Duuude!|Sup, brah!|Aloha, dudes!", bye = "Later, brah!|Catch ya on the next wave!", thanks = "Thanks, brah! Mad respect.",
    sorry = "My bad, dude. Totally.", yes = "Totally!|For sure, dude!", no = "Nah, brah.|Bogus, dude.", okay = "Rad.|Righteous.",
    lol = "Hahaha, gnarly!|Duuude, hilarious!", ready = "Stoked and ready, brah!", go = "Cowabunga!|Let's shred, dudes!",
    dead = "Wiped out, brah.", heal = "Dude, heal me, I ate it hard.", gg = "Radical, dudes!|Totally tubular!", nice = "Gnarly!|Sick, brah!",
    wow = "Whoa!|Duuude!", idk = "No clue, brah.", help = "Dudes, help!", run = "Paddle out, paddle out!",
  },
  phrases = { ["i think"] = "I'm like, pretty sure|dude, I think", ["oh my god"] = "duuude|whoa", ["omg"] = "duuude", ["you guys"] = "dudes|brahs",
    ["let's go"] = "let's shred|cowabunga", ["a lot"] = "a gnarly amount", ["right now"] = "right now, brah" },
  lex = { friend = "dude|brah|bro", friends = "dudes|brahs", good = "rad|gnarly|tubular|righteous", bad = "bogus|harsh|lame", big = "gnarly|massive",
    very = "totally|super", wow = "whoa|duuude", boss = "big kahuna", mob = "kook", mobs = "kooks", idiot = "kook|barney", happy = "stoked",
    angry = "bummed", sad = "bummed", died = "wiped out", die = "wipe out", scary = "gnarly" },
  interject = "dude|brah|like", interjectChance = { 0, 0.25, 0.4 },
})

---------------------------------------------------------------------------
-- 20. Butler
---------------------------------------------------------------------------
Add("butler", {
  name = "Butler", group = "silly", icon = "Interface\\Icons\\INV_Misc_Bell_01",
  blurb = "Very good, sir. Shall I fetch the healer?",
  ranks = { "Footman", "Valet", "Under-Butler", "Butler", "Head Butler", "Majordomo", "Gentleman's Gentleman", "Perfectly Composed" },
  say = {
    greet = "Good day. How may I be of service?|Ah, welcome.", bye = "Very good. I shall take my leave.|Will that be all?",
    thanks = "Most kind.|You are too kind.", welcome = "A pleasure, as always.", sorry = "My sincerest apologies.", yes = "Very good.|Certainly.|Indeed.",
    no = "I'm afraid not.|Regrettably, no.", okay = "Very good.|As you wish.", lol = "How very droll.|Quite amusing.", ready = "Ready when you are.",
    wait = "One moment, if you please.", go = "Shall we proceed?|After you, of course.", dead = "I appear to have perished. Most irregular.",
    heal = "If it isn't too much trouble, a heal would be most welcome.", gg = "A job well done, if I may say so.", nice = "Splendid.|Very well done.",
    wow = "Good heavens.|Goodness.", idk = "I couldn't say.", help = "Might I trouble someone for assistance?", run = "Perhaps a hasty retreat is in order.",
  },
  phrases = { ["i think"] = "if I may say so|I believe", ["can you"] = "might you|would you be so kind as to", ["you guys"] = "sirs and madams|everyone",
    ["oh my god"] = "good heavens", ["omg"] = "good heavens", ["let's go"] = "shall we proceed", ["i need"] = "I require", ["i want"] = "I would prefer",
    ["what the hell"] = "goodness me", ["right now"] = "presently" },
  lex = { friend = "sir|madam", friends = "sirs and madams|everyone", good = "splendid|very fine|most satisfactory", bad = "regrettable|unfortunate|most unpleasant",
    idiot = "the gentleman|the young master", boss = "the master of this place", mob = "uninvited guest", mobs = "uninvited guests",
    kill = "dispose of|see out", killed = "disposed of|saw out", money = "funds", food = "refreshments", drink = "tea|refreshment", very = "most|quite" },
  openers = "Pardon me,|If I may,",
})

---------------------------------------------------------------------------
-- 21. Grumpy Old Man
---------------------------------------------------------------------------
Add("grumpy", {
  name = "Grumpy Old Man", group = "silly", icon = "Interface\\Icons\\INV_Misc_Spectacles_01", slash = "grumpy",
  blurb = "Back in my day we walked uphill to Deadmines. Both ways.",
  ranks = { "Whippersnapper", "Grouch", "Crank", "Curmudgeon", "Old Coot", "Get Off My Lawn", "Ancient Grump", "Older Than Dirt" },
  say = {
    greet = "What? Who's there?|Oh, it's you again.|Hmph. Hello.", bye = "Finally. Goodbye.|I'm going to bed. It's past 8.",
    thanks = "Hmph. Thanks, I suppose.", sorry = "Fine. Sorry. Happy now?", yes = "Yes, yes.|I suppose so.", no = "No! Absolutely not!",
    okay = "Fine. Whatever.", lol = "Hmph. Kids these days.|That's not funny. We had real jokes.", ready = "I've been ready for an hour.",
    wait = "Hold your horses!", go = "Well, get on with it!", dead = "Dead again. Back in my day we didn't die.", heal = "My back! Heal my back!",
    gg = "Back in my day that took us a week.", nice = "Not bad. For a whippersnapper.", wow = "Well, I never.|Hmph.",
    idk = "How should I know?", help = "Somebody help an old man!", run = "I can't run, my knees!",
  },
  phrases = { ["i think"] = "in my opinion|I'll tell you what I think:", ["you guys"] = "you kids|you whippersnappers",
    ["oh my god"] = "good grief", ["omg"] = "good grief", ["what the hell"] = "what in tarnation", ["right now"] = "right now, not tomorrow",
    ["let's go"] = "let's get this over with" },
  lex = { friend = "kid|sonny", friends = "you kids|whippersnappers", good = "fine|not terrible", bad = "terrible|ridiculous|a disgrace",
    idiot = "whippersnapper|young fool", noob = "whippersnapper|kid", new = "newfangled", game = "game", expensive = "highway robbery",
    money = "money (it used to be a copper!)|money", very = "darn|real", tired = "tired, my back hurts" },
  openers = "Hmph.|Bah.",
})

---------------------------------------------------------------------------
-- 22. Valley Girl
---------------------------------------------------------------------------
Add("valley", {
  name = "Valley Girl", group = "silly", icon = "Interface\\Icons\\INV_Misc_Gem_Pearl_04", slash = "valley",
  blurb = "Like, oh my gosh. Totally.",
  ranks = { "Freshman", "Mall Rat", "Trendsetter", "Queen Bee", "Total Icon", "Prom Queen", "Like, Famous", "Literally Iconic" },
  say = {
    greet = "Oh my gosh, hiii!|Heyyy!", bye = "Byeee!|Gotta go, kisses!", thanks = "Oh my gosh, thank you sooo much!",
    sorry = "Ugh, I'm like, so sorry.", yes = "Totally!|For sure!|Like, duh!", no = "Ew, no.|As if!|Like, no way.", okay = "Whatever.|Fine, I guess.",
    lol = "Oh my gosh, I'm dying!|Literally crying!", ready = "Like, so ready!", go = "Let's gooo!|Like, come on!", dead = "Ugh, I'm like, so dead.",
    heal = "Can you, like, heal me?", gg = "That was, like, amazing!", nice = "Oh my gosh, cute!|Totally!", wow = "Oh my gosh!|Shut up!",
    idk = "I literally have no idea.", help = "Like, help!", run = "Ew, run!",
  },
  phrases = { ["i think"] = "I'm like, pretty sure|I literally think", ["oh my god"] = "oh my gosh", ["omg"] = "oh my gosh", ["you guys"] = "you guys",
    ["no way"] = "as if", ["a lot"] = "like, so much" },
  lex = { good = "cute|amazing|totally awesome", bad = "gross|ew|so lame", very = "like, so|literally|totally", big = "huge|like, massive",
    ugly = "ew|gross", friend = "bestie|girl", friends = "besties|you guys", idiot = "loser|total loser", boring = "like, so boring",
    expensive = "so pricey", honestly = "literally|like" },
  interject = "like|literally|you know", interjectChance = { 0.1, 0.3, 0.5 },
})

---------------------------------------------------------------------------
-- 23. Conspiracy Guy
---------------------------------------------------------------------------
Add("conspiracy", {
  name = "Conspiracy Guy", group = "silly", icon = "Interface\\Icons\\INV_Misc_Eye_01", slash = "conspiracy",
  blurb = "Wake up! The healer is working for the boss!",
  ranks = { "Curious", "Skeptic", "Truth Seeker", "Researcher", "Whistleblower", "Insider", "They're Watching", "Knows Too Much" },
  say = {
    greet = "Hey. Don't say my name. They're listening.|Psst. Over here.", bye = "I have to go. They're onto me.",
    thanks = "Thanks. Don't tell anyone.", sorry = "Sorry. That's what they WANT me to say.", yes = "Exactly. EXACTLY.|You see it too.",
    no = "No. And that's what they don't want you to know.", okay = "Okay. For now.", lol = "Laugh all you want. You'll see.",
    ready = "I've been ready since the cover-up.", go = "Go! Before they reset the dungeon!", dead = "They got me. I knew too much.",
    heal = "Heal me. If that's even really a heal.", gg = "Too easy. Almost like it was planned.", nice = "Nice. Suspiciously nice.",
    wow = "I KNEW IT.|Wake up, people!", idk = "That's classified.", help = "Help! They're coming!", run = "Run! It's a setup!",
  },
  phrases = { ["i think"] = "I KNOW|wake up, people,", ["oh my god"] = "I knew it", ["omg"] = "I knew it", ["you guys"] = "sheeple|people",
    ["right now"] = "right now, while they're not looking", ["i don't know"] = "nobody knows, and that's the point", ["of course"] = "of course. COINCIDENCE?" },
  lex = { friend = "fellow truth seeker|brother", friends = "people|sheeple", boss = "so-called boss", healer = "so-called healer", tank = "so-called tank",
    good = "suspicious|suspiciously good", bad = "rigged|staged", game = "simulation", drop = "plant", dropped = "planted", lag = "lag (it's not lag)",
    random = "not random", lucky = "too lucky", very = "VERY" },
  post = function(s, strength)
    if strength >= 2 and math.random() < 0.18 and not s:find("Coincidence") and not s:find("[%?]$") then s = s:gsub("[%.!]$", "") .. ". Coincidence?" end
    return s
  end,
})

---------------------------------------------------------------------------
-- 24. Sports Announcer
---------------------------------------------------------------------------
Add("announcer", {
  name = "Sports Announcer", group = "silly", icon = "Interface\\Icons\\INV_Misc_Horn_02", slash = "announcer",
  blurb = "AND HE PULLS THE WHOLE ROOM! UNBELIEVABLE!",
  ranks = { "Benchwarmer", "Rookie", "Play-by-Play", "Color Commentator", "Lead Announcer", "Voice of the League", "Hall of Famer", "THE GOAT" },
  say = {
    greet = "WELCOME, folks, to another BIG night!|Hello and welcome, everybody!", bye = "That's all from us, folks! GOOD NIGHT!",
    thanks = "A class act, folks!", sorry = "A rare fumble there!", yes = "YES! YES! YES!|ABSOLUTELY!", no = "NO! He can't believe it!",
    okay = "And the play is on!", lol = "OH, the crowd LOVES it!|What a moment!", ready = "The players are in position!",
    wait = "Timeout on the field!", go = "AND THEY'RE OFF!|HERE WE GO!", dead = "He's DOWN! He's down, folks!", heal = "The trainers are rushing out!",
    gg = "WHAT A GAME! WHAT A GAME!|AND THE CROWD GOES WILD!", nice = "WHAT A PLAY!|SPECTACULAR!", wow = "UNBELIEVABLE!|DID YOU SEE THAT?!",
    idk = "Nobody saw that coming, folks!", help = "He needs backup out there!", run = "AND HE'S RUNNING! LOOK AT HIM GO!", oom = "He's running on EMPTY!",
  },
  phrases = { ["i think"] = "folks, I believe", ["oh my god"] = "UNBELIEVABLE", ["omg"] = "UNBELIEVABLE", ["you guys"] = "folks",
    ["let's go"] = "HERE WE GO", ["i'm"] = "he's", ["i am"] = "he is", ["what the hell"] = "WHAT A PLAY" },
  lex = { friend = "teammate|veteran", friends = "folks|the team", boss = "the champion|the reigning champ", good = "SPECTACULAR|incredible|world-class",
    bad = "a fumble|rough|a disaster", kill = "take down|defeat", killed = "takes down|defeats", pulled = "PULLS", pull = "PULL", died = "goes DOWN",
    mob = "opponent", mobs = "opponents", tank = "tank", healer = "healer", very = "absolutely", wow = "UNBELIEVABLE" },
  openers = "Folks,|AND",
  post = function(s, strength) if strength >= 2 then s = s:gsub("%.$", "!") end if strength >= 3 then s = s:gsub("!$", "!!") end return s end,
})
