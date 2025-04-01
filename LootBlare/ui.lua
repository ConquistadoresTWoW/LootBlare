total_button_width = 0

local function create_close_button(frame, position, xOffset, yOffset)
  -- Default values if not provided
  position = position or 'TOPRIGHT'
  xOffset = xOffset or -7
  yOffset = yOffset or -7

  -- Add a custom close button
  local close_button = CreateFrame('Button', nil, frame)
  close_button:SetWidth(16) -- Button size
  close_button:SetHeight(16) -- Button size
  close_button:SetPoint(position, frame, position, xOffset, yOffset) -- Custom position

  -- Set normal texture
  local normal_texture = close_button:CreateTexture(nil, 'BACKGROUND')
  normal_texture:SetTexture("Interface\\AddOns\\LootBlare\\assets\\close.tga")
  normal_texture:SetAllPoints(close_button)
  close_button:SetNormalTexture(normal_texture)

  -- Set pushed texture
  local pushed_texture = close_button:CreateTexture(nil, 'BACKGROUND')
  pushed_texture:SetTexture("Interface\\AddOns\\LootBlare\\assets\\close2.tga")
  pushed_texture:SetAllPoints(close_button)
  close_button:SetPushedTexture(pushed_texture)

  -- Set highlight texture
  local highlight_texture = close_button:CreateTexture(nil, 'HIGHLIGHT')
  highlight_texture:SetTexture(
    "Interface\\AddOns\\LootBlare\\assets\\close2.tga")
  highlight_texture:SetAllPoints(close_button)
  close_button:SetHighlightTexture(highlight_texture)

  -- Hide the frame when the button is clicked
  close_button:SetScript('OnClick', function() frame:Hide() end)

  return close_button
end

local function create_action_button(frame, button_text, tooltip_text, index,
                                    on_click_action, width_multiplier,
                                    button_space_before)
  local width_multiplier = width_multiplier or 1
  local panel_width = frame:GetWidth()
  local spacing = (panel_width - total_button_width) / (config.BUTTON_COUNT + 1)
  local button = CreateFrame('Button', nil, frame, UIParent)
  button:SetWidth(config.BUTTON_WIDTH * width_multiplier)
  button:SetHeight(config.BUTTON_WIDTH)
  button:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT',
                  spacing * index + button_space_before, config.BUTTON_PADING)

  -- Set button text
  button:SetText(button_text)
  local font = button:GetFontString()
  font:SetFont(config.FONT_NAME, config.FONT_SIZE, config.FONT_OUTLINE)
  font:SetPoint("CENTER", button, "CENTER", 0, -4) -- Move text down by 2 pixels

  -- Add background
  local background = button:CreateTexture(nil, 'BACKGROUND')
  background:SetAllPoints(button)
  background:SetTexture(1, 1, 1, 1)
  background:SetVertexColor(0.2, 0.2, 0.2, 1)

  button:SetScript('OnMouseDown', function(self)
    background:SetVertexColor(0.6, 0.6, 0.6, 1) -- Even lighter gray when pressed
  end)

  button:SetScript('OnMouseUp', function(self)
    background:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on release
  end)

  -- Add tooltip
  button:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
    GameTooltip:SetText(tooltip_text, nil, nil, nil, nil, true)
    background:SetVertexColor(0.4, 0.4, 0.4, 1) -- Lighter gray on hover
    GameTooltip:Show()
  end)

  button:SetScript('OnLeave', function(self)
    background:SetVertexColor(0.2, 0.2, 0.2, 1) -- Dark gray when not hovered
    GameTooltip:Hide()
  end)

  -- Add functionality to the button
  button:SetScript('OnClick', function() on_click_action() end)
end

