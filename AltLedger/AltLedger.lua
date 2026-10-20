-- Dalorrian's Alt Ledger: every character you play, in one window. Level, gold, rested XP, free bag space,
-- professions and where you left them. Find any item across all of them, and see the counts on item tooltips.
-- Each character shows up the first time you log in on it after installing. /alts for the window.

local ADDON, ns = ...
local DB
local W = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local DEFAULTS = { realm = "all", sort = "level", tab = "chars" }
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local Tip = ns.Tip or GameTooltip
local CF = ns.CreateFrame or CreateFrame   -- frames whose text is translated
local function Say(msg) P("|cffffd100Alt Ledger:|r " .. msg) end
local GICON = "|TInterface\\MoneyFrame\\UI-GoldIcon:10:10:2:0|t"
local SICON = "|TInterface\\MoneyFrame\\UI-SilverIcon:10:10:2:0|t"
local CICON = "|TInterface\\MoneyFrame\\UI-CopperIcon:10:10:2:0|t"
local ICON = "Interface\\Icons\\INV_Misc_GroupNeedMore"

local function Commas(n)
  if BreakUpLargeNumbers then return BreakUpLargeNumbers(n) end
  local s = tostring(n)
  while true do
    local t, k = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
    s = t
    if k == 0 then return s end
  end
