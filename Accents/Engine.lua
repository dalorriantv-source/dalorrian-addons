-- Dalorrian's Accents: the engine. Turns a plain chat line into an accent.
-- Nothing here touches the game: it only works on text, so it can be tested outside WoW.
--
-- How a line is turned:
--   1. Protect: item links, icons, raid marks, web addresses, "quoted text", words with numbers, and the names of
--      players in your group are set aside, so nothing can break them.
--   2. Chat-speak is spelled out ("u" -> "you", "brb" -> "be right back"), so the accent rules see real words.
--   3. Phrases first, longest first: common chat lines (greetings, thanks, brb, pull, oom...) are swapped for the
--      accent's own lines, with a few versions each so it doesn't repeat.
--   4. Words: swaps ("my" -> "me"), little words dropped (Medium and up), word endings (Heavy).
--   5. Flavor: now and then an opener or a closer ("Lok'tar!").
--   6. The protected bits go back in.
-- Strength: 1 Light, 2 Medium, 3 Heavy.

local ADDON, ns = ...
ns = ns or {}
local E = {}
ns.Engine = E
ns.ACCENTS = ns.ACCENTS or {}
ns.ORDER = ns.ORDER or {}

local random = math.random
local function Pick(v)
  if type(v) == "table" then return v[random(#v)] end
  return v
end
E.Pick = Pick

function ns.AddAccent(key, def)
  def.key = key
  if not ns.ACCENTS[key] then ns.ORDER[#ns.ORDER + 1] = key end
  ns.ACCENTS[key] = def
  def._index = nil
end

---------------------------------------------------------------------------
-- What people type, spelled out (only whole words; done before the accent)
---------------------------------------------------------------------------
E.SHORT = {
  u = "you", ur = "your", ppl = "people", pls = "please", plz = "please", thx = "thanks", ty = "thanks",
  tyvm = "thanks", tysm = "thanks", np = "no problem", yw = "you're welcome", idk = "i don't know", im = "i'm",
  dont = "don't", cant = "can't", didnt = "didn't", doesnt = "doesn't", isnt = "isn't", wasnt = "wasn't", ive = "i've",
  youre = "you're", thats = "that's", whats = "what's", hows = "how's", theres = "there's", wouldnt = "wouldn't",
  couldnt = "couldn't", shouldnt = "shouldn't", brb = "be right back", omw = "on my way", gonna = "going to",
  wanna = "want to", gotta = "got to", rn = "right now", tbh = "to be honest", nvm = "never mind", ofc = "of course",
  kk = "okay", k = "okay", ok = "okay", rdy = "ready", sry = "sorry", gj = "good job", wp = "well played",
  gratz = "congrats", grats = "congrats", gz = "congrats", cya = "see you", gn = "good night", gm = "good morning",
  ima = "i'm going to", imma = "i'm going to", lemme = "let me", gimme = "give me", dunno = "i don't know",
  wb = "welcome back", gl = "good luck", glhf = "good luck have fun", inv = "invite", summ = "summon", sum = "summon",
  def = "definitely", r = "are", prob = "probably", probs = "probably", srsly = "seriously", ez = "easy", lf = "looking for",
}

-- (1.4.4) contractions typed without the apostrophe: "ill go" is "i'll go", "hell be back" is "he'll be back".
-- Only when the next word shows it, so "i'm ill", "an ill wind" and "hell yeah" stay as typed.
E.SHORT_CTX = { ill = "i'll", hell = "he'll", shell = "she'll", id = "i'd", itll = "it'll", youll = "you'll",
  theyll = "they'll", wont = "won't", wouldve = "would've", couldve = "could've", shouldve = "should've", hes = "he's", shes = "she's" }
local SHORT_ANY = { itll = true, youll = true, theyll = true, wont = true, wouldve = true, couldve = true, shouldve = true }
local ILL_ADJ = { ["i'm"] = true, im = true, am = true, feel = true, feeling = true, felt = true, feels = true, was = true, is = true,
  so = true, very = true, really = true, get = true, got = true, gets = true, getting = true, been = true, be = true, are = true,
  were = true, look = true, looks = true, seem = true, seems = true, an = true, quite = true, too = true, kinda = true, pretty = true,
  fell = true, falls = true, mentally = true, real = true, little = true, bit = true, still = true, sounds = true }
local SHORT_NEXT = { be = true, go = true, get = true, ["do"] = true, have = true, need = true, take = true, make = true, come = true,
  see = true, tank = true, heal = true, pull = true, probably = true, prob = true, never = true, just = true, def = true,
  definitely = true, ["try"] = true, help = true, like = true, love = true, rather = true, say = true, think = true, want = true,
  buy = true, sell = true, give = true, wait = true, ["let"] = true, put = true, grab = true, run = true, start = true, stop = true,
  invite = true, inv = true, check = true, show = true, send = true, bring = true, kill = true, play = true, log = true, brb = true,
  always = true, still = true, also = true, ["not"] = true, gonna = true, really = true, totally = true, ["back"] = false,
  going = true, coming = true, ["on"] = false, prolly = true, ask = true, tell = true, find = true, stay = true, keep = true, be = true,
  am = false, sleep = true, eat = true, ["leave"] = true, ["miss"] = true, ["catch"] = true, ["meet"] = true, ["join"] = true, hop = true }
local function Neighbor(t, i, step)
  local j = i + step
  local gap = t[j]
  if not gap then return nil end
  if gap.k == "o" then
    if gap.v:find("[^%s]") then return nil end  -- punctuation ends the clause
    j = j + step
  end
  local w = t[j]
  return w and w.k == "w" and w.v:lower() or nil
end
function E.ShortHere(t, i)
  local k = t[i].v:lower()
  local full = E.SHORT_CTX[k]
  if not full then return nil end
  if SHORT_ANY[k] then return full end
  local nx = Neighbor(t, i, 1)
  if not nx then return nil end
  if k == "hes" or k == "shes" then return full end
  if k == "ill" then
    local pv = Neighbor(t, i, -1)
    if pv and ILL_ADJ[pv] then return nil end
    if SHORT_NEXT[nx] or nx:find("ing$") then return full end
    return nil
  end
  if SHORT_NEXT[nx] then return full end
  return nil
end

---------------------------------------------------------------------------
-- Common chat lines. An accent gives its own lines for these in def.say[id].
---------------------------------------------------------------------------
E.INTENTS = {
  greet = { "hi", "hello", "hey", "heya", "hiya", "yo", "sup", "howdy", "greetings", "hey all", "hi all", "hello all",
    "hey guys", "hi guys", "hello guys", "hey everyone", "hi everyone", "hello everyone", "hey there", "hi there",
    "good morning", "good evening", "good afternoon", "good morning everyone", "good morning all", "morning all",
    "morning everyone", "evening all", "evening everyone", "hello friends", "hi friends", "hey y'all", "hi y'all", "hey team", "hi team" },
  bye = { "bye", "goodbye", "bye bye", "see you", "see ya", "see you later", "later", "take care", "bye all",
    "bye guys", "bye everyone", "got to go", "i have to go", "i'm out", "farewell", "catch you later" },
  goodnight = { "good night", "good night all", "good night everyone", "good night guys", "gn all", "night all", "night everyone", "goodnight", "nighty night", "going to bed",
    "time for bed", "off to bed" },
  thanks = { "thanks", "thank you", "thanks all", "thanks guys", "thanks everyone", "thank you all",
    "thanks for the group", "thanks for the run", "thanks for the help", "thanks a lot", "thank you so much",
    "much appreciated", "appreciate it", "thanks man" },
  welcome = { "no problem", "you're welcome", "no worries", "anytime", "my pleasure", "don't mention it", "all good" },
  sorry = { "sorry", "my bad", "my bad guys", "my bad all", "my bad everyone", "oops", "my fault", "apologies", "i'm sorry", "sorry guys", "sorry all", "whoops" },
  yes = { "yes", "yeah", "yep", "yup", "yea", "sure", "of course", "absolutely", "definitely", "for sure" },
  no = { "no", "nope", "nah", "no thanks", "no way", "not really", "no thank you" },
  okay = { "okay", "alright", "sounds good", "will do", "got it", "fine", "cool cool", "roger", "understood", "on it" },
  lol = { "lol", "lmao", "haha", "hahaha", "hehe", "rofl", "lul", "xd", "lmfao", "that's funny", "so funny" },
  brb = { "be right back", "one sec", "one second", "sec", "one moment", "give me a sec", "give me a second",
    "hold on a sec", "just a sec", "back in a sec", "afk a sec", "be right back guys" },
  back = { "back", "i'm back", "back now", "ok back", "okay back", "i am back" },
  afk = { "afk", "going afk", "afk for a bit", "away for a bit" },
  ready = { "ready", "i'm ready", "ready to go", "all set", "ready when you are", "i am ready" },
  wait = { "wait", "hold on", "hold up", "wait up", "stop", "wait for me", "slow down", "hang on", "wait a sec" },
  go = { "let's go", "go go", "go go go", "let's do this", "charge", "pull it", "pull", "pulling", "let's pull",
    "go ahead", "send it", "let's get it" },
  oom = { "oom", "out of mana", "need mana", "low mana", "drinking", "need to drink", "mana break",
    "need a drink", "low on mana" },
  heal = { "heal", "heal me", "heal please", "need heal", "need heals", "need healing", "heals please", "heal pls",
    "i need heals", "help me heal", "healer please" },
  invite = { "invite", "invite please", "can i get an invite", "can i join", "invite me", "room for one more",
    "inv please", "can i come", "mind if i join" },
  gg = { "gg", "good game", "well played", "nice run", "good run", "great run", "gg all", "gg everyone", "gg guys" },
  goodjob = { "good job", "nice job", "great job", "nice one", "nice work", "well done", "great work", "nicely done" },
  nice = { "nice", "cool", "awesome", "sweet", "great", "epic", "dope", "sick", "amazing", "perfect", "fantastic", "neat" },
  wow = { "wow", "whoa", "omg", "oh my god", "holy cow", "jeez", "geez", "dang", "oh no", "no way", "what the" },
  dead = { "rip", "i died", "i'm dead", "dead", "wipe", "we wiped", "we died", "i'm down", "died again" },
  rez = { "rez", "res", "rez please", "res please", "rez me", "res me", "need a rez", "need rez", "can i get a rez" },
  idk = { "i don't know", "no idea", "not sure", "i have no idea", "beats me", "who knows" },
  help = { "help", "help me", "need help", "can someone help", "anyone help", "i need help", "somebody help" },
  run = { "run", "run away", "flee", "retreat", "get out", "back off" },
  howareyou = { "how are you", "how are you doing", "how's it going", "how you doing", "what's up", "how are things",
    "how's everyone", "how is everyone", "how are you all" },
  good = { "i'm good", "doing good", "i'm fine", "not bad", "i'm great", "good thanks", "i'm okay", "doing well" },
  hungry = { "i'm hungry", "so hungry", "need food", "food break", "dinner break", "lunch break" },
  congrats = { "congrats", "congratulations", "congrats man", "well deserved", "nice ding" },
  wtf = { "what", "what happened", "what was that", "how", "why", "huh" },
  -- (1.4.0)
  omw = { "on my way", "on my way now", "coming", "i'm coming", "be there soon", "almost there", "on the way", "heading over" },
  wb = { "welcome back", "welcome back man", "welcome back all" },
  gl = { "good luck", "good luck all", "good luck everyone", "good luck guys", "good luck have fun", "have fun", "best of luck" },
  summon = { "summon please", "summon", "summon me", "need a summon", "can i get a summon", "summon me please", "need summon", "can someone summon me" },
}

---------------------------------------------------------------------------
-- lines that also count at the very start or end of a message ("omg that was close", "that was crazy lol")
-- (1.4.1) words that already say which one: a swap's own "the" is dropped after these
E.DETERMINER = { the = true, a = true, an = true, this = true, that = true, these = true, those = true, my = true, our = true,
  your = true, his = true, her = true, its = true, their = true, any = true, some = true, no = true, every = true, each = true,
  which = true, what = true, whose = true, all = true, both = true, another = true, me = true, yer = true, ye = true, da = true }
---------------------------------------------------------------------------
-- (1.4.3) words with two meanings in chat. KeepHere(word, tokens, i) says "leave it as typed" when its neighbours
-- show the other meaning: "hits so hard" (how, not difficult), "pretty easy" (very, not beautiful), "that was sick"
-- (great, not ill), "need to drink" (the verb), "home from work" (the job), "got home", "mount up"
---------------------------------------------------------------------------
local INTENS = { so = true, too = true, very = true, really = true, real = true, pretty = true, super = true, quite = true, absolutely = true, totally = true, extremely = true, incredibly = true,
  kinda = true, way = true, mad = true, hella = true, damn = true, freaking = true, fucking = true, extra = true }
-- verbs a how-word follows: "hits hard", "run fast", "pull slow", "died quick", "take it easy"
local HOWVERB = {}
for w in ([[hit hits hitting run runs running ran go goes going went pull pulls pulling pulled die dies dying died
  fell fall falls move moves moving moved play plays playing played push pushing pushed work works working worked
  crit crits critting heal heals healing healed drop drops dropped dropping hurt hurts hurting kill kills killing killed
  learn learning level leveling levelling farm farming grind grinding fight fights fighting fought take it hold walk
  walking walked ride riding rode fly flying flew talk talking type typing read come coming came wipe wiped wiping
  burn burning burned cast casting dps tank tanking melt melted melting]]):gmatch("%S+") do HOWVERB[w] = true end
local HOWWORD = { hard = true, fast = true, slow = true, slowly = true, quick = true, quickly = true, easy = true, bad = true, good = true, well = true }
local SLANG_SICK = { was = true, is = true, ["that's"] = true, thats = true, looks = true, looked = true, sounds = true, so = true,
  real = true, pretty = true, super = true, too = true, kinda = true, mad = true, how = true, very = true }
local VERB_BEFORE = { to = true, gotta = true, must = true, i = true, ["i'll"] = true, ill = true, we = true, can = true,
  could = true, should = true, will = true, lemme = true, gonna = true, please = true, pls = true, ["and"] = true, ["then"] = true,
  go = true, ["let's"] = true, lets = true, me = true, ["don't"] = true, dont = true, ["didn't"] = true, didnt = true,
  ["doesn't"] = true, doesnt = true, ["won't"] = true, wont = true, ["can't"] = true, cant = true, would = true, might = true, gonna = true }
local WORK_NOUN = { from = true, at = true, after = true, before = true, ["for"] = true, of = true, my = true, the = true, off = true, during = true }
local HOME_FIXED = { got = true, get = true, go = true, going = true, went = true, come = true, came = true, coming = true,
  head = true, heading = true, back = true, at = true, from = true, stay = true, stayed = true, staying = true, way = true, get = true }
E.FUTURE_VERB = {}
for w in ([[be go get do have need take make come see tank heal pull try help buy sell give wait put grab run start stop invite
  check show send bring kill play log sleep eat leave miss catch meet join hop ask tell find stay keep say think want die wipe
  farm grind level quest craft fish cook mine skin learn train respec fight win lose lead follow carry explain look watch use
  open loot roll need equip hearth fly ride walk port summon rez res buff drink rest stream raid queue test call text clear
  skip solo duo group work cry quit lag crash dc afk reset hit attack cast drop pick hold save spend pay trade mail post craft
  read write talk sit stand jump swim chill relax be]]):gmatch("%S+") do E.FUTURE_VERB[w] = true end
local BE = { ["i'm"] = true, im = true, am = true, is = true, are = true, was = true, were = true, be = true, being = true, been = true,
  ["it's"] = true, its = true, ["that's"] = true, thats = true, ["you're"] = true, youre = true, ["we're"] = true, ["they're"] = true,
  ["he's"] = true, ["she's"] = true, so = true, totally = true, completely = true, flat = true, dead = true, super = true, very = true,
  pretty = true, too = true, get = true, got = true, getting = true, kinda = true }
local LEFT_SUBJ = { he = true, she = true, they = true, i = true, we = true, you = true, just = true, already = true, who = true,
  tank = true, healer = true, guy = true, everyone = true, people = true, someone = true, everybody = true, mage = true, rogue = true }
local DROP_ADJ = { nice = true, good = true, great = true, rare = true, epic = true, first = true, big = true, sick = true, sweet = true, lucky = true, bad = true }
local DROP_NOUN = { rate = true, rates = true, chance = true, chances = true, table = true, list = true }
local COME_PART = { on = true, back = true, out = true, ["in"] = true, up = true, down = true, over = true, here = true, along = true, by = true, around = true, through = true, with = true, to = true, at = true }
local NOUN_AFTER = { item = true, items = true, giver = true, givers = true, log = true, line = true, chain = true, reward = true, rewards = true,
  mob = true, mobs = true, npc = true, hub = true, xp = true, text = true, quest = true, quests = true, shot = true, count = true,
  streak = true, power = true, speed = true, guide = true, zone = true, zones = true, spot = true, spots = true, route = true,
  gear = true, buddy = true, partner = true, group = true, dungeon = true, dungeons = true, alt = true, alts = true, steal = true }
local HEAD_GO = { to = true, over = true, back = true, out = true, there = true, home = true, ["in"] = true, up = true, down = true, into = true, towards = true, toward = true }
local MAKE_FIXED = { sure = true, it = true, sense = true, fun = true, up = true, out = true }
local WIPE_ADJ = { nice = true, full = true, another = true, big = true, total = true, first = true, second = true, last = true, epic = true, raid = true }
local AGE = { years = true, yrs = true, year = true, months = true, days = true, weeks = true }
local LOOSE_AFTER = { now = true, soon = true, early = true, today = true, tonight = true, already = true, lol = true, ["then"] = true, too = true,
  again = true, anyway = true, lmao = true, haha = true, guys = true, man = true, bro = true, lmfao = true, xd = true, pls = true, please = true,
  solo = true, alone = true, together = true, still = true, fast = true, slowly = true, quickly = true, ["for"] = true, ["in"] = true }
local ADJ = {}
for g in ([[good bad big small strong weak fast easy hard funny stupid smart crazy scary tired hungry happy sad angry annoyed
  rich poor ugly pretty old new expensive cheap broken boring annoying dangerous ridiculous scared sick late early whole ready
  lucky unlucky dead important sure fun]]):gmatch("%S+") do ADJ[g] = true end
local WOW_GAME = { is = true, was = true, just = true, play = true, playing = true, played = true, love = true, ["in"] = true, of = true,
  about = true, the = true, classic = true, retail = true, my = true, this = true, at = true, quit = true, into = true, ["and"] = true, like = true }
local LOOK_PART = { out = true, ["for"] = true, like = true, up = true, around = true, into = true, after = true, forward = true }
local FEW = { few = true, couple = true, several = true, some = true, many = true, more = true, a = true, an = true, ten = true, five = true, two = true, three = true, half = true }
local GET_FIXED = { up = true, ["in"] = true, out = true, on = true, off = true, back = true, over = true, down = true, away = true, ready = true,
  rid = true, it = true, there = true, home = true, lost = true, killed = true, rekt = true, to = true, going = true, started = true,
  used = true, better = true, worse = true, paid = true, hit = true, carried = true, ganked = true, along = true }
local GOOD_FIXED = { luck = true, morning = true, night = true, evening = true, afternoon = true }
local GO_FIXED = { ahead = true, afk = true, away = true, off = true, on = true, again = true, go = true, now = true }
local PLACE_AFTER = { bed = true, sleep = false, town = true, stormwind = true, ironforge = true, orgrimmar = true, darnassus = true,
  undercity = true, ["thunder"] = true, ["booty"] = true, school = true, work = true, church = true, ["there"] = true }
local TIME_BEFORE = { first = true, second = true, third = true, last = true, next = true, this = true, that = true, one = true,
  what = true, every = true, any = true, each = true, another = true, more = true, same = true, no = true, all = true, whole = true,
  some = true, other = true, good = true, long = true, great = true, ["full"] = true, ["play"] = true, ["free"] = true, ["of"] = true }
local function Near(t, i, step, skipIntens)
  local j = i + step
  while t[j] do
    local tk = t[j]
    if tk.k == "w" then
      local w = tk.v:lower()
      if not (skipIntens and INTENS[w]) then return w end
    elseif tk.k == "r" then   -- (1.4.7) a phrase already swapped in ("it is"): its nearest word counts
      local w = (step < 0 and tk.v:match("([%a']+)[^%a']*$") or tk.v:match("^[^%a']*([%a']+)"))
      if w and not tk.v:find(step < 0 and "[%.!%?,;:]%s*$" or "^%s*[%.!%?,;:]") then return w:lower() end
      return nil
    elseif tk.k == "o" and tk.v:find("[%.!%?,;:]") then return nil end
    j = j + step
  end
end
function E.KeepHere(k, t, i)
  local prev, nxt = Near(t, i, -1), Near(t, i, 1)
  if HOWWORD[k] then
    local verb = Near(t, i, -1, true)
    if verb and HOWVERB[verb] then return true end
  end
  if k == "pretty" and nxt then return true end                     -- "pretty easy": pretty means very
  if k == "sick" and prev and SLANG_SICK[prev] then return true end   -- "that was sick": great, not ill
  if (k == "drink" or k == "drinks") and prev and VERB_BEFORE[prev] then return true end
  if k == "work" and prev and WORK_NOUN[prev] then return true end   -- "home from work": the job
  if k == "home" and prev and HOME_FIXED[prev] then return true end   -- "got home", "on my way home"
  if k == "mount" and nxt == "up" then return true end
  -- (1.4.6) "bad at healing" (not corrupted at it), "elite quest" / "elite mob" (the word picks the kind, keep it)
  if k == "bad" and nxt == "at" then return true end
  if k == "elite" and nxt then return true end
  if k == "hell" and nxt == "of" then return true end
  -- (1.4.6) set phrases where a swap reads wrong: "let it go", "go ahead", "going to tank" (the future, not a walk),
  -- "first time", "one day", "get a life", "life tap"
  if k == "go" and ((prev == "it" or prev == "we") or (nxt and GO_FIXED[nxt])) then return true end
  if k == "going" and nxt == "to" then
    local third = Near(t, i, 2)
    if t[i + 4] and t[i + 4].k == "w" then third = t[i + 4].v:lower() end
    if not third or not (E.DETERMINER[third] or PLACE_AFTER[third]) then return true end
  end
  if k == "time" and ((prev and TIME_BEFORE[prev]) or nxt == "to") then return true end
  if k == "day" and prev and TIME_BEFORE[prev] then return true end
  if k == "life" and (prev == "a" or nxt == "tap") then return true end
  -- (1.4.7) the full audit: one rule per word that reads two ways in chat
  local raw = t[i - 1]
  local numBefore = (raw and raw.k == "o" and raw.v:find("%d%s*$")) or (raw and raw.k == "o" and not raw.v:find("%S") and t[i - 2] and t[i - 2].k == "p") or (raw and raw.k == "p")
  local rawN = t[i + 1]
  local numAfter = (rawN and rawN.k == "o" and rawN.v:find("^%s*%d")) or (rawN and rawN.k == "o" and not rawN.v:find("%S") and t[i + 2] and t[i + 2].k == "p")
  if k == "world" and nxt == "of" then return true end                          -- "world of warcraft"
  if k == "head" and nxt and HEAD_GO[nxt] then return true end                   -- "head to org" (the verb)
  if k == "face" and prev and (VERB_BEFORE[prev] or prev == "to") then return true end   -- "we face the boss"
  if (k == "here" or k == "there") and nxt then return true end                  -- "here we go", "there is a rare": only "I'm here" / "over there" swap
  if (k == "broke" or k == "loaded") and not (prev and BE[prev]) then return true end   -- "it broke", "it loaded": only "I'm broke"
  if k == "lost" and prev and BE[prev] then return true end                     -- "I'm lost" (where am I), not "we lost"
  if k == "lost" and nxt and not LOOSE_AFTER[nxt] then return true end          -- "lost all my gold", "lost the tank"
  if (k == "forget" or k == "forgot") and (nxt == "to" or nxt == "about") then return true end
  if k == "need" and nxt == "to" then return true end                           -- "need to repair", never "require to repair"
  if (k == "sick" or k == "scared" or k == "afraid") and nxt == "of" then return true end   -- "sick of this zone"
  if k == "see" and nxt and (nxt == "you" or nxt == "ya" or nxt == "ye" or nxt == "u" or nxt == "y'all") then return true end   -- "see you tomorrow"
  if k == "look" and nxt and LOOK_PART[nxt] then return true end               -- "look out", "look for"
  if k == "item" and prev == "quest" then return true end                        -- "quest item"
  if (k == "pull" or k == "pulled") and prev and (E.DETERMINER[prev] or ADJ[E.WORD_GROUP[prev] or ""]) then return true end   -- "a stupid pull"
  if (k == "minute" or k == "minutes" or k == "mins" or k == "hour" or k == "hours") and prev and FEW[prev] then return true end
  if (k == "get" or k == "grab") and nxt and GET_FIXED[nxt] then return true end   -- "get up", "get ready"
  if E.WORD_GROUP[k] == "good" and nxt and GOOD_FIXED[nxt] then return true end
  if k == "luck" and prev == "good" then return true end
  if k == "wow" and prev and WOW_GAME[prev] then return true end                 -- "my life is just wow now": the game
  if k == "go" and nxt and E.FUTURE_VERB[nxt] then return true end              -- "let's go kill it"   -- "good luck", "good morning"
  if E.WORD_GROUP[k] == "crazy" and nxt and ADJ[E.WORD_GROUP[nxt] or ""] then return true end   -- "crazy good dps": crazy means very
  if k == "left" and not (prev and LEFT_SUBJ[prev]) then return true end        -- "3 left", "on the left": only "he left"
  if k == "drop" and ((prev and (E.DETERMINER[prev] or DROP_ADJ[prev])) or (nxt and DROP_NOUN[nxt])) then return true end   -- "nice drop", "drop rate"
  if (k == "okay" or k == "ok" or k == "alright") and prev and (BE[prev] or prev == "it" or prev == "'tis" or prev == "tis" or prev == "be") then return true end   -- "it's okay" means fine
  if (k == "going" or k == "go") and nxt == "on" then return true end           -- "what's going on"
  if (k == "come" or k == "coming") and nxt and COME_PART[nxt] then return true end   -- "come back", "coming over"
  if (k == "quest" or k == "kill" or k == "attack") and nxt and NOUN_AFTER[nxt] then return true end   -- "quest item", "kill quest", "attack power"
  if k == "attack" and prev == "auto" then return true end
  if k == "instance" and prev == "for" then return true end                     -- "for instance"
  if k == "mount" and prev and (VERB_BEFORE[prev] or prev == "can't" or prev == "cant" or prev == "cannot") then return true end
  if (k == "help" or k == "sleep" or k == "hope") and prev and (E.DETERMINER[prev] or prev == "for" or prev == "of") then return true end   -- "thanks for the help", "no hope"
  if k == "need" and (nxt == "on" or nxt == "roll" or (prev and (prev == "roll" or prev == "rolled" or prev == "no" or prev == "hit"))) then return true end   -- loot rolls
  if k == "make" and nxt and MAKE_FIXED[nxt] then return true end              -- "make sure", "make it"
  if k == "give" and nxt == "up" then return true end
  if k == "sorry" and prev and (BE[prev] or prev == "feel" or prev == "so" or prev == "very" or prev == "really") then return true end   -- "I'm sorry I pulled"
  if k == "wipe" and prev and (E.DETERMINER[prev] or WIPE_ADJ[prev]) then return true end   -- "that was a wipe"
  if k == "ready" and nxt and (nxt == "to" or nxt == "for" or nxt == "check") then return true end
  if k == "old" and (prev == "how" or (prev and AGE[prev]) or numBefore) then return true end   -- "how old", "20 years old"
  if k == "new" and nxt == "to" then return true end
  if k == "now" and prev == "right" then return true end                        -- "right now" is its own phrase
  if k == "tired" and nxt == "of" then return true end
  if (k == "leveling" or k == "levelling") and nxt and (nxt == "up" or NOUN_AFTER[nxt]) then return true end
  if (k == "minute" or k == "minutes" or k == "mins" or k == "hour" or k == "hours" or k == "sec") and numBefore then return true end
  if (k == "day" or k == "time") and numAfter then return true end              -- "day 3"
  if (k == "no" or k == "nah") and nxt then return true end                     -- "no mana": only a plain "no" is an answer
  if (k == "light" or k == "fire") and nxt then return true end                 -- "light armor", "fire resist"
  if (k == "leave" or k == "quit" or k == "win" or k == "leveling" or k == "levelling") and nxt and not LOOSE_AFTER[nxt] then return true end   -- "leveling a warrior"
  if k == "wait" and ((nxt and (nxt == "until" or nxt == "till" or nxt == "til" or nxt == "to" or nxt == "up" or nxt == "a")) or (prev and (prev == "can't" or prev == "cant" or prev == "cannot"))) then return true end   -- "can't wait"
  if k == "drop" or k == "dropped" or k == "drops" then return true end           -- "did it drop", "nice drop": the loot word stays   -- "leave the group", "win the roll"
  if k == "work" then return true end                                           -- "it doesn't work" and "home from work" both stay                        -- "one hell of a run"
  if k == "guess" and nxt == "what" then return true end                     -- "guess what"
  if k == "quick" and nxt and (nxt == "question" or nxt == "q" or nxt == "one" or nxt == "sec" or nxt == "break") then return true end
  if (k == "group" or k == "party") and prev and (prev == "to" or prev == "can" or prev == "lets" or prev == "let's" or prev == "wanna") then return true end   -- the verb: "want to group"
  if k == "play" or k == "playing" or k == "played" then return true end   -- "play wow", "playing a priest"
  if k == "world" and nxt and (nxt == "boss" or nxt == "bosses" or nxt == "buff" or nxt == "buffs" or nxt == "chat" or nxt == "pvp" or nxt == "first") then return true end
  if (k == "boss" or k == "bosses" or k == "buff" or k == "buffs") and prev == "world" then return true end
  return false
end

-- (1.4.2) words after which "wow" is still the exclamation ("oh wow", "lol wow")
E.WOWBEFORE = { oh = true, ohh = true, lol = true, lmao = true, omg = true, haha = true, hahaha = true, man = true, dude = true, just = true, like = true, ok = true, okay = true }
E.LOOSE = { lol = true, wow = true, gg = true, brb = true, dead = true, congrats = true }

---------------------------------------------------------------------------
-- Protecting what must not change
---------------------------------------------------------------------------
local function Caseless(name)
  return (name:gsub("%a", function(c) return "[" .. c:lower() .. c:upper() .. "]" end)
              :gsub("([%^%$%(%)%%%.%+%-%*%?])", "%%%1"))
end

function E.Protect(s, names)
  local saved = {}
  local function keep(x) saved[#saved + 1] = x; return "\001" .. #saved .. "\002" end
  s = s:gsub("|c%x%x%x%x%x%x%x%x|H.-|h.-|h|r", keep)   -- item, spell, quest links
  s = s:gsub("|H.-|h.-|h", keep)
  s = s:gsub("|T.-|t", keep)                            -- icons
  s = s:gsub("|A.-|a", keep)
  s = s:gsub('"[^"]*"', keep)                           -- "quoted text" stays word for word
  s = s:gsub("%f[%w_]https?://%S+", keep)              -- web addresses
  s = s:gsub("%f[%w_]www%.%S+", keep)
  s = s:gsub("%f[%w_][%w%-]+%.[%a][%a]+/%S*", keep)     -- discord.gg/abc, site.com/page
  s = s:gsub("%f[%w_][%w%-]+%.com%f[^%w]", keep)
  s = s:gsub("{[^}]*}", keep)                           -- raid marks {rt1}
  s = s:gsub("%f[%w]%w*%d%w*", keep)                    -- 5k, 2v2, 10g, 60, 1.60
  -- (1.2.0) a Capitalized word in the middle of a sentence is a name (a guildmate, a place, a boss): left alone.
  -- The first word of a sentence and "I'm"/"I'll" don't count
  local src = s
  s = s:gsub("()(%u[%l']+)", function(pos, w)
    if w:find("^I'") then return end
    local before = src:sub(1, pos - 1)
    if before:find("^%s*$") or before:find("[%.!%?:]%s*$") then return end
    return keep(w)
  end)
  -- (1.4.2) "wow" is the game unless it's said like "wow!": at the start of a sentence, alone, or right after
  -- oh / lol / omg. "people play wow", "i love wow", "is wow classic" keep it as it is
  local src2 = s
  s = s:gsub("()(%f[%a][Ww][Oo][Ww]%f[%A])", function(pos, w)
    local before = src2:sub(1, pos - 1)
    if before:find("^%s*$") or before:find("[%.!%?:,;]%s*$") then return end
    local prev = before:match("(%a+)%s*$")
    if prev and E.WOWBEFORE[prev:lower()] then return end
    return keep(w)
  end)
  for _, n in ipairs(names or {}) do
    if type(n) == "string" and #n > 1 then
      s = s:gsub("%f[%a]" .. Caseless(n) .. "%f[%A]", keep)
    end
  end
  return s, saved
end

function E.Restore(s, saved)
  for _ = 1, 6 do
    local n
    s, n = s:gsub("\001(%d+)\002", function(i) return saved[tonumber(i)] or "" end)
    if n == 0 then break end
  end
  return s
end

---------------------------------------------------------------------------
-- Words and tokens
---------------------------------------------------------------------------
local function Tokens(s)
  local t, i, n = {}, 1, #s
  while i <= n do
    local c = s:sub(i, i)
    if c == "\001" then
      local j = s:find("\002", i, true) or n
      t[#t + 1] = { k = "p", v = s:sub(i, j) }
      i = j + 1
    elseif c:find("[%a']") then
      local j = i
      while j <= n and s:sub(j, j):find("[%a']") do j = j + 1 end
      t[#t + 1] = { k = "w", v = s:sub(i, j - 1) }
      i = j
    else
      local j = i
      while j <= n and not s:sub(j, j):find("[%a'\001]") do j = j + 1 end
      t[#t + 1] = { k = "o", v = s:sub(i, j - 1) }
      i = j
    end
  end
  return t
end
E.Tokens = Tokens

-- class, role and group-finding words: never changed, never re-spelled ("LF healer" stays readable)
E.KEEP = {}
for w in ("healer healers heals tank tanks dps lf lfg lfm wts wtb pst inv warrior warriors priest priests shaman shamans druid druids mage mages hunter hunters rogue rogues paladin paladins warlock warlocks"):gmatch("%S+") do E.KEEP[w] = true end

-- words that only look like they end in -ing
E.NO_SUFFIX = {}
for w in ("ding king ring sing wing thing bring sting spring string swing fling cling sling wring something nothing everything anything ceiling morning evening"):gmatch("%S+") do E.NO_SUFFIX[w] = true end

-- swear words: always swapped (unless the player keeps them), never left half-done
E.SWEAR_GROUP, E.SWEAR_PHRASE = {}, {}

local function Key(w) return (w:lower():gsub("^'+", ""):gsub("'+$", "")) end

-- copy the capitals of the original onto the replacement
local function Case(orig, repl, first)
  if repl == "" then return repl end
  local letters = orig:gsub("[^%a]", "")
  if #letters > 1 and letters:upper() == letters then return repl:upper() end
  local f = orig:match("%a")
  if f and f:upper() == f and (#letters > 1 or first) then return (repl:gsub("^%l", string.upper)) end
  return repl
end

-- index of every phrase an accent knows, by first word, longest first
local function Index(def)
  if def._index then return def._index end
  local idx = {}
  local function add(words, out, kind, id)
    local list = {}
    for w in words:gmatch("[%a']+") do list[#list + 1] = w end
    if #list == 0 then return end
    idx[list[1]] = idx[list[1]] or {}
    table.insert(idx[list[1]], { words = list, out = out, kind = kind, id = id })
  end
  for id, lines in pairs(def.say or {}) do
    for _, trig in ipairs(E.INTENTS[id] or {}) do add(trig, lines, "say", id) end
  end
  for phrase, out in pairs(def.phrases or {}) do add(phrase, out, "phrase", phrase) end
  for _, list in pairs(idx) do table.sort(list, function(a, b) return #a.words > #b.words end) end
  def._index = idx
  return idx
end

-- is the token at i followed (over single spaces) by these words?
local function Match(t, i, words)
  local j, used = i, {}
  for w = 1, #words do
    while t[j] and t[j].k == "o" and t[j].v:match("^%s*$") and w > 1 do j = j + 1 end
    local tok = t[j]
    if not tok or tok.k ~= "w" or tok.done or Key(tok.v) ~= words[w] then return nil end
    used[#used + 1] = j
    j = j + 1
    if w < #words then
      local sp = t[j]
      if not (sp and sp.k == "o" and sp.v:match("^%s+$")) then return nil end
    end
  end
  return used
end

-- (common chat lines only count as a whole thought: the full message, or a part between commas and full stops.
-- "back" swaps in "ok back", never in "I'll be back later")
local function ClauseStart(out)
  for k = #out, 1, -1 do
    local x = out[k]
    if x.k == "r" and x.v:find("[%.!%?]$") then return true end
    if x.k ~= "o" then return false end
    if x.v:find("[,%.!%?;:%(%)]") then return true end
    if not x.v:match("^%s*$") then return true end
  end
  return true
end
local function ClauseEnd(t, last)
  -- (1.4.7) a link or number is not the end when words follow it: "we wiped 60 times" is not "We died."
  local j = last + 1
  while t[j] do
    local x = t[j]
    if x.k == "w" or x.k == "r" then return false end
    if x.k == "o" and x.v:find("[,%.!%?;:%(%)]") then return true end
    j = j + 1
  end
  return true
end

---------------------------------------------------------------------------
-- The accent itself
---------------------------------------------------------------------------
-- E.Apply(key, text, strength, opts) -> new text. opts.names: player names to leave alone,
-- opts.noFlavor: no openers or closers (used when a line is too long)
---------------------------------------------------------------------------
-- (1.4.7) which swap fits where. A swap like "a cakewalk" or "smooth sailin'" can only end a thought ("that was easy"),
-- never sit in front of a word ("easy quest"). "your tribute is accepted" can't be followed by "for the help".
---------------------------------------------------------------------------
local AFTER_ADJ = {}
for w in ([[to for and or but now then lol lmao lmfao haha hahaha xd though tho too enough as if when with at so man bro dude guys
  af today tonight right again anyway yet already honestly tbh imo because cause cuz since until til in on of from by there here
  yo you me i we they he she it ngl fr rn lately sometimes either also still btw bud buddy fam all ever lately this that]]):gmatch("%S+") do AFTER_ADJ[w] = true end
local PRED_ONLY = {}
for x in ([[smooth sailin'|double time|child's play|simple enough|folly|highway robbery|bankrupt-sad|done in|tuckered out|wiped out|big brain
  |worn to the bone|beat|gassed|a snooze|always late|too late|in overtime|behind schedule|behind the wind|at first light]]):gmatch("[^|]+") do PRED_ONLY[x:match("^%s*(.-)%s*$")] = true end
local function PredOnly(x)
  local l = x:lower()
  return PRED_ONLY[l] or l:find("^an? ") or l:find("^no ") or l:find("^nothing") or l:find("^nae ") or l:find("^too much")
    or l:find("^lotsa") or l:find("^too ") or l:find("^many ") or l:find("^need ") or l:find("^want ") or l:find("^make ") or l:find("^ready ")
    or l:find("^easy %a") or l:find("^in ") or l:find(" as ") or l:find(" like ") or l:find(" than ") or l:find(" of ") or l:find(" to ")
    or l:find(" for ") or l:find(" in ") or l:find(" on ") or l:find(" me$") or l:find("[,%.!%?]")
end
-- verbs that read wrong with a two-word swap in front of more words: "wait for me" is not "hold your horses for me"
local CLAUSE_VERB = { wait = true, stop = true, try = true, look = true, forget = true }
-- words that start a thought: a longer swap only at the very start ("honestly, ..."), never "I wake up died"
local START_ADV = { honestly = true, obviously = true }
-- answers and thanks: a whole little sentence only when nothing follows
local INTERJ = { thanks = true, sorry = true, okay = true, yes = true, no = true, maybe = true, ugh = true, hello = true }
local COMMA_AFTER = { hello = true, yes = true, no = true }
local STANDALONE = {}
for x in ([[a class act|gratitude logged|apology issued|no refunds|no excuses|a rough play|i'll remember that|your tribute is accepted
  |depends on the price|probability fifty percent|reckon so|so be it|very well|as you wish|sure thing|copy that|roger|acknowledged
  |deal|agreed|indeed|quite so|it is so|sir yes sir|zug zug|yeah dude|exactly|sure enough|never|certainly not|i think not
  |not really|i'm afraid not|that's what they want|ew, no|no deal|no dice|negative|affirmative|aye aye|nae chance|no way
  |so, you have come|welcome, mortals|ten-hut|listen up|what's the deal|welcome|yeah, hello|ah, you|welcome back, folks|throm-ka|lok'tar]]):gmatch("[^|]+") do STANDALONE[x:match("^%s*(.-)%s*$")] = true end
local function Standalone(x)
  local l = x:lower()
  if STANDALONE[l] or l:find("[,%.!%?]") then return true end
  local _, n = l:gsub("%S+", "")
  return n >= 4
end
local PAD = { please = true, pls = true, plz = true, lol = true, now = true, asap = true, thanks = true, ty = true, guys = true, man = true, bro = true }
local PREP_END = { ["in"] = true, on = true, with = true, at = true, ["for"] = true, of = true, to = true, into = true, up = true }
local function Fits(g, k, x, prev, nxt)
  if type(x) ~= "string" then return true end
  if g and ADJ[g] and nxt and not AFTER_ADJ[nxt] and PredOnly(x) then return false end
  if g and CLAUSE_VERB[g] and nxt and x:find(" ") then return false end
  if g and START_ADV[g] and prev and x:find(" ") then return false end
  if g and INTERJ[g] and nxt and Standalone(x) then return false end
  if (not nxt or PAD[nxt]) and x:find(" %a+$") and PREP_END[x:match(" (%a+)$")] then return false end   -- "can you help" is not "can you invest in"
  if g == "finally" and prev and (x == "about time" or x:find("!")) then return false end
  return true
end
E.Fits = Fits
-- (1.4.7) "thank you" -> "thank thee", "you are" -> "thou art": thou does, thee is done to
local THEE_PREV = {}
for w in ([[to for with at from of by about on in upon unto without like than behind beside near against thank thanks see tell give help
  love hate kill heal invite need want show ask let make beat miss follow trust know hear call meet join pay owe bless save carry
  find get send bring teach guide protect forgive leave res rez buff summon]]):gmatch("%S+") do THEE_PREV[w] = true end
-- (1.4.7) set lines that only work as a whole thought, or only with certain endings when more words follow
E.FOLLOW = {
  ["good luck"] = true, ["be careful"] = true, ["calm down"] = true, ["hurry up"] = true, ["have fun"] = true, ["i'm dead"] = true,
  ["i'm dying"] = true, ["i don't care"] = true, ["for free"] = true, ["how's it going"] = true, ["what's up"] = true, ["no way"] = true,
  ["no worries"] = true, ["sounds good"] = true, ["take care"] = true, ["see you"] = true, ["that's crazy"] = true, ["come on"] = true,
  ["kill me"] = true, ["got it"] = true, ["my bad"] = true, ["of course"] = true, ["for real"] = true,
  ["i don't know"] = { say = 1, know = 1, knows = 1, tell = 1, me = 1, ya = 1, dunno = 1, idea = 1, said = 1, care = 1 },
  ["i dunno"] = { say = 1, know = 1, dunno = 1, me = 1 },
  ["i'm tired"] = { weary = 1, tired = 1, wiped = 1 },
  ["i'm hungry"] = { hungry = 1, hunger = 1 },
  ["let's go"] = { go = 1 },
}
E.NOT_ALONE = { ["so long"] = true }   -- "so long" alone is a goodbye, not "an age"
local function NextWord(t, j)
  while t[j] do
    if t[j].k == "w" then return Key(t[j].v) end
    if t[j].k == "p" or (t[j].k == "o" and t[j].v:find("[%.!%?,;:]")) then return nil end
    j = j + 1
  end
end

function E.Apply(key, text, strength, opts)
  local def = ns.ACCENTS[key]
  if not def or type(text) ~= "string" or text == "" then return text end
  opts = opts or {}
  strength = strength or 2
  if def.whole then
    local ok, r = pcall(def.whole, text, strength, opts)
    if ok and type(r) == "string" and r ~= "" then return r end
  end
  local s, saved = E.Protect(text, opts.names)
  local t = Tokens(s)

  -- 1. chat-speak spelled out
  local spelled = {}
  for ti, tok in ipairs(t) do
    if tok.k == "w" then
      local full = E.SHORT[Key(tok.v)] or E.ShortHere(t, ti)
      if full and not (def.keep and def.keep[Key(tok.v)]) then
        tok.v = Case(tok.v, full)
      end
    end
    spelled[#spelled + 1] = tok.v
  end
  t = Tokens(table.concat(spelled))

  -- 2. phrases, longest first
  local idx = Index(def)
  local out, i, firstWord = {}, 1, true
  local lastSay, usedSay = nil, false
  local sayChance = (strength == 1 and 0.75) or 1
  while i <= #t do
    local tok, done = t[i], false
    if tok.k == "w" then
      local cands = idx[Key(tok.v)]
      if cands then
        for _, c in ipairs(cands) do
          local used = Match(t, i, c.words)
          if used and c.kind == "say" then
            local cs, ce = ClauseStart(out), ClauseEnd(t, used[#used])
            -- interjections (lol, wow, gg, brb, rip) also count at the very start or end of a line
            if not ((cs and ce) or (E.LOOSE[c.id] and #c.words == 1 and ((cs and #out == 0) or (ce and not t[used[#used] + 2])))) then used = nil end
            -- (1.4.6) "that was a wipe", "nice wipe": only "rip" stands for a death line inside a sentence
            if used and c.id == "dead" and not (cs and ce) and Key(t[i].v) ~= "rip" then used = nil end
          end
          if used and opts.keepSwears and c.kind == "phrase" and E.SWEAR_PHRASE[c.id] then used = nil end
          -- (1.4.6) "I'm going to" is "I shall" only before a verb: "I'm going to stormwind" is a trip
          if used and c.kind == "phrase" and c.words[#c.words] == "to" and (c.words[#c.words - 1] == "going" or c.words[#c.words - 1] == "gonna") then
            local nx = t[used[#used] + 2]
            if not (nx and nx.k == "w" and E.FUTURE_VERB[Key(nx.v)]) then used = nil end
          end
          local pool = c.out
          local used0 = used
          if used and c.kind == "phrase" then
            local nxw = NextWord(t, used[#used] + 1)
            local f = E.FOLLOW[c.id]
            if (c.id == "i think" and nxw == "so") or (c.words[#c.words] == "need" and nxw == "to") then used = nil
              for _, u in ipairs(used0) do t[u].keep = true end
            elseif E.NOT_ALONE[c.id] and ClauseStart(out) then used = nil
            elseif nxw and type(pool) == "table" then
              if f == true then used = nil; for _, u in ipairs(used0) do t[u].keep = true end   -- leave the words as typed
              else
                local keep = {}
                for _, v in ipairs(pool) do
                  local last = v:lower():match("([%a']+)%W*$")
                  if not v:find("[,%.!%?]") and (type(f) ~= "table" or (last and f[last])) then keep[#keep + 1] = v end
                end
                if #keep == 0 then used = nil; for _, u in ipairs(used0) do t[u].keep = true end else pool = keep end
              end
            elseif nxw and type(pool) == "string" then
              if f == true or (type(f) == "table" and not f[(pool:lower():match("([%a']+)%W*$") or "")]) or pool:find("[,%.!%?]") then used = nil end
            end
          end
          if used and (c.kind ~= "say" or random() < sayChance) then
            local repl = Pick(pool)
            local orig = {}
            for _, u in ipairs(used) do orig[#orig + 1] = t[u].v end
            local o = table.concat(orig, " ")
            -- (1.4.6) "XD", "LOL", "GG" are how people type them, not shouting: the line keeps its own case
            if c.kind == "say" and #o <= 4 and not o:find("%l") then o = o:lower() end
            local r = Case(o, repl, firstWord)
            if c.kind == "say" then
              -- a whole line in the middle of a message reads as its own sentence: "..., Me back." -> "... Me back."
              local prev = out[#out]
              if prev and prev.k == "o" and prev.v:find(",%s*$") then prev.v = prev.v:gsub(",(%s*)$", ".%1")
              elseif #out > 0 and not (prev and prev.k == "o" and prev.v:find("[%.!%?]%s*$")) then
                -- (1.4.6) a full sentence after words ("get a life lol"): end the words first, "get a life. Amusing, young one."
                local before = out[#out - 1]
                if r:find("[%.!%?]$") and prev and prev.k == "o" and not prev.v:find("%S") then
                  if not (before and before.v:find("[%.!%?%*]$")) then prev.v = "." .. prev.v end
                else r = r:gsub("^(%u)(%l)", function(a, b) return a:lower() .. b end) end
              end
              local nx = t[used[#used] + 1]
              -- (1.4.6) "hello?" -> "Greetings.?": the line brings its own end mark
              if nx and nx.k == "o" and r:find("[%.!%?]$") then nx.v = nx.v:gsub("^[,%.%?!]+", "") end
            end
            -- the same line twice in a row ("going to bed, good night all"): say it once
            local twice = c.kind == "say" and lastSay == c.id
            if twice then
              local prev = out[#out]
              if prev and prev.k == "o" then prev.v = prev.v:gsub("[%.,]?%s*$", "") end
            else
              out[#out + 1] = { k = "r", v = r }
            end
            if c.kind == "say" then lastSay, usedSay = c.id, true end
            i = used[#used] + 1
            done = true
            break
          end
        end
      end
    end
    if not done then
      out[#out + 1] = tok; i = i + 1
      if tok.k == "w" or tok.k == "p" then lastSay = nil end
    end
    if tok.k == "w" or tok.k == "p" then firstWord = false end
  end

  -- 3. words: the accent's own words first, then its word bank (def.lex, by E.WORD_GROUP), then its sound rules
  local lex, groups = def.lex, E.WORD_GROUP or {}
  local lexChance = (def.lexChance or { 0.4, 0.75, 1 })[strength] or 1
  local rules = def.rules
  def._last = def._last or {}
  local seen = {}   -- nothing picked twice in one message if the pool can help it
  local function Fresh(list, group)
    if type(list) ~= "table" then return list end
    if #list == 1 then return list[1] end
    local tries, pick = 0
    repeat
      pick = list[random(#list)]; tries = tries + 1
    until (pick ~= def._last[group] and not seen[pick]) or tries > 8
    def._last[group] = pick; seen[pick] = true
    return pick
  end
  local words = def.words or {}
  local more = strength >= 2 and def.more or {}
  local drop = strength >= 2 and def.drop or {}
  local heavy = strength >= 3 and def.heavy or {}
  local suffix = (strength >= (def.suffixAt or 3)) and def.suffix or nil
  local res, first = {}, true
  for n, tok in ipairs(out) do
    if tok.k == "w" then
      local k = Key(tok.v)
      local repl = heavy[k] or more[k] or words[k]
      local group = not repl and lex and groups[k]
      -- (1.4.3) the same word can mean two things in chat: leave it alone when the words around it say so
      if tok.keep or E.KeepHere(k, out, n) then repl, group = nil, nil end
      if group and opts.keepSwears and E.SWEAR_GROUP[group] then group = nil end
      if group and lex[group] and random() < (E.SWEAR_GROUP[group] and 1 or lexChance) then repl = lex[group] end
      if repl then
        local pool = repl
        repl = Fresh(repl, group or k)
        -- (1.4.7) keep only a swap that fits here (see Fits); thee or thou by place
        do
          local g = group or E.WORD_GROUP[k]
          local pw, nw = Near(out, n, -1), Near(out, n, 1)
          if type(pool) == "table" and #pool == 2 and ((pool[1] == "thee" and pool[2] == "thou") or (pool[1] == "thou" and pool[2] == "thee")) then
            repl = (pw and THEE_PREV[pw]) and "thee" or "thou"
          elseif not Fits(g, k, repl, pw, nw) then
            local alt
            if type(pool) == "table" then
              local s0 = random(#pool)
              for d = 0, #pool - 1 do local x = pool[(s0 + d - 1) % #pool + 1]; if Fits(g, k, x, pw, nw) then alt = x; break end end
            end
            repl = alt or tok.v
          end
          -- "hey can you help me" -> "Well met, can you help me"
          if g and COMMA_AFTER[g] and nw and repl ~= tok.v and not repl:find("[,%.!%?]$") then
            local nt = out[n + 1]
            if nt and nt.k == "o" and nt.v:match("^%s+$") then repl = repl .. "," end
          end
        end
        -- "the horde" -> "the the Horde": a swap that brings its own "the" drops it when one is already there
        -- (1.4.3) "pretty a cakewalk", "so a riot": a swap with its own "a" can't follow so/pretty/very. Pick another, or keep
        if repl:find("^[Aa]n? ") then
          local pw = Near(out, n, -1)
          if pw and (INTENS[pw] or E.DETERMINER[pw]) then
            local list = heavy[k] or more[k] or words[k] or (group and lex[group])
            local ok
            if type(list) == "table" then for _, x in ipairs(list) do if not x:find("^[Aa]n? ") and not x:find(" ") then ok = x; break end end end
            repl = ok or tok.v
          end
        end
        -- (1.4.3) "pretty nothing", "so easy kill": after so/pretty/very only a one-word describing swap fits
        do
          local pw = Near(out, n, -1)
          if pw and INTENS[pw] and (repl:find(" ") or repl:lower() == "nothing") then repl = tok.v end
        end
        -- (1.4.0) never the same word twice in a row ("it's ornery ornery"): pick again, or leave the word alone
        do
          local prevWord
          for j = #res, 1, -1 do if res[j]:find("%S") then prevWord = res[j]:lower(); break end end
          if prevWord then
            local tries = 0
            while repl:lower() == prevWord and tries < 4 do repl = Fresh(heavy[k] or more[k] or words[k] or lex[group], group or k); tries = tries + 1 end
            if repl:lower() == prevWord then repl = tok.v end
          end
        end
        -- (1.4.0) and "my buddy" -> "my my dear": the same for a swap that brings its own "my" / "me"
        if repl:find("^[Mm][ye] ") then
          for j = #res, 1, -1 do
            local p = res[j]
            if p:find("%S") then
              local pl = p:lower()
              if pl == "my" or pl == "me" or pl == "our" or pl == "your" or pl == "yer" or pl == "the" or pl == "a" or pl == "his" or pl == "her" or pl == "their" then repl = repl:gsub("^[Mm][ye] ", "") end
              break
            end
          end
        end
        if repl:find("^[Tt]his ") or repl:find("^[Tt]hat ") then
          local pw = Near(out, n, -1)
          if pw and E.DETERMINER[pw] then repl = repl:gsub("^%a+ ", "") end
        end
        if repl:find("^[Tt]he ") then
          for j = #res, 1, -1 do
            local p = res[j]
            if p:find("%S") then
              -- (1.4.1) any word that already picks the thing out: "any horde players" must not become "any the Horde players"
              if p:lower():find("^%a+$") and E.DETERMINER[p:lower()] then repl = repl:gsub("^[Tt]he ", "") end
              break
            end
          end
        end
        res[#res + 1] = Case(tok.v, repl, first)
      elseif drop[k] and not first then
        res[#res + 1] = "\003"   -- dropped (its space is cleaned up below)
      else
        local w = tok.v
        local keep = E.KEEP[k]
        if rules and not keep then
          for _, rule in ipairs(rules) do
            if strength >= (rule.min or 1) and random() < (rule.chance or 1)
              and not (E.NO_SUFFIX[w:lower()] and rule[1]:find("ing", 1, true)) then   -- (1.2.0) "ding" stays "ding"
              local lw = w:lower()
              local nw, hits = lw:gsub(rule[1], rule[2])
              if hits > 0 and nw ~= lw then w = Case(w, nw, first); if rule.stop then break end end
            end
          end
        end
        if suffix and not keep then
          for _, rule in ipairs(suffix) do
            local lw = w:lower()
            if lw:find(rule[1]) and #lw > (rule[3] or 3) and not E.NO_SUFFIX[lw] then
              w = Case(w, (lw:gsub(rule[1], rule[2])), first)
              break
            end
          end
        end
        res[#res + 1] = w
      end
      first = false
    else
      res[#res + 1] = tok.v
      if tok.k == "r" or tok.k == "p" then first = false end
    end
  end
  s = table.concat(res)
  s = s:gsub("%s*\003", ""):gsub("^\003%s*", "")
  s = s:gsub("%s%s+", " "):gsub("%s+([,%.!%?;:])", "%1"):gsub("^%s+", ""):gsub("%s+$", "")

  -- 3b. little asides dropped in at commas ("..., by the Light, ...")
  local _, nwords = text:gsub("%S+", "")
  if def.interject and nwords >= 8 then
    local ic = (def.interjectChance or { 0, 0.2, 0.4 })[strength] or 0
    -- (1.1.0) one aside per message at most, and never one the line already says ("partner, partner")
    local used = false
    s = s:gsub("()(,)( )", function(pos, _, sp)
      if used or random() >= ic then return end
      -- (1.2.0) only after a real clause (3+ words since the sentence began): never inside a short built-in line
      -- like "Thanks, I suppose." or "Much obliged, partner."
      local clause = s:sub(1, pos - 1):match("[^%.!%?]*$") or ""
      local _, nw = clause:gsub("%S+", "")
      if nw < 3 then return end
      local w = Fresh(def.interject, "_interject")
      if s:lower():find(w:lower(), 1, true) then return end
      used = true
      return ", " .. w .. "," .. sp
    end)
  end

  -- 4. the accent's own touches (word order, stutters, all caps...)
  if def.post then
    local ok, r = pcall(def.post, s, strength, opts)
    if ok and type(r) == "string" then s = r end
  end

  -- 5. flavor
  if not opts.noFlavor then
    -- tags like "Heh." or "Lok'tar!" are seasoning: rare, never two messages in a row, never the same one twice running
    local chance = ((def.flavor or { 0.06, 0.18, 0.33 })[strength] or 0) * 0.45
    if usedSay then chance = chance * 0.5 end   -- a whole line was already swapped: less extra
    if def._flavored then chance = 0 end
    def._flavored = false
    local function Pick(list)
      local tries, x = 0
      repeat x = list[random(#list)]; tries = tries + 1 until x ~= def._lastFlavor or tries > 6 or #list == 1
      return x
    end
    local function Has(x) local bare = x:lower():gsub("[%p%s]", ""); return bare ~= "" and s:lower():gsub("[%p%s]", ""):find(bare, 1, true) end
    if def.openers and random() < chance * 0.6 then
      local op = Pick(def.openers)
      if not Has(op) then
        if op:find("[,:]$") then s = s:gsub("^(%u)(%l)", function(a, b) return a:lower() .. b end) end
        s = op .. " " .. s
        def._flavored, def._lastFlavor = true, op
      end
    end
    if def.closers and random() < chance then
      local cl = Pick(def.closers)
      if not Has(cl) then
        if not s:find("[%.!%?]$") then
          s = s .. (def.closerJoin or ".")
          if def.closerJoin == "," then cl = cl:gsub("^(%u)(%l)", function(a, b) return a:lower() .. b end) end
        end
        s = s .. " " .. cl
        def._flavored, def._lastFlavor = true, cl
      end
    end
  end
  if def.caps == "upper" then s = s:upper() elseif def.caps == "lower" then s = s:lower() end

  -- a whole line we put in ends a sentence: what follows starts with a capital
  s = s:gsub("([%.!%?]%s+)(%l)", function(a, b) return a .. b:upper() end)
  -- the line starts with a capital if yours did
  if text:match("^%s*%u") then s = s:gsub("^(%l)", string.upper) end
  -- one *emote* per message is flavor; more is noise
  do
    local seenEmote = false
    s = s:gsub("%s*(%*[^%*]+%*)%s*", function(e)
      if seenEmote then return " " end
      seenEmote = true
      return " " .. e .. " "
    end)
    s = s:gsub("%s%s+", " "):gsub("^%s+", ""):gsub("%s+$", ""):gsub("%s+([,%.!%?])", "%1")
  end
  -- a comma right before the end or a full stop is a leftover: drop it
  s = s:gsub(",%s*([%.!%?])", "%1"):gsub(",%s*$", "")
  -- "a" or "an" to fit the word that now follows
  s = s:gsub("%f[%a]([Aa])(n?) (%a+)", function(a, n, w)
    local l = w:sub(1, 1):lower()
    if l == "h" then return a .. n .. " " .. w end
    if l == "u" then
      -- (1.4.0) "an unwanted guest", "an ugly one", but "a unit", "a user", "a unique one"
      local lw = w:lower()
      if #lw < 2 or lw:find("^uni") or lw:find("^us[eu]") or lw:find("^ut[ie]") or lw:find("^ur[aeio]") or lw:find("^u[bfkv]") then return a .. " " .. w end
      return a .. "n " .. w
    end
    if l:find("[aeio]") then return a .. "n " .. w end
    return a .. " " .. w
  end)
  return E.Restore(s, saved)
end

-- a line too long for one message: the place to cut it (never inside a link)
function E.SplitPoint(s, max)
  max = max or 255
  if #s <= max then return nil end
  local best
  for p = max, 40, -1 do
    if s:sub(p, p) == " " then
      local head = s:sub(1, p - 1)
      local _, opens = head:gsub("|c", "")
      local _, closes = head:gsub("|r", "")
      local _, h1 = head:gsub("|H", "")
      local _, h2 = head:gsub("|h|r", "")
      if opens == closes and h1 <= h2 + (opens - closes) then best = p; break end
    end
  end
  return best
end

return E
