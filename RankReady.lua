local _, addon = ...
local frame = CreateFrame("Frame")
local settings, knownIDs
local loggedIn, scheduled = false, false
local review = {}

local function Say(message)
    print("|cffffd100RankReady:|r " .. message)
end

local function Limits()
    local constants = Constants and Constants.MacroConsts or {}
    return constants.MAX_ACCOUNT_MACROS or MAX_ACCOUNT_MACROS or 120,
        constants.MAX_CHARACTER_MACROS or MAX_CHARACTER_MACROS or 18
end

local function Body(name)
    return "#showtooltip " .. name .. "\n/cast " .. name .. "\n# RankReady"
end

local function Spells()
    local spells, counts = {}, {}
    local modern = C_SpellBook and C_SpellBook.GetNumSpellBookSkillLines
        and C_SpellBook.GetSpellBookSkillLineInfo and C_SpellBook.GetSpellBookItemInfo
        and C_SpellBook.GetSpellBookItemName and Enum.SpellBookSpellBank
    local bank = modern and Enum.SpellBookSpellBank.Player or (BOOKTYPE_SPELL or "spell")
    local lineCount = modern and C_SpellBook.GetNumSpellBookSkillLines() or GetNumSpellTabs()
    for lineIndex = 1, lineCount do
        local line
        if modern then
            line = C_SpellBook.GetSpellBookSkillLineInfo(lineIndex)
        else
            local _, _, offset, count, _, offSpecID = GetSpellTabInfo(lineIndex)
            if offset and count then
                line = {itemIndexOffset = offset, numSpellBookItems = count, offSpecID = offSpecID}
            end
        end
        -- General contains racial abilities and professions, rather than class spells.
        if line and lineIndex > 1 and not line.shouldHide
            and (not line.offSpecID or line.offSpecID == 0) then
            for slot = line.itemIndexOffset + 1, line.itemIndexOffset + line.numSpellBookItems do
                local info
                if modern then
                    info = C_SpellBook.GetSpellBookItemInfo(slot, bank)
                else
                    local kind, id = GetSpellBookItemInfo(slot, bank)
                    if kind == "SPELL" then
                        local name, subName = GetSpellBookItemName(slot, bank)
                        info = {name = name, subName = subName, spellID = id,
                            isPassive = IsPassiveSpell(slot, bank)}
                    end
                end
                if info and (not modern or info.itemType == Enum.SpellBookItemType.Spell)
                    and not info.isPassive and not info.isOffSpec
                    and type(info.name) == "string" and info.name ~= "" then
                    local name = info.name
                    local subName = info.subName
                    if not subName or subName == "" then
                        local _, sub
                        if modern then _, sub = C_SpellBook.GetSpellBookItemName(slot, bank)
                        else _, sub = GetSpellBookItemName(slot, bank) end
                        subName = sub
                    end
                    local entry = spells[name]
                    if not entry then entry = {}; spells[name] = entry end
                    -- Icon fields differ between client versions. Prefer the
                    -- spellbook texture API when item info omits its icon.
                    local icon = info.iconID
                    if icon == 0 or icon == "" then icon = nil end
                    if not icon and modern and C_SpellBook.GetSpellBookItemTexture then
                        icon = C_SpellBook.GetSpellBookItemTexture(slot, bank)
                    end
                    if not icon and not modern and GetSpellBookItemTexture then
                        icon = GetSpellBookItemTexture(slot, bank)
                    end
                    if icon == 0 or icon == "" then icon = nil end
                    local spellID = info.spellID or info.actionID
                    if not icon and spellID and C_Spell and C_Spell.GetSpellTexture then
                        icon = C_Spell.GetSpellTexture(spellID)
                    end
                    entry.icon = icon or entry.icon
                    local rank = type(subName) == "string" and tonumber(subName:match("%d+"))
                    if rank and rank >= (entry.highestRank or 0) then
                        entry.highestRank = rank
                        entry.highestSpellID = info.spellID or info.actionID
                    end
                    -- Rank subtext is localized; numeric ranks work without English matching.
                    entry.ranked = entry.ranked or (subName and subName:match("%d+") ~= nil)
                    local id = info.spellID or info.actionID
                    if id and not entry[id] then
                        entry[id] = true
                        counts[name] = (counts[name] or 0) + 1
                    end
                end
            end
        end
    end
    local names, icons = {}, {}
    for name, entry in pairs(spells) do
        if entry.ranked or (counts[name] or 0) > 1 then
            names[#names + 1] = name
            icons[name] = entry.icon
        end
    end
    table.sort(names)
    return names, icons, spells
end

function addon.GetKnownRanks()
    local _, _, spells = Spells()
    return spells
end


-- Accept a simple rank-free spell macro regardless of label, CRLF, spacing,
-- tooltip spelling, or our ownership comment. Never reuse downrank/conditional
-- or multi-command macros: those may intentionally behave differently.
local function MacroSpell(body)
    if type(body) ~= "string" then return end
    local spell
    for line in body:gmatch("[^\r\n]+") do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and line:sub(1, 1) ~= "#" then
            local command, argument = line:match("^(/%S+)%s+(.+)$")
            if not command or command:lower() ~= "/cast" or spell then return end
            spell = argument:match("^%s*(.-)%s*$"):gsub("%(%s*%)$", "")
            if spell:find("[", 1, true) or spell:find("(", 1, true) then return end
        end
    end
    return spell
end

function addon.GetSimpleMacroSpell(index)
    return MacroSpell(select(3, GetMacroInfo(index)))
end

local function Inventory()
    local accountMax = Limits()
    local accountCount, characterCount = GetNumMacros()
    local macros = {}
    local function Remember(index, location)
        local _, _, body = GetMacroInfo(index)
        local spell = MacroSpell(body)
        if not spell then return end
        local entry = macros[spell]
        if entry then entry.count = entry.count + 1
        else macros[spell] = {index = index, location = location, count = 1} end
    end
    -- Prefer character macros for dragging when both scopes contain one.
    for index = accountMax + 1, accountMax + characterCount do Remember(index, "Character") end
    for index = 1, accountCount do Remember(index, "Account") end
    return macros, accountCount, characterCount
end

local function Refresh()
    if addon.RefreshWindow then addon.RefreshWindow() end
end

local function ShowReview()
    if not settings or InCombatLockdown() or not next(review) then return end
    local names = {}
    for spell in pairs(review) do names[#names + 1] = spell end
    table.sort(names)
    local text = #names == 1 and ("Learned a new spell or rank: " .. names[1] .. ".")
        or ("Learned " .. #names .. " new spells or ranks.")
    text = text .. "\n\nExisting rank-free macros already use your highest rank. Review your macros?"
    local popup = StaticPopup_FindVisible("RANKREADY_REVIEW")
    if popup then popup:GetTextFontString():SetText(text)
    else StaticPopup_Show("RANKREADY_REVIEW", text) end
end

StaticPopupDialogs.RANKREADY_REVIEW = {
    text = "%s", button1 = "Review", button2 = "Later",
    OnAccept = function()
        review = {}
        if addon.OpenWindow then addon.OpenWindow() end
    end,
    OnCancel = function() review = {} end,
    timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

local function Scan()
    local names, _, spells = Spells()
    local baseline = knownIDs == nil
    knownIDs = knownIDs or {}
    for _, name in ipairs(names) do
        local changed = false
        for id, value in pairs(spells[name]) do
            if type(id) == "number" and value == true and not knownIDs[id] then
                knownIDs[id] = true
                changed = true
            end
        end
        if changed and not baseline and not settings.excluded[name] then review[name] = true end
    end
    ShowReview()
    Refresh()
end

local function Schedule()
    if not loggedIn or scheduled then return end
    scheduled = true
    C_Timer.After(0.5, function()
        scheduled = false
        Scan()
    end)
end

-- Only explicit button/slash actions reach CreateMacro. No queued creation,
-- including after combat, login, spell changes, or deleting a macro.
function addon.CreateMacros(onlySpell)
    if not settings then return end
    if InCombatLockdown() then Say("Leave combat, then click Create again."); return end
    local names, icons = Spells()
    local created, existing, missing = 0, 0, 0
    for _, spell in ipairs(names) do
        if (not onlySpell or spell == onlySpell) and not settings.excluded[spell] then
            -- Re-read before each creation, so a previous insert cannot stale indices.
            local macros, accountCount, characterCount = Inventory()
            local accountMax, characterMax = Limits()
            if macros[spell] then existing = existing + 1
            elseif characterCount < characterMax or (settings.accountFallback and accountCount < accountMax) then
                local ok, index = pcall(CreateMacro, " ", icons[spell] or 134400,
                    Body(spell), characterCount < characterMax)
                if ok and index and index > 0 then created = created + 1
                else missing = missing + 1 end
            else missing = missing + 1 end
        end
    end
    Say(string.format("%d created, %d already available, %d could not be created.", created, existing, missing))
    Refresh()
end

function addon.GetWindowData()
    if not settings then return end
    local names, icons = Spells()
    local macros, accountCount, characterCount = Inventory()
    local accountMax, characterMax = Limits()
    local rows = {}
    local hasSpace = characterCount < characterMax or (settings.accountFallback and accountCount < accountMax)
    for _, spell in ipairs(names) do
        local entry = macros[spell]
        local enabled = not settings.excluded[spell]
        local status = entry and (entry.location .. " macro") or not enabled and "Excluded"
            or not hasSpace and "No available macro slots" or "Click Create"
        if entry and entry.count > 1 then status = entry.count .. " existing copies (reused)" end
        if entry and not enabled then status = status .. " / excluded" end
        rows[#rows + 1] = {spell = spell, icon = icons[spell], enabled = enabled,
            ready = entry ~= nil, status = status}
    end
    return rows, settings, string.format("Free slots: Character %d/%d  Account %d/%d",
        characterMax - characterCount, characterMax, accountMax - accountCount, accountMax)
end

function addon.SetPreference(key, value)
    if not settings then return end
    if key == "accountFallback" or key == "showManaCosts" or key == "showRageCosts" or key == "showEnergyCosts"
        or key == "showLowerRanks" then
        settings[key] = value == true
        if key == "showLowerRanks" and addon.ConfigureRankLabels then
            addon.ConfigureRankLabels(settings.showLowerRanks)
        elseif key ~= "accountFallback" and addon.ConfigureManaCosts then
            addon.ConfigureManaCosts(settings.showManaCosts, settings.showRageCosts, settings.showEnergyCosts)
        end
        Refresh()
    end
end

function addon.GetCostSettings()
    return settings
end

function addon.SetCostMode(mode)
    if not settings or InCombatLockdown() then return end
    if mode ~= "all" and mode ~= "selected" and mode ~= "off" then return end
    settings.costMode = mode
    addon.ConfigureManaCosts(settings.showManaCosts, settings.showRageCosts, settings.showEnergyCosts)
    if addon.QueueCostSelection then addon.QueueCostSelection() end
    Refresh()
end

function addon.SetSpellEnabled(spell, enabled)
    if not settings then return end
    settings.excluded[spell] = not enabled or nil
    Refresh()
end

function addon.PickupSpell(spell)
    if InCombatLockdown() then Say("Wait until combat ends to place a macro."); return end
    local entry = Inventory()[spell]
    if entry then PickupMacro(entry.index)
    else Say("Click Create beside " .. spell .. " first.") end
end

function addon.SyncNow() addon.CreateMacros() end

frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        -- Preserve preferences when upgrading in the original addon folder.
        if type(RankReadyDB) ~= "table" then
            RankReadyDB = type(MacroMateDB) == "table" and MacroMateDB or {}
        end
        MacroMateDB = nil
        settings = RankReadyDB
        settings.automatic = nil -- Retire the old automatic-creation preference.
        if type(settings.excluded) ~= "table" then settings.excluded = {} end
        if type(settings.accountFallback) ~= "boolean" then settings.accountFallback = true end
        if type(settings.showManaCosts) ~= "boolean" then settings.showManaCosts = true end
        if type(settings.showRageCosts) ~= "boolean" then settings.showRageCosts = true end
        if type(settings.showEnergyCosts) ~= "boolean" then settings.showEnergyCosts = true end
        if type(settings.showLowerRanks) ~= "boolean" then settings.showLowerRanks = false end
        if settings.costMode ~= "selected" and settings.costMode ~= "off" then settings.costMode = "all" end
        if type(settings.costSpells) ~= "table" then settings.costSpells = {} end
        loggedIn = true
        if addon.ConfigureRankLabels then addon.ConfigureRankLabels(settings.showLowerRanks) end
        if addon.ConfigureManaCosts then
            addon.ConfigureManaCosts(settings.showManaCosts, settings.showRageCosts, settings.showEnergyCosts)
        end
        Schedule()
    elseif event == "PLAYER_REGEN_ENABLED" then
        ShowReview()
        Refresh()
    elseif event == "PLAYER_REGEN_DISABLED" or event == "UPDATE_MACROS" then
        Refresh()
    else Schedule() end
end)
for _, event in ipairs({"PLAYER_LOGIN", "SPELLS_CHANGED", "LEARNED_SPELL_IN_SKILL_LINE",
    "SPELL_TEXT_UPDATE", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED", "UPDATE_MACROS"}) do
    frame:RegisterEvent(event)
end

SLASH_RANKREADY1 = "/rankready"
SLASH_RANKREADY2 = "/rr"
SlashCmdList.RANKREADY = function(message)
    local command = message:lower():match("^%s*(.-)%s*$")
    if not loggedIn then return end
    if command == "" then addon.ToggleWindow()
    elseif command == "sync" or command == "create" then addon.CreateMacros()
    elseif command == "costs" then addon.ToggleCostSelection()
    elseif command == "status" then
        local rows, _, slots = addon.GetWindowData()
        local ready = 0
        for _, row in ipairs(rows) do if row.ready then ready = ready + 1 end end
        Say(string.format("%d/%d spells have macros. %s", ready, #rows, slots))
    else Say("/rr: companion; /rr create: create missing included macros; /rr status: report only; /rr costs: choose cost labels.") end
end
