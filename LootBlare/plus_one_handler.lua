-- plus_one_handler.lua
function print_plus_one_list()
  local plus_one_str = 'Plus one list: '
  for name, value in pairs(PlusOneList) do
    if value > 0 then
      plus_one_str = plus_one_str .. name .. ', ' .. value .. '; '
    end
  end
  lb_print(plus_one_str)
end

local function increase_po_message(player_name, increment)
  if not increment then increment = 1 end
  local function po_on_list(player_name, list)
    for _, msg in ipairs(list) do
      if msg.roller == player_name then
        -- Initialize plus_one if it doesn't exist
        if msg.plus_one == nil then
          msg.plus_one = 0
        end
        msg.plus_one = msg.plus_one + increment
        if msg.plus_one < 0 then
          msg.plus_one = 0
        end
        return true
      end
    end
    return false
  end

  if po_on_list(player_name, ms_roll_messages) then return end
  if po_on_list(player_name, os_roll_messages) then return end
  if po_on_list(player_name, sr_ms_messages) then return end
  if po_on_list(player_name, sr_os_messages) then return end
  if po_on_list(player_name, tmog_roll_messages) then return end
end

function increase_plus_one(player_name)
  if not is_master_looter(UnitName('player')) then
    lb_print('You are not the master looter')
    return
  end

  -- allow lowercase names
  player_name = string.lower(player_name)
  player_name = string.upper(string.sub(player_name, 1, 1)) ..
                  string.sub(player_name, 2)

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

  -- find player_name in all the roll lists and increase the plus one there
  increase_po_message(player_name)
  return player_name
end

function create_gold_string(money)
  if type(money) ~= "number" then return "-" end

  local gold = floor(money / 100 / 100)
  local silver = floor(mod((money / 100), 100))
  local copper = floor(mod(money, 100))

  local string = ""
  if gold > 0 then string = string .. gold .. "g " end
  if silver > 0 or gold > 0 then string = string .. " " .. silver .. "s" end
  string = string .. " " .. copper .. "c"

  return string
end

function increase_plus_one_and_whisper_os_payment(player_name, current_link)
  if not is_master_looter(UnitName('player')) then
    lb_print('You are not the master looter')
    return
  end

  local is_tm_roll = false
  for _, msg in ipairs(tmog_roll_messages) do
    local roller = msg.roller
    if roller == player_name then
      is_tm_roll = true
      break
    end
  end

  if not is_tm_roll then player_name = increase_plus_one(player_name) end

  local item_name, item_link, item_quality, _, _, _, _, _, _ = GetItemInfo(
                                                                 current_link)

  local item_id = tonumber(string_match(item_link, 'item:(%d+):'))

  local sell_buy_str = pfui_sell_data[item_id] or ''

  if sell_buy_str == '' then
    lb_print('No sell price found for ' .. item_name)
    return
  end

  local _, _, sell, buy = string.find(sell_buy_str, "(.*),(.*)")
  sell = create_gold_string(tonumber(sell))

  -- local message = item_link .. " ganado por OS. Pagar al banco/ML: " .. sell
  local _, _, _, color, _ = GetItemQualityColor(item_quality) or "ffffff"
  local r, g, b, hex_color = GetItemQualityColor(item_quality)
  local message = string.format(
                    "Precio OS: %s|Hitem:%d:0:0:0|h[%s]|h|r - %s >>>INGRESAR EN BANCO DE LA GUILD<<<",
                    hex_color, item_id, item_name, sell)

  SendChatMessage(message, 'WHISPER', nil, player_name)
end

function reduce_plus_one(player_name)
  if not is_master_looter(UnitName('player')) then
    lb_print('You are not the master looter')
    return
  end

  -- allow lowercase names
  player_name = string.lower(player_name)
  player_name = string.upper(string.sub(player_name, 1, 1)) ..
                  string.sub(player_name, 2)

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
  increase_po_message(player_name, -1)
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