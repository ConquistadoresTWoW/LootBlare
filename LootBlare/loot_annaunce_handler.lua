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
  local items_with_sr = {} -- Track items that have SRs

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
        
        -- Check if this item has any soft reserves
        local sr_list = find_soft_reservers_for_item(item_link)
        if sr_list and len(sr_list) > 0 then
          items_with_sr[item_link] = sr_list
        end
      end
    end
  end

  if len(item_link_list) > 0 then
    SendChatMessage(announcestring, "RAID", nil, nil)
    for _, item_link in ipairs(item_link_list) do
      SendChatMessage("- " .. item_link, "RAID", nil, nil)
      
      -- Announce soft reserves for this item if any exist
      local sr_list = items_with_sr[item_link]
      if sr_list and len(sr_list) > 0 then
        -- Group SRs by type (MS/OS) and sort by SR+ value
        local ms_srs = {}
        local os_srs = {}
        
        for _, sr in ipairs(sr_list) do
          if sr["MS"] then
            table.insert(ms_srs, sr)
          else
            table.insert(os_srs, sr)
          end
        end
        
        -- Sort by SR+ value (descending)
        table.sort(ms_srs, function(a, b) return a["SR+"] > b["SR+"] end)
        table.sort(os_srs, function(a, b) return a["SR+"] > b["SR+"] end)
        
        -- Build SR announcement message
        local sr_message = "- SR: "
        local sr_entries = {}
        
        -- Add MS SRs
        for _, sr in ipairs(ms_srs) do
          local class_color = config.RAID_CLASS_COLORS[get_class_of_roller(sr["Attendee"])] or 
                             config.DEFAULT_TEXT_COLOR
          local entry = "|c" .. class_color .. sr["Attendee"] .. "|r"
          if sr["SR+"] > 1 then
            entry = entry .. "(" .. sr["SR+"] .. ")"
          end
          table.insert(sr_entries, entry)
        end
        
        -- Add OS SRs
        for _, sr in ipairs(os_srs) do
          local class_color = config.RAID_CLASS_COLORS[get_class_of_roller(sr["Attendee"])] or 
                             config.DEFAULT_TEXT_COLOR
          local entry = "|c" .. class_color .. sr["Attendee"] .. "|r(OS)"
          if sr["SR+"] > 1 then
            entry = entry .. "(" .. sr["SR+"] .. ")"
          end
          table.insert(sr_entries, entry)
        end
        
        -- Combine all entries
        sr_message = sr_message .. table.concat(sr_entries, ", ")
        SendChatMessage(sr_message, "RAID", nil, nil)
      end
    end
  end
end