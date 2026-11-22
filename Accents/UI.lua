-- Dalorrian's Accents: the window (Accents, Awards, Where), toasts, the chat button, the minimap button,
-- the "someone asked" prompt, settings and slash commands.
local ADDON, ns = ...
local CreateFrame = ns.CreateFrame or CreateFrame
local Tr = function(x) return (ns.Tr or function(y) return y end)(x) end
local Tip = ns.Tip or GameTooltip
local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF"
local PINK = { 1, 0.56, 0.69 }
local GOLD = { 1, 0.82, 0 }

local function Solid(parent, layer, r, g, b, a)
  local t = parent:CreateTexture(nil, layer or "BACKGROUND")
  t:SetTexture(FLAT); t:SetVertexColor(r, g, b, a or 1)
  return t
end
local function Text(parent, size, flags)
  local f = parent:CreateFontString(nil, "OVERLAY")
  f:SetFont(FONT, size or 12, flags or "")
  f:SetShadowColor(0, 0, 0, 1); f:SetShadowOffset(1, -1)
  return f
end
local function Box(f, r, g, b, a)
  f.bg = Solid(f, "BACKGROUND", r or 0.06, g or 0.06, b or 0.08, a or 0.96); f.bg:SetAllPoints()
  for _, e in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 1 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 1 } }) do
    local l = Solid(f, "BORDER", 0, 0, 0, 1); l:SetPoint(e[1]); l:SetPoint(e[2]); l:SetHeight(1)
  end
  for _, e in ipairs({ { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }) do
    local l = Solid(f, "BORDER", 0, 0, 0, 1); l:SetPoint(e[1]); l:SetPoint(e[2]); l:SetWidth(1)
  end
end
local function Button(parent, w, h, label, onClick)
  local b = CreateFrame("Button", nil, parent)
  b:SetSize(w, h)
  b.bg = Solid(b, "BACKGROUND", 0.14, 0.15, 0.19); b.bg:SetAllPoints()
  b.hl = Solid(b, "HIGHLIGHT", 1, 1, 1, 0.08); b.hl:SetAllPoints()
  b.text = Text(b, 11); b.text:SetPoint("CENTER"); b.text:SetText(label or "")
  b.SetOn = function(self, on)
    if on then self.bg:SetVertexColor(PINK[1] * 0.55, PINK[2] * 0.4, PINK[3] * 0.45); self.text:SetTextColor(1, 1, 1)
    else self.bg:SetVertexColor(0.14, 0.15, 0.19); self.text:SetTextColor(0.8, 0.8, 0.85) end
  end
  b:SetOn(false)
  if onClick then b:SetScript("OnClick", onClick) end
  return b
end
local function Sound(kit)
  if not (ns.DB and ns.DB.sound) then return end
  local id = SOUNDKIT and SOUNDKIT[kit]
  if id then pcall(PlaySound, id) end
end

---------------------------------------------------------------------------
-- Toasts: awards, new ranks and unlocks pop in at the top of the screen
---------------------------------------------------------------------------
local toast, queue = nil, {}
local function NextToast()
  if not toast or toast:IsShown() or #queue == 0 then return end
  local q = table.remove(queue, 1)
  toast.kind:SetText(Tr(q[1]))
  toast.name:SetText(Tr(q[2]))
  toast.desc:SetText(Tr(q[3] or ""))
  toast.icon:SetTexture(q[4] or ns.ICON)
  toast:SetAlpha(0)
  toast:Show()
  toast.anim:Play()
  Sound("UI_EPICLOOT_TOAST")
end
function ns.Toast(kind, name, desc, icon)
  if not (ns.DB and ns.DB.toasts) then return end
  queue[#queue + 1] = { kind, name, desc, icon }
  NextToast()
end
local function BuildToast()
  toast = CreateFrame("Frame", nil, UIParent)
  toast:SetSize(360, 64)
  toast:SetPoint("TOP", 0, -140)
  toast:SetFrameStrata("HIGH")
  Box(toast, 0.07, 0.05, 0.07, 0.95)
  local edge = Solid(toast, "BORDER", PINK[1], PINK[2], PINK[3], 1); edge:SetPoint("TOPLEFT"); edge:SetPoint("BOTTOMLEFT"); edge:SetWidth(3)
  toast.icon = toast:CreateTexture(nil, "ARTWORK"); toast.icon:SetSize(42, 42); toast.icon:SetPoint("LEFT", 14, 0)
  toast.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  toast.kind = Text(toast, 10); toast.kind:SetPoint("TOPLEFT", toast.icon, "TOPRIGHT", 12, 0); toast.kind:SetTextColor(PINK[1], PINK[2], PINK[3])
  toast.name = Text(toast, 15, "OUTLINE"); toast.name:SetPoint("TOPLEFT", toast.kind, "BOTTOMLEFT", 0, -2); toast.name:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  toast.desc = Text(toast, 10); toast.desc:SetPoint("TOPLEFT", toast.name, "BOTTOMLEFT", 0, -2); toast.desc:SetWidth(280)
  toast.desc:SetJustifyH("LEFT"); toast.desc:SetTextColor(0.85, 0.85, 0.9)
  toast.anim = toast:CreateAnimationGroup()
  local fin = toast.anim:CreateAnimation("Alpha"); fin:SetFromAlpha(0); fin:SetToAlpha(1); fin:SetDuration(0.25); fin:SetOrder(1)
  local hold = toast.anim:CreateAnimation("Alpha"); hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(3.5); hold:SetOrder(2)
  local fout = toast.anim:CreateAnimation("Alpha"); fout:SetFromAlpha(1); fout:SetToAlpha(0); fout:SetDuration(0.6); fout:SetOrder(3)
  toast.anim:SetScript("OnFinished", function() toast:Hide(); NextToast() end)
  toast:EnableMouse(true)
  toast:SetScript("OnMouseUp", function() toast.anim:Stop(); toast:Hide(); if ns.OpenWindow then ns.OpenWindow("awards") end; NextToast() end)
  toast:Hide()
end

---------------------------------------------------------------------------
-- The Godd Howard badge: a gold gear stamp that slams onto the middle of the screen when he's found
---------------------------------------------------------------------------
local badge
function ns.GoddBadge()
  if not badge then
    badge = CreateFrame("Frame", nil, UIParent)
    badge:SetSize(300, 300)
    badge:SetPoint("CENTER", 0, 80)
    badge:SetFrameStrata("DIALOG")
    -- the gear, big, behind everything
    badge.gear = badge:CreateTexture(nil, "BACKGROUND")
    badge.gear:SetTexture("Interface\\Icons\\Trade_Engineering"); badge.gear:SetSize(150, 150); badge.gear:SetPoint("CENTER", 0, 20)
    badge.gear:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    -- a gold frame around it
    for _, side in ipairs({ { "TOPLEFT", "TOPRIGHT", 0, 4 }, { "BOTTOMLEFT", "BOTTOMRIGHT", 0, 4 }, { "TOPLEFT", "BOTTOMLEFT", 4, 0 }, { "TOPRIGHT", "BOTTOMRIGHT", 4, 0 } }) do
      local t = badge:CreateTexture(nil, "BORDER"); t:SetColorTexture(GOLD[1], GOLD[2], GOLD[3], 1)
      t:SetPoint(side[1], badge.gear, side[1], 0, 0); t:SetPoint(side[2], badge.gear, side[2], 0, 0)
      if side[3] > 0 then t:SetWidth(side[3]) else t:SetHeight(side[4]) end
    end
    -- the stamp across it
    badge.band = badge:CreateTexture(nil, "ARTWORK"); badge.band:SetColorTexture(0.55, 0.05, 0.05, 0.92)
    badge.band:SetSize(260, 40); badge.band:SetPoint("CENTER", badge.gear, "CENTER", 0, -6)
    badge.title = Text(badge, 24, "OUTLINE"); badge.title:SetPoint("CENTER", badge.band, "CENTER", 0, 0)
    badge.title:SetText("IT JUST WORKS"); badge.title:SetTextColor(1, 1, 1)
    badge.sub = Text(badge, 12, "OUTLINE"); badge.sub:SetPoint("TOP", badge.gear, "BOTTOM", 0, -10)
    badge.sub:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    badge.sub:SetText(Tr("Secret accent found: Godd Howard"))
    badge.anim = badge:CreateAnimationGroup()
    local grow = badge.anim:CreateAnimation("Scale"); grow:SetScaleFrom(2.2, 2.2); grow:SetScaleTo(1, 1); grow:SetDuration(0.22); grow:SetOrder(1)
    local fin = badge.anim:CreateAnimation("Alpha"); fin:SetFromAlpha(0); fin:SetToAlpha(1); fin:SetDuration(0.15); fin:SetOrder(1)
    local hold = badge.anim:CreateAnimation("Alpha"); hold:SetFromAlpha(1); hold:SetToAlpha(1); hold:SetDuration(3); hold:SetOrder(2)
    local fout = badge.anim:CreateAnimation("Alpha"); fout:SetFromAlpha(1); fout:SetToAlpha(0); fout:SetDuration(0.8); fout:SetOrder(3)
    badge.anim:SetScript("OnFinished", function() badge:Hide() end)
    badge:EnableMouse(true)
    badge:SetScript("OnMouseUp", function() badge.anim:Stop(); badge:Hide() end)
  end
  badge:Show(); badge:SetAlpha(1); badge.anim:Stop(); badge.anim:Play()
  if ns.DB and ns.DB.sound ~= false and PlaySound then pcall(PlaySound, 888) end   -- the level-up fanfare
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------
local W, H = 560, 470
local win
local function GroupTag(g) return (g == "race" and "Race") or (g == "monster" and "Monster") or (g == "fantasy" and "Fantasy") or (g == "secret" and "Secret") or "Silly" end

local function BuildWindow()
  win = CreateFrame("Frame", "AccentsWindow", UIParent)
  win:SetSize(W, H)
  win:SetPoint("CENTER")
  win:SetFrameStrata("DIALOG")
  win:SetMovable(true); win:EnableMouse(true); win:SetClampedToScreen(true)
  win:RegisterForDrag("LeftButton")
  win:SetScript("OnDragStart", win.StartMoving)
  win:SetScript("OnDragStop", win.StopMovingOrSizing)
  Box(win)
  tinsert(UISpecialFrames, "AccentsWindow")
  local head = Solid(win, "ARTWORK", 0.1, 0.08, 0.1, 1); head:SetPoint("TOPLEFT", 1, -1); head:SetPoint("TOPRIGHT", -1, -1); head:SetHeight(34)
  local icon = win:CreateTexture(nil, "OVERLAY"); icon:SetSize(22, 22); icon:SetPoint("TOPLEFT", 10, -7); icon:SetTexture(ns.ICON)
  icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local title = Text(win, 15, "OUTLINE"); title:SetPoint("LEFT", icon, "RIGHT", 8, 0); title:SetText("Accents")
  title:SetTextColor(PINK[1], PINK[2], PINK[3])
  win.count = Text(win, 11); win.count:SetPoint("LEFT", title, "RIGHT", 12, 0); win.count:SetTextColor(0.7, 0.7, 0.75)
  local close = Button(win, 24, 24, "X", function() win:Hide() end); close:SetPoint("TOPRIGHT", -6, -6)
  local help = Button(win, 110, 24, "Settings & Help", function() if ns.OpenHelp then ns.OpenHelp() end end)
  help:SetPoint("RIGHT", close, "LEFT", -6, 0)

  -- top bar: on/off, current accent
  win.onoff = Button(win, 70, 26, "", function() ns.SetOn(not ns.CDB.on) end)
  win.onoff:SetPoint("TOPLEFT", 12, -44)
  win.current = Text(win, 13); win.current:SetPoint("LEFT", win.onoff, "RIGHT", 10, 0)
  win.str = {}

  -- tabs
  win.tabs, win.pages = {}, {}
  for i, t in ipairs({ { "accents", "Accents" }, { "awards", "Awards" }, { "where", "Where" } }) do
    local b = Button(win, 100, 24, t[2], function() ns.OpenWindow(t[1]) end)
    b:SetPoint("TOPLEFT", 12 + (i - 1) * 104, -80)
    win.tabs[t[1]] = b
    local page = CreateFrame("Frame", nil, win)
    page:SetPoint("TOPLEFT", 12, -110); page:SetPoint("BOTTOMRIGHT", -12, 12)
    page:Hide()
    win.pages[t[1]] = page
  end

  -- Accents page: a scrolling list
  local pa = win.pages.accents
  pa.rows, pa.offset = {}, 0
  local ROWS, RH = 8, 43
  for r = 1, ROWS do
    local row = CreateFrame("Button", nil, pa)
    row:SetSize(W - 24, RH - 3)
    row:SetPoint("TOPLEFT", 0, -(r - 1) * RH)
    row.bg = Solid(row, "BACKGROUND", 0.1, 0.1, 0.13, 1); row.bg:SetAllPoints()
    row.hl = Solid(row, "HIGHLIGHT", 1, 1, 1, 0.06); row.hl:SetAllPoints()
    row.sel = Solid(row, "BORDER", PINK[1], PINK[2], PINK[3], 1); row.sel:SetPoint("TOPLEFT"); row.sel:SetPoint("BOTTOMLEFT"); row.sel:SetWidth(3)
    row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(32, 32); row.icon:SetPoint("LEFT", 8, 0); row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.name = Text(row, 13); row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
    row.tag = Text(row, 10); row.tag:SetPoint("LEFT", row.name, "RIGHT", 8, 0); row.tag:SetTextColor(0.55, 0.55, 0.6)
    row.blurb = Text(row, 10); row.blurb:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 1); row.blurb:SetTextColor(0.7, 0.7, 0.75)
    row.rank = Text(row, 11); row.rank:SetPoint("TOPRIGHT", -10, -5); row.rank:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
    row.track = Solid(row, "ARTWORK", 0.18, 0.18, 0.22, 1); row.track:SetSize(140, 5); row.track:SetPoint("BOTTOMRIGHT", -10, 8)
    row.fill = Solid(row, "OVERLAY", PINK[1], PINK[2], PINK[3], 1); row.fill:SetHeight(5); row.fill:SetPoint("LEFT", row.track, "LEFT")
    row.prog = Text(row, 9); row.prog:SetPoint("RIGHT", row.track, "LEFT", -6, 0); row.prog:SetTextColor(0.6, 0.6, 0.65)
    row:SetScript("OnClick", function(self)
      if not self.key then return end
      if ns.SetAccent(self.key) then ns.SetOn(true) end
    end)
    row:SetScript("OnEnter", function(self)
      if not self.key then return end
      local d = ns.ACCENTS[self.key]
      Tip:SetOwner(self, "ANCHOR_RIGHT")
      if not ns.IsUnlocked(self.key) then
        -- locked: no name, no sample, just a nudge
        Tip:AddLine("???", 0.6, 0.6, 0.65)
        Tip:AddLine(d.secret and Tr("A secret accent. No hints.") or Tr("Keep talking to unlock it, or find its secret way in."), 1, 1, 1, true)
        Tip:Show()
        return
      end
      Tip:AddLine(d.name, GOLD[1], GOLD[2], GOLD[3])
      if d.blurb then Tip:AddLine(d.blurb, 1, 1, 1, true) end
      local sample = ns.Turn(self.key, "Hey guys, thanks for the group! Ready to go?", 3)
      Tip:AddLine(" ")
      Tip:AddLine("Sample:", 0.6, 0.6, 0.65)
      Tip:AddLine(sample, 0.9, 0.9, 1, true)
      local slash = d.slash and ("/" .. d.slash) or ("/ac " .. self.key)
      Tip:AddLine(" ")
      Tip:AddLine(slash .. " <message>: " .. Tr("one line in this accent"), 0.6, 0.6, 0.65)
      Tip:Show()
    end)
    row:SetScript("OnLeave", function() Tip:Hide() end)
    pa.rows[r] = row
  end
  pa:EnableMouseWheel(true)
  pa:SetScript("OnMouseWheel", function(self, d)
    self.offset = math.max(0, math.min(math.max(0, #ns.ListOrder() - ROWS), self.offset - d))
    ns.RefreshUI()
  end)
  pa.Paint = function()
    local DB = ns.DB
    local list = {}
    for _, k in ipairs(ns.ListOrder()) do list[#list + 1] = k end
    for r = 1, ROWS do
      local row, key = pa.rows[r], list[r + pa.offset]
      row.key = key
      if not key then row:Hide() else
        row:Show()
        local d = ns.ACCENTS[key]
        local open, at = ns.IsUnlocked(key)
        local n = DB.per[key] or 0
        local rk = ns.RankOf(key, n)
        row.icon:SetTexture(open and (d.icon or ns.ICON) or "Interface\\Icons\\INV_Misc_QuestionMark")
        row.icon:SetDesaturated(not open)
        row.name:SetText(open and Tr(d.name) or "???"); row.name:SetTextColor(open and 1 or 0.5, open and 1 or 0.5, open and 1 or 0.55)
        row.tag:SetText(open and Tr(GroupTag(d.group)) or "")
        row.sel:SetShown(key == ns.Current() and ns.CDB.on)
        if open then
          row.blurb:SetText(Tr(d.blurb or ""))
          row.rank:SetText(rk > 0 and Tr(ns.RankTitle(key, rk)) or Tr("No rank yet"))
          local nextAt = ns.RANK_AT[rk + 1]
          local from = ns.RANK_AT[rk] or 0
          if nextAt then
            row.prog:SetText(n .. " / " .. nextAt)
            row.fill:SetWidth(math.max(1, 140 * (n - from) / (nextAt - from)))
          else
            row.prog:SetText(n); row.fill:SetWidth(140)
          end
          row.track:Show(); row.fill:Show()
        else
          if d.secret then row.blurb:SetText(Tr("A secret."))
          else row.blurb:SetText(string.format(Tr("Unlocks at %d messages (you have %d), or find its secret way"), at or 0, DB.total)) end
          row.rank:SetText(Tr("Locked")); row.prog:SetText("")
          row.track:Hide(); row.fill:Hide()
        end
      end
    end
  end

  -- Awards page
  local pw = win.pages.awards
  pw.rows, pw.offset = {}, 0
  local AROWS, AH = 9, 38
  pw.head = Text(pw, 11); pw.head:SetPoint("TOPLEFT", 0, 0); pw.head:SetTextColor(0.7, 0.7, 0.75)
  for r = 1, AROWS do
    local row = CreateFrame("Frame", nil, pw)
    row:SetSize(W - 24, AH - 3)
    row:SetPoint("TOPLEFT", 0, -18 - (r - 1) * AH)
    row.bg = Solid(row, "BACKGROUND", 0.1, 0.1, 0.13, 1); row.bg:SetAllPoints()
    row.icon = row:CreateTexture(nil, "ARTWORK"); row.icon:SetSize(28, 28); row.icon:SetPoint("LEFT", 6, 0); row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.name = Text(row, 12); row.name:SetPoint("TOPLEFT", row.icon, "TOPRIGHT", 10, -1)
    row.desc = Text(row, 10); row.desc:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 10, 1); row.desc:SetTextColor(0.7, 0.7, 0.75)
    row.when = Text(row, 10); row.when:SetPoint("RIGHT", -10, 0); row.when:SetTextColor(0.55, 0.55, 0.6)
    pw.rows[r] = row
  end
  pw:EnableMouseWheel(true)
  pw:SetScript("OnMouseWheel", function(self, d)
    self.offset = math.max(0, math.min(math.max(0, #ns.AWARDS - AROWS), self.offset - d))
    ns.RefreshUI()
  end)
  pw.Paint = function()
    local DB = ns.DB
    local got, hidden = 0, 0
    for _, a in ipairs(ns.AWARDS) do if DB.awards[a.id] then got = got + 1 end; if a.hidden then hidden = hidden + 1 end end
    pw.head:SetText(string.format(Tr("%d of %d awards earned (%d are hidden until you find them)"), got, #ns.AWARDS, hidden))
    -- earned first, then the ones you can see, then the hidden ones
    local list = {}
    for _, a in ipairs(ns.AWARDS) do list[#list + 1] = a end
    table.sort(list, function(x, y)
      local gx, gy = DB.awards[x.id] and 0 or (x.hidden and 2 or 1), DB.awards[y.id] and 0 or (y.hidden and 2 or 1)
      if gx ~= gy then return gx < gy end
      return (x._i or 0) < (y._i or 0)
    end)
    for r = 1, AROWS do
      local row, a = pw.rows[r], list[r + pw.offset]
      if not a then row:Hide() else
        row:Show()
        local have = DB.awards[a.id]
        local secret = a.hidden and not have
        row.icon:SetTexture(secret and "Interface\\Icons\\INV_Misc_QuestionMark" or ("Interface\\Icons\\" .. a.icon))
        row.icon:SetDesaturated(not have)
        row.name:SetText(secret and "???" or Tr(a.name))
        row.name:SetTextColor(have and GOLD[1] or 0.75, have and GOLD[2] or 0.75, have and GOLD[3] or 0.78)
        row.desc:SetText(Tr(secret and a.clue or a.desc))
        row.when:SetText(have and date("%b %d, %Y", have) or "")
      end
    end
  end
  for i, a in ipairs(ns.AWARDS) do a._i = i end

  -- Where page: where accents apply, and where awards are announced
  local pe = win.pages.where
  local h1 = Text(pe, 13); h1:SetPoint("TOPLEFT", 0, 0); h1:SetText("Talk in an accent in:"); h1:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  pe.where = {}
  for i, w in ipairs(ns.WHERE) do
    local b = Button(pe, 124, 26, w.label, function() ns.DB.where[w.key] = not ns.DB.where[w.key]; ns.RefreshUI() end)
    b:SetPoint("TOPLEFT", ((i - 1) % 4) * 132, -22 - math.floor((i - 1) / 4) * 32)
    b.key = w.key
    pe.where[i] = b
  end
  local note = Text(pe, 10); note:SetPoint("TOPLEFT", 0, -122); note:SetWidth(W - 40); note:SetJustifyH("LEFT")
  note:SetTextColor(0.6, 0.6, 0.65)
  note:SetText("Start a message with (( or press Shift+Enter to send one line plain. Links, names, numbers, web addresses and \"quoted text\" are never changed.")
  local h2 = Text(pe, 13); h2:SetPoint("TOPLEFT", 0, -160); h2:SetText("Announce awards, ranks and unlocks in:"); h2:SetTextColor(GOLD[1], GOLD[2], GOLD[3])
  pe.ann = {}
  for i, a in ipairs(ns.ANNOUNCE) do
    local b = Button(pe, 124, 26, a.label, function() ns.DB.announce[a.key] = not ns.DB.announce[a.key]; ns.RefreshUI() end)
    b:SetPoint("TOPLEFT", (i - 1) * 132, -182)
    b.key = a.key
    pe.ann[i] = b
  end
  local note2 = Text(pe, 10); note2:SetPoint("TOPLEFT", 0, -216); note2:SetWidth(W - 40); note2:SetJustifyH("LEFT")
  note2:SetTextColor(0.6, 0.6, 0.65)
  note2:SetText("Party posts in party or raid chat when you're in a group. Instance posts in instance groups. Turn them all off to keep awards to yourself.")
  pe.Paint = function()
    for _, b in ipairs(pe.where) do b:SetOn(ns.DB.where[b.key]) end
    for _, b in ipairs(pe.ann) do b:SetOn(ns.DB.announce[b.key]) end
  end

  win:Hide()
end

function ns.RefreshUI()
  if ns.chatButton then ns.chatButton:Paint() end
  if not win or not win:IsShown() then return end
  local CDB, DB = ns.CDB, ns.DB
  win.onoff.text:SetText(CDB.on and Tr("ON") or Tr("OFF"))
  win.onoff:SetOn(CDB.on)
  local d = ns.ACCENTS[ns.Current()]
  win.current:SetText(d and (Tr("Talking as") .. " |cffffd100" .. Tr(d.name) .. "|r") or "")
  for i, b in ipairs(win.str) do b:SetOn(CDB.strength == i) end
  win.count:SetText(string.format(Tr("%d messages  ·  %d of %d accents unlocked"), DB.total, ns.UnlockedCount(), ns.PublicCount()))
  for k, b in pairs(win.tabs) do b:SetOn(win.pages[k]:IsShown()) end
  for _, p in pairs(win.pages) do if p:IsShown() and p.Paint then p.Paint() end end
end

function ns.OpenWindow(tab)
  if not win then BuildWindow() end
  tab = tab or win.tab or "accents"
  win.tab = tab
  for k, p in pairs(win.pages) do p:SetShown(k == tab) end
  win:Show()
  ns.RefreshUI()
end
function ns.ToggleWindow()
  if win and win:IsShown() then win:Hide() else ns.OpenWindow() end
end

---------------------------------------------------------------------------
-- The button on the chat window, and the label while you type
---------------------------------------------------------------------------
local function BuildChatButton()
  local parent = _G.ChatFrame1
  if not parent then return end
  local b = CreateFrame("Button", "AccentsChatButton", UIParent)
  b:SetSize(22, 22)
  b:SetPoint("BOTTOMRIGHT", parent, "TOPRIGHT", 2, 4)
  b:SetFrameStrata("MEDIUM")
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetAllPoints(); b.icon:SetTexture(ns.ICON); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  b.ring = Solid(b, "BORDER", 0, 0, 0, 1); b.ring:SetPoint("TOPLEFT", -1, 1); b.ring:SetPoint("BOTTOMRIGHT", 1, -1)
  b:SetHighlightTexture(FLAT); b:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.15)
  b.Paint = function(self)
    self:SetShown(ns.DB and ns.DB.chatButton)
    local on = ns.CDB and ns.CDB.on
    self.icon:SetDesaturated(not on)
    self.icon:SetAlpha(on and 1 or 0.6)
    self.ring:SetVertexColor(on and PINK[1] or 0, on and PINK[2] or 0, on and PINK[3] or 0, 1)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then ns.ToggleWindow() else ns.SetOn(not ns.CDB.on) end
  end)
  b:SetScript("OnEnter", function(self)
    local d = ns.ACCENTS[ns.Current()]
    Tip:SetOwner(self, "ANCHOR_TOPLEFT")
    Tip:AddLine("Accents", PINK[1], PINK[2], PINK[3])
    Tip:AddLine((ns.CDB.on and Tr("On") or Tr("Off")) .. "  ·  " .. Tr(d and d.name or ""), 1, 1, 1)
    Tip:AddLine("Left-click: turn on or off", 0.8, 0.8, 0.85)
    Tip:AddLine("Right-click: pick an accent", 0.8, 0.8, 0.85)
    Tip:Show()
  end)
  b:SetScript("OnLeave", function() Tip:Hide() end)
  ns.chatButton = b
  b:Paint()

  -- while you type: the accent's name inside the chat box, when it will be used
  local label = UIParent:CreateFontString(nil, "OVERLAY")
  label:SetFont(FONT, 10, "OUTLINE")
  label:SetTextColor(PINK[1], PINK[2], PINK[3])
  label:Hide()
  local t = 0
  local watcher = CreateFrame("Frame")
  watcher:SetScript("OnUpdate", function(_, el)
    t = t + el
    if t < 0.15 then return end
    t = 0
    local eb = ChatEdit_GetActiveWindow and ChatEdit_GetActiveWindow()
    if not eb then
      for i = 1, (NUM_CHAT_WINDOWS or 10) do
        local e = _G["ChatFrame" .. i .. "EditBox"]
        if e and e:IsShown() and e:HasFocus() then eb = e; break end
      end
    end
    local show = false
    if eb and eb:IsShown() and ns.CDB and ns.CDB.on then
      local ok, ct = pcall(eb.GetAttribute, eb, "chatType")
      local where = ok and ct and ns.CHAT_TO_WHERE[ct]
      if where and ns.DB.where[where] then
        local d = ns.ACCENTS[ns.Current()]
        label:SetText(Tr(d and d.name or ""))
        label:ClearAllPoints()
        label:SetPoint("RIGHT", eb, "RIGHT", -10, 0)
        label:SetParent(eb)
        label:SetDrawLayer("OVERLAY", 7)
        show = true
      end
    end
    label:SetShown(show)
  end)
end

---------------------------------------------------------------------------
-- "Someone asked": a small prompt, you choose to answer
---------------------------------------------------------------------------
local ask
function ns.ShowAsk(who, where, fullName)
  if not ask then
    ask = CreateFrame("Frame", nil, UIParent)
    ask:SetSize(300, 54)
    ask:SetPoint("BOTTOMLEFT", _G.ChatFrame1 or UIParent, "TOPLEFT", 0, 32)
    ask:SetFrameStrata("HIGH")
    Box(ask, 0.08, 0.06, 0.08, 0.95)
    ask.text = Text(ask, 11); ask.text:SetPoint("TOPLEFT", 10, -8); ask.text:SetWidth(280); ask.text:SetJustifyH("LEFT")
    ask.yes = Button(ask, 110, 20, "Tell them", function()
      ns.TellThem(ask.where, ask.full)
      ask:Hide()
    end)
    ask.yes:SetPoint("BOTTOMLEFT", 10, 6); ask.yes:SetOn(true)
    ask.no = Button(ask, 70, 20, "No thanks", function() ask:Hide() end)
    ask.no:SetPoint("LEFT", ask.yes, "RIGHT", 6, 0)
  end
  ask.where, ask.full = where, fullName
  ask.text:SetText(string.format(Tr("%s asked about your accent. Tell them about Accents?"), who or "Someone"))
  ask:Show()
  Sound("TELL_MESSAGE")
  C_Timer.After(30, function() if ask then ask:Hide() end end)
end

---------------------------------------------------------------------------
-- Minimap button
---------------------------------------------------------------------------
local function BuildMinimap()
  if not Minimap or _G.AccentsMinimapButton then return end
  local DB = ns.DB
  local b = CreateFrame("Button", "AccentsMinimapButton", Minimap)
  b:SetSize(31, 31); b:SetFrameStrata("MEDIUM"); b:SetFrameLevel(8)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp"); b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
  b.icon = b:CreateTexture(nil, "ARTWORK"); b.icon:SetTexture(ns.ICON)
  b.icon:SetSize(20, 20); b.icon:SetPoint("CENTER", 0, 1); b.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
  local border = b:CreateTexture(nil, "OVERLAY"); border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  border:SetSize(53, 53); border:SetPoint("TOPLEFT")
  local function Spot()
    local a = math.rad(DB.minimapAngle or 200)
    local r = (Minimap:GetWidth() or 140) / 2 + 5
    b:ClearAllPoints(); b:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
  end
  b:SetScript("OnClick", function(_, button)
    if button == "RightButton" then ns.SetOn(not ns.CDB.on) else ns.ToggleWindow() end
  end)
  b:SetScript("OnEnter", function(self)
    Tip:SetOwner(self, "ANCHOR_LEFT")
    Tip:AddLine("Accents", PINK[1], PINK[2], PINK[3])
    Tip:AddLine("Left-click: open", 1, 1, 1)
    Tip:AddLine(ns.CDB.on and "Right-click: turn off" or "Right-click: turn on", 1, 1, 1)
    Tip:AddLine("Drag to move", 0.6, 0.6, 0.6)
    Tip:Show()
  end)
  b:SetScript("OnLeave", function() Tip:Hide() end)
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
  b:SetShown(not DB.miniHidden)
  ns.minimapButton = b
end
function Accents_OnCompartmentClick() ns.ToggleWindow() end

function ns.BuildUI()
  BuildToast()
  pcall(BuildChatButton)
  pcall(BuildMinimap)
end

---------------------------------------------------------------------------
-- Settings & Help (Help.lua)
---------------------------------------------------------------------------
ns.HelpConfig = {
  title = "Accents",
  tag = "Accents",
  settings = {
    { label = "Accents", choices = { { "On", true }, { "Off", false } },
      get = function() return ns.CDB.on and true or false end, set = function(v) ns.SetOn(v) end },
    { label = "Swear Words", choices = { { "Swap", "swap" }, { "Keep", "keep" } },
      get = function() return ns.DB.keepSwears and "keep" or "swap" end, set = function(v) ns.DB.keepSwears = (v == "keep") or nil end },
    { label = "Award Pop-ups", choices = { { "Show", true }, { "Hide", false } },
      get = function() return ns.DB.toasts and true or false end, set = function(v) ns.DB.toasts = v end },
    { label = "Sounds", choices = { { "On", true }, { "Off", false } },
      get = function() return ns.DB.sound and true or false end, set = function(v) ns.DB.sound = v end },
    { label = "Chat Button", choices = { { "Show", true }, { "Hide", false } },
      get = function() return ns.DB.chatButton and true or false end, set = function(v) ns.DB.chatButton = v; ns.RefreshUI() end },
    { label = "Minimap Button", choices = { { "Show", "show" }, { "Hide", "hide" } },
      get = function() return ns.DB.miniHidden and "hide" or "show" end,
      set = function(v) ns.DB.miniHidden = (v == "hide") or nil; if ns.minimapButton then ns.minimapButton:SetShown(not ns.DB.miniHidden) end end },
    { label = "Unlock Everything", choices = { { "No", false }, { "Yes", true } },
      get = function() return ns.DB.unlockAll and true or false end, set = function(v) ns.DB.unlockAll = v or nil; ns.RefreshUI() end },
  },
  notes = {
    { v = "1.4.8", "Item, armor, weapon, quest and spell links you put in chat go out untouched in every accent. Links in the game's newer color format were getting broken, so the game blanked them" },
    { v = "1.4.7", "Every accent audited the same way as Night Elf: thousands of chat lines run through each one, and every swap that changed what you meant was fixed or removed",
      "Words keep their meaning in context: \"I'm lost\" vs \"we lost the tank\", \"3 left\" vs \"he left\", \"it broke\" vs \"I'm broke\", \"nice drop\", \"it's okay\", \"look out\", \"see you\", \"need to\", \"get up\", \"come back\", \"for instance\", \"quest item\", \"attack power\", \"5 minutes\", \"crazy good\", \"good luck\"",
      "Longer swaps only where they fit: \"an easy quest\" never becomes \"a cakewalk quest\", \"good luck with the boss\" stays readable, and \"hey can you help me\" gets a comma after the greeting",
      "Bard uses thou and thee in the right places, \"we wiped 60 times\" is no longer read as a death line, and no more \"my dear\" or \"little one\" for your friend" },
    { v = "1.4.6", "Night Elf reworked after a full audit: \"friend\" no longer turns into \"sister\" or \"brother\", \"nuts\" is not \"mad\", \"no problem\" is not \"no shadow\", and no more random \"Fandu-dath-belore?\" or \"Ishnu-alah\" in front of lines that aren't greetings",
      "Every accent: \"let it go\", \"go ahead\", \"first time\", \"one day\", \"get a life\", \"bad at\", \"quick question\", \"guess what\", \"one hell of a\", \"elite quest\" and \"want to group\" read right. \"I'm going to stormwind\" stays a trip. Item words stay what you typed: gold, mana, axe, sword, trash, epic, giant",
      "\"hello?\" no longer ends in \".?\", and \"get a life lol\" ends the sentence before the laugh" },
    { v = "1.4.5", "Gnome drops its catchphrases: no more \"Fun fact:\" or \"Ooh!\" in front of your lines, and no \"by my math\" in the middle. Its gnome talk stays in the words. Noir and Human lose an odd opener too" },
    { v = "1.4.4", "Typed without the apostrophe? \"ill go\", \"hell be back\", \"id like\", \"shes here\" and \"itll work\" are read as I'll, he'll, I'd, she's and it'll. \"I'm ill\" and \"hell yeah\" stay as you meant them" },
    { v = "1.4.3", "Smarter swaps in every accent: words that mean something else in context stay put. \"pretty easy\", \"that was sick\", \"need to drink\", \"home from work\", \"got home\" and \"died so fast\" read right now",
      "Common phrases are left alone: take it easy, world boss, world buff, world chat, going to bed, play wow" },
    { v = "1.4.2", "\"wow\" the game stays \"wow\": \"people play wow\" or \"i love wow\" are left alone. Only \"wow!\" said like an exclamation turns into the accent's",
      "\"though\" at the end of a sentence stays \"though\" (it used to turn into \"but\")" },
    { v = "1.4.1", "\"Horde\" and \"Alliance\" stay as you wrote them: \"any horde players\" no longer turns into \"any the Horde players\". The same fix for every swap that brought its own \"the\"",
      "\"In the city\" no longer becomes \"in the Stormwind\", and \"my gear is\" never gets a plural swap" },
    { v = "1.4.0", "Everyday chat lines for every accent: brb, back, afk, rez, oom, grats, good job, invite and more now come out in character in Skyborne and all the unlockable accents, with a few different lines each",
      "Four new lines every accent answers: on my way (omw), welcome back (wb), good luck (gl) and asking for a summon",
      "Cleanup: no more \"my my dear\" or \"a unwanted guest\", the same word never lands twice in a row, and brb works in every accent again" },
    { v = "1.3.0", "Announcements are one short line now (\"unlocked Pirate, earned Night Owl\"), and your group hears at most one a minute. The full details still pop up on your own screen",
      "A secret unlock is announced once, not twice" },
    { v = "1.2.0", "Names stay names: a guildmate called Boss or Killer is never swapped, even when they're not in your group",
      "Grammar pass on every accent: \"afraid of\", \"leave the group\", \"at night\", \"one more time\" and \"got killed\" all read right now",
      "Little asides only land after something you wrote, never inside a built-in line",
      "Very long lines (Murloc!) split into as many messages as it takes, never inside a link, and Godd Howard keeps any link you shared",
      "Secret unlocks work in more places: any mine, quarry or dig site, any ogre camp, Ratchet, and boss kills the game reports quietly" },
    { v = "1.1.0", "Skyborne and all 24 unlockable accents got their full word banks: over 100 words each now come out in the accent, so everyday lines sound like Noir, Pirate, Cowboy and the rest, not just greetings and thanks",
      "Swaps keep the sentence making sense: \"run Deadmines\" and \"going to bed\" stay as they are, and nothing doubles up like \"so so slow\"",
      "At most one little aside per message, and never one the line already says" },
    { v = "1.0.1", "The \"tell them about Accents\" prompt only comes up when someone asks how you're talking, in the chat where you were talking. Before, any talk about addons in guild set it off" },
    { v = "1.0.0", "First release. Type normally and your message goes out in an accent, instantly, with no preview step",
      "9 race accents to start (Orc, Troll, Tauren, Forsaken, Human Noble, Dwarf, Gnome, Night Elf, Skyborne). Yours is picked from your race, and you can switch to any of them",
      "24 more to unlock as you talk, from Pirate and Murloc to Raid Boss, Bard, Noir Detective, Cowboy and Sports Announcer. Locked ones show as ??? until you find them, and every one also has a secret way to unlock it early",
      "Ranks for every accent and 62 awards, 40 of them hidden. Awards are announced to your group like Questie does, and you pick where in Settings",
      "You choose where it works: say, party, raid, instance, guild, officer, whispers, emotes and general channels",
      "Swear words get a clean swap in each accent's own style (Settings, Swear Words: Swap or Keep)",
      "Item links, names, slash commands and (( out of character )) text are never touched",
      "/orc, /pirate and the rest send one line in that accent and go back to normal. /accents opens the window" },
  },
  report = function()
    local DB, CDB = ns.DB, ns.CDB
    return { "Hook: " .. tostring(ns.hooked) .. ", on " .. tostring(CDB.on) .. ", accent " .. tostring(ns.Current()) ..
      ", messages " .. tostring(DB.total),
      "Last error: " .. tostring(ns.lastError) }
  end,
}

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------
local function FindAccent(word)
  word = (word or ""):lower():gsub("[%s'%-]", "")
  if word == "" then return nil end
  if ns.ACCENTS[word] then return word end
  for _, k in ipairs(ns.ORDER) do
    local d = ns.ACCENTS[k]
    if d.name:lower():gsub("[%s'%-]", "") == word then return k end
    for _, a in ipairs(d.aliases or {}) do if a == word then return k end end
  end
end
ns.FindAccent = FindAccent

SLASH_ACCENTS1, SLASH_ACCENTS2 = "/accents", "/accent"
SlashCmdList.ACCENTS = function(msg)
  local cmd, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  cmd = (cmd or ""):lower()
  if cmd == "" then ns.ToggleWindow()
  elseif cmd == "on" then ns.SetOn(true); ns.Say("on.")
  elseif cmd == "off" then ns.SetOn(false); ns.Say("off.")
  elseif cmd == "toggle" then ns.SetOn(not ns.CDB.on)
  elseif cmd == "awards" then ns.OpenWindow("awards")
  elseif cmd == "where" then ns.OpenWindow("where")
  elseif cmd == "help" or cmd == "settings" then if ns.OpenHelp then ns.OpenHelp() end
  elseif cmd == "test" then
    local key = FindAccent(rest) or ns.Current()
    local line = "Hey guys, thanks for the group! I need to sell my stuff, be right back. Ready to go?"
    ns.Say(ns.ACCENTS[key].name .. ":")
    local out = ns.print or print
    out("  " .. ns.Turn(key, line, 3))
  elseif cmd == "debug" then
    ns.Hook()
    ns.Say("hooks " .. ns.HookNames() .. ", seen " .. ns.dbg.calls .. "/" .. ns.dbg.sends .. " (" .. ns.dbg.lastSend .. "), on " .. tostring(ns.CDB.on) .. ", accent " .. tostring(ns.Current()) ..
      ", messages " .. ns.DB.total .. ", last error " .. tostring(ns.lastError))
  else
    local key = FindAccent(cmd)
    if key then
      if rest ~= "" then ns.OneShot(key, rest)
      elseif ns.SetAccent(key) then ns.SetOn(true); ns.Say(string.format(Tr("talking as %s."), Tr(ns.ACCENTS[key].name))) end
    else
      ns.Say("commands:")
      local p = ns.print or print
      p("  /accents   " .. Tr("open the window"))
      p("  /accents on | off   " .. Tr("turn it on or off"))
      p("  /accents <accent>   " .. Tr("talk as that accent (like /accents dwarf)"))
      p("  /ac <accent> <message>   " .. Tr("one line in an accent, then back to normal"))
      p("  /accents test <accent>   " .. Tr("see a sample line"))
      p("  /accents help   " .. Tr("settings and how to report a bug"))
    end
  end
end

-- /ac pirate where be the loot: one line in any accent
SLASH_ACCENTSONE1 = "/ac"
SlashCmdList.ACCENTSONE = function(msg)
  local word, rest = (msg or ""):match("^%s*(%S*)%s*(.-)%s*$")
  local key = FindAccent(word)
  if not key then ns.Say("type /ac <accent> <message>, like /ac orc we go now"); return end
  ns.OneShot(key, rest)
end

-- one command per accent: /orc, /dwarf ... (only where no other addon or the game already uses the name)
function ns.RegisterOneShots()
  local open = {}
  for _, k in ipairs(ns.ORDER) do if not ns.ACCENTS[k].secret then open[#open + 1] = k end end
  for _, k in ipairs(open) do
    local d = ns.ACCENTS[k]
    local cmd = d.slash or k
    local id = "ACCENTS_" .. k:upper()
    local taken = false
    if hash_SlashCmdList and hash_SlashCmdList["/" .. cmd:upper()] then taken = true end
    for name, _ in pairs(SlashCmdList) do
      if name ~= id then
        local i = 1
        while _G["SLASH_" .. name .. i] do
          if _G["SLASH_" .. name .. i]:lower() == "/" .. cmd then taken = true end
          i = i + 1
        end
      end
    end
    if not taken then
      _G["SLASH_" .. id .. "1"] = "/" .. cmd
      SlashCmdList[id] = function(m) ns.OneShot(k, m) end
      d.slash = cmd
    end
  end
end
