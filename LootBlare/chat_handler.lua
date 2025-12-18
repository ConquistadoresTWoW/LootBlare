function handle_chat_message(event, message, sender)
  if event == 'CURRENT_SPELL_CAST_CHANGED' and Settings.HideWhenUsingSpell and
    is_rolling == false then
    item_roll_frame:Hide()
  elseif event == 'CHAT_MSG_SYSTEM' then
    local _, _, new_ml = string.find(message, '(%S+) is now the loot master')
    if new_ml then
      master_looter = new_ml
      player_name = UnitName('player')
      -- if the player is the new master looter, send settings
      if new_ml == player_name then send_ml_settings() end
    end
    if is_rolling and sender == UnitName('player') and
      string.find(message, 'rolls') then has_rolled_for_current_item = true end
    if is_rolling and master_looter == UnitName('player') and
      string.find(message, 'rolls') and string.find(message, '(%d+)') then
      local _, _, roller, roll, min_roll, max_roll =
        string.find(message, '(%S+) rolls (%d+) %((%d+)%-(%d+)%)')
      max_roll = tonumber(max_roll)
      if roller and roll and rollers[roller] == nil then
        local has_ms_sr = has_sr(sr_ms_messages, roller)
        local has_os_sr = has_sr(sr_os_messages, roller)
        if (has_ms_sr or has_os_sr) and max_roll ~= 100 then return end
        roll = tonumber(roll)
        rollers[roller] = 1

        message = {
          roller = roller,
          roll = roll,
          class = get_class_of_roller(roller),
          is_high_rank = lb_is_high_rank(roller),
          has_debt = lb_has_debt(roller),
          prio_os = lb_has_prio_os(roller),
          is_alt = AltList[roller] ~= nil,
          plus_one = PlusOneList[roller] or 0,
          has_ms_sr = has_ms_sr,
          has_os_sr = has_os_sr
        }

        if has_ms_sr then
          for i, sr in ipairs(sr_ms_messages) do
            if sr.roller == roller then sr.roll = roll end
          end
        elseif has_os_sr then
          for i, sr in ipairs(sr_os_messages) do
            if sr.roller == roller then sr.roll = roll end
          end
        end

        if not has_ms_sr and not has_os_sr then
          if max_roll == 100 then
            message.roll_type = RollType.MS
            table.insert(ms_roll_messages, message)
          elseif max_roll == 99 then
            message.roll_type = RollType.OS
            table.insert(os_roll_messages, message)
          elseif max_roll == 50 then
            message.roll_type = RollType.TM
            table.insert(tmog_roll_messages, message)
          end
        end
        sort_rolls()
        update_text_area(item_roll_frame)
      end
    end
  elseif event == 'CHAT_MSG_RAID_WARNING' and sender == master_looter and
    not string.find(message, 'Random Rolling') then
    local links = extract_item_links_from_message(message)

    if len(links) == 1 then
      current_link = links[1]
      reset_rolls()
      -- Find and announce soft reserves for this item (new functionality)

      if master_looter ~= UnitName('player') then return end

      local sr_list = find_soft_reservers_for_item(current_link)
      if sr_list and len(sr_list) > 0 then
        -- Group SRs by type (MS/OS) and sort by SR+ value
        local ms_srs = {}
        local os_srs = {}

        for _, sr in ipairs(sr_list) do
          if sr["MS"] then
            table.insert(ms_srs, sr)
          else
            table.insert(os_srs, sr)
          end
        end

        -- Sort by SR+ value (descending)
        table.sort(ms_srs, function(a, b) return a["SR+"] > b["SR+"] end)
        table.sort(os_srs, function(a, b) return a["SR+"] > b["SR+"] end)

        -- Build SR announcement message
        local sr_message = "- SR: "
        local sr_entries = {}

		-- Add MS SRs
		for _, sr in ipairs(ms_srs) do
		local class_color = config.RAID_CLASS_COLORS[get_class_of_roller(
								sr["Attendee"])] or config.DEFAULT_TEXT_COLOR
		local entry = "|c" .. class_color .. sr["Attendee"] .. "|r"
		if sr["SR+"] > 1 then
			entry = entry .. " [" .. sr["SR+"] .. "]"
		end
		table.insert(sr_entries, entry)
		end
		
		-- Add OS SRs
		for _, sr in ipairs(os_srs) do
		local class_color = config.RAID_CLASS_COLORS[get_class_of_roller(
								sr["Attendee"])] or config.DEFAULT_TEXT_COLOR
		local entry = "|c" .. class_color .. sr["Attendee"] .. "|r"
		if sr["SR+"] > 1 then
			entry = entry .. "(OS) [" .. sr["SR+"] .. "]"
		else
			entry = entry .. "(OS)"
		end
		table.insert(sr_entries, entry)
		end

        -- Combine all entries
        sr_message = sr_message .. table.concat(sr_entries, ", ")
        SendChatMessage(sr_message, "RAID", nil, nil)
        insert_sr_rolls(ms_srs, os_srs)
      end
      sort_rolls()
      update_text_area(item_roll_frame)
      SendAddonMessage(config.LB_PREFIX, config.LB_START_ROLL, 'RAID')
    end

    -- item_roll_frame:UnregisterEvent('ADDON_LOADED')
  elseif event == 'CHAT_MSG_ADDON' and arg1 == config.LB_PREFIX then
    local prefix, message, channel, sender = arg1, arg2, arg3, arg4

    -- Someone is asking for the master looter settings
    if message == config.LB_GET_ML_SETTINGS and master_looter ==
      UnitName('player') then send_ml_settings() end

    -- ML is sending settings
    if string.find(message, config.LB_SET_ML_SETTINGS) and sender ~=
      UnitName('player') then
      local _, _, new_settings = string.find(message,
                                             config.LB_SET_ML_SETTINGS .. '(.+)')
      load_ml_settings_from_string(new_settings)
    end

    -- ML is starting a roll
    if sender == master_looter and message == config.LB_START_ROLL then
      update_text_area(item_roll_frame)
      time_elapsed = 0
      is_rolling = true
      show_frame(item_roll_frame, Settings.RollDuration, current_link)
      -- Reset roll tracking
      -- has_rolled_for_current_item = {}
      if update_roll_buttons then update_roll_buttons() end
    end

    if sender == master_looter and message == config.LB_STOP_ROLL then
      is_rolling = false
      time_elapsed = Settings.RollDuration
    end
    -- ML is reseting the SR list for the current item
    if sender == master_looter and sender ~= UnitName('player') then
      if message == config.LB_CLEAR_ROLL_RESULTS then
        reset_rolls()
        update_text_area(item_roll_frame)
      end
      if string.find(message, config.LB_ADD_ROLL_RESULT) then
        local _, _, roll_message_str = string.find(message,
                                                   config.LB_ADD_ROLL_RESULT ..
                                                     '(.+)')
        lb_load_roll_message(roll_message_str)
        update_text_area(item_roll_frame)
      end
    end

  elseif event == 'ADDON_LOADED' and arg1 == 'LootBlare' then
    if Settings == nil then
      Settings = {
        RollDuration = 15,
        FrameAutoClose = false,
        HideWhenUsingSpell = false,
        ResetPOAfterImportingSR = true,
        CustomFontSize = config.CLICKABLE_TEXT_FONT_SIZE,
        PrioMainOverAlts = true,
        LootAnnounceActive = true,
        LootAnnounceMinQuality = 4, -- Epic
        DNDMode = false
      }
    end
    if Settings.LootAnnounceActive == nil then
      Settings.LootAnnounceActive = true
    end

    if Settings.LootAnnounceMinQuality == nil then
      Settings.LootAnnounceMinQuality = 4 -- Epic
    end

    if AltList == nil then AltList = {} end
    if SRList == nil then SRList = {} end
    if PlusOneList == nil then PlusOneList = {} end
    if LastRaidData == nil then
      LastRaidData = {RaidName = '', RaidTime = 0, AlreadyLooted = {}}
    end

    if is_master_looter(UnitName('player')) then
      master_looter = UnitName('player')
      send_ml_settings()
    else
      SendAddonMessage(config.LB_PREFIX, config.LB_GET_ML_SETTINGS, 'RAID')
    end

    if len(lb_guild_info) == 0 then lb_load_guild_info() end
  elseif event == 'ZONE_CHANGED_NEW_AREA' then
    reset_plus_one_when_entering_raid()
  elseif event == 'LOOT_OPENED' then
    run_if_master_looter(function() loot_announce_handler() end, false)
  elseif event == 'GUILD_ROSTER_UPDATE' and len(lb_guild_info) == 0 then
    lb_load_guild_info()
    if is_master_looter(UnitName('player')) then
      master_looter = UnitName('player')
      send_ml_settings()
    else
      SendAddonMessage(config.LB_PREFIX, config.LB_GET_ML_SETTINGS, 'RAID')
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
    lb_print('|c' .. config.CHAT_COLORS.INFO ..
               'LootBlare|r is a simple addon that displays and sort item rolls in a frame.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb time <seconds>|r to set the duration the frame is shown. This value will be automatically set by the master looter after the first rolls.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb ac on/off|r to enable/disable auto closing the frame after the time has elapsed.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb hwus on/off|r (hide when using a spell) to enable/disable hiding the frame when using a spell.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb settings|r to see the current settings.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb srl|r to show the soft reserve list.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb al|r to show the alts list.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb pol|r to show the plus one list.')
    lb_print('Master looter commands:')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb sr|r to show the soft reserve frame.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb src|r to clear the soft reserve list.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb aa alt1,alt2,alt3,...,altN|r to add alts to the alts list.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb ar alt1,alt2,alt3,...,altN|r to remove alts from the alts list.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb po <player>|r to increase the plus one count for a player.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb mo <player>|r to reduce the plus one count for a player.')
    lb_print('Type |c' .. config.DEFAULT_TEXT_COLOR ..
               '/lb poc|r to clear the plus one list.')
  elseif msg == 'settings' then
    settings_frame:Show()
  elseif msg == 'srl' then
    print_sr_list()
  elseif msg == 'al' then
    print_alts_list()
  elseif msg == 'pol' then
    print_plus_one_list()
  elseif msg == 'sr' then
    run_if_master_looter(function() import_sr_frame:Show() end)
  elseif msg == 'src' then
    run_if_master_looter(function() clear_sr_list() end)
  elseif string.find(msg, 'aa (%a+)') then
    run_if_master_looter(function()
      local _, _, new_alts = string.find(msg, 'aa (%a+)')
      load_alts_from_string(new_alts)
      lb_print('Alts added')
    end)
  elseif string.find(msg, 'ar (%a+)') then
    run_if_master_looter(function()
      local _, _, new_alts = string.find(msg, 'ar (%a+)')
      remove_alts_from_string(new_alts)
      lb_print('Alts removed')
    end)
  elseif msg == 'ac' then
    run_if_master_looter(function()
      AltList = {}
      lb_print('Alts list cleared')
    end)
  elseif string.find(msg, 'po (%a)') then
    run_if_master_looter(function()
      local _, _, new_plus_one = string.find(msg, 'po (%a+)')
      increase_plus_one(new_plus_one)
    end)
  elseif string.find(msg, 'poos (%a)') then
    run_if_master_looter(function()
      local _, _, new_plus_one = string.find(msg, 'poos (%a+)')
      increase_plus_one_and_whisper_os_payment(new_plus_one, current_link)
    end)
  elseif string.find(msg, 'mo (%a)') then
    run_if_master_looter(function()
      local _, _, new_plus_one = string.find(msg, 'mo (%a+)')
      reduce_plus_one(new_plus_one)
    end)
  elseif msg == 'poc' then
    run_if_master_looter(function()
      PlusOneList = {}
      lb_print('Plus one list cleared')
    end)
  else
    lb_print('Invalid command. Type /lb help for a list of commands.')
  end
end