function create_item_roll_frame()
  local frame = CreateFrame('Frame', 'item_roll_frame', UIParent)
  frame:SetWidth(config.FRAME_WIDTH)
  frame:SetHeight(config.FRAME_HEIGHT)
  frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
  frame:SetBackdrop({
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
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

  create_close_button(frame)

  local action_button_settings = {
    {
      text = 'SR/MS',
      tooltip = 'Roll for Soft Reserve or Main Spec',
      roll = function() RandomRoll(1, 100) end,
      width_multiplier = 2.2
    }, {
      text = 'OS',
      tooltip = 'Roll for Off Spec',
      roll = function() RandomRoll(1, 99) end,
      width_multiplier = 1.2
    }, {
      text = 'TM',
      tooltip = 'Roll for Trasmog',
      roll = function() RandomRoll(1, 50) end,
      width_multiplier = 1.2
    }
  }

  total_button_width = 0
  local button_space_before = 0

  for i, settings in ipairs(action_button_settings) do
    settings.button_space_before = button_space_before
    lb_print(button_space_before)
    total_button_width = total_button_width +
                           (config.BUTTON_WIDTH * settings.width_multiplier)

    button_space_before = button_space_before +
                            (config.BUTTON_WIDTH * settings.width_multiplier)
  end

  for i, settings in ipairs(action_button_settings) do
    create_action_button(frame, settings.text, settings.tooltip, i,
                         settings.roll, settings.width_multiplier,
                         settings.button_space_before)
  end

  frame:Hide()

  return frame
end

local function create_clickable_text(parent, text, player_name)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetWidth(config.FRAME_WIDTH - 20)
  btn:SetHeight(config.CLICKABLE_TEXT_HEIGHT * 2) -- Double height for two lines

  -- Set button font
  local font_string = btn:CreateFontString(nil, "OVERLAY")
  font_string:SetFont(config.FONT_NAME, config.CLICKABLE_TEXT_FONT_SIZE,
                      config.FONT_OUTLINE)
  font_string:SetPoint("LEFT", btn, "LEFT", 5, -1.5)
  font_string:SetText(text)
  font_string:SetJustifyH("LEFT")
  font_string:SetJustifyV("TOP")
  -- add shadow to the font
  font_string:SetShadowOffset(2, -2)

  btn:SetFontString(font_string)
  -- Highlight effect when hovered
  btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  btn:GetHighlightTexture():SetWidth(config.FRAME_WIDTH * 0.8)

  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  btn:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" then
      increase_plus_one(player_name)
    elseif arg1 == "RightButton" then
      reduce_plus_one(player_name)
    end
    update_text_area(item_roll_frame)
  end)

  return btn
end

local function create_text_area(frame)
  local text_area = CreateFrame("Frame", nil, frame)
  text_area:SetHeight(150)
  text_area:SetWidth(300)
  text_area:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, -80)
  text_area.text_lines = {}
  return text_area
end

function update_text_area(frame)
  if not frame.text_area then frame.text_area = create_text_area(frame) end
  local text_area = frame.text_area

  for _, btn in ipairs(text_area.text_lines) do btn:Hide() end
  text_area.text_lines = {}

  local text = ''
  local colored_msg = ''
  local count = 0
  local y_offset = 0
  sort_rolls()

  -- helper function to process each category of messages
  local function process_messages(messages, max_count)
    for _, msg in ipairs(messages) do
      if count >= max_count then break end
      create_roller_message(msg)
      local colored_text = create_color_message(msg)

      local btn = create_clickable_text(text_area, colored_text, msg.roller)
      btn:SetPoint("TOPLEFT", text_area, "TOPLEFT", 10, -y_offset)
      btn:Show()

      table.insert(text_area.text_lines, btn)
      y_offset = y_offset + (config.CLICKABLE_TEXT_HEIGHT * 2) -- Double the height increment
      count = count + 1
    end
  end

  -- Process different message categories
  process_messages(sr_ms_messages, 5)
  process_messages(ms_roll_messages, 5)
  process_messages(sr_os_messages, 5)
  process_messages(os_roll_messages, 5)
  process_messages(tmog_roll_messages, 6)
end

