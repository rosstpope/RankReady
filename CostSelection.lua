local _, addon = ...
local watcher = CreateFrame("Frame")
local editing, scheduled = false, false
local banner
local overlays = {}
local Refresh, ConfigureWatching

local function Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

local function Eligible(spellID)
    local name = addon.GetCostSpellName(spellID)
    if not name then return end
    local costs = C_Spell.GetSpellPowerCost(spellID)
    if not Readable(costs) or type(costs) ~= "table" then return end
    for _, cost in ipairs(costs) do
        if Readable(cost.type) and Readable(cost.cost) and type(cost.cost) == "number"
            and cost.cost >= 0 and (cost.type == Enum.PowerType.Mana
                or cost.type == Enum.PowerType.Rage or cost.type == Enum.PowerType.Energy) then
            return name
        end
    end
end

local function HideOverlays()
    for _, overlay in pairs(overlays) do overlay:Hide(); overlay.spell = nil end
    GameTooltip:Hide()
end

function addon.QueueCostSelection()
    if not editing or scheduled then return end
    scheduled = true
    C_Timer.After(0, function()
        scheduled = false
        if editing then Refresh() end
    end)
end

local function SnapshotVisible()
    local selected, cache = {}, {macros = {}}
    for _, button in ipairs(addon.GetActionButtons()) do
        if button:IsVisible() then
            local name = Eligible(addon.ResolveCostSpell(button, cache))
            if name then selected[name] = true end
        end
    end
    return selected
end

local function Overlay(button)
    local overlay = overlays[button]
    if overlay then return overlay end
    -- Independent UIParent frames: never replace protected button scripts or
    -- parent interactive controls to secure action buttons. Only position out of combat.
    overlay = CreateFrame("CheckButton", nil, UIParent)
    overlay:SetFrameStrata("DIALOG")
    overlay:SetFrameLevel(100)
    overlay:RegisterForClicks("LeftButtonUp")
    overlay:EnableMouse(true)
    overlay.fill = overlay:CreateTexture(nil, "BACKGROUND")
    overlay.fill:SetAllPoints(overlay)
    local box = overlay:CreateTexture(nil, "OVERLAY")
    box:SetTexture("Interface/Buttons/UI-CheckBox-Up")
    box:SetSize(22, 22)
    box:SetPoint("TOPRIGHT", 2, 2)
    local checked = overlay:CreateTexture(nil, "OVERLAY", nil, 1)
    checked:SetTexture("Interface/Buttons/UI-CheckBox-Check")
    checked:SetAllPoints(box)
    overlay:SetCheckedTexture(checked)
    overlay:SetScript("OnClick", function(self)
        if not editing or InCombatLockdown() then return end
        -- Resolve again at click time: paging and conditional macros may have changed.
        local name = button:IsVisible() and Eligible(addon.ResolveCostSpell(button, {macros = {}}))
        if not name then addon.QueueCostSelection(); return end
        local settings = addon.GetCostSettings()
        local wasSelected = settings.costMode == "all" or
            (settings.costMode == "selected" and settings.costSpells[name] == true)
        if settings.costMode == "all" then settings.costSpells = SnapshotVisible() end
        settings.costSpells[name] = not wasSelected or nil
        addon.SetCostMode("selected")
        Refresh()
    end)
    overlay:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText(self.spell or "Spell cost")
        GameTooltip:AddLine("Click to show or hide cost labels for all ranks and bar positions.", 1, 1, 1, true)
        GameTooltip:AddLine("Mana, Rage and Energy filters still apply. No spells are cast in selection mode.", 0.8, 0.8, 0.8, true)
        GameTooltip:Show()
    end)
    overlay:SetScript("OnLeave", function() GameTooltip:Hide() end)
    overlays[button] = overlay
    return overlay
end

