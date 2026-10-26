local _, addon = ...
local window, attached
local page, pageSize = 1, 6

local function Label(parent, font, x, y, text)
    local label = parent:CreateFontString(nil, "OVERLAY", font)
    label:SetPoint("TOPLEFT", x, y)
    label:SetText(text)
    return label
end

local function Button(parent, text, width, x, y, callback)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 23)
    button:SetPoint("TOPLEFT", x, y)
    button:SetText(text)
    button:SetScript("OnClick", callback)
    return button
end

local function Check(parent, text, x, y, callback)
    local check = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    check:SetSize(24, 24)
    check:SetPoint("TOPLEFT", x, y)
    if text ~= "" then Label(check, "GameFontHighlightSmall", 27, -7, text) end
    check:SetScript("OnClick", function(self) callback(self:GetChecked() == true) end)
    return check
end

local function Book()
    if PlayerSpellsFrame and PlayerSpellsFrame.SpellBookFrame then
        return PlayerSpellsFrame.SpellBookFrame, PlayerSpellsFrame
    end
    return SpellBookFrame, SpellBookFrame
end

local function Dock()
    if not window then return end
    local book, root = Book()
    if not book or not book:IsVisible() then return end
    attached = true
    window:ClearAllPoints()
    window:SetScale(root:GetEffectiveScale() / UIParent:GetEffectiveScale())
    local right = root:GetRight()
    local room = right and UIParent:GetWidth() * UIParent:GetEffectiveScale()
        - right * root:GetEffectiveScale() or 0
    if room >= (window:GetWidth() + 8) * window:GetEffectiveScale() then
        window:SetPoint("TOPLEFT", root, "TOPRIGHT", 8, -22)
    else
        local left = root:GetLeft()
        if left and left * root:GetEffectiveScale() >= (window:GetWidth() + 8) * window:GetEffectiveScale() then
            window:SetPoint("TOPRIGHT", root, "TOPLEFT", -8, -22)
        else
            -- Clamp to the screen when a maximized book leaves no free side.
            window:SetPoint("TOPLEFT", root, "TOPRIGHT", 8, -22)
        end
    end
end

