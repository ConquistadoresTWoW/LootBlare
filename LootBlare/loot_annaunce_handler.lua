local function getGuid()
  local _, guid = UnitExists("target")
  return guid
end

function loot_announce_handler()
  local unit_guid = getGuid()
  if LastRaidData.AlreadyLooted[unit_guid] then
    return -- If this unit has already been looted, do nothing
  end
  LastRaidData.AlreadyLooted[unit_guid] = true -- Mark this unit as looted to avoid duplicate announcements

  local announcestring = "Items inside:"

  for lootedindex = 1, GetNumLootItems() do
    local min_quality = tonumber(Settings.LootAnnounceMinQuality)
    lb_print(tostring(min_quality))
    local item_link = GetLootSlotLink(lootedindex)
    if item_link then
      local item_id = tonumber(string.match(item_link, "item:(%d+):"))
      local item_quality = select(3, GetItemInfo(item_id))
      if item_quality and item_quality >= min_quality then
        announcestring = announcestring .. " " .. item_link
      end
    end
  end

  if announcestring ~= "Items inside:" then
    SendChatMessage(announcestring, "RAID", nil, nil)
  end
end
