srRollMessages = {}
msRollMessages = {}
osRollMessages = {}
tmogRollMessages = {}
rollers = {}
isRolling = false
time_elapsed = 0
item_query = 0.5
times = 5
masterLooter = nil

function resetRolls()
  srRollMessages = {}
  msRollMessages = {}
  osRollMessages = {}
  tmogRollMessages = {}
  rollers = {}
end
  
function sortRolls()
  table.sort(srRollMessages, function(a, b)
      return a.roll > b.roll
  end)
  table.sort(msRollMessages, function(a, b)
      return a.roll > b.roll
  end)
  table.sort(osRollMessages, function(a, b)
      return a.roll > b.roll
  end)
  table.sort(tmogRollMessages, function(a, b)
      return a.roll > b.roll
  end)
end