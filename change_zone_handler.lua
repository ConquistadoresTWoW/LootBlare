TWOW_RAID_NAMES = {
  ["Zul'Gurub"] = true,
  ["Onyxia's Lair"] = true,
  ["Ruins of Ahn'Qiraj"] = true,
  ["Molten Core"] = true,
  ["Emerald Sanctum"] = true,
  ["Blackwing Lair"] = true,
  ["Ahn'Qiraj"] = true,
  ["Naxxramas"] = true,
  ["Tower of Karazhan"] = true
}

function reset_plus_one_when_entering_raid()
  local current_zone = GetRealZoneText()
  local last_raid_time = LastRaidData.RaidTime or 0
  local current_time = time()
  local THREE_DAYS_IN_SECONDS = 3 * 24 * 60 * 60
  local time_difference = current_time - last_raid_time
  local is_a_new_raid = false

  if TWOW_RAID_NAMES[current_zone] then
    if current_zone ~= LastRaidData.RaidName then
      is_a_new_raid = true
    elseif time_difference > THREE_DAYS_IN_SECONDS then
      is_a_new_raid = true
    end
  end

  if is_a_new_raid then
    PlusOneList = {}
    LastRaidData.AlreadyLooted = {}
    LastRaidData.RaidName = current_zone
    LastRaidData.RaidTime = current_time
    lb_print('Plus one list cleared for entering a new raid: ' .. current_zone)
  end
end
