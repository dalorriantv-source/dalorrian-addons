-- Dalorrian's Chat Copy: a small button on each chat window. Click it and the chat opens as plain text,
-- already selected, so Ctrl+C copies it. /chatcopy opens the main chat window too.

local ADDON, ns = ...
local DB
local DEFAULTS = { lines = 500, bright = false, links = true }
local CF = ns.CreateFrame or CreateFrame   -- (1.1.0) Lang.lua: text on these frames is translated
local P = ns.print or print
local Tip = ns.Tip or GameTooltip
local W = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local GOLD = { 1, 0.82, 0 }

local function Style(f, edge, a)
  f:SetBackdrop({ bgFile = W, edgeFile = W, edgeSize = edge or 2 })
  f:SetBackdropColor(0.04, 0.04, 0.05, a or 0.94)
  f:SetBackdropBorderColor(0, 0, 0, 1)
end

-- chat text without colors, icons or link code: just what you read on screen
local function Plain(s)
  if type(s) ~= "string" then return "" end
  s = s:gsub("|T.-|t", ""):gsub("|A.-|a", "")
  s = s:gsub("|H.-|h(.-)|h", "%1")
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|cn[^:]-:", ""):gsub("|r", "")
  s = s:gsub("|K.-|k", "(Battle.net name)")
  s = s:gsub("||", "|")
  return s
end

---------------------------------------------------------------------------
-- the copy window
---------------------------------------------------------------------------
local win
local function Window()
  if win then return win end
  win = CF("Frame", "ChatCopyFrame", UIParent, "BackdropTemplate")
  win:SetSize(560, 380)
  win:SetPoint("CENTER")
  win:SetFrameStrata("DIALOG")
  win:SetMovable(true)
  win:SetClampedToScreen(true)
  win:EnableMouse(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  Style(win)
  win:Hide()
  tinsert(UISpecialFrames, "ChatCopyFrame")   -- Esc closes it

  win.title = win:CreateFontString(nil, "OVERLAY")
  win.title:SetFont(FONT, 12, "")
  win.title:SetShadowOffset(1, -1)
  win.title:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  win.title:SetPoint("TOPLEFT", 10, -8)
  win.hint = win:CreateFontString(nil, "OVERLAY")
  win.hint:SetFont(FONT, 10, "")
  win.hint:SetTextColor(0.6, 0.6, 0.62)
  win.hint:SetPoint("LEFT", win.title, "RIGHT", 10, 0)
  win.hint:SetText("Ctrl+C to copy, Esc to close")
  local line = win:CreateTexture(nil, "ARTWORK")
  line:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.25)
  line:SetHeight(1)
  line:SetPoint("TOPLEFT", 6, -26); line:SetPoint("TOPRIGHT", -6, -26)

  -- a small gold X
  local x = CreateFrame("Button", nil, win)
  x:SetSize(18, 18)
  x:SetPoint("TOPRIGHT", -5, -4)
  x.text = x:CreateFontString(nil, "OVERLAY")
  x.text:SetFont(FONT, 13, "")
  x.text:SetPoint("CENTER")
  x.text:SetText("x")
  x.text:SetTextColor(0.7, 0.7, 0.72)
  x:SetScript("OnEnter", function(self) self.text:SetTextColor(GOLD[1], GOLD[2], GOLD[3]) end)
  x:SetScript("OnLeave", function(self) self.text:SetTextColor(0.7, 0.7, 0.72) end)
  x:SetScript("OnClick", function() win:Hide() end)

  local sf = CreateFrame("ScrollFrame", "ChatCopyScroll", win, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 10, -32)
  sf:SetPoint("BOTTOMRIGHT", -30, 10)
  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true)
  eb:SetAutoFocus(false)
  eb:SetFontObject(ChatFontNormal)
  eb:SetWidth(510)
  eb:SetScript("OnEscapePressed", function() win:Hide() end)
  -- it's for copying, so typing doesn't change it
  eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(self.full or ""); self:HighlightText() end end)
  sf:SetScrollChild(eb)
  win.scroll, win.edit = sf, eb
  return win
end

