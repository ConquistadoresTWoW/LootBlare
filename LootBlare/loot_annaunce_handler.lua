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

-- Function to get SR information for an item
local function get_sr_info_for_item(item_link)
    if not SRList or len(SRList) == 0 then
        return {}
    end
    
    local item_id = tonumber(string_match(item_link, "item:(%d+):"))
    if not item_id then return {} end
    
    local sr_info = {}
    
    for i, sr in ipairs(SRList) do
        if tonumber(sr["ID"]) == item_id and sr["SR+"] > 0 then
            -- Check if the player is in raid
            if is_member_in_raid(sr["Attendee"]) then
                table.insert(sr_info, {
                    player = sr["Attendee"],
                    sr_charges = sr["SR+"],
                    is_ms = sr["MS"],
                    is_alt = AltList[sr["Attendee"]] or false
                })
            end
        end
    end
    
    -- Sort by SR charges (highest first)
    table.sort(sr_info, function(a, b)
        if a.sr_charges == b.sr_charges then
            -- If same SR charges, prio MS over OS
            if a.is_ms == b.is_ms then
                return a.player < b.player
            end
            return a.is_ms and not b.is_ms
        end
        return a.sr_charges > b.sr_charges
    end)
    
    return sr_info
end

-- Function to format SR information for chat
local function format_sr_info_for_chat(sr_info, max_to_show)
    if len(sr_info) == 0 then
        return nil
    end
    
    local result = ""
    local count = 0
    local max_show = max_to_show or 3 -- Show up to 3 by default
    
    for i, info in ipairs(sr_info) do
        if count >= max_show then
            local remaining = len(sr_info) - max_show
            if remaining > 0 then
                result = result .. " (+" .. remaining .. " more)"
            end
            break
        end
        
        local class = get_class_of_roller(info.player)
        local colored_name = create_color_name_by_class(info.player, class)
        
        local ms_os_text = info.is_ms and "MS" or "OS"
        local alt_text = info.is_alt and " (Alt)" or ""
        
        if count > 0 then
            result = result .. ", "
        end
        
        result = result .. colored_name .. " [" .. info.sr_charges .. " " .. ms_os_text .. alt_text .. "]"
        count = count + 1
    end
    
    return result
end

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
  local items_with_sr = {} -- Track which items have SR

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
        
        -- Check if this item has SR
        local sr_info = get_sr_info_for_item(item_link)
        if len(sr_info) > 0 then
            items_with_sr[item_link] = sr_info
        end
      end
    end
  end

  if len(item_link_list) > 0 then
    SendChatMessage(announcestring, "RAID", nil, nil)
    for _, item_link in ipairs(item_link_list) do
      local line = "- " .. item_link
      
      -- Add SR information if available
      if items_with_sr[item_link] then
          local sr_text = format_sr_info_for_chat(items_with_sr[item_link])
          if sr_text then
              line = line .. " SR: " .. sr_text
          end
      end
      
      SendChatMessage(line, "RAID", nil, nil)
    end
  end
end

-- Helper function to extract full item links from text
local function extract_full_item_links(text)
    local links = {}
    -- This pattern captures the full item link including color codes and brackets
    for link in string.gfind(text, '|c.-|Hitem:.-|h.-|h|r') do
        table.insert(links, link)
    end
    return links
end

-- Function to simulate loot announcement from command
function simulate_loot_announcement(item_links_str)
  if not Settings.LootAnnounceActive then
    lb_print('Loot announcements are disabled')
    return
  end
  
  local item_links = extract_full_item_links(item_links_str)
  
  if len(item_links) == 0 then
    lb_print('No valid item links found')
    lb_print('Make sure to use full item links like: |cffa335ee|Hitem:18832:0:0:0|h[Brutality Blade]|h|r')
    return
  end
  
  local announcestring = "- Items inside:"
  local items_with_sr = {}
  
  SendChatMessage(announcestring, "RAID", nil, nil)
  
  for _, item_link in ipairs(item_links) do
    local line = "- " .. item_link
    
    -- Check if this item has SR
    local sr_info = get_sr_info_for_item(item_link)
    if sr_info and len(sr_info) > 0 then
      local sr_text = format_sr_info_for_chat(sr_info)
      if sr_text then
        line = line .. " SR: " .. sr_text
      end
    end
    
    SendChatMessage(line, "RAID", nil, nil)
  end
  
  lb_print('Simulated loot announcement sent to raid chat')
end