-- Dalorrian's Accents: the secret one. Not in the unlock order, not listed until found.
-- Found by sending "it just works" (any accent, any channel) while Accents is on.
local ADDON, ns = ...

-- his five real lines. Whatever you type, out comes the next one, in this order, round and round.
local LINES = {
  "It just works.",
  "Sixteen times the detail.",
  "See that mountain? You can climb it.",
  "Four times the size.",
  "Over a thousand planets.",
}

ns.AddAccent("godd", {
  name = "Godd Howard", group = "secret", secret = true,
  icon = "Interface\\Icons\\Trade_Engineering",
  blurb = "Whatever you say, it just works.",
  ranks = { "Intern", "Tester", "Designer", "Lead Designer", "Director", "Producer", "Visionary", "It Just Works" },
  whole = function(text, strength)
    -- where the cycle is, kept between sessions when the saved data is there
    local store = ns.DB or ns
    local i = ((store.goddLine or 0) % #LINES) + 1
    store.goddLine = i
    -- (1.2.0) links you meant to share (items, quests, web links) still go out after the line
    local keep = {}
    for l in text:gmatch("|c%x+|H.-|h.-|h|r") do keep[#keep + 1] = l end
    for u in text:gmatch("https?://%S+") do keep[#keep + 1] = u end
    if #keep > 0 then return LINES[i] .. " " .. table.concat(keep, " ") end
    return LINES[i]
  end,
})
