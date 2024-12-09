﻿local weird_vibes_mode = true
local srRollMessages = {}
local msRollMessages = {}
local osRollMessages = {}
local tmogRollMessages = {}
local rollers = {}
local time_elapsed = 0
local item_query = 0.5
local times = 5
local discover = CreateFrame("GameTooltip", "CustomTooltip1", UIParent, "GameTooltipTemplate")
local buttonWidth = 32
local numButtons = 4
local bottomPadding = 10
local font = "Fonts\\FRIZQT__.TTF"
local fontSize = 12
local fontOutline = "OUTLINE"

local function lb_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage(msg)
end

local function resetRolls()
  srRollMessages = {}
  msRollMessages = {}
  osRollMessages = {}
  tmogRollMessages = {}
  rollers = {}
end

local function sortRolls()
  table.sort(srRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(msRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(osRollMessages, function(a, b)
    return a.roll > b.roll
  end)
  table.sort(tmogRollMessages, function(a, b)
    return a.roll > b.roll
  end)
end

local function colorMsg(msg)
  if string.find(msg, "-101") then
      colored_msg = string.format("%s%s|r", "|cFFFF0000", msg)
  elseif string.find(msg, "-100") then
      -- MS uses default color. cFFFFFF00
      colored_msg = msg
  elseif string.find(msg, "-99") then
      colored_msg = string.format("%s%s|r", "|cFF00FF00", msg)
  elseif string.find(msg, "-50") then
    colored_msg = string.format("%s%s|r", "|cFF00FFFF", msg)
  end
  return colored_msg
end

local function tsize(t)
  c = 0
  for _ in pairs(t) do
    c = c + 1
  end
  if c > 0 then return c else return nil end
end

local function CheckItem(link)
  discover:SetOwner(UIParent, "ANCHOR_PRESERVE")
  discover:SetHyperlink(link)

  if discoverTextLeft1 and discoverTooltipTextLeft1:IsVisible() then
    local name = discoverTooltipTextLeft1:GetText()
    discoverTooltip:Hide()

    if name == (RETRIEVING_ITEM_INFO or "") then
      return false
    else
      return true
    end
  end
  return false
end

local function CreateCloseButton(frame)
  -- Add a close button
  local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  closeButton:SetWidth(32) -- Button size
  closeButton:SetHeight(32) -- Button size
  closeButton:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -5, -5) -- Position at the top right

  -- Set textures if you want to customize the appearance
  closeButton:SetNormalTexture("Interface/Buttons/UI-Panel-MinimizeButton-Up")
  closeButton:SetPushedTexture("Interface/Buttons/UI-Panel-MinimizeButton-Down")
  closeButton:SetHighlightTexture("Interface/Buttons/UI-Panel-MinimizeButton-Highlight")

  -- Hide the frame when the button is clicked
  closeButton:SetScript("OnClick", function()
      frame:Hide()
      resetRolls()
  end)
end

local function CreateActionButton(frame, buttonText, tooltipText, index, onClickAction)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (numButtons * buttonWidth)) / (numButtons + 1)
  local button = CreateFrame("Button", nil, frame, UIParent)
  button:SetWidth(buttonWidth)
  button:SetHeight(buttonWidth)
  button:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", index*spacing + (index-1)*buttonWidth, bottomPadding)

  -- Set button text
  button:SetText(buttonText)
  local font = button:GetFontString()
  font:SetFont(font, fontSize, fontOutline)

  -- Add background 
  local bg = button:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(button)
  bg:SetTexture(1, 1, 1, 1) -- White texture
  bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray background

  button:SetScript("OnMouseDown", function(self)
      bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript("OnMouseUp", function(self)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
      GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
      bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
      GameTooltip:Show()
  end)

  button:SetScript("OnLeave", function(self)
      bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
      GameTooltip:Hide()
  end)

  -- Add functionality to the button
  button:SetScript("OnClick", function()
    onClickAction()
  end)
end

local function CreateItemRollFrame()
  local frame = CreateFrame("Frame", "ItemRollFrame", UIParent)
  frame:SetWidth(200) -- Adjust size as needed
  frame:SetHeight(220)
  frame:SetPoint("CENTER",UIParent,"CENTER",0,0) -- Position at center of the parent frame
  frame:SetBackdrop({
      bgFile = "Interface/Tooltips/UI-Tooltip-Background",
      edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
      tile = true, tileSize = 16, edgeSize = 16,
      insets = { left = 4, right = 4, top = 4, bottom = 4 }
  })
  frame:SetBackdropColor(0, 0, 0, 1) -- Black background with full opacity

  frame:SetMovable(true)
  frame:EnableMouse(true)

  frame:RegisterForDrag("LeftButton") -- Only start dragging with the left mouse button
  frame:SetScript("OnDragStart", function () frame:StartMoving() end)
  frame:SetScript("OnDragStop", function () frame:StopMovingOrSizing() end)
  CreateCloseButton(frame)
  CreateActionButton(frame, "SR", "Roll for Soft Reserve", 1, function() RandomRoll(1,101) end)
  CreateActionButton(frame, "MS", "Roll for Main Spec", 2, function() RandomRoll(1,100) end)
  CreateActionButton(frame, "OS", "Roll for Off Spec", 3, function() RandomRoll(1,99) end)
  CreateActionButton(frame, "TM", "Roll for Transmog", 4, function() RandomRoll(1,50) end)
  frame:Hide()

  return frame
end

local itemRollFrame = CreateItemRollFrame()

local function InitItemInfo(frame)
  -- Create the texture for the item icon
  local icon = frame:CreateTexture()
  icon:SetWidth(40) -- Size of the icon
  icon:SetHeight(40) -- Size of the icon
  icon:SetPoint("TOP", frame, "TOP", 0, -10)

  -- Create a button for mouse interaction
  local iconButton = CreateFrame("Button", nil, frame)
  iconButton:SetWidth(40) -- Size of the icon
  iconButton:SetHeight(40) -- Size of the icon
  iconButton:SetPoint("TOP", frame, "TOP", 0, -10)

  -- Create a FontString for the frame hide timer
  local timerText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  timerText:SetPoint("CENTER", frame, "TOPLEFT", 30, -32)
  timerText:SetFont(timerText:GetFont(), 20)

  -- Create a FontString for the item name
  local name = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  name:SetPoint("TOP", icon, "BOTTOM", 0, -10)

  frame.icon = icon
  frame.iconButton = iconButton
  frame.timerText = timerText
  frame.name = name
  frame.itemLink = ""

  local tt = CreateFrame("GameTooltip", "CustomTooltip2", UIParent, "GameTooltipTemplate")

  -- Set up tooltip
  iconButton:SetScript("OnEnter", function()
    tt:SetOwner(iconButton, "ANCHOR_RIGHT")
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  iconButton:SetScript("OnLeave", function()
    tt:Hide()
  end)
  iconButton:SetScript("OnClick", function()
    if ( IsControlKeyDown() ) then
      DressUpItemLink(frame.itemLink);
    elseif ( IsShiftKeyDown() and ChatFrameEditBox:IsVisible() ) then
      local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(ITEM_QUALITY_COLORS[itemQuality].hex.."\124H"..itemLink.."\124h["..itemName.."]\124h"..FONT_COLOR_CODE_CLOSE);
    end
  end)
end

-- Function to return colored text based on item quality
local function GetColoredTextByQuality(text, qualityIndex)
  -- Get the color associated with the item quality
  local r, g, b, hex = GetItemQualityColor(qualityIndex)
  -- Return the text wrapped in WoW's color formatting
  return string.format("%s%s|r", hex, text)
end

local function SetItemInfo(frame, itemLinkArg)
  local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(itemLinkArg)
  if not frame.icon then InitItemInfo(frame) end

  -- if we know the item, and the quality isn't green+, don't show it
  if itemName and itemQuality < 2 then return false end
  if not itemIcon then
    frame.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
    frame.name:SetText("Unknown item, attempting to query...")
    -- could be an item we want to see, try to show it
    return true
  end

  frame.icon:SetTexture(itemIcon)
  frame.iconButton:SetNormalTexture(itemIcon)  -- Sets the same texture as the icon

  frame.name:SetText(GetColoredTextByQuality(itemName,itemQuality))

  frame.itemLink = itemLink
  return true
end

local function ShowFrame(frame,duration,item)
  frame:SetScript("OnUpdate", function()
    time_elapsed = time_elapsed + arg1
    item_query = item_query - arg1
    if frame.timerText then frame.timerText:SetText(format("%.1f", duration - time_elapsed)) end
    if time_elapsed >= duration then
      frame:Hide()
      frame:SetScript("OnUpdate", nil)
      time_elapsed = 0
      item_query = 1.5
      times = 3
      rollMessages = {}
    end
    if times > 0 and item_query < 0 and not CheckItem(item) then
      times = times - 1
    else
      -- try to set item info, if it's not a valid item or too low quality, hide
      if not SetItemInfo(itemRollFrame,item) then frame:Hide() end
      times = 5
    end
  end)
  frame:Show()
end

local function CreateTextArea(frame)
  local textArea = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  textArea:SetHeight(150) -- Size of the icon
  textArea:SetPoint("TOP", frame, "TOP", 0, -80)
  textArea:SetJustifyH("LEFT")
  textArea:SetJustifyV("TOP")

  return textArea
end

local function UpdateTextArea(frame)
  if not frame.textArea then
    frame.textArea = CreateTextArea(frame)
  end

  -- frame.textArea:SetTeClear()  -- Clear the existing messages
  local text = ""
  local colored_msg = ""
  local count = 0

  sortRolls()

  for i, v in ipairs(srRollMessages) do
    if count >= 5 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v.msg) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(msRollMessages) do
    if count >= 6 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v.msg) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(osRollMessages) do
    if count >= 7 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v.msg) .. "\n"
    count = count + 1
  end
  for i, v in ipairs(tmogRollMessages) do
    if count >= 8 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v.msg) .. "\n"
    count = count + 1
  end

  frame.textArea:SetText(text)
