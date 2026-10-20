-- Languages, shared by Dalorrian's addons (each addon carries its own copy).
-- The addon's text is written in English. Each language file (Locales\*.lua) maps English pieces of text
-- to that language. Everything shown on screen passes through ns.Tr on its way out, which swaps each known
-- English piece for its translation and leaves the rest (names, numbers, colours) as they are.
-- The language follows the game's own unless the player picks one in Settings & Help.
local ADDON, ns = ...

ns.LANGS = {
  { code = "auto", name = "Auto" },
  { code = "enUS", name = "English" },
  { code = "deDE", name = "Deutsch" },
  { code = "frFR", name = "Français" },
  { code = "esES", name = "Español (EU)" },
  { code = "esMX", name = "Español (AL)" },
  { code = "ptBR", name = "Português" },
  { code = "itIT", name = "Italiano" },
  { code = "ruRU", name = "Русский", font = "Fonts\\FRIZQT___CYR.TTF" },
  { code = "koKR", name = "한국어", font = "Fonts\\2002.TTF" },
  { code = "zhCN", name = "简体中文", font = "Fonts\\ARKai_T.ttf" },
  { code = "zhTW", name = "繁體中文", font = "Fonts\\bLEI00D.ttf" },
}
ns.LOCALES = ns.LOCALES or {}
local SV = ADDON .. "_Lang"   -- saved: "auto" or a language code
local L = { code = "enUS", map = nil, byStart = nil, cache = {}, cacheN = 0, ready = false }
ns.L = L

local function Pick(choice)
  local code = choice
  if not code or code == "auto" then code = (GetLocale and GetLocale()) or "enUS" end
  if code == "enGB" then code = "enUS" end
  if code ~= "enUS" and not ns.LOCALES[code] then code = "enUS" end
  return code
end

