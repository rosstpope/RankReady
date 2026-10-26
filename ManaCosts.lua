local _, addon = ...
local watcher = CreateFrame("Frame")
local labels = {}
local enabled, scheduled = false, false
local resources = {}
local Refresh

local function Readable(value)
    return not (issecretvalue and issecretvalue(value))
end

local function Number(value)
    return Readable(value) and type(value) == "number"
end

function addon.QueueManaCosts()
    if not enabled or scheduled then return end
    scheduled = true
    C_Timer.After(0.1, function()
        scheduled = false
        if enabled then Refresh() end
    end)
end

local function ResourceCost(spellID)
    local costs = C_Spell.GetSpellPowerCost(spellID)
    if not Readable(costs) or type(costs) ~= "table" then return end
    local amounts, conditional = {}, {}
    for _, info in ipairs(costs) do
        if Number(info.type) and resources[info.type] then
            -- Aura-specific entries apply only in their required form/state.
            if Number(info.cost) and info.cost >= 0
                and Readable(info.requiredAuraID) and Readable(info.hasRequiredAura) then
                if info.hasRequiredAura then
                    amounts[info.type], conditional[info.type] = info.cost, true
                elseif (not info.requiredAuraID or info.requiredAuraID == 0) and not conditional[info.type] then
                    amounts[info.type] = info.cost
                end
            end
        end
    end
    local parts = {}
    for _, powerType in ipairs({Enum.PowerType.Mana, Enum.PowerType.Rage, Enum.PowerType.Energy}) do
        local amount = amounts[powerType]
        if amount then
            parts[#parts + 1] = resources[powerType] .. math.floor(amount + 0.5) .. "|r"
        end
    end
    if #parts > 0 then return table.concat(parts, " ") end
end

local function Label(button)
    local label = labels[button]
    if not label then
        label = button:CreateFontString(nil, "OVERLAY")
        label:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
        label:SetPoint("BOTTOM", button, "BOTTOM", 0, 3)
        label:SetTextColor(1, 1, 1)
        labels[button] = label
    end
    return label
end

function addon.ResolveCostSpell(button, cache)
    local action = button.action
    if not Number(action) or action <= 0 then return end
    local kind, id, subtype = GetActionInfo(action)
    if not Readable(kind) or not Number(id) then return end
    if kind == "spell" or (kind == "macro" and Readable(subtype) and subtype == "spell") then
        return id
    elseif kind == "macro" then
        if cache.macros[id] == nil then
            local spell = addon.GetSimpleMacroSpell(id)
            local spellID
            if spell then
                cache.known = cache.known or addon.GetKnownRanks()
                local entry = cache.known[spell]
                spellID = entry and entry.highestSpellID
            end
            spellID = spellID or GetMacroSpell(id)
            cache.macros[id] = Number(spellID) and spellID or false
        end
        return cache.macros[id] or nil
    end
end

function addon.GetCostSpellName(spellID)
    if not Number(spellID) or spellID <= 0 then return end
    local name = C_Spell.GetSpellName(spellID)
    if Readable(name) and type(name) == "string" and name ~= "" then return name end
end

function addon.ShouldShowCost(spellID)
    local settings = addon.GetCostSettings()
    if not settings or settings.costMode == "off" then return false end
    if settings.costMode == "all" then return true end
    local name = addon.GetCostSpellName(spellID)
    return name ~= nil and settings.costSpells[name] == true
end

Refresh = function()
    -- Reuse labels and cache costs only for this refresh, so buffs and rank
    -- changes cannot leave a persistent price cache stale.
    for _, label in pairs(labels) do label:Hide() end
    local costs, cache = {}, {macros = {}}
    for _, button in ipairs(addon.GetActionButtons()) do
        if button:IsVisible() then
            local spellID = addon.ResolveCostSpell(button, cache)
            if Number(spellID) and spellID > 0 and addon.ShouldShowCost(spellID) then
                if costs[spellID] == nil then costs[spellID] = ResourceCost(spellID) or false end
                local cost = costs[spellID]
                if cost ~= false then
                    local label = Label(button)
                    label:SetText(tostring(cost))
                    label:Show()
                end
            end
        end
    end
end

watcher:SetScript("OnEvent", function(_, event, _, powerToken)
    -- Variable-cost rage/energy spells can depend on the current resource pool.
    if event == "UNIT_POWER_UPDATE" then
        if not Readable(powerToken) then return end
        if not ((powerToken == "RAGE" and resources[Enum.PowerType.Rage])
            or (powerToken == "ENERGY" and resources[Enum.PowerType.Energy])) then return end
    end
    addon.QueueManaCosts()
end)
if EventRegistry then
    EventRegistry:RegisterCallback("ActionButton.OnActionChanged", addon.QueueManaCosts, watcher)
end

function addon.ConfigureManaCosts(mana, rage, energy)
    resources = {}
    if mana then resources[Enum.PowerType.Mana] = "|cff8cccff" end
    if rage then resources[Enum.PowerType.Rage] = "|cffff6666" end
    if energy then resources[Enum.PowerType.Energy] = "|cffffdb55" end
    local settings = addon.GetCostSettings()
    enabled = next(resources) ~= nil and settings and settings.costMode ~= "off"
    watcher:UnregisterAllEvents()
    if enabled then
        for _, event in ipairs({"PLAYER_ENTERING_WORLD", "ACTIONBAR_SLOT_CHANGED", "ACTIONBAR_PAGE_CHANGED",
            "UPDATE_BONUS_ACTIONBAR", "UPDATE_SHAPESHIFT_FORM", "UPDATE_OVERRIDE_ACTIONBAR",
            "UPDATE_VEHICLE_ACTIONBAR", "SPELLS_CHANGED", "SPELL_TEXT_UPDATE", "UPDATE_MACROS",
            "MODIFIER_STATE_CHANGED", "PLAYER_TARGET_CHANGED", "PLAYER_EQUIPMENT_CHANGED",
            "SPELL_UPDATE_USES", "PLAYER_REGEN_ENABLED", "PLAYER_REGEN_DISABLED"}) do
            watcher:RegisterEvent(event)
        end
        watcher:RegisterUnitEvent("UNIT_AURA", "player")
        watcher:RegisterUnitEvent("UNIT_MAXPOWER", "player")
        if rage or energy then watcher:RegisterUnitEvent("UNIT_POWER_UPDATE", "player") end
        addon.QueueManaCosts()
    else
        for _, label in pairs(labels) do label:Hide() end
    end
end