Refresh = function()
    if not editing or InCombatLockdown() then return end
    HideOverlays()
    local settings, cache = addon.GetCostSettings(), {macros = {}}
    for _, button in ipairs(addon.GetActionButtons()) do
        if button:IsVisible() then
            local name = Eligible(addon.ResolveCostSpell(button, cache))
            if name then
                local left, bottom, width, height = button:GetRect()
                if left and bottom and width and height then
                    local scale = button:GetEffectiveScale() / UIParent:GetEffectiveScale()
                    local overlay = Overlay(button)
                    overlay:ClearAllPoints()
                    overlay:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", left * scale, bottom * scale)
                    overlay:SetSize(width * scale, height * scale)
                    overlay.spell = name
                    local checked = settings.costMode == "all" or
                        (settings.costMode == "selected" and settings.costSpells[name] == true)
                    overlay:SetChecked(checked)
                    if checked then overlay.fill:SetColorTexture(0.1, 0.8, 0.2, 0.16)
                    else overlay.fill:SetColorTexture(0, 0, 0, 0.4) end
                    overlay:Show()
                end
            end
        end
    end
    local modes = {all = "All spells", selected = "Selected spells", off = "Off"}
    banner.state:SetText("Costs: " .. modes[settings.costMode] .. " - changes save immediately")
end

local function Stop()
    editing = false
    HideOverlays()
    ConfigureWatching()
end

local function BuildBanner()
    banner = CreateFrame("Frame", "RankReadyCostSelection", UIParent, "BackdropTemplate")
    banner:Hide()
    banner:SetSize(470, 108)
    banner:SetPoint("TOP", UIParent, "TOP", 0, -70)
    banner:SetFrameStrata("FULLSCREEN_DIALOG")
    banner:SetClampedToScreen(true)
    banner:EnableMouse(true)
    banner:SetMovable(true)
    banner:RegisterForDrag("LeftButton")
    banner:SetScript("OnDragStart", banner.StartMoving)
    banner:SetScript("OnDragStop", banner.StopMovingOrSizing)
    banner:SetBackdrop({bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border", edgeSize = 14,
        insets = {left = 3, right = 3, top = 3, bottom = 3}})
    banner:SetBackdropColor(0.04, 0.04, 0.05, 0.96)
    local title = banner:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOP", 0, -14)
    title:SetText("RankReady: click spells to show or hide costs")
    banner.state = banner:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    banner.state:SetPoint("TOP", 0, -35)
    local function Button(text, x, callback)
        local button = CreateFrame("Button", nil, banner, "UIPanelButtonTemplate")
        button:SetSize(100, 24)
        button:SetPoint("BOTTOMLEFT", x, 14)
        button:SetText(text)
        button:SetScript("OnClick", callback)
    end
    Button("All", 70, function() addon.SetCostMode("all"); Refresh() end)
    Button("None", 185, function()
        if InCombatLockdown() then return end
        addon.GetCostSettings().costSpells = {}
        addon.SetCostMode("selected")
        Refresh()
    end)
    Button("Done", 300, function() banner:Hide() end)
    banner:SetScript("OnHide", Stop)
    UISpecialFrames[#UISpecialFrames + 1] = "RankReadyCostSelection"
end

function addon.ToggleCostSelection()
    if editing then banner:Hide(); return end
    if InCombatLockdown() or not addon.GetCostSettings() then
        print("|cffffd100RankReady:|r Leave combat to choose cost labels.")
        return
    end
    if not banner then BuildBanner() end
    editing = true
    banner:Show()
    ConfigureWatching()
    Refresh()
end

watcher:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_ENTERING_WORLD" then
        if editing then banner:Hide() end
    else addon.QueueCostSelection() end
end)
ConfigureWatching = function()
    watcher:UnregisterAllEvents()
    if not editing then return end
    for _, event in ipairs({"PLAYER_REGEN_DISABLED", "PLAYER_ENTERING_WORLD", "ACTIONBAR_SLOT_CHANGED",
        "ACTIONBAR_PAGE_CHANGED", "UPDATE_BONUS_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM", "UPDATE_MACROS",
        "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED", "SPELLS_CHANGED", "SPELL_TEXT_UPDATE",
        "UPDATE_OVERRIDE_ACTIONBAR", "UPDATE_VEHICLE_ACTIONBAR",
        "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED"}) do
        watcher:RegisterEvent(event)
    end
end
if EventRegistry then
    EventRegistry:RegisterCallback("ActionButton.OnActionChanged", addon.QueueCostSelection, watcher)
end
