function CreateCloseButton(frame)
  -- Add a close button
  local closeButton = CreateFrame('Button', nil, frame, 'UIPanelCloseButton')
  closeButton:SetWidth(32) -- Button size
  closeButton:SetHeight(32) -- Button size
  closeButton:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -5, -5) -- Position at the top right

  -- Set textures if you want to customize the appearance
  closeButton:SetNormalTexture('Interface/Buttons/UI-Panel-MinimizeButton-Up')
  closeButton:SetPushedTexture('Interface/Buttons/UI-Panel-MinimizeButton-Down')
  closeButton:SetHighlightTexture(
    'Interface/Buttons/UI-Panel-MinimizeButton-Highlight')

  -- Hide the frame when the button is clicked
  closeButton:SetScript('OnClick', function()
    frame:Hide()
    resetRolls()
  end)
end

function CreateActionButton(frame, buttonText, tooltipText, index, onClickAction)
  local panelWidth = frame:GetWidth()
  local spacing = (panelWidth - (config.BUTTON_COUNT * config.BUTTON_WIDTH)) /
                    (config.BUTTON_COUNT + 1)
  local button = CreateFrame('Button', nil, frame, UIParent)
  button:SetWidth(config.BUTTON_WIDTH)
  button:SetHeight(config.BUTTON_WIDTH)
  button:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT',
                  index * spacing + (index - 1) * config.BUTTON_WIDTH,
                  config.BUTTON_PADING)

  -- Set button text
  button:SetText(buttonText)
  local font = button:GetFontString()
  font:SetFont(config.FONT_NAME, config.FONT_SIZE, config.FONT_OUTLINE)

  -- Add background 
  local bg = button:CreateTexture(nil, 'BACKGROUND')
  bg:SetAllPoints(button)
  bg:SetTexture(1, 1, 1, 1) -- White texture
  bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray background

  button:SetScript('OnMouseDown', function(self)
    bg:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript('OnMouseUp', function(self)
    bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
    GameTooltip:SetText(tooltipText, nil, nil, nil, nil, true)
    bg:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
    GameTooltip:Show()
  end)

  button:SetScript('OnLeave', function(self)
    bg:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
    GameTooltip:Hide()
  end)

  -- Add functionality to the button
  button:SetScript('OnClick', function() onClickAction() end)
end

function CreateItemRollFrame()
  local frame = CreateFrame('Frame', 'ItemRollFrame', UIParent)
  frame:SetWidth(200) -- Adjust size as needed
  frame:SetHeight(220)
  frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0) -- Position at center of the parent frame
  frame:SetBackdrop({
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
    edgeFile = 'Interface/Tooltips/UI-Tooltip-Border',
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  frame:SetBackdropColor(0, 0, 0, 1) -- Black background with full opacity

  frame:SetMovable(true)
  frame:EnableMouse(true)

  frame:RegisterForDrag('LeftButton') -- Only start dragging with the left mouse button
  frame:SetScript('OnDragStart', function() frame:StartMoving() end)
  frame:SetScript('OnDragStop', function() frame:StopMovingOrSizing() end)
  CreateCloseButton(frame)
  CreateActionButton(frame, 'MS', 'Roll for Main Spec', 1,
                     function() RandomRoll(1, 100) end)
  CreateActionButton(frame, 'OS', 'Roll for Off Spec', 2,
                     function() RandomRoll(1, 99) end)
  CreateActionButton(frame, 'TM', 'Roll for Transmog', 3,
                     function() RandomRoll(1, 50) end)
  frame:Hide()

  return frame
end

function UpdateTextArea(frame)
  if not frame.textArea then frame.textArea = CreateTextArea(frame) end

  -- frame.textArea:SetTeClear()  -- Clear the existing messages
  local text = ''
  local colored_msg = ''
  local count = 0

  sortRolls()

  for i, v in ipairs(srRollMessages) do
    if count >= 5 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. '\n'
    count = count + 1
  end
  for i, v in ipairs(msRollMessages) do
    if count >= 6 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. '\n'
    count = count + 1
  end
  for i, v in ipairs(osRollMessages) do
    if count >= 7 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. '\n'
    count = count + 1
  end
  for i, v in ipairs(tmogRollMessages) do
    if count >= 8 then break end
    colored_msg = v.msg
    text = text .. colorMsg(v) .. '\n'
    count = count + 1
  end

  frame.textArea:SetText(text)
end

function InitItemInfo(frame)
  -- Create the texture for the item icon
  local icon = frame:CreateTexture()
  icon:SetWidth(40) -- Size of the icon
  icon:SetHeight(40) -- Size of the icon
  icon:SetPoint('TOP', frame, 'TOP', 0, -10)

  -- Create a button for mouse interaction
  local iconButton = CreateFrame('Button', nil, frame)
  iconButton:SetWidth(40) -- Size of the icon
  iconButton:SetHeight(40) -- Size of the icon
  iconButton:SetPoint('TOP', frame, 'TOP', 0, -10)

  -- Create a FontString for the frame hide timer
  local timerText = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  timerText:SetPoint('CENTER', frame, 'TOPLEFT', 30, -32)
  timerText:SetFont(timerText:GetFont(), 20)

  -- Create a FontString for the item name
  local name = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  name:SetPoint('TOP', icon, 'BOTTOM', 0, -10)

  frame.icon = icon
  frame.iconButton = iconButton
  frame.timerText = timerText
  frame.name = name
  frame.itemLink = ''

  local tt = CreateFrame('GameTooltip', 'CustomTooltip2', UIParent,
                         'GameTooltipTemplate')

  -- Set up tooltip
  iconButton:SetScript('OnEnter', function()
    tt:SetOwner(iconButton, 'ANCHOR_RIGHT')
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  iconButton:SetScript('OnLeave', function() tt:Hide() end)
  iconButton:SetScript('OnClick', function()
    if (IsControlKeyDown()) then
      DressUpItemLink(frame.itemLink);
    elseif (IsShiftKeyDown() and ChatFrameEditBox:IsVisible()) then
      local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon =
        GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(config.ITEM_QUALITY_COLORS[itemQuality].hex ..
                                '\124H' .. itemLink .. '\124h[' .. itemName ..
                                ']\124h' .. config.FONT_COLOR_CODE_CLOSE);
    end
  end)
end
-- Function to return colored text based on item quality
function GetColoredTextByQuality(text, qualityIndex)
  -- Get the color associated with the item quality
  local r, g, b, hex = GetItemQualityColor(qualityIndex)
  -- Return the text wrapped in WoW's color formatting
  return string.format('%s%s|r', hex, text)
end

function SetItemInfo(frame, itemLinkArg)
  local itemName, itemLink, itemQuality, _, _, _, _, _, itemIcon = GetItemInfo(
                                                                     itemLinkArg)
  if not frame.icon then InitItemInfo(frame) end

  -- if we know the item, and the quality isn't green+, don't show it
  if itemName and itemQuality < 2 then return false end
  if not itemIcon then
    frame.icon:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
    frame.name:SetText('Unknown item, attempting to query...')
    -- could be an item we want to see, try to show it
    return true
  end

  frame.icon:SetTexture(itemIcon)
  frame.iconButton:SetNormalTexture(itemIcon) -- Sets the same texture as the icon

  frame.name:SetText(GetColoredTextByQuality(itemName, itemQuality))

  frame.itemLink = itemLink
  return true
end

function ShowFrame(frame, duration, item)
  frame:SetScript('OnUpdate', function()
    time_elapsed = time_elapsed + arg1
    item_query = item_query - arg1
    if frame.timerText then
      frame.timerText:SetText(format('%.1f', duration - time_elapsed))
    end
    if time_elapsed >= duration then
      frame:SetScript('OnUpdate', nil)
      time_elapsed = 0
      item_query = 1.5
      times = 3
      rollMessages = {}
      isRolling = false
      if FrameAutoClose then frame:Hide() end
    end
    if times > 0 and item_query < 0 and not CheckItem(item) then
      times = times - 1
    else
      if not SetItemInfo(itemRollFrame, item) then frame:Hide() end
      times = 5
    end
  end)
  frame:Show()
end

function CreateTextArea(frame)
  local textArea = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  textArea:SetHeight(150) -- Size of the icon
  textArea:SetPoint('TOP', frame, 'TOP', 0, -80)
  textArea:SetJustifyH('LEFT')
  textArea:SetJustifyV('TOP')

  return textArea
end

function GetClassOfRoller(rollerName)
  -- Iterate through the raid roster
  for i = 1, GetNumRaidMembers() do
    local name, rank, subgroup, level, class, fileName, zone, online, isDead,
          role, isML = GetRaidRosterInfo(i)
    if name == rollerName then
      return class -- Return the class as a string (e.g., 'Warrior', 'Mage')
    end
  end
  return nil -- Return nil if the player is not found in the raid
end

function ExtractItemLinksFromMessage(message)
  local itemLinks = {}
  -- This pattern matches the standard item link structure in WoW
  for link in string.gfind(message, '|c.-|H(item:.-)|h.-|h|r') do
    table.insert(itemLinks, link)
  end
  return itemLinks
end
