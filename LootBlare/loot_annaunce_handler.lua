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
  ["Pristine Lay Crytstal"] = true
}

IDOL_PREFIX = "Idol"

function loot_announce_handler()
  local has_superwow = SetAutoloot and true or false

  if has_superwow then
    local unit_guid = getGuid()
    if LastRaidData.AlreadyLooted[unit_guid] then
      return -- If this unit has already been looted, do nothing
    end
    LastRaidData.AlreadyLooted[unit_guid] = true -- Mark this unit as looted to avoid duplicate announcements
  end

  local announcestring = "Items inside:"

  for lootedindex = 1, GetNumLootItems() do
    local min_quality = tonumber(Settings.LootAnnounceMinQuality)
    local item_link = GetLootSlotLink(lootedindex)
    if item_link then
      local item_id = tonumber(string.match(item_link, "item:(%d+):"))
      local item_name, _, item_quality = GetItemInfo(item_id)
      if item_quality and item_quality >= min_quality and
        not EXCLUDED_ITEMS_TABLE[item_name] and
        not string.find(item_name, IDOL_PREFIX) then
        announcestring = announcestring .. " " .. item_link
      end
    end
  end

  if announcestring ~= "Items inside:" then
    SendChatMessage(announcestring, "RAID", nil, nil)
  end
end
