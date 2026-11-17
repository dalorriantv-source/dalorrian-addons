-- Dalorrian's Accents: deep word pools for the eight starter accents.
-- lex[group] = "a|b|c": any English word in that group (see Lexicon.lua) comes out as one of these.
-- rules = sound changes on every other word. interject = little asides dropped in at commas.
local ADDON, ns = ...

local function Split(v)
  local t = {}
  for x in v:gmatch("[^|]+") do t[#t + 1] = x end
  return t
end
function ns.Bank(key, b)
  local d = ns.ACCENTS[key]
  if not d then return end
  d.lex = d.lex or {}
  for g, v in pairs(b.lex or {}) do d.lex[g] = Split(v) end
  if b.rules then d.rules = b.rules end
  if b.interject then d.interject = Split(b.interject) end
  if b.interjectChance then d.interjectChance = b.interjectChance end
  if b.lexChance then d.lexChance = b.lexChance end
  for k, v in pairs(b.words or {}) do d.words = d.words or {}; d.words[k] = v end
  for k, v in pairs(b.phrases or {}) do d.phrases = d.phrases or {}; d.phrases[k] = v; d._index = nil end
end
local Bank = ns.Bank

---------------------------------------------------------------------------
Bank("orc", {
  lex = {
    friend = "warrior|brother|blood-kin|battle-brother", friends = "warriors|brothers|blood-kin|warband|clan",
    enemy = "foe|enemy|weakling|prey", enemies = "foes|enemies|weaklings|prey",
    mob = "beast|prey|weakling|thing", mobs = "beasts|prey|weaklings|things",
    boss = "big one|warlord|chief|big brute", bosses = "big ones|warlords|chiefs",
    noob = "peon|whelp|runt|weakling", idiot = "fool|peon|fat-head|rock-brain", idiots = "fools|peons|rock-brains",
    leader = "chieftain|warchief|leader", kid = "whelp|pup|runt", man = "warrior|male|brute", woman = "warrior|she-orc|female",
    good = "strong|mighty|good|worthy|fierce", bad = "weak|puny|bad|shameful|soft",
    big = "big|huge|giant|mighty big", small = "puny|tiny|runty|little", strong = "mighty|strong|tough|fierce",
    weak = "puny|weak|soft|feeble", fast = "fast|quick like wolf|swift", quickly = "quick|fast|now now",
    easy = "easy|nothing|easy kill", hard = "hard|tough|hard like rock|big pain",
    funny = "funny|good laugh", stupid = "dumb|stupid|rock-brained|thick", smart = "smart|clever|cunning",
    crazy = "crazy|mad|berserk|wild", scary = "scary|frightful|creepy",
    tired = "tired|weary|worn out", hungry = "hungry|starving|need meat", happy = "happy|glad|pleased",
    sad = "sad|gloomy|low", angry = "angry|raging|furious|mad like boar",
    rich = "rich|full of gold", ugly = "ugly|ugly like kobold|hideous", pretty = "pretty|fine|good-looking",
    old = "old|ancient|grey", new = "new|fresh", expensive = "costly|too much gold|pricey",
    broken = "broken|busted|smashed", boring = "boring|dull|sleepy", important = "important|big deal",
    very = "much|very|mighty|big", maybe = "maybe|perhaps", probably = "probably|maybe", definitely = "for sure|yes|always",
    money = "gold|coin|shinies", food = "meat|grub|food|roast", drink = "grog|drink|swill|ale",
    weapon = "axe|blade|weapon|cleaver", weapons = "axes|blades|weapons", armor = "armor|mail|plate",
    gear = "gear|loot|spoils", stuff = "stuff|junk|things", quest = "task|mission|job|hunt", quests = "tasks|jobs|hunts",
    dungeon = "cave|dungeon|hole|pit", dungeons = "caves|dungeons|holes", home = "hut|home|camp",
    city = "town|city|Orgrimmar", fight = "fight|battle|brawl", fights = "fights|battles|brawls",
    problem = "problem|trouble|pain", magic = "magic|mana|magic juice", mount = "wolf|mount|beast",
    kill = "smash|crush|kill|slay|break", killed = "smashed|crushed|killed|slew", killing = "smashing|crushing|killing",
    attack = "smash|attack|charge", help = "help|aid", go = "go|march",
    want = "want|need", think = "think|say", know = "know", look = "look",
    get = "get|take|grab", buy = "buy|trade for", make = "make|forge|build",
    love = "love|like much", hate = "hate|despise|loathe", farm = "farm|grind|hunt", farming = "farming|grinding|hunting",
    die = "die|fall", died = "died|fell", leave = "leave|go", lose = "lose", win = "win|conquer",
    hello = "throm-ka|lok'tar|hail", yes = "zug zug|dabu|yes", no = "no|never|nah",
    damn = "grr|blast|curse it|bah", wow = "grr|whoa|by Doomhammer", lol = "har har|ha|haha|har",
    but = "but", because = "because|cause",
  },
  rules = {
    { "^th(%a)", "d%1", min = 3, chance = 0.4 },
  },
  interject = "grr|hmph|har|by the ancestors",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("troll", {
  lex = {
    friend = "mon|bruddah|friend|my mon", friends = "mon|bruddahs|my people|da tribe",
    enemy = "enemy|fool|dat one", enemies = "enemies|fools|dem",
    mob = "beastie|critter|ting|creature", mobs = "beasties|critters|tings|creatures",
    boss = "big boss|big mon|chief|big one", noob = "lil' one|baby troll|newbie mon",
    idiot = "fool|crazy mon|dummy", idiots = "fools|dummies",
    kid = "lil' one|youngin'", man = "mon", woman = "lady|sista",
    good = "good|nice|irie|real good|sweet", bad = "bad|no good|nasty|cursed",
    big = "big|huge|mighty big|massive", small = "lil'|tiny|wee", strong = "strong|tough|mighty",
    weak = "weak|soft|puny", fast = "fast|quick|zippy", quickly = "quick quick|real quick|fast",
    easy = "easy|no problem|easy mon", hard = "hard|tough|real tough",
    funny = "funny|crazy funny", stupid = "dumb|crazy|silly", smart = "smart|wise|clever",
    crazy = "crazy|loco|wild|mad", scary = "spooky|scary|creepy", tired = "tired|sleepy",
    hungry = "hungry|starvin'", happy = "happy|irie|feelin' good", sad = "sad|down|low",
    angry = "angry|mad|hot", rich = "rich|loaded", ugly = "ugly|nasty-lookin'", pretty = "pretty|fine|lovely",
    old = "old|ancient", expensive = "pricey|too much gold|crazy expensive", broken = "busted|broken|cursed",
    boring = "boring|sleepy", very = "real|very|so|mighty", maybe = "maybe|could be", probably = "prob'ly|maybe",
    definitely = "for sure|fo' sure|sure ting",
    money = "gold|coin|shiny", food = "grub|food|eats|fish", drink = "drink|rum|juice",
    weapon = "spear|weapon|blade|axe", gear = "gear|loot|goodies", stuff = "stuff|tings|junk",
    quest = "job|quest|task", quests = "jobs|quests", dungeon = "cave|dungeon|hole", dungeons = "caves|dungeons",
    home = "hut|home|village", city = "city|big town", fight = "fight|scrap|rumble",
    problem = "problem|trouble|bad mojo", magic = "voodoo|mojo|magic|juju", mount = "raptor|mount",
    luck = "mojo|luck", time = "time",
    kill = "kill|get|take down|hex", killed = "killed|got|took down", attack = "hit|attack",
    help = "help", want = "want", think = "tink|figure", know = "know", look = "look|peep",
    get = "get|grab", love = "love|dig", hate = "hate|can't stand", farm = "farm|grind",
    farming = "farmin'|grindin'", die = "die|go see da spirits", died = "died|went ta see da spirits",
    hello = "hey mon|wassup|yo mon", yes = "ya mon|ya|yeah mon", no = "nah|no way|nah mon",
    damn = "dang|oh mon|curses", wow = "whoa mon|oh mon|by da loa", lol = "hehe|haha|ha mon",
    because = "'cause|cuz",
  },
  rules = {
    { "^th", "d", min = 2, chance = 0.85, stop = true },
    { "th$", "t", min = 2, chance = 0.7 },
    { "^to$", "ta", min = 2, chance = 0.6 },
    { "^for$", "fo'", min = 3, chance = 0.5 },
    { "er$", "a", min = 3, chance = 0.4 },
  },
  interject = "mon|ya mon|hehe",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("tauren", {
  lex = {
    friend = "friend|little one|kin|brother", friends = "friends|little ones|kin|herd|tribe",
    enemy = "foe|enemy|lost soul", enemies = "foes|enemies|lost souls",
    mob = "beast|creature|spirit|thing", mobs = "beasts|creatures|wild things",
    boss = "great beast|chieftain|old one|great foe", bosses = "great beasts|old ones",
    noob = "calf|young one|little calf", idiot = "foolish one|lost calf|silly one", idiots = "foolish ones|lost calves",
    leader = "chieftain|elder|leader", kid = "calf|young one", man = "brave|bull", woman = "cow|sister",
    good = "good|blessed|fine|worthy", bad = "bad|unwise|troubling|unbalanced",
    big = "big|great|mighty|vast", small = "small|little|humble", strong = "strong|mighty|sturdy as stone",
    weak = "weak|frail|tender", fast = "swift|fast|quick as the wind", quickly = "swiftly|with haste",
    slow = "slow|patient|unhurried", slowly = "slowly|patiently",
    easy = "easy|simple|gentle", hard = "hard|trying|difficult as climbing a mesa",
    funny = "funny|amusing", stupid = "foolish|unwise|silly", smart = "wise|clever|thoughtful",
    crazy = "wild|untamed|mad as a kodo", scary = "frightful|dark|unsettling", tired = "weary|tired|heavy-hooved",
    hungry = "hungry|ready to graze", happy = "content|happy|at peace", sad = "sad|heavy-hearted",
    angry = "angry|stormy|restless", rich = "rich|blessed with plenty", ugly = "unsightly|homely",
    pretty = "beautiful|lovely|fair as the plains", old = "old|ancient|aged", new = "new|young|fresh",
    expensive = "costly|dear", broken = "broken|cracked", boring = "dull|quiet",
    very = "very|truly|greatly|deeply", maybe = "perhaps|maybe", probably = "likely|perhaps",
    definitely = "surely|truly", always = "always|ever", never = "never",
    now = "now", soon = "soon|before long", later = "later|in time",
    money = "gold|coin|trade goods", food = "food|grain|stew|meal", drink = "water|drink|spring water",
    weapon = "totem|staff|weapon|axe", weapons = "weapons|totems", armor = "hide|armor",
    gear = "gear|gifts|goods", stuff = "things|belongings", quest = "journey|task|path", quests = "journeys|tasks",
    dungeon = "cave|dark place|deep place", dungeons = "caves|dark places", home = "lodge|home|tent",
    city = "Thunder Bluff|town|the village", fight = "battle|fight|struggle", fights = "battles|struggles",
    problem = "trouble|burden|problem", magic = "magic|spirit power", mount = "kodo|mount",
    world = "world|land|Earth Mother", life = "life|path", time = "time|season",
    day = "day|sun", morning = "dawn|morning", today = "this day|today",
    kill = "hunt|kill|bring down|end", killed = "hunted|killed|brought down", killing = "hunting|killing",
    attack = "charge|attack", help = "help|aid", go = "go|walk|wander",
    going = "going|walking|wandering", want = "want|wish|seek", think = "feel|believe|think",
    know = "know|sense", see = "see|sense", look = "look|gaze",
    get = "get|gather", buy = "trade for|buy", make = "make|craft", eat = "eat|graze",
    sleep = "rest|sleep|dream", love = "love|cherish", hate = "dislike|hate",
    farm = "gather|farm", farming = "gathering|farming", die = "die|return to the earth",
    died = "died|returned to the earth", leave = "leave|depart", lose = "lose", win = "win|prevail",
    hello = "peace|well met|greetings", bye = "farewell|walk with the Earth Mother", yes = "yes|indeed|it is so",
    no = "no|it is not so", damn = "hrm|alas|by the Earth Mother", wow = "by the Earth Mother|hm|ah",
    lol = "hm hm|ha|*chuckles*", ugh = "hrm|ugh",
  },
  interject = "little one|hm|friend",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("forsaken", {
  lex = {
    friend = "fellow corpse|friend|ally|bone-friend", friends = "fellow corpses|allies|my rotting friends|the damned",
    enemy = "fool|enemy|living fool|breather", enemies = "fools|enemies|breathers|the living",
    mob = "fleshbag|creature|thing|meat", mobs = "fleshbags|creatures|meatbags|things",
    boss = "master|big one|tyrant", noob = "fresh corpse|newly dead|whelp",
    idiot = "fool|imbecile|wretch|maggot-brain", idiots = "fools|wretches|imbeciles",
    leader = "master|leader", kid = "brat|whelp", man = "breather|man|corpse", woman = "woman|banshee",
    good = "good|acceptable|tolerable|delightfully grim|fine", bad = "bad|wretched|vile|pathetic|rotten",
    big = "big|bloated|huge|massive", small = "small|scrawny|tiny|meager", strong = "strong|unbreakable|relentless",
    weak = "weak|frail|pathetic|brittle", fast = "fast|swift", quickly = "quickly|swiftly",
    easy = "easy|trivial|child's play", hard = "hard|cruel|torturous", funny = "funny|darkly amusing",
    stupid = "stupid|brainless|witless", smart = "clever|cunning", crazy = "mad|deranged|unhinged",
    scary = "delightful|frightful|creepy", tired = "tired|drained", hungry = "hungry|ravenous|starved",
    happy = "pleased|almost happy|grimly pleased", sad = "gloomy|miserable|bleak", angry = "furious|seething|bitter",
    rich = "rich|wealthy", ugly = "beautiful|hideous|rotten", pretty = "disgustingly pretty|too pretty|unbearably pretty",
    old = "old|ancient|decrepit", new = "new|fresh", expensive = "costly|extortionate",
    broken = "broken|shattered|rotted", boring = "boring|dull as a grave", very = "very|terribly|dreadfully|truly",
    maybe = "perhaps|maybe", probably = "probably|no doubt", definitely = "surely|without doubt",
    money = "gold|coin", food = "food|flesh|meat|rations", drink = "drink|potion|swill|bile",
    weapon = "blade|weapon|dagger|scythe", weapons = "blades|weapons", armor = "armor|rags",
    gear = "gear|plunder|grave goods", stuff = "stuff|trinkets|leftovers",
    quest = "errand|task|chore", quests = "errands|tasks|chores", dungeon = "crypt|tomb|dungeon|pit",
    dungeons = "crypts|tombs|dungeons", home = "grave|crypt|home", city = "the Undercity|the city|town",
    fight = "fight|slaughter|battle", fights = "fights|slaughters", problem = "problem|plague|nuisance",
    magic = "magic|dark arts|mana", mount = "skeletal horse|mount|steed", life = "unlife|life|existence",
    world = "world|graveyard", time = "time", night = "night", day = "day|wretched day",
    kill = "kill|slaughter|end|bury", killed = "killed|slaughtered|buried|ended", killing = "killing|slaughtering|burying",
    attack = "strike|attack", help = "help|aid", go = "go|shamble|creep",
    going = "going|shambling", want = "want|desire", think = "think|suspect",
    know = "know", see = "see", look = "look", get = "get|take", buy = "buy", make = "make|brew",
    eat = "eat|devour|feast", sleep = "rest|sleep", love = "tolerate|love|enjoy", hate = "hate|despise|loathe",
    die = "die|perish|rot", died = "died|perished|rotted", lose = "lose", win = "win",
    farm = "farm|harvest", farming = "farming|harvesting",
    hello = "greetings|hail|ah, you", bye = "farewell|until death", yes = "yes|indeed|very well",
    no = "no|never|absolutely not", damn = "curses|blast|rot", wow = "how grim|oh|well well",
    lol = "heh|heh heh|*rattles*|hah",
  },
  interject = "heh|breather|*rattles*|hmph",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("human", {
  lex = {
    friend = "friend|good fellow|companion|comrade", friends = "friends|good people|companions|comrades|fellows",
    enemy = "foe|villain|scoundrel", enemies = "foes|villains|scoundrels",
    mob = "beast|brute|wretch|creature", mobs = "beasts|brutes|wretches|creatures",
    boss = "villain|fiend|brute|tyrant", bosses = "villains|fiends",
    noob = "squire|novice|greenhorn", idiot = "fool|buffoon|dolt|simpleton", idiots = "fools|buffoons|dolts",
    leader = "commander|captain|leader", kid = "lad|child|youngster", man = "gentleman|fellow|sir", woman = "lady|madam",
    good = "splendid|admirable|fine|excellent|most agreeable|capital", bad = "dreadful|regrettable|deplorable|ghastly|unfortunate",
    big = "grand|great|large|considerable", small = "modest|small|slight", strong = "stalwart|mighty|formidable",
    weak = "feeble|frail|weak", fast = "swift|fast|brisk", quickly = "posthaste|swiftly|at once",
    easy = "effortless|simple|a trifle", hard = "arduous|difficult|trying", funny = "amusing|droll|hilarious",
    stupid = "foolish|absurd|ridiculous", smart = "clever|learned|astute", crazy = "mad|absurd|preposterous",
    scary = "fearsome|frightful|harrowing", tired = "weary|fatigued", hungry = "famished|hungry",
    happy = "delighted|pleased|glad", sad = "sorrowful|downcast|glum", angry = "cross|furious|vexed",
    rich = "wealthy|prosperous", ugly = "unsightly|ghastly|homely", pretty = "fair|lovely|handsome",
    old = "old|aged|venerable", new = "new|novel", expensive = "costly|dear|extravagant",
    broken = "broken|ruined", boring = "tedious|dull|tiresome", important = "important|of great import",
    very = "most|very|terribly|exceedingly|quite", maybe = "perhaps|mayhap", probably = "likely|in all likelihood",
    definitely = "certainly|undoubtedly|indeed",
    money = "gold|coin|funds|coin purse", food = "supper|food|provisions|fare", drink = "wine|ale|drink|refreshment",
    weapon = "sword|blade|weapon", weapons = "swords|arms|weapons", armor = "armor|plate",
    gear = "equipment|gear|arms", stuff = "belongings|wares|things", quest = "quest|errand|duty|endeavor",
    quests = "quests|duties|errands", dungeon = "dungeon|keep|crypt", dungeons = "dungeons|keeps|catacombs",
    home = "manor|home|estate", city = "Stormwind|town|the city", fight = "battle|skirmish|duel", fights = "battles|skirmishes",
    problem = "predicament|problem|difficulty", magic = "arcane|magic", mount = "steed|horse|charger",
    kill = "vanquish|slay|defeat|dispatch", killed = "vanquished|slew|defeated|dispatched", killing = "vanquishing|slaying|defeating",
    attack = "strike|assail|charge", help = "assist|aid|help", go = "go|proceed|venture",
    going = "going|proceeding|venturing", want = "wish|desire|want", think = "believe|think|daresay",
    know = "know", look = "look|observe", get = "obtain|acquire|get", buy = "purchase|buy", sell = "sell",
    make = "make|craft", eat = "dine|eat", sleep = "retire|rest|sleep", love = "adore|cherish|love",
    hate = "detest|loathe|despise", farm = "gather|farm", farming = "gathering|farming",
    die = "perish|fall|die", died = "perished|fell|died", leave = "depart|leave", lose = "lose", win = "triumph|prevail|win",
    hello = "good day|greetings|well met", bye = "farewell|good day", yes = "yes|indeed|quite so",
    no = "no|certainly not|I think not", okay = "very well|certainly|as you wish",
    damn = "blast|confound it|good heavens", wow = "good heavens|my word|by the Light",
    lol = "ha ha|how amusing|*chuckles*", ugh = "dear me|ugh", but = "but|however|yet", because = "because|for",
  },
  interject = "good sir|I daresay|by the Light|mind you",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("dwarf", {
  lex = {
    friend = "lad|lass|friend|me friend", friends = "lads|friends|lads an' lasses|me friends",
    enemy = "foe|scoundrel|enemy", enemies = "foes|scoundrels|enemies",
    mob = "beastie|beast|brute|critter", mobs = "beasties|beasts|brutes|critters",
    boss = "big brute|big beastie|great ugly lump", noob = "wee lad|beardling|greenbeard",
    idiot = "eejit|numpty|daftie|fool", idiots = "eejits|numpties|fools",
    kid = "bairn|wee one", man = "lad|fella", woman = "lass|lassie",
    good = "grand|braw|bonny|good|fine", bad = "rotten|awful|manky|bad|dreadful",
    big = "muckle|big|huge|great", small = "wee|small|tiny", strong = "strong|stout|tough as stone",
    weak = "weak|feeble|soft", fast = "quick|fast|nippy", quickly = "quick|sharpish|right quick",
    easy = "easy|nae bother|simple", hard = "hard|tough|a right pain",
    funny = "funny|a right laugh", stupid = "daft|stupid|thick", smart = "clever|canny|sharp",
    crazy = "mad|daft|bonkers", scary = "scary|grim|eerie", tired = "knackered|tired|wabbit",
    hungry = "starvin'|hungry|peckish", happy = "chuffed|happy|glad", sad = "glum|sad|down",
    angry = "ragin'|furious|fumin'", rich = "rich|loaded", ugly = "ugly|manky|hideous",
    pretty = "bonny|pretty|lovely", old = "auld|old|ancient", new = "new|shiny",
    expensive = "dear|pricey|a king's ransom", broken = "broken|knackered|busted", boring = "dull|borin'",
    very = "right|awful|pure|very|dead", maybe = "maybe|mebbe|aye, perhaps", probably = "prob'ly|likely",
    definitely = "aye|for certain|nae doubt", always = "always|aye always", never = "never|ne'er",
    money = "gold|coin|siller", food = "grub|food|vittles|roast", drink = "ale|stout|drink|brew|pint",
    weapon = "hammer|axe|blade|weapon", weapons = "hammers|axes|weapons", armor = "armor|plate|mail",
    gear = "gear|kit|loot", stuff = "stuff|gubbins|bits an' bobs", quest = "job|task|quest", quests = "jobs|tasks|quests",
    dungeon = "mine|cave|tunnel|dungeon", dungeons = "mines|caves|tunnels", home = "hearth|home|hall",
    city = "Ironforge|town|the city", fight = "brawl|scrap|fight|rammy", fights = "brawls|scraps|fights",
    problem = "bother|problem|trouble", magic = "magic|runes", mount = "ram|mount",
    kill = "flatten|smash|kill|squash|batter", killed = "flattened|smashed|killed|squashed", killing = "flattenin'|smashin'|killin'",
    attack = "clobber|attack|hit", help = "help", go = "go|head", want = "want|fancy", think = "reckon|think",
    know = "ken|know", look = "look|have a gander", get = "get|grab", buy = "buy",
    make = "forge|make|craft", eat = "eat|scoff", sleep = "kip|sleep|rest", love = "love",
    hate = "hate|cannae stand", farm = "mine|farm|dig", farming = "minin'|farmin'|diggin'",
    die = "die|snuff it", died = "died|snuffed it", lose = "lose", win = "win",
    hello = "hullo|aye|well met", bye = "bye|cheerio|safe travels", yes = "aye|yes|aye aye",
    no = "nae|no|nae chance", damn = "blast|och|bah|crivens", wow = "och|blimey|by me beard",
    lol = "har|haha|hah", but = "but", because = "'cause|because",
  },
  rules = {
    { "^you$", "ye", min = 2, chance = 0.7 },
    { "^your$", "yer", min = 2, chance = 0.7 },
    { "^my$", "me", min = 2, chance = 0.8 },
    { "^don't$", "dinnae", min = 3, chance = 0.6 },
    { "^can't$", "cannae", min = 2, chance = 0.7 },
    { "^won't$", "willnae", min = 3, chance = 0.5 },
    { "^no$", "nae", min = 3, chance = 0.5 },
    { "^know$", "ken", min = 3, chance = 0.4 },
  },
  interject = "aye|lad|och",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("gnome", {
  lex = {
    friend = "friend|pal|colleague|lab partner", friends = "friends|folks|colleagues|test subjects",
    enemy = "foe|obstacle|variable", enemies = "foes|obstacles|variables",
    mob = "specimen|creature|thingamajig|subject", mobs = "specimens|creatures|subjects",
    boss = "big specimen|prime variable|main problem", noob = "apprentice|intern|new model",
    idiot = "dunderhead|nincompoop|dingbat|silly-billy", idiots = "dunderheads|nincompoops",
    leader = "chief engineer|leader|project lead", kid = "little one|tyke", man = "fellow|chap",
    good = "excellent|fantastic|optimal|top-notch|delightful", bad = "faulty|defective|suboptimal|terrible",
    big = "huge|enormous|gargantuan|big", small = "tiny|compact|itty-bitty|miniature", strong = "powerful|high-output|sturdy",
    weak = "underpowered|flimsy|weak", fast = "speedy|zippy|turbo-charged", quickly = "speedily|in a jiffy|lickety-split",
    slow = "sluggish|slow", easy = "simple|elementary|a cinch", hard = "complicated|difficult|tricky",
    funny = "hilarious|funny", stupid = "silly|illogical|nonsensical", smart = "brilliant|ingenious|clever",
    crazy = "bonkers|wacky|zany", scary = "scary|alarming", tired = "sleepy|tired",
    hungry = "low on fuel|hungry", happy = "thrilled|delighted|giddy", sad = "glum|sad",
    angry = "steamed|overheated|cross", rich = "well-funded|rich", ugly = "ugly|unaesthetic",
    pretty = "pretty|elegant|beautifully engineered", old = "old|outdated|obsolete", new = "new|new-model|cutting-edge",
    expensive = "pricey|over budget|expensive", broken = "broken|malfunctioning|on the fritz|kaput",
    boring = "boring|tedious", very = "super|extremely|wildly|positively|super-duper",
    maybe = "possibly|hypothetically|maybe", probably = "probably|statistically likely",
    definitely = "definitely|with certainty|guaranteed",
    money = "gold|funding|coin", food = "snacks|food|fuel", drink = "drink|coolant|juice",
    weapon = "gadget|weapon|wrench", weapons = "gadgets|weapons", armor = "plating|armor",
    gear = "gear|gizmos|equipment", stuff = "gizmos|gadgets|doohickeys|whatsits",
    quest = "project|experiment|task", quests = "projects|experiments|tasks",
    dungeon = "dungeon|test chamber|cave", dungeons = "dungeons|test chambers", home = "workshop|home|lab",
    city = "Gnomeregan|town|the city", fight = "fight|stress test|scuffle", fights = "fights|stress tests",
    problem = "malfunction|bug|technical difficulty|problem", idea = "idea|theory|hypothesis",
    magic = "magic|mana|energy", mount = "mechanostrider|mount", time = "time",
    kill = "dismantle|defeat|disassemble|neutralize", killed = "dismantled|defeated|disassembled|neutralized",
    killing = "dismantling|defeating", attack = "zap|attack", help = "help|assist",
    go = "go|zip|scoot", want = "want", think = "calculate|think|theorize",
    know = "know", look = "look|inspect|analyze", get = "get|acquire", buy = "buy|procure",
    make = "build|invent|engineer|make", eat = "eat|refuel", sleep = "recharge|sleep|power down",
    love = "love|adore", hate = "hate|can't stand", farm = "collect|farm", farming = "collecting|farming",
    die = "die|break down", died = "died|broke down", lose = "lose", win = "win|succeed",
    try = "try|attempt", trying = "trying|attempting",
    hello = "hiya|hello|greetings", bye = "bye-bye|toodles|goodbye", yes = "yes|affirmative|yes yes",
    no = "no|negative|nope", damn = "drat|oh fiddlesticks|oh bother|gears and sprockets",
    wow = "wowee|golly|whoa", lol = "tee hee|haha|hehe", but = "but|however",
  },
  interject = "technically|in theory|by my math",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
Bank("nightelf", {
  lex = {
    friend = "friend|young one|sister|brother", friends = "friends|young ones|kin|sisters and brothers",
    enemy = "foe|enemy|defiler", enemies = "foes|enemies|defilers",
    mob = "beast|creature|corrupted thing", mobs = "beasts|creatures|wild things",
    boss = "great foe|ancient evil|corrupted one", noob = "young one|sapling|initiate",
    idiot = "fool|foolish one|sapling", idiots = "fools|foolish ones",
    leader = "elder|leader|high priestess", kid = "young one|sapling", man = "man|brother", woman = "woman|sister",
    good = "good|graceful|blessed|beautiful|serene", bad = "bad|corrupted|tainted|troubling",
    big = "great|vast|immense", small = "small|slight|little", strong = "strong|mighty|unyielding",
    weak = "weak|frail|fragile", fast = "swift|fleet|fast", quickly = "swiftly|quickly|like the wind",
    slow = "slow|patient", slowly = "slowly|patiently", easy = "easy|simple|effortless", hard = "hard|trying|daunting",
    funny = "amusing|curious", stupid = "foolish|unwise|thoughtless", smart = "wise|clever|insightful",
    crazy = "mad|wild|reckless", scary = "dreadful|ominous|haunting", tired = "weary|tired",
    hungry = "hungry", happy = "joyful|content|at peace", sad = "sorrowful|melancholy|heavy-hearted",
    angry = "wrathful|angry|furious", rich = "rich|blessed", ugly = "ugly|unsightly|corrupted",
    pretty = "beautiful|graceful|radiant", old = "ancient|old|timeless", new = "new|young",
    expensive = "costly|precious", broken = "broken|shattered", boring = "dull|tedious",
    very = "very|truly|deeply|most", maybe = "perhaps|maybe", probably = "likely|perhaps",
    definitely = "surely|certainly", always = "always|eternally", never = "never",
    now = "now", soon = "soon|before the moon rises", later = "later|in time",
    money = "gold|coin", food = "food|moonberries|fruit|nourishment", drink = "drink|cup of moonwell water|cup of water",
    weapon = "glaive|blade|bow|weapon", weapons = "glaives|blades|weapons", armor = "armor|leathers",
    gear = "gear|relics", stuff = "things|belongings|trinkets", quest = "task|path|calling", quests = "tasks|callings",
    dungeon = "barrow|dark place|ruin", dungeons = "barrows|dark places|ruins", home = "home|grove|Darnassus",
    city = "Darnassus|town", fight = "battle|fight|struggle", fights = "battles|struggles",
    problem = "problem|shadow|trouble", magic = "magic|nature's power|druidic arts", mount = "nightsaber|mount",
    world = "world|forest|Azeroth", day = "day|sunlight", time = "time|ages",
    life = "life|eternity", tonight = "tonight|beneath the moon",
    kill = "slay|cleanse|end|kill", killed = "slew|cleansed|ended|killed", killing = "slaying|cleansing|killing",
    attack = "strike|attack", help = "aid|help", go = "go|travel|journey",
    going = "going|journeying", want = "wish|seek|want", think = "believe|sense|think",
    know = "know", see = "see|perceive", look = "look|gaze",
    get = "get|gather", buy = "buy|trade for", make = "make|craft|shape",
    sleep = "rest|dream|slumber", love = "love|treasure", hate = "despise|hate",
    die = "die|fall|perish", died = "died|fell|perished", leave = "leave|depart", lose = "lose", win = "win|prevail",
    farm = "gather|farm", farming = "gathering|farming",
    hello = "Ishnu-alah|greetings|well met", bye = "farewell|Elune be with you", yes = "yes|indeed|it is so",
    no = "no|it is not so", damn = "alas|by Elune|curses", wow = "by Elune|ah|remarkable",
    lol = "*smiles*|hm hm|*laughs softly*",
  },
  interject = "young one|by Elune|hm",
  interjectChance = { 0, 0.15, 0.3 },
})

---------------------------------------------------------------------------
-- the game words and the way people talk, per accent
---------------------------------------------------------------------------
Bank("orc", { lex = {
  healer = "shaman|healer|mender", healers = "shamans|healers", tank = "shield-wall|meat wall|tank", group = "warband|group|pack",
  guild = "clan|guild", zone = "land|territory", pet = "beast|pet", elite = "big brute|elite", spiders = "spiders|eight-legs",
  wipe = "slaughter|wipe", wiped = "all died|got slaughtered", drop = "drop|give", dropped = "dropped|gave",
  aggro = "rage|anger", rogue = "sneaky one|coward|rogue", mage = "magic man|spell-flinger", hunter = "hunter|beast-friend",
  priest = "holy one|priest", paladin = "pink-skin knight|paladin", warlock = "demon-caller|warlock", druid = "tree-hugger|druid",
  honestly = "for true|truly|me say true", obviously = "of course|everyone know", annoying = "annoying|make me angry",
  dangerous = "dangerous|deadly", ridiculous = "dumb|stupid", finally = "at last|finally", almost = "almost",
  scared = "scared|frightened", nobody = "no one|nobody", anybody = "anyone|any warrior",
}})
Bank("troll", { lex = {
  healer = "witch doctor|healer|mojo mon", healers = "witch doctors|healers", tank = "big tank mon|tank", group = "group|tribe",
  guild = "tribe|guild", zone = "jungle|place|zone", pet = "pet|critter friend", elite = "big nasty|elite", spiders = "spiders|creepy crawlies",
  wipe = "wipe", wiped = "all went ta see da spirits|wiped", aggro = "rage|anger", rogue = "sneaky mon|rogue", mage = "magic mon|mage",
  hunter = "hunter|headhunter", priest = "priest|holy mon", druid = "druid|animal mon", warlock = "warlock|demon mon",
  honestly = "fo' real|truly|no lie", obviously = "obviously|everybody know", annoying = "annoyin'|buggin' me",
  dangerous = "dangerous|deadly", ridiculous = "crazy|ridiculous", finally = "finally|at last", almost = "almost|nearly",
  scared = "spooked|scared", nobody = "nobody|no mon", anybody = "anybody|any mon",
}})
Bank("tauren", { lex = {
  healer = "healer|mender|spirit-walker", healers = "healers|menders", tank = "shield|tank|stalwart one", group = "herd|group|band",
  guild = "tribe|guild", zone = "land|plains|lands", pet = "beast companion|pet|companion", elite = "great beast|elite",
  spider = "spider|crawling one", spiders = "spiders|crawling ones", wipe = "fall together|wipe", wiped = "fell together|wiped",
  drop = "give|drop", dropped = "gave up|dropped", aggro = "anger|wrath", rogue = "shadow-walker|rogue", mage = "spell-weaver|mage",
  hunter = "hunter", priest = "priest", druid = "druid|keeper of the grove", warrior = "brave|warrior",
  honestly = "truly|in truth|honestly", obviously = "plainly|clearly", annoying = "troubling|trying", dangerous = "perilous|dangerous",
  ridiculous = "foolish|absurd", finally = "at last|finally", almost = "nearly|almost", together = "together|as one herd",
  whole = "whole|entire", scared = "uneasy|afraid", ready = "ready|prepared", late = "late", early = "early|at first light",
  minute = "moment|breath", minutes = "moments|breaths", hour = "while|hour", hours = "long hours|hours",
  nobody = "no one", anybody = "anyone|any friend", repair = "mend|repair",
}})
Bank("forsaken", { lex = {
  healer = "healer|flesh-mender|bone-setter", healers = "healers|flesh-menders", tank = "meat shield|tank", tanks = "meat shields|tanks",
  group = "group|band of corpses|party", guild = "guild|cabal", zone = "wasteland|zone|land", pet = "pet|ghoul|minion",
  elite = "elite|big corpse", spider = "spider|little friend", spiders = "spiders|little friends",
  wipe = "massacre|wipe", wiped = "all perished|wiped|got massacred", drop = "drop|cough up", dropped = "dropped|coughed up",
  aggro = "hatred|aggro", rogue = "rogue|knife-in-the-dark", mage = "mage|spellslinger", hunter = "hunter", priest = "priest|shadow priest",
  paladin = "paladin|Light-licker", warrior = "warrior|brute", druid = "druid|tree-lover",
  honestly = "frankly|honestly|truthfully", obviously = "obviously|clearly", annoying = "irritating|tiresome|insufferable",
  dangerous = "deadly|lethal|delightfully deadly", ridiculous = "absurd|pathetic", finally = "finally|at long last",
  almost = "nearly|almost", together = "together", whole = "whole|entire", scared = "afraid|scared",
  ready = "ready", late = "late", early = "early", minute = "moment|minute", minutes = "moments|minutes",
  hour = "hour", hours = "hours|wretched hours", nobody = "nobody|not a soul", anybody = "anybody|any soul",
  repair = "patch up|repair", sick = "diseased|sick", annoyed = "irritated|annoyed",
}})
Bank("human", { lex = {
  healer = "healer|cleric|physician", healers = "healers|clerics", tank = "shieldbearer|vanguard|tank", tanks = "shieldbearers|tanks",
  group = "party|company|fellowship", guild = "guild|order", zone = "region|province|land", pet = "companion|pet|hound",
  elite = "champion|elite", spider = "spider|vile spider", spiders = "spiders|vile spiders", wipe = "rout|wipe",
  wiped = "were routed|fell to a man", drop = "yield|drop", dropped = "yielded|dropped", aggro = "ire|wrath",
  repair = "mend|repair", rogue = "rogue|cutpurse", mage = "magus|mage", hunter = "huntsman|hunter", priest = "priest|cleric",
  warrior = "warrior|soldier|man-at-arms", paladin = "paladin|holy knight", warlock = "warlock|heretic",
  honestly = "truly|in all honesty|frankly", obviously = "obviously|plainly|evidently", annoying = "vexing|irksome|tiresome",
  dangerous = "perilous|dangerous|treacherous", ridiculous = "preposterous|absurd|ridiculous", finally = "at long last|finally",
  almost = "nearly|almost", together = "together|as one", whole = "entire|whole", scared = "afraid|frightened",
  ready = "prepared|ready", minute = "moment|minute", minutes = "moments|minutes", hour = "hour", hours = "hours",
  nobody = "no one|not a soul", anybody = "anyone|any soul", annoyed = "vexed|irritated", sick = "ill|unwell",
}})
Bank("dwarf", { lex = {
  healer = "healer|medic|priest lad", healers = "healers", tank = "shield|tank|anvil", group = "group|lot",
  guild = "guild|clan", zone = "land|zone|parts", pet = "pet|beastie", elite = "big beastie|elite", spider = "spider|creepy wee beastie",
  spiders = "spiders|creepy wee beasties", wipe = "wipe|right massacre", wiped = "got flattened|wiped", aggro = "temper|aggro",
  rogue = "sneak|rogue", mage = "wizard|mage", hunter = "hunter|rifleman", priest = "priest", warrior = "warrior|fighter",
  paladin = "paladin", honestly = "honest|truth be told|honestly", obviously = "obviously|plain as day",
  annoying = "annoyin'|a right pain", dangerous = "dangerous|deadly", ridiculous = "daft|ridiculous|mad",
  finally = "at last|finally", almost = "near|nearly|almost", scared = "feart|scared", minute = "minute|tick",
  minutes = "minutes", nobody = "naebody|nobody", anybody = "anybody|any lad", repair = "fix|mend|repair",
  ready = "ready", whole = "whole|hale",
}})
Bank("gnome", { lex = {
  healer = "healer|medic|repair specialist", healers = "healers|medics", tank = "tank|armored unit|tank unit", group = "group|team",
  guild = "guild|society|research club", zone = "zone|sector|area", pet = "pet|companion bot|mechanical friend",
  elite = "elite|upgraded model", spider = "spider|arachnid", spiders = "spiders|arachnids", wipe = "total system failure|wipe",
  wiped = "had a total system failure|wiped", drop = "drop|output", dropped = "dropped|output", aggro = "aggro|threat level",
  repair = "repair|recalibrate|tune up", rogue = "rogue|stealth unit", mage = "mage|arcane specialist", hunter = "hunter|tracker",
  priest = "priest|healer", warlock = "warlock|shady caster", warrior = "warrior|melee unit",
  honestly = "honestly|scientifically speaking|technically", obviously = "obviously|by simple deduction",
  annoying = "annoying|inefficient|bothersome", dangerous = "dangerous|hazardous|volatile", ridiculous = "ridiculous|illogical|absurd",
  finally = "finally|at long last", almost = "almost|nearly", together = "together|in tandem",
  whole = "whole|entire", scared = "scared|spooked", ready = "ready|calibrated|online", minute = "minute|tick",
  minutes = "minutes|cycles", hour = "hour|cycle", hours = "hours|cycles", nobody = "nobody", anybody = "anybody",
}})
Bank("nightelf", { lex = {
  healer = "healer|priestess|druid", healers = "healers|priestesses", tank = "guardian|bear|tank", group = "group|circle|company",
  guild = "guild|order|circle", zone = "land|forest|realm", pet = "companion|pet|nightsaber", elite = "ancient beast|elite",
  spider = "spider|webspinner", spiders = "spiders|webspinners", wipe = "fall|wipe", wiped = "fell together|wiped",
  aggro = "wrath|fury", rogue = "shadow|rogue", mage = "mage|arcanist", hunter = "huntress|hunter|sentinel", priest = "priestess|priest",
  druid = "druid|shapeshifter", warrior = "warrior|sentinel", honestly = "truly|in truth|honestly", obviously = "plainly|clearly",
  annoying = "tiresome|troubling", dangerous = "perilous|dangerous", ridiculous = "absurd|foolish", finally = "at last|finally",
  almost = "nearly|almost", together = "together|as one", whole = "whole|entire", scared = "afraid|uneasy", ready = "ready|prepared",
  minute = "moment|minute", minutes = "moments|minutes", hour = "hour", hours = "hours|long hours", nobody = "no one",
  anybody = "anyone", early = "early|at dawn", late = "late|deep into the night",
}})

---------------------------------------------------------------------------
-- "everyone" stays one word's worth of grammar ("everyone is ..."), and the formal ones say it in full
---------------------------------------------------------------------------
local FULL = { ["don't"] = "do not", ["can't"] = "cannot", ["won't"] = "will not", ["isn't"] = "is not",
  ["didn't"] = "did not", ["wasn't"] = "was not", ["i'm"] = "I am", ["it's"] = "it is", ["that's"] = "that is",
  ["i've"] = "I have", ["i'll"] = "I shall", ["gonna"] = "going to", ["wanna"] = "wish to", i = "I" }
Bank("orc", { lex = { everyone = "every warrior|all|everyone", everybody = "every warrior|everyone" } })
Bank("troll", { lex = { everyone = "every mon|everybody|da whole tribe", everybody = "every mon|everybody" } })
Bank("tauren", { lex = { everyone = "everyone|every friend|the whole herd" }, words = FULL })
Bank("forsaken", { lex = { everyone = "every living fool|everyone|every last soul" }, words = { fun = "morbid fun" } })
Bank("human", { phrases = { ["because of"] = "on account of" }, lex = { everyone = "everyone|one and all|every good soul" }, words = FULL })
Bank("dwarf", { lex = { everyone = "everyone|every lad an' lass|the lot o' ye" } })
Bank("gnome", { phrases = { ["tired of"] = "done with", ["want to"] = "want to" }, lex = { everyone = "everyone|every single one|the whole team" } })
Bank("nightelf", { lex = { everyone = "everyone|every one of you|all of you" }, words = FULL })

-- an accent's old one-word swaps join its pools, so they add variety instead of always winning
local G = ns.Engine.WORD_GROUP
for _, key in ipairs(ns.ORDER) do
  local d = ns.ACCENTS[key]
  if d.lex and d.words then
    for k, v in pairs(d.words) do
      local g = G[k]
      local pool = g and d.lex[g]
      if pool and k ~= "i" then
        for _, x in ipairs(type(v) == "table" and v or { v }) do
          local have = false
          for _, y in ipairs(pool) do if y == x then have = true end end
          if not have then pool[#pool + 1] = x end
        end
        d.words[k] = nil
      end
    end
  end
end

---------------------------------------------------------------------------
-- from real guild chat: swears, "sucks", ding, DCs, leveling, faction talk
---------------------------------------------------------------------------
Bank("orc", { lex = {
  swear = "dung|filth", swearing = "blasted|cursed|stupid", sucks = "is weak|stinks like kobold|is shame",
  kinda = "little|bit", hope = "hope|pray to ancestors", disconnected = "dropped|yanked",
  kicked = "thrown out|kicked", leveling = "getting stronger|leveling", horde = "Horde|mighty Horde", alliance = "pink-skins|Alliance dogs",
  character = "warrior|fighter", server = "realm|world" } })
Bank("troll", { lex = {
  swear = "junk|mess", swearing = "cursed|crazy|dang", sucks = "be bad juju|stinks, mon|be no good",
  kinda = "kinda|lil' bit", hope = "hope|pray ta da loa",
  disconnected = "cut|dropped", kicked = "kicked|tossed out", leveling = "levelin'|gettin' stronger",
  alliance = "Alliance|da pink ones", character = "toon|troll", server = "realm" } })
Bank("tauren", { lex = {
  swear = "dung|mess", swearing = "troublesome|wretched", sucks = "is unfortunate|is troubling|is a heavy burden",
  kinda = "somewhat|a little", hope = "hope|pray", disconnected = "cut|dropped",
  kicked = "cast out|sent away", leveling = "growing|walking the path", alliance = "the Alliance|our Alliance cousins",
  character = "spirit|character", server = "realm|land" } })
Bank("forsaken", { lex = {
  swear = "rot|filth", swearing = "wretched|accursed|rotten", sucks = "is wretched|reeks|is deliciously awful",
  kinda = "somewhat|rather", hope = "hope|dare to hope", disconnected = "severed|dropped",
  kicked = "cast out|discarded", leveling = "growing deadlier|leveling", alliance = "the living Alliance|Alliance",
  character = "corpse|character", server = "realm|graveyard" } })
Bank("human", { lex = {
  swear = "rubbish|nonsense", swearing = "blasted|confounded|wretched", sucks = "is dreadful|is most unfortunate|is ghastly",
  kinda = "rather|somewhat", hope = "hope|pray", disconnected = "severed|dropped",
  kicked = "expelled|dismissed", leveling = "training|leveling", horde = "the Horde|the savage Horde", alliance = "the Alliance|the noble Alliance",
  character = "hero|character", server = "realm|kingdom" } })
Bank("dwarf", { lex = {
  swear = "muck|mince", swearing = "blasted|bloody|flamin'", sucks = "is rotten|is pure mince|is a right pain",
  kinda = "a wee bit|kinda", hope = "hope|pray", disconnected = "booted|dropped",
  kicked = "booted|thrown oot", leveling = "levelin'|gettin' stronger", horde = "Horde|greenskins", alliance = "Alliance",
  character = "toon|fella", server = "realm" } })
Bank("gnome", { lex = {
  swear = "scrap|junk", swearing = "blasted|dratted|ding-dang", sucks = "is suboptimal|malfunctions|is inefficient",
  kinda = "roughly|approximately|sorta", hope = "hope|calculate", disconnected = "disconnected|unplugged",
  kicked = "ejected|kicked", leveling = "upgrading|leveling", alliance = "Alliance", character = "unit|character", server = "server|network" } })
Bank("nightelf", { lex = {
  swear = "filth|corruption", swearing = "cursed|wretched", sucks = "is troubling|is sorrowful|is ill-fated",
  kinda = "somewhat|rather", hope = "hope|pray to Elune", disconnected = "severed|dropped",
  kicked = "cast out|banished", leveling = "growing|leveling", horde = "the Horde|the brutish Horde", alliance = "the Alliance",
  character = "spirit|character", server = "realm" } })

---------------------------------------------------------------------------
-- Canon words from the race languages (warcraft.wiki.gg glossaries), always paired with plain words
---------------------------------------------------------------------------
function ns.Extend(key, x)
  local d = ns.ACCENTS[key]
  if not d then return end
  for id, lines in pairs(x.say or {}) do
    d.say = d.say or {}
    d.say[id] = d.say[id] or {}
    for _, l in ipairs(lines) do table.insert(d.say[id], l) end
  end
  for g, v in pairs(x.lex or {}) do
    d.lex = d.lex or {}
    d.lex[g] = d.lex[g] or {}
    for w in v:gmatch("[^|]+") do table.insert(d.lex[g], w) end
  end
  for _, k in ipairs({ "openers", "closers", "interject" }) do
    if x[k] then d[k] = d[k] or {}; for _, l in ipairs(x[k]) do table.insert(d[k], l) end end
  end
  d._index = nil
end
local Extend = ns.Extend

-- Orcish: Lok'tar (victory), Lok'tar ogar (victory or death), Zug zug (okay), Dabu (agreed), Throm-ka/Mok-rah/Putanni (greetings),
-- Aka'magosh (a blessing on you and yours), Gol'kosh (by my axe), Kagh (run), Lok-Narash (to arms), Mok-thorin ka (engage the enemy),
-- Lok-regar (ready for orders), Bin mog g'thazag cha (I will protect you), Ur'gora (no honor, the worst insult)
Extend("orc", {
  say = {
    greet = { "Mok-rah!", "Putanni, brothers.", "Throm-ka! Mok-rah!" },
    thanks = { "Aka'magosh. A blessing on you and yours.", "Aka'magosh, brother." },
    welcome = { "Aka'magosh.", "Is nothing. Aka'magosh." },
    run = { "Kagh! Run!", "KAGH!", "Kagh! Fall back!" },
    go = { "Lok-Narash! To arms!", "Mok-thorin ka!", "Lok'tar ogar! Victory or death!" },
    ready = { "Lok-regar. Ready for orders.", "Lok-regar!" },
    help = { "Bin mog g'thazag cha! Me protect you!", "Lok-Narash! Help me!" },
    wow = { "Gol'kosh!", "Gol'kosh! By my axe!" },
    gg = { "Lok'tar! Victory!", "Lok'tar! Good fight." },
  },
  lex = { damn = "Gol'kosh|Gol'kosh", swear = "ur'gora" },
  openers = { "Gol'kosh!", "Mok-rah." },
})

-- Zandali: Mado'ru (thanks), Taz'dingo (war cry/cheer), Ma'tuba (exclamation), Kon'sahwe (craziness), Zagota (insult),
-- Tokobo'ne (welcome), juju/mojo/loa
Extend("troll", {
  say = {
    thanks = { "Mado'ru, mon!", "Mado'ru. Respect.", "Mado'ru, ya mon." },
    go = { "Taz'dingo!", "TAZ'DINGO!", "Taz'dingo, mon! Get 'em!" },
    gg = { "Taz'dingo! Good game, mon!" },
    wow = { "Ma'tuba!", "Ma'tuba, mon!" },
    welcome = { "Tokobo'ne, mon. Anytime." },
    congrats = { "Taz'dingo! Respect, mon!" },
  },
  lex = { crazy = "kon'sahwe crazy|full of kon'sahwe", idiot = "zagota|fool", idiots = "zagotas|fools",
    luck = "juju|mojo|luck", magic = "juju|mojo|voodoo" },
  closers = { "Taz'dingo!", "Mado'ru." },
})

-- Darnassian: Ishnu-alah (good fortune to you), Elune-Adore (Elune be with you), Ande'thoras-ethil (may your troubles be diminished),
-- Shaha lor'ma (thank you), Andu-falah-dor (let balance be restored), Bandu thoribas (prepare to fight),
-- Tor ilisar'thera'nal (let our enemies beware), Fandu-dath-belore (who goes there), Shan'do (honored teacher), Thero'shan (honored student)
Extend("nightelf", {
  say = {
    greet = { "Elune-adore.", "Ishnu-alah, friend. Good fortune to you.", "Elune-adore. Elune be with you." },
    bye = { "Ande'thoras-ethil. May your troubles be diminished.", "Elune-adore." },
    thanks = { "Shaha lor'ma.", "Shaha lor'ma, friend. Thank you." },
    go = { "Andu-falah-dor!", "Tor ilisar'thera'nal! Let our enemies beware!", "Bandu thoribas!" },
    ready = { "Bandu thoribas. I am ready.", "Ready. Andu-falah-dor." },
    gg = { "Andu-falah-dor. Balance is restored.", "Well fought. Ishnu-alah." },
  },
  lex = { leader = "shan'do|elder|leader", noob = "thero'shan|young one|sapling" },
  openers = { "Fandu-dath-belore?", "Ishnu-alah." },
})

-- Taur-ahe: Nechi owachi (hello and thank you), Theia-shoush ahmen (so it will be), Ish-ne-alo por-ah (may the elders guide your days),
-- An'she (the sun), Mu'sha (the moon), Shu'halo (the tauren people)
Extend("tauren", {
  say = {
    greet = { "Nechi owachi.", "Nechi owachi, friend." },
    thanks = { "Nechi owachi. Thank you.", "Owachi, friend." },
    yes = { "Theia-shoush ahmen. So it will be.", "Theia-shoush ahmen." },
    okay = { "Theia-shoush ahmen.", "So it will be." },
    bye = { "Ish-ne-alo por-ah. May the elders guide your days.", "Ish-ne-alo por-ah." },
    goodnight = { "Rest well. Mu'sha watches over you.", "Sleep under Mu'sha's light." },
  },
  lex = { friends = "Shu'halo|friends|herd" },
  closers = { "Theia-shoush ahmen.", "Ish-ne-alo por-ah." },
})

---------------------------------------------------------------------------
-- words with more than one meaning: only swaps that fit every meaning survive
-- ("stuff" is "and stuff" and "doing stuff", not just goods; "make sense", "get on", "see you later", "look like")
---------------------------------------------------------------------------
local SAFE = {}
local DROP = { "make", "get", "see", "look", "know", "pretty", "stuff" }
for _, key in ipairs(ns.ORDER) do
  local d = ns.ACCENTS[key]
  if d.lex then
    for _, g in ipairs(DROP) do d.lex[g] = nil end
    for g, per in pairs(SAFE) do
      if per[key] then local t = {}; for w in per[key]:gmatch("[^|]+") do t[#t + 1] = w end; d.lex[g] = t end
    end
  end
  if d.words then for _, w in ipairs({ "stuff", "make", "get", "see", "look", "know" }) do d.words[w] = nil end end
  if d.more then d.more.stuff = nil end
end
-- dwarves really do say "ken" for know
ns.ACCENTS.dwarf.lex.know = { "know", "ken" }
