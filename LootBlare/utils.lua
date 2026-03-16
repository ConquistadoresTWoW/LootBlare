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
  local line1 = '|c' .. class_color .. message.roller_name .. '|r |c' ..
                  config.DEFAULT_TEXT_COLOR .. 'rolls ' .. message.roll .. '|r'

  -- Second line: Roll type and additional info
  local line2_parts = {}

  -- Add roll type info
  if message.roll_type == RollType.SR_MS then
    table.insert(line2_parts, '|c' .. config.SR_MS_TEXT_COLOR .. 'SR-MS: ' ..
                   message.sr .. '|r')
  elseif message.roll_type == RollType.SR_OS then
    table.insert(line2_parts, '|c' .. config.SR_OS_TEXT_COLOR .. 'SR-OS: ' ..
                   message.sr .. '|r')
  elseif message.roll_type == RollType.MS then
    table.insert(line2_parts, '|c' .. config.MS_TEXT_COLOR .. 'MS|r')
  elseif message.roll_type == RollType.OS then
    table.insert(line2_parts, '|c' .. config.OS_TEXT_COLOR .. 'OS|r')
  elseif message.roll_type == RollType.TM then
    table.insert(line2_parts, '|c' .. config.TM_TEXT_COLOR .. 'TM|r')
  end

  -- Add plus one info if applicable
  if message.plus_one and message.plus_one > 0 then
    table.insert(line2_parts, '|c' .. config.CHAT_COLORS.NEUTRAL .. '+ ' ..
                   message.plus_one .. '|r')
  end

  -- Combine all parts of line 2
  local line2 = table.concat(line2_parts, ' ')

  -- Combine both lines with newline
  return line1 .. '\n' .. line2
end

function len(t)
  if type(t) ~= 'table' then return 0 end
  if t == nil then return 0 end
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
  if path == nil then path = 'Interface\\AddOns\\LootBlare\\assets\\sound.mp3' end
  PlaySoundFile(path, 'Master')
end

function run_if_master_looter(callback, notify)
  if notify == nil then notify = true end
  if is_master_looter(UnitName('player')) then
    callback()
  elseif notify then
    lb_print('You are not the master looter')
  end
end

-- Read version from .toc so it only needs to be updated in one place
local raw_version = GetAddOnMetadata("LootBlare", "Version") or "0.0.0"
local latest_version = "[" .. raw_version .. "]"

local function is_older_version(my_ver, their_ver)
  -- Strip brackets: "[3.1.0]" -> "3.1.0"
  my_ver = string.gsub(my_ver, "[%[%]]", "")
  their_ver = string.gsub(their_ver, "[%[%]]", "")

  local my_major, my_minor, my_patch = string_match(my_ver, "(%d+)%.(%d+)%.(%d+)")
  local their_major, their_minor, their_patch = string_match(their_ver, "(%d+)%.(%d+)%.(%d+)")

  my_major, my_minor, my_patch = tonumber(my_major), tonumber(my_minor), tonumber(my_patch)
  their_major, their_minor, their_patch = tonumber(their_major), tonumber(their_minor), tonumber(their_patch)

  if not (my_major and their_major) then return false end

  if my_major ~= their_major then return my_major < their_major end
  if my_minor ~= their_minor then return my_minor < their_minor end
  return my_patch < their_patch
end

local lb_version_check = false

function send_ml_settings()
  local master_looter = master_looter or 'unknown'
  local message = config.LB_SET_ML_SETTINGS .. Settings.RollDuration .. ',' ..
                    tostring(Settings.PrioMainOverAlts) .. ',' .. master_looter ..
                    ',' .. latest_version
  SendAddonMessage(config.LB_PREFIX, message, 'RAID')
end

function load_ml_settings_from_string(settings_str)
  local settings = string_split(settings_str, ',')

  Settings.RollDuration = tonumber(settings[1])
  Settings.PrioMainOverAlts = settings[2] == 'true'
  master_looter = settings[3]

  if not lb_version_check then
    local ml_version = settings[4] or '[0.0.0]'
    if is_older_version(latest_version, ml_version) then
      local download_url = "https://github.com/ConquistadoresTWoW/LootBlare/archive/refs/heads/master.zip"
      DEFAULT_CHAT_FRAME:AddMessage(
        '|c' .. config.ADDON_TEXT_COLOR .. 'LootBlare: ' .. '|r' ..
        '|c' .. config.CHAT_COLORS.INFO .. ml_version .. ' is available! ' .. '|r' ..
        '|c' .. config.ADDON_TEXT_COLOR .. download_url .. '|r')
    end
    lb_version_check = true
  end

  update_moa_button_texture()
  update_text_area(item_roll_frame)
end

function lb_has_debt(player_name)
  local has_debt = false
  if HC_GetCurrentDebtData ~= nil then
    local n, debt, t = HC_GetCurrentDebtData(player_name)
    if debt and tonumber(debt) and tonumber(debt) > 0 then has_debt = true end
  end
  return has_debt
end
