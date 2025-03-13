itemRollFrame = CreateItemRollFrame()
itemRollFrame:RegisterEvent('ADDON_LOADED')
itemRollFrame:RegisterEvent('CHAT_MSG_SYSTEM')
itemRollFrame:RegisterEvent('CHAT_MSG_RAID_WARNING')
itemRollFrame:RegisterEvent('CHAT_MSG_RAID')
itemRollFrame:RegisterEvent('CHAT_MSG_RAID_LEADER')
itemRollFrame:RegisterEvent('CHAT_MSG_ADDON')
itemRollFrame:RegisterEvent('CURRENT_SPELL_CAST_CHANGED')
itemRollFrame:SetScript('OnEvent',
                        function() HandleChatMessage(event, arg1, arg2) end)

-- Register the slash command
SLASH_LOOTBLARE1 = '/lootblare'
SLASH_LOOTBLARE2 = '/lb'

-- Command handler
SlashCmdList['LOOTBLARE'] = function(msg)
  if msg == '' then
    if itemRollFrame:IsVisible() then
      itemRollFrame:Hide()
    else
      itemRollFrame:Show()
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
    lb_print('Master Looter: ' .. (masterLooter or 'unknown'))
  elseif string.find(msg, 'time') then
    local _, _, newDuration = string.find(msg, 'time (%d+)')
    newDuration = tonumber(newDuration)
    if newDuration and newDuration > 0 then
      FrameShownDuration = newDuration
      lb_print('Roll time set to ' .. newDuration .. ' seconds.')
      if IsSenderMasterLooter(UnitName('player')) then
        SendAddonMessage(config.LB_PREFIX,
                         config.LB_SET_ROLL_TIME .. newDuration, 'RAID')
      end
    else
      lb_print('Invalid duration. Please enter a number greater than 0.')
    end
  elseif string.find(msg, 'autoClose') then
    local _, _, autoClose = string.find(msg, 'autoClose (%a+)')
    if autoClose == 'on' then
      lb_print('Auto closing enabled.')
      FrameAutoClose = true
    elseif autoClose == 'off' then
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
