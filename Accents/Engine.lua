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
  def = "definitely", r = "are", prob = "probably", probs = "probably", srsly = "seriously", ez = "easy", lf = "looking for",
}

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
}

---------------------------------------------------------------------------
-- lines that also count at the very start or end of a message ("omg that was close", "that was crazy lol")
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
  local nx = t[last + 1]
  if not nx then return true end
  if nx.k == "p" then return true end
  if nx.k ~= "o" then return false end
  if nx.v:find("[,%.!%?;:%(%)]") then return true end
  local after = t[last + 2]
  return after == nil or after.k == "p"
end

---------------------------------------------------------------------------
-- The accent itself
---------------------------------------------------------------------------
-- E.Apply(key, text, strength, opts) -> new text. opts.names: player names to leave alone,
-- opts.noFlavor: no openers or closers (used when a line is too long)
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
  for _, tok in ipairs(t) do
    if tok.k == "w" then
      local full = E.SHORT[Key(tok.v)]
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
          end
          if used and opts.keepSwears and c.kind == "phrase" and E.SWEAR_PHRASE[c.id] then used = nil end
          if used and (c.kind ~= "say" or random() < sayChance) then
            local repl = Pick(c.out)
            local orig = {}
            for _, u in ipairs(used) do orig[#orig + 1] = t[u].v end
            local r = Case(table.concat(orig, " "), repl, firstWord)
            if c.kind == "say" then
              -- a whole line in the middle of a message reads as its own sentence: "..., Me back." -> "... Me back."
              local prev = out[#out]
              if prev and prev.k == "o" and prev.v:find(",%s*$") then prev.v = prev.v:gsub(",(%s*)$", ".%1")
              elseif #out > 0 and not (prev and prev.k == "o" and prev.v:find("[%.!%?]%s*$")) then r = r:gsub("^(%u)(%l)", function(a, b) return a:lower() .. b end) end
              local nx = t[used[#used] + 1]
              if nx and nx.k == "o" and r:find("[%.!%?]$") then nx.v = nx.v:gsub("^[,%.]", "") end
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
      if group and opts.keepSwears and E.SWEAR_GROUP[group] then group = nil end
      if group and lex[group] and random() < (E.SWEAR_GROUP[group] and 1 or lexChance) then repl = lex[group] end
      if repl then
        repl = Fresh(repl, group or k)
        -- "the horde" -> "the the Horde": a swap that brings its own "the" drops it when one is already there
        if repl:find("^[Tt]he ") then
          for j = #res, 1, -1 do
            local p = res[j]
            if p:find("%S") then
              if p:lower():find("^%a+$") and (p:lower() == "the" or p:lower() == "a" or p:lower() == "an" or p:lower() == "this" or p:lower() == "that" or p:lower() == "my" or p:lower() == "our" or p:lower() == "your") then repl = repl:gsub("^[Tt]he ", "") end
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
            if strength >= (rule.min or 1) and random() < (rule.chance or 1) then
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
    s = s:gsub(",( )", function(sp)
      if random() < ic then return ", " .. Fresh(def.interject, "_interject") .. "," .. sp end
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
  s = s:gsub("%f[%a]([Aa])(n?) (%a)", function(a, n, c)
    local l = c:lower()
    if l == "h" or l == "u" then return a .. n .. " " .. c end
    if l:find("[aeio]") then return a .. "n " .. c end
    return a .. " " .. c
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
