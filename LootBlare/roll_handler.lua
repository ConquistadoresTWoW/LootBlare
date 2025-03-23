sr_roll_messages = {}
sr_ms_messages = {}
sr_os_messages = {}
ms_roll_messages = {}
os_roll_messages = {}
tmog_roll_messages = {}
rollers = {}
is_rolling = false
time_elapsed = 0
item_query = 0.5
times = 5
master_looter = nil

function reset_rolls()
  sr_roll_messages = {}
  ms_roll_messages = {}
  os_roll_messages = {}
  tmog_roll_messages = {}
  rollers = {}
  sr_ms_messages = {}
  sr_os_messages = {}
end

function sort_rolls()
  table.sort(sr_roll_messages, function(a, b) return a.roll > b.roll end)
  table.sort(ms_roll_messages, function(a, b) return a.roll > b.roll end)
  table.sort(os_roll_messages, function(a, b) return a.roll > b.roll end)
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
