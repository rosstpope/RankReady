local _, addon = ...
local watcher = CreateFrame("Frame")
local active, scheduled = false, false
local bookOpen, alwaysRanks = false, false
local overlays, hooked = {}, {}
local Refresh

local function Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

local function Queue()
    if not active or scheduled then return end
    scheduled = true
    C_Timer.After(0, function()
        scheduled = false
        if active then Refresh() end
    end)
end

local function Overlay(button)
    local overlay = overlays[button]
    if overlay then return overlay end
    overlay = {edges = {}}
    local points = {"TOP", "BOTTOM", "LEFT", "RIGHT"}
    for index, point in ipairs(points) do
        local edge = button:CreateTexture(nil, "OVERLAY", nil, 7)
        edge:SetColorTexture(1, 0.48, 0.08, 1)
        if index <= 2 then
            edge:SetPoint(point .. "LEFT", button, point .. "LEFT", 0, 0)
            edge:SetPoint(point .. "RIGHT", button, point .. "RIGHT", 0, 0)
            edge:SetHeight(2)
        else
            edge:SetPoint("TOP" .. point, button, "TOP" .. point, 0, 0)
            edge:SetPoint("BOTTOM" .. point, button, "BOTTOM" .. point, 0, 0)
            edge:SetWidth(2)
        end
        edge:Hide()
        overlay.edges[index] = edge
    end
    overlay.label = button:CreateFontString(nil, "OVERLAY")
    overlay.label:SetFont(STANDARD_TEXT_FONT, 9, "OUTLINE")
    overlay.label:SetPoint("TOPLEFT", button, "TOPLEFT", 3, -3)
    overlay.label:SetTextColor(1, 0.65, 0.15)
    overlay.label:Hide()
    overlays[button] = overlay
    return overlay
end

local function HideAll()
    for _, overlay in pairs(overlays) do
        overlay.rank, overlay.latest = nil, nil
        for _, edge in ipairs(overlay.edges) do edge:Hide() end
        overlay.label:Hide()
    end
end

local function Buttons()
    local buttons, seen = {}, {}
    local function Add(button)
        if not button or seen[button] then return end
        seen[button] = true
        buttons[#buttons + 1] = button
        if not hooked[button] then
            hooked[button] = true
            button:HookScript("OnShow", function()
                Queue()
                if addon.QueueManaCosts then addon.QueueManaCosts() end
            end)
            button:HookScript("OnEnter", function(self)
                local overlay = overlays[self]
                if active and overlay and overlay.rank and GameTooltip:GetOwner() == self then
                    GameTooltip:AddLine(string.format("MacroMate: rank %d on bar; rank %d learned.",
                        overlay.rank, overlay.latest), 1, 0.6, 0.15, true)
                    GameTooltip:Show()
                end
            end)
        end
    end
    if ActionBarButtonEventsFrame and ActionBarButtonEventsFrame.ForEachFrame then
        ActionBarButtonEventsFrame:ForEachFrame(Add)
    end
    -- Explicit defaults also cover buttons not registered with the dispatcher yet.
    for _, prefix in ipairs({"ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarLeftButton", "MultiBarRightButton", "MultiBar5Button", "MultiBar6Button",
        "MultiBar7Button", "OverrideActionBarButton"}) do
        for index = 1, 12 do Add(_G[prefix .. index]) end
    end
    return buttons
end

addon.GetActionButtons = Buttons

local function OldRank(button, known)
    local action = button.action
    if not Readable(action) or type(action) ~= "number" or action <= 0 then return end
    local kind, id = GetActionInfo(action)
    if not Readable(kind) or not Readable(id) or kind ~= "spell" or type(id) ~= "number" then return end
    -- Resolve the actual action's spell ID, never by name (which picks the latest).
    local name = C_Spell.GetSpellName(id)
    local subtext = C_Spell.GetSpellSubtext(id)
    if not Readable(name) or not Readable(subtext) or type(subtext) ~= "string" then return end
    local rank = tonumber(subtext:match("%d+"))
    local latest = name and known[name] and known[name].highestRank
    if rank and latest and rank < latest then return rank, latest end
end

Refresh = function()
    HideAll()
    local known = addon.GetKnownRanks()
    for _, button in ipairs(Buttons()) do
        if button:IsVisible() then
            local rank, latest = OldRank(button, known)
            if rank then
                local overlay = Overlay(button)
                overlay.rank, overlay.latest = rank, latest
                overlay.label:SetText("R" .. rank)
                if bookOpen and not alwaysRanks then
                    for _, edge in ipairs(overlay.edges) do edge:Show() end
                end
                overlay.label:Show()
            end
        end
    end
end

watcher:SetScript("OnEvent", Queue)
if EventRegistry then
    EventRegistry:RegisterCallback("ActionButton.OnActionChanged", Queue, watcher)
end

local function UpdateWatching()
    active = bookOpen or alwaysRanks
    watcher:UnregisterAllEvents()
    if active then
        for _, event in ipairs({"ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED",
            "UPDATE_BONUS_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM", "UPDATE_OVERRIDE_ACTIONBAR",
            "UPDATE_VEHICLE_ACTIONBAR", "SPELLS_CHANGED", "SPELL_TEXT_UPDATE", "PLAYER_REGEN_ENABLED"}) do
            watcher:RegisterEvent(event)
        end
        Queue()
    else HideAll() end
end

function addon.SetBookOpen(open)
    bookOpen = open == true
    UpdateWatching()
end

function addon.ConfigureRankLabels(value)
    alwaysRanks = value == true
    -- Clear the old border immediately, including when toggled with the book open.
    HideAll()
    UpdateWatching()
end
