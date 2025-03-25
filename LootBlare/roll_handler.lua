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

function reset_rolls()
  ms_roll_messages = {}
  os_roll_messages = {}
  tmog_roll_messages = {}
  rollers = {}
  sr_ms_messages = {}
  sr_os_messages = {}
  greesil_sound_played = false
end

function sort_rolls()
  -- sort by roll but mains first
  table.sort(ms_roll_messages, function(a, b)
    if a.alt and not b.alt then return false end
    if not a.alt and b.alt then return true end
    return a.roll > b.roll
  end)
  -- sort by roll but mains first
  table.sort(os_roll_messages, function(a, b)
    if a.alt and not b.alt then return false end
    if not a.alt and b.alt then return true end
    return a.roll > b.roll
  end)
  table.sort(tmog_roll_messages, function(a, b) return a.roll > b.roll end)
  -- sort ms_roll_messages by SR and then by roll
  table.sort(sr_ms_messages, function(a, b)
    if a.sr == b.sr then return a.roll > b.roll end
    return a.sr > b.sr
  end)
  table.sort(sr_os_messages, function(a, b)
    if a.sr == b.sr then return a.roll > b.roll end
    return a.sr > b.sr
  end)
end

function create_roller_message(message)
  local roller = message.roller

  if message.alt then roller = '*' .. roller end

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

  message.alt_roller = roller
  message.message_end = message_end
end
