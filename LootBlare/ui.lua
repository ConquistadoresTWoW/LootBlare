total_button_width = 0

local function create_top_button(frame, position, xOffset, yOffset,
                                 normal_texture_path, pushed_texture_path,
                                 highlight_texture_path, action)
  -- Default values if not provided
  position = position or 'TOPRIGHT'
  xOffset = xOffset or -7
  yOffset = yOffset or -7
  normal_texture_path = normal_texture_path or
                          "Interface\\AddOns\\LootBlare\\assets\\close.tga"
  pushed_texture_path = pushed_texture_path or
                          "Interface\\AddOns\\LootBlare\\assets\\close2.tga"
  highlight_texture_path = highlight_texture_path or
                             "Interface\\AddOns\\LootBlare\\assets\\close2.tga"
  action = action or function() frame:Hide() end
  -- default texture_color to red
  texture_color = texture_color or {1, 0, 0, 1}

  -- Add a custom close button
  local button = CreateFrame('Button', nil, frame)
  button:SetWidth(16) -- Button size
  button:SetHeight(16) -- Button size
  button:SetPoint(position, frame, position, xOffset, yOffset) -- Custom position

  -- Set normal texture
  local normal_texture = button:CreateTexture(nil, 'BACKGROUND')
  normal_texture:SetTexture(normal_texture_path)
  normal_texture:SetAllPoints(button)
  button:SetNormalTexture(normal_texture)

  -- Set pushed texture
  local pushed_texture = button:CreateTexture(nil, 'BACKGROUND')
  pushed_texture:SetTexture(pushed_texture_path)
  pushed_texture:SetAllPoints(button)
  button:SetPushedTexture(pushed_texture)

  -- Set highlight texture
  local highlight_texture = button:CreateTexture(nil, 'HIGHLIGHT')
  highlight_texture:SetTexture(highlight_texture_path)
  highlight_texture:SetAllPoints(button)
  button:SetHighlightTexture(highlight_texture)

  -- Hide the frame when the button is clicked
  button:SetScript('OnClick', action)

  return button
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

  create_top_button(frame)
  local main_over_alts_button = CreateFrame('Button', nil, frame,
                                            'UIPanelButtonTemplate')

  local ICON_ENABLED = 'Interface\\AddOns\\LootBlare\\assets\\moa_on.tga'
  local ICON_DISABLED = 'Interface\\AddOns\\LootBlare\\assets\\moa_off.tga'

  main_over_alts_button:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', -27, -7)
  main_over_alts_button:SetWidth(16) -- Button size
  main_over_alts_button:SetHeight(16) -- Button size

  local moa = true
  if Settings ~= nil then moa = Settings.PrioMainOverAlts end

  local normal_texture = main_over_alts_button:CreateTexture(nil, 'BACKGROUND')
  normal_texture:SetTexture(moa and ICON_ENABLED or ICON_DISABLED)
  normal_texture:SetAllPoints(main_over_alts_button)
  main_over_alts_button:SetNormalTexture(normal_texture)

  -- add moa_button tooltip
  main_over_alts_button:SetScript('OnEnter', function(self)
    GameTooltip:SetOwner(main_over_alts_button, 'ANCHOR_RIGHT')
    local text = Settings.PrioMainOverAlts and 'Enabled' or 'Disabled'
    GameTooltip:AddLine('Prioritize main over alts: ' .. text, nil, nil, nil,
                        true)
    GameTooltip:Show()
  end)
  main_over_alts_button:SetScript('OnLeave',
                                  function(self) GameTooltip:Hide() end)

  function update_moa_button_texture()
    -- change the texture of the button to show current state
    local normal_texture =
      main_over_alts_button:CreateTexture(nil, 'BACKGROUND')
    normal_texture:SetTexture(Settings.PrioMainOverAlts and ICON_ENABLED or
                                ICON_DISABLED)
    normal_texture:SetAllPoints(main_over_alts_button)
    main_over_alts_button:SetNormalTexture(normal_texture)
  end

  -- set highlight texture
  local highlight_texture =
    main_over_alts_button:CreateTexture(nil, 'HIGHLIGHT')
  highlight_texture:SetTexture(moa and ICON_ENABLED or ICON_DISABLED)
  highlight_texture:SetAllPoints(main_over_alts_button)
  main_over_alts_button:SetHighlightTexture(highlight_texture)

  main_over_alts_button:SetScript('OnClick', function()
    if master_looter == UnitName('player') then
      Settings.PrioMainOverAlts = not Settings.PrioMainOverAlts
      send_ml_settings()
      update_moa_button_texture()
      update_text_area(item_roll_frame)
    else
      lb_print('You are not the master looter')
    end

  end)

  -- on show update the button texture
  frame:SetScript('OnShow', function() update_moa_button_texture() end)

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
  config.CLICKABLE_TEXT_HEIGHT = Settings.CustomFontSize + 3
  btn:SetWidth(config.FRAME_WIDTH - 20)
  btn:SetHeight(config.CLICKABLE_TEXT_HEIGHT * 2) -- Double height for two lines

  -- Set button font
  local font_string = btn:CreateFontString(nil, "OVERLAY")
  font_string:SetFont(config.FONT_NAME, Settings.CustomFontSize,
                      config.FONT_OUTLINE)
  font_string:SetPoint("LEFT", btn, "LEFT", 5, -1.5)
  font_string:SetText(text)
  font_string:SetJustifyH("LEFT")
  font_string:SetJustifyV("TOP")
  -- add shadow to the font
  font_string:SetShadowOffset(1, -1)

  btn:SetFontString(font_string)
  -- Highlight effect when hovered
  btn:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
  btn:GetHighlightTexture():SetWidth(config.FRAME_WIDTH * 0.8)

  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")

  btn:SetScript("OnMouseUp", function()
    if arg1 == "LeftButton" and IsShiftKeyDown() then
      increase_plus_one_and_whisper_os_payment(player_name, current_link)
    elseif arg1 == "LeftButton" then
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
    config.CLICKABLE_TEXT_HEIGHT = Settings.CustomFontSize + 3
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
  duration = tonumber(duration)
  frame:SetScript('OnUpdate', function()
    time_elapsed = time_elapsed + arg1
    item_query = item_query - arg1
    if frame.timerText then
      frame.timerText:SetText(format('%.1f', duration - time_elapsed))
    end

    if time_elapsed >= duration - 3 and time_elapsed < duration - 2 and
      not seconds_3 then
      seconds_3 = true
      run_if_master_looter(function() SendChatMessage('3', 'RAID') end, false)
    elseif time_elapsed >= duration - 2 and time_elapsed < duration - 1 and
      not seconds_2 then
      seconds_2 = true
      run_if_master_looter(function() SendChatMessage('2', 'RAID') end, false)
    elseif time_elapsed >= duration - 1 and time_elapsed < duration and
      not seconds_1 then
      seconds_1 = true
      run_if_master_looter(function() SendChatMessage('1', 'RAID') end, false)
    end

    if time_elapsed >= duration then
      run_if_master_looter(function()
        SendChatMessage('Roll time ended!', 'RAID')
      end, false)
      frame:SetScript('OnUpdate', nil)
      time_elapsed = 0
      item_query = 1.5
      times = 3
      roll_messages = {}
      is_rolling = false
      seconds_3 = false
      seconds_2 = false
      seconds_1 = false
      if Settings.FrameAutoClose then frame:Hide() end
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

function create_import_sr_frame()
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
    LastRaidData.AlreadyLooted = {}
    LastRaidData.RaidName = ''
    LastRaidData.RaidTime = 0
    edit_box:SetText('')
  end)
  reset_plus_one:SetPoint('RIGHT', import_button, 'LEFT', -10, 0)
  reset_plus_one:SetHeight(20)
  reset_plus_one:SetWidth(100)
  reset_plus_one:SetText('Reset +1!')

  edit_box:SetScript("OnTextChanged",
                     function(_) scroll_frame:UpdateScrollChildRect() end)
  create_top_button(frame, 'TOPRIGHT', -2, -2)

  return frame
end

function create_settings_frame()
  local frame = CreateFrame('Frame', 'settings_frame', UIParent)
  frame:SetWidth(300)
  frame:SetHeight(420)
  frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
  frame:SetBackdrop({
    bgFile = 'Interface/Tooltips/UI-Tooltip-Background',
    tile = true,
    tileSize = 16,
    edgeSize = 16,
    insets = {left = 4, right = 4, top = 4, bottom = 4}
  })
  frame:SetBackdropColor(0, 0, 0, 1)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag('LeftButton') -- Only start dragging with the left mouse button
  frame:SetScript('OnDragStart', function() frame:StartMoving() end)
  frame:SetScript('OnDragStop', function() frame:StopMovingOrSizing() end)

  -- add titel to the frame
  local title = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  title:SetPoint('CENTER', frame, 'TOP', 0, -20)
  title:SetFont(title:GetFont(), 12)
  title:SetText('General Settings')

  -- local settings
  -- add edit box to set font size
  local font_size_edit_box = CreateFrame('EditBox', nill, frame,
                                         'InputBoxTemplate')
  font_size_edit_box:SetPoint('TOPLEFT', frame, 'TOPLEFT', 30, -35)
  font_size_edit_box:SetWidth(20)
  font_size_edit_box:SetHeight(15)
  font_size_edit_box:SetAutoFocus(false)
  font_size_edit_box:SetFontObject('ChatFontNormal')
  font_size_edit_box:SetAutoFocus(false)
  font_size_edit_box:SetNumeric(true)
  local font_size_label = frame:CreateFontString(nil, 'OVERLAY',
                                                 'GameFontNormal')
  font_size_label:SetPoint('LEFT', font_size_edit_box, 'RIGHT', 5, 0)
  font_size_label:SetText('Font size')
  -- add edit box to set frame auto close
  local frame_auto_close_cb = CreateFrame('CheckButton', 'ac_cb', frame,
                                          'UICheckButtonTemplate')
  frame_auto_close_cb:SetPoint('TOPLEFT', font_size_edit_box, 'BOTTOMLEFT', -10,
                               -10)

  getglobal(frame_auto_close_cb:GetName() .. 'Text'):SetText('Auto close frame');
  frame_auto_close_cb.tooltip = 'Auto close frame'

  -- hide when using spell
  local hwus_cb = CreateFrame('CheckButton', 'hwus_cb', frame,
                              'UICheckButtonTemplate')
  hwus_cb:SetPoint('TOPLEFT', frame_auto_close_cb, 'BOTTOMLEFT', 0, 0)
  getglobal(hwus_cb:GetName() .. 'Text'):SetText('Hide when using spell');
  hwus_cb.tooltip = 'Hide when using spell'

  -- ML settings
  -- Add label roll settings (master looter)
  local ml_label = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  ml_label:SetPoint('CENTER', frame, 'TOP', 0, -150)
  ml_label:SetFont(ml_label:GetFont(), 12)
  ml_label:SetText('Master Looter Settings')

  -- show current master looter read Only
  local ml_text = frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  ml_text:SetPoint('TOPLEFT', frame, 'TOPLEFT', 20, -170)

  ml_text:SetFont(ml_text:GetFont(), 12)
  ml_text:SetText('Current ML: Unknown')

  -- roll duration 
  local frame_duration_edit_box = CreateFrame('EditBox',
                                              'frame_duration_edit_box', frame,
                                              'InputBoxTemplate')
  frame_duration_edit_box:SetPoint('TOPLEFT', ml_text, 'BOTTOMLEFT', 10, -15)
  frame_duration_edit_box:SetWidth(20)
  frame_duration_edit_box:SetHeight(15)
  frame_duration_edit_box:SetAutoFocus(false)
  frame_duration_edit_box:SetFontObject('ChatFontNormal')
  frame_duration_edit_box:SetNumeric(true)
  local frame_duration_label = frame:CreateFontString(nil, 'OVERLAY',
                                                      'GameFontNormal')
  frame_duration_label:SetPoint('LEFT', frame_duration_edit_box, 'RIGHT', 5, 0)
  frame_duration_label:SetText('Roll duration (s)')

  -- prio mains over alts
  local prio_main_over_alts_cb = CreateFrame('CheckButton', 'pmoa_cb', frame,
                                             'UICheckButtonTemplate')
  prio_main_over_alts_cb:SetPoint('TOPLEFT', frame_duration_edit_box,
                                  'BOTTOMLEFT', -10, -10)
  getglobal(prio_main_over_alts_cb:GetName() .. 'Text'):SetText(
    'Prioritize main over alts');
  prio_main_over_alts_cb.tooltip = 'Prioritize mains over alts'

  -- reset after importing SRs
  local reset_po_after_importing_sr_cb =
    CreateFrame('CheckButton', 'rpoasr_cb', frame, 'UICheckButtonTemplate')
  reset_po_after_importing_sr_cb:SetPoint('TOPLEFT', prio_main_over_alts_cb,
                                          'BOTTOMLEFT', 0, 0)
  getglobal(reset_po_after_importing_sr_cb:GetName() .. 'Text'):SetText(
    'Reset PO after importing SRs');
  reset_po_after_importing_sr_cb.tooltip = 'Reset PO after importing SRs'

  -- loot announce on or off
  local loot_announce_cb = CreateFrame('CheckButton', 'loot_announce_cb', frame,
                                       'UICheckButtonTemplate')
  loot_announce_cb:SetPoint('TOPLEFT', reset_po_after_importing_sr_cb,
                            'BOTTOMLEFT', 0, 0)
  getglobal(loot_announce_cb:GetName() .. 'Text'):SetText(
    'Loot announce on or off');
  loot_announce_cb.tooltip = 'Loot announce on or off'

  -- min quality for items to announce in chat
  local loot_announce_min_quality_edit_box =
    CreateFrame('EditBox', 'loot_announce_min_quality_edit_box', frame,
                'InputBoxTemplate')
  loot_announce_min_quality_edit_box:SetPoint('TOPLEFT', loot_announce_cb,
                                              'BOTTOMLEFT', 10, -10)
  loot_announce_min_quality_edit_box:SetWidth(20)
  loot_announce_min_quality_edit_box:SetHeight(15)
  loot_announce_min_quality_edit_box:SetAutoFocus(false)
  loot_announce_min_quality_edit_box:SetFontObject('ChatFontNormal')
  loot_announce_min_quality_edit_box:SetNumeric(true)
  local loot_announce_min_quality_label =
    frame:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
  loot_announce_min_quality_label:SetPoint('LEFT',
                                           loot_announce_min_quality_edit_box,
                                           'RIGHT', 5, 0)
  loot_announce_min_quality_label:SetText('Loot announce min quality (0-4)')

  -- do not disturb while being master looter cb
  local dnd_cb = CreateFrame('CheckButton', 'dnd_cb', frame,
                             'UICheckButtonTemplate')
  dnd_cb:SetPoint('TOPLEFT', loot_announce_min_quality_edit_box, 'BOTTOMLEFT',
                  -10, -10)
  getglobal(dnd_cb:GetName() .. 'Text'):SetText('Block whispers while being ML');
  dnd_cb.tooltip = 'Block whispers while being ML'

  frame:RegisterEvent('OnShow')
  frame:SetScript('OnShow', function()
    if master_looter ~= UnitName('player') then
      prio_main_over_alts_cb:Disable()
      reset_po_after_importing_sr_cb:Disable()
      reset_po_after_importing_sr_cb:Hide()
      loot_announce_min_quality_edit_box:Hide()
      loot_announce_min_quality_label:Hide()
      loot_announce_cb:Disable()
      loot_announce_cb:Hide()
      dnd_cb:Disable()
      dnd_cb:Hide()
    else
      prio_main_over_alts_cb:Enable()
      reset_po_after_importing_sr_cb:Enable()
      reset_po_after_importing_sr_cb:Show()
      loot_announce_min_quality_edit_box:Show()
      loot_announce_cb:Enable()
      loot_announce_cb:Show()
      loot_announce_min_quality_label:Show()
      dnd_cb:Enable()
      dnd_cb:Show()
    end

    local current_ml = master_looter or 'unknown'
    font_size_edit_box:SetText(Settings.CustomFontSize)
    frame_auto_close_cb:SetChecked(Settings.FrameAutoClose)
    hwus_cb:SetChecked(Settings.HideWhenUsingSpell)
    ml_text:SetText('Current ML: ' .. current_ml)
    frame_duration_edit_box:SetText(Settings.RollDuration)
    reset_po_after_importing_sr_cb:SetChecked(Settings.ResetPOAfterImportingSR)
    prio_main_over_alts_cb:SetChecked(Settings.PrioMainOverAlts)
    loot_announce_cb:SetChecked(Settings.LootAnnounceActive)
    loot_announce_min_quality_edit_box:SetText(
      Settings.LootAnnounceMinQuality or 4)
    dnd_cb:SetChecked(Settings.DNDMode or false)
  end)

  local save_button = CreateFrame('Button', nil, frame, 'UIPanelButtonTemplate')
  save_button:SetScript('OnClick', function()
    -- Save the settings
    Settings.CustomFontSize = font_size_edit_box:GetText()
    Settings.FrameAutoClose = frame_auto_close_cb:GetChecked() == 1
    Settings.HideWhenUsingSpell = hwus_cb:GetChecked() == 1

    -- master looter actions
    if master_looter == UnitName('player') then
      Settings.RollDuration = frame_duration_edit_box:GetText()
      Settings.ResetPOAfterImportingSR =
        reset_po_after_importing_sr_cb:GetChecked() == 1
      Settings.PrioMainOverAlts = prio_main_over_alts_cb:GetChecked() == 1
      Settings.LootAnnounceActive = loot_announce_cb:GetChecked() == 1
      Settings.LootAnnounceMinQuality =
        loot_announce_min_quality_edit_box:GetText()
      send_ml_settings()
      Settings.DNDMode = dnd_cb:GetChecked() == 1
    end

    lb_print('Settings saved!')
    frame:Hide()
  end)
  save_button:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 10)
  save_button:SetHeight(20)
  save_button:SetWidth(100)
  save_button:SetText('Save Settings!')

  -- Close button
  create_top_button(frame, 'TOPRIGHT', -10, -10)

  frame:Hide()

  return frame

end