function L.Activate(choice)
  local code = Pick(choice)
  L.ready = true
  L.code, L.map, L.byStart, L.cache, L.cacheN, L.font = code, nil, nil, {}, 0, nil
  for _, lg in ipairs(ns.LANGS) do if lg.code == code then L.font = lg.font end end
  if GetLocale and GetLocale() == code then L.font = nil end   -- the game's own font already covers its language
  if code == "enUS" then return code end
  local ok, map = pcall(ns.LOCALES[code])
  if not ok or type(map) ~= "table" then L.code = "enUS"; return "enUS" end
  for _, keep in ipairs({ "Dalorrian", "Discord", "CurseForge", "Twitch", "YouTube", "Claude Code" }) do map[keep] = keep end
  L.map = map
  -- index the English pieces by their first two characters, longest first, so a line is translated in one pass
  local by = {}
  for k in pairs(map) do
    local p = k:sub(1, 2)
    by[p] = by[p] or {}
    table.insert(by[p], k)
  end
  for _, list in pairs(by) do table.sort(list, function(a, b) return #a > #b end) end
  L.byStart = by
  return code
end

local function isWord(c) return c ~= "" and c:find("^[%w']") ~= nil end

function L.Tr(s)
  if not L.ready then
    if not ns.langLoaded then return s end
    L.Activate(_G[SV])
  end
  local map = L.map
  if not map or type(s) ~= "string" or s == "" then return s end
  local hit = map[s]
  if hit then return hit end
  local c = L.cache[s]
  if c then return c end
  local by, out, n, i, last = L.byStart, {}, #s, 1, 1
  local fresh = true
  while i <= n do
    local ch = s:sub(i, i)
    if ch == "|" then
      local nx = s:sub(i + 1, i + 1)
      if nx == "c" then i = i + 10
      elseif nx == "T" or nx == "H" or nx == "A" or nx == "K" then
        local e = s:find("|[thak]", i + 2); i = e and (e + 2) or (n + 1)
      else i = i + 2 end
      fresh = true
    elseif (ch:find("[%w%%]") and (fresh or not isWord(s:sub(i - 1, i - 1)))) or (ch == "'" and s:sub(i + 1, i + 1) == "s") then
      fresh = false
      local list, found = by[s:sub(i, i + 1)], nil
      if list then
        for _, k in ipairs(list) do
          local kn = #k
          if s:sub(i, i + kn - 1) == k then
            local after = s:sub(i + kn, i + kn)
            if not (isWord(k:sub(-1)) and isWord(after)) then found = k; break end
          end
        end
      end
      if found then
        out[#out + 1] = s:sub(last, i - 1); out[#out + 1] = map[found]
        i = i + #found; last = i
      else
        i = i + 1
        while i <= n and isWord(s:sub(i, i)) and not (s:sub(i, i + 1) == "'s" and not isWord(s:sub(i + 2, i + 2))) do i = i + 1 end
      end
    else
      i = i + 1; fresh = false
    end
  end
  out[#out + 1] = s:sub(last)
  local res = table.concat(out)
  if L.cacheN > 3000 then L.cache, L.cacheN = {}, 0 end
  L.cache[s] = res; L.cacheN = L.cacheN + 1
  return res
end
ns.Tr = L.Tr

-- a font string whose text is translated on its way to the screen
function ns.TrText(fs)
  if not fs or rawget(fs, "__tr") or not fs.SetText then return fs end
  fs.__tr = true
  local raw = fs.SetText
  fs.SetText = function(self, txt, ...)
    local r = raw(self, L.Tr(txt), ...)
    if L.font and self.GetFont then
      local f, size, flags = self:GetFont()
      if f ~= L.font and size then pcall(self.SetFont, self, L.font, size, flags) end
    end
    return r
  end
  return fs
end

-- CreateFrame that translates: font strings made on these frames, and button labels
function ns.CreateFrame(kind, ...)
  local f = CreateFrame(kind, ...)
  if f and not rawget(f, "__trf") then
    f.__trf = true
    local rawFS = f.CreateFontString
    if rawFS then f.CreateFontString = function(self, ...) return ns.TrText(rawFS(self, ...)) end end
    local t = f.GetObjectType and f:GetObjectType()
    if (t == "Button" or t == "CheckButton") and f.SetText then
      local rawSet = f.SetText
      f.SetText = function(self, txt, ...) return rawSet(self, L.Tr(txt), ...) end
    end
  end
  return f
end

-- GameTooltip, translated: use ns.Tip:AddLine(...) the same way as GameTooltip:AddLine(...)
ns.Tip = setmetatable({}, { __index = function(t, k)
  local real = GameTooltip
  local v = real and real[k]
  if type(v) ~= "function" then return v end
  if k == "AddLine" or k == "SetText" then
    return function(self, text, ...) return v(real, L.Tr(text), ...) end
  elseif k == "AddDoubleLine" then
    return function(self, a, b, ...) return v(real, L.Tr(a), L.Tr(b), ...) end
  end
  return function(self, ...) if self == t then self = real end return v(self, ...) end
end })

-- print, translated
function ns.print(...)
  local n, args = select("#", ...), { ... }
  for i = 1, n do if type(args[i]) == "string" then args[i] = L.Tr(args[i]) end end
  return print(unpack(args, 1, n))
end

-- the Language row for Settings & Help: one button that steps through the languages
function ns.LangSetting()
  local choices = {}
  for _, lg in ipairs(ns.LANGS) do
    if lg.code == "auto" or lg.code == "enUS" or ns.LOCALES[lg.code] then choices[#choices + 1] = { lg.name, lg.code } end
  end
  return { label = "Language", cycle = true, choices = choices,
    get = function() return _G[SV] or "auto" end,
    set = function(v)
      _G[SV] = v
      if Pick(v) ~= L.code then
        ns.print("|cffffd200" .. ADDON .. "|r: Language saved. Click the green check (or type /reload) to switch.")
      end
    end,
    -- a different language is picked than the one showing: the green check reloads to switch
    pending = function() return Pick(_G[SV]) ~= L.code end,
    apply = function()
      local reload = (C_UI and C_UI.Reload) or ReloadUI
      if reload then reload() end
    end }
end

local lf = CreateFrame("Frame")
lf:RegisterEvent("ADDON_LOADED")
lf:SetScript("OnEvent", function(self, _, name)
  if name ~= ADDON then return end
  self:UnregisterEvent("ADDON_LOADED")
  ns.langLoaded = true
  L.Activate(_G[SV])
end)
