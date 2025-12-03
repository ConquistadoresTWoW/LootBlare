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
    elseif is_rolling and string.find(message, 'rolls') and
      string.find(message, '(%d+)') then
      local _, _, roller, roll, min_roll, max_roll =
        string.find(message, '(%S+) rolls (%d+) %((%d+)%-(%d+)%)')
      max_roll = tonumber(max_roll)
      if roller and roll and rollers[roller] == nil then

        local has_ms_sr = has_sr(sr_ms_messages, roller)
        local has_os_sr = has_sr(sr_os_messages, roller)
        if (has_ms_sr or has_os_sr) and max_roll ~= 100 then return end
        roll = tonumber(roll)
        rollers[roller] = 1
        
        -- Record that this player has rolled for current item
        check_and_record_roll(roller)

		local has_debt = false
		if HC_GetCurrentDebtData ~= nil then
		local n, debt, t = HC_GetCurrentDebtData(roller)
		if debt and tonumber(debt) and tonumber(debt) > 0 then
			has_debt = true
		end
		end
		message = {
		roller = roller,
		roll = roll,
		class = get_class_of_roller(roller),
		is_high_rank = lb_is_high_rank(roller),
		has_debt = has_debt
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
        update_text_area(item_roll_frame)
      end
    end
  elseif event == 'CHAT_MSG_RAID_WARNING' and sender == master_looter and
    not string.find(message, 'Random Rolling') then
    local links = extract_item_links_from_message(message)

    if len(links) == 1 then
      current_link = links[1]
      
      -- Find and announce soft reserves for this item (new functionality)
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
          local class_color = config.RAID_CLASS_COLORS[get_class_of_roller(sr["Attendee"])] or 
                             config.DEFAULT_TEXT_COLOR
          local entry = "|c" .. class_color .. sr["Attendee"] .. "|r"
          if sr["SR+"] > 1 then
            entry = entry .. "(" .. sr["SR+"] .. ")"
          end
          table.insert(sr_entries, entry)
        end
        
        -- Add OS SRs
        for _, sr in ipairs(os_srs) do
          local class_color = config.RAID_CLASS_COLORS[get_class_of_roller(sr["Attendee"])] or 
                             config.DEFAULT_TEXT_COLOR
          local entry = "|c" .. class_color .. sr["Attendee"] .. "|r(OS)"
          if sr["SR+"] > 1 then
            entry = entry .. "(" .. sr["SR+"] .. ")"
          end
          table.insert(sr_entries, entry)
        end
        
        -- Combine all entries
        sr_message = sr_message .. table.concat(sr_entries, ", ")
        SendChatMessage(sr_message, "RAID", nil, nil)
      end
      
      if is_master_looter(UnitName('player')) then
        current_item_sr = sr_list or {}
        SendAddonMessage(config.LB_PREFIX, config.LB_CLEAR_ALTS, 'RAID')
        report_alt_list()
        SendAddonMessage(config.LB_PREFIX, config.LB_CLEAR_PLUS_ONE, 'RAID')
        report_plus_one_list()
        report_sr_list()
        SendAddonMessage(config.LB_PREFIX, config.LB_START_ROLL, 'RAID')
      end
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
      reset_rolls()
      sr_ms, sr_os = find_ms_and_os_sr_for_item()
      insert_sr_rolls(sr_ms, sr_os)
      update_text_area(item_roll_frame)
      time_elapsed = 0
      is_rolling = true
      show_frame(item_roll_frame, Settings.RollDuration, current_link)
      -- Reset roll tracking
      has_rolled_for_current_item = {}
      if update_roll_buttons then
        update_roll_buttons()
      end
    end

    if sender == master_looter and message == config.LB_STOP_ROLL then
      is_rolling = false
      time_elapsed = Settings.RollDuration
    end
    -- ML is reseting the SR list for the current item
    if sender == master_looter and sender ~= UnitName('player') then

      if message == config.LB_CLEAR_SR then current_item_sr = {} end
      if string.find(message, config.LB_ADD_SR) then
        local _, _, sr_str = string.find(message, config.LB_ADD_SR .. '(.+)')
        local row = built_sr_row_from_string(sr_str)
        table.insert(current_item_sr, row)
      end
      if message == config.LB_CLEAR_ALTS then AltList = {} end
      if string.find(message, config.LB_ADD_ALTS) then
        local _, _, alts_str =
          string.find(message, config.LB_ADD_ALTS .. '(.+)')
        load_alts_from_string(alts_str)
      end
      if message == config.LB_CLEAR_PLUS_ONE then PlusOneList = {} end
      if string.find(message, config.LB_ADD_PLUS_ONE) then
        local _, _, plus_one_str = string.find(message,
                                               config.LB_ADD_PLUS_ONE .. '(.+)')
        load_plus_one_from_string(plus_one_str)
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
  end
end