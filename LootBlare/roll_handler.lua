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
  table.sort(ms_roll_messages, function(a, b)
    local a_alt = AltList[a.roller] or false
    local b_alt = AltList[b.roller] or false
    local a_plus_one = PlusOneList[a.roller] or 0
    local b_plus_one = PlusOneList[b.roller] or 0

    if a_alt and not b_alt then return false end
    if not a_alt and b_alt then return true end
    if a_plus_one == b_plus_one then return a.roll > b.roll end
    return a_plus_one < b_plus_one
  end)
  table.sort(os_roll_messages, function(a, b)
    local a_alt = AltList[a.roller] or false
    local b_alt = AltList[b.roller] or false
    local a_plus_one = PlusOneList[a.roller] or 0
    local b_plus_one = PlusOneList[b.roller] or 0

    if a_alt and not b_alt then return false end
    if not a_alt and b_alt then return true end
    if a_plus_one == b_plus_one then return a.roll > b.roll end
    return a_plus_one < b_plus_one
  end)
  table.sort(tmog_roll_messages, function(a, b) return a.roll > b.roll end)
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

  if AltList[roller] then roller = '*' .. roller end

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

  if PlusOneList[message.roller] and PlusOneList[message.roller] > 0 then
    message_end = message_end .. ' (+' .. PlusOneList[message.roller] .. ')'
  end

  message.alt_roller = roller
  message.message_end = message_end
end
