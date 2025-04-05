function print_alts_list()
  local alt_str = 'Alts list:'
  for alt, _ in pairs(AltList) do alt_str = alt_str .. alt .. ', ' end
  lb_print(alt_str)
end

function load_alts_from_string(alts_string)
  local alts = string_split(alts_string, ',')
  for i, alt in ipairs(alts) do if alt ~= '' then AltList[alt] = true end end
end

function remove_alts_from_string(alts_string)
  local alts = string_split(alts_string, ',')
  for i, alt in ipairs(alts) do AltList[alt] = nil end
end

function report_alt_list()
  local alt_str = ''
  for alt, _ in pairs(AltList) do
    alt_str = alt_str .. alt .. ','
    if string.len(alt_str) > 100 then
      SendAddonMessage(config.LB_PREFIX, config.LB_ADD_ALTS .. alt_str, 'RAID')
      alt_str = ''
    end
  end
  if string.len(alt_str) > 0 then
    SendAddonMessage(config.LB_PREFIX, config.LB_ADD_ALTS .. alt_str, 'RAID')
  end
end
