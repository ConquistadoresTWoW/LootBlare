discover = CreateFrame('GameTooltip', 'CustomTooltip1', UIParent,
                       'GameTooltipTemplate')

function lb_print(msg)
  if msg == nil then msg = 'nil' end
  DEFAULT_CHAT_FRAME:AddMessage('|c' .. config.ADDON_TEXT_COLOR ..
                                  config.LB_PREFIX .. ': ' .. msg .. '|r')
end

function create_color_message(message)
  msg = message.msg
  class = message.class
  _, _, _, message_end = string.find(msg, '(%S+)%s+(.+)')
  class_color = config.RAID_CLASS_COLORS[class]
  text_color = config.DEFAULT_TEXT_COLOR

  if string.find(msg, '-101') then
    text_color = config.SR_TEXT_COLOR
  elseif string.find(msg, '-100') then
    text_color = config.MS_TEXT_COLOR
  elseif string.find(msg, '-99') then
    text_color = config.OS_TEXT_COLOR
  elseif string.find(msg, '-50') then
    text_color = config.TM_TEXT_COLOR
  end

  colored_msg = '|c' .. class_color .. '' .. message.roller .. '|r |c' ..
                  text_color .. message_end .. '|r'
  return colored_msg
end

function len(t)
  c = 0
  for _ in pairs(t) do c = c + 1 end
  if c > 0 then
    return c
  else
    return nil
  end
end

function check_item(link)
  discover:SetOwner(UIParent, 'ANCHOR_PRESERVE')
  discover:SetHyperlink(link)
  -- I don't know why this is here or what it does. I'm just leaving it here for future reference
  -- these variables are not defined 
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

function is_sender_master_looter(sender)
  local loot_method, master_looter_party_id = GetLootMethod()
  if loot_method == 'master' and master_looter_party_id then
    if master_looter_party_id == 0 then
      if sender == UnitName('player') then end
      return sender == UnitName('player')
    else
      local sender_UID = 'party' .. master_looter_party_id
      local master_looter_name = UnitName(sender_UID)
      return master_looter_name == sender
    end
  end
  return false
end