local function init_item_info(frame)
  -- Create the texture for the item icon
  local icon = frame:CreateTexture()
  icon:SetWidth(40) -- Size of the icon
  icon:SetHeight(40) -- Size of the icon
  icon:SetPoint('TOP', frame, 'TOP', 0, -10)

  -- Create a button for mouse interaction
  local icon_button = CreateFrame('Button', nil, frame)
  icon_button:SetWidth(40) -- Size of the icon
  icon_button:SetHeight(40) -- Size of the icon
  icon_button:SetPoint('TOP', frame, 'TOP', 0, -10)

  -- Create a FontString for the frame hide timer
  local timer_text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  timer_text:SetPoint('CENTER', frame, 'TOPLEFT', 30, -32)
  timer_text:SetFont(timer_text:GetFont(), 20)

  -- Create a FontString for the item name
  local name = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  name:SetPoint('TOP', icon, 'BOTTOM', 0, -10)

  frame.icon = icon
  frame.iconButton = icon_button
  frame.timerText = timer_text
  frame.name = name
  frame.itemLink = ''

  local tt = CreateFrame('GameTooltip', 'CustomTooltip2', UIParent,
                         'GameTooltipTemplate')

  -- Set up tooltip
  icon_button:SetScript('OnEnter', function()
    tt:SetOwner(icon_button, 'ANCHOR_RIGHT')
    tt:SetHyperlink(frame.itemLink)
    tt:Show()
  end)
  icon_button:SetScript('OnLeave', function() tt:Hide() end)
  icon_button:SetScript('OnClick', function()
    if (IsControlKeyDown()) then
      DressUpItemLink(frame.itemLink);
    elseif (IsShiftKeyDown() and ChatFrameEditBox:IsVisible()) then
      local item_name, item_link, item_quality, _, _, _, _, _, item_icon =
        GetItemInfo(frame.itemLink)
      ChatFrameEditBox:Insert(config.ITEM_QUALITY_COLORS[item_quality].hex ..
                                '\124H' .. item_link .. '\124h[' .. item_name ..
                                ']\124h' .. config.FONT_COLOR_CODE_CLOSE);
    end
  end)
end

-- Function to return colored text based on item quality
local function get_colored_text_by_quality(text, quality_index)
  -- Get the color associated with the item quality
  local r, g, b, hex = GetItemQualityColor(quality_index)
  -- Return the text wrapped in WoW's color formatting
  return string.format('%s%s|r', hex, text)
end

local function set_item_info(frame, item_link_arg)
  local item_name, item_link, item_quality, _, _, _, _, _, item_icon =
    GetItemInfo(item_link_arg)

  if item_name == config.GRESSIL and not greesil_sound_played then
    greesil_sound_played = true
    play_sound()
  end

  if not frame.icon then init_item_info(frame) end

  -- if we know the item, and the quality isn't green+, don't show it
  if item_name and item_quality < 2 then return false end
  if not item_icon then
    frame.icon:SetTexture('Interface\\Icons\\INV_Misc_QuestionMark')
    frame.name:SetText('Unknown item, attempting to query...')
    -- could be an item we want to see, try to show it
    return true
  end

  frame.icon:SetTexture(item_icon)
  frame.iconButton:SetNormalTexture(item_icon) -- Sets the same texture as the icon

  frame.name:SetText(get_colored_text_by_quality(item_name, item_quality))

  frame.itemLink = item_link
  return true
end

function show_frame(frame, duration, item)
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
      roll_messages = {}
      is_rolling = false
      if FrameAutoClose then frame:Hide() end
    end
    if times > 0 and item_query < 0 and not check_item(item) then
      times = times - 1
    else
      if not set_item_info(item_roll_frame, item) then frame:Hide() end
      times = 5
    end
  end)
  frame:Show()
end

function get_class_of_roller(roller_name)
  -- Iterate through the raid roster
  for i = 1, GetNumRaidMembers() do
    local name, rank, subgroup, level, class, file_name, zone, online, is_dead,
          role, isML = GetRaidRosterInfo(i)
    if name == roller_name then
      return class -- Return the class as a string (e.g., 'Warrior', 'Mage')
    end
  end
  return 'unknown' -- Return nil if the player is not found in the raid
end

function extract_item_links_from_message(message)
  local item_links = {}
  -- This pattern matches the standard item link structure in WoW
  for link in string.gfind(message, '|c.-|H(item:.-)|h.-|h|r') do
    table.insert(item_links, link)
  end
  return item_links
end