function addon.RefreshWindow()
    if not window or not window:IsShown() then return end
    local rows, settings, slots = addon.GetWindowData()
    if not rows then return end
    local pages = math.max(1, math.ceil(#rows / pageSize))
    page = math.min(page, pages)
    window.fallback:SetChecked(settings.accountFallback)
    window.mana:SetChecked(settings.showManaCosts)
    window.rage:SetChecked(settings.showRageCosts)
    window.energy:SetChecked(settings.showEnergyCosts)
    window.lowerRanks:SetChecked(settings.showLowerRanks)
    local modes = {all = "All spells", selected = "Selected spells", off = "Off"}
    window.costMode:SetText("Costs: " .. modes[settings.costMode])
    window.costMode:SetEnabled(not InCombatLockdown())
    window.chooseCosts:SetEnabled(not InCombatLockdown())
    window.slots:SetText(slots)
    window.state:SetText(InCombatLockdown() and "Leave combat to create or drag macros."
        or "Create only when you choose. Drag ready icons onto your bars.")
    window.pagination:SetText(string.format("%d/%d", page, pages))
    window.previous:SetEnabled(page > 1)
    window.next:SetEnabled(page < pages)
    window.create:SetEnabled(not InCombatLockdown())
    window.empty:SetShown(#rows == 0)
    for position, row in ipairs(window.rows) do
        local data = rows[(page - 1) * pageSize + position]
        row:SetShown(data ~= nil)
        if data then
            row.spell = data.spell
            row.check:SetChecked(data.enabled)
            row.icon.texture:SetTexture(data.icon or 134400)
            row.icon:SetAlpha(data.ready and 1 or 0.45)
            row.name:SetText(data.spell)
            row.status:SetText(data.status)
            row.create:SetText(data.ready and "Ready" or "Create")
            row.create:SetEnabled(not data.ready and data.enabled and not InCombatLockdown())
        else row.spell = nil end
    end
end

local function BuildWindow()
    local panel = CreateFrame("Frame", "RankReadyWindow", UIParent, "BackdropTemplate")
    panel:Hide()
    panel:SetSize(330, 568)
    panel:SetPoint("CENTER")
    panel:SetFrameStrata("DIALOG")
    panel:SetClampedToScreen(true)
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", function(self) if not attached then self:StartMoving() end end)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)
    panel:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}})
    panel:SetBackdropColor(0.045, 0.045, 0.055, 0.98)
    Label(panel, "GameFontNormalLarge", 16, -15, "RankReady")
    Label(panel, "GameFontDisableSmall", 16, -36, "Highest-rank macros. Manual creation.")
    local close = CreateFrame("Button", nil, panel, "UIPanelCloseButton")
    close:SetPoint("TOPRIGHT", -2, -2)
    panel.fallback = Check(panel, "Use account slots when needed", 12, -56,
        function(value) addon.SetPreference("accountFallback", value) end)
    panel.slots = Label(panel, "GameFontHighlightSmall", 16, -87, "")
    panel.state = Label(panel, "GameFontDisableSmall", 16, -108, "")
    panel.state:SetWidth(298)
    panel.state:SetJustifyH("LEFT")
    panel.rows = {}
    for index = 1, pageSize do
        local row = CreateFrame("Frame", nil, panel)
        row:SetSize(300, 38)
        row:SetPoint("TOPLEFT", 14, -150 - (index - 1) * 42)
        row.check = Check(row, "", -3, -5, function(value)
            if row.spell then addon.SetSpellEnabled(row.spell, value) end
        end)
        row.check:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Include in Create included")
            GameTooltip:AddLine("Excluding a spell preserves any existing macro.", 1, 1, 1, true)
            GameTooltip:Show()
        end)
        row.check:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.icon = CreateFrame("Button", nil, row)
        row.icon:SetSize(28, 28)
        row.icon:SetPoint("TOPLEFT", 24, -3)
        row.icon.texture = row.icon:CreateTexture(nil, "ARTWORK")
        row.icon.texture:SetAllPoints(row.icon)
        row.icon:RegisterForDrag("LeftButton")
        row.icon:SetScript("OnDragStart", function()
            if row.spell then addon.PickupSpell(row.spell) end
        end)
        row.icon:SetScript("OnClick", function()
            if row.spell then addon.PickupSpell(row.spell) end
        end)
        row.icon:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(row.spell or "Spell")
            GameTooltip:AddLine(row.status:GetText() or "", 1, 1, 1)
            GameTooltip:AddLine("Drag a ready icon to your bar.\nCreate never replaces existing macros.", 0.75, 0.75, 0.75, true)
            GameTooltip:Show()
        end)
        row.icon:SetScript("OnLeave", function() GameTooltip:Hide() end)
        row.name = Label(row, "GameFontHighlightSmall", 59, -3, "")
        row.name:SetWidth(179)
        row.name:SetJustifyH("LEFT")
        row.status = Label(row, "GameFontDisableSmall", 59, -21, "")
        row.status:SetWidth(235)
        row.status:SetJustifyH("LEFT")
        row.create = Button(row, "Create", 56, 243, 0, function()
            if row.spell then addon.CreateMacros(row.spell) end
        end)
        panel.rows[index] = row
    end
    panel.empty = Label(panel, "GameFontHighlightSmall", 20, -170, "No learned ranked class spells found yet.")
    panel.previous = Button(panel, "<", 28, 16, -412, function()
        page = math.max(1, page - 1); addon.RefreshWindow()
    end)
    panel.next = Button(panel, ">", 28, 50, -412, function()
        page = page + 1; addon.RefreshWindow()
    end)
    panel.pagination = Label(panel, "GameFontHighlightSmall", 88, -419, "")
    panel.create = Button(panel, "Create included", 125, 189, -412, addon.SyncNow)
    panel.mana = Check(panel, "Mana", 12, -448,
        function(value) addon.SetPreference("showManaCosts", value) end)
    panel.rage = Check(panel, "Rage", 110, -448,
        function(value) addon.SetPreference("showRageCosts", value) end)
    panel.energy = Check(panel, "Energy", 208, -448,
        function(value) addon.SetPreference("showEnergyCosts", value) end)
    panel.lowerRanks = Check(panel, "Always show lower ranks (text only)", 12, -474,
        function(value) addon.SetPreference("showLowerRanks", value) end)
    panel.costMode = Button(panel, "Costs: All spells", 145, 16, -506, function()
        local settings = addon.GetCostSettings()
        local nextMode = {all = "selected", selected = "off", off = "all"}
        addon.SetCostMode(nextMode[settings.costMode])
    end)
    panel.chooseCosts = Button(panel, "Choose cost labels", 145, 169, -506, addon.ToggleCostSelection)
    Label(panel, "GameFontDisableSmall", 16, -540, "Choose labels directly on your action bars.")
    panel:SetScript("OnShow", addon.RefreshWindow)
    panel:SetScript("OnHide", function() GameTooltip:Hide() end)
    UISpecialFrames[#UISpecialFrames + 1] = "RankReadyWindow"
    window = panel
end

function addon.OpenWindow()
    if not window then BuildWindow() end
    local book = Book()
    if book and book:IsVisible() then Dock()
    elseif attached then
        attached = false
        window:ClearAllPoints()
        window:SetScale(1)
        window:SetPoint("CENTER")
    end
    window:Show()
    addon.RefreshWindow()
end

function addon.ToggleWindow()
    if window and window:IsShown() then window:Hide()
    else addon.OpenWindow() end
end

-- Spellbook is load-on-demand. Hook its own visibility, including tab switches,
-- without changing its parent, protected scripts, or Blizzard layout.
local watcher = CreateFrame("Frame")
local function HookBook()
    local book, root = Book()
    if not book then return end
    book:HookScript("OnShow", function()
        if addon.SetBookOpen then addon.SetBookOpen(true) end
        addon.OpenWindow()
    end)
    book:HookScript("OnHide", function()
        if addon.SetBookOpen then addon.SetBookOpen(false) end
        if window and attached then window:Hide() end
    end)
    root:HookScript("OnSizeChanged", function()
        if window and window:IsShown() then Dock() end
    end)
    watcher:UnregisterAllEvents()
    if book:IsVisible() then
        if addon.SetBookOpen then addon.SetBookOpen(true) end
        addon.OpenWindow()
    end
end
watcher:SetScript("OnEvent", HookBook)
watcher:RegisterEvent("ADDON_LOADED")
watcher:RegisterEvent("PLAYER_LOGIN")
