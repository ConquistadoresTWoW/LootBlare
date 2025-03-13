
function HandleChatMessage(event, message, sender)
  if (event == 'CHAT_MSG_RAID' or event == 'CHAT_MSG_RAID_LEADER') then
    local _,_,duration = string.find(message, 'Roll time set to (%d+) seconds')
    duration = tonumber(duration)
    if duration and duration ~= FrameShownDuration then
      FrameShownDuration = duration
      -- The players get the new duration from the master looter after the first rolls
      lb_print('Rolling duration set to ' .. FrameShownDuration .. ' seconds. (set by Master Looter)')
    end
  elseif event == 'CURRENT_SPELL_CAST_CHANGED' and HideWhenUsingSpell and time_elapsed == 0 then
    itemRollFrame:Hide()
  elseif event == 'CHAT_MSG_SYSTEM' then
    local _,_, newML = string.find(message, '(%S+) is now the loot master')
    if newML then
      masterLooter = newML
      playerName = UnitName('player')
      -- if the player is the new master looter, announce the roll time
      if newML == playerName then
        SendAddonMessage(config.LB_PREFIX, config.LB_SET_ROLL_TIME .. FrameShownDuration .. ' seconds', 'RAID')
      end
    elseif isRolling and string.find(message, 'rolls') and string.find(message, '(%d+)') then
      local _,_,roller, roll, minRoll, maxRoll = string.find(message, '(%S+) rolls (%d+) %((%d+)%-(%d+)%)')
      if roller and roll and rollers[roller] == nil then
        roll = tonumber(roll)
        rollers[roller] = 1
        message = { roller = roller, roll = roll, msg = message, class = GetClassOfRoller(roller) }
        if maxRoll == '101' then
          table.insert(srRollMessages, message)
        elseif maxRoll == '100' then
          table.insert(msRollMessages, message)
        elseif maxRoll == '99' then
          table.insert(osRollMessages, message)
        elseif maxRoll == '50' then
          table.insert(tmogRollMessages, message)
        end
        UpdateTextArea(itemRollFrame)
      end
    end

  elseif event == 'CHAT_MSG_RAID_WARNING' and sender == masterLooter then
    local links = ExtractItemLinksFromMessage(message)
    if tsize(links) == 1 then
      -- these if are not being used RN. I'm just leaving them here for future reference
      if string.find(message, '^No one has need:') or
          string.find(message,'has been sent to') or
          string.find(message, ' received ') then
        itemRollFrame:Hide()
        return
      elseif string.find(message,'Rolling Cancelled') or -- usually a cancel is accidental in my experience
              string.find(message,'seconds left to roll') or
              string.find(message,'Rolling is now Closed') then
        return
      end
      resetRolls()
      UpdateTextArea(itemRollFrame)
      time_elapsed = 0
      isRolling = true
      ShowFrame(itemRollFrame,FrameShownDuration,links[1])
    end
  elseif event == 'ADDON_LOADED' then
    if FrameShownDuration == nil then FrameShownDuration = 15 end
    if FrameAutoClose == nil then FrameAutoClose = true end
    if HideWhenUsingSpell == nil then HideWhenUsingSpell = false end
    if IsSenderMasterLooter(UnitName('player')) then
      SendAddonMessage(config.LB_PREFIX, config.LB_SET_ML .. UnitName('player'), 'RAID')
      SendAddonMessage(config.LB_PREFIX, config.LB_SET_ROLL_TIME .. FrameShownDuration, 'RAID')
      itemRollFrame:UnregisterEvent('ADDON_LOADED')
    else
      SendAddonMessage(config.LB_PREFIX, config.LB_GET_DATA, 'RAID')
    end
  elseif event == 'CHAT_MSG_ADDON' and arg1 == config.LB_PREFIX then
    local prefix, message, channel, sender = arg1, arg2, arg3, arg4
    
    -- Someone is asking for the master looter and his roll time
    if message == config.LB_GET_DATA and IsSenderMasterLooter(UnitName('player')) then
      masterLooter = UnitName('player')
      SendAddonMessage(config.LB_PREFIX, config.LB_SET_ML .. masterLooter, 'RAID')
      SendAddonMessage(config.LB_PREFIX, config.LB_SET_ROLL_TIME .. FrameShownDuration, 'RAID')
    end

    -- Someone is setting the master looter
    if string.find(message, config.LB_SET_ML) then
      local _,_, newML = string.find(message, 'ML set to (%S+)')
      masterLooter = newML
    end
    -- Someone is setting the roll time
    if string.find(message, config.LB_SET_ROLL_TIME) then
      local _,_,duration = string.find(message, 'Roll time set to (%d+)')
      duration = tonumber(duration)
      if duration and duration ~= FrameShownDuration then
        FrameShownDuration = duration
        lb_print('Roll time set to ' .. FrameShownDuration .. ' seconds.')
      end
    end
  end
end