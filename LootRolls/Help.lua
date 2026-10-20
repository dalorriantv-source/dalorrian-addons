-- Settings & Help window, shared by Dalorrian's addons (each addon carries its own copy).
-- Release notes, how to report a bug, a copy-ready bug report, and links to the Discord, Twitch and YouTube.
-- Nothing is sent anywhere by itself: the player copies the report and pastes it in Discord.
--
-- The addon fills in ns.HelpConfig (optional):
--   title    = "Podium"                       name shown on top (defaults to the .toc title)
--   tag      = "Podium"                       the forum tag to pick in #bug-reports
--   settings = { { label = "Look", choices = { { "Modern", "modern" }, { "Classic", "classic" } },
--                  get = function() return v end, set = function(v) end }, ... }
--   report   = function() return { "line", ... } end   extra lines for the bug report
--   notes    = { { v = "1.2.0", "what changed", "what else changed" }, ... }   release notes, newest first
-- A setting with cycle = true is one button that steps through its choices (Language uses it).
-- A setting with slider = { min, max, step } is a slider: get/set use numbers, format(v) is the text beside it,
-- and release() runs when you let go of it (a sound preview, say).
-- Every addon gets a Language row (Lang.lua) at the bottom of its settings.
-- Open it with ns.OpenHelp().

local ADDON, ns = ...
local CreateFrame = ns.CreateFrame or CreateFrame   -- Lang.lua: text on these frames is translated

local LINKS = {
  { name = "Discord", url = "discord.gg/SCvVgA7xHD" },
  { name = "Twitch",  url = "twitch.tv/dalorrian" },
  { name = "YouTube", url = "youtube.com/@DalorrianTV" },
}
local FLAT = "Interface\\Buttons\\WHITE8X8"
local GOLD = { 1, 0.82, 0 }
local W = 480

local function Meta(field)
  local get = (C_AddOns and C_AddOns.GetAddOnMetadata) or GetAddOnMetadata
  if not get then return nil end
  local ok, v = pcall(get, ADDON, field)
  return ok and v or nil
end
local function Cfg() return ns.HelpConfig or {} end
local function Title() return Cfg().title or Meta("Title") or ADDON end

