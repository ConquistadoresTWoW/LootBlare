discover = CreateFrame('GameTooltip', 'CustomTooltip1', UIParent,
                       'GameTooltipTemplate')

function lb_print(msg)
  if msg == nil then msg = 'nil' end
  DEFAULT_CHAT_FRAME:AddMessage('|c' .. config.ADDON_TEXT_COLOR ..
                                  config.LB_PREFIX .. ': ' .. msg .. '|r')
end

function create_color_message(message)
  local class_color = config.RAID_CLASS_COLORS[message.class] or
                        config.DEFAULT_TEXT_COLOR
  local text_color = config.DEFAULT_TEXT_COLOR

  if message.roll_type == RollType.SR_MS then
    text_color = config.SR_MS_TEXT_COLOR
  elseif message.roll_type == RollType.SR_OS then
    text_color = config.SR_OS_TEXT_COLOR
  elseif message.roll_type == RollType.MS then
    text_color = config.MS_TEXT_COLOR
  elseif message.roll_type == RollType.OS then
    text_color = config.OS_TEXT_COLOR
  elseif message.roll_type == RollType.TM then
    text_color = config.TM_TEXT_COLOR
  end

  local colored_msg =
    '|c' .. class_color .. '' .. message.alt_roller .. '|r |c' .. text_color ..
      message.message_end .. '|r'
  return colored_msg
end

function len(t)
  c = 0
  for _ in pairs(t) do c = c + 1 end
  return c
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

function split_string(input_str, sep)
  if sep == nil then sep = "," end
  local result = {}
  local field = ""

  -- remove spaces of input_str
  input_str = string.gsub(input_str, ' ', '')

  for i = 1, string.len(input_str) do
    -- local char = input_str:sub(i, i)
    local char = string.sub(input_str, i, i)

    if char == '"' then
      -- ignore quotes and continue to next char
    elseif char == sep then
      table.insert(result, field)
      field = "" -- Reset field
    else
      field = field .. char
    end
  end

  table.insert(result, field) -- Add last field

  -- Convert numeric fields where applicable
  for i, v in ipairs(result) do if tonumber(v) then result[i] = tonumber(v) end end

  return result
end

function load_alts_from_string(alts_string)

  local alts = split_string(alts_string, ',')

  for i, alt in ipairs(alts) do AltList[alt] = true end
end

function print_alts_list()
  local alt_str = ''
  for alt, _ in pairs(AltList) do alt_str = alt_str .. alt .. ', ' end
  lb_print(alt_str)
end

function is_member_in_raid(member_name)
  for i = 1, GetNumRaidMembers() do
    local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
    if name == member_name and online then return true end
  end

  return false
end