local function Open(chat)
  chat = chat or DEFAULT_CHAT_FRAME
  if not chat or not chat.GetNumMessages then return end
  local w = Window()
  local lines = {}
  local n = chat:GetNumMessages()
  for i = math.max(1, n - ((DB and DB.lines) or 500) + 1), n do
    local text = chat:GetMessageInfo(i)
    lines[#lines + 1] = Plain(text)
  end
  local full = table.concat(lines, "\n")
  local name = chat.name or (chat.GetName and _G[chat:GetName() .. "Tab"] and _G[chat:GetName() .. "Tab"]:GetText()) or "Chat"
  w.title:SetText("Chat Copy: " .. Plain(name))
  w.edit.full = full
  w.edit:SetText(full)
  w:Show()
  w.edit:SetFocus()
  w.edit:HighlightText()
  -- start at the newest line
  C_Timer.After(0, function() w.scroll:SetVerticalScroll(w.scroll:GetVerticalScrollRange()) end)
end

---------------------------------------------------------------------------
-- the button on each chat window: two small gold squares, faint until you point at it
---------------------------------------------------------------------------
local function Button(chat)
  if not chat or chat.chatCopyButton then return end
  if IsCombatLog and IsCombatLog(chat) then return end   -- the combat log has its own filter bar up there
  local b = CF("Button", nil, chat, "BackdropTemplate")
  b:SetSize(18, 18)
  b:SetPoint("TOPRIGHT", chat, "TOPRIGHT", 0, 0)
  b:SetFrameLevel(chat:GetFrameLevel() + 5)
  Style(b, 1, 0.85)
  local back = b:CreateTexture(nil, "ARTWORK")
  back:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 0.45)
  back:SetSize(7, 7); back:SetPoint("TOPLEFT", 4, -4)
  local edge = b:CreateTexture(nil, "ARTWORK", nil, 1)
  edge:SetColorTexture(0, 0, 0, 1)
  edge:SetSize(9, 9); edge:SetPoint("BOTTOMRIGHT", -3, 3)
  local front = b:CreateTexture(nil, "ARTWORK", nil, 2)
  front:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
  front:SetSize(7, 7); front:SetPoint("BOTTOMRIGHT", -4, 4)
  local function Rest() return (DB and DB.bright) and 1 or 0.35 end
  b:SetAlpha(Rest())
  b:SetScript("OnEnter", function(self)
    self:SetAlpha(1)
    self:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 1)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Copy Chat")
    Tip:AddLine("Opens this chat as plain text you can copy.", 1, 1, 1, true)
    Tip:Show()
  end)
  b:SetScript("OnLeave", function(self)
    self:SetAlpha(Rest())
    self:SetBackdropBorderColor(0, 0, 0, 1)
    GameTooltip:Hide()
  end)
  b:SetScript("OnClick", function() Open(chat) end)
  b.Rest = Rest
  chat.chatCopyButton = b
  if DB and DB.hidden then b:Hide() end
end

local function All()
  for i = 1, (NUM_CHAT_WINDOWS or 10) do Button(_G["ChatFrame" .. i]) end
end

