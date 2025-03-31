current_sr_text = ''
current_item_sr = {}
current_item_sr_ms = {}
current_item_sr_od = {}

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
  local is_pug = true

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
    if string.find(comment, 'alt') then row["Alt"] = true end
    row["SR+"] = tonumber(row["SR+"])
    if row["SR+"] ~= 0 then is_pug = false end
    if row["Alt"] then AltList[row["Attendee"]] = true end
    if AltList[row["Attendee"]] then row["Alt"] = true end

    table.insert(data, row)
  end

  -- In raiders, if the SR+ is off then all the SR+ are exported as 0, which is the same value 
  -- as the invalid SR when the SR+ is on. This is a workaround to fix the SR+ values when the SR+ is off.
  if is_pug then for i, row in ipairs(data) do row["SR+"] = 1 end end

  return data, nil
end

function load_sr_from_csv()
  local items, error = parse_csv()

  if error then
    lb_print('Error loading SR from CSV: ' .. error)
    return
  end

  SRList = items

  if ResetPOAfterImportingSR then
    PlusOneList = {}
    lb_print('PO list cleared')
  end

  lb_print('Loading SR from CSV')
end

function clear_sr_list()
  SRList = {}
  lb_print('SR list cleared')
end

function print_sr_list()
  for i, item in ipairs(SRList) do
    lb_print('ItemID: ' .. item["ID"] .. ', ItemName: ' .. item["Item"] ..
               ', Attendee: ' .. item["Attendee"] .. ', Comment: ' ..
               item["Comment"] .. ', SR+: ' .. item["SR+"] .. ', MS: ' ..
               tostring(item["MS"]) .. ', Alt: ' ..
               tostring(AltList[item["Attendee"]]))
  end
end

function find_soft_reservers_for_item(item_link)
  local item_id = tonumber(string_match(item_link, 'item:(%d+):'))

  local current_item_sr = {}
  for i, item in ipairs(SRList) do
    if tonumber(item["ID"]) == item_id and item["SR+"] > 0 then
      table.insert(current_item_sr, item)
    end
  end

  -- Filter out members not in the raid
  for i = len(current_item_sr), 1, -1 do
    if not is_member_in_raid(current_item_sr[i]["Attendee"]) then
      table.remove(current_item_sr, i)
    end
  end

  return current_item_sr
end

function find_ms_and_os_sr_for_item()
  if len(current_item_sr) == 0 then return {}, {} end

  local sorted_ms = {}
  local sorted_os = {}

  for i, sr in ipairs(current_item_sr) do
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
      class = get_class_of_roller(sr["Attendee"]),
      sr = sr["SR+"],
      sr_type = 'SR-MS',
      alt = AltList[sr["Attendee"]],
      roll_type = RollType.SR_MS
    }
    table.insert(sr_ms_messages, fake_roller)
  end

  for i, sr in ipairs(sr_os) do
    local alt_str = ''
    local fake_roller = {
      roller = sr["Attendee"],
      roll = 1,
      class = get_class_of_roller(sr["Attendee"]),
      sr = sr["SR+"],
      sr_type = 'SR-OS',
      alt = AltList[sr["Attendee"]],
      roll_type = RollType.SR_OS
    }
    table.insert(sr_os_messages, fake_roller)
  end
end

function has_sr(sr_list, roller)
  for i, sr in ipairs(sr_list) do if sr.roller == roller then return true end end
  return false
end

function built_sr_row_from_string(sr_str)
  local sr = string_split(sr_str, ',')
  local row = {
    ["ID"] = tonumber(sr[1]),
    ["Item"] = sr[2],
    ["Attendee"] = sr[3],
    ["SR+"] = tonumber(sr[4]),
    ["MS"] = sr[5] == 'true'
  }
  return row
end

function report_sr_list()
  SendAddonMessage(config.LB_PREFIX, config.LB_CLEAR_SR, 'RAID')
  for i, sr in current_item_sr do
    local message = sr["ID"] .. ',' .. sr["Item"] .. ',' .. sr["Attendee"] ..
                      ',' .. sr["SR+"] .. ',' .. tostring(sr["MS"])
    SendAddonMessage(config.LB_PREFIX, config.LB_ADD_SR .. message, 'RAID')
  end
end