end
local function Money(c, short)
  c = c or 0
  local g, s, cp = math.floor(c / 10000), math.floor(c / 100) % 100, c % 100
  if short then
    if g > 0 then return Commas(g) .. GICON elseif s > 0 then return s .. SICON else return cp .. CICON end
  end
  local out = {}
  if g > 0 then out[#out + 1] = Commas(g) .. GICON end
  if g > 0 or s > 0 then out[#out + 1] = s .. SICON end
  out[#out + 1] = cp .. CICON
  return table.concat(out, " ")
end
local function ClassColor(class)
  local cc = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
  if cc then return cc.r, cc.g, cc.b end
  return 1, 1, 1
end
local function Hex(r, g, b) return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255) end
local function Ago(t)
  local s = time() - (t or time())
  if s < 120 then return Tr("Just now") end
  if s < 3600 then return string.format(Tr("%s min ago"), math.floor(s / 60)) end
  if s < 86400 then return string.format(Tr("%s hr ago"), math.floor(s / 3600)) end
  return string.format(Tr("%s days ago"), math.floor(s / 86400))
end
local function Played(sec)
  if not sec then return nil end
  local d, h, m = math.floor(sec / 86400), math.floor(sec / 3600) % 24, math.floor(sec / 60) % 60
  if d > 0 then return d .. "d " .. h .. "h" end
  return h .. "h " .. m .. "m"
end

---------------------------------------------------------------------------
-- this character, saved as you play: DB.chars[realm][name]
---------------------------------------------------------------------------
local ME, REALM, C   -- C is this character's entry
local function Char()
  if not DB or not ME then return end
  DB.chars[REALM] = DB.chars[REALM] or {}
  local c = DB.chars[REALM][ME] or {}
  DB.chars[REALM][ME] = c
  return c
end

local function MaxLevel()
  if GetMaxLevelForPlayerExpansion then local ok, v = pcall(GetMaxLevelForPlayerExpansion); if ok and v then return v end end
  if GetMaxPlayerLevel then local ok, v = pcall(GetMaxPlayerLevel); if ok and v then return v end end
  return MAX_PLAYER_LEVEL or 60
end

-- (1.2.0) who you are. WoW: Forever gives characters a surname and keeps names unique per ruleset (PvP, PvE...)
-- rather than per realm, so "Dalorrian Fury" and "Dalorrian Warlockian" are two characters, not one "Dalorrian"
local function Ruleset()
  local ok, on = pcall(function() return RegionalUniqueNamesEnabled and RegionalUniqueNamesEnabled() end)
  if not (ok and on) then return nil end
  local R = Enum and Enum.GameRule
  local function Is(rule) local o, v = pcall(C_GameRules.IsGameRuleActive, rule); return o and v end
  if C_GameRules and R then
    if R.PvPRuleset and Is(R.PvPRuleset) then return "PvP" end
    if R.RPRuleset and Is(R.RPRuleset) then return "RP" end
    if R.HardcoreRuleset and Is(R.HardcoreRuleset) then return "HC" end
  end
  return "PvE"
end
local function Who()
  local name, surname = UnitName("player")
  if surname and surname ~= "" then
    local sep = Constants and Constants.CharacterNameSeparatorConsts and Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR or " "
    name = name .. sep .. surname
  end
  return name, Ruleset() or (GetRealmName and GetRealmName()) or "?"
end

local function Snapshot(leaving)
  C = Char()
  if not C then return end
  C.own = true   -- logged in with Alt Ledger at least once
  C.seen = time()
  C.rested = GetXPExhaustion and GetXPExhaustion() or C.rested or 0
  C.resting = IsResting and IsResting() or false
  if leaving then return end   -- (1.2.0) while logging out the game reports 0 gold: keep what we had
  local _, class = UnitClass("player")
  local race = UnitRace("player")
  C.class, C.race = class, race
  C.faction = UnitFactionGroup and UnitFactionGroup("player") or C.faction
  C.level = UnitLevel("player")
  C.xp, C.xpMax = UnitXP("player"), UnitXPMax("player")
  C.rested = GetXPExhaustion and GetXPExhaustion() or 0
  C.resting = IsResting and IsResting() or false
  local m = GetMoney()
  if m and (m > 0 or not C.money) then C.money = m end
  C.zone = GetRealZoneText and GetRealZoneText() or C.zone
  local sub = GetSubZoneText and GetSubZoneText() or ""
  C.sub = (sub ~= "" and sub ~= C.zone) and sub or nil
  C.guild = IsInGuild and IsInGuild() and GetGuildInfo and GetGuildInfo("player") or nil
  DB.maxLevel = MaxLevel()
end

-- professions, by skill line so it works in every language
local PROF_IDS = { 171, 164, 333, 202, 182, 165, 186, 393, 197, 755, 773, 185, 129, 356 }
local SECONDARY = { [185] = true, [129] = true, [356] = true }
local PROF_EN = { Alchemy = 1, Blacksmithing = 1, Enchanting = 1, Engineering = 1, Herbalism = 1, Leatherworking = 1,
  Mining = 1, Skinning = 1, Tailoring = 1, Jewelcrafting = 1, Inscription = 1, Cooking = 2, ["First Aid"] = 2, Fishing = 2 }
local function ReadProfs()
  local out = {}
  local S = C_SkillInfo
  if S and S.GetSkillLineInfoByID then
    for _, id in ipairs(PROF_IDS) do
      local ok, info = pcall(S.GetSkillLineInfoByID, id)
      if ok and type(info) == "table" and not info.isHeader then
        local rank, max = tonumber(info.rank or info.skillRank) or 0, tonumber(info.maxRank or info.skillMaxRank) or 0
        if rank > 0 or max > 0 then
          out[#out + 1] = { name = info.name or info.skillName or "?", rank = rank, max = max, second = SECONDARY[id], id = id }
        end
      end
    end
    if #out > 0 then return out end
  end
  if GetProfessions and GetProfessionInfo then
    local list = { GetProfessions() }
    for i = 1, 6 do
      local idx = list[i]
      if idx then
        local name, _, rank, max, _, _, line = GetProfessionInfo(idx)
        if name then out[#out + 1] = { name = name, rank = rank or 0, max = max or 0, second = SECONDARY[line], id = line } end
      end
    end
    if #out > 0 then return out end
  end
  if GetNumSkillLines and GetSkillLineInfo then
    for i = 1, GetNumSkillLines() do
      local name, header, _, rank, _, _, max, abandon = GetSkillLineInfo(i)
      if name and not header and (abandon or PROF_EN[name]) then
        out[#out + 1] = { name = name, rank = rank or 0, max = max or 0, second = PROF_EN[name] == 2 }
      end
    end
  end
  return out
end
local function ScanProfs()
  C = C or Char()
  if not C then return end
  local ok, list = pcall(ReadProfs)
  if ok and list then
    table.sort(list, function(a, b) if (a.second and 1 or 0) ~= (b.second and 1 or 0) then return not a.second end return a.name < b.name end)
    C.profs = list
  end
end

-- bags, bank and what you wear, counted by item
local KEYRING = Enum and Enum.BagIndex and Enum.BagIndex.Keyring or -2
local function Slots(bag)
  if bag == KEYRING then
    if GetKeyRingSize then local ok, n = pcall(GetKeyRingSize); return ok and n or 0 end
  end
  local f = (C_Container and C_Container.GetContainerNumSlots) or GetContainerNumSlots
  if not f then return 0 end
  local ok, n = pcall(f, bag)
  return ok and tonumber(n) or 0
end
local function ItemAt(bag, slot)
  if C_Container and C_Container.GetContainerItemInfo then
    local ok, i = pcall(C_Container.GetContainerItemInfo, bag, slot)
    if ok and type(i) == "table" then return i.itemID, i.stackCount or 1, i.hyperlink end
    return
  end
  if GetContainerItemInfo then
    local _, count, _, _, _, _, link, _, _, id = GetContainerItemInfo(bag, slot)
    return id, count, link
  end
end
local function Name(id, link)
  if not DB.names[id] and link then
    local n = link:match("%[(.-)%]")
    if n and n ~= "" then DB.names[id] = n end
  end
end

local function BagIDs()
  local ids, seen = {}, {}
  local function add(b) if b and not seen[b] then seen[b] = true; ids[#ids + 1] = b end end
  for b = 0, (NUM_BAG_SLOTS or 4) do add(b) end
  if Enum and Enum.BagIndex and Enum.BagIndex.ReagentBag then add(Enum.BagIndex.ReagentBag) end
  return ids
end
local function BankIDs()
  local ids, seen = {}, {}
  local function add(b) if b and not seen[b] then seen[b] = true; ids[#ids + 1] = b end end
  local E = Enum and Enum.BagIndex
  if E and E.CharacterBankTab_1 then
    for i = 1, 9 do add(E["CharacterBankTab_" .. i]) end
  else
    add(BANK_CONTAINER or -1)
    for i = 1, (NUM_BANKBAGSLOTS or 6) do add((NUM_BAG_SLOTS or 4) + i) end
  end
  return ids
end

local function Count(ids, into)
  for _, bag in ipairs(ids) do
    for slot = 1, Slots(bag) do
      local id, n, link = ItemAt(bag, slot)
      if id then into[id] = (into[id] or 0) + (n or 1); Name(id, link) end
    end
  end
  return into
end

local function ScanBags()
  C = C or Char()
  if not C then return end
  local ids = BagIDs()
  local free, total = 0, 0
  for _, bag in ipairs(ids) do
    local n = Slots(bag)
    total = total + n
    for slot = 1, n do if not ItemAt(bag, slot) then free = free + 1 end end
  end
  C.bagFree, C.bagTotal = free, total
  ids[#ids + 1] = KEYRING
  C.bags = Count(ids, {})
  local worn = {}
  for slot = 1, 19 do
    local id = GetInventoryItemID and GetInventoryItemID("player", slot)
    if id then worn[id] = (worn[id] or 0) + 1; Name(id, GetInventoryItemLink and GetInventoryItemLink("player", slot)) end
  end
  C.worn = worn
end

local bankOpen = false
local function ScanBank()
  C = C or Char()
  if not (C and bankOpen) then return end
  C.bank = Count(BankIDs(), {})
  C.bankWhen = time()
end

-- (1.1.0) mail: what's in your mailbox when you open it, new mail waiting at login, and anything you
-- send to your own characters (so an alt shows it has mail before you ever log in on it)
local MAIL_ICON = "|TInterface\\Icons\\INV_Letter_15:14:14:0:0:64:64:5:59:5:59|t"
local function ScanMail()
  C = C or Char()
  if not (C and GetInboxNumItems) then return end
  local n = GetInboxNumItems() or 0
  local m = { letters = n, items = {}, money = 0, when = time() }
  for i = 1, n do
    local _, _, _, _, money, _, days, hasItem = GetInboxHeaderInfo(i)
    m.money = m.money + (tonumber(money) or 0)
    if days then
      local t = time() + days * 86400
      if not m.expires or t < m.expires then m.expires = t end
    end
    if hasItem and GetInboxItem then
      for a = 1, (ATTACHMENTS_MAX_RECEIVE or 16) do
        local name, id, _, count = GetInboxItem(i, a)
        if id then
          m.items[id] = (m.items[id] or 0) + (count or 1)
          if name and not DB.names[id] then DB.names[id] = name end
        end
      end
    end
  end
  C.mail, C.mailNew = m, false
end
local outgoing
local function WatchSends()
  if not (SendMail and hooksecurefunc) then return end
  hooksecurefunc("SendMail", function(to)
    local items = {}
    if GetSendMailItem then
      for a = 1, (ATTACHMENTS_MAX_SEND or 12) do
        local name, id, _, count = GetSendMailItem(a)
        if id then items[id] = (items[id] or 0) + (count or 1); if name and not DB.names[id] then DB.names[id] = name end end
      end
    end
    outgoing = { to = to, items = items, money = GetSendMailMoney and GetSendMailMoney() or 0 }
  end)
end
local function Sent()
  local o = outgoing
  outgoing = nil
  if not (o and type(o.to) == "string") then return end
  local name, realm = o.to:match("^([^%-]+)%-?(.*)$")
  if not name then return end
  if realm == "" then realm = REALM end
  for r, list in pairs(DB.chars) do
    if r:gsub("[%s%-']", ""):lower() == realm:gsub("[%s%-']", ""):lower() then
      for n, c in pairs(list) do
        if n:lower() == name:lower() and not (r == REALM and n == ME) then
          c.mail = c.mail or { letters = 0, items = {}, money = 0 }
          c.mail.letters = (c.mail.letters or 0) + 1
          c.mail.money = (c.mail.money or 0) + (o.money or 0)
          c.mail.items = c.mail.items or {}
          for id, k in pairs(o.items) do c.mail.items[id] = (c.mail.items[id] or 0) + k end
          local exp = time() + 30 * 86400
          if not c.mail.expires or exp < c.mail.expires then c.mail.expires = exp end
          c.mailNew = true
          return
        end
      end
    end
  end
end
local function Letters(c) return c.mail and c.mail.letters or 0 end

-- (1.2.0) characters you haven't logged into since installing Alt Ledger: if Syndicator (Baganator's data
-- addon) knows them, their class, gold, bags, bank, mail and gear come from there until you log in on them
local function CountInto(t, into)
  if type(t) ~= "table" then return end
  if t.itemID and (t.itemCount or 0) > 0 then
    into[t.itemID] = (into[t.itemID] or 0) + t.itemCount
    if t.itemLink and not DB.names[t.itemID] then
      local n = tostring(t.itemLink):match("%[(.-)%]")
      if n and n ~= "" then DB.names[t.itemID] = n end
    end
    return
  end
  for _, v in pairs(t) do if type(v) == "table" then CountInto(v, into) end end
end
local function FromSyndicator()
  local data = type(SYNDICATOR_DATA) == "table" and SYNDICATOR_DATA.Characters
  if type(data) ~= "table" then return 0 end
  local n = 0
  for _, ch in pairs(data) do
    local d = type(ch) == "table" and ch.details
    if type(d) == "table" and d.character and (d.realmNormalized or d.realm) then
      local realm = d.realmNormalized or d.realm
      if not (realm == REALM and d.character == ME) then
        DB.chars[realm] = DB.chars[realm] or {}
        local c = DB.chars[realm][d.character] or {}
        DB.chars[realm][d.character] = c
        if not c.own then   -- never logged in with Alt Ledger: Syndicator's copy is the best we have
          -- Syndicator keeps the game's inner race names ("Scourge"): show the ones players know
          local RACE = { Scourge = "Undead", NightElf = "Night Elf", BloodElf = "Blood Elf" }
          c.class, c.race, c.faction = d.className or c.class, RACE[d.race] or d.race or c.race, d.faction or c.faction
          c.money = tonumber(ch.money) or c.money
          local bags, bank, worn = {}, {}, {}
          CountInto(ch.bags, bags); CountInto(ch.bank, bank); CountInto(ch.bankTabs, bank); CountInto(ch.equipped, worn)
          c.bags, c.bank, c.worn = bags, bank, worn
          if next(bank) then c.bankWhen = c.bankWhen or 0 end
          local mail = {}
          CountInto(ch.mail, mail)
          if next(mail) then
            local k = 0
            for _ in pairs(ch.mail) do k = k + 1 end
            c.mail = { letters = k, items = mail, money = 0 }
          end
          c.synd = true
          n = n + 1
        elseif (c.money or 0) == 0 and (tonumber(ch.money) or 0) > 0 then
          c.money = tonumber(ch.money)   -- a 0 from an older Alt Ledger logging out
        end
      end
    end
  end
  return n
end
-- (1.2.0) older versions keyed characters by first name and realm; on WoW: Forever that mixed up characters
-- who share a first name. Their entries are cleared; this character is carried over.
local function Migrate()
  local old = GetRealmName and GetRealmName()
  if not old or old == REALM or not DB.chars[old] then return end
  local first = UnitName("player")
  local mine = DB.chars[old][first]
  local _, class = UnitClass("player")
  DB.chars[REALM] = DB.chars[REALM] or {}
  if mine and mine.class == class and not DB.chars[REALM][ME] then
    mine.money = nil   -- may be another character's; refreshed in a moment
    DB.chars[REALM][ME] = mine
  end
  DB.chars[old] = nil
end

---------------------------------------------------------------------------
-- reading it back
---------------------------------------------------------------------------
local function RestedNow(c, live)
  if not c.xpMax or c.xpMax <= 0 or (c.level or 0) >= (DB.maxLevel or 60) then return nil end
  local r = c.rested or 0
  if not live and c.seen then   -- while logged out you keep resting: 5% of a level every 8 hours in an inn or city, a quarter of that outside
    local hours = (time() - c.seen) / 3600
    r = r + c.xpMax * 0.05 * (c.resting and 1 or 0.25) * hours / 8
  end
  return math.min(r, c.xpMax * 1.5)
end

-- (1.4.0) the Professions column: each main profession's icon and skill ("[icon] 112  [icon] 45")
local PROF_ICON = { [171] = "Trade_Alchemy", [164] = "Trade_BlackSmithing", [333] = "Trade_Engraving", [202] = "Trade_Engineering",
  [182] = "Spell_Nature_NatureTouchGrow", [165] = "INV_Misc_ArmorKit_17", [186] = "Trade_Mining", [393] = "INV_Misc_Pelt_Wolf_01",
  [197] = "Trade_Tailoring", [755] = "INV_Misc_Gem_01", [773] = "INV_Inscription_Tradeskill01", [185] = "INV_Misc_Food_15",
  [129] = "Spell_Holy_SealOfSacrifice", [356] = "Trade_Fishing" }
local PROF_BY_NAME = { Alchemy = 171, Blacksmithing = 164, Enchanting = 333, Engineering = 202, Herbalism = 182, Leatherworking = 165,
  Mining = 186, Skinning = 393, Tailoring = 197, Jewelcrafting = 755, Inscription = 773, Cooking = 185, ["First Aid"] = 129, Fishing = 356 }
local function ProfText(c)
  local out = {}
  for _, p in ipairs(c.profs or {}) do
    if not p.second then
      local icon = PROF_ICON[p.id or PROF_BY_NAME[p.name] or 0]
      local tag = icon and ("|TInterface\\Icons\\" .. icon .. ":14:14:0:0:64:64:5:59:5:59|t") or (p.name:sub(1, 3))
      out[#out + 1] = tag .. " " .. (p.rank or 0)
    end
  end
  if #out == 0 then return "|cff666666-|r" end
  return table.concat(out, "   ")
end

-- (1.3.0) Horde and Alliance kept apart: by default you only see your own side (Faction button to change it)
local function MyFaction() return (UnitFactionGroup and UnitFactionGroup("player")) or "Horde" end
local function OtherFaction() return MyFaction() == "Horde" and "Alliance" or "Horde" end
local function FactionOK(c)
  local f = DB.faction or "mine"
  if f == "both" or not c.faction then return true end
  return c.faction == (f == "mine" and MyFaction() or OtherFaction())
end
local function Chars()
  local out = {}
  for realm, list in pairs(DB.chars) do
    if DB.realm == "all" or realm == REALM then
      for name, c in pairs(list) do
        if FactionOK(c) then
          out[#out + 1] = { name = name, realm = realm, c = c, me = (realm == REALM and name == ME) }
        end
      end
    end
  end
  local function v(e, k)
    local c = e.c
    if k == "name" then return e.name end
    if k == "level" then return (c.level or 0) + ((c.xpMax or 0) > 0 and (c.xp or 0) / c.xpMax or 0) end
    if k == "money" then return c.money or 0 end
    if k == "rested" then local r = RestedNow(c, e.me); return r and c.xpMax and r / c.xpMax or -1 end
    if k == "bags" then return c.bagFree or 0 end
    if k == "zone" then return c.zone or "" end
    if k == "mail" then return Letters(c) + (c.mailNew and 0.5 or 0) end
    if k == "played" then return c.played or 0 end
    if k == "profs" then local t = 0; for _, p in ipairs(c.profs or {}) do if not p.second then t = t + (p.rank or 0) end end; return t end
    return 0
  end
  local k = DB.sort or "level"
  table.sort(out, function(a, b)
    local x, y = v(a, k), v(b, k)
    if x == y then return a.name < b.name end
    if k == "name" or k == "zone" then return x < y end
    return x > y
  end)
  return out
end

-- every character holding an item: { { name, realm, class, bags, bank, worn, total }, ... }, grand total
local function Holders(id)
  local out, total = {}, 0
  for realm, list in pairs(DB.chars) do
    for name, c in pairs(list) do
      if not FactionOK(c) then c = {} end   -- the other side's characters don't count
      local b, k, w = c.bags and c.bags[id] or 0, c.bank and c.bank[id] or 0, c.worn and c.worn[id] or 0
      local m = c.mail and c.mail.items and c.mail.items[id] or 0
      local t = b + k + w + m
      if t > 0 then
        out[#out + 1] = { name = name, realm = realm, class = c.class, bags = b, bank = k, worn = w, mail = m, total = t }
        total = total + t
      end
    end
  end
  table.sort(out, function(a, b) if a.total == b.total then return a.name < b.name end return a.total > b.total end)
  return out, total
end
local function Where(h)
  local parts = {}
  if h.bags > 0 then parts[#parts + 1] = Tr("Bags") .. " " .. h.bags end
  if h.bank > 0 then parts[#parts + 1] = Tr("Bank") .. " " .. h.bank end
  if (h.mail or 0) > 0 then parts[#parts + 1] = Tr("Mail") .. " " .. h.mail end
  if h.worn > 0 then parts[#parts + 1] = Tr("Equipped") end
  return table.concat(parts, ", ")
end

---------------------------------------------------------------------------
-- item tooltips: how many of it each of your characters has
---------------------------------------------------------------------------
local function AddCounts(tt, link)
  if not (DB and DB.tips and link) then return end
  local id = tonumber(tostring(link):match("item:(%d+)")) or (C_Item and C_Item.GetItemInfoInstant and C_Item.GetItemInfoInstant(link))
  if not id then return end
  local list, total = Holders(id)
  if total == 0 then return end
  tt:AddLine(" ")
  tt:AddDoubleLine("|cffffd100" .. Tr("Alt Ledger") .. "|r", Tr("Total") .. ": " .. Commas(total), 1, 1, 1, 1, 1, 1)
  for i, h in ipairs(list) do
    if i > 8 then tt:AddLine("  ...", 0.6, 0.6, 0.6) break end
    local r, g, b = ClassColor(h.class)
    tt:AddDoubleLine("  " .. h.name .. ((h.realm ~= REALM) and (" - " .. h.realm) or ""), h.total .. "  |cff999999(" .. Where(h) .. ")|r", r, g, b, 1, 1, 1)
  end
  tt:Show()
end
local function HookTooltips()
  if TooltipDataProcessor and TooltipDataProcessor.AddTooltipPostCall and Enum and Enum.TooltipDataType then
    TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, function(tt)
      if tt ~= GameTooltip and tt ~= ItemRefTooltip then return end
      local ok, _, link = pcall(TooltipUtil.GetDisplayedItem, tt)
      if ok and link then pcall(AddCounts, tt, link) end
    end)
  else
    for _, tt in ipairs({ GameTooltip, ItemRefTooltip }) do
      if tt and tt.HookScript then
        tt:HookScript("OnTooltipSetItem", function(self)
          local _, link = self:GetItem()
          if link then pcall(AddCounts, self, link) end
        end)
      end
    end
  end
end

---------------------------------------------------------------------------
-- the window: Characters, and Find An Item
---------------------------------------------------------------------------
local win
local WW, ROWH = 820, 20   -- (1.4.0) wider for Played and Professions
local COLS = {
  -- (1.0.1) everything ends before the scroll bar
  { key = "name", label = "Character", x = 30, w = 136, justify = "LEFT" },
  { key = "level", label = "Level", x = 168, w = 36, justify = "RIGHT" },
  { key = "money", label = "Gold", x = 208, w = 104, justify = "RIGHT" },
  { key = "rested", label = "Rested", x = 316, w = 52, justify = "RIGHT" },
  { key = "bags", label = "Free Bag Space", x = 372, w = 84, justify = "RIGHT" },
  { key = "played", label = "Played", x = 462, w = 64, justify = "RIGHT" },        -- (1.4.0)
  { key = "profs", label = "Professions", x = 534, w = 120, justify = "LEFT" },    -- (1.4.0)
  { key = "zone", label = "Zone", x = 658, w = 84, justify = "LEFT" },
  { key = "mail", label = "Mail", x = 744, w = 46, justify = "RIGHT" },   -- (1.1.0) was Last Seen, now in the hover
}
-- (1.3.0) one line per character holding it, with where it is in its own column
local FCOLS = {
  { key = "item", label = "Item", x = 30, w = 260, justify = "LEFT" },
  { key = "who", label = "Who Has It", x = 296, w = 170, justify = "LEFT" },
  { key = "where", label = "Where", x = 472, w = 240, justify = "LEFT" },
  { key = "count", label = "Count", x = 716, w = 74, justify = "RIGHT" },
}

local function Solid(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetTexture(W); t:SetVertexColor(r, g, b, a or 1)
  return t
end
local function Text(parent, font)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlightSmall")
  fs:SetJustifyH("LEFT")
  return fs
end
local function FlatButton(parent, w, label, onClick)
  local b = CF("Button", nil, parent)
  b:SetSize(w, 20)
  b.bg = Solid(b, "BACKGROUND", 0.14, 0.15, 0.19); b.bg:SetAllPoints()
  b.label = Text(b); b.label:SetPoint("CENTER"); b.label:SetJustifyH("CENTER"); b.label:SetText(label)
  b.SetOn = function(self, on)
    self.on = on
    if on then self.bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9); self.label:SetTextColor(0.1, 0.1, 0.1)
    else self.bg:SetVertexColor(0.14, 0.15, 0.19, 1); self.label:SetTextColor(0.85, 0.85, 0.9) end
  end
  b:SetScript("OnEnter", function(self) if not self.on then self.bg:SetVertexColor(0.22, 0.23, 0.28, 1) end end)
  b:SetScript("OnLeave", function(self) self:SetOn(self.on) end)
  if onClick then b:SetScript("OnClick", onClick) end
  b:SetOn(false)
  return b
end

local Refresh, forgetArmed
local function Forget(realm, name)
  if DB.chars[realm] then DB.chars[realm][name] = nil end
  if DB.chars[realm] and not next(DB.chars[realm]) then DB.chars[realm] = nil end
  if realm == REALM and name == ME then C = nil end
end

local function Build()
  win = CF("Frame", "AltLedgerFrame", UIParent, "BackdropTemplate")
  win:SetSize(WW, 420)
  win:SetPoint("CENTER")
  win:SetFrameStrata("DIALOG")
  win:SetClampedToScreen(true)
  win:SetMovable(true); win:EnableMouse(true); win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  win:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = 1 })
  win:SetBackdropColor(0.05, 0.05, 0.07, 0.95)
  win:SetBackdropBorderColor(0.25, 0.26, 0.3, 1)
  tinsert(UISpecialFrames, "AltLedgerFrame")   -- Escape closes it

  local title = Text(win, "GameFontNormalLarge"); title:SetPoint("TOPLEFT", 14, -12); title:SetText("Alt Ledger")
  local close = CF("Button", nil, win)
  close:SetSize(20, 20); close:SetPoint("TOPRIGHT", -8, -8)
  close.label = Text(close, "GameFontHighlight"); close.label:SetPoint("CENTER"); close.label:SetText("x")
  close:SetScript("OnClick", function() win:Hide() end)

  -- tabs
  win.tabs = {}
  local tx = 14
  for _, t in ipairs({ { "Characters", "chars", 100 }, { "Find An Item", "find", 110 } }) do
    local b = FlatButton(win, t[3], t[1], function() DB.tab = t[2]; Refresh() end)
    b:SetPoint("TOPLEFT", tx, -40); b.value = t[2]
    win.tabs[#win.tabs + 1] = b
    tx = tx + t[3] + 4
  end
  -- realms
  win.realms = {}
  local rx = -14
  for _, t in ipairs({ { "This Realm", "this" }, { "All Realms", "all" } }) do
    local b = FlatButton(win, 90, t[1], function() DB.realm = t[2]; Refresh() end)
    b:SetPoint("TOPRIGHT", rx, -40); b.value = t[2]
    win.realms[#win.realms + 1] = b
    rx = rx - 94
  end
  -- (1.3.0) whose side: yours, the other one, or both (a click steps through them)
  local fb = FlatButton(win, 110, "", function()
    local nxt = { mine = "other", other = "both", both = "mine" }
    DB.faction = nxt[DB.faction or "mine"] or "mine"
    Refresh()
  end)
  win.factionBtn = fb
  -- search box (Find An Item)
  local box = CreateFrame("EditBox", "AltLedgerSearch", win, "InputBoxTemplate")
  box:SetSize(200, 20); box:SetPoint("TOPLEFT", tx + 14, -40)
  box:SetAutoFocus(false)
  box:SetScript("OnTextChanged", function() if win:IsShown() then Refresh() end end)
  box:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  box:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
  win.box = box
  win.hint = Text(win, "GameFontDisableSmall"); win.hint:SetPoint("LEFT", box, "RIGHT", 8, 0); win.hint:SetText("Type part of a name")

  -- column headers: click to sort
  win.heads, win.fheads = {}, {}
  for _, c in ipairs(COLS) do
    local h = CF("Button", nil, win)
    h:SetSize(c.w, 18); h:SetPoint("TOPLEFT", c.x, -70)
    h.label = Text(h, "GameFontNormalSmall"); h.label:SetAllPoints(); h.label:SetJustifyH(c.justify); h.label:SetText(c.label)
    h:SetScript("OnClick", function() DB.sort = c.key; Refresh() end)
    h.key = c.key
    win.heads[#win.heads + 1] = h
  end
  for _, c in ipairs(FCOLS) do
    local h = CF("Frame", nil, win)
    h:SetSize(c.w, 18); h:SetPoint("TOPLEFT", c.x, -70)
    h.label = Text(h, "GameFontNormalSmall"); h.label:SetAllPoints(); h.label:SetJustifyH(c.justify); h.label:SetText(c.label)
    win.fheads[#win.fheads + 1] = h
  end
  local line = Solid(win, "ARTWORK", GOLD[1], GOLD[2], GOLD[3], 0.35)
  line:SetPoint("TOPLEFT", 14, -90); line:SetPoint("TOPRIGHT", -14, -90); line:SetHeight(1)

  local sf = CreateFrame("ScrollFrame", nil, win, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 0, -94); sf:SetPoint("BOTTOMRIGHT", -28, 34)
  local child = CreateFrame("Frame", nil, sf)
  child:SetSize(WW - 28, 10)
  sf:SetScrollChild(child)
  win.child, win.rows = child, {}

  win.empty = Text(win, "GameFontDisable"); win.empty:SetPoint("TOP", 0, -120); win.empty:SetWidth(WW - 60); win.empty:SetJustifyH("CENTER")
  win.foot = Text(win, "GameFontDisableSmall"); win.foot:SetPoint("BOTTOMLEFT", 14, 12); win.foot:SetWidth(WW - 200)
  win.total = Text(win, "GameFontHighlightSmall"); win.total:SetPoint("BOTTOMRIGHT", -14, 12); win.total:SetJustifyH("RIGHT")
  win:Hide()
end

local function CharTip(row, e)
  local c = e.c
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  local r, g, b = ClassColor(c.class)
  GameTooltip:AddDoubleLine(e.name, e.realm, r, g, b, 0.6, 0.6, 0.6)
  local lvl = (c.level and (Tr("Level") .. " " .. c.level .. " ") or "") .. (c.race or "")
  if c.class and LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[c.class] then lvl = lvl .. " " .. LOCALIZED_CLASS_NAMES_MALE[c.class] end
  GameTooltip:AddLine(lvl, 1, 1, 1)
  if c.guild then GameTooltip:AddLine("<" .. c.guild .. ">", 0.4, 1, 0.4) end
  if (c.xpMax or 0) > 0 and (c.level or 0) < (DB.maxLevel or 60) then
    GameTooltip:AddDoubleLine(Tr("Experience"), Commas(c.xp or 0) .. " / " .. Commas(c.xpMax) .. "  (" .. math.floor((c.xp or 0) / c.xpMax * 100) .. "%)", 0.8, 0.8, 0.8, 1, 1, 1)
    local rest = RestedNow(c, e.me)
    if rest then
      GameTooltip:AddDoubleLine(Tr("Rested"), Commas(math.floor(rest)) .. "  (" .. math.floor(rest / c.xpMax * 100) .. "%)", 0.8, 0.8, 0.8, 0.5, 0.7, 1)
      if not e.me then GameTooltip:AddLine("   " .. Tr(c.resting and "Logged out in an inn or city" or "Logged out in the wild"), 0.6, 0.6, 0.6) end
    end
  end
  GameTooltip:AddDoubleLine(Tr("Gold"), Money(c.money or 0), 0.8, 0.8, 0.8, 1, 1, 1)
  if c.played then GameTooltip:AddDoubleLine(Tr("Played"), Played(c.played), 0.8, 0.8, 0.8, 1, 1, 1) end
  local where = c.zone and ((c.sub and (c.sub .. ", ") or "") .. c.zone)
  if where then GameTooltip:AddDoubleLine(Tr("Location"), where, 0.8, 0.8, 0.8, 1, 1, 1) end
  if c.profs and #c.profs > 0 then
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(Tr("Professions"), GOLD[1], GOLD[2], GOLD[3])
    for _, p in ipairs(c.profs) do
      GameTooltip:AddDoubleLine("  " .. p.name, p.rank .. " / " .. p.max, 1, 1, 1, 1, 1, 1)
    end
  end
  if Letters(c) > 0 or c.mailNew then
    GameTooltip:AddLine(" ")
    if Letters(c) > 0 then
      local nitems = 0
      for _, k in pairs(c.mail.items or {}) do nitems = nitems + k end
      GameTooltip:AddDoubleLine(Tr("Mail"), string.format(Tr("%s letters"), Letters(c)) .. (nitems > 0 and (", " .. string.format(Tr("%s items"), nitems)) or ""), GOLD[1], GOLD[2], GOLD[3], 1, 1, 1)
      if (c.mail.money or 0) > 0 then GameTooltip:AddDoubleLine(" ", Money(c.mail.money), 1, 1, 1, 1, 1, 1) end
      if c.mail.expires then
        local days = math.max(0, math.floor((c.mail.expires - time()) / 86400))
        local r, g = 0.6, 0.6
        if days <= 3 then r, g = 1, 0.4 end
        GameTooltip:AddLine("   " .. string.format(Tr("first one expires in %s days"), days), r, g, 0.4)
      end
    else
      GameTooltip:AddLine(Tr("New mail waiting"), GOLD[1], GOLD[2], GOLD[3])
    end
  end
  GameTooltip:AddLine(" ")
  if c.synd and not c.own then GameTooltip:AddLine(Tr("From Syndicator. Log in once on this character for level, rested XP and more"), 0.6, 0.6, 0.6)
  elseif not e.me and c.seen then GameTooltip:AddLine(Tr("Last played") .. " " .. Ago(c.seen), 0.6, 0.6, 0.6) end
  if c.bankWhen then GameTooltip:AddLine(Tr("Bank checked") .. " " .. Ago(c.bankWhen), 0.6, 0.6, 0.6)
  else GameTooltip:AddLine(Tr("Bank not seen yet. Open it once on this character"), 0.6, 0.6, 0.6) end
  if not e.me then GameTooltip:AddLine(Tr("Right-click to forget this character"), 0.6, 0.6, 0.6) end
  GameTooltip:Show()
end

local function ItemTip(row, d)
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  local ok = pcall(GameTooltip.SetItemByID, GameTooltip, d.id)
  if not ok then
    GameTooltip:AddLine(d.name or "?", 1, 1, 1)
    local list, total = Holders(d.id)
    GameTooltip:AddDoubleLine(Tr("Total"), Commas(total), 0.8, 0.8, 0.8, 1, 1, 1)
    for _, h in ipairs(list) do
      local r, g, b = ClassColor(h.class)
      GameTooltip:AddDoubleLine("  " .. h.name, h.total .. "  |cff999999(" .. Where(h) .. ")|r", r, g, b, 1, 1, 1)
    end
  end
  GameTooltip:Show()
end

local function Row(i)
  local r = win.rows[i]
  if r then return r end
  r = CreateFrame("Button", nil, win.child)
  r:SetSize(WW - 28, ROWH)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROWH)
  r:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  r.hl = Solid(r, "BACKGROUND", 1, 1, 1, 0); r.hl:SetAllPoints()
  r.icon = r:CreateTexture(nil, "ARTWORK"); r.icon:SetSize(16, 16); r.icon:SetPoint("LEFT", 12, 0)
  r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  r.cols = {}
  for n = 1, 9 do
    local fs = r:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")   -- plain: names stay as the game names them
    fs:SetWordWrap(false)
    r.cols[n] = fs
  end
  r:SetScript("OnEnter", function(self)
    self.hl:SetVertexColor(1, 1, 1, 0.06)
    if self.char then CharTip(self, self.char) elseif self.item then ItemTip(self, self.item) end
  end)
  r:SetScript("OnLeave", function(self) self.hl:SetVertexColor(1, 1, 1, self.base or 0); GameTooltip:Hide() end)
  r:SetScript("OnClick", function(self, button)
    if self.item and IsModifiedClick and IsModifiedClick("CHATLINK") and ChatEdit_InsertLink then
      local _, link = (C_Item and C_Item.GetItemInfo or GetItemInfo)(self.item.id)
      if link then ChatEdit_InsertLink(link) end
      return
    end
    local e = self.char
    if button ~= "RightButton" or not e or e.me then return end
    local key = e.realm .. "/" .. e.name
    if forgetArmed == key then
      forgetArmed = nil
      Forget(e.realm, e.name); Say(string.format(Tr("forgot %s"), e.name)); GameTooltip:Hide(); Refresh()
    else
      forgetArmed = key
      win.foot:SetText("|cffff6060" .. string.format(Tr("Right-click %s again to forget them"), e.name) .. "|r")
      C_Timer.After(4, function() if forgetArmed == key then forgetArmed = nil; Refresh() end end)
    end
  end)
  win.rows[i] = r
  return r
end
local function Place(fs, c)
  fs:ClearAllPoints(); fs:SetPoint("LEFT", c.x, 0); fs:SetWidth(c.w); fs:SetJustifyH(c.justify); fs:Show()
end

local function Search(q)
  local out = {}
  q = (q or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if #q < 2 then return out, q end
  local seen = {}
  for _, list in pairs(DB.chars) do
    for _, c in pairs(list) do
      for _, set in ipairs(FactionOK(c) and { c.bags or {}, c.bank or {}, c.worn or {}, c.mail and c.mail.items or {} } or {}) do
        for id in pairs(set) do
          if not seen[id] then
            seen[id] = true
            local name = DB.names[id] or (C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id))
            if name and name:lower():find(q, 1, true) then out[#out + 1] = { id = id, name = name } end
          end
        end
      end
    end
  end
  table.sort(out, function(a, b) return a.name < b.name end)
  return out, q
end

Refresh = function()
  if not (win and win:IsShown()) then return end
  if C and ME then Snapshot() end
  local find = DB.tab == "find"
  for _, b in ipairs(win.tabs) do b:SetOn(DB.tab == b.value) end
  for _, b in ipairs(win.realms) do b:SetOn(DB.realm == b.value); b:SetShown(not find) end
  local f = DB.faction or "mine"
  local function FName(x) return x == "Horde" and (FACTION_HORDE or "Horde") or (FACTION_ALLIANCE or "Alliance") end
  win.factionBtn.label:SetText(f == "both" and Tr("Both Factions") or FName(f == "mine" and MyFaction() or OtherFaction()))
  win.factionBtn:SetOn(f ~= "both")
  win.factionBtn:ClearAllPoints()
  win.factionBtn:SetPoint("TOPRIGHT", find and -14 or -202, -40)   -- (1.0.1) Find searches every realm; the search box sits there
  win.box:SetShown(find); win.hint:SetShown(find and win.box:GetText() == "")
  for _, h in ipairs(win.heads) do
    h:SetShown(not find)
    if h.key == (DB.sort or "level") then h.label:SetTextColor(1, 1, 1) else h.label:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end
  end
  for _, h in ipairs(win.fheads) do h:SetShown(find) end
  local n = 0
  if not find then
    local list = Chars()
    local gold = 0
    for i, e in ipairs(list) do
      local c, r = e.c, Row(i)
      r.char, r.item = e, nil
      r.base = e.me and 0.04 or 0
      r.hl:SetVertexColor(1, 1, 1, r.base)
      r.icon:Show()
      local cl = c.class and CLASS_ICON_TCOORDS and CLASS_ICON_TCOORDS[c.class]
      if cl then r.icon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles"); r.icon:SetTexCoord(cl[1], cl[2], cl[3], cl[4])
      else r.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark"); r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) end
      local cr, cg, cb = ClassColor(c.class)
      for k, col in ipairs(COLS) do Place(r.cols[k], col) end
      r.cols[1]:SetText(Hex(cr, cg, cb) .. e.name .. "|r" .. ((DB.realm == "all" and e.realm ~= REALM) and ("|cff777777 *|r") or ""))
      local maxed = (c.level or 0) >= (DB.maxLevel or 60)
      r.cols[2]:SetText(not c.level and "|cff666666-|r" or maxed and ("|cffffd100" .. c.level .. "|r") or tostring(c.level))
      r.cols[3]:SetText(c.money and Money(c.money) or "|cff666666-|r")   -- (1.2.0) gold, silver and copper
      local rest = RestedNow(c, e.me)
      if rest and c.xpMax and c.xpMax > 0 then
        local pct = math.floor(rest / c.xpMax * 100)
        r.cols[4]:SetText((pct >= 150 and "|cff80b3ff" or "|cffb0c8ff") .. pct .. "%|r")
      else r.cols[4]:SetText("|cff666666-|r") end
      if c.bagTotal then
        local low = c.bagFree <= 3
        r.cols[5]:SetText((low and "|cffff6060" or "") .. c.bagFree .. "|r|cff888888 / " .. c.bagTotal .. "|r")
      else r.cols[5]:SetText("|cff666666-|r") end
      r.cols[6]:SetText(c.played and Played(c.played) or "|cff666666-|r")
      r.cols[7]:SetText(ProfText(c))
      r.cols[8]:SetText(c.zone or "")
      local L = Letters(c)
      if L > 0 then
        local soon = c.mail.expires and c.mail.expires - time() < 3 * 86400
        r.cols[9]:SetText(MAIL_ICON .. " " .. (soon and "|cffff6060" or "") .. L .. (soon and "|r" or ""))
      elseif c.mailNew then r.cols[9]:SetText(MAIL_ICON .. " |cffffd100" .. Tr("New") .. "|r")
      else r.cols[9]:SetText("|cff666666-|r") end
      r:Show()
      gold = gold + (c.money or 0)
      n = i
    end
    win.empty:SetText("No characters yet")
    win.total:SetText(Tr("All Characters") .. ":  " .. Money(gold))   -- (1.3.1) gold, silver and copper
    if not forgetArmed then win.foot:SetText("Hover a character for more. Click a column to sort") end
  else
    local list, q = Search(win.box:GetText())
    for _, d in ipairs(list) do
      if n >= 300 then break end
      local quality = C_Item and C_Item.GetItemQualityByID and C_Item.GetItemQualityByID(d.id)
      local qc = quality and ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]
      local holders = Holders(d.id)
      for hi, h in ipairs(holders) do
        n = n + 1
        local r = Row(n)
        r.char, r.item, r.base = nil, d, (hi == 1 and 0 or 0)
        r.hl:SetVertexColor(1, 1, 1, 0)
        r.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        if hi == 1 then   -- the item's name and icon on its first line only, the rest line up under it
          r.icon:SetTexture((C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(d.id)) or (GetItemIcon and GetItemIcon(d.id)) or "Interface\\Icons\\INV_Misc_QuestionMark")
          r.icon:Show()
        else
          r.icon:Hide()
        end
        for k, col in ipairs(FCOLS) do Place(r.cols[k], col) end
        for k = #FCOLS + 1, 9 do r.cols[k]:Hide() end
        r.cols[1]:SetText(hi == 1 and ((qc and qc.hex or "|cffffffff") .. d.name .. "|r") or "")
        local cr, cg, cb = ClassColor(h.class)
        r.cols[2]:SetText(Hex(cr, cg, cb) .. h.name .. "|r")
        r.cols[3]:SetText("|cffbbbbbb" .. Where(h) .. "|r")
        r.cols[4]:SetText(Commas(h.total))
        r:Show()
      end
    end
    win.empty:SetText(#q < 2 and "Type at least two letters of an item's name" or "None of your characters have that")
    win.total:SetText("")
    win.foot:SetText("Counts bags, bank, mail and what you wear. Shift-click an item to link it")
  end
  for i = n + 1, #win.rows do win.rows[i]:Hide(); win.rows[i].char = nil; win.rows[i].item = nil end
  win.child:SetHeight(math.max(10, n * ROWH))
  win.empty:SetShown(n == 0)
end

local function Toggle(tab)
  if not DB then return end
  if not win then Build() end
  if tab then DB.tab = tab end
  if win:IsShown() and not tab then win:Hide() else win:Show(); Refresh() end
end
ns.ToggleAltLedger = Toggle

---------------------------------------------------------------------------
-- events
---------------------------------------------------------------------------
local MinimapButton   -- further down
local pendingBags
local function BagsSoon()
  if pendingBags then return end
  pendingBags = true
  C_Timer.After(0.5, function()
    pendingBags = nil
    ScanBags()
    if bankOpen then ScanBank() end
    Refresh()
  end)
end
-- (1.4.0) time played: asked once a few seconds after login, without the "Total time played" lines in chat
-- (the chat windows stop listening for that one answer, then listen again)
local muted
local quietPlayed
local function AskPlayed()
  if not RequestTimePlayed or (InCombatLockdown and InCombatLockdown()) then return end
  muted = {}
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local f = _G["ChatFrame" .. i]
    if f and f.IsEventRegistered and f:IsEventRegistered("TIME_PLAYED_MSG") then
      local ok = pcall(f.UnregisterEvent, f, "TIME_PLAYED_MSG")
      if ok then muted[#muted + 1] = f end
    end
  end
  local function Back()
    for _, f in ipairs(muted or {}) do pcall(f.RegisterEvent, f, "TIME_PLAYED_MSG") end
    muted, quietPlayed = nil, nil
  end
  quietPlayed = function() C_Timer.After(0, Back) end
  C_Timer.After(10, function() if muted then Back() end end)   -- never leave chat deaf if no answer comes
  RequestTimePlayed()
end
local function Loaded(name)
  local f = (C_AddOns and C_AddOns.IsAddOnLoaded) or IsAddOnLoaded
  return f and f(name) and true or false
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
for _, e in ipairs({ "PLAYER_ENTERING_WORLD", "PLAYER_MONEY", "PLAYER_XP_UPDATE", "PLAYER_LEVEL_UP", "UPDATE_EXHAUSTION",
  "PLAYER_UPDATE_RESTING", "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "PLAYER_GUILD_UPDATE",
  "PLAYER_LOGOUT", "BAG_UPDATE_DELAYED", "PLAYER_EQUIPMENT_CHANGED", "BANKFRAME_OPENED", "BANKFRAME_CLOSED",
  "PLAYERBANKSLOTS_CHANGED", "PLAYER_INTERACTION_MANAGER_FRAME_SHOW", "PLAYER_INTERACTION_MANAGER_FRAME_HIDE",
  "SKILL_LINES_CHANGED", "TRADE_SKILL_SHOW", "TIME_PLAYED_MSG",
  "MAIL_SHOW", "MAIL_INBOX_UPDATE", "UPDATE_PENDING_MAIL", "MAIL_SEND_SUCCESS" }) do
  pcall(ev.RegisterEvent, ev, e)
end
local BANKER = Enum and Enum.PlayerInteractionType and Enum.PlayerInteractionType.Banker
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    AltLedgerDB = AltLedgerDB or {}
    DB = AltLedgerDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    DB.chars = DB.chars or {}
    DB.names = DB.names or {}
    return
  end
  if not DB then return end
  if e == "PLAYER_LOGIN" then
    ME, REALM = Who()
    pcall(Migrate)
    pcall(FromSyndicator)
    C_Timer.After(3, function() Snapshot(); Refresh() end)   -- gold can read 0 for a moment right after login
    C_Timer.After(6, function() pcall(AskPlayed) end)
    -- item counts on tooltips: on, unless another addon already shows them
    if DB.tips == nil then DB.tips = not (Loaded("Syndicator") or Loaded("Altoholic") or Loaded("BagBrother") or Loaded("DataStore")) end
    Snapshot(); ScanProfs(); ScanBags()
    if HasNewMail then C.mailNew = HasNewMail() and true or false end
    pcall(HookTooltips)
    pcall(WatchSends)
    pcall(MinimapButton)
  elseif not ME then
    return
  elseif e == "BAG_UPDATE_DELAYED" or e == "PLAYER_EQUIPMENT_CHANGED" or e == "PLAYERBANKSLOTS_CHANGED" then
    BagsSoon()
  elseif e == "BANKFRAME_OPENED" or (e == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" and BANKER and a1 == BANKER) then
    bankOpen = true
    C_Timer.After(0.3, function() ScanBank(); Refresh() end)
  elseif e == "BANKFRAME_CLOSED" or (e == "PLAYER_INTERACTION_MANAGER_FRAME_HIDE" and BANKER and a1 == BANKER) then
    if bankOpen then ScanBank() end
    bankOpen = false
  elseif e == "SKILL_LINES_CHANGED" or e == "TRADE_SKILL_SHOW" then
    ScanProfs()
  elseif e == "MAIL_SHOW" or e == "MAIL_INBOX_UPDATE" then
    ScanMail(); Refresh()
  elseif e == "UPDATE_PENDING_MAIL" then
    C = C or Char()
    if C and HasNewMail and HasNewMail() then C.mailNew = true; Refresh() end
  elseif e == "MAIL_SEND_SUCCESS" then
    Sent(); Refresh()
  elseif e == "TIME_PLAYED_MSG" then
    C = C or Char()
    if C and tonumber(a1) then C.played = tonumber(a1) end
    if quietPlayed then quietPlayed() end
    Refresh()
  elseif e == "PLAYER_LOGOUT" then
    Snapshot(true)
  else
    Snapshot()
    if e == "PLAYER_ENTERING_WORLD" then ScanProfs() end
    Refresh()
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Alt Ledger",
  tag = "Alt Ledger",
  settings = {
    { label = "Item Counts On Tooltips", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.tips and true or false end, set = function(v) DB.tips = v end },
    { label = "Show Characters", choices = { { "All Realms", "all" }, { "This Realm", "this" } },
      get = function() return DB.realm end, set = function(v) DB.realm = v; Refresh() end },
    { label = "Alt Ledger Window", choices = { { "Open It", "open" } },
      get = function() return nil end, set = function() Toggle("chars") end },
  },
  notes = {
    { v = "1.4.0", "New Played and Professions columns. Played fills in by itself a few seconds after you log in on a character. Professions shows each main profession's icon and skill", "The window is a bit wider to fit them" },
    { v = "1.3.1", "The All Characters total shows gold, silver and copper" },
    { v = "1.3.0", "Horde and Alliance apart: you see your own side, and the Faction button switches to the other side or both", "Find An Item lists one line per character, with where it is (bags, bank, mail, equipped) in its own column" },
    { v = "1.2.0", "Characters who share a first name (WoW: Forever surnames) are kept apart now", "Gold no longer drops to 0 after you log out, and shows gold, silver and copper", "Have Syndicator? Every character it knows shows up right away, with gold, bags, bank and mail", "Find An Item says where each one is: bags, bank, mail or equipped" },
    { v = "1.1.0", "A Mail column: who has mail and how many letters, red when one expires within 3 days. Mail you send to your own characters shows up right away", "Find An Item and the tooltip counts include mail", "Last Seen moved into the hover" },
    { v = "1.0.1", "The search box no longer covers the realm buttons, and Last Seen fits beside the scroll bar" },
    { v = "1.0.0", "First release: every character you play in one window, with level, gold, rested XP, free bag space, professions and where you left them. Find any item across all your characters, and see the counts on item tooltips" },
  },
  report = function()
    local n, r = 0, 0
    for _, list in pairs(DB.chars or {}) do r = r + 1; for _ in pairs(list) do n = n + 1 end end
    return { "Characters " .. n .. " on " .. r .. " realms, tips " .. tostring(DB.tips) .. ", bank " .. tostring(C and C.bankWhen ~= nil) }
  end,
}

MinimapButton = function()
  if not Minimap or _G.AltLedgerMinimapButton then return end
  local b = CreateFrame("Button", "AltLedgerMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture(ICON)
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 205)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then if ns.OpenHelp then ns.OpenHelp() end
    else Toggle() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Alt Ledger")
    Tip:AddLine("Left-click: your characters", 1, 1, 1)
    Tip:AddLine("Right-click: Settings & Help", 1, 1, 1)
    Tip:AddLine("Drag to move", 0.6, 0.6, 0.6)
    Tip:Show()
  end)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  b:SetScript("OnDragStart", function(self)
    self:SetScript("OnUpdate", function()
      local mx, my = Minimap:GetCenter()
      local cx, cy = GetCursorPosition()
      local sc = Minimap:GetEffectiveScale()
      DB.minimapAngle = math.deg((math.atan2 or math.atan)(cy / sc - my, cx / sc - mx))
      Spot()
    end)
  end)
  b:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
  Spot()
end
function AltLedger_OnCompartmentClick() Toggle() end

SLASH_ALTLEDGER1 = "/alts"
SLASH_ALTLEDGER2 = "/altledger"
SlashCmdList.ALTLEDGER = function(msg)
  msg = msg or ""
  local cmd, rest = msg:match("^(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  if cmd == "" or cmd == "show" then
    Toggle()
  elseif cmd == "find" or cmd == "search" then
    Toggle("find")
    win.box:SetText(rest or ""); Refresh()
  elseif cmd == "forget" and rest ~= "" then
    local gone
    if rest:lower() == ME:lower() then Say("that's the character you're on") return end
    for realm, list in pairs(DB.chars) do
      for name in pairs(list) do
        if name:lower() == rest:lower() then Forget(realm, name); gone = name; break end
      end
      if gone then break end
    end
    Say(gone and string.format(Tr("forgot %s"), gone) or string.format(Tr("no character called %s"), rest))
    Refresh()
  elseif cmd == "help" or cmd == "settings" then
    if ns.OpenHelp then ns.OpenHelp() end
  else
    Say("every character you play, in one window.")
    P("  /alts   (" .. "your characters" .. ")   /alts find <" .. "item" .. ">")
    P("  /alts forget <" .. "name" .. ">   /alts help   (" .. "all settings, and how to report a bug" .. ")")
  end
end
