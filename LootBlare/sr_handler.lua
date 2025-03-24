current_sr_text = ''
sr_list = {}

local function parse_csv()
  -- Check if the input is valid
  if type(current_sr_text) ~= "string" or current_sr_text == "" then
    return nil, "Invalid input: CSV string is empty or not a string"
  end

  -- Split the CSV into lines
  local lines = {}
  for line in string.gfind(current_sr_text, "[^\r\n]+") do
    table.insert(lines, line)
  end

  -- Check if there are at least two lines (header + data)
  if len(lines) < 2 then return nil, "Invalid CSV: Missing header or data" end

  -- Parse the header
  local header = string_split(lines[1])

  -- Validate the header structure
  local expected_header = {"ID", "Item", "Attendee", "Comment", "SR+"}
  if len(header) ~= len(expected_header) then
    return nil, "Invalid CSV header: Incorrect number of fields"
  end

  for i, field in ipairs(expected_header) do
    if header[i] ~= field then
      return nil,
             "Invalid CSV header: Expected '" .. field .. "' but got '" ..
               (header[i] or "") .. "'"
    end
  end

  -- Parse the data
  local data = {}

  for i = 2, len(lines) do
    local row = {
      ["ID"] = nil,
      ["Item"] = nil,
      ["Attendee"] = nil,
      ["Comment"] = nil,
      ["SR+"] = nil,
      ["MS"] = true,
      ["Alt"] = false
    }

    local values = string_split(lines[i])
    if len(values) ~= len(header) then
      return nil,
             "Invalid CSV row: Incorrect number of fields in row " .. (i - 1)
    end

    for i, value in ipairs(values) do row[header[i]] = value end

    local comment = string.lower(row["Comment"])
    row["MS"] = not (string.find(comment, 'os')) and true
    row["Alt"] = string.find(comment, 'alt') and true or false
    row["SR+"] = tonumber(row["SR+"])
    if row["SR+"] == 0 then row["SR+"] = 1 end
    if row["Alt"] then AltList[row["Attendee"]] = true end
    if AltList[row["Attendee"]] then row["Alt"] = true end

    table.insert(data, row)
  end

  return data, nil
end

function load_sr_from_csv()
  local items, error = parse_csv()

  if error then
    lb_print('Error loading SR from CSV: ' .. error)
    return
  end

  sr_list = items
  lb_print('Loading SR from CSV')
end

function clear_sr_list()
  sr_list = {}
  lb_print('SR list cleared')
end

function print_sr_list()
  for i, item in ipairs(sr_list) do
    lb_print('ItemID: ' .. item["ID"] .. ', ItemName: ' .. item["Item"] ..
               ', Attendee: ' .. item["Attendee"] .. ', Comment: ' ..
               item["Comment"] .. ', SR+: ' .. item["SR+"] .. ', MS: ' ..
               tostring(item["MS"]) .. ', Alt: ' .. tostring(item["Alt"]))
  end
end

function find_soft_reservers_for_item(item_link)
  local item_id = tonumber(string_match(item_link, 'item:(%d+):'))

  lb_print('Item ID: ' .. tostring(item_id))

  local soft_reservers = {}
  for i, item in ipairs(sr_list) do
    if tonumber(item["ID"]) == item_id then
      table.insert(soft_reservers, item)
    end
  end

  return soft_reservers
end

function find_ms_and_os_sr_for_item(item_link)
  local soft_reservers = find_soft_reservers_for_item(item_link)

  -- Filter out members not in the raid
  for i = len(soft_reservers), 1, -1 do
    if not is_member_in_raid(soft_reservers[i]["Attendee"]) then
      table.remove(soft_reservers, i)
    end
  end

  if len(soft_reservers) == 0 then return {}, {} end

  local sorted_ms = {}
  local sorted_os = {}

  for i, sr in ipairs(soft_reservers) do
    if sr["MS"] then
      table.insert(sorted_ms, sr)
    else
      table.insert(sorted_os, sr)
    end
  end

  table.sort(sorted_ms, function(a, b) return a["SR+"] > b["SR+"] end)
  table.sort(sorted_os, function(a, b) return a["SR+"] > b["SR+"] end)

  return sorted_ms, sorted_os
end

function insert_sr_rolls(sr_ms, sr_os)
  for i, sr in ipairs(sr_ms) do
    local fake_roller = {
      roller = sr["Attendee"],
      roll = 1,
      msg = sr["Attendee"] .. ' rolls 1 (SR-MS: ' .. sr["SR+"] .. ')',
      class = get_class_of_roller(sr["Attendee"]),
      sr = sr["SR+"]
    }
    table.insert(sr_ms_messages, fake_roller)
  end

  for i, sr in ipairs(sr_os) do
    local fake_roller = {
      roller = sr["Attendee"],
      roll = 1,
      msg = sr["Attendee"] .. ' rolls 1 (SR-OS: ' .. sr["SR+"] .. ')',
      class = get_class_of_roller(sr["Attendee"]),
      sr = sr["SR+"]
    }
    table.insert(sr_os_messages, fake_roller)
  end
end

function has_sr(sr_list, roller)
  for i, sr in ipairs(sr_list) do if sr.roller == roller then return true end end
  return false
end