end

local function ExtractItemLinksFromMessage(message)
  local itemLinks = {}
  -- This pattern matches the standard item link structure in WoW
  for link in string.gfind(message, "|c.-|H(item:.-)|h.-|h|r") do
    -- lb_print(link)
    table.insert(itemLinks, link)
  end
  return itemLinks
end

-- no good, seems like masterLooterRaidID always nil?
local function IsUnitMasterLooter(unit)
  local lootMethod, masterLooterPartyID, masterLooterRaidID = GetLootMethod()
  
  if lootMethod == "master" then
      if IsInRaid() then
          -- In a raid, use the raid ID to check
          return UnitIsUnit(unit, "raid" .. masterLooterRaidID)
      elseif IsInGroup() then
          -- In a party, use the party ID to check
          return UnitIsUnit(unit, "party" .. masterLooterPartyID)
      end
  end
  
  return false
end

local function HandleChatMessage(event, message, from)
  if event == "CHAT_MSG_SYSTEM" and itemRollFrame:IsShown() then
    if string.find(message, "rolls") and string.find(message, "(%d+)") then
      local _,_,roller, roll, minRoll, maxRoll = string.find(message, "(%S+) rolls (%d+) %((%d+)%-(%d+)%)")
      if roller and roll and rollers[roller] == nil then
        roll = tonumber(roll)
        rollers[roller] = 1
        message = { roller = roller, roll = roll, msg = message }
        if maxRoll == "101" then
          table.insert(srRollMessages, message)
        elseif maxRoll == "100" then
          table.insert(msRollMessages, message)
        elseif maxRoll == "99" then
          table.insert(osRollMessages, message)
        elseif maxRoll == "50" then
          table.insert(tmogRollMessages, message)
        end
        time_elapsed = 0
        UpdateTextArea(itemRollFrame)
      end
    end
  elseif event == "CHAT_MSG_RAID_WARNING" then
    local lootMethod, _ = GetLootMethod()
    if lootMethod == "master" then -- check if there is a loot master
      local links = ExtractItemLinksFromMessage(message)
      if tsize(links) == 1 then
        if string.find(message, "^No one has need:") or
           string.find(message,"has been sent to") or
           string.find(message, " received ") then
          itemRollFrame:Hide()
          return
        elseif string.find(message,"Rolling Cancelled") or -- usually a cancel is accidental in my experience
               string.find(message,"seconds left to roll") or
               string.find(message,"Rolling is now Closed") then
          return
        end
        resetRolls()
        UpdateTextArea(itemRollFrame)
        time_elapsed = 0
        ShowFrame(itemRollFrame,FrameShownDuration,links[1])
        -- SetItemInfo(itemRollFrame,links[1])
      end
    end
  elseif event == "ADDON_LOADED" and arg1 == "LootBlare" then
    if not FrameShownDuration then FrameShownDuration = 20 end
  end
end

itemRollFrame:RegisterEvent("ADDON_LOADED")
itemRollFrame:RegisterEvent("CHAT_MSG_SYSTEM")
itemRollFrame:RegisterEvent("CHAT_MSG_RAID_WARNING")
itemRollFrame:SetScript("OnEvent", function () HandleChatMessage(event,arg1,arg2) end)

-- Register the slash command
SLASH_LOOTBLARE1 = '/lootblare'

-- Command handler
SlashCmdList["LOOTBLARE"] = function(msg)
    local newDuration = tonumber(msg)
    if newDuration then
      if newDuration > 0 then
        FrameShownDuration = newDuration
        lb_print("Frame shown duration set to " .. newDuration .. " seconds.")
      else
        lb_print("Invalid duration. Please enter a number greater than 0.")
      end
    else
      ShowFrame(itemRollFrame,FrameShownDuration,"item:15723")
    end
end