local function getGuid()
  local _, guid = UnitExists("target")
  return guid
end

EXCLUDED_ITEMS_TABLE = {
  ["Sulfuron Ingot"] = true,
  ["Elementium Ore"] = true,
  ["Fading Dream Fragment"] = true,
  ["Wartorn Cloth Scrap"] = true,
  ["Wartorn Leather Scrap"] = true,
  ["Wartorn Chain Scrap"] = true,
  ["Wartorn Plate Scrap"] = true,
  ["Pristine Lay Crytstal"] = true,

  -- enchanting stuff
  ["Nexus Crystal"] = true,
  ["Large Brilliant Shard"] = true,
  ["Small Brilliant Shard"] = true,
  ["Large Radiant Shard"] = true,
  ["Small Radiant Shard"] = true,
  ["Large Glimmering Shard"] = true,
  ["Small Glimmering Shard"] = true,
  ["Lesser Eternal Essence"] = true,
  ["Greater Eternal Essence"] = true,
  ["Lesser Nether Essence"] = true,
  ["Greater Nether Essence"] = true,
  ["Lesser Mystic Essence"] = true,
  ["Greater Mystic Essence"] = true,
  ["Dream Dust"] = true,
  ["Illusion Dust"] = true,
  ["Arcane Dust"] = true
}

IDOL_PREFIX = "Idol"

function loot_announce_handler()
  if not Settings.LootAnnounceActive then
    return -- If loot announcements are disabled, do nothing
  end

  local has_superwow = SetAutoloot and true or false

  if has_superwow then
    local unit_guid = getGuid()
    if unit_guid == nil or LastRaidData.AlreadyLooted[unit_guid] then
      return -- If this unit has already been looted, do nothing
    end
    LastRaidData.AlreadyLooted[unit_guid] = true -- Mark this unit as looted to avoid duplicate announcements
  end

  local announcestring = "- Items inside:"
  local item_link_list = {}
  local sr_item_info = {} -- Store SR info for each item

  for lootedindex = 1, GetNumLootItems() do
    local min_quality = tonumber(Settings.LootAnnounceMinQuality)
    local item_link = GetLootSlotLink(lootedindex)
    if item_link then
      local item_id = tonumber(string_match(item_link, "item:(%d+):"))
      local item_name, _, item_quality = GetItemInfo(item_id)
      if item_quality and item_quality >= min_quality and
        not EXCLUDED_ITEMS_TABLE[item_name] and
        not string.find(item_name, IDOL_PREFIX) then
        table.insert(item_link_list, item_link)
        
        -- Get SR information for this item
        local item_sr = find_soft_reservers_for_item(item_link)
        if len(item_sr) > 0 then
          sr_item_info[item_link] = item_sr
        end
      end
    end
  end

  if len(item_link_list) > 0 then
    SendChatMessage(announcestring, "RAID", nil, nil)
    for _, item_link in ipairs(item_link_list) do
      -- Announce the item
      SendChatMessage("- " .. item_link, "RAID", nil, nil)
      
      -- If there are SRs for this item, announce them
      if sr_item_info[item_link] then
        local sr_names = {}
        
        for _, sr in ipairs(sr_item_info[item_link]) do
          local attendee = sr["Attendee"]
          local sr_plus = sr["SR+"] or 0
          local ms_status = sr["MS"] and "MS" or "OS"
          local alt_status = sr["Alt"] and " (Alt)" or ""
          
          -- Get player class and create colored name
          local player_class = get_class_of_roller(attendee) or "unknown"
          local colored_name = create_color_name_by_class(attendee, player_class)
          
          -- Format each SR entry with colored name
          table.insert(sr_names, colored_name .. " (SR+" .. sr_plus .. ", " .. ms_status .. alt_status .. ")")
        end
        
        -- Send SR info in chunks to avoid message length issues
        local sr_count = len(sr_names)
        local chunk_size = 3 -- Number of SRs per message
        for i = 1, sr_count, chunk_size do
          local chunk_end = math.min(i + chunk_size - 1, sr_count)
          local chunk_message = "  "
          
          for j = i, chunk_end do
            if j > i then chunk_message = chunk_message .. ", " end
            chunk_message = chunk_message .. sr_names[j]
          end
          
          SendChatMessage(chunk_message, "RAID", nil, nil)
        end
      end
    end
  end
end