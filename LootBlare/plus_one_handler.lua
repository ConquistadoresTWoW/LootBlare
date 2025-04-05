function print_plus_one_list()
  local plus_one_str = 'Plus one list: '
  for name, value in pairs(PlusOneList) do
    if value > 0 then
      plus_one_str = plus_one_str .. name .. ', ' .. value .. '; '
    end
  end
  lb_print(plus_one_str)
end

function increase_plus_one(player_name)
  if not is_master_looter(UnitName('player')) then
    lb_print('You are not the master looter')
    return
  end

  local class = get_class_of_roller(player_name)
  local colored_name = create_color_name_by_class(player_name, class)

  if PlusOneList[player_name] then
    PlusOneList[player_name] = PlusOneList[player_name] + 1
    SendChatMessage(colored_name .. ' |c' .. config.CHAT_COLORS.POSITIVE ..
                      '+1|r. (|c' .. config.CHAT_COLORS.NEUTRAL .. '+' ..
                      PlusOneList[player_name] .. '|r)', 'RAID')
  else
    PlusOneList[player_name] = 1
    SendChatMessage(colored_name .. ' |c' .. config.CHAT_COLORS.POSITIVE ..
                      '+1|r. (|c' .. config.CHAT_COLORS.NEUTRAL .. '+1|r)',
                    'RAID')
  end
  report_plus_one_list()
end

function reduce_plus_one(player_name)
  if not is_master_looter(UnitName('player')) then
    lb_print('You are not the master looter')
    return
  end

  local class = get_class_of_roller(player_name)
  local colored_name = create_color_name_by_class(player_name, class)

  if PlusOneList[player_name] then
    PlusOneList[player_name] = PlusOneList[player_name] - 1
    if PlusOneList[player_name] < 0 then PlusOneList[player_name] = 0 end
    SendChatMessage(colored_name .. ' |c' .. config.CHAT_COLORS.NEGATIVE ..
                      '-1|r. (|c' .. config.CHAT_COLORS.NEUTRAL .. '+' ..
                      PlusOneList[player_name] .. '|r)', 'RAID')
  else
    PlusOneList[player_name] = 0
    SendChatMessage(colored_name .. ' |c' .. config.CHAT_COLORS.NEGATIVE ..
                      '-1|r. (|c' .. config.CHAT_COLORS.NEUTRAL .. '+0|r)',
                    'RAID')
  end
  report_plus_one_list()
end

function load_plus_one_from_string(plus_one_string)
  local plus_ones = string_split(plus_one_string, ';')
  for i, plus_one in ipairs(plus_ones) do
    local name, value = string_match(plus_one, '(%w+),(%d+)')
    if name and value then PlusOneList[name] = tonumber(value) end
  end
end

function report_plus_one_list()
  local plus_one_str = ''
  for player, value in pairs(PlusOneList) do
    plus_one_str = plus_one_str .. player .. ',' .. value .. ';'
    if string.len(plus_one_str) > 100 then
      SendAddonMessage(config.LB_PREFIX, config.LB_ADD_PLUS_ONE .. plus_one_str,
                       'RAID')
      plus_one_str = ''
    end
  end
  if string.len(plus_one_str) > 0 then
    SendAddonMessage(config.LB_PREFIX, config.LB_ADD_PLUS_ONE .. plus_one_str,
                     'RAID')
  end
end
