-- Dalorrian's Chat Saver: save your chat setup once (windows, tabs, sizes, spots, what shows where, colors,
-- channels and chat options) and load it on any other character. New characters get it on their own.
-- /chatsaver for options.

local ADDON, ns = ...
local DB, CHAR
local P = ns.print or print
local Tr = ns.Tr or function(s) return s end
local function Say(msg) P("|cffffd100Chat Saver:|r " .. msg) end
local Tip = ns.Tip or GameTooltip
local NUM = NUM_CHAT_WINDOWS or 10
local CVARS = { "chatStyle", "colorChatNamesByClass", "chatMouseScroll", "whisperMode", "showTimestamps", "chatBubbles",
  "chatBubblesParty", "removeChatDelay", "wholeChatWindowClickable", "showToastWindow", "chatClassColorOverride" }
local ZONE = { general = true, trade = true, localdefense = true, lookingforgroup = true, worlddefense = true, guildrecruitment = true }

local function Pack(...) return { n = select("#", ...), ... } end

---------------------------------------------------------------------------
-- reading what you have now
---------------------------------------------------------------------------
local function Capture()
  local s = { windows = {}, colors = {}, cvars = {}, channels = {} }
  for i = 1, NUM do
    local name, size, r, g, b, a, shown, locked, docked, unint = GetChatWindowInfo(i)
    local w = { name = name, size = size, r = r, g = g, b = b, a = a, shown = shown and true or false, locked = locked and true or false,
      docked = docked, unint = unint and true or false }
    w.groups = Pack(GetChatWindowMessages(i)); w.groups.n = nil
    local ch = Pack(GetChatWindowChannels(i))
    w.channels = {}
    for k = 1, ch.n, 2 do if ch[k] then w.channels[#w.channels + 1] = ch[k] end end
    if GetChatWindowSavedPosition then
      local pt, x, y = GetChatWindowSavedPosition(i)
      w.point, w.x, w.y = pt, x, y
    end
    if GetChatWindowSavedDimensions then w.width, w.height = GetChatWindowSavedDimensions(i) end
    s.windows[i] = w
  end
  for chatType, info in pairs(ChatTypeInfo or {}) do
    if type(info) == "table" and info.r then
      s.colors[chatType] = { info.r, info.g, info.b, info.colorNameByClass and true or false }
    end
  end
  for _, cv in ipairs(CVARS) do
    local ok, v = pcall(GetCVar, cv)
    if ok and v ~= nil then s.cvars[cv] = v end
  end
  -- your own channels (the zone ones like General and Trade come back by themselves)
  local list = Pack(GetChannelList())
  for k = 1, list.n, 3 do
    local name = list[k + 1]
    if type(name) == "string" and not ZONE[name:lower()] then s.channels[#s.channels + 1] = name end
  end
  s.from = UnitName("player") .. " - " .. (GetRealmName() or "")
  s.when = time()
  return s
end

---------------------------------------------------------------------------
-- putting a saved setup on this character
---------------------------------------------------------------------------
local fails
local function Try(f, ...)
  local ok = pcall(f, ...)
  if not ok then fails = fails + 1 end
end

local function Apply(s)
  fails = 0
  -- channels first, so the windows can be told to show them
  for _, name in ipairs(s.channels or {}) do
    if not (GetChannelName and GetChannelName(name) and GetChannelName(name) > 0) then
      Try(JoinPermanentChannel, name, nil, 1)
    end
  end
  for i = 1, NUM do
    local w = s.windows[i]
    local f = _G["ChatFrame" .. i]
    if w and f then
      -- which windows are open: the first two always are (chat and the combat log)
      if i > 2 then
        if w.shown and not f:IsShown() then
          Try(SetChatWindowShown, i, true)
          Try(f.Show, f)
        elseif not w.shown and f:IsShown() then
          Try(FCF_Close, f)
        end
      end
      if w.shown or i <= 2 then
        if w.name and w.name ~= "" then Try(FCF_SetWindowName, f, w.name) end
        if w.size then Try(FCF_SetChatWindowFontSize, nil, f, w.size) end
        if w.r then Try(FCF_SetWindowColor, f, w.r, w.g, w.b) end
        if w.a then Try(FCF_SetWindowAlpha, f, w.a) end
        Try(SetChatWindowLocked, i, w.locked); f.isLocked = w.locked
        if FCF_SetUninteractable then Try(FCF_SetUninteractable, f, w.unint) end
        -- what shows in it
        if ChatFrame_RemoveAllMessageGroups then Try(ChatFrame_RemoveAllMessageGroups, f) end
        for _, g in ipairs(w.groups or {}) do Try(ChatFrame_AddMessageGroup, f, g) end
        if ChatFrame_RemoveAllChannels then Try(ChatFrame_RemoveAllChannels, f) end
        for _, c in ipairs(w.channels or {}) do Try(ChatFrame_AddChannel, f, c) end
        -- docked into the tabs, or on its own with its own spot and size
        if i > 1 then
          if w.docked then Try(FCF_DockFrame, f, w.docked, false)
          elseif f.isDocked then Try(FCF_UnDockFrame, f) end
        end
        if w.point and SetChatWindowSavedPosition then Try(SetChatWindowSavedPosition, i, w.point, w.x, w.y) end
        if w.width and SetChatWindowSavedDimensions then Try(SetChatWindowSavedDimensions, i, w.width, w.height) end
        if FCF_RestorePositionAndDimensions and (i == 1 or not w.docked) then Try(FCF_RestorePositionAndDimensions, f) end
      end
    end
  end
  for chatType, c in pairs(s.colors or {}) do
    if ChatTypeInfo and ChatTypeInfo[chatType] then
      Try(ChangeChatColor, chatType, c[1], c[2], c[3])
      if SetChatColorNameByClass then Try(SetChatColorNameByClass, chatType, c[4]) end
    end
  end
  for cv, v in pairs(s.cvars or {}) do Try(SetCVar, cv, v) end
  if FCF_DockUpdate then Try(FCF_DockUpdate) end
  if FCF_SelectDockFrame and ChatFrame1 then Try(FCF_SelectDockFrame, ChatFrame1) end
  return fails
end

local function When(t) return t and date("%b %d", t) or "?" end

---------------------------------------------------------------------------
-- (1.1.0) named setups: save as many as you like ("Leveling", "Raid") and pick which one to load
---------------------------------------------------------------------------
local NEW = "\001new"   -- the "New Setup" choice
local setupChoices, autoChoices = {}, {}
local function Names()
  local list = {}
  for name in pairs(DB.setups) do list[#list + 1] = name end
  table.sort(list, function(x, y) return x:lower() < y:lower() end)
  return list
end
local function RefreshChoices()
  wipe(setupChoices); wipe(autoChoices)
  autoChoices[1] = { "Nothing", false }
  for _, n in ipairs(Names()) do
    setupChoices[#setupChoices + 1] = { n, n }
    autoChoices[#autoChoices + 1] = { n, n }
  end
  setupChoices[#setupChoices + 1] = { "+ New Setup", NEW }
  if DB.sel ~= NEW and not DB.setups[DB.sel or ""] then DB.sel = Names()[1] or NEW end
  if DB.newChar and not DB.setups[DB.newChar] then DB.newChar = Names()[1] or false end
end

local function SaveAs(name)
  name = (name or ""):gsub("^%s+", ""):gsub("%s+$", "")
  if name == "" then return end
  local first = next(DB.setups) == nil
  DB.setups[name] = Capture()
  DB.sel = name
  if first and DB.newChar == nil then DB.newChar = name end   -- your first setup is what new characters get
  RefreshChoices()
  Say(string.format(Tr("saved this chat as %s. Load it on any other character from Settings & Help"), name))
  if ns.RepaintHelp then ns.RepaintHelp() end
end

StaticPopupDialogs = StaticPopupDialogs or {}
StaticPopupDialogs.CHATSAVER_NAME = {
  text = "Name this chat setup", button1 = ACCEPT or "Accept", button2 = CANCEL or "Cancel",
  hasEditBox = true, maxLetters = 24, timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  OnShow = function(self)
    self.text:SetText(Tr("Name this chat setup"))
    local eb = self.editBox or self.EditBox
    if eb then eb:SetText(""); eb:SetFocus() end
  end,
  OnAccept = function(self)
    local eb = self.editBox or self.EditBox
    SaveAs(eb and eb:GetText())
  end,
  EditBoxOnEnterPressed = function(self)
    SaveAs(self:GetText())
    self:GetParent():Hide()
  end,
  EditBoxOnEscapePressed = function(self) self:GetParent():Hide() end,
}

local armed
local function Arm(what, msg)
  if armed == what then armed = nil; return true end
  armed = what
  Say(msg)
  C_Timer.After(8, function() if armed == what then armed = nil end end)
end

local function Save()
  if DB.sel == NEW or not DB.sel then
    if StaticPopup_Show then StaticPopup_Show("CHATSAVER_NAME") else SaveAs("Main") end
    return
  end
  if Arm("save" .. DB.sel, string.format(Tr("this replaces the saved setup %s with this character's chat. Click Save again to go ahead"), DB.sel)) then
    SaveAs(DB.sel)
  end
end

local function Load(confirmed, name)
  name = name or DB.sel
  local setup = name and DB.setups[name]
  if not setup then Say("nothing saved yet. Save your chat on the character it looks right on first") return end
  if not confirmed and not Arm("load" .. name, string.format(Tr("this replaces this character's chat with %s, saved from %s on %s. Click Load again to go ahead"),
      name, setup.from or "?", When(setup.when))) then return end
  local n = Apply(setup)
  CHAR.loaded, CHAR.loadedName = time(), name
  if n > 0 then Say(string.format(Tr("chat loaded, with %s small parts the game wouldn't take. Type /reload if anything looks off"), n))
  else Say("chat loaded") end
end

local function Delete()
  local name = DB.sel
  if not (name and DB.setups[name]) then return end
  if Arm("del" .. name, string.format(Tr("this deletes the saved setup %s. Click Delete again to go ahead"), name)) then
    DB.setups[name] = nil
    RefreshChoices()
    Say(string.format(Tr("deleted %s"), name))
    if ns.RepaintHelp then ns.RepaintHelp() end
  end
end

---------------------------------------------------------------------------
-- events: a brand new character gets the saved chat by itself
---------------------------------------------------------------------------
local MinimapButton
local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_ENTERING_WORLD")
ev:SetScript("OnEvent", function(_, e, a1, a2)
  if e == "ADDON_LOADED" then
    if a1 ~= ADDON then return end
    ChatSaverDB = ChatSaverDB or {}
    DB = ChatSaverDB
    DB.setups = DB.setups or {}
    if DB.setup then   -- 1.0.0 kept a single setup: it becomes "Main"
      DB.setups.Main = DB.setups.Main or DB.setup
      DB.setup = nil
      if DB.auto ~= false and DB.newChar == nil then DB.newChar = "Main" end
    end
    DB.auto = nil
    RefreshChoices()
    ChatSaverChar = ChatSaverChar or {}
    CHAR = ChatSaverChar
  elseif e == "PLAYER_ENTERING_WORLD" then
    pcall(MinimapButton)
    if a1 and not CHAR.seen then   -- the first login with this addon on this character
      CHAR.seen = true
      local new = (UnitLevel("player") or 99) <= 5
      local setup = DB.newChar and DB.setups[DB.newChar]
      if new and setup then
        C_Timer.After(3, function()   -- the chat windows finish setting up a moment after login
          local n = Apply(setup)
          CHAR.loaded, CHAR.loadedName = time(), DB.newChar
          Say(string.format(Tr("new character: loaded your saved chat %s"), DB.newChar) .. (n > 0 and " (" .. n .. ")" or ""))
        end)
      end
    end
  end
end)

---------------------------------------------------------------------------
-- Settings & Help (Help.lua, shared by Dalorrian's addons) and a minimap button
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Chat Saver",
  tag = "Chat Saver",
  settings = {
    { label = "Setup", cycle = true, choices = setupChoices,
      get = function() return DB.sel end, set = function(v) DB.sel = v end },
    { label = "This Setup", choices = { { "Save", "save" }, { "Load", "load" }, { "Delete", "delete" } },
      get = function() return nil end,
      set = function(v) if v == "save" then Save() elseif v == "load" then Load() else Delete() end end },
    { label = "New Characters Get", cycle = true, choices = autoChoices,
      get = function() return DB.newChar or false end, set = function(v) DB.newChar = v end },
  },
  notes = {
    { v = "1.1.0", "Save as many chat setups as you like, each with its own name, and pick which one to load. Pick which one new characters get, or none" },
    { v = "1.0.0", "First release: save your chat setup once and load it on any other character. New characters get it by themselves" },
  },
  report = function()
    return { "Setups " .. #Names() .. ", selected " .. tostring(DB.sel ~= NEW and DB.sel or "new") .. ", new characters " .. tostring(DB.newChar) ..
      ", loaded here " .. (CHAR.loaded and (tostring(CHAR.loadedName) .. " " .. When(CHAR.loaded)) or "never") }
  end,
}

MinimapButton = function()
  if not Minimap or _G.ChatSaverMinimapButton then return end
  local b = CreateFrame("Button", "ChatSaverMinimapButton", Minimap)
  b:SetSize(31, 31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK")
  b.icon:SetTexture("Interface\\Icons\\INV_Scroll_03")
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 125)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints()
    b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function() if ns.OpenHelp then ns.OpenHelp() end end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Chat Saver")
    Tip:AddLine("Click: Settings & Help", 1, 1, 1)
    local names = Names()
    if #names == 0 then Tip:AddLine("Nothing saved yet", 0.8, 0.8, 0.8) end
    for _, n in ipairs(names) do
      local st = DB.setups[n]
      GameTooltip:AddDoubleLine(n, (st.from or "?") .. ", " .. When(st.when), 1, 0.82, 0, 0.8, 0.8, 0.8)
    end
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
function ChatSaver_OnCompartmentClick() if ns.OpenHelp then ns.OpenHelp() end end

SLASH_CHATSAVER1 = "/chatsaver"
SlashCmdList.CHATSAVER = function(msg)
  local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  local function Find(n)   -- names typed in any case
    for k in pairs(DB.setups) do if k:lower() == n:lower() then return k end end
  end
  if cmd == "save" then
    if rest ~= "" then SaveAs(Find(rest) or rest) else Save() end
  elseif cmd == "load" then
    local n
    if rest ~= "" then n = Find(rest) else n = DB.sel end
    if not n or not DB.setups[n] then Say(string.format(Tr("no setup called %s"), rest)) else Load(true, n) end
  elseif cmd == "list" then
    local names = Names()
    if #names == 0 then Say("nothing saved yet. Save your chat on the character it looks right on first") end
    for _, n in ipairs(names) do P("  " .. n .. "  (" .. (DB.setups[n].from or "?") .. ", " .. When(DB.setups[n].when) .. ")") end
  elseif cmd == "" then
    Say("save your chat setup once and load it on any other character" .. ".")
    P("  /chatsaver save <name>   (" .. "save this character's chat" .. ")")
    P("  /chatsaver load <name>   (" .. "put the saved chat on this character" .. ")")
    P("  /chatsaver list")
    P("  /chatsaver help   (" .. "all settings, and how to report a bug" .. ")")
  elseif ns.OpenHelp then
    ns.OpenHelp()
  end
end
