function handle_chat_message(event, message, sender)
  if (event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER') then
    local _, _, duration =
      string.find(message, 'Roll time set to (%d+) seconds')
    duration = tonumber(duration)
    if duration and duration ~= FrameShownDuration then
      FrameShownDuration = duration
      -- The players get the new duration from the master looter after the first rolls
      lb_print('Rolling duration set to ' .. FrameShownDuration ..
                 ' seconds. (set by Master Looter)')
    end
  elseif event == 'CURRENT_SPELL_CAST_CHANGED' and HideWhenUsingSpell and
    time_elapsed == 0 then
    item_roll_frame:Hide()
  elseif event == 'CHAT_MSG_SYSTEM' then
    local _, _, new_ml = string.find(message, '(%S+) is now the loot master')
    if new_ml then
      master_looter = new_ml
      player_name = UnitName('player')
      -- if the player is the new master looter, announce the roll time
      if new_ml == player_name then
        SendAddonMessage(config.LB_PREFIX, config.LB_SET_ROLL_TIME ..
                           FrameShownDuration .. ' seconds', 'RAID')
      end
    elseif is_rolling and string.find(message, 'rolls') and
      string.find(message, '(%d+)') then
      local _, _, roller, roll, min_roll, max_roll =
        string.find(message, '(%S+) rolls (%d+) %((%d+)%-(%d+)%)')
      if roller and roll and rollers[roller] == nil then
        roll = tonumber(roll)
        rollers[roller] = 1
        message = {
          roller = roller,
          roll = roll,
          msg = message,
          class = get_class_of_roller(roller)
        }
        if max_roll == '101' then
          table.insert(sr_roll_messages, message)
        elseif max_roll == '100' then
          table.insert(ms_roll_messages, message)
        elseif max_roll == '99' then
          table.insert(os_roll_messages, message)
        elseif max_roll == '50' then
          table.insert(tmog_roll_messages, message)
        end
        update_text_area(item_roll_frame)
      end
    end

  elseif event == 'CHAT_MSG_RAID_WARNING' and sender == master_looter then
    local links = extract_item_links_from_message(message)
    if get_table_size(links) == 1 then
      -- these if are not being used RN. I'm just leaving them here for future reference
      if string.find(message, '^No one has need:') or
        string.find(message, 'has been sent to') or
        string.find(message, ' received ') then
        item_roll_frame:Hide()
        return
      elseif string.find(message, 'Rolling Cancelled') or -- usually a cancel is accidental in my experience
        string.find(message, 'seconds left to roll') or
        string.find(message, 'Rolling is now Closed') then
        return
      end
      reset_rolls()
      update_text_area(item_roll_frame)
      time_elapsed = 0
      is_rolling = true
      show_frame(item_roll_frame, FrameShownDuration, links[1])
    end
  elseif event == 'ADDON_LOADED' then
    if FrameShownDuration == nil then FrameShownDuration = 15 end
    if FrameAutoClose == nil then FrameAutoClose = true end
    if HideWhenUsingSpell == nil then HideWhenUsingSpell = false end
    if is_sender_master_looter(UnitName('player')) then
      SendAddonMessage(config.LB_PREFIX, config.LB_SET_ML .. UnitName('player'),
                       'RAID')
      SendAddonMessage(config.LB_PREFIX,
                       config.LB_SET_ROLL_TIME .. FrameShownDuration, 'RAID')
      item_roll_frame:UnregisterEvent('ADDON_LOADED')
    else
      SendAddonMessage(config.LB_PREFIX, config.LB_GET_DATA, 'RAID')
    end
  elseif event == 'CHAT_MSG_ADDON' and arg1 == config.LB_PREFIX then
    local prefix, message, channel, sender = arg1, arg2, arg3, arg4

    -- Someone is asking for the master looter and his roll time
    if message == config.LB_GET_DATA and
      is_sender_master_looter(UnitName('player')) then
      master_looter = UnitName('player')
      SendAddonMessage(config.LB_PREFIX, config.LB_SET_ML .. master_looter,
                       'RAID')
      SendAddonMessage(config.LB_PREFIX,
                       config.LB_SET_ROLL_TIME .. FrameShownDuration, 'RAID')
    end

    -- Someone is setting the master looter
    if string.find(message, config.LB_SET_ML) then
      local _, _, new_ml = string.find(message, 'ML set to (%S+)')
      master_looter = new_ml
    end
    -- Someone is setting the roll time
    if string.find(message, config.LB_SET_ROLL_TIME) then
      local _, _, duration = string.find(message, 'Roll time set to (%d+)')
      duration = tonumber(duration)
      if duration and duration ~= FrameShownDuration then
        FrameShownDuration = duration
        lb_print('Roll time set to ' .. FrameShownDuration .. ' seconds.')
      end
    end
  end
end

function handle_config_command(msg)
  if msg == '' then
    if item_roll_frame:IsVisible() then
      item_roll_frame:Hide()
    else
      item_roll_frame:Show()
    end
  elseif msg == 'help' then
    lb_print(
      'LootBlare is a simple addon that displays and sort item rolls in a frame.')
    lb_print(
      'Type /lb time <seconds> to set the duration the frame is shown. This value will be automatically set by the master looter after the first rolls.')
    lb_print(
      'Type /lb autoClose on/off to enable/disable auto closing the frame after the time has elapsed.')
    lb_print('Type /lb settings to see the current settings.')
  elseif msg == 'settings' then
    lb_print('Frame shown duration: ' .. FrameShownDuration .. ' seconds.')
    lb_print('Auto closing: ' .. (FrameAutoClose and 'on' or 'off'))
    lb_print('Master Looter: ' .. (master_looter or 'unknown'))
  elseif string.find(msg, 'time') then
    local _, _, new_duration = string.find(msg, 'time (%d+)')
    new_duration = tonumber(new_duration)
    if new_duration and new_duration > 0 then
      FrameShownDuration = new_duration
      lb_print('Roll time set to ' .. new_duration .. ' seconds.')
      if is_sender_master_looter(UnitName('player')) then
        SendAddonMessage(config.LB_PREFIX,
                         config.LB_SET_ROLL_TIME .. new_duration, 'RAID')
      end
    else
      lb_print('Invalid duration. Please enter a number greater than 0.')
    end
  elseif string.find(msg, 'autoClose') then
    local _, _, auto_close = string.find(msg, 'autoClose (%a+)')
    if auto_close == 'on' then
      lb_print('Auto closing enabled.')
      FrameAutoClose = true
    elseif auto_close == 'off' then
      lb_print('Auto closing disabled.')
      FrameAutoClose = false
    else
      lb_print('Invalid option. Please enter \'on\' or \'off\'.')
    end
  elseif string.find(msg, 'hideWhenUsingSpell') then
    local _, _, hide = string.find(msg, 'hideWhenUsingSpell (%a+)')
    if hide == 'on' then
      lb_print('Hiding frame when using a spell enabled.')
      HideWhenUsingSpell = true
    elseif hide == 'off' then
      lb_print('Hiding frame when using a spell disabled.')
      HideWhenUsingSpell = false
    else
      lb_print('Invalid option. Please enter \'on\' or \'off\'.')
    end
  else
    lb_print('Invalid command. Type /lb help for a list of commands.')
  end
end
