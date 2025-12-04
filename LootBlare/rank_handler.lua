lb_guild_info = {}
function lb_load_guild_info()
  GuildRoster() -- Request guild roster update

  for i = 1, GetNumGuildMembers(true) do
    local name, rank, rankIndex, _, _, _, _, officer_note =
      GetGuildRosterInfo(i)

    -- lower the officer_note and search for prioos:spec pattern
    local officer_note = string.lower(officer_note or "")
    local prio_os = string_match(officer_note, "prioos:(%S+)")

    if not name then break end
    -- ranks start at 0
    lb_guild_info[name] = {}
    lb_guild_info[name].rankIndex = rankIndex or 0
    lb_guild_info[name].prio_os = prio_os ~= nil
  end
end

function lb_get_player_rank(player_name)
  if lb_guild_info[player_name] and lb_guild_info[player_name].rankIndex then
    return lb_guild_info[player_name].rankIndex
  else
    return nil -- Player not found in guild
  end
end

function lb_is_high_rank(player_name)
  local rankIndex = lb_get_player_rank(player_name)
  if rankIndex and rankIndex <= 4 then
    return true
  else
    return false
  end
end

function lb_has_prio_os(player_name)
  if lb_guild_info[player_name] and lb_guild_info[player_name].prio_os then
    return lb_guild_info[player_name].prio_os
  else
    return false -- Player not found in guild or no prio os
  end
end

-- /run print(tostring(lb_is_high_rank("Segismundo")))
-- /run print(lb_get_player_rank("Segismundo"))