function create_text_box_frame()
  local frame_backdrop = {
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
    tile = true,
    tileSize = 16
  }

  local control_backdrop = {
    bgFile = 'Interface\\Tooltips\\UI-Tooltip-Background',
    edgeFile = 'Interface\\Tooltips\\UI-Tooltip-Border',
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 3, right = 3, top = 3, bottom = 3}
  }

  local frame = CreateFrame('Frame', 'load_sr_from_text_frame', UIParent)
  frame:Hide()
  frame:SetWidth(565)
  frame:SetHeight(300)
  frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
  frame:EnableMouse()
  frame:SetMovable(true)
  frame:SetResizable(true)
  frame:SetFrameStrata('DIALOG')

  frame:SetBackdrop(frame_backdrop)
  frame:SetBackdropColor(0, 0, 0, 1)

  frame:SetMinResize(400, 200)
  frame:SetToplevel(true)

  local backdrop = CreateFrame('Frame', nil, frame)
  backdrop:SetBackdrop(control_backdrop)
  backdrop:SetBackdropColor(0, 0, 0)
  backdrop:SetBackdropBorderColor(0.4, 0.4, 0.4)

  backdrop:SetPoint('TOPLEFT', frame, 'TOPLEFT', 17, -18)
  backdrop:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -17, 43)

  local scroll_frame = CreateFrame('ScrollFrame', "a@ScrollFrame@c", backdrop,
                                   'UIPanelScrollFrameTemplate')
  scroll_frame:SetPoint('TOPLEFT', 5, -6)
  scroll_frame:SetPoint('BOTTOMRIGHT', -28, 6)
  scroll_frame:EnableMouse(true)

  local scroll_child = CreateFrame('Frame', nil, scroll_frame)
  scroll_frame:SetScrollChild(scroll_child)
  scroll_child:SetHeight(2)
  scroll_child:SetWidth(2)

  local edit_box = CreateFrame('EditBox', nil, scroll_child)
  edit_box:SetPoint('TOPLEFT', 0, 0)
  edit_box:SetHeight(50)
  edit_box:SetWidth(50)
  edit_box:SetMultiLine(true)
  edit_box:SetTextInsets(5, 5, 3, 3)
  edit_box:EnableMouse(true)
  edit_box:SetAutoFocus(false)
  edit_box:SetFontObject('ChatFontNormal')
  frame.editbox = edit_box

  edit_box:SetScript('OnEscapePressed', function() frame:Hide() end)
  scroll_frame:SetScript('OnMouseUp', function() edit_box:SetFocus() end)

  local function fix_size()
    scroll_child:SetHeight(scroll_frame:GetHeight())
    scroll_child:SetWidth(scroll_frame:GetWidth())
    edit_box:SetWidth(scroll_frame:GetWidth())
  end

  scroll_frame:SetScript('OnShow', fix_size)
  scroll_frame:SetScript('OnSizeChanged', fix_size)

  -- Clear SRs button
  local clear_button =
    CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
  clear_button:SetScript('OnClick', function()
    edit_box:SetText('')
    SRList = {}
  end)
  clear_button:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -27, 17)
  clear_button:SetHeight(20)
  clear_button:SetWidth(100)
  clear_button:SetText('Clear SRs!')

  -- Import SRs button (positioned left of Clear)
  local import_button = CreateFrame('Button', nil, frame,
                                    'UIPanelButtonTemplate')
  import_button:SetScript('OnClick', function()
    current_sr_text = edit_box:GetText()
    load_sr_from_csv()
    frame:Hide()
  end)
  import_button:SetPoint('RIGHT', clear_button, 'LEFT', -10, 0)
  import_button:SetHeight(20)
  import_button:SetWidth(110)
  import_button:SetText('Import SRs!')

  -- Reset +1 button (positioned left of Import)
  local reset_plus_one = CreateFrame('Button', nil, frame,
                                     'UIPanelButtonTemplate')
  reset_plus_one:SetScript('OnClick', function()
    PlusOneList = {}
    edit_box:SetText('')
  end)
  reset_plus_one:SetPoint('RIGHT', import_button, 'LEFT', -10, 0)
  reset_plus_one:SetHeight(20)
  reset_plus_one:SetWidth(100)
  reset_plus_one:SetText('Reset +1!')

  edit_box:SetScript("OnTextChanged",
                     function(_) scroll_frame:UpdateScrollChildRect() end)
  create_close_button(frame, 'TOPRIGHT', -2, -2)

  local check_box = CreateFrame('CheckButton', 'FrameAutoClose', frame,
                                'UICheckButtonTemplate')
  check_box:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 10, 10)
  getglobal(check_box:GetName() .. 'Text'):SetText(
    'Reset PO after importing SRs');
  check_box.tooltip = 'Reset PO after importing SRs'
  check_box:SetScript('OnClick', function()
    ResetPOAfterImportingSR = check_box:GetChecked() == 1
  end)

  frame:RegisterEvent('OnShow')
  frame:SetScript('OnShow',
                  function() check_box:SetChecked(ResetPOAfterImportingSR) end)

  return frame
end
