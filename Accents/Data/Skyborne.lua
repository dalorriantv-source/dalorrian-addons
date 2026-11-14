-- Dalorrian's Accents: the Skyborne (shen'dorei), WoW: Forever's own race. A starter accent.
-- Built from their lore: high elves of Zephras Isle in Skywall, bound to the wind spirits, ruled by a Council of Elders,
-- who greet with the winds ("Gale's greetings", "Winds be with you"), trade in windstones and scatter their dead to the winds.
local ADDON, ns = ...

local function L(v)
  if type(v) ~= "string" or not v:find("|") then return v end
  local t = {}
  for x in v:gmatch("[^|]+") do t[#t + 1] = x end
  return t
end
local d = {
  name = "Skyborne", group = "race", race = "Skyborne", faction = "Neutral", starter = true,
  icon = "Interface\\Icons\\Spell_Nature_Cyclone",
  blurb = "Light as the open sky, bound to the winds.",
  ranks = { "Fledgling", "Wind-Touched", "Skystream Walker", "Peacekeeper", "Windshaper", "Empyrean Blade", "Council Elder", "Sky-Touched" },
  say = {
    greet = "Gale's greetings!|Gale's greetings, friends.|Well met, under open skies.", bye = "Winds be with you.|May the winds guide your path.|Fair winds, friend.",
    goodnight = "Rest well. The winds will keep watch.|Sleep softly, sky-kin.", thanks = "My thanks, carried on the wind.|Thank you, friend. The winds remember.",
    welcome = "Gladly given, like a fair breeze.", sorry = "Forgive me. An ill wind took my thoughts.", yes = "Yes, as the wind wills.|Gladly.|It is so.",
    no = "No. The winds say otherwise.|I think not.", okay = "As the winds will.|So be it.", lol = "Ha! Light as a breeze!|*laughs like the wind*",
    brb = "A moment. I'll drift back soon.", back = "I've returned on the wind.", ready = "Ready. The winds are at my back.", wait = "Hold. Let the wind settle.",
    go = "To the skies!|Ride the winds!|Onward, on the gale!", oom = "My magic has scattered on the wind.", heal = "Mend me, the winds are failing me!",
    gg = "The winds favored us!|A fine victory, sky-kin.", nice = "Beautifully done.|Soaring work!", wow = "By the four winds!|Gale's breath!",
    dead = "I fall from the sky...", rez = "Lift me back to the skies.", idk = "The winds have not told me.", help = "To me, sky-kin! Help!",
    run = "Take to the wind! Retreat!", congrats = "Your wings grow stronger!", howareyou = "How fare the winds with you?",
  },
  phrases = {
    ["i think"] = "the winds tell me|I sense on the wind", ["i don't know"] = "the winds have not said", ["oh my god"] = "by the four winds",
    ["omg"] = "by the four winds", ["good luck"] = "may the winds guide your path", ["let's go"] = "to the skies|let us ride the winds",
    ["you guys"] = "you sky-kin|you all", ["right now"] = "on this very breeze", ["calm down"] = "let the wind settle", ["be careful"] = "mind the crosswinds",
    ["what the hell"] = "what ill wind is this", ["i'm tired"] = "my wings are weary", ["take care"] = "fair winds", ["have fun"] = "enjoy the breeze",
    ["a lot"] = "a great gust of", ["no way"] = "not on any wind",
  },
  lex = {
    friend = "sky-kin|friend|wind-friend", friends = "sky-kin|friends|wind-friends", enemy = "storm-bringer|foe", enemies = "storm-bringers|foes",
    mob = "beast|grounded thing", mobs = "beasts|grounded things", boss = "great storm|tempest|foe", noob = "fledgling|young one",
    idiot = "featherbrain|fool", idiots = "featherbrains|fools", leader = "elder|leader",
    good = "fair|bright|soaring|lovely", bad = "ill-winded|stormy|dreadful", big = "vast|towering", small = "slight|small", strong = "mighty|gale-strong",
    weak = "frail|windless", fast = "swift|gale-swift", quickly = "swiftly|on the wind", slow = "becalmed|slow", easy = "light as a feather|easy",
    scary = "ill-winded|stormy", happy = "light-hearted|bright", sad = "grounded|heavy-hearted", angry = "stormy|tempestuous", tired = "weary|wind-worn",
    crazy = "wind-mad|wild", beautiful = "radiant", old = "ancient|old as the winds", new = "new|fresh as a breeze",
    money = "windstones|gold", magic = "arcane winds|magic", home = "the isles|Zephras|home", city = "Valanaar|the city",
    dungeon = "deep place|dark hold", fight = "storm|battle", problem = "ill wind|trouble", mount = "hippogryph|mount", world = "the skies|the world",
    kill = "cast down|bring down|ground", killed = "cast down|brought down|grounded", die = "fall from the sky", died = "fell from the sky",
    run = "run", go = "go|drift", going = "going|drifting", wow = "by the four winds|gale's breath", lol = "ha|heh",
    hello = "Gale's greetings|well met", bye = "fair winds|winds be with you", very = "truly|most",
    honestly = "truly|on the open wind", healer = "healer|windshaper", tank = "tank|bulwark",
  },
  openers = { "Ah,", "Hm," },
  interject = { "by the winds", "sky-kin" },
  interjectChance = { 0, 0.15, 0.25 },
}
for _, f in ipairs({ "say", "lex", "phrases" }) do for k, v in pairs(d[f]) do d[f][k] = L(v) end end
ns.AddAccent("skyborne", d)
