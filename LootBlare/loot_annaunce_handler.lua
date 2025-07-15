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
      end
    end
  end

  if len(item_link_list) > 0 then
    SendChatMessage(announcestring, "RAID", nil, nil)
    for _, item_link in ipairs(item_link_list) do
      SendChatMessage("- " .. item_link, "RAID", nil, nil)
    end
  end
end