---------------------------------------------------------------------------
-- Errors from this addon, kept for this session so they can go in the report
---------------------------------------------------------------------------
local errors = {}
do
  local prev = geterrorhandler and geterrorhandler()
  if seterrorhandler and prev then
    seterrorhandler(function(msg, ...)
      if type(msg) == "string" and (msg:find(ADDON .. "/", 1, true) or msg:find(ADDON .. "\\", 1, true)) then
        pcall(function()
          for _, e in ipairs(errors) do if e.msg == msg then e.n = e.n + 1; return end end
          local stack = debugstack and debugstack(2) or nil
          errors[#errors + 1] = { msg = msg, n = 1, stack = stack }
          if #errors > 5 then table.remove(errors, 1) end
        end)
      end
      return prev(msg, ...)
    end)
  end
end

local function Report()
  local lines = {}
  local function L(s) lines[#lines + 1] = s end
  local build, iface = "?", "?"
  if GetBuildInfo then local b, _, _, i = GetBuildInfo(); build, iface = b or "?", i or "?" end
  L(Title() .. " " .. (Meta("Version") or "?") .. "  |  client " .. tostring(build) .. " (" .. tostring(iface) .. ")  |  " ..
    (GetLocale and GetLocale() or "?") .. ((IsMacClient and IsMacClient()) and "  |  Mac" or ""))
  local _, class = UnitClass("player")
  L("Level " .. (UnitLevel("player") or "?") .. " " .. tostring(class or "?") .. "  |  " .. (GetRealZoneText and GetRealZoneText() or "?"))
  local extra = Cfg().report
  if extra then
    local ok, more = pcall(extra)
    if ok and type(more) == "table" then for _, s in ipairs(more) do L(tostring(s)) end end
  end
  if #errors == 0 then
    L("No errors from " .. Title() .. " this session.")
  else
    for i = #errors, 1, -1 do
      local e = errors[i]
      L("")
      L("ERROR x" .. e.n .. ": " .. e.msg)
      local n = 0
      for line in tostring(e.stack or ""):gmatch("[^\n]+") do
        if line:find(ADDON, 1, true) then
          n = n + 1
          if n <= 6 then L("   " .. line:gsub("^.-AddOns[/\\]", "")) end
        end
      end
    end
  end
  return table.concat(lines, "\n")
end

---------------------------------------------------------------------------
-- Window
---------------------------------------------------------------------------
local win

local function Solid(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetTexture(FLAT)
  t:SetVertexColor(r, g, b, a or 1)
  return t
end
local function Text(parent, font, r, g, b)
  local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
  fs:SetJustifyH("LEFT")
  if r then fs:SetTextColor(r, g, b) end
  return fs
end
local function Button(parent, w, label, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, 22)
  b.bg = Solid(b, "BACKGROUND", 0.14, 0.15, 0.19)
  b.bg:SetAllPoints()
  b.label = Text(b, "GameFontHighlightSmall")
  b.label:SetPoint("CENTER")
  b.label:SetJustifyH("CENTER")
  b.label:SetText(label)
  b.SetOn = function(self, on)
    self.on = on
    if on then
      self.bg:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 0.9); self.label:SetTextColor(0.1, 0.1, 0.1)
    else
      self.bg:SetVertexColor(0.14, 0.15, 0.19, 1); self.label:SetTextColor(0.85, 0.85, 0.9)
    end
  end
  b:SetScript("OnEnter", function(self) if not self.on then self.bg:SetVertexColor(0.22, 0.23, 0.28, 1) end end)
  b:SetScript("OnLeave", function(self) self:SetOn(self.on) end)
  b:SetScript("OnClick", onClick)
  b:SetOn(false)
  return b
end
-- a box for copying, not typing: anything typed puts the text back
local function CopyBox(parent, w, getText)
  local eb = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
  eb:SetSize(w, 22)
  eb:SetAutoFocus(false)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  eb:SetScript("OnMouseUp", function(self) self:SetFocus(); self:HighlightText() end)
  eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(getText()); self:HighlightText() end end)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  return eb
end

local function Build()
  local name = ADDON .. "HelpFrame"
  win = CreateFrame("Frame", name, UIParent, "BackdropTemplate")
  win:SetFrameStrata("DIALOG")
  win:SetToplevel(true)
  win:SetPoint("CENTER")
  win:SetMovable(true)
  win:EnableMouse(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  win:SetClampedToScreen(true)
  win:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })
  win:SetBackdropColor(0.06, 0.07, 0.09, 0.97)
  win:SetBackdropBorderColor(GOLD[1], GOLD[2], GOLD[3], 0.6)
  win:Hide()
  tinsert(UISpecialFrames, name)   -- Esc closes it

  local head = Solid(win, "ARTWORK", 0.10, 0.11, 0.14)
  head:SetPoint("TOPLEFT", 1, -1); head:SetPoint("TOPRIGHT", -1, -1); head:SetHeight(34)
  win.title = Text(win, "GameFontNormalLarge")
  win.title:SetPoint("TOPLEFT", 14, -10)
  win.ver = Text(win, "GameFontDisableSmall")
  win.ver:SetPoint("LEFT", win.title, "RIGHT", 8, -1)
  local close = CreateFrame("Button", nil, win)
  close:SetSize(26, 26); close:SetPoint("TOPRIGHT", -5, -5)
  close.label = Text(close, "GameFontHighlightLarge", 0.6, 0.6, 0.65)
  close.label:SetPoint("CENTER"); close.label:SetText("x")
  close:SetScript("OnEnter", function(self) self.label:SetTextColor(1, 0.35, 0.35) end)
  close:SetScript("OnLeave", function(self) self.label:SetTextColor(0.6, 0.6, 0.65) end)
  close:SetScript("OnClick", function() win:Hide() end)

  local y = -48

  -- Settings (only the ones this addon has)
  win.rows = {}
  local settings = {}
  for _, s in ipairs(Cfg().settings or {}) do settings[#settings + 1] = s end
  if ns.LangSetting then settings[#settings + 1] = ns.LangSetting() end
  if #settings > 0 then
    local h = Text(win, "GameFontNormal"); h:SetPoint("TOPLEFT", 16, y); h:SetText("Settings")
    y = y - 24
    for _, s in ipairs(settings) do
      local lab = Text(win, "GameFontHighlightSmall"); lab:SetPoint("TOPLEFT", 16, y - 4); lab:SetWidth(150); lab:SetText(s.label)
      local row = { s = s, btns = {} }
      if s.slider then
        -- a flat gold slider, the same look as the buttons
        local lo, hi, step = s.slider[1], s.slider[2], s.slider[3] or 1
        local sl = CreateFrame("Slider", nil, win)
        sl:SetOrientation("HORIZONTAL")
        sl:SetSize(186, 16)
        sl:SetPoint("TOPLEFT", 170, y - 3)
        sl:SetMinMaxValues(lo, hi)
        sl:SetValueStep(step)
        if sl.SetObeyStepOnDrag then sl:SetObeyStepOnDrag(true) end
        sl:EnableMouse(true)
        sl:EnableMouseWheel(true)
        local track = Solid(sl, "BACKGROUND", 0.14, 0.15, 0.19)
        track:SetPoint("LEFT"); track:SetPoint("RIGHT"); track:SetHeight(6)
        local fill = Solid(sl, "BORDER", GOLD[1], GOLD[2], GOLD[3], 0.55)
        fill:SetPoint("LEFT", track, "LEFT"); fill:SetHeight(6)
        sl:SetThumbTexture(FLAT)
        local th = sl:GetThumbTexture()
        if th then th:SetSize(10, 16); th:SetVertexColor(GOLD[1], GOLD[2], GOLD[3], 1) end
        local val = Text(win, "GameFontHighlightSmall")
        val:SetPoint("LEFT", sl, "RIGHT", 10, 0)
        sl.Show2 = function(self, v)
          v = math.floor(v / step + 0.5) * step
          fill:SetWidth(math.max(1, (v - lo) / (hi - lo) * self:GetWidth()))
          val:SetText(s.format and s.format(v) or tostring(v))
          return v
        end
        sl:SetScript("OnValueChanged", function(self, v)
          v = self:Show2(v)
          if not self.painting then pcall(s.set, v) end
        end)
        local function Release() if s.release then pcall(s.release) end end
        sl:SetScript("OnMouseUp", Release)
        sl:SetScript("OnMouseWheel", function(self, d)
          self:SetValue(math.max(lo, math.min(hi, self:GetValue() + d * step))); Release()
        end)
        row.slider = sl
      end
      if s.cycle then
        -- one button: shows the current choice, a click moves to the next one
        local b = Button(win, 186, "", function()
          local ok, cur = pcall(s.get)
          local at = 1
          for i, c in ipairs(s.choices) do if ok and c[2] == cur then at = i end end
          local nxt = s.choices[at % #s.choices + 1]
          pcall(s.set, nxt[2]); win:Paint()
        end)
        b:SetPoint("TOPLEFT", 170, y)
        row.cycle = b
        if s.apply then
          -- a green check that saves and reloads (shows only when a change is waiting)
          local ok = CreateFrame("Button", nil, win)
          ok:SetSize(24, 24)
          ok:SetPoint("LEFT", b, "RIGHT", 8, 0)
          ok.tex = ok:CreateTexture(nil, "ARTWORK"); ok.tex:SetAllPoints()
          ok.tex:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
          ok:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
          ok:SetScript("OnClick", function() pcall(s.apply) end)
          ok:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:AddLine(ns.Tr and ns.Tr("Save and reload") or "Save and reload")
            GameTooltip:Show()
          end)
          ok:SetScript("OnLeave", function() GameTooltip:Hide() end)
          ok:Hide()
          row.apply = ok
        end
      end
      for i, c in ipairs((s.cycle or s.slider) and {} or s.choices) do
        local b = Button(win, 90, c[1], function()
          pcall(s.set, c[2]); win:Paint()
        end)
        b:SetPoint("TOPLEFT", 170 + (i - 1) * 96, y)
        b.value = c[2]
        row.btns[#row.btns + 1] = b
      end
      win.rows[#win.rows + 1] = row
      y = y - 28
    end
    y = y - 10
  end

  -- Help, release notes, the bug report and the links sit behind one button, so the window opens small
  -- with just the settings (shared by Dalorrian's addons: keep it this way in every one)
  local toggle = Button(win, W - 32, "Help & Release Notes  +", function() win:SetMore(not win.moreShown) end)
  toggle:SetPoint("TOPLEFT", 16, y)
  win.toggle = toggle
  y = y - 32
  local top = y
  local more = CreateFrame("Frame", nil, win)
  more:SetPoint("TOPLEFT", 0, top)
  more:SetWidth(W)
  win.more = more
  y = 0

  -- Release Notes (newest first, scrolls)
  local notes = Cfg().notes
  if type(notes) == "table" and #notes > 0 then
    local nh = Text(more, "GameFontNormal"); nh:SetPoint("TOPLEFT", 16, y); nh:SetText("Release Notes")
    local nsub = Text(more, "GameFontDisableSmall"); nsub:SetPoint("LEFT", nh, "RIGHT", 10, 0); nsub:SetText("What changed in each version.")
    y = y - 22
    local nbox = CreateFrame("Frame", nil, more, "BackdropTemplate")
    nbox:SetPoint("TOPLEFT", 16, y); nbox:SetSize(W - 32, 120)
    nbox:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })
    nbox:SetBackdropColor(0, 0, 0, 0.6); nbox:SetBackdropBorderColor(0.25, 0.26, 0.3, 1)
    local nsf = CreateFrame("ScrollFrame", nil, nbox, "UIPanelScrollFrameTemplate")
    nsf:SetPoint("TOPLEFT", 8, -6); nsf:SetPoint("BOTTOMRIGHT", -26, 6)
    local child = CreateFrame("Frame", nil, nsf)
    child:SetSize(W - 76, 10)
    local body = Text(child, "GameFontHighlightSmall")
    body:SetPoint("TOPLEFT", 0, 0); body:SetWidth(W - 76); body:SetSpacing(2)
    local parts = {}
    for i, n in ipairs(notes) do
      if i > 1 then parts[#parts + 1] = " " end
      parts[#parts + 1] = "|cffffd200v" .. tostring(n.v or "?") .. "|r" .. (n.title and ("  " .. n.title) or "")
      for _, line in ipairs(n) do parts[#parts + 1] = "  - " .. line end
    end
    body:SetText(table.concat(parts, "\n"))
    local function Fit() child:SetHeight(math.max(10, (body:GetStringHeight() or 0) + 4)) end
    Fit()
    nsf:SetScrollChild(child)
    nsf:SetScript("OnShow", function(self) Fit(); self:SetVerticalScroll(0) end)
    y = y - 130
  end

  -- Found a bug?
  local bh = Text(more, "GameFontNormal"); bh:SetPoint("TOPLEFT", 16, y); bh:SetText("Found a bug?")
  y = y - 22
  win.steps = Text(more, "GameFontHighlightSmall")
  win.steps:SetPoint("TOPLEFT", 16, y); win.steps:SetWidth(W - 32); win.steps:SetSpacing(3)
  y = y - 70

  local box = CreateFrame("Frame", nil, more, "BackdropTemplate")
  box:SetPoint("TOPLEFT", 16, y); box:SetSize(W - 32, 110)
  box:SetBackdrop({ bgFile = FLAT, edgeFile = FLAT, edgeSize = 1 })
  box:SetBackdropColor(0, 0, 0, 0.6); box:SetBackdropBorderColor(0.25, 0.26, 0.3, 1)
  local sf = CreateFrame("ScrollFrame", nil, box, "UIPanelScrollFrameTemplate")
  sf:SetPoint("TOPLEFT", 6, -6); sf:SetPoint("BOTTOMRIGHT", -26, 6)
  local eb = CreateFrame("EditBox", nil, sf)
  eb:SetMultiLine(true); eb:SetAutoFocus(false); eb:SetWidth(W - 70)
  eb:SetFontObject(ChatFontSmall or GameFontHighlightSmall)
  eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  eb:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
  eb:SetScript("OnTextChanged", function(self, user) if user then self:SetText(win.report or ""); self:HighlightText() end end)
  sf:SetScrollChild(eb)
  win.edit = eb
  y = y - 118

  local sel = Button(more, 110, "Select All", function() win.edit:SetFocus(); win.edit:HighlightText() end)
  sel:SetPoint("TOPLEFT", 16, y)
  local note = Text(more, "GameFontDisableSmall"); note:SetPoint("LEFT", sel, "RIGHT", 10, 0); note:SetWidth(W - 160)
  note:SetText("Nothing is sent anywhere by itself. You copy it and paste it.")
  y = y - 36

  -- Links
  local lh = Text(more, "GameFontNormal"); lh:SetPoint("TOPLEFT", 16, y); lh:SetText("Find Dalorrian")
  local lsub = Text(more, "GameFontDisableSmall"); lsub:SetPoint("LEFT", lh, "RIGHT", 10, 0); lsub:SetText("Click a box, then Ctrl+C to copy.")
  y = y - 24
  for _, l in ipairs(LINKS) do
    local lab = Text(more, "GameFontHighlightSmall"); lab:SetPoint("TOPLEFT", 16, y - 5); lab:SetText(l.name)
    local link = "https://" .. l.url
    local cb = CopyBox(more, W - 120, function() return link end)
    cb:SetPoint("TOPLEFT", 96, y)
    cb:SetText(link); cb:SetCursorPosition(0)
    y = y - 28
  end

  more:SetHeight(-y)
  win.smallH = -top + 8
  win.bigH = -top - y + 12
  function win:SetMore(on)
    self.moreShown = on
    self.more:SetShown(on)
    self:SetHeight(on and self.bigH or self.smallH)
    self.toggle.label:SetText(on and "Help & Release Notes  -" or "Help & Release Notes  +")
  end
  win:SetSize(W, win.smallH)
  win:SetMore(false)


  function win:Paint()
    for _, row in ipairs(self.rows) do
      local ok, v = pcall(row.s.get)
      for _, b in ipairs(row.btns) do b:SetOn(ok and v == b.value) end
      if row.slider and ok and tonumber(v) then
        row.slider.painting = true
        row.slider:SetValue(v); row.slider:Show2(v)
        row.slider.painting = nil
      end
      if row.cycle then
        local label = "?"
        for _, c in ipairs(row.s.choices) do if ok and c[2] == v then label = c[1] end end
        row.cycle.label:SetText(label .. "  >")
        if row.apply then
          local okP, want = pcall(row.s.pending or function() return false end)
          row.apply:SetShown(okP and want and true or false)
        end
      end
    end
  end
end

function ns.OpenHelp()
  if not win then Build() end
  if win:IsShown() then win:Hide(); return end
  local tag = Cfg().tag or Title()
  win.title:SetText(Title() .. ((#win.rows > 0) and "  Settings & Help" or "  Help"))
  win.ver:SetText("v" .. (Meta("Version") or "?"))
  win.steps:SetText(
    "1. Take a screenshot when it happens (|cffffd200Print Screen|r, saved in your WoW Screenshots folder).\n" ..
    "2. Click |cffffd200Select All|r below and copy it (|cffffd200Ctrl+C|r, or |cffffd200Cmd+C|r on a Mac).\n" ..
    "3. On our Discord, post in |cffffd200#bug-reports|r with the |cffffd200" .. tag .. "|r tag: paste the report,\n" ..
    "    add the screenshot and say what you were doing.")
  win.report = Report()
  win.edit:SetText(win.report); win.edit:SetCursorPosition(0)
  win:Paint()
  win:Show()
end
