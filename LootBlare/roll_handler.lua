sr_roll_messages = {}
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
end

function sort_rolls()
  table.sort(sr_roll_messages, function(a, b) return a.roll > b.roll end)
  table.sort(ms_roll_messages, function(a, b) return a.roll > b.roll end)
  table.sort(os_roll_messages, function(a, b) return a.roll > b.roll end)
  table.sort(tmog_roll_messages, function(a, b) return a.roll > b.roll end)
end
