--[[
SR Tooltip Handler (Vanilla 1.12 Compatible)

Design goals:
- 100% Lua 5.0 / WoW 1.12 compatible
- NO use of #table operator
- NO HookScript (not available in 1.12)
- Uses secure method hooking via function replacement
- Works for GameTooltip, ItemRefTooltip, and shopping tooltips
- Prevents duplicate lines per tooltip draw
]]

local MAX_SR_DISPLAY = 5
local BULLET_CHAR = " "

-- Track last item processed per tooltip to avoid duplicates
local lastTooltipItem = {}

local function CountTable(t)
    local c = 0
    for _ in pairs(t) do
        c = c + 1
    end
    return c
end

local function AddSRInfoToTooltip(tooltip, itemLink)
    if not tooltip or not itemLink then return end

    if lastTooltipItem[tooltip] == itemLink then return end
    lastTooltipItem[tooltip] = itemLink

    local _, _, itemId = string.find(itemLink, "item:(%d+):")
    itemId = tonumber(itemId)
    if not itemId then return end

    if not SRList or CountTable(SRList) == 0 then return end

    local itemSRs = {}
    for _, sr in ipairs(SRList) do
        if tonumber(sr.ID) == itemId and sr["SR+"] and sr["SR+"] > 0 then
            table.insert(itemSRs, sr)
        end
    end

    local totalSRs = CountTable(itemSRs)
    if totalSRs == 0 then return end

    table.sort(itemSRs, function(a, b)
        if a["SR+"] == b["SR+"] then
            return a.Attendee < b.Attendee
        end
        return a["SR+"] > b["SR+"]
    end)

    if totalSRs > MAX_SR_DISPLAY then
        for i = MAX_SR_DISPLAY + 1, totalSRs do
            itemSRs[i] = nil
        end
    end

    tooltip:AddLine(" ")
    tooltip:AddDoubleLine("Soft Reserves:", "", 1, 1, 1, 1, 1, 1)

    local shown = 0
    for _, sr in ipairs(itemSRs) do
        shown = shown + 1

        local playerName = sr.Attendee
        local class = get_class_of_roller(playerName)
        local srValue = sr["SR+"] or 1
        local isMS = sr.MS

        local classColor = config.RAID_CLASS_COLORS[class] or config.DEFAULT_TEXT_COLOR
        local coloredName = "|c" .. classColor .. playerName .. "|r"

        local rightText = coloredName
        if isMS then
            rightText = rightText .. " |cFF00FF00MS|r"
        else
            rightText = rightText .. " |cFF808080OS|r"
        end

        if srValue > 1 then
            rightText = rightText .. " |cFF00FF00[" .. srValue .. "]|r"
        end

        tooltip:AddDoubleLine(BULLET_CHAR, rightText, 0.5, 0.5, 0.5, 1, 1, 1)
    end

    if totalSRs > shown then
        tooltip:AddDoubleLine("", "|cFFAAAAAA+" .. (totalSRs - shown) .. " more|r", 1, 1, 1, 0.7, 0.7, 0.7)
    end

    tooltip:Show()
end

-- =========================
-- Tooltip Hooking (1.12)
-- =========================

local function HookTooltip(tooltip)
    if not tooltip or tooltip.__SRHooked then return end
    tooltip.__SRHooked = true

    local orig_SetHyperlink = tooltip.SetHyperlink
    tooltip.SetHyperlink = function(self, link)
        orig_SetHyperlink(self, link)
        lastTooltipItem[self] = nil
        AddSRInfoToTooltip(self, link)
    end

    local orig_ClearLines = tooltip.ClearLines
    tooltip.ClearLines = function(self)
        orig_ClearLines(self)
        lastTooltipItem[self] = nil
    end
end

local function InitializeSRTooltipHandler()
    HookTooltip(GameTooltip)
    HookTooltip(ItemRefTooltip)

    if ShoppingTooltip1 then HookTooltip(ShoppingTooltip1) end
    if ShoppingTooltip2 then HookTooltip(ShoppingTooltip2) end
end

InitializeSRTooltipHandler()
