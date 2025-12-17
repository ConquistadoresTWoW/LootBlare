-- sr_tooltip_handler.lua
-- Adds Soft Reserve information to item tooltips

local MAX_SR_DISPLAY = 5  -- Maximum number of SRs to show in tooltip

-- Helper function to create right-aligned text using non-breaking spaces
local function CreateRightAlignedText(text)
    -- Use non-breaking spaces (Alt+255) to push text to the right
    -- We'll add a lot of them to ensure text appears on the right side
    local nbsp = string.char(194, 160)  -- UTF-8 non-breaking space
    local padding = nbsp .. nbsp .. nbsp .. nbsp .. nbsp .. nbsp .. nbsp .. nbsp .. nbsp .. nbsp
    return padding .. text
end

-- Hook into GameTooltip to add SR information
local function AddSRInfoToTooltip(tooltip, itemLink)
    -- Check if we have an item link
    if not itemLink then return end
    
    -- Extract item ID from the link
    local itemId = tonumber(string.match(itemLink, "item:(%d+):"))
    if not itemId then return end
    
    -- Check if we have SR data for this item
    if not SRList or len(SRList) == 0 then return end
    
    -- Find soft reserves for this item
    local itemSRs = {}
    for _, sr in ipairs(SRList) do
        if tonumber(sr["ID"]) == itemId and sr["SR+"] > 0 then
            table.insert(itemSRs, sr)
        end
    end
    
    -- Sort by SR+ value (descending) and then by attendee name
    table.sort(itemSRs, function(a, b)
        if a["SR+"] == b["SR+"] then
            return a["Attendee"] < b["Attendee"]
        end
        return a["SR+"] > b["SR+"]
    end)
    
    -- Count how many SRs we have
    local itemSRsCount = 0
    for _ in pairs(itemSRs) do
        itemSRsCount = itemSRsCount + 1
    end
    
    -- Limit to MAX_SR_DISPLAY
    if itemSRsCount > MAX_SR_DISPLAY then
        local limitedSRs = {}
        local count = 0
        for i, sr in ipairs(itemSRs) do
            if count < MAX_SR_DISPLAY then
                table.insert(limitedSRs, sr)
                count = count + 1
            else
                break
            end
        end
        itemSRs = limitedSRs
        itemSRsCount = count
    end
    
    -- Add SR information to tooltip if we have any
    if itemSRsCount > 0 then
        -- Add a separator line
        tooltip:AddLine(" ")
        
        -- Count total SRs for this item
        local totalSRs = 0
        for _, sr in ipairs(SRList) do
            if tonumber(sr["ID"]) == itemId and sr["SR+"] > 0 then
                totalSRs = totalSRs + 1
            end
        end
        
        -- Add SR header without right alignment
        tooltip:AddLine("SR:")
        
        -- Add each player on a separate line
        for i = 1, itemSRsCount do
            local sr = itemSRs[i]
            local playerName = sr["Attendee"]
            local class = get_class_of_roller(playerName)
            local srValue = sr["SR+"]
            local isMS = sr["MS"]
            
            -- Get class color
            local classColor = config.RAID_CLASS_COLORS[class] or config.DEFAULT_TEXT_COLOR
            
            -- Format the player name with class color
            local coloredName = "|c" .. classColor .. playerName .. "|r"
            
            -- Create SR type indicator
            local srType = ""
            if not isMS then
                srType = "OS"
            end
            
            if srValue > 1 then
                if srType ~= "" then
                    srType = srType .. " [" .. srValue .. "]"  -- Added space before [
                else
                    srType = "[" .. srValue .. "]"
                end
            elseif srType ~= "" then
                srType = srType  -- Just "OS" without brackets
            end
            
            -- Combine player name and SR type with space
            local entry = coloredName
            if srType ~= "" then
                entry = entry .. " " .. srType  -- Added space between name and type
            end
            
            -- Add the entry to tooltip
            tooltip:AddLine("  " .. entry)  -- Indented for better readability
        end
        
        -- Add "and X more" if needed
        if totalSRs > MAX_SR_DISPLAY then
            local remaining = totalSRs - MAX_SR_DISPLAY
            tooltip:AddLine("  +" .. remaining .. " more")
        end
    end
end

-- Store original functions
local original_SetHyperlink = GameTooltip.SetHyperlink
local original_SetLootItem = GameTooltip.SetLootItem
local original_SetBagItem = GameTooltip.SetBagItem
local original_SetInventoryItem = GameTooltip.SetInventoryItem
local original_SetLootRollItem = GameTooltip.SetLootRollItem
local original_SetAuctionItem = GameTooltip.SetAuctionItem
local original_SetAuctionSellItem = GameTooltip.SetAuctionSellItem
local original_SetBuybackItem = GameTooltip.SetBuybackItem
local original_SetMerchantItem = GameTooltip.SetMerchantItem
local original_SetQuestItem = GameTooltip.SetQuestItem
local original_SetQuestLogItem = GameTooltip.SetQuestLogItem
local original_SetTradeSkillItem = GameTooltip.SetTradeSkillItem
local original_SetInboxItem = GameTooltip.SetInboxItem
local original_SetSendMailItem = GameTooltip.SetSendMailItem

-- Hook GameTooltip:SetHyperlink
function GameTooltip:SetHyperlink(link)
    original_SetHyperlink(self, link)
    AddSRInfoToTooltip(self, link)
end

-- Hook GameTooltip:SetLootItem
function GameTooltip:SetLootItem(lootIndex)
    original_SetLootItem(self, lootIndex)
    local itemLink = GetLootSlotLink(lootIndex)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetBagItem
function GameTooltip:SetBagItem(bag, slot)
    original_SetBagItem(self, bag, slot)
    local itemLink = GetContainerItemLink(bag, slot)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetInventoryItem
function GameTooltip:SetInventoryItem(unit, slot)
    original_SetInventoryItem(self, unit, slot)
    local itemLink = GetInventoryItemLink(unit, slot)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetLootRollItem
function GameTooltip:SetLootRollItem(id)
    original_SetLootRollItem(self, id)
    local itemLink = GetLootRollItemLink(id)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetAuctionItem
function GameTooltip:SetAuctionItem(type, index)
    original_SetAuctionItem(self, type, index)
    local itemLink = GetAuctionItemLink(type, index)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetAuctionSellItem
function GameTooltip:SetAuctionSellItem()
    original_SetAuctionSellItem(self)
    -- Note: GetAuctionSellItemInfo doesn't return a link directly in 1.12
    -- This hook might need adjustment based on exact 1.12 API
end

-- Hook GameTooltip:SetBuybackItem
function GameTooltip:SetBuybackItem()
    original_SetBuybackItem(self)
    local itemLink = GetBuybackItemLink(GetNumBuybackItems())
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetMerchantItem
function GameTooltip:SetMerchantItem(slot)
    original_SetMerchantItem(self, slot)
    local itemLink = GetMerchantItemLink(slot)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetQuestItem
function GameTooltip:SetQuestItem(type, index)
    original_SetQuestItem(self, type, index)
    local itemLink = GetQuestItemLink(type, index)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetQuestLogItem
function GameTooltip:SetQuestLogItem(type, index)
    original_SetQuestLogItem(self, type, index)
    local itemLink = GetQuestLogItemLink(type, index)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetTradeSkillItem
function GameTooltip:SetTradeSkillItem(tradeItemIndex, reagentIndex)
    original_SetTradeSkillItem(self, tradeItemIndex, reagentIndex)
    local itemLink
    if reagentIndex then
        itemLink = GetTradeSkillReagentItemLink(tradeItemIndex, reagentIndex)
    else
        itemLink = GetTradeSkillItemLink(tradeItemIndex)
    end
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetInboxItem
function GameTooltip:SetInboxItem(index)
    original_SetInboxItem(self, index)
    local itemLink = GetInboxItemLink(index)
    AddSRInfoToTooltip(self, itemLink)
end

-- Hook GameTooltip:SetSendMailItem
function GameTooltip:SetSendMailItem()
    original_SetSendMailItem(self)
    local itemLink = GetSendMailItemLink()
    AddSRInfoToTooltip(self, itemLink)
end

-- Function to refresh tooltip SR info when SR list changes
function RefreshTooltipSRInfo()
    -- Force refresh any visible tooltip
    if GameTooltip:IsVisible() then
        local owner = GameTooltip:GetOwner()
        if owner then
            -- Try to get the item link from the tooltip's current item
            local itemLink
            for i = 1, GameTooltip:NumLines() do
                local lineText = getglobal("GameTooltipTextLeft" .. i):GetText()
                if lineText and string.find(lineText, "|Hitem:") then
                    -- Extract item link from tooltip text
                    itemLink = string.match(lineText, "(|c%x+|Hitem:%d+:.-|h%[.-%]|h|r)")
                    break
                end
            end
            
            if itemLink then
                -- Clear and re-set the tooltip with SR info
                GameTooltip:ClearLines()
                GameTooltip:SetHyperlink(itemLink)
            end
        end
    end
end

-- Refresh tooltips when SR list is updated
local function HookSRFunctions()
    -- Hook load_sr_from_csv to refresh tooltips
    local original_load_sr_from_csv = load_sr_from_csv
    load_sr_from_csv = function(text)
        local result = original_load_sr_from_csv(text)
        RefreshTooltipSRInfo()
        return result
    end
    
    -- Hook clear_sr_list to refresh tooltips
    local original_clear_sr_list = clear_sr_list
    clear_sr_list = function()
        local result = original_clear_sr_list()
        RefreshTooltipSRInfo()
        return result
    end
    
    -- Hook functions that modify SRList
    local original_built_sr_row_from_string = built_sr_row_from_string
    built_sr_row_from_string = function(sr_str)
        local result = original_built_sr_row_from_string(sr_str)
        RefreshTooltipSRInfo()
        return result
    end
end

-- Initialize when addon loads
local function InitializeSRTooltipHandler()
    HookSRFunctions()
    lb_print("SR tooltip handler initialized")
end

-- Call initialization
InitializeSRTooltipHandler()