---------------------------------------------------------------------------
-- (1.2.0) web links in chat turn gold and clickable: a click opens a small box with the link selected
---------------------------------------------------------------------------
local URLS = {
  "https?://[%w%-%._~:/%?#%[%]@!%$&'%(%)%*%+,;=%%]+",
  "www%.[%w%-]+%.[%w%-%._~:/%?#@!%$&'%*%+,;=%%]+",
  "discord%.gg/[%w%-]+",
}
local LINK = "|cffffd100|Haddon:ChatCopy:%s|h%s|h|r"
local function Linkify(msg)
  if type(msg) ~= "string" or not (DB and DB.links) then return msg end
  -- links already in the message (items, players) are left alone: only the plain text between them changes
  local out, pos = {}, 1
  while pos <= #msg do
    local a, b = msg:find("|H.-|h.-|h", pos)
    local plain = msg:sub(pos, (a or #msg + 1) - 1)
    local marks = {}
    for i, pat in ipairs(URLS) do
      plain = plain:gsub(pat, function(u)
        if u:find("\001") then return u end
        local trail = u:match("[%.,;:!%?%)]+$") or ""   -- a full stop or bracket after a link isn't part of it
        u = u:sub(1, #u - #trail)
        marks[#marks + 1] = u
        return "\001" .. #marks .. "\001" .. trail
      end)
    end
    plain = plain:gsub("\001(%d+)\001", function(n)
      local u = marks[tonumber(n)]
      return string.format(LINK, u, u)
    end)
    out[#out + 1] = plain
    if not a then break end
    out[#out + 1] = msg:sub(a, b)
    pos = b + 1
  end
  return table.concat(out)
end

-- (1.2.1) a link is clicked through the game's own "addon" links, and the address opens in our own small
-- box. Taking over SetItemRef or borrowing the game's popups spread "blocked action" errors to the Esc menu
-- and logging out, so neither is touched any more.
local box
local function ShowURL(url)
  if not box then
    box = CF("Frame", "ChatCopyURLBox", UIParent, "BackdropTemplate")
    box:SetSize(420, 70)
    box:SetPoint("TOP", 0, -160)
    box:SetFrameStrata("DIALOG")
    box:SetClampedToScreen(true)
    box:EnableMouse(true)
    Style(box)
    local t = box:CreateFontString(nil, "OVERLAY")
    t:SetFont(FONT, 11, ""); t:SetTextColor(GOLD[1], GOLD[2], GOLD[3]); t:SetPoint("TOPLEFT", 12, -10)
    t:SetText(ns.Tr and ns.Tr("Ctrl+C to copy, Esc to close") or "Ctrl+C to copy, Esc to close")
    local eb = CreateFrame("EditBox", nil, box, "InputBoxTemplate")
    eb:SetSize(390, 20); eb:SetPoint("TOPLEFT", 18, -32)
    eb:SetAutoFocus(false)
    local function Close() eb:ClearFocus(); box:Hide() end
    eb:SetScript("OnEscapePressed", Close)
    eb:SetScript("OnEnterPressed", Close)
    eb:SetScript("OnTextChanged", function(self, user)   -- for copying, so typing doesn't change it
      if user and self:GetText() ~= box.url then self:SetText(box.url or ""); self:HighlightText() end
    end)
    local x = CreateFrame("Button", nil, box)
    x:SetSize(18, 18); x:SetPoint("TOPRIGHT", -6, -6)
    x.t = x:CreateFontString(nil, "OVERLAY", "GameFontHighlight"); x.t:SetPoint("CENTER"); x.t:SetText("x")
    x:SetScript("OnClick", Close)
    box.eb = eb
  end
  box.url = url
  box:Show()
  box.eb:SetText(url or "")
  box.eb:SetFocus()
  box.eb:HighlightText()
end
local function Filter(_, _, msg, ...)
  local ok, new = pcall(Linkify, msg)   -- some chat text can't be read by addons: leave it as it is
  if ok and new ~= msg then return false, new, ... end
end
local function HookLinks()
  if ChatCopy_LinksHooked then return end
  ChatCopy_LinksHooked = true
  if not (EventRegistry and EventRegistry.RegisterCallback) then return end   -- no safe way to catch the click: plain text it stays
  EventRegistry:RegisterCallback("SetItemRef", function(_, link)
    if type(link) ~= "string" then return end
    local url = link:match("^addon:ChatCopy:(.+)$")
    if url then ShowURL(url) end
  end, ns)
  local add = ChatFrame_AddMessageEventFilter or (ChatFrameUtil and ChatFrameUtil.AddMessageEventFilter)
  if add then
    for _, e in ipairs({ "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_GUILD", "CHAT_MSG_OFFICER", "CHAT_MSG_PARTY", "CHAT_MSG_PARTY_LEADER",
      "CHAT_MSG_RAID", "CHAT_MSG_RAID_LEADER", "CHAT_MSG_RAID_WARNING", "CHAT_MSG_WHISPER", "CHAT_MSG_WHISPER_INFORM", "CHAT_MSG_CHANNEL",
      "CHAT_MSG_BN_WHISPER", "CHAT_MSG_BN_WHISPER_INFORM", "CHAT_MSG_INSTANCE_CHAT", "CHAT_MSG_INSTANCE_CHAT_LEADER", "CHAT_MSG_EMOTE" }) do
      pcall(add, e, Filter)
    end
  end
end

-- (1.1.0) show, hide or brighten every button at once
local function Refresh()
  for i = 1, (NUM_CHAT_WINDOWS or 10) do
    local c = _G["ChatFrame" .. i]
    local b = c and c.chatCopyButton
    if b then b:SetShown(not DB.hidden); b:SetAlpha(b.Rest()) end
  end
  if CHAT_FRAMES then for _, n in ipairs(CHAT_FRAMES) do local b = _G[n] and _G[n].chatCopyButton; if b then b:SetShown(not DB.hidden); b:SetAlpha(b.Rest()) end end end
end

local MinimapButton
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function(_, e, a1)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    ChatCopyDB = ChatCopyDB or {}
    DB = ChatCopyDB
    for k, v in pairs(DEFAULTS) do if DB[k] == nil then DB[k] = v end end
    return
  end
  All()
  pcall(MinimapButton)
  pcall(HookLinks)
  -- new chat windows (and temporary whisper windows) get a button too
  if FCF_OpenNewWindow then hooksecurefunc("FCF_OpenNewWindow", function() C_Timer.After(0, All) end) end
  if FCF_OpenTemporaryWindow then
    hooksecurefunc("FCF_OpenTemporaryWindow", function() C_Timer.After(0, function()
      if CHAT_FRAMES then for _, n in ipairs(CHAT_FRAMES) do Button(_G[n]) end end
    end) end)
  end
end)

---------------------------------------------------------------------------
-- (1.1.0) Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Chat Copy",
  tag = "Chat Copy",
  settings = {
    { label = "Copy Buttons", choices = { { "Shown", "on" }, { "Hidden", "off" } },
      get = function() return DB.hidden and "off" or "on" end,
      set = function(v) DB.hidden = (v == "off") or nil; Refresh() end },
    { label = "Button Look", choices = { { "Faint", false }, { "Bright", true } },
      get = function() return DB.bright and true or false end, set = function(v) DB.bright = v; Refresh() end },
    { label = "Clickable Links", choices = { { "On", true }, { "Off", false } },
      get = function() return DB.links and true or false end, set = function(v) DB.links = v end },
    { label = "Lines To Copy", choices = { { "200", 200 }, { "500", 500 }, { "All", 5000 } },
      get = function() return DB.lines or 500 end, set = function(v) DB.lines = v end },
  },
  notes = {
    { v = "1.2.1", "Fixed \"blocked action\" errors when pressing Esc or logging out. Clicked links now open in Chat Copy's own box" },
    { v = "1.2.0", "Web links in chat turn gold and clickable: a click opens a small box with the link ready to copy" },
    { v = "1.1.0", "A Settings & Help window, a minimap button and 10 languages. Pick how many lines to copy and how the button looks" },
    { v = "1.0.0", "First release: a small button on each chat window that opens the chat as plain text, ready to copy" },
  },
  report = function()
    return { "Lines " .. tostring(DB.lines) .. ", bright " .. tostring(DB.bright) .. (DB.hidden and ", buttons hidden" or "") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.ChatCopyMinimapButton then return end
  local b = CreateFrame("Button", "ChatCopyMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Misc_Note_01")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 85)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then Open(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME)
    elseif ns.OpenHelp then ns.OpenHelp() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Chat Copy")
    Tip:AddLine("Left-click: Settings & Help", 1, 1, 1)
    Tip:AddLine("Right-click: copy the chat you're on", 1, 1, 1)
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
function ChatCopy_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_CHATCOPY1 = "/chatcopy"
SlashCmdList.CHATCOPY = function(msg)
  local cmd = (msg or ""):lower():match("^(%S*)")
  if (cmd == "help" or cmd == "settings") and ns.OpenHelp then ns.OpenHelp() return end
  Open(SELECTED_CHAT_FRAME or DEFAULT_CHAT_FRAME)
end
