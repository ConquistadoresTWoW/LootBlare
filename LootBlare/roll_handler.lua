sr_ms_messages = {}
sr_os_messages = {}
ms_roll_messages = {}
os_roll_messages = {}
tmog_roll_messages = {}
rollers = {}
current_link = nil
is_rolling = false
time_elapsed = 0
item_query = 0.5
times = 5
master_looter = nil
RollType = {SR_MS = 102, SR_OS = 101, MS = 100, OS = 99, TM = 50}
seconds_3 = false
seconds_2 = false
seconds_1 = false
roll_result = {}

-- Add these new variables for roll tracking
has_rolled_for_current_item = false
current_item_id = nil

function reset_rolls()
  ms_roll_messages = {}
  os_roll_messages = {}
  tmog_roll_messages = {}
  rollers = {}
  sr_ms_messages = {}
  sr_os_messages = {}
  greesil_sound_played = false
  -- Reset the roll tracking for the new item
  has_rolled_for_current_item = false
  roll_result = {}
end

function sort_rolls()
  roll_result = {}
  table.sort(sr_ms_messages, function(a, b)
    if a.sr == b.sr then return a.roll > b.roll end
    return a.sr > b.sr
  end)
  table.sort(sr_os_messages, function(a, b)
    if a.sr == b.sr then return a.roll > b.roll end
    return a.sr > b.sr
  end)
  table.sort(ms_roll_messages, function(a, b)
    local a_alt = a.is_alt or false
    local b_alt = b.is_alt or false
    local a_plus_one = a.plus_one or 0
    local b_plus_one = b.plus_one or 0
    local prio_mains = Settings.PrioMainOverAlts
    if prio_mains and (a.is_high_rank and not b.is_high_rank) then
      return true
    end
    if prio_mains and (not a.is_high_rank and b.is_high_rank) then
      return false
    end
    if prio_mains and (a_alt and not b_alt) then return false end
    if prio_mains and (not a_alt and b_alt) then return true end
    if a_plus_one == b_plus_one then return a.roll > b.roll end
    return a_plus_one < b_plus_one
  end)
  table.sort(os_roll_messages, function(a, b)
    local a_alt = a.is_alt or false
    local b_alt = b.is_alt or false
    local a_plus_one = a.plus_one or 0
    local b_plus_one = b.plus_one or 0
    local prio_mains = Settings.PrioMainOverAlts

    if prio_mains and (a.is_high_rank and not b.is_high_rank) then
      return true
    end
    if prio_mains and (not a.is_high_rank and b.is_high_rank) then
      return false
    end
    if prio_mains and (a_alt and not b_alt) then return false end
    if prio_mains and (not a_alt and b_alt) then return true end
    if a_plus_one == b_plus_one then return a.roll > b.roll end
    return a_plus_one < b_plus_one
  end)
  table.sort(tmog_roll_messages, function(a, b) return a.roll > b.roll end)

  local count = 0
  local function insert_into_result(roll_list, max_count)
    for _, message in ipairs(roll_list) do
      if count >= max_count then break end
      table.insert(roll_result, message)
      count = count + 1
    end
  end

  insert_into_result(sr_ms_messages, 4)
  insert_into_result(ms_roll_messages, 4)
  insert_into_result(sr_os_messages, 4)
  insert_into_result(os_roll_messages, 4)
  insert_into_result(tmog_roll_messages, 5)

  lb_send_roll_results()
end

function create_roller_message(message)
  local roller = message.roller

  local message_end = ' rolls ' .. message.roll

  -- roll type to text 
  if message.roll_type == RollType.SR_MS then
    message_end = message_end .. ' (SR-MS: ' .. message.sr .. ')'
  elseif message.roll_type == RollType.SR_OS then
    message_end = message_end .. ' (SR-OS: ' .. message.sr .. ')'
  elseif message.roll_type == RollType.MS then
    message_end = message_end .. ' (MS)'
  elseif message.roll_type == RollType.OS then
    message_end = message_end .. ' (OS)'
  elseif message.roll_type == RollType.TM then
    message_end = message_end .. ' (TM)'
  end

  if message.plus_one and message.plus_one > 0 then
    message_end = message_end .. ' (+' .. message.plus_one .. ')'
  end

  message.roller_name = roller
  message.message_end = message_end
end
local separator = ';'
local function lb_roll_message_to_string(message)
  return message.roller .. separator .. message.roll .. separator ..
           message.class .. separator .. tostring(message.is_high_rank) ..
           separator .. tostring(message.has_debt) .. separator ..
           tostring(message.prio_os) .. separator .. tostring(message.is_alt) ..
           separator .. tostring(message.plus_one) .. separator ..
           tostring(message.has_ms_sr) .. separator ..
           tostring(message.has_os_sr) .. separator ..
           tostring(message.roll_type) .. separator .. tostring(message.sr)
end

function lb_send_roll_results()
  SendAddonMessage(config.LB_PREFIX, config.LB_CLEAR_ROLL_RESULTS, 'RAID')
  for _, message in ipairs(roll_result) do
    SendAddonMessage(config.LB_PREFIX, config.LB_ADD_ROLL_RESULT ..
                       lb_roll_message_to_string(message), 'RAID')
  end
end

function lb_load_roll_message(message_str)
  local parts = string_split(message_str, separator)
  local message = {
    roller = parts[1],
    roll = tonumber(parts[2]),
    class = parts[3],
    is_high_rank = parts[4] == 'true',
    has_debt = parts[5] == 'true',
    prio_os = parts[6] == 'true',
    is_alt = parts[7] == 'true',
    plus_one = tonumber(parts[8]),
    has_ms_sr = parts[9] == 'true',
    has_os_sr = parts[10] == 'true',
    roll_type = tonumber(parts[11]),
    sr = tonumber(parts[12])
  }
  table.insert(roll_result, message)
end
