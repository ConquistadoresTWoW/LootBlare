discover = CreateFrame('GameTooltip', 'CustomTooltip1', UIParent,
                       'GameTooltipTemplate')

function lb_print(msg)
  DEFAULT_CHAT_FRAME:AddMessage('|c' .. config.ADDON_TEXT_COLOR ..
                                  config.LB_PREFIX .. ': ' .. msg .. '|r')
end

function colorMsg(message)
  msg = message.msg
  class = message.class
  _, _, _, message_end = string.find(msg, '(%S+)%s+(.+)')
  classColor = config.RAID_CLASS_COLORS[class]
  textColor = config.DEFAULT_TEXT_COLOR

  if string.find(msg, '-101') then
    textColor = config.SR_TEXT_COLOR
  elseif string.find(msg, '-100') then
    textColor = config.MS_TEXT_COLOR
  elseif string.find(msg, '-99') then
    textColor = config.OS_TEXT_COLOR
  elseif string.find(msg, '-50') then
    textColor = config.TM_TEXT_COLOR
  end

  colored_msg = '|c' .. classColor .. '' .. message.roller .. '|r |c' ..
                  textColor .. message_end .. '|r'
  return colored_msg
end

function tsize(t)
  c = 0
  for _ in pairs(t) do c = c + 1 end
  if c > 0 then
    return c
  else
    return nil
  end
end

function CheckItem(link)
  discover:SetOwner(UIParent, 'ANCHOR_PRESERVE')
  discover:SetHyperlink(link)

  if discoverTextLeft1 and discoverTooltipTextLeft1:IsVisible() then
    local name = discoverTooltipTextLeft1:GetText()
    discoverTooltip:Hide()

    if name == (RETRIEVING_ITEM_INFO or '') then
      return false
    else
      return true
    end
  end
  return false
end

function IsSenderMasterLooter(sender)
  local lootMethod, masterLooterPartyID = GetLootMethod()
  if lootMethod == 'master' and masterLooterPartyID then
    if masterLooterPartyID == 0 then
      if sender == UnitName('player') then end
      return sender == UnitName('player')
    else
      local senderUID = 'party' .. masterLooterPartyID
      local masterLooterName = UnitName(senderUID)
      return masterLooterName == sender
    end
  end
  return false
end
