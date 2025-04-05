discover = CreateFrame('GameTooltip', 'CustomTooltip1', UIParent,
                       'GameTooltipTemplate')
greesil_sound_played = false

function lb_print(msg)
  if msg == nil then msg = 'nil' end
  DEFAULT_CHAT_FRAME:AddMessage('|c' .. config.ADDON_TEXT_COLOR ..
                                  config.LB_PREFIX .. ': ' .. msg .. '|r')
end

function create_color_name_by_class(name, class)
  local class_color = config.RAID_CLASS_COLORS[class] or
                        config.DEFAULT_TEXT_COLOR
  return '|c' .. class_color .. name .. '|r'
end

function create_color_message(message)
  local class_color = config.RAID_CLASS_COLORS[message.class] or
                        config.DEFAULT_TEXT_COLOR
  local text_color = config.DEFAULT_TEXT_COLOR

  -- First line: Character name (class colored) + "rolls XX" (yellow)
  local line1 = '|c' .. class_color .. message.alt_roller .. '|r |c' .. 
                config.DEFAULT_TEXT_COLOR .. 'rolls ' .. message.roll .. '|r'
  
  -- Second line: Roll type and additional info
  local line2_parts = {}
  
  -- Add roll type info
  if message.roll_type == RollType.SR_MS then
    table.insert(line2_parts, '|c' .. config.SR_MS_TEXT_COLOR .. 'SR-MS: ' .. message.sr .. '|r')
  elseif message.roll_type == RollType.SR_OS then
    table.insert(line2_parts, '|c' .. config.SR_OS_TEXT_COLOR .. 'SR-OS: ' .. message.sr .. '|r')
  elseif message.roll_type == RollType.MS then
    table.insert(line2_parts, '|c' .. config.MS_TEXT_COLOR .. 'MS|r')
  elseif message.roll_type == RollType.OS then
    table.insert(line2_parts, '|c' .. config.OS_TEXT_COLOR .. 'OS|r')
  elseif message.roll_type == RollType.TM then
    table.insert(line2_parts, '|c' .. config.TM_TEXT_COLOR .. 'TM|r')
  end
  
  -- Add plus one info if applicable
  if PlusOneList[message.roller] and PlusOneList[message.roller] > 0 then
    table.insert(line2_parts, '|c' .. config.CHAT_COLORS.NEUTRAL .. 
                '+ ' .. PlusOneList[message.roller] .. '|r')
  end
  
  -- Combine all parts of line 2
  local line2 = table.concat(line2_parts, ' ')
  
  -- Combine both lines with newline
  return line1 .. '\n' .. line2
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

function is_master_looter(player_name)
  local loot_method, master_looter_party_id = GetLootMethod()
  if loot_method == 'master' and master_looter_party_id then
    if master_looter_party_id == 0 then
      if player_name == UnitName('player') then end
      return player_name == UnitName('player')
    else
      local sender_UID = 'party' .. master_looter_party_id
      local master_looter_name = UnitName(sender_UID)
      return master_looter_name == player_name
    end
  end
  return false
end

function string_split(input_str, sep)
  if sep == nil then sep = "," end
  local result = {}
  local field = ""

  for i = 1, string.len(input_str) do

    local char = string.sub(input_str, i, i)

    if char == '"' then
      -- skip separators until next quote
      field = field .. char
      repeat
        i = i + 1
        char = string.sub(input_str, i, i)
        field = field .. char
      until char == '"' or i == string.len(input_str)
    elseif char == sep then
      table.insert(result, field)
      field = "" -- Reset field
    elseif char == ' ' then
      -- skip spaces
    else
      field = field .. char
    end
  end

  table.insert(result, field) -- Add last field

  -- Convert numeric fields where applicable
  for i, v in ipairs(result) do if tonumber(v) then result[i] = tonumber(v) end end

  return result
end

function string_match(str, pattern)
  if not str then return nil end

  local _, _, r1, r2, r3, r4, r5, r6, r7, r8, r9 = string.find(str, pattern)
  return r1, r2, r3, r4, r5, r6, r7, r8, r9
end

function is_member_in_raid(member_name)
  for i = 1, GetNumRaidMembers() do
    local name, _, _, _, _, _, _, online = GetRaidRosterInfo(i)
    if name == member_name and online then return true end
  end

  return false
end

function play_sound(path)
  lb_print('Playing sound ')
  if path == nil then
    path = 'Interface\\AddOns\\LootBlare\\assets\\conxale.mp3'
  end
  PlaySoundFile(path, 'Master')
end

function run_if_master_looter(callback)
  if is_master_looter(UnitName('player')) then
    callback()
  else
    lb_print('You are not the master looter')
  end
end